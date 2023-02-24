//SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.7;  
  
import "erc721a/contracts/ERC721A.sol";  
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./../DefaultOperatorFilterer.sol";

contract YecheLangeSchoolOfTruth is ERC721A, DefaultOperatorFilterer, ERC2981, Ownable, ReentrancyGuard {  
    using Counters for Counters.Counter;
    
    address public royaltySplit;

    string public baseURI;

    bool public baseURILocked = false;

    uint96 private royaltyBps = 1000;

    constructor() ERC721A("YecheLangeSchoolOfTruth", "TRUTH") {} 

    function mint(uint256 quantity) public payable nonReentrant onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    function updateRoyalty(uint96 _royaltyBps) public onlyOwner {
        require(royaltySplit!=address(0), "split address not set, please set split address before updating royalty");
        royaltyBps = _royaltyBps;
        _setDefaultRoyalty(royaltySplit, royaltyBps);
    }

    function updateBaseURI(string calldata givenBaseURI) public onlyOwner {
        require(!baseURILocked, "base uri locked");
       
        baseURI = givenBaseURI;
    }

    function lockBaseURI() public onlyOwner {
        baseURILocked = true;
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, Strings.toString(tokenID)));
    }
 
    function setSplitAddress(address _address) public onlyOwner {
        royaltySplit = _address;
        _setDefaultRoyalty(royaltySplit, royaltyBps);
    }

    function withdraw() public onlyOwner {
        require(royaltySplit != address(0), "split address not set");

        (bool success, ) = royaltySplit.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // Opensea Operator filter registry
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

    function supportsInterface(
    bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }
}