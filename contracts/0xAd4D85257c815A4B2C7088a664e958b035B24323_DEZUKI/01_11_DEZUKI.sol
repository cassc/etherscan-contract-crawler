// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract DEZUKI is Ownable, ERC721 {
    uint256 public constant TOTAL_MAX_QTY = 8888;
    uint256 public constant FREE_MINT_MAX_QTY = 800;
    uint256 public constant PAID_MINT_MAX_QTY = 8044;
    uint256 public constant TOTAL_MINT_MAX_QTY =
        FREE_MINT_MAX_QTY + PAID_MINT_MAX_QTY;
    uint256 public constant GIFT_MAX_QTY = 44;
    uint256 public constant PRICE = 0.038 ether;
    uint256 public constant MAX_QTY_PER_WALLET = 20;
    string private _tokenBaseURI;
    uint256 public maxFreeQtyPerWallet = 0;
    uint256 public mintedQty = 0;
    uint256 public giftedQty = 0;
    mapping(address => uint256) public minterToTokenQty;
    address proxyRegistryAddress;

    constructor() ERC721("Demonized Azuki", "DEZUKI") {}

    function totalSupply() public view returns (uint256) {
        return mintedQty + giftedQty;
    }

    function mint(uint256 _mintQty) external payable {
        // free
        if (mintedQty < FREE_MINT_MAX_QTY) {
            require(mintedQty + _mintQty <= FREE_MINT_MAX_QTY, "MAXL");
            require(
                minterToTokenQty[msg.sender] + _mintQty <= maxFreeQtyPerWallet,
                "MAXF"
            );
        }
        //paid
        else {
            require(mintedQty + _mintQty <= TOTAL_MINT_MAX_QTY, "MAXL");
            require(
                minterToTokenQty[msg.sender] + _mintQty <= MAX_QTY_PER_WALLET,
                "MAXP"
            );
            require(msg.value >= PRICE * _mintQty, "SETH");
        }
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

    function setMaxFreeQtyPerTx(uint256 _maxQtyPerTx) external onlyOwner {
        maxFreeQtyPerWallet = _maxQtyPerTx;
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