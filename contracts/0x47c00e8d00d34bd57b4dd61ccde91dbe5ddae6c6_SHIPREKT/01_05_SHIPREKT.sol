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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";


contract SHIPREKT is ERC721A, Ownable {
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC
    }

    uint public constant COLLECTION_SIZE = 7777;
    
    uint public constant TOKENS_PER_TRAN_LIMIT = 1;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 1;
    
    
    uint public MINT_PRICE = 0 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    
    string private _baseURL;
    string public preRevealURL = "ipfs://QmPzT2fPDeCS79ZuHhNihBDYdkmW9mmzB2qnfZFCr4NGtv";
    mapping(address => uint) private _mintedCount;
    

    constructor() ERC721A("SHIPREKT",
    "SHIPREKT"){}
    
    
    function contractURI() public pure returns (string memory) {
        return "https://zerocodenft.azurewebsites.net/api/marketplacecollections/2cf1bf66-9454-44df-3d4b-08da4822632f";
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
        require(balance > 0,
        "No balance");
        payable(owner()).transfer(balance);
    }
    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(_totalMinted() + count <= COLLECTION_SIZE,
        "Request exceeds collection size");
        _safeMint(to, count);
    }
    /// @notice Get token URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI,
        "/", _toString(tokenId),
        ".json")) 
            : preRevealURL;
    }
    
    function calcTotal(uint count, uint price) public pure returns(uint) {
        

        return count * price;
    }
    /// @notice Mints specified amount of tokens
    /// @param count How many tokens to mint
    function mint(uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED,
        "ZeroCodeNFT: Sales are off");
        require(_totalMinted() + count <= COLLECTION_SIZE,
        "ZeroCodeNFT: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT,
        "ZeroCodeNFT: Number of requested tokens exceeds allowance (1)");
        require(_mintedCount[msg.sender
        ] + count <= TOKENS_PER_PERSON_PUB_LIMIT,
        "ZeroCodeNFT: Number of requested tokens exceeds allowance (1)");
        require(msg.value >= calcTotal(count, MINT_PRICE),
        "ZeroCodeNFT: Ether value sent is not sufficient");
        _mintedCount[msg.sender
        ] += count;
        _safeMint(msg.sender, count);
    }
}