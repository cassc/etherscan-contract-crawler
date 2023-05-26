// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DivineWolves is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    //Counters
    Counters.Counter internal _airdrops;

    address breedingContract;
    string public baseURI;
    string public notRevealedUri;
    bytes32 private whitelistRoot;

    //Inventory
    uint16 public maxMintAmountPerTransaction = 1;
    uint16 public maxMintAmountPerWallet = 1;
    uint256 public maxSupply = 3800;

    //Prices
    uint256 public cost = 0.07 ether;
    uint256 public whitelistCost = 0.07 ether;

    //Utility
    bool public paused = true;
    bool public revealed = false;
    bool public whiteListingSale = true;

    //mapping
    mapping(address => bool) private whitelistedMints;

    constructor(string memory _baseUrl, string memory _notRevealedUrl) ERC721("Divine Wolves", "TWV") {
uint256 supply = totalSupply();
baseURI = _baseUrl;
notRevealedUri = _notRevealedUrl;

for (uint256 i = 1; i <= 17; i++) {
_safeMint(msg.sender, supply + i);
}
}

    function setBreedingContractAddress(address _bAddress) public onlyOwner {
        breedingContract = _bAddress;
    }

    function mintExternal(address _address, uint256 _tokenId) external {
        require(msg.sender == breedingContract, "Sorry you dont have permission to mint");
        _safeMint(_address, _tokenId);
    }

    function setWhitelistingRoot(bytes32 _root) public onlyOwner {
        whitelistRoot = _root;
    }

    // Verify that a given leaf is in the tree.
    function _verify(bytes32 _leafNode, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, whitelistRoot, _leafNode);
    }

    // Generate the leaf node (just the hash of tokenID concatenated with the account address)
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    //whitelist mint
    function mintWhitelist(bytes32[] calldata proof) public payable {
        uint256 supply = totalSupply();
        if (msg.sender != owner()) {
            require(!paused);
            require(whiteListingSale, "Whitelisting not enabled");
            require(_verify(_leaf(msg.sender), proof), "Invalid proof");
            require(!whitelistedMints[msg.sender], "You have already Minted");
            require(msg.value >= whitelistCost, "Insuffcient funds");
        }

        _safeMint(msg.sender, supply + 1);
        whitelistedMints[msg.sender] = true;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();

        if (msg.sender != owner()) {
            uint256 ownerTokenCount = balanceOf(msg.sender);

            require(!paused);
            require(!whiteListingSale, "You cant mint on Presale");
            require(_mintAmount > 0, "Mint amount should be greater than 0");
            require(_mintAmount <= maxMintAmountPerTransaction, "Sorry you cant mint this amount at once");
            require(supply + _mintAmount <= maxSupply, "Exceeds Max Supply");
            require((ownerTokenCount + _mintAmount) <= maxMintAmountPerWallet, "Sorry you cant mint more");

            require(msg.value >= cost * _mintAmount, "Insuffcient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function gift(address _to, uint256 _mintAmount) public onlyOwner {
        uint256 supply = totalSupply();
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
            _airdrops.increment();
        }
    }

    function totalAirdrops() public view returns (uint256) {
        return _airdrops.current();
    }

    function airdrop(address[] memory _airdropAddresses) public onlyOwner {
        for (uint256 i = 0; i < _airdropAddresses.length; i++) {
            uint256 supply = totalSupply();
            address to = _airdropAddresses[i];
            _safeMint(to, supply + 1);
            _airdrops.increment();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getTotalMints() public view returns (uint256) {
        return totalSupply() - _airdrops.current();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (revealed == false) {
            return bytes(notRevealedUri).length > 0 ? string(abi.encodePacked(notRevealedUri, tokenId.toString())) : "";
        } else {
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function toggleReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setWhitelistingCost(uint256 _newCost) public onlyOwner {
        whitelistCost = _newCost;
    }

    function setmaxMintAmountPerTransaction(uint16 _amount) public onlyOwner {
        maxMintAmountPerTransaction = _amount;
    }

    function setMaxMintAmountPerWallet(uint16 _amount) public onlyOwner {
        maxMintAmountPerWallet = _amount;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function toggleWhiteSale() public onlyOwner {
        whiteListingSale = !whiteListingSale;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}