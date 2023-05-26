// SPDX-License-Identifier: MIT

// @Author Manuel (ManuelH#0001)

pragma solidity ^ 0.8 .9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract GreatestGoats is ERC721A, Ownable {
    using Strings for uint256;

    bytes32 public holderSaleMerkleRoot = 0xd2fccaa49ee9d6be70d40d14e5d49e41535d9a353576e34bb93f75691755148b;
    uint256 private constant maxSupply = 4444;

    string public BaseURI = "ipfs://QmPjGAswMPAmeHGcvRZgxukrgaycQuEWYXjkoTUEnakyJP/";

    mapping(address => uint256) public hasHolderMinted;
    mapping(address => bool) public hasPublicMinted;

    bool isHoldersSaleActive = false;
    bool isPublicSaleActive = false;

    constructor() ERC721A("GreatestGoats", "GG"){}

    modifier noBots(){
        require(tx.origin == msg.sender, "Please be yourself, not a contract.");
        _;
    }
    function holderMint(uint256 _quantity, bytes32[] calldata proof) external noBots() {
        require(isHoldersSaleActive, "Holder sale has yet to be activated or already has been activated and is over.");
        require(hasHolderMinted[msg.sender] + _quantity <= 2, "You reached you're max mints");
        require(totalSupply() + _quantity <= maxSupply, "The supply cap is reached.");
        require(MerkleProof.verify(proof, holderSaleMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof");
        hasHolderMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function publicMint() external noBots() {
        require(isPublicSaleActive, "Public sale has yet to be activated or already has been activated and is over.");
        require(!hasPublicMinted[msg.sender], "You reached you're max mints");
        require(totalSupply() + 1 <= maxSupply, "The supply cap is reached.");
        hasPublicMinted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "URI query for non-existent token");
        return string(abi.encodePacked(BaseURI, _tokenId.toString(), ".json"));
    }

    function _startTokenId() internal view virtual override(ERC721A) returns(uint256) {
        return 1;
    }
    
    function setHolderSaleDetails(bytes32 _root) external onlyOwner {
      holderSaleMerkleRoot = _root;
    }
    function toggleHolderSaleActive() external onlyOwner {
        isHoldersSaleActive = !isHoldersSaleActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        BaseURI = _baseUri;
    }
}