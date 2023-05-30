//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Waifu is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost = 0.069 ether;
    uint256 public whitelistCost = 0.05 ether;
    uint256 public maxSupply = 2222;

    bool public paused = true;
    bool public revealed = false;
    bool public onlyWhitelisted = true;
    
    bytes32 public merkleRoot;

    address private a1 = 0x943405d0d429C865affcC487270A1cFE3a6B9A71;
    address private a2 = 0x38482Dc0050Dc32c66e41b9D5ae8b7383EC3bb49;
    address private a3 = 0xE9Cd9e74dA2c357B3A0423a06a33d5157B7280AE;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) {
        setHiddenMetadataUri("ipfs://QmWJ5BBdnm4ibqJkzkPchL5priksAgxCCAtsV9xk7Mycfe/hidden.json");
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(!paused, "Minting is not live yet");
        require(_totalMinted() + _mintAmount <= maxSupply, "Max supply exceeded!");
        uint256 actualCost = onlyWhitelisted ? whitelistCost : cost;
        require(msg.value >= actualCost * _mintAmount, "Insufficient funds!");
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");
        _safeMint(msg.sender, _mintAmount);
    }
  
    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
        _safeMint(msg.sender, _mintAmount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
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
        "ERC721AMetadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : "";
    }

    //only owner
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setWhitelistCost(uint256 _cost) public onlyOwner {
        whitelistCost = _cost;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
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

    function setOnlyWhitelist(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function withdraw() public payable onlyOwner {
        uint256 mintFees = address(this).balance;
        (bool hs, ) = payable(a1).call{value: mintFees * 5500 / 10000}("");
        require(hs);
        (bool os, ) = payable(a2).call{value: mintFees * 2250 / 10000}("");
        require(os);
        (bool ls, ) = payable(a3).call{value: mintFees * 2250 / 10000}("");
        require(ls);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}