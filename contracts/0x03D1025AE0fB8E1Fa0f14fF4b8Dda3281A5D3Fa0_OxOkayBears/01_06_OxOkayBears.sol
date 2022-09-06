// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract OxOkayBears is ERC721A, Ownable {
    enum SaleStatus{ PAUSED,PUBLIC }

    uint public constant COLLECTION_SIZE = 9999;
    uint public constant FIRSTXFREE = 500;
    uint public constant TOKENS_PER_TRAN_LIMIT = 10;
    address private immutable TREASURY;
    
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    
    string private _baseURL = "ipfs://QmV16agBfM3Tuivx3QypKBN5r5UXm3H4hjwoUtVBJ1eJop/";
    mapping(address => uint) private _mintedCount;

    constructor(address treasury) ERC721A("OxOkayBears", "OxOB"){
        TREASURY = treasury;
    }
    

    function calculateTotal(uint count) public view returns (uint total) {
        if(_totalMinted() < FIRSTXFREE) {
            return 0 ether;
        }
           return count * 0.03 ether;
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

    /// @notice Withdraw contract balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");
        
        payable(TREASURY).transfer(balance);
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
            ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) 
            : "";
    }
    
    /// @notice Mints specified amount of tokens
    /// @param count How many tokens to mint
    function mint(uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "0xOkayBears: Sales are off");
        require(_totalMinted() + count <= COLLECTION_SIZE, "0xOkayBears: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT, "0xOkayBears: Number of requested tokens exceeds allowance (10)");

        if(_totalMinted() < FIRSTXFREE) {
            require(count == 1, "0xOkayBears: Only 1 per wallet");
            require(_mintedCount[msg.sender] == 0, "0xOkayBears: Only 1 per wallet");
        }
        
        uint total = calculateTotal(count);
        require(msg.value >= total, "0xOkayBears: Ether value sent is not sufficient");
        _mintedCount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }
}