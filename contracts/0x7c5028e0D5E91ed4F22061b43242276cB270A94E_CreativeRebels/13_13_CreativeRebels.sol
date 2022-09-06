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


contract CreativeRebels is ERC721, Ownable {
    using Strings for uint;
    using Counters for Counters.Counter;
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }

    Counters.Counter private _tokenIds;

    uint public constant COLLECTION_SIZE = 9595;
    
    uint public constant TOKENS_PER_TRAN_LIMIT = 10;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 250;
    
    
    uint public MINT_PRICE = 0.01995 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    
    string private _baseURL = "ipfs://bafybeiart7ijea7fzpnx7wmzr4zrm5v2lewsbscnx6zjnmaj6svf6pxw4a/";
    
    mapping(address => uint) private _mintedCount;
    

    constructor() ERC721("CreativeRebels", "CR"){}
    
    
    function contractURI() public pure returns (string memory) {
        return "data:application/json;base64,eyJuYW1lIjoiQ3JlYXRpdmUgUmViZWxzIiwiZGVzY3JpcHRpb24iOiJMZXZlbCB1cCB5b3VyIHdhbGxldCB3aXRoIG9uZSBvciBtb3JlIE5GVHMgb2YgdGhlIENyZWF0aXZlIFJlYmVscyBieSBLb2Noc3RyYXNzZS4gT3VyIHNxdWFkIG9mIDcwKyBjcmVhdGl2ZSBtYXN0ZXJtaW5kcyBhcmUgbW9yZSB0aGFuIGV4Y2l0ZWQgdG8gZmluYWxseSBzaGFyZSB3aXRoIHlvdSBvdXIgZmlyc3QsIHZlcnktdW5pcXVlLCBORlQgQ29sbGVjdGlvbi4gU28gZG9u4oCZdCB3YXN0ZSBhbm90aGVyIHNlYyBhbmQgR0VUIFlPVVIgUkVCRUwgT04hIEluIGEgd29ybGQgZnVsbCBvZiBiYXNpYyBjb3B5Y2F0cywgYmUgYSBSZWJlbCEgQnV0IG1pbmQgeW91OiB0aGUgQ1JFQVRJVkUgUkVCRUxTIGlzIG1vcmUgdGhhbiBqdXN0IGEgY29sbGVjdGlvbiBvZiBwcm9ncmFtbWF0aWNhbGx5LCByYW5kb21seSBnZW5lcmF0ZWQgTkZUcyBvbiB0aGUgRXRoZXJldW0gYmxvY2tjaGFpbi4gT3VyIGZpcnN0IHNlcmllcyBpbiAyMDIyIGNvbnNpc3RzIG9mIDk1OTUgcmFuZG9tbHkgYXNzZW1ibGVkIHJlYmVscyDigJMgZWFjaCBvbmUgc3RhbmRpbmcgZm9yIGNyZWF0aXZpdHksIGZyZWVkb20sIGVxdWFsaXR5LCBhbmQgZGVzaWduIGV4Y2VsbGVuY2UuIFdhcm0gUmUoYmVsKWdhcmRzIGZyb20gR2VybWFueSEiLCJleHRlcm5hbF91cmwiOiJodHRwczovL2tvY2hzdHJhc3NlLmFnZW5jeS9pby8iLCJmZWVfcmVjaXBpZW50IjoiMHhEQjc2NjdBQkI1OUVCQjM4QjU1YzAxNTViODkwOTRjNzQ5YmRmRDM2Iiwic2VsbGVyX2ZlZV9iYXNpc19wb2ludHMiOjMwMH0=";
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
        require(saleStatus != SaleStatus.PAUSED, "CreativeRebels: Sales are off");

        

        
        uint price = MINT_PRICE;

        return count * price;
    }
    
    
    
    /// @notice Mints specified amount of tokens
    /// @param count How many tokens to mint
    function mint(uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "CreativeRebels: Sales are off");
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "CreativeRebels: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT, "CreativeRebels: Number of requested tokens exceeds allowance (10)");
        require(_mintedCount[msg.sender] + count <= TOKENS_PER_PERSON_PUB_LIMIT, "CreativeRebels: Number of requested tokens exceeds allowance (250)");
        require(msg.value >= calcTotal(count), "CreativeRebels: Ether value sent is not sufficient");
        _mintedCount[msg.sender] += count;
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