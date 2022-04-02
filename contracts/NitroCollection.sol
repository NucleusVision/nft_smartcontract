// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NitroCollection is
    ERC721,
    ERC721Enumerable,
    ReentrancyGuard,
    Ownable,
    ERC721Burnable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // To maintain tier
    uint256 public tier;

    // Mapping to TokenURIs
    mapping(uint256 => string) private _tokenURIs;

    // Allowed ERC20 & Status
    mapping(address => bool) public allowedERC20;

    // Allowed ERC20, Price Mapping
    mapping(address => uint256) public erc20Price;

    // Operator Users , Status Mapping
    mapping(address => bool) public operators;

    string private _baseURIextended;
    address public beneficiary;
    address public teller;

    event BeneficiaryUpdated(address oldBeneficiary, address newBeneficiary);
    event TellerUpdated(address oldTeller, address newTeller);
    event SignerUpdated(address oldBeneficiary, address newBeneficiary);
    event AllowedERC20Updated(address erc20, bool status, uint256 when);
    event UpdatedERC20Price(address erc20, uint256 price, uint256 when);
    event Paid(
        address erc20,
        uint256 price,
        address who,
        address to,
        uint256 when,
        uint256 tier
    );
    event PendingPaid(
        address erc20,
        uint256 price,
        address who,
        address to,
        uint256 when,
        uint256 tier
    );
    event OperatorUpdated(address operator, bool status, uint256 when);
    event OperatorMinted(address operator, address to, uint256 when);

    constructor(
        address _usdc,
        address _dai,
        uint256 _tier,
        uint256 _price,
        string memory _URI,
        address _beneficiary,
        address _teller
    ) ERC721("Nitro Network", "Top") {
        require(_usdc != address(0), "Initiate:: Invalid USDC Address");
        require(_dai != address(0), "Initiate:: Invalid DAI Address");
        require(_tier > 0, "Initiate:: Tier can not be Zero");
        require(_price > 0, "Initiate:: Price can not be Zero");
        require(
            _beneficiary != address(0),
            "Initiate:: Invalid Beneficiary Address"
        );
        require(_teller != address(0), "Initiate:: Invalid Teller Address");
        tier = _tier;
        _baseURIextended = _URI;
        beneficiary = _beneficiary;
        teller = _teller;
        allowedERC20[_usdc] = true;
        allowedERC20[_dai] = true;
        erc20Price[_usdc] = _price * 10**6; // USDC
        erc20Price[_dai] = _price * 10**18; // DAI
    }

    function updateERC20(address _erc20, bool _status) external onlyOwner {
        require(_erc20 != address(0), "UpdateERC20:: Invalid Address");
        allowedERC20[_erc20] = _status;
        emit AllowedERC20Updated(_erc20, _status, block.timestamp);
    }

    function updateOperator(address _operator, bool _status)
        external
        onlyOwner
    {
        require(_operator != address(0), "UpdateOperator:: Invalid Address");
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status, block.timestamp);
    }

    function updatePrice(address _erc20, uint256 _price) external onlyOwner {
        require(_erc20 != address(0), "UpdatePrice:: Invalid Address");
        require(
            allowedERC20[_erc20],
            "UpdatePrice:: Whitelist ERC20 before set Price"
        );
        erc20Price[_erc20] = _price;
        emit UpdatedERC20Price(_erc20, _price, block.timestamp);
    }

    function pay(address _erc20) external nonReentrant {
        require(_erc20 != address(0), "Pay:: Invalid Address");
        require(allowedERC20[_erc20], "Pay:: Unsupported ERC20");
        uint256 _toPay = erc20Price[_erc20];
        require(
            IERC20(_erc20).balanceOf(msg.sender) >= _toPay,
            "Pay:: Insufficient Balance"
        );
        require(
            transferERC20(_erc20, beneficiary, _toPay),
            "Pay:: Transfer Failed"
        );
        safeMint(msg.sender);
        emit Paid(
            _erc20,
            _toPay,
            msg.sender,
            beneficiary,
            block.timestamp,
            tier
        );
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "OnlyOperator:: Unauthorized");
        _;
    }

    function superMint(address _to) external onlyOperator nonReentrant {
        require(_to != address(0), "SuperMint:: _to can not be zero address");
        safeMint(_to);
        emit OperatorMinted(msg.sender, _to, block.timestamp);
    }

    function bulkMint(address[] memory _recipients)
        external
        onlyOperator
        nonReentrant
    {
        require(
            _recipients.length > 0,
            "BulkMint:: _recipients length != amounts length"
        );
        for (uint64 i = 0; i < _recipients.length; i++) {
            require(
                _recipients[i] != address(0),
                "BulkMint:: _recipients can not be zero address"
            );
            safeMint(_recipients[i]);
            emit OperatorMinted(msg.sender, _recipients[i], block.timestamp);
        }
    }

    function transferERC20(
        address _erc20,
        address _recipient,
        uint256 _toPay
    ) internal returns (bool) {
        return IERC20(_erc20).transferFrom(msg.sender, _recipient, _toPay);
    }

    function payPending(address _erc20, uint256 _toPay) external nonReentrant {
        require(
            IERC20(_erc20).balanceOf(msg.sender) >= _toPay,
            "PayPending:: Insufficient Balance"
        );
        require(
            transferERC20(_erc20, teller, _toPay),
            "PayPending:: Transfer Failed"
        );
        emit PendingPaid(
            _erc20,
            _toPay,
            msg.sender,
            teller,
            block.timestamp,
            tier
        );
    }

    function safeMint(address _to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(_exists(tokenId), "_setTokenURI: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "tokenURI: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, tokenId.toString()));
        }
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function tokenExists(uint256 tokenId) external view returns (bool) {
        return (_exists(tokenId));
    }

    function updateBeneficiary(address payable _newBeneficiary)
        external
        onlyOwner
    {
        require(
            _newBeneficiary != address(0),
            "UpdateBeneficiary:: New Beneficiary can not be Zero Address"
        );
        address _oldBeneficiary = beneficiary;
        beneficiary = _newBeneficiary;
        emit BeneficiaryUpdated(_oldBeneficiary, _newBeneficiary);
    }

    function updateTeller(address payable _newTeller) external onlyOwner {
        require(
            _newTeller != address(0),
            "updateTeller:: New Teller can not be Zero Address"
        );
        address _oldTeller = teller;
        teller = _newTeller;
        emit TellerUpdated(_oldTeller, _newTeller);
    }
}
