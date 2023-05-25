// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interface/IMLFieldAgents.sol";

// @author: olive

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                                        ///
///                                                                                                        ///
///    ooo        ooooo ooooo              .o.                                            .                ///
///    `88.       .888' `888'             .888.                                         .o8                ///
///     888b     d'888   888             .8"888.      .oooooooo  .ooooo.  ooo. .oo.   .o888oo  .oooo.o     ///
///     8 Y88. .P  888   888            .8' `888.    888' `88b  d88' `88b `888P"Y88b    888   d88(  "8     ///
///     8  `888'   888   888           .88ooo8888.   888   888  888ooo888  888   888    888   `"Y88b.      ///
///     8    Y     888   888       o  .8'     `888.  `88bod8P'  888    .o  888   888    888 . o.  )88b     ///
///    o8o        o888o o888ooooood8 o88o     o8888o `8oooooo.  `Y8bod8P' o888o o888o   "888" 8""888P'     ///
///                                                  d"     YD                                             ///
///                                                  "Y88888P'                                             ///
///                                                                                                        ///
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract MLSecretAgents is ERC721Enumerable, Ownable {
    address private signerAddress;

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public MAX_ELEMENTS = 9000;
    uint256 public MAX_ELEMENTS_COMMON = 4000;
    uint256 public PRICE = 1.5 ether;
    uint256 public constant START_AT = 1;
    uint256 public TIME_LIMIT = 60;
    uint256 public LIMIT_PER_MINT = 50;
    uint256 public mintedCommon = 0;

    IMLFieldAgents public fieldAgents;

    bool private PAUSE = true;
    bool private UPGRADE_PAUSE = true;

    Counters.Counter private _tokenIdTracker;

    string public baseTokenURI;

    bool public META_REVEAL = false;
    uint256 public HIDE_FROM = 1;
    uint256 public HIDE_TO = 9000;
    string public sampleTokenURI;

    address public constant creatorAddress =
        0xB9a02542e41DBEDaec5cF18030a3519ee0120a51;

    mapping(address => bool) internal admins;
    mapping(address => uint256) mintTokens;
    mapping(address => uint256) lastCheckPoint;

    event PauseEvent(bool pause);
    event UpgradePauseEvent(bool pause);
    event welcomeToLNS(uint256 indexed id);
    event NewPriceEvent(uint256 price);
    event NewMaxElement(uint256 max);

    constructor(address _singenr, IMLFieldAgents _mlagents)
        ERC721("Meta Labs Secret Agents", "MLA2")
    {
        signerAddress = _singenr;
        fieldAgents = _mlagents;
        admins[msg.sender] = true;
    }

    modifier saleIsOpen() {
        require(totalToken() <= MAX_ELEMENTS, "MLSecretAgents: Soldout!");
        require(!PAUSE, "MLSecretAgents: Sales not open");
        _;
    }

    modifier upgradeSaleIsOpen() {
        require(totalToken() <= MAX_ELEMENTS, "MLSecretAgents: Soldout!");
        require(!UPGRADE_PAUSE, "MLSecretAgents: Upgrade Sales not open");
        _;
    }

    modifier onlyAdmin() {
        require(
            admins[_msgSender()],
            "MLSecretAgents: Caller is not the admin"
        );
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyAdmin {
        baseTokenURI = baseURI;
    }

    function setSampleURI(string memory sampleURI) public onlyAdmin {
        sampleTokenURI = sampleURI;
    }

    function totalToken() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalMintedCommon() public view returns (uint256) {
        return mintedCommon;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!META_REVEAL && tokenId >= HIDE_FROM && tokenId <= HIDE_TO)
            return sampleTokenURI;

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function mintTokensOfWallet(address _wallet) public view returns (uint256) {
        return mintTokens[_wallet];
    }

    function upgradeMint(
        uint256[] calldata commonIds,
        uint256[] calldata goldenIds,
        uint256 _timestamp,
        bytes memory _signature
    ) public saleIsOpen {
        address wallet = _msgSender();
        address signerOwner = signatureWalletUpgrade(
            wallet,
            commonIds,
            goldenIds,
            _timestamp,
            _signature
        );
        require(signerOwner == signerAddress, "MLSecretAgents: Not authorized to mint");
        require(block.timestamp >= _timestamp - TIME_LIMIT, "MLSecretAgents: Out of time");
        require(
            commonIds.length.mod(5) == 0,
            "MLSecretAgents: Token data is not correct."
        );
        uint256 total = totalToken();
        uint256 mintAmount = 0;
        if (commonIds.length > 0) {
            for (uint8 i = 0; i < commonIds.length; i++) {
                require(commonIds[i] != 0, "Token Id can't be zero.");

                require(
                    fieldAgents.ownerOf(commonIds[i]) == msg.sender,
                    "MLSecretAgents: Caller is not owner."
                );
            }
            fieldAgents.burn(commonIds);
            mintAmount += commonIds.length.div(5);
        }

        if (goldenIds.length > 0) {
            for (uint8 i = 0; i < goldenIds.length; i++) {
                require(goldenIds[i] != 0, "Token Id can't be zero.");
                require(
                    fieldAgents.ownerOf(goldenIds[i]) == msg.sender,
                    "MLSecretAgents: You are not owner."
                );
                mintAmount++;
            }
            fieldAgents.burn(goldenIds);
        }

        require(mintAmount > 0, "MLSecretAgents: Mint amount can't be zero.");

        for (uint8 i = 1; i <= mintAmount; i++) {
            _mintAnElement(msg.sender, total + i);
        }
    }

    function signatureWalletUpgrade(
        address wallet,
        uint256[] calldata commonIds,
        uint256[] calldata goldenIds,
        uint256 _timestamp,
        bytes memory _signature
    ) public pure returns (address) {
        return
            ECDSA.recover(
                keccak256(abi.encode(wallet, commonIds, goldenIds, _timestamp)),
                _signature
            );
    }

    function mint(
        uint256 _tokenAmount,
        uint256 _timestamp,
        bytes memory _signature
    ) public payable saleIsOpen {
        uint256 total = totalToken();
        require(
            _tokenAmount <= LIMIT_PER_MINT,
            "MLSecretAgents: Max limit per mint"
        );
        require(
            total + _tokenAmount <= MAX_ELEMENTS,
            "MLSecretAgents: Max limit"
        );
        require(
            mintedCommon + _tokenAmount <= MAX_ELEMENTS_COMMON,
            "MLSecretAgents: Max limit Common mint"
        );
        require(
            msg.value >= price(_tokenAmount),
            "MLSecretAgents: Value below price"
        );

        address wallet = _msgSender();

        address signerOwner = signatureWallet(
            wallet,
            _tokenAmount,
            _timestamp,
            _signature
        );
        require(signerOwner == signerAddress, "Not authorized to mint");

        require(block.timestamp >= _timestamp - TIME_LIMIT, "Out of time");
        require(_timestamp > lastCheckPoint[wallet], "Invalid timestamp");

        lastCheckPoint[wallet] = block.timestamp;

        mintTokens[wallet] += _tokenAmount;
        mintedCommon += _tokenAmount;
        for (uint8 i = 1; i <= _tokenAmount; i++) {
            _mintAnElement(wallet, total + i);
        }
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
        require(_minter != address(0), "Unknown address");
        lastCheckPoint[_minter] = _point;
    }

    function getCheckPoint(address _minter) external view returns (uint256) {
        return lastCheckPoint[_minter];
    }

    function _mintAnElement(address _to, uint256 _tokenId) private {
        _tokenIdTracker.increment();
        _safeMint(_to, _tokenId);

        emit welcomeToLNS(_tokenId);
    }

    function price(uint256 _count) public view returns (uint256) {
        return PRICE.mul(_count);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function setPause(bool _pause) public onlyAdmin {
        PAUSE = _pause;
        emit PauseEvent(PAUSE);
    }

    function setUpgradePause(bool _pause) public onlyAdmin {
        UPGRADE_PAUSE = _pause;
        emit UpgradePauseEvent(UPGRADE_PAUSE);
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
        emit NewPriceEvent(PRICE);
    }

    function setMaxElement(uint256 _max) public onlyOwner {
        MAX_ELEMENTS = _max;
        emit NewMaxElement(MAX_ELEMENTS);
    }

    function setMaxElementCommon(uint256 _max) public onlyAdmin {
        MAX_ELEMENTS_COMMON = _max;
        emit NewMaxElement(MAX_ELEMENTS_COMMON);
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
        require(success, "Transfer failed.");
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
        require(total + totalQuantity <= MAX_ELEMENTS, "Max limit");
        for (uint256 i = 0; i < _addrs.length; i++) {
            for (uint256 j = 0; j < _tokenAmounts[i]; j++) {
                total++;
                _mintAnElement(_addrs[i], total);
            }
        }
    }

    function mintUnsoldTokens(uint256[] memory _tokensId) public onlyOwner {
        require(PAUSE, "Pause is disable");

        for (uint256 i = 0; i < _tokensId.length; i++) {
            if (rawOwnerOf(_tokensId[i]) == address(0)) {
                _mintAnElement(owner(), _tokensId[i]);
            }
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

    function burn(uint256 tokenId) external onlyAdmin {
        _burn(tokenId);
    }

    function updateTimeLimit(uint256 _timeLimit) public onlyAdmin {
        TIME_LIMIT = _timeLimit;
    }

    function updateSignerAddress(address _signer) public onlyOwner {
        signerAddress = _signer;
    }

    function updateLimitPerMint(uint256 _limitpermint) public onlyAdmin {
        LIMIT_PER_MINT = _limitpermint;
    }

    function setMLAgents1Contract(IMLFieldAgents _fieldAgents)
        public
        onlyOwner
    {
        fieldAgents = _fieldAgents;
    }
}