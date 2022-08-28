// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 


contract Bearfrenz is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    // ===Configuration===

    mapping(address => uint) public freeMint;
    mapping(address => uint) public wlMint;
    string internal baseUri;
    uint256 public publicCost = 0.006 ether;
    uint256 public whitelistCost = 0.0055 ether;
    uint256 public publicSupply = 4000;
    uint256 public maxTotalSupply = 5555;
    uint256 public VIPAmount = 1;
    uint256 public WLAmount = 5;
    uint256 public maxPerTXN = 5;
    bool public freeSale = false;
    bool public publicSale = false;
    bool public metadataReveal = false;
    bytes32 rootVIP;
    bytes32 rootWL;
    
    constructor() ERC721A("Bearfrenz", "BFZ") {}
    
    // ===Mint Functions===

    function mintVIP(bytes32[] memory proof) external nonReentrant {
        require(freeSale, "Mint hasn't commenced yet.");
        require(MerkleProof.verify(proof, rootVIP, keccak256(abi.encodePacked(msg.sender))), "You're not eligible.");
        require(freeMint[msg.sender] < 1, "You've already minted one Free Bear.");
        require(totalSupply() + VIPAmount <= maxTotalSupply, "There's not enough supply left.");
        freeMint[msg.sender] += VIPAmount;
        _safeMint(msg.sender, VIPAmount);

    }

    function mintWL(bytes32[] memory proof, uint256 _amount) external payable nonReentrant {
        require(publicSale, "Mint hasn't commenced yet.");
        require(MerkleProof.verify(proof, rootWL, keccak256(abi.encodePacked(msg.sender))), "You're not eligible.");
        require(_amount <= WLAmount && _amount > 0, "You can mint a maximum of 10 per transaction.");
        require(_amount + wlMint[msg.sender]  <= WLAmount, "You've already minted your nfts..");
        require(totalSupply() + _amount <= publicSupply, "There's not enough supply left.");
        require(msg.value >= whitelistCost * _amount, "It costs 0.0055 to mint a NFT for whitelisted bears.");
        wlMint[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function mintPublic(uint256 _amount) external payable nonReentrant {
        require(publicSale, "Mint hasn't commenced yet.");
        require(_amount <= maxPerTXN && _amount > 0, "You can mint a maximum of 10 per transaction.");
        require(_amount + totalSupply() <= publicSupply, "There's not enough supply left.");
        require(msg.value >= publicCost * _amount, "It costs 0.006 to mint a bear in the public sale.");
        _safeMint(msg.sender, _amount);
    }
    
    // ===Configuration functions===

    function setRootWL(bytes32 _merkleRoot) external onlyOwner {
        rootWL = _merkleRoot;
    }

    function setRootVIP(bytes32 _merkleRoot) external onlyOwner {
        rootVIP = _merkleRoot;
    }

    function setMaxTotalSupply(uint256 _supply) external onlyOwner {
        maxTotalSupply = _supply;
    }
    

    function setPublicSupply(uint256 _supply) external onlyOwner {
        publicSupply = _supply;
    }
    
    function setMaxPerTXN(uint256 _pertxn) external onlyOwner {
        maxPerTXN = _pertxn;
    }

    function togglePublicWL() external onlyOwner {
        publicSale = !publicSale;
    }
    
    function toggleFree() external onlyOwner {
        freeSale = !freeSale;
    }
    
    function setPublicCost(uint256 _cost) external onlyOwner {
        publicCost = _cost;
    }
    
    function setWhitelistCost(uint256 _cost) external onlyOwner {
        whitelistCost = _cost;
    }

    // ===Metadata functions====

    function setMetadata(string calldata newUri) external onlyOwner {
        baseUri = newUri;
    }
    
    function _baseURI() internal override view returns (string memory) {
        return baseUri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : '';
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    

    // ===Funds withdrawal===

    function withdrawFunds() public onlyOwner {
	    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
    
}