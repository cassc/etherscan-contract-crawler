//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract Ailiens is ERC721AQueryable, Ownable {
    string public unrevealedURI;
    string public baseTokenURI;
    bool unrevealed = true;

    uint16 public maxSupply = 4444;
    uint16 public minted = 0;
    uint8 public constant batchLimit = 5; // mint amount limit
    bool public mintStarted = false; // is mint started flag

    constructor() ERC721A("Ailiens", "Ailiens") { }

    /**
    @notice mint tokens to sender 
    @param _mintAmount amount of tokens to mint
    */
    function mint(uint8 _mintAmount) public {
        require(mintStarted, "Mint is not started");
        require(_mintAmount <= batchLimit, "Not in batch limit");
        require(minted + _mintAmount <= maxSupply, "Too much tokens to mint");

        _safeMint(msg.sender, _mintAmount);
        minted += _mintAmount;
    }

        /**
    @notice mint tokens to sender 
    @param _mintAmount amount of tokens to mint
    */
    function ownerMint(uint8 _mintAmount) public onlyOwner {
        require(minted + _mintAmount <= maxSupply, "Too much tokens to mint");

        _safeMint(msg.sender, _mintAmount);
        minted += _mintAmount;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function reveal(string memory baseURI) external onlyOwner {
        unrevealed = false;
        baseTokenURI = baseURI;
    }

    function setMintState(bool _state) external onlyOwner {
        mintStarted = _state;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (unrevealed) {
            return unrevealedURI;
        }

        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }
}