// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// @author: olive

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                                                          ///
///                                                            ___..............._                                           ///
///     /$$$$$$$   /$$$$$$   /$$$$$$                  __.. ' _'.""""""\\""""""""- .`-._                                      ///
///    | $$__  $$ /$$__  $$ /$$__  $$       ______.-'         (_) |      \\           ` \\`-. _                              ///
///    | $$  \ $$| $$  \__/| $$  \__/      /_       --------------'-------\\---....______\\__`.`  -..___                     ///
///    | $$  | $$| $$      | $$            | T      _.----._              |x...           |          _.._`--. _              ///
///    | $$  | $$| $$      | $$            | |    .' ..--.. `.            |XXXXXXXXXxx==  |       .'.---..`.     -._         ///
///    | $$  | $$| $$    $$| $$    $$      \_j   /  /  __  \  \           |XXXXXXXXXXX==  |      / /  __  \ \        `-.     ///
///    | $$$$$$$/|  $$$$$$/|  $$$$$$/       _|  |  |  /  \  |  |          |""'            |     / |  /  \  | |          |    ///
///    |_______/  \______/  \______/       |__\_j  |  \__/  |  L__________|_______________|_____j |  \__/  | L__________J    ///
///                                              `'\ \      / ./__________________________________\ \      / /___________\   ///
///                                                 `.`----'.'   dp                                `.`----'.'                ///
///                                                   `""""'                                         `""""'                  ///
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract DreamCarClub is ERC721AQueryable, Ownable, ReentrancyGuard {
    address private signerAddress;

    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_ELEMENTS = 21000;
    uint256 public PRICE = 0.18 ether;
    uint256 public constant START_AT = 1;
    uint256 public LIMIT_PER_MINT = 50;

    bool private PAUSE = true;

    uint256 private tokenIdTracker = 0;

    string public baseTokenURI1;
    string public baseTokenURI2;

    bool public META_REVEAL = false;
    uint256 public HIDE_FROM = 1;
    uint256 public HIDE_TO = 21000;
    string public sampleTokenURI;

    address public CROSSMINT_WALLET = 0xdAb1a1854214684acE522439684a145E62505233;
    address public constant creatorAddress = 0xacb59e6D6cB8E3bcb11B612269A2BAAC02C08764;

    mapping(address => bool) internal admins;
    mapping(address => uint256) mintTokenCount;
    mapping(address => uint256) lastCheckPoint;

    event PauseEvent(bool pause);
    event NewPriceEvent(uint256 price);
    event NewMaxElement(uint256 max);

    constructor(address _singenr)
        ERC721A("Dream Car Club NFTs", "DCC")
    {
        admins[msg.sender] = true;
        signerAddress = _singenr;
    }

    modifier saleIsOpen() {
        require(totalToken() <= MAX_ELEMENTS, "DCC: Soldout!");
        require(!PAUSE, "DCC: Sales not open");
        _;
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], "DCC: Caller is not the admin");
        _;
    }

    function setBaseURI(string memory _baseURI1, string memory _baseURI2)
        public
        onlyAdmin
    {
        baseTokenURI1 = _baseURI1;
        baseTokenURI2 = _baseURI2;
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

        string memory baseURI;
        if (tokenId <= (MAX_ELEMENTS / 2)) baseURI = baseTokenURI1;
        else baseURI = baseTokenURI2;
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
        require(_tokenAmount <= LIMIT_PER_MINT, "DCC: Max limit per mint");
        require(total + _tokenAmount <= MAX_ELEMENTS, "DCC: Max limit");

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
        require(signerOwner == signerAddress, "DCC: Not authorized to mint");

        require(_timestamp > lastCheckPoint[wallet], "DCC: Invalid timestamp");

        lastCheckPoint[wallet] = block.timestamp;
        mintTokenCount[wallet] += _tokenAmount;

        tokenIdTracker = tokenIdTracker + _tokenAmount;
        _safeMint(wallet, _tokenAmount);
    }

    function crossmint(address _to, uint256 _tokenAmount) public payable saleIsOpen {
        uint256 total = totalToken();
        require(_tokenAmount <= LIMIT_PER_MINT, "DCC: Max limit per mint");
        require(total + _tokenAmount <= MAX_ELEMENTS, "DCC: Max limit");

        require(
            msg.value >= price(_tokenAmount),
            "Value below price"
        );

        require(
            _msgSender() == CROSSMINT_WALLET,
            "DCC: This function is for Crossmint only."
        );

        tokenIdTracker = tokenIdTracker + _tokenAmount;
        _safeMint(_to, _tokenAmount);
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
        require(_minter != address(0), "DCC: Unknown address");
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
        require(success, "DCC: Transfer failed.");
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
        require(total + totalQuantity <= MAX_ELEMENTS, "DCC: Max limit");

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

    function updateCrossMintAddress(address _crossmintAddress)
        public
        onlyOwner
    {
        CROSSMINT_WALLET = _crossmintAddress;
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