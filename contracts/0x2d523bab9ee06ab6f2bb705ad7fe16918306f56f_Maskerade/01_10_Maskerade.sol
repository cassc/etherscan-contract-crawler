// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Maskerade is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    // mint config

    //The masks are free
    uint256 public cost = 0 ether;
    uint256 public maxSupply = 1167;
    uint256 public maxMintAmount = 2;
    uint256 public maxPerTxn = 2;
    uint256 public maxFreeAmt = 0;

    bool public revealed = true;
    bool public paused = true;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _uriPrefix,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setHiddenMetadataUri(_hiddenMetadataUri);
        setUriPrefix(_uriPrefix);
        mintForAddress(15, msg.sender);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(!paused, "masks minting is paused...");
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "All masks are minted..."
        );
        require(
            _mintAmount > 0 && _mintAmount <= maxPerTxn,
            "Only 2 masks each time..."
        );
        require(
            _mintAmount > 0 &&
                numberMinted(msg.sender) + _mintAmount <= maxMintAmount,
            "Invalid number of masks or minted max masks..."
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        uint256 costToSubtract = 0;

        if (numberMinted(msg.sender) < maxFreeAmt) {
            uint256 freeMintsLeft = maxFreeAmt - numberMinted(msg.sender);
            costToSubtract = cost * freeMintsLeft;
        }

        require(
            msg.value >= cost * _mintAmount - costToSubtract,
            "Insufficient funds."
        );
        _;
    }

    // modifier mintPriceCompliance(uint256 _mintAmount) {
    //     require(
    //         msg.value >= cost * _mintAmount,
    //         "Insufficient funds."
    //     );
    //     _;
    // }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

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
                : "";
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function setMaxFreeAmt(uint256 _maxFreeAmt) public onlyOwner {
        maxFreeAmt = _maxFreeAmt;
    }

    function setMaxPerTxn(uint256 _maxPerTxn) public onlyOwner {
        maxPerTxn = _maxPerTxn;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
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

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}