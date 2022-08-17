//Collection Desc:

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TOPGDAO is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public uriPrefix = "ipfs://QmaffXTe4V4ZzmyKYdxbSbxMwj1RohpeCSYUYnq9vqfHzE/";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri = "ipfs://__CID__/hiddenMetadata.json";

    uint256 public cost = 0;
    uint256 public numFree = 2;
    uint256 public costNotFree = 0.0069 ether;
    uint256 public maxSupply = 969;
    uint256 public maxMintAmountPerTx = 4;

    bool public paused = true;
    bool public revealed = true;

    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC721A(_tokenName, _tokenSymbol)
    {}

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }
    
    function checkCost(uint256 _mintAmount)
        private
        view
        returns (uint256 price)
    {
        uint256 totalMints = _mintAmount + balanceOf(msg.sender);
        if (totalMints <= numFree) {
            return cost;
        } else if (balanceOf(msg.sender) >= numFree) {
            uint256 total = costNotFree * _mintAmount;
            return total;
        } else {
            uint256 total = costNotFree * (totalMints - numFree);
            return total;
        }
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        uint256 price = checkCost(_mintAmount);
        require(msg.value >= price, "Insufficient funds!");
        _;
    }


    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
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

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setCostNotFree(uint256 _cost) public onlyOwner {
        costNotFree = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
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

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}