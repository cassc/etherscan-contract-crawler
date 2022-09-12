/*
 /$$$$$$$$                                /$$$$$$                  /$$           /$$   /$$ /$$$$$$$$ /$$$$$$$$
|_____ $$                                /$$__  $$                | $$          | $$$ | $$| $$_____/|__  $$__/
     /$$/   /$$$$$$   /$$$$$$   /$$$$$$ | $$  \__/  /$$$$$$   /$$$$$$$  /$$$$$$ | $$$$| $$| $$         | $$
    /$$/   /$$__  $$ /$$__  $$ /$$__  $$| $$       /$$__  $$ /$$__  $$ /$$__  $$| $$ $$ $$| $$$$$      | $$
   /$$/   | $$$$$$$$| $$  \__/| $$  \ $$| $$      | $$  \ $$| $$  | $$| $$$$$$$$| $$  $$$$| $$__/      | $$
  /$$/    | $$_____/| $$      | $$  | $$| $$    $$| $$  | $$| $$  | $$| $$_____/| $$\  $$$| $$         | $$
 /$$$$$$$$|  $$$$$$$| $$      |  $$$$$$/|  $$$$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$| $$ \  $$| $$         | $$
|________/ \_______/|__/       \______/  \______/  \______/  \_______/ \_______/|__/  \__/|__/         |__/

Drop Your NFT Collection With ZERO Coding Skills at https://zerocodenft.com
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DucksRevolution is ERC721, Ownable {
    using Strings for uint;
    using Counters for Counters.Counter;
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }

    Counters.Counter private _tokenIds;

    uint public constant COLLECTION_SIZE = 10001;
    
    uint public constant TOKENS_PER_TRAN_LIMIT = 100;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 100;
    uint public constant TOKENS_PER_PERSON_WL_LIMIT = 10;
    uint public constant PRESALE_MINT_PRICE = 0.0001 ether;
    uint public MINT_PRICE = 0.05 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    bytes32 public merkleRoot;
    string private _baseURL = "ipfs://bafybeie3zkom5hn3a7timqrm454ltnneiwr2ds3vya7zy3wcxxbyvvhhau/";
    
    mapping(address => uint) private _mintedCount;
    mapping(address => uint) private _whitelistMintedCount;

    constructor() ERC721("DucksRevolution", "DR"){}
    
    
    function contractURI() public pure returns (string memory) {
        return "data:application/json;base64,eyJuYW1lIjoiRHVja3MgUmV2b2x1dGlvbiIsImRlc2NyaXB0aW9uIjoiVGhlIER1Y2tzIFJldm9sdXRpb24gaXMgYSBjb2xsZWN0aW9uIG9mIDEwLDAwMSByYXJlIGFuZCB1bmlxdWUgRHVjayBORlRzIGFuZCB0aGUgZmlyc3Qgb2YgdGhlaXIga2luZC4gUmViZWxsaW91cyBkdWNrcyBhcmUgbGl2aW5nIG9uIHRoZSBFdGhlcmV1bSBibG9ja2NoYWluIGJ1aWxkaW5nIHRoZWlyIG5ldyBNZXRhdmVyc2Ugc29jaWV0eSwgYSBzb2NpZXR5IHRoYXQgd2lsbCBsZWFkIHRoZSBuZXcgZXJhIG9mIHRoZSBUaGlyZCB3ZWIuIERvbnQgZm9yZ2V0IHRoYXQgb3VyIHZpcnR1YWwgc29jaWV0eSBpcyBjb21pbmcgc29vbiB3aXRoIHRoZSBlcXVpcG1lbnQgdGhhdCBvdXIgdGVhbSB3aWxsIGRyb3Agb3V0IGZvciBlYWNoIGR1Y2sgb3duZXIiLCJleHRlcm5hbF91cmwiOiJodHRwczovL29wZW5zZWEuaW8vY29sbGVjdGlvbi9yZWJlbGxpb3VzLXdlYXBvbnMiLCJmZWVfcmVjaXBpZW50IjoiMHg4MDIyNkU0N0YwYjQwMWMyYzhjOGI0Qzg2ZGQwMzQ2NUMxNWZhMTYxIiwic2VsbGVyX2ZlZV9iYXNpc19wb2ludHMiOjUwMH0=";
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
        require(saleStatus != SaleStatus.PAUSED, "DucksRevolution: Sales are off");

        

        
        uint price = saleStatus == SaleStatus.PRESALE 
            ? PRESALE_MINT_PRICE 
            : MINT_PRICE;

        return count * price;
    }
    
    
    function redeem(bytes32[] calldata merkleProof, uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "DucksRevolution: Sales are off");
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "DucksRevolution: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT, "DucksRevolution: Number of requested tokens exceeds allowance (100)");
        require(msg.value >= calcTotal(count), "DucksRevolution: Ether value sent is not sufficient");
        if(saleStatus == SaleStatus.PRESALE) {
            require(_whitelistMintedCount[msg.sender] + count <= TOKENS_PER_PERSON_WL_LIMIT, "DucksRevolution: Number of requested tokens exceeds allowance (10)");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "DucksRevolution: You are not whitelisted");
            _whitelistMintedCount[msg.sender] += count;
        }
        else {
            require(_mintedCount[msg.sender] + count <= TOKENS_PER_PERSON_PUB_LIMIT, "DucksRevolution: Number of requested tokens exceeds allowance (100)");
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
}