// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC721.sol";
import "IERC2981.sol";

import "Pausable.sol";
import "ReentrancyGuard.sol";
import "Ownable.sol";

import "MerkleProof.sol";
import "Counters.sol";

import "ContentMixin.sol";
import "NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

//       _       _____     _______  ____  ____       _
//      / \     |_   _|   |_   __ \|_   ||   _|     / \
//     / _ \      | |       | |__) | | |__| |      / _ \
//    / ___ \     | |   _   |  ___/  |  __  |     / ___ \     Artist: SaJo
//  _/ /   \ \_  _| |__/ | _| |_    _| |  | |_  _/ /   \ \_   Dev: HogChop
// |____|_|____||________||_____| _|____||____||____|_|____|__  _____  _________     _       _______   ____  ____
// |_   __  ||_   _|   |_   __  ||_   \  /   _||_   __  ||_   \|_   _||  _   _  |   / \     |_   __ \ |_  _||_  _|
//   | |_ \_|  | |       | |_ \_|  |   \/   |    | |_ \_|  |   \ | |  |_/ | | \_|  / _ \      | |__) |  \ \  / /
//   |  _| _   | |   _   |  _| _   | |\  /| |    |  _| _   | |\ \| |      | |     / ___ \     |  __ /    \ \/ /
//  _| |__/ | _| |__/ | _| |__/ | _| |_\/_| |_  _| |__/ | _| |_\   |_    _| |_  _/ /   \ \_  _| |  \ \_  _|  |_
// |________||________||________||_____||_____||________||_____|\____|  |_____||____| |____||____| |___||______|

contract AlphaElementary is
    ERC721,
    IERC2981,
    Pausable,
    Ownable,
    ReentrancyGuard,
    ContextMixin,
    NativeMetaTransaction
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bool public preLiveToggle;
    bool public saleLiveToggle;
    bool public freezeURI;
    bool public contractRoyalties;

    bytes32 private wlisteRoot;
    bytes32 private xileMkRoot;

    uint32 public constant MAX_NFT = 3000;
    uint32 private constant MAX_MINT = 4;
    uint32 private constant MAX_GIFT = 35;
    uint32 public GIFT_COUNT = 0;
    uint256 public PRICE = 0.07 ether;
    uint256 public XILE_PRICE = 0.05 ether; // for Xile and Xalt holders

    address private _creators;
    address public proxyRegistryAddress;

    string private _contractURI;
    string private _metadataBaseURI;

    mapping(address => uint256) private presalePurchased;

    // ** MODIFIERS ** //
    // *************** //

    modifier saleLive() {
        require(saleLiveToggle == true, "Sale is closed");
        _;
    }

    modifier preSaleLive() {
        require(preLiveToggle == true, "Presale is closed");
        _;
    }

    modifier allocTokens(uint32 numToMint) {
        require(
            totalSupply() + numToMint <= (MAX_NFT - (MAX_GIFT - GIFT_COUNT)),
            "Sorry, there are not enough artworks remaining."
        );
        _;
    }

    modifier maxOwned(uint32 numToMint) {
        require(
            presalePurchased[_msgSender()] + numToMint <= MAX_MINT,
            "Max 4 mints for presale"
        );
        _;
    }

    modifier correctPayment(uint256 mintPrice, uint32 numToMint) {
        require(
            msg.value == mintPrice * numToMint,
            "Payment failed, please ensure you are paying the correct amount."
        );
        _;
    }

    constructor(
        string memory _cURI,
        string memory _mURI,
        address _creatorAdd,
        address _proxyRegistryAddress
    ) ERC721("Alpha Elementary", "AE") {
        _contractURI = _cURI;
        _metadataBaseURI = _mURI;
        _creators = _creatorAdd;
        proxyRegistryAddress = _proxyRegistryAddress;
        _tokenIdCounter.increment();
    }

    // ** MINTING FUNCS ** //
    // ******************* //

    function aeMint(uint32 mintNum)
        external
        payable
        nonReentrant
        saleLive
        allocTokens(mintNum)
        correctPayment(PRICE, mintNum)
    {
        require(
            balanceOf(_msgSender()) + mintNum <= MAX_MINT,
            "Limit of 4 per wallet"
        );
        for (uint32 i = 0; i < mintNum; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(_msgSender(), tokenId);
        }
    }

    function preMint(uint32 mintNum, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        preSaleLive
        maxOwned(mintNum)
        correctPayment(PRICE, mintNum)
    {
        require(
            MerkleProof.verify(
                merkleProof,
                wlisteRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not on whitelist"
        );

        presalePurchased[_msgSender()] += mintNum;

        for (uint32 i = 0; i < mintNum; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(_msgSender(), tokenId);
        }
    }

    function xileMint(uint32 mintNum, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        preSaleLive
        maxOwned(mintNum)
        correctPayment(XILE_PRICE, mintNum)
    {
        require(
            MerkleProof.verify(
                merkleProof,
                xileMkRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not on Xile whitelist"
        );

        presalePurchased[_msgSender()] += mintNum;

        for (uint32 i = 0; i < mintNum; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(_msgSender(), tokenId);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // ** ADMIN ** //
    // *********** //

    function giftMint(address[] calldata receivers) public onlyOwner {
        require(
            totalSupply() + receivers.length <= MAX_NFT,
            "Sorry, there are not enough artworks remaining."
        );
        require(
            GIFT_COUNT + receivers.length <= MAX_GIFT,
            "no gifts remaining"
        );

        for (uint32 i = 0; i < receivers.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            GIFT_COUNT++;
            _safeMint(receivers[i], tokenId);
        }
    }

    function getOwnersTokens(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        require(balanceOf(_owner) > 0, "You don't currently hold any tokens");
        uint256 tokenCount = balanceOf(_owner);
        uint256 foundTokens = 0;
        uint256[] memory tokenIds = new uint256[](tokenCount);

        for (uint256 i = 1; i < _tokenIdCounter.current(); i++) {
            if (ownerOf(i) == _owner) {
                tokenIds[foundTokens] = i;
                foundTokens++;
            }
        }

        return tokenIds;
    }

    function _baseURI() internal view override returns (string memory) {
        return _metadataBaseURI;
    }

    function withdrawFunds(uint256 _amt) public onlyOwner {
        uint256 pay_amt;
        if (_amt == 0) {
            pay_amt = address(this).balance;
        } else {
            pay_amt = _amt;
        }

        (bool success, ) = payable(_creators).call{value: pay_amt}("");
        require(success, "Failed to send payment, let the artists starve!");
    }

    // ** SETTINGS ** //
    // ************** //

    function metaURI(string calldata _URI) external onlyOwner {
        require(freezeURI == false, "Metadata has been frozen");
        _metadataBaseURI = _URI;
    }

    function cntURI(string calldata _URI) external onlyOwner {
        _contractURI = _URI;
    }

    function tglLive() external onlyOwner {
        saleLiveToggle = !saleLiveToggle;
    }

    function tglPresale() external onlyOwner {
        preLiveToggle = !preLiveToggle;
    }

    function freezeAll() external onlyOwner {
        require(freezeURI == false, "Metadata is already frozen");
        freezeURI = true;
    }

    /**
     * @dev Reserve ability to make use of {IERC165-royaltyInfo} standard to implement royalties.
     */
    function tglRoyalties() external onlyOwner {
        contractRoyalties = !contractRoyalties;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updatePrice(uint256 _price, uint32 _list) external onlyOwner {
        if (_list == 0) {
            // sale price
            PRICE = _price;
        } else {
            // xile price
            XILE_PRICE = _price;
        }
    }

    function setMerkleRoot(bytes32 _root, uint32 _list) external onlyOwner {
        if (_list == 0) {
            // update main whitelist
            wlisteRoot = _root;
        } else {
            // update xile whitelist
            xileMkRoot = _root;
        }
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }

    function setCreator(address to) external onlyOwner returns (address) {
        _creators = to;
        return _creators;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress)
        external
        onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        require(contractRoyalties == true, "Royalties dissabled");

        return (address(this), (salePrice * 7) / 100);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}