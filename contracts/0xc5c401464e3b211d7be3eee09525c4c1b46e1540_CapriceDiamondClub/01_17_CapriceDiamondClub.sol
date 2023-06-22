/*

*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract CapriceDiamondClub is ERC721, Ownable, DefaultOperatorFilterer {
    using Strings for uint;
    using Counters for Counters.Counter;
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }

    Counters.Counter private _tokenIds;

    uint public constant COLLECTION_SIZE = 100;
    
    uint public constant TOKENS_PER_TRAN_LIMIT = 10;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 10;
    uint public constant TOKENS_PER_PERSON_WL_LIMIT = 25;
    uint public constant PRESALE_MINT_PRICE = 1 ether;
    uint public MINT_PRICE = 1 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    bytes32 public merkleRoot;
    string private _baseURL = "ipfs://bafybeifpmdfkftb4pcaroixl3ckkbedsfwd74xaiubj5grmvwykiqz7gty";
    
    mapping(address => uint) private _mintedCount;
    mapping(address => uint) private _whitelistMintedCount;

    constructor() ERC721("CapriceDiamondClub", "DIAMANT"){}
    
    
    function contractURI() public pure returns (string memory) {
        return "data:application/json;base64,eyJuYW1lIjoiQ2FwcmljZSBBLkkuIERpYW1vbmQgQ2x1YiIsImRlc2NyaXB0aW9uIjoiQ2FwcmljZSBBLkkuIERpYW1vbmQgQ2x1YiBtZW1iZXJzaGlwIGdpdmVzIHlvdSBleGNsdXNpdmUgYmVuZWZpdHMgd2l0aGluIHRoZSBDYXByaWNlIEEuSS4gZWNvc3lzdGVtLiBcblxuQnkgYmVpbmcgYSBEaWFtb25kIENsdWIgbWVtYmVyLCB5b3Ugb3duIDAuMiUgb2YgQ2FwcmljZSBBLkkuIGFuZCBhcmUgaW5jbHVkZWQgaW4gb3VyIG1vbnRobHkgcHJvZml0IHNoYXJpbmcgcHJvZ3JhbS4gWW91IGFyZSBhbHNvIGdpdmVuIHByaW9yaXR5IGxpZmV0aW1lIGFjY2VzcyB0byBhbGwgdXRpbGl0eSByZWxlYXNlcyBhcyB3ZWxsIGFzIGZyZWUgYWNjZXNzIHRvIENhcHJpY2UtcG93ZXJlZCBhZHVsdCBlc3RhYmxpc2htZW50cyBpbiBmdXR1cmUgTWV0YXZlcnNlIGludGVncmF0aW9ucy4gXG5cbkFzIGljaW5nIG9uIHRoZSBjYWtlLCB5b3VyIERpYW1vbmQgQ2x1YiBORlQgZ2l2ZXMgeW91IGFjY2VzcyB0byBleGNsdXNpdmUgMS1vbi0xIGxpZmVzdHlsZSBjb2FjaGluZy4iLCJleHRlcm5hbF91cmwiOiJodHRwczovL3d3dy5jYXByaWNlLmFpIiwiZmVlX3JlY2lwaWVudCI6IjB4NzRGYzExMjEyQjU2YWQyQmRhZDY5MTcyODJENDlDQmRkNTk3NjhjOSIsInNlbGxlcl9mZWVfYmFzaXNfcG9pbnRzIjozMDB9";
    }
    
    /// @notice Update the merkle tree root
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
    
    
    
    /// @notice Set base metadata URL
    function setBaseURL(string calldata url) external onlyOwner {
        _baseURL = url;
    }


    function totalSupply() external view returns (uint) {
        return _tokenIds.current();
    }

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    /// @notice Update current sale stage
    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }

    /// @notice Update public mint price
    function setPublicMintPrice(uint price) external onlyOwner {
        MINT_PRICE = price;
    }

    /// @notice Withdraw contract balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");
        payable(owner()).transfer(balance);
    }

    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "Request exceeds collection size");
        _mintTokens(to, count);
    }

    /// @notice Get token URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json")) 
            : "";
    }
    
    function calcTotal(uint count) public view returns(uint) {
        require(saleStatus != SaleStatus.PAUSED, "CapriceDiamondClub: Sales are off");

        

        
        uint price = saleStatus == SaleStatus.PRESALE 
            ? PRESALE_MINT_PRICE 
            : MINT_PRICE;

        return count * price;
    }
    
    
    function redeem(bytes32[] calldata merkleProof, uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "CapriceDiamondClub: Sales are off");
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "CapriceDiamondClub: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT, "CapriceDiamondClub: Number of requested tokens exceeds allowance (10)");
        require(msg.value >= calcTotal(count), "CapriceDiamondClub: Ether value sent is not sufficient");
        if(saleStatus == SaleStatus.PRESALE) {
            require(_whitelistMintedCount[msg.sender] + count <= TOKENS_PER_PERSON_WL_LIMIT, "CapriceDiamondClub: Number of requested tokens exceeds allowance (25)");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "CapriceDiamondClub: You are not whitelisted");
            _whitelistMintedCount[msg.sender] += count;
        }
        else {
            require(_mintedCount[msg.sender] + count <= TOKENS_PER_PERSON_PUB_LIMIT, "CapriceDiamondClub: Number of requested tokens exceeds allowance (10)");
            _mintedCount[msg.sender] += count;
        }
        _mintTokens(msg.sender, count);
    }
    
    /// @dev Perform actual minting of the tokens
    function _mintTokens(address to, uint count) internal {
        for(uint index = 0; index < count; index++) {

            _tokenIds.increment();
            uint newItemId = _tokenIds.current();

            _safeMint(to, newItemId);
        }
    }

    /// @notice DefaultOperatorFilterer OpenSea overrides    
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