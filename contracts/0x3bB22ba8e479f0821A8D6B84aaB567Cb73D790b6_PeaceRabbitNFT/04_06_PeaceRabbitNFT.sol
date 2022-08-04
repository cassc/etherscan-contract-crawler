/*
__________                          __________       ___.  ___.   .__  __     _______  ______________________
\______   \ ____ _____    ____  ____\______   \_____ \_ |__\_ |__ |__|/  |_   \      \ \_   _____/\__    ___/
 |     ___// __ \\__  \ _/ ___\/ __ \|       _/\__  \ | __ \| __ \|  \   __\  /   |   \ |    __)    |    |   
 |    |   \  ___/ / __ \\  \__\  ___/|    |   \ / __ \| \_\ \ \_\ \  ||  |   /    |    \|     \     |    |   
 |____|    \___  >____  /\___  >___  >____|_  /(____  /___  /___  /__||__|   \____|__  /\___  /     |____|   
               \/     \/     \/    \/       \/      \/    \/    \/                   \/     \/               
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PeaceRabbitNFT is ERC721A, Ownable {
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }

    uint public constant COLLECTION_SIZE = 8000;
    uint public constant FIRSTXFREE = 1000;
    uint public constant TOKENS_PER_TRAN_LIMIT = 3;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 3;
    uint public constant TOKENS_PER_PERSON_WL_LIMIT = 3;
    uint public constant PRESALE_MINT_PRICE = 0.04 ether;
    uint public MINT_PRICE = 0.06 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    bytes32 public merkleRoot;
    string private _baseURL;
    string public preRevealURL = "ipfs://QmdaWN3TtT1UTGssGuoTo7SvpRQtLs7ADaX1h5jgSMHFCu";
    mapping(address => uint) private _mintedCount;
    mapping(address => uint) private _whitelistMintedCount;

    constructor() ERC721A("PeaceRabbitNFT", "PEACE"){}
    
    
    function contractURI() public pure returns (string memory) {
        return "https://zerocodenft.azurewebsites.net/api/marketplacecollections/aaf0118f-49ba-42f2-cd05-08da74bb7726";
    }
    
    /// @notice Update the merkle tree root
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
    
    /// @notice Reveal metadata for all the tokens
    function reveal(string memory url) external onlyOwner {
        _baseURL = url;
    }
    
     /// @notice Set Pre Reveal URL
    function setPreRevealUrl(string memory url) external onlyOwner {
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
        payable(owner()).transfer(balance);
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
        require(saleStatus != SaleStatus.PAUSED, "PeaceRabbitNFT: Sales are off");

        
        require(msg.sender != address(0));
        uint totalMintedCount = _whitelistMintedCount[msg.sender] + _mintedCount[msg.sender];

        if(FIRSTXFREE > totalMintedCount) {
            uint freeLeft = FIRSTXFREE - totalMintedCount;
            if(count > freeLeft) {
                // just pay the difference
                count -= freeLeft;
            }
            else {
                count = 0;
            }
        }

        
        uint price = saleStatus == SaleStatus.PRESALE 
            ? PRESALE_MINT_PRICE 
            : MINT_PRICE;

        return count * price;
    }
    
    
    function redeem(bytes32[] calldata merkleProof, uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "PeaceRabbitNFT: Sales are off");
        require(_totalMinted() + count <= COLLECTION_SIZE, "PeaceRabbitNFT: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT, "PeaceRabbitNFT: Number of requested tokens exceeds allowance (3)");
        require(msg.value >= calcTotal(count), "PeaceRabbitNFT: Ether value sent is not sufficient");
        if(saleStatus == SaleStatus.PRESALE) {
            require(_whitelistMintedCount[msg.sender] + count <= TOKENS_PER_PERSON_WL_LIMIT, "PeaceRabbitNFT: Number of requested tokens exceeds allowance (3)");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "PeaceRabbitNFT: You are not whitelisted");
            _whitelistMintedCount[msg.sender] += count;
        }
        else {
            require(_mintedCount[msg.sender] + count <= TOKENS_PER_PERSON_PUB_LIMIT, "PeaceRabbitNFT: Number of requested tokens exceeds allowance (3)");
            _mintedCount[msg.sender] += count;
        }
        _safeMint(msg.sender, count);
    }
    
}