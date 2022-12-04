// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/529cceeda9f5f8e28812c20042cc57626f784718/src/DefaultOperatorFilterer.sol";

contract Baninomado is ERC721A, DefaultOperatorFilterer, Ownable {

    string public baseURI = "ipfs://bafybeif6mzexubfdq7kiuvhabqqvfhacgrr3fs3zfinywrebihham6iriu/";  
    string public baseExtension = ".json";
    uint256 public price = 0 ether;
    uint256 public maxSupply = 4444;
    uint256 public maxPerTransaction = 1;
    uint256 public maxPerWallet = 1;
    mapping(address => uint256) usedWallet;

    constructor () ERC721A("Baninomado", "BNDO") {
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://Qmbyve9dd6vQ3iHckTjXuuy7kv3RgoQ2zzbs3UYL7NL3Mb/";
    }

    // Mint - Free 1 per wallet
    function publicMint(uint256 amount) public payable {
        require(amount + usedWallet[msg.sender] <= maxPerWallet, "Cannot mint more than 1 per wallet!");
        require(totalSupply() + amount <= maxSupply, "Sold Out!");
        uint256 mintAmount = amount;
        usedWallet[msg.sender] += mintAmount;
        
        if (msg.value >= price * mintAmount) {
            _safeMint(msg.sender, amount);
        }
    }    

    /////////////////////////////
    // CONTRACT MANAGEMENT 
    /////////////////////////////

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
        
	}
    
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    } 

    function setMaxPerWallet(uint256 newAmount) public onlyOwner {
        maxPerWallet = newAmount;
    }
    /////////////////////////////
    // OPENSEA FILTER REGISTRY 
    /////////////////////////////

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}