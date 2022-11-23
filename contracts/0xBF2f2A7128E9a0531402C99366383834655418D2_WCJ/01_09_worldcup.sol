// SPDX-License-Identifier: MIT
//
//          [email protected]@@                                                                  
//               ,@@@@@@@&,                  #@@%                                  
//                    @@@@@@@@@@@@@@.          @@@@@@@@@                           
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      
//                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   
//                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                 
//                                    @@@@@@@    &@@@@@@@@@@@@@@@@@                
//                                        @@@/        &@@@@@@@@@@@@@,              
//                                            @            @@@@@@@@@@@             
//                                                             /@@@@@@@#           
//                                                                  @@@@@          
//                                                                      *@&   
//         RTFKT Studios (https://twitter.com/RTFKT)
//         WCJ Contract (made by @CardilloSamuel)

/**
    RTFKT Legal Overview [https://rtfkt.com/legaloverview]
    1. RTFKT Platform Terms of Services [Document #1, https://rtfkt.com/tos]
    2. End Use License Terms
    A. Digital Collectible Terms (RTFKT-Owned Content) [Document #2-A, https://rtfkt.com/legal-2A]
    B. Digital Collectible Terms (Third Party Content) [Document #2-B, https://rtfkt.com/legal-2B]
    C. Digital Collectible Limited Commercial Use License Terms (RTFKT-Owned Content) [Document #2-C, https://rtfkt.com/legal-2C]
    D. Digital Collectible Terms [Document #2-D, https://rtfkt.com/legal-2D]
    
    3. Policies or other documentation
    A. RTFKT Privacy Policy [Document #3-A, https://rtfkt.com/privacy]
    B. NFT Issuance and Marketing Policy [Document #3-B, https://rtfkt.com/legal-3B]
    C. Transfer Fees [Document #3C, https://rtfkt.com/legal-3C]
    C. 1. Commercialization Registration [https://rtfkt.typeform.com/to/u671kiRl]
    
    4. General notices
    A. Murakami Short Verbiage – User Experience Notice [Document #X-1, https://rtfkt.com/legal-X1]
**/

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/529cceeda9f5f8e28812c20042cc57626f784718/src/DefaultOperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";

contract WCJ is ERC721A, DefaultOperatorFilterer, Ownable {
    bytes32 public merkleRoot = 0x03765987128374056d5408648f16e2642773556c1ae79e5c9582b9a9dd5a2d62;
    mapping (address => bool) public minterAddress;
    string metadataURI;
    bool public mintIsOpen;
    uint256 public forgePrice = 0;
    uint256 public constant MAX_SUPPLY = 3333;

    constructor () ERC721A("WCJ", "WCJ") {
        mintIsOpen = true;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Mint
    function forgeToken(bytes32[] calldata _merkleProof) public payable {
        require(mintIsOpen, "Mint is not open for now");
        require(isWinner(_merkleProof), "Invalid proof");
        require(!minterAddress[msg.sender], "Already minted");
        require(msg.value == forgePrice, "Wrong price");
        require(_totalMinted() < MAX_SUPPLY, "No remaining supply");

        minterAddress[msg.sender] = true;

        _safeMint(msg.sender, 1); // Minting of the token
    }

    function airdropToken(uint256[] calldata amount, address[] calldata owners) public onlyOwner {
        for(uint256 i = 0; i < owners.length; ++i) {            
            _safeMint(owners[i], amount[i]); // Minting of the token
        }
    }

    function isWinner(bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return (MerkleProof.verify(_merkleProof, merkleRoot, leaf)) ? true : false;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return metadataURI;
    }

    /////////////////////////////
    // CONTRACT MANAGEMENT 
    /////////////////////////////

    function toggleMint() public onlyOwner {
        mintIsOpen = !mintIsOpen;
    }

    function setForgePrice(uint256 newPrice) public onlyOwner {
        forgePrice = newPrice;
    }

    function setMetadataURI(string calldata newURI) public onlyOwner {
        metadataURI = newURI;
    }

    function changeMerkleRoot(bytes32 newRoot) public onlyOwner {
        merkleRoot = newRoot;
    }

    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	} 

    /////////////////////////////
    // OPENSEA FILTER REGISTRY 
    /////////////////////////////

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}