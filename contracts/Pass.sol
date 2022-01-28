// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Pass is
    ERC721,
    ERC721Enumerable,
    ReentrancyGuard,
    Ownable,
    ERC721Burnable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    uint256 public tier = 1;

    // Mapping to TokenURIs
    mapping(uint256 => string) private _tokenURIs;

    // Allowed ERC20 & Status
    mapping(address => bool) private allowedERC20;

    // Allowed ERC20, Price Mapping
    mapping(address => uint256) private erc20Price;

    // Claimed Users , Price Mapping
    mapping(address => bool) private claimedWallets;

    // Operator Users , Status Mapping
    mapping(address => bool) private operators;

    string private _baseURIextended;
    address public beneficiary;
    address public systemSigner;

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
    event Calimed(address who, uint256 howmany, uint256 when);

    constructor(
        address USDT,
        address USDC,
        address DAI
    ) ERC721("Pass", "Pass") {
        _baseURIextended = "#";
        allowedERC20[USDT] = true;
        allowedERC20[USDC] = true;
        allowedERC20[DAI] = true;
        erc20Price[USDT] = 450 * 10**6; // USDT
        erc20Price[USDC] = 450 * 10**6; // USDC
        erc20Price[DAI] = 450 * 10**18; // DAI
    }

    function updateERC20(address _erc20, bool _status) public onlyOwner {
        allowedERC20[_erc20] = _status;
        emit AllowedERC20Updated(_erc20, _status, block.timestamp);
    }

    function updatePrice(address _erc20, uint256 _price) public onlyOwner {
        require(
            allowedERC20[_erc20],
            "UpdatePrice:: Whitelist ERC20 before set Price"
        );
        erc20Price[_erc20] = _price;
        emit UpdatedERC20Price(_erc20, _price, block.timestamp);
    }

    function pay(address _erc20) external {
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

    function claim(
        uint256 _noOfNFTToMint,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(!claimedWallets[msg.sender], "Calim:: Already Calimed");
        require(_noOfNFTToMint > 0, "Claim:: Invalid tokens to mint");
        string memory messageSigned = prepareMessage(
            msg.sender,
            tier,
            _noOfNFTToMint
        );
        address signedBy = StringLibrary.recover(messageSigned, v, r, s);
        require(signedBy == systemSigner, "Claim:: Invalid Signature");
        claimedWallets[msg.sender] = true;
        for (uint256 i = 0; i <= _noOfNFTToMint; i++) {
            safeMint(msg.sender);
        }
        emit Calimed(msg.sender, _noOfNFTToMint, block.timestamp);
    }

    function prepareMessage(
        address _wallet,
        uint256 _tier,
        uint256 _noOfNFTToMint
    ) internal pure returns (string memory) {
        return toString(keccak256(abi.encode(_wallet, _tier, _noOfNFTToMint)));
    }

    function generateMessageToSign(
        address _wallet,
        uint256 _tier,
        uint256 _noOfNFTToMint
    ) public pure returns (string memory) {
        return prepareMessage(_wallet, _tier, _noOfNFTToMint);
    }

    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i * 2] = alphabet[uint8(value[i] >> 4)];
            str[1 + i * 2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
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

    function updateSystemSigner(address payable _systemSigner)
        external
        onlyOwner
    {
        require(
            _systemSigner != address(0),
            "updateSystemSigner:: New Signer can not be Zero Address"
        );
        address _oldSigner = systemSigner;
        systemSigner = _systemSigner;
        emit SignerUpdated(_oldSigner, _systemSigner);
    }
}

library StringLibrary {
    using UintLibrary for uint256;

    function recover(
        string memory message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0),
            new bytes(0),
            new bytes(0),
            new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(
        bytes memory _ba,
        bytes memory _bb,
        bytes memory _bc,
        bytes memory _bd,
        bytes memory _be,
        bytes memory _bf,
        bytes memory _bg
    ) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(
            _ba.length +
                _bb.length +
                _bc.length +
                _bd.length +
                _be.length +
                _bf.length +
                _bg.length
        );
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint256 i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint256 i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];
        return resultBytes;
    }
}

library UintLibrary {
    function toString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
