// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract MASAC is Ownable, ERC721, EIP712 {
    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Whitelist(address buyer,uint256 signedQty,uint256 nonce)");
    address public whitelistSigner;

    uint256 public constant TOTAL_MAX_QTY = 16000;
    uint256 public constant GIFT_MAX_QTY = 160;
    uint256 public constant TOTAL_MINT_MAX_QTY = TOTAL_MAX_QTY - GIFT_MAX_QTY;
    uint256 public constant PRICE = 0.055 ether;
    uint256 public constant MAX_MINT_PER_WALLET = 20;
    string private _tokenBaseURI;
    uint256 public claimedQty = 0;
    uint256 public mintedQty = 0;
    uint256 public giftedQty = 0;
    mapping(address => uint256) public claimerToTokenQty;
    mapping(address => uint256) public minterToTokenQty;
    address proxyRegistryAddress;
    uint8 public status = 0; // 0: closed, 1: claim phase, 2: public mint phase

    constructor()
        ERC721("Mutant Anatomy Science Ape Club", "MASAC")
        EIP712("MASAC", "1")
    {}

    function setWhitelistSigner(address _address) external onlyOwner {
        whitelistSigner = _address;
    }

    function getSigner(
        address _buyer,
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(WHITELIST_TYPEHASH, _buyer, _signedQty, _nonce)
            )
        );
        return ECDSA.recover(digest, _signature);
    }

    function totalSupply() public view returns (uint256) {
        return claimedQty + mintedQty + giftedQty;
    }

    function claim(
        uint256 _mintQty,
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    ) external payable {
        require(status == 1, "CLOS");
        require(claimedQty + mintedQty + _mintQty <= TOTAL_MINT_MAX_QTY, "MAXL");
        require(
            getSigner(msg.sender, _signedQty, _nonce, _signature) ==
                whitelistSigner,
            "SIGN"
        );
        require(claimerToTokenQty[msg.sender] + _mintQty <= _signedQty, "MAXS");

        uint256 totalSupplyBefore = totalSupply();
        claimedQty += _mintQty;
        claimerToTokenQty[msg.sender] += _mintQty;
        for (uint256 i = 0; i < _mintQty; i++) {
            _mint(msg.sender, ++totalSupplyBefore);
        }
    }

    function mint(uint256 _mintQty) external payable {
        require(status == 2, "CLOS");
        require(claimedQty + mintedQty + _mintQty <= TOTAL_MINT_MAX_QTY, "MAXL");
        require(
            minterToTokenQty[msg.sender] + _mintQty <= MAX_MINT_PER_WALLET,
            "MAXP"
        );
        require(msg.value >= PRICE * _mintQty, "SETH");

        uint256 totalSupplyBefore = totalSupply();
        mintedQty += _mintQty;
        minterToTokenQty[msg.sender] += _mintQty;
        for (uint256 i = 0; i < _mintQty; i++) {
            _mint(msg.sender, ++totalSupplyBefore);
        }
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(giftedQty + receivers.length <= GIFT_MAX_QTY, "MAXG");

        uint256 totalSupplyBefore = totalSupply();
        giftedQty += receivers.length;
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], ++totalSupplyBefore);
        }
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "ZERO");
        payable(msg.sender).transfer(address(this).balance);
    }

    function setStatus(uint8 _code) external onlyOwner {
        status = _code;
    }

    // rinkeby: 0xf57b2c51ded3a29e6891aba85459d600256cf317
    // mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
    function setProxyRegistryAddress(address proxyAddress) external onlyOwner {
        proxyRegistryAddress = proxyAddress;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _tokenBaseURI;
    }
}