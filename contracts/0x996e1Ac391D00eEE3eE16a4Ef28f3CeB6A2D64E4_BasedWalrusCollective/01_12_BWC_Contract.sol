// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BasedWalrusCollective is ERC721, Ownable {

	using ECDSA for bytes32;
	using Strings for uint;
    
    uint constant MAX_BWC = 3333;
    uint constant maxPurchase = 10;
    uint constant maxPresalePurchase = 2;
    uint constant maxPerWallet = 50;
    uint constant maxPerWalletPresale = 2;
	uint constant basePrice = 40000000000000000; // 0.04 ETH
	
	uint public bwcPrice = 40000000000000000; // 0.04 ETH
	uint public preSalePrice = 30000000000000000; // 0.03 ETH
	uint public totalSupply;
    
	mapping(address => uint) public addressMintedAmount;
    bool public revealed = false;
	uint8 public saleStatus = 0;
	
	address private authorizedSigner;
	address private projectManager;
	address private developer;
	
    string private baseURI;
	string private baseExtension = ".json";
	string private notRevealedUri;
	
	modifier overallSupplyCheck() {
		
        require(totalSupply < MAX_BWC, "All NFTs have been minted");
        _;
    }
	
	modifier onlyTeam() {
		
        require(
			msg.sender == owner() ||
			msg.sender == projectManager ||
			msg.sender == developer,
			"Not a team member"
		);
        _;
    }

    constructor(address pm, address dev) ERC721("Based Walrus Collective", "BWC") {
		        
		projectManager = pm;
		developer = dev;
    }
	
	function remainingNFTs() private view returns (string memory) {
		
        return string(abi.encodePacked("There are only ", (MAX_BWC - totalSupply).toString(), " NFTs left in supply"));
    }
	
	function tokenURI(uint tokenId) public view virtual override returns (string memory) {
		
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if(!revealed) {
            return notRevealedUri;
        }

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension))
            : "";
    }    

	function hashTransaction(address minter) private pure returns (bytes32) {
		
        bytes32 argsHash = keccak256(abi.encodePacked(minter));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", argsHash));
    }

    function recoverSignerAddress(address minter, bytes memory signature) private pure returns (address) {
		
        bytes32 hash = hashTransaction(minter);
        return hash.recover(signature);
    }

    function presale(uint amount, bytes memory signature) external payable overallSupplyCheck {
		
		require(saleStatus == 1, "Presale is not active");
		require(recoverSignerAddress(msg.sender, signature) == authorizedSigner, "Wallet not authorized to mint during presale");
		require(amount > 0 && amount <= maxPresalePurchase, "Must mint between 1 and 2 NFTs during presale");
		require(addressMintedAmount[msg.sender] + amount <= maxPerWalletPresale, "Maximum 2 NFTs per wallet during presale");

        mintBWC(amount);
    }

    function mint(uint amount) external payable overallSupplyCheck {
		
        require(saleStatus == 2, "Public sale is not active");
		require(amount > 0 && amount <= maxPurchase, "Must mint between 1 and 10 NFTs");
		require(addressMintedAmount[msg.sender] + amount <= maxPerWallet, "Maximum 50 NFTs per wallet during presale");

        mintBWC(amount);
    }

    function mintBWC(uint mintAmount) internal {
        
        require(totalSupply + mintAmount <= MAX_BWC, remainingNFTs());
        require(msg.value >= (bwcPrice * mintAmount), string(abi.encodePacked("Incorrect ether amount for ", mintAmount.toString(), " NFT", (mintAmount > 1 ? "s" : ""))));
        
		uint currSupply = totalSupply;
		
		totalSupply += mintAmount;
		
        for (uint i = 1; i <= mintAmount; i++) {
            addressMintedAmount[msg.sender]++;
            _safeMint(msg.sender, currSupply + i);
        }
    }
	
	// onlyTeam
	function configureURIS(string memory newBaseURI, string memory notRevealedURI) external onlyTeam {
		
        setBaseURI(newBaseURI);
        setNotRevealedURI(notRevealedURI);
    }	
	
    function setBaseURI(string memory newBaseURI) public onlyTeam {
		
        baseURI = newBaseURI;
    }
	
	function setNotRevealedURI(string memory notRevealedURI) public onlyTeam {
		
        notRevealedUri = notRevealedURI;
    }
	
	function setAuthorizedSigner(address authSigner) external onlyTeam {
		
        authorizedSigner = authSigner;
    }
	
	function setPrice(uint price) external onlyTeam {
		
        require(price > 10000000000000000, "Price must be greater than 0.01 ether, set in wei");

        bwcPrice = price;
    }

    function setBaseExtension(string memory newBaseExtension) external onlyTeam {
		
        baseExtension = newBaseExtension;
    }
    
    function setRevealed() external onlyTeam {
		
        revealed = true;
    }
    
    function setSaleStatus(uint8 status) external onlyTeam {
		
		require(status == 0 || status == 1 || status == 2, "Invalid sale status");
		if (status == 0 || status == 2) { // Reset to base price
			bwcPrice = basePrice;
		}
		else { // Presale price
			bwcPrice = preSalePrice;
		}
        saleStatus = status;
    }
    
    function withdraw() external onlyTeam {
        
		uint balance = address(this).balance;
        uint splitBalance = balance * 50 / 100;
        payable(projectManager).transfer(splitBalance);
        payable(developer).transfer(balance - splitBalance);
    }
	
	// onlyOwner
	// Used to set aside a specified number of NFTs to transfer to mods, grandma and grandpa, other pillars of the community, etc.
	
    function mintGifts(uint giftAmount) external onlyOwner overallSupplyCheck {
				
        require(giftAmount > 0 && giftAmount <= 20, "Can only mint between 1 and 20 gift NFTs at a time");
		require(totalSupply + giftAmount <= MAX_BWC, remainingNFTs());

		uint currSupply = totalSupply;
		
		totalSupply += giftAmount;
		
        for (uint i = 1; i <= giftAmount; i++) {
            _safeMint(msg.sender, currSupply + i);
        }
    }
}