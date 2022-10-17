/*
   __  _______  _  ___________________    _______  ___ _      ___  __
  /  |/  / __ \/ |/ / __/_  __/ __/ _ \  / __/ _ \/ _ | | /| / / |/ /
 / /|_/ / /_/ /    /\ \  / / / _// , _/ _\ \/ ___/ __ | |/ |/ /    / 
/_/  /_/\____/_/|_/___/ /_/ /___/_/|_| /___/_/  /_/ |_|__/|__/_/|_/  
                                                                     
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MonsterSpawn1 is ERC721A, Ownable {
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }

    uint public constant COLLECTION_SIZE = 8888;
    
    
    
    uint public constant TOKENS_PER_PERSON_WL_LIMIT = 2;
    uint public constant PRESALE_MINT_PRICE = 0.00666 ether;
    uint public MINT_PRICE = 0.0333 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    bytes32 public merkleRoot = 0x88b5d32ed8551d8b9dc03c0749e16b5efd865bb52ed162c9cd34d240a596f6a4;
    string private _baseURL;
    string public preRevealURL = "ipfs://bafyreiho56hwve65sb45wgu4pkxfoe7lgzs2w2zpqxt7ufkv5i4ba6f4ku/metadata.json";
    mapping(address => uint) private _mintedCount;
    mapping(address => uint) private _whitelistMintedCount;

    constructor() ERC721A("MonsterSpawn1", "MOS"){}
    
    
    function contractURI() public pure returns (string memory) {
        return "data:application/json;base64,eyJuYW1lIjoiTW9uc3RlciBTcGF3biAo8J+Ogyzwn6ebKSIsImRlc2NyaXB0aW9uIjoiV2VsY29tZSB0byBNb25zdGVyIFNwYXduISAgQSBjb2xsZWN0aW9uIG9mIDgsODg4IG1vbnN0ZXJzIHRoYXQgaW52YWRlZCB0aGUgRXRoZXJldW0gYmxvY2tjaGFpbiwgU21hcnQgQ29udHJhY3QgRVJDNzIxQS4iLCJleHRlcm5hbF91cmwiOm51bGwsImZlZV9yZWNpcGllbnQiOiIweGI3RDhFOGE2NGJlM2M0OWFjODY1MWZENjRCN2U1NUZiOTY4MDQyRDAiLCJzZWxsZXJfZmVlX2Jhc2lzX3BvaW50cyI6NzUwfQ==";
    }
    
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
    

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
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
        
        payable(0x94EF1D2E76292485C2ac6B25E1cd26cdcdDe0164).transfer((balance * 1000)/10000);
        payable(0xFb426e67d28D62084DbAE17CBD0795866dd9f5a7).transfer((balance * 1500)/10000);
        payable(0x94858112daE54dc55CC481CE47a61779103914E3).transfer((balance * 2500)/10000);
        payable(0x84154f740d115Eaf73838aB655AdA274e12c8A9C).transfer((balance * 2500)/10000);
        payable(0xFb28b5e0D771e14C4d298f8566D980896438f12A).transfer((balance * 400)/10000);
        payable(0xFF7c62778EDA4c36907C05c851fF3EB1016eD021).transfer((balance * 500)/10000);
        payable(0x6d11006E0859aDE1885F257e7c46812b34b364D6).transfer((balance * 600)/10000);
        payable(0x4156560Eea7Fbe14d2098F66c6c4f3cf9F7D5E56).transfer((balance * 1000)/10000);
    }

    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(_totalMinted() + count <= COLLECTION_SIZE, "Request exceeds collection size");
        _safeMint(to, count);
    }

    /// @notice Get token URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, "/", _toString(tokenId), ".json")) 
            : preRevealURL;
    }
    
    function calcTotal(uint count) public view returns(uint) {
        require(saleStatus != SaleStatus.PAUSED, "MonsterSpawn1: Sales are off");

        

        
        uint price = saleStatus == SaleStatus.PRESALE 
            ? PRESALE_MINT_PRICE 
            : MINT_PRICE;

        return count * price;
    }
    
    
    function redeem(bytes32[] calldata merkleProof, uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "MonsterSpawn1: Sales are off");
        require(_totalMinted() + count <= COLLECTION_SIZE, "MonsterSpawn1: Number of requested tokens will exceed collection size");
        
        require(msg.value >= calcTotal(count), "MonsterSpawn1: Ether value sent is not sufficient");
        if(saleStatus == SaleStatus.PRESALE) {
            require(_whitelistMintedCount[msg.sender] + count <= TOKENS_PER_PERSON_WL_LIMIT, "MonsterSpawn1: Number of requested tokens exceeds allowance (2)");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "MonsterSpawn1: You are not whitelisted");
            _whitelistMintedCount[msg.sender] += count;
        }
        else {
            
            _mintedCount[msg.sender] += count;
        }
        _safeMint(msg.sender, count);
    }
    
}