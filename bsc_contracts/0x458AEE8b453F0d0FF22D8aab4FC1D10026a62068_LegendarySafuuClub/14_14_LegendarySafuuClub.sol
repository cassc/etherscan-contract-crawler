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

contract LegendarySafuuClub is ERC721, Ownable {
    using Strings for uint;
    using Counters for Counters.Counter;
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }

    Counters.Counter private _tokenIds;

    uint public constant COLLECTION_SIZE = 4211;
    
    uint public constant TOKENS_PER_TRAN_LIMIT = 20;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 100;
    uint public constant TOKENS_PER_PERSON_WL_LIMIT = 2;
    uint public constant PRESALE_MINT_PRICE = 0.5 ether;
    uint public MINT_PRICE = 0.75 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    bytes32 public merkleRoot = 0x8c38fb1ddf609037788871b8bcba752c2a05d5dc3e271911f3601cade59b23bc;
    string private _baseURL;
    string public preRevealURL = "ipfs://bafyreialmxwdkb4bznjlsfvypapa57to4fbxfffkg2gnz6d76iavi667iq/metadata.json";
    mapping(address => uint) private _mintedCount;
    mapping(address => uint) private _whitelistMintedCount;

    constructor() ERC721("LegendarySafuuClub", "LSC"){}
    
    
    
    /// @notice Update the merkle tree root
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
    
    /// @notice Reveal metadata for all the tokens
    function reveal(string calldata url) external onlyOwner {
        _baseURL = url;
    }
    
    /// @notice Set Pre Reveal URL
    function setPreRevealUrl(string calldata url) external onlyOwner {
        preRevealURL = url;
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
        
        payable(0xb629e9b3167c769b0044b67c67bc7fb36CDcE131).transfer((balance * 6000)/10000);
        payable(0x2c5967e124fc99B7e9E04Ba075Cd80fEc0AD55cb).transfer((balance * 1000)/10000);
        payable(0x302bE2dABe3f55eF098e80a670F55Bcd1145Fd05).transfer((balance * 1000)/10000);
        payable(0xee6CB396286E79648b0EadDbBaFA68C38cD70f29).transfer((balance * 2000)/10000);
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
            : preRevealURL;
    }
    
    function calcTotal(uint count) public view returns(uint) {
        require(saleStatus != SaleStatus.PAUSED, "LegendarySafuuClub: Sales are off");

        

        
        uint price = saleStatus == SaleStatus.PRESALE 
            ? PRESALE_MINT_PRICE 
            : MINT_PRICE;

        return count * price;
    }
    
    
    function redeem(bytes32[] calldata merkleProof, uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "LegendarySafuuClub: Sales are off");
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "LegendarySafuuClub: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT, "LegendarySafuuClub: Number of requested tokens exceeds allowance (20)");
        require(msg.value >= calcTotal(count), "LegendarySafuuClub: Ether value sent is not sufficient");
        if(saleStatus == SaleStatus.PRESALE) {
            require(_whitelistMintedCount[msg.sender] + count <= TOKENS_PER_PERSON_WL_LIMIT, "LegendarySafuuClub: Number of requested tokens exceeds allowance (2)");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "LegendarySafuuClub: You are not whitelisted");
            _whitelistMintedCount[msg.sender] += count;
        }
        else {
            require(_mintedCount[msg.sender] + count <= TOKENS_PER_PERSON_PUB_LIMIT, "LegendarySafuuClub: Number of requested tokens exceeds allowance (100)");
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