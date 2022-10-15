// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// @author: olive

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                           ///                                   
///                                                                                           ///                                                                           
///              _____ ______       ________      ___  ___          ___    ___                ///
///             |\   _ \  _   \    |\   __  \    |\  \|\  \        |\  \  |\  \               ///
///             \ \  \\\__\ \  \   \ \  \|\ /_   \ \  \\\  \       \ \  \ \ \  \              ///
///              \ \  \\|__| \  \   \ \   __  \   \ \   __  \       \ \  \ \ \  \             ///
///               \ \  \    \ \  \   \ \  \|\  \   \ \  \ \  \       \ \  \ \ \  \            ///
///                \ \__\    \ \__\   \ \_______\   \ \__\ \__\       \ \__\ \ \__\           ///
///                 \|__|     \|__|    \|_______|    \|__|\|__|        \|__|  \|__|           ///
///                                                                                           ///
///                                                                                           ///
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////

contract MetaBountyHuntress is ERC721AQueryable, Ownable, ReentrancyGuard {
    address private signerAddress;

    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_ELEMENTS = 8888;
    uint256 public PRICE = 1.63 ether;
    uint256 public constant START_AT = 1;
    uint256 public LIMIT_PER_MINT = 50;

    bool private PAUSE = true;

    uint256 private tokenIdTracker = 0;

    string public baseTokenURI;

    bool public META_REVEAL = false;
    uint256 public HIDE_FROM = 1;
    uint256 public HIDE_TO = 8888;
    string public sampleTokenURI;

    address public constant creatorAddress = 0xE4f3c38Ae79e4C86641FB605872b86DaAA1AaE65;

    mapping(address => bool) internal admins;
    mapping(address => uint256) mintTokenCount;
    mapping(address => uint256) lastCheckPoint;

    event PauseEvent(bool pause);
    event NewPriceEvent(uint256 price);
    event NewMaxElement(uint256 max);

    constructor(address _singenr)
        ERC721A("Meta Bounty Huntress", "MBH II")
    {
        admins[msg.sender] = true;
        signerAddress = _singenr;
    }

    modifier saleIsOpen() {
        require(totalToken() <= MAX_ELEMENTS, "MBH II: Soldout!");
        require(!PAUSE, "MBH II: Sales not open");
        _;
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], "MBH II: Caller is not the admin");
        _;
    }

    function setBaseURI(string memory _baseURI)
        public
        onlyAdmin
    {
        baseTokenURI = _baseURI;
    }

    function setSampleURI(string memory sampleURI) public onlyAdmin {
        sampleTokenURI = sampleURI;
    }

    function totalToken() public view returns (uint256) {
        return tokenIdTracker;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

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

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (address)
    {
        return super.ownerOf(tokenId);
    }

    function mint(
        uint256 _tokenAmount,
        uint256 _timestamp,
        bytes memory _signature
    ) public payable saleIsOpen {
        uint256 total = totalToken();
        require(_tokenAmount <= LIMIT_PER_MINT, "MBH II: Max limit per mint");
        require(total + _tokenAmount <= MAX_ELEMENTS, "MBH II: Max limit");

        require(
            msg.value >= price(_tokenAmount),
            "Value below price"
        );

        address wallet = _msgSender();

        address signerOwner = signatureWallet(
            wallet,
            _tokenAmount,
            _timestamp,
            _signature
        );
        require(signerOwner == signerAddress, "MBH II: Not authorized to mint");

        require(_timestamp > lastCheckPoint[wallet], "MBH II: Invalid timestamp");

        lastCheckPoint[wallet] = block.timestamp;
        mintTokenCount[wallet] += _tokenAmount;

        tokenIdTracker = tokenIdTracker + _tokenAmount;
        _safeMint(wallet, _tokenAmount);
    }

    function signatureWallet(
        address wallet,
        uint256 _tokenAmount,
        uint256 _timestamp,
        bytes memory _signature
    ) public pure returns (address) {
        return
            ECDSA.recover(
                keccak256(abi.encode(wallet, _tokenAmount, _timestamp)),
                _signature
            );
    }

    function setCheckPoint(address _minter, uint256 _point) public onlyOwner {
        require(_minter != address(0), "MBH II: Unknown address");
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
        require(success, "MBH II: Transfer failed.");
    }

    function giftMint(address[] memory _addrs, uint256[] memory _tokenAmounts)
        public
        onlyAdmin
    {
        uint256 totalQuantity = 0;
        uint256 total = totalToken();
        for (uint256 i = 0; i < _addrs.length; i++) {
            totalQuantity += _tokenAmounts[i];
        }
        require(total + totalQuantity <= MAX_ELEMENTS, "MBH II: Max limit");

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
}