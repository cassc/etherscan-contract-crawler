// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SuperRareMoonTryxterWambo is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    struct whitelist {
        address user;
        bool canMint;
        uint256 maxMintAmount;
    }

    mapping(address => whitelist) public whitelistMap;

    string public uriPrefix = "https://seashell-app-v4pim.ondigitalocean.app/";
    string public uriSuffix = "";
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    uint256 public maxMintAmountPerWallet;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        uint256 _maxMintAmountPerWallet,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        cost = _cost;
        maxSupply = _maxSupply;
        maxMintAmountPerTx = _maxMintAmountPerTx;
        maxMintAmountPerWallet = _maxMintAmountPerWallet;
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier iLoveYourMom(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount <= maxSupply, "Wambo dango");

        require(msg.value >= cost * _mintAmount, "eat my sack");
        _;
    }

    modifier iLoveMyMom(uint256 _mintAmount) {
        require(_mintAmount <= maxMintAmountPerTx, "fizz my jizz");
        require(
            balanceOf(msg.sender) + _mintAmount <= maxMintAmountPerWallet,
            "shit my sack before you get more"
        );
        _;
    }

    modifier iHaveApetfish() {
        require(
            whitelistMintEnabled,
            "BLAAAAHH BLOOOOOO HHHHHHHHHHHHHHHHHHHHHH!"
        );
        require(
            whitelistMap[msg.sender].canMint,
            "Why are you so fucking pretty"
        );
        _;
    }

    modifier willYouBeMyPoney() {
        require(!paused, "How are you my secret lover");
        _;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet)
        public
        onlyOwner
    {
        maxMintAmountPerWallet = _maxMintAmountPerWallet;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setWhiteListAddresses(address[] memory _addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistMap[_addresses[i]] = whitelist(_addresses[i], true, 0);
        }
    }

    function whitelistMint(uint256 _mintAmount)
        public
        payable
        iLoveYourMom(_mintAmount)
        iLoveMyMom(_mintAmount)
        iHaveApetfish
    {
        whitelistMap[_msgSender()] = whitelist(_msgSender(), false, 0);
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        iLoveYourMom(_mintAmount)
        iLoveMyMom(_mintAmount)
        willYouBeMyPoney
    {
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 iHaveABoat = balanceOf(_owner);
        uint256[] memory googleIsLying = new uint256[](iHaveABoat);
        uint256 whyAreYouEvenReadingThis = _startTokenId();
        uint256 pleaseStopSendingWind = 0;
        address maybeIShouldTellYouMyName;

        while (
            pleaseStopSendingWind < iHaveABoat &&
            whyAreYouEvenReadingThis <= maxSupply
        ) {
            TokenOwnership memory ownership = _ownerships[
                whyAreYouEvenReadingThis
            ];

            if (!ownership.burned && ownership.addr != address(0)) {
                maybeIShouldTellYouMyName = ownership.addr;
            }

            if (maybeIShouldTellYouMyName == _owner) {
                googleIsLying[pleaseStopSendingWind] = whyAreYouEvenReadingThis;

                pleaseStopSendingWind++;
            }

            whyAreYouEvenReadingThis++;
        }

        return googleIsLying;
    }

    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Please let me touch your feets!");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "bricks are not older then other rocks, change my mind";
    }
}