// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// RadicalDigitalPainting
contract RadicalDigitalPainting is ERC721Enumerable, Ownable {

    // contractURI, BaseTokenURI, extension
    string private _contractURI;
    string public _baseTokenURI = 'https://rdp.whistlegraph.com/json/';
    string private _baseTokenExtension = '.json';

    uint256 public constant MAX_SUPPLY = 239; // Max NFT Supply
    bool public locked;

    constructor() payable ERC721("Radical Digital Painting", "RDP") {
    }

    /**
     * Lock modifier for locking contract to make it immutable
     */
    modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }

    // Owner function to lock Metadata forever
    function lockMetadata() external onlyOwner {
        locked = true;
    }

    /**
     * minting as owner
     */
    function MultiMintOwner(uint256 mintAmount) external onlyOwner {
        require(totalSupply() + mintAmount <= MAX_SUPPLY, "Minting: All tokens minted");
        // Mint NFT
        for (uint256 i = 0; i < mintAmount; i++) {
            uint256 mintIndex = totalSupply() + 1;
            // Start with TokenID 1
            _safeMint(_msgSender(), mintIndex);
        }
    }

    /**
     * @dev Set metadata only when it's not locked
     */
    function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }

    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner notLocked {
        _baseTokenURI = __baseTokenURI;
    }

    /**
     * @dev Returns a URI for contract metadata
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId), _baseTokenExtension));
    }
}