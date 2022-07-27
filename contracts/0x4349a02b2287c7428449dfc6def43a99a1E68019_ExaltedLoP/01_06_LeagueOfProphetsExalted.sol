// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ExaltedLoP is ERC721A, Ownable {
    using Strings for uint;
    enum SaleStatus{ PAUSED, PUBLIC }

    uint public constant COLLECTION_SIZE = 1111; 
    string public baseURI = ""; 
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    address private constant ORIGINAL = 0x2761D225A3bd0F308C5481d0ffFFF2442e7FA98B;
    uint256 private origSupply = 5555;
    uint256 public burnRate = 5;

    constructor() ERC721A("League of Prophets: Exalted", "LOPEX") {} 
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    /// @notice Update current sale stage
    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }
    /// @notice Withdraw contract's balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");
        payable(owner()).transfer(balance);
    }
    /// @notice Allows owner to mint tokens to a specified address 
    function airdrop(address to, uint count) external onlyOwner {
        require(totalSupply() + count <= COLLECTION_SIZE, "Supply exceeded");
        _safeMint(to, count);
    }
    /// @notice Get token's URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "tokenId doesn't exist yet");

        string memory baseURI_mem = _baseURI();
        return bytes(baseURI_mem).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }
    /// @notice Sets the base URI for the tokens
    /// @param newURI the URI to set
    function setBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    function burn(uint256[] calldata ids) external {
        require(tx.origin == msg.sender, "caller is another contract");
        require(saleStatus != SaleStatus.PAUSED, "Burning is paused");
        require(ids.length == burnRate, "Must supply 5 ids to burn");

        // Transfer old contract tokens
        for (uint i = 0; i < burnRate; i++) {
            (bool success, ) = ORIGINAL.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(0xdead), ids[i]));
            require(success, "transferFrom call failed");
        }

        // Mint new token
        _safeMint(msg.sender, 1);
    }
}