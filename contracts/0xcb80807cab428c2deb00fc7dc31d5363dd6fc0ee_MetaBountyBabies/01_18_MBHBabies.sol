// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

// @author: olive

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                                                             ///
///    ____    ____        _           ______                          _            ______         __        _                  ///
///   |_   \  /   _|      / |_        |_   _ \                        / |_         |_   _ \       [  |      (_)                 ///
///     |   \/   |  .---.`| |-',--.     | |_) |  .--.  __   _  _ .--.`| |-'_   __    | |_) | ,--.  | |.--.  __  .---.  .--.     ///
///     | |\  /| | / /__\\| | `'_\ :    |  __'./ .'`\ [  | | |[ `.-. || | [ \ [  ]   |  __'.`'_\ : | '/'`\ [  |/ /__\\( (`\]    ///
///    _| |_\/_| |_| \__.,| |,// | |,  _| |__) | \__. || \_/ |,| | | || |, \ '/ /   _| |__) // | |,|  \__/ || || \__., `'.'.    ///
///   |_____||_____|'.__.'\__/\'-;__/ |_______/ '.__.' '.__.'_[___||__]__[\_:  /   |_______/\'-;__[__;.__.'[___]'.__.'[\__))    ///
///                                                                       \__.'                                                 ///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract MetaBountyBabies is
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    address private signerAddress;

    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_ELEMENTS = 8888;
    uint256 public PRICE = 0.1 ether;
    uint256 public constant START_AT = 1;
    uint256 public LIMIT_PER_MINT = 500;

    bool private PAUSE = true;
    bool private PAUSE_FREE = true;

    uint256 private tokenIdTracker = 0;

    string public baseTokenURI = "";

    bool public META_REVEAL = false;
    uint256 public HIDE_FROM = 1;
    uint256 public HIDE_TO = 8888;
    string public sampleTokenURI = "";

    address public constant creatorAddress =
        0x69A0B32752011FB029Df30B4388D2752aD3997e1;

    mapping(address => bool) internal admins;
    mapping(address => uint256) mintTokenCount;
    mapping(address => uint256) lastCheckPoint;

    struct NFTArrays {
        uint256[] iconics;
        uint256[] hunters;
        uint256[] huntresses;
        uint256[] secrets;
    }

    NFTArrays private nftsUsed;

    event PauseEvent(bool pause);
    event NewPriceEvent(uint256 price);
    event NewMaxElement(uint256 max);

    constructor(address _singenr) ERC721A("Meta Bounty Babies", "MBB") {
        admins[msg.sender] = true;
        signerAddress = _singenr;
    }

    modifier saleIsOpen() {
        require(totalToken() <= MAX_ELEMENTS, "MBB: Soldout");
        require(!PAUSE, "MBB: Sales not open");
        _;
    }

    modifier freeMintIsOpen() {
        require(totalToken() <= MAX_ELEMENTS, "MBB: Soldout");
        require(!PAUSE_FREE, "MBB: Free Mint not open");
        _;
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], "MBB: Caller is not the admin");
        _;
    }

    function setBaseURI(string calldata _baseURI) public onlyAdmin {
        baseTokenURI = _baseURI;
    }

    function setSampleURI(string calldata sampleURI) public onlyAdmin {
        sampleTokenURI = sampleURI;
    }

    function totalToken() public view returns (uint256) {
        return tokenIdTracker;
    }

    function totalIconicTokensUsed() public view returns (uint256[] memory) {
        return nftsUsed.iconics;
    }

    function totalHunterTokensUsed() public view returns (uint256[] memory) {
        return nftsUsed.hunters;
    }

    function totalHuntressTokensUsed() public view returns (uint256[] memory) {
        return nftsUsed.huntresses;
    }

    function totalSecretTokensUsed() public view returns (uint256[] memory) {
        return nftsUsed.secrets;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "MBB: URI query for nonexistent token");

        if (!META_REVEAL && tokenId >= HIDE_FROM && tokenId <= HIDE_TO)
            return sampleTokenURI;

        string memory baseURI = baseTokenURI;

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function mintCountOfWallet(address _wallet) public view returns (uint256) {
        return mintTokenCount[_wallet];
    }

    function ownerOf(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (address) {
        return super.ownerOf(tokenId);
    }

    function mint(
        uint256 _tokenAmount,
        uint256 _timestamp,
        bytes calldata _signature
    ) public payable saleIsOpen {
        uint256 total = totalToken();
        require(_tokenAmount <= LIMIT_PER_MINT, "MBB: Max limit per mint");
        require(total + _tokenAmount <= MAX_ELEMENTS, "MBB: Max limit");

        require(msg.value >= price(_tokenAmount), "MBB: Value below price");

        address wallet = _msgSender();

        address signerOwner = signatureWallet(
            wallet,
            _tokenAmount,
            _timestamp,
            _signature
        );
        require(signerOwner == signerAddress, "MBB: Not authorized to mint");

        require(_timestamp > lastCheckPoint[wallet], "MBB: Invalid timestamp");

        lastCheckPoint[wallet] = block.timestamp;
        mintTokenCount[wallet] += _tokenAmount;

        tokenIdTracker = tokenIdTracker + _tokenAmount;
        _safeMint(wallet, _tokenAmount);
    }

    function freeMint(
        uint256 _tokenAmount,
        uint256 _timestamp,
        bytes calldata _signature,
        NFTArrays calldata _nfts
    ) public freeMintIsOpen {
        uint256 total = totalToken();
        require(total + _tokenAmount <= MAX_ELEMENTS, "MBB: Max limit");

        address wallet = _msgSender();
        address signerOwner = signatureWalletForFreeMint(
            wallet,
            _tokenAmount,
            _timestamp,
            _nfts,
            _signature
        );

        require(signerOwner == signerAddress, "MBB: Not authorized to mint");
        require(_timestamp > lastCheckPoint[wallet], "MBB: Invalid timestamp");

        lastCheckPoint[wallet] = block.timestamp;
        mintTokenCount[wallet] += _tokenAmount;

        for (uint256 i = 0; i < _nfts.iconics.length; i++)
            nftsUsed.iconics.push(_nfts.iconics[i]);
        for (uint256 i = 0; i < _nfts.hunters.length; i++)
            nftsUsed.hunters.push(_nfts.hunters[i]);
        for (uint256 i = 0; i < _nfts.huntresses.length; i++)
            nftsUsed.huntresses.push(_nfts.huntresses[i]);
        for (uint256 i = 0; i < _nfts.secrets.length; i++)
            nftsUsed.secrets.push(_nfts.secrets[i]);

        tokenIdTracker = tokenIdTracker + _tokenAmount;
        _safeMint(wallet, _tokenAmount);
    }

    function signatureWalletForFreeMint(
        address wallet,
        uint256 _tokenAmount,
        uint256 _timestamp,
        NFTArrays calldata _nfts,
        bytes calldata _signature
    ) public pure returns (address) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encode(
                        wallet,
                        _tokenAmount,
                        _timestamp,
                        _nfts.iconics,
                        _nfts.hunters,
                        _nfts.huntresses,
                        _nfts.secrets
                    )
                ),
                _signature
            );
    }

    function signatureWallet(
        address wallet,
        uint256 _tokenAmount,
        uint256 _timestamp,
        bytes calldata _signature
    ) public pure returns (address) {
        return
            ECDSA.recover(
                keccak256(abi.encode(wallet, _tokenAmount, _timestamp)),
                _signature
            );
    }

    function setCheckPoint(address _minter, uint256 _point) public onlyOwner {
        require(_minter != address(0), "MBB: Unknown address");
        lastCheckPoint[_minter] = _point;
    }

    function getCheckPoint(address _minter) external view returns (uint256) {
        return lastCheckPoint[_minter];
    }

    function price(uint256 _count) public view returns (uint256) {
        return PRICE.mul(_count);
    }

    function setPause(bool _pause) public onlyAdmin {
        PAUSE = _pause;
        emit PauseEvent(PAUSE);
    }

    function setPauseFree(bool _pause) public onlyAdmin {
        PAUSE_FREE = _pause;
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
        emit NewPriceEvent(PRICE);
    }

    function setMaxElement(uint256 _max) public onlyOwner {
        MAX_ELEMENTS = _max;
        emit NewMaxElement(MAX_ELEMENTS);
    }

    function setMetaReveal(
        bool _reveal,
        uint256 _from,
        uint256 _to
    ) public onlyAdmin {
        META_REVEAL = _reveal;
        HIDE_FROM = _from;
        HIDE_TO = _to;
    }

    function withdrawAll() public onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creatorAddress, balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "MBB: Transfer failed.");
    }

    function giftMint(
        address[] calldata _addrs,
        uint256[] calldata _tokenAmounts
    ) public onlyAdmin {
        uint256 totalQuantity = 0;
        uint256 total = totalToken();
        for (uint256 i = 0; i < _addrs.length; i++) {
            totalQuantity += _tokenAmounts[i];
        }
        require(total + totalQuantity <= MAX_ELEMENTS, "MBB: Max limit");

        for (uint256 i = 0; i < _addrs.length; i++) {
            tokenIdTracker = tokenIdTracker + _tokenAmounts[i];
            _safeMint(_addrs[i], _tokenAmounts[i]);
        }
    }

    function addAdminRole(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function revokeAdminRole(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function hasAdminRole(address _address) external view returns (bool) {
        return admins[_address];
    }

    function burn(uint256[] calldata tokenIds) external onlyAdmin {
        for (uint8 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    function updateSignerAddress(address _signer) public onlyOwner {
        signerAddress = _signer;
    }

    function updateLimitPerMint(uint256 _limitpermint) public onlyAdmin {
        LIMIT_PER_MINT = _limitpermint;
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}