// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract TheGoreys is ERC721A, Ownable {
    using Strings for uint;
    enum SaleStatus{ PAUSED, PUBLIC }

    uint128 public constant maxSupply = 4000;
    uint128 public constant maxMintAmountPerTx = 20;
    uint128 public constant maxPerWallet = 100;
    uint128 public price = 0.003 ether;
    SaleStatus public saleStatus = SaleStatus.PUBLIC;
    string private _baseURL = "ipfs://bafybeibnheb2y4ecud3mh3iln3obkek35gqadb5sdyo367idvfwin6dmly/";
    
    mapping(address => uint) private _mintedCount;

    constructor() ERC721A("TheGoreys", "GOREY$"){}
    
   
      
      function burn(uint256 tokenId) external{
        _burn(tokenId, true); // no approve function, but need to check if owner
    }
    
    
    /// @notice Set base metadata URL
    function setBaseURL(string memory url) external onlyOwner {
        _baseURL = url;
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
    function setPublicMintPrice(uint128 _price) external onlyOwner {
        price = _price;
    }

    /// @notice Withdraw contract balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");
        
        payable(0x33C17539fF344E8bFDcd1dCcBbAeB65b2bdBBEe3).transfer((balance * 10000)/10000);
        
    }

    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(_totalMinted() + count <= maxSupply, "Request exceeds collection size");
        _safeMint(to, count);
    }

    /// @notice Get token URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) 
            : "";
    }
    
    function mint( uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, " Sales are off");
        require(_totalMinted() + count <= maxSupply, " Number of requested tokens will exceed collection size");
        require(count <= maxMintAmountPerTx, " Number of requested tokens exceeds allowance");
        require(_mintedCount[msg.sender] + count <= maxPerWallet, " Max token per wallet exceeded");
         {
            require(msg.value >= count * price, " Ether value sent is not sufficient");
            
            _mintedCount[msg.sender] += count;
        }
        _safeMint(msg.sender, count);
    }
    
}