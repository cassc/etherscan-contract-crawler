// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 


contract LegendsTown is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    // ===Configuration===

    mapping(address => uint) public freeMint;
    string internal baseUri;
    uint256 public mintCost = 0.0077 ether;
    uint256 public maxSupply = 5555;
    uint256 public freeMintAmount = 1;
    uint256 public maxPerTXN = 10;
    bool private freeSale = false;
    bool public publicSale = false;
    bytes32 root;
    
    constructor() ERC721A("LegendsTown", "LT") {}
    
    // ===Mint Functions===

    function mintFree(bytes32[] memory proof) external nonReentrant {
        require(freeSale, "You cant mint yet.");
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))), "You are not whitelisted!");
        require(freeMint[msg.sender] < 1, "You've already minted your Free Legend.");
        require(totalSupply() + freeMintAmount <= maxSupply, "Max supply for Free mints has been reached.");
        freeMint[msg.sender] += freeMintAmount;
        _safeMint(msg.sender, freeMintAmount);

    }

    function mintPublic(uint256 _amount) external payable nonReentrant {
        require(publicSale, "Sale hasnt commenced yet.");
        require(_amount <= maxPerTXN && _amount > 0, "Max 10 per TXN.");
        require(_amount + totalSupply() <= maxSupply, "There's not enough supply left.");
        require(msg.value >= mintCost * _amount, "One Legend costs 0.0077 Ether.");
        _safeMint(msg.sender, _amount);
    }
    
    // ===Configuration functions===

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setMaxSupply(uint256 _newSupply) external onlyOwner {
        maxSupply = _newSupply;
    }
    
    function setMaxPerTXN(uint256 _maxTXN) external onlyOwner {
        maxPerTXN = _maxTXN;
    }

    function togglePublic() external onlyOwner {
        publicSale = !publicSale;
    }
    
    function toggleFree() external onlyOwner {
        freeSale = !freeSale;
    }
    
    function setCost(uint256 newCost) external onlyOwner {
        mintCost = newCost;
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

    function transferFunds() public onlyOwner {
	    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
    
}