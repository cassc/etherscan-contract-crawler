/*
$$\   $$\ $$$$$$$$\ $$$$$$$$\ $$\ $$\                  $$\            $$$$$$\   $$$$$$\            $$$$$$$$\ $$\   $$\ $$$$$$$$\ 
$$$\  $$ |$$  _____|\__$$  __|\__|$$ |                 $$ |          $$$ __$$\ $$ ___$$\           \__$$  __|$$ |  $$ |$$  _____|
$$$$\ $$ |$$ |         $$ |   $$\ $$$$$$$\   $$$$$$\ $$$$$$\         $$$$\ $$ |\_/   $$ |             $$ |   $$ |  $$ |$$ |      
$$ $$\$$ |$$$$$\       $$ |   $$ |$$  __$$\ $$  __$$\\_$$  _|        $$\$$\$$ |  $$$$$ /              $$ |   $$$$$$$$ |$$$$$\    
$$ \$$$$ |$$  __|      $$ |   $$ |$$ |  $$ |$$$$$$$$ | $$ |          $$ \$$$$ |  \___$$\              $$ |   \_____$$ |$$  __|   
$$ |\$$$ |$$ |         $$ |   $$ |$$ |  $$ |$$   ____| $$ |$$\       $$ |\$$$ |$$\   $$ |             $$ |         $$ |$$ |      
$$ | \$$ |$$ |         $$ |   $$ |$$$$$$$  |\$$$$$$$\  \$$$$  |      \$$$$$$  /\$$$$$$  |$$\          $$ |         $$ |$$$$$$$$\ 
\__|  \__|\__|         \__|   \__|\_______/  \_______|  \____/        \______/  \______/ $  |         \__|         \__|\________|
                                                                                         \_/                                     
                                                                                                                                 
                                                                                                                                 
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract NFTibet3thefourelements is ERC721, Ownable {
    using Strings for uint;
    using Counters for Counters.Counter;
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }

    Counters.Counter private _tokenIds;

    uint public constant COLLECTION_SIZE = 6;
    
    uint public constant TOKENS_PER_TRAN_LIMIT = 2;
    
    
    
    uint public MINT_PRICE = 3.369 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    
    string private _baseURL = "ipfs://bafybeibcixrpgsfkfla74dwuqo4poyrxnzfm6z6cbjludqjxb326o5viuu";
    
    mapping(address => uint) private _mintedCount;
    

    constructor() ERC721("NFTibet3thefourelements", "NFTibet4el"){}
    
    
    
    
    
    
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
        require(saleStatus != SaleStatus.PAUSED, "NFTibet3thefourelements: Sales are off");

        

        
        uint price = MINT_PRICE;

        return count * price;
    }
    
    
    
    /// @notice Mints specified amount of tokens
    /// @param count How many tokens to mint
    function mint(uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "NFTibet3thefourelements: Sales are off");
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "NFTibet3thefourelements: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT, "NFTibet3thefourelements: Number of requested tokens exceeds allowance (2)");
        
        require(msg.value >= calcTotal(count), "NFTibet3thefourelements: Ether value sent is not sufficient");
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