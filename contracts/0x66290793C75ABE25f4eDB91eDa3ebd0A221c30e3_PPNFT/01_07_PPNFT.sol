// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PPNFT is ERC721A, Ownable {
    using Strings for uint;
    enum SaleStatus{ PAUSED, PUBLIC }

    uint public constant COLLECTION_SIZE = 8008;
    string public baseURI = "ipfs://QmaRDs5KRTwNhT4xJqRDFvUqfv44gAxHcXWLFaMufrQWeC/";
    SaleStatus public saleStatus = SaleStatus.PAUSED;

    constructor() ERC721A("Poop Pass", "POOPNFT") {}
    
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
    
    /// @param quantity quantity to mint
    function mint(uint256 quantity) external {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(saleStatus != SaleStatus.PAUSED, "Minting paused");
        require(totalSupply() + quantity <= COLLECTION_SIZE, "Supply exceeded");

        uint magicTokenNum;
        uint count = totalSupply();
        if (count <= 2000) {
            magicTokenNum = 3;  // Minting early means tx limit and acc limit = 3
        } else if (count <= 4008) {
            magicTokenNum = 2;  // Minting in the middle means tx limit and acc limit = 2
        } else {
            magicTokenNum = 1;  // Otherwise tx limit and acc limit = 1
        }
        
        require(quantity <= magicTokenNum, "Tx limit exceeded");
        require(quantity + _numberMinted(msg.sender) <= magicTokenNum, "Acc has token limit");

        _safeMint(msg.sender, quantity);
    }
}