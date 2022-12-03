// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/529cceeda9f5f8e28812c20042cc57626f784718/src/DefaultOperatorFilterer.sol";

contract CycleAbstractions is ERC721A, DefaultOperatorFilterer, Ownable {

    string public baseURI = "ipfs://bafybeigthfxipkea6nxe5go5u62w3izgedwc26vxjkmdc5o2vae55i4u34/";  
    string public baseExtension = ".json";
    uint256 public price = 0.005 ether;
    uint256 public maxSupply = 333;
    uint256 public maxPerTransaction = 1;
    uint256 public maxPerWallet = 1;
    mapping(address => uint256) usedWallet;

    constructor () ERC721A("Cycle Abstractions by Onna", "CYCLE") {
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://bafkreicjtfy4mqqmkax3ny2eklo6imxc2qpz3qlig5lzluamrlw53xpkxy";
    }

    // Mint - 0.005 eth 1 per wallet
    function publicMint(uint256 amount) public payable {
        require(amount + usedWallet[msg.sender] <= maxPerWallet, "Cannot mint more than 1 per wallet!");
        require(totalSupply() + amount <= maxSupply, "Sold Out!");
        uint256 mintAmount = amount;
        usedWallet[msg.sender] += mintAmount;
        

        require(msg.value > 0, "Insufficient Value!");
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