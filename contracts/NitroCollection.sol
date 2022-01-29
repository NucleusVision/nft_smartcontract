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

    event BeneficiaryUpdated(address oldBeneficiary, address newBeneficiary);
    event SignerUpdated(address oldBeneficiary, address newBeneficiary);
    event AllowedERC20Updated(address erc20, bool status, uint256 when);
    event UpdatedERC20Price(address erc20, uint256 price, uint256 when);
    event Paid(
        address erc20,
        uint256 price,
        address who,
        uint256 when,
        uint256 tier
    );
    event OperatorUpdated(address operator, bool status, uint256 when);
    event OperatorMinted(address operator, address to, uint256 when);

    constructor(
        address _usdt,
        address _usdc,
        address _dai,
        uint256 _tier,
        uint256 _price,
        string memory _URI,
        address _beneficiary
    ) ERC721("NPass", "NPass") {
        require(_usdt != address(0), "Initiate:: Invalid USDT Address");
        require(_usdc != address(0), "Initiate:: Invalid USDC Address");
        require(_dai != address(0), "Initiate:: Invalid DAI Address");
        require(_beneficiary != address(0), "Initiate:: Invalid Beneficiary Address");
        require(_tier > 0, "Initiate:: Tier can not be Zero");
        require(_price > 0, "Initiate:: Price can not be Zero");
        tier = _tier;
        _baseURIextended = _URI;
        beneficiary = _beneficiary;
        allowedERC20[_usdt] = true;
        allowedERC20[_usdc] = true;
        allowedERC20[_dai] = true;
        erc20Price[_usdt] = _price * 10**6; // USDT
        erc20Price[_usdc] = _price * 10**6; // USDC
        erc20Price[_dai] = _price * 10**18; // DAI
    }

    function updateERC20(address _erc20, bool _status) public onlyOwner {
        require(_erc20 != address(0), "UpdateOperator:: Invalid Address");
        allowedERC20[_erc20] = _status;
        emit AllowedERC20Updated(_erc20, _status, block.timestamp);
    }

    function updateOperator(address _operator, bool _status) public onlyOwner {
        require(_operator != address(0), "UpdateOperator:: Invalid Address");
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status, block.timestamp);
    }

    function updatePrice(address _erc20, uint256 _price) public onlyOwner {
        require(_erc20 != address(0), "UpdatePrice:: Invalid Address");
        require(
            allowedERC20[_erc20],
            "UpdatePrice:: Whitelist ERC20 before set Price"
        );
        erc20Price[_erc20] = _price;
        emit UpdatedERC20Price(_erc20, _price, block.timestamp);
    }

    function pay(address _erc20) external {
        require(_erc20 != address(0), "SuperMint:: Invalid Address");
        require(allowedERC20[_erc20], "Pay:: Unsupported ERC20");
        uint256 _toPay = erc20Price[_erc20];
        require(
            IERC20(_erc20).balanceOf(msg.sender) >= _toPay,
            "Pay:: Insufficient Balance"
        );
        require(
            transferERC20(_erc20, _toPay) == true,
            "Mint:: Transfer Failed"
        );
        safeMint(msg.sender);
        emit Paid(_erc20, _toPay, msg.sender, block.timestamp, tier);
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "OnlyOperator:: Unauthorized");
        _;
    }

    function superMint(address _to) public onlyOperator {
        require(_to != address(0), "SuperMint:: _to can not be zero address");
        safeMint(_to);
        emit OperatorMinted(msg.sender, _to, block.timestamp);
    }

    function transferERC20(address _erc20, uint256 _toPay)
        internal
        returns (bool)
    {
        return IERC20(_erc20).transferFrom(msg.sender, beneficiary, _toPay);
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

    function setBaseURI(string memory baseURI_) public onlyOwner {
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

    function tokenExists(uint256 tokenId) public view returns (bool) {
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
}
