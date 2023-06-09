//SPDX-License-Identifier: None

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// SHA256 of csv with tokenIds and phrases: 3165ed0ca18d34f4783b9336a11b43c77af616dd617fe483b0216ba712c4006d

contract IWantNFT is ERC721, Ownable {
    using Strings for uint256;
    using Address for address payable;

    /***********************************|
    |        Variables and Events       |
    |__________________________________*/

    // The counter for next tokenID for each primary key
    // So tokenId = nextTokenId[i] + i * 1000 Eg (i=0: 0->999, i=1: 1000->1999, etc)
    uint256[5] public nextTokenId;
    // Cap on number of mints per primary key
    uint256 constant public SIZE = 1000;
    // Primary key for minting Reel NFTs
    uint256 constant public REEL_ID = 4;
    // Limit on mintable reels
    uint256 constant public REEL_LIMIT = 5;
    // Toggle whether minting is enabled for the public
    bool public mintEnabled = false;

    // Price per mint
    uint256 public mintPrice = 0.1 ether;
    // Base metadata URI
    string public baseURI = "https://storage.treum.io/iwantnfts/";

	// Constructor
    constructor() ERC721("RosenBigDrop", "Rosen") {}


    /***********************************|
    |        User Interactions          |
    |__________________________________*/

    /**
     * @dev Function to mint tokens. Payable & open to public when mintEnabled==true
     * @param primaryId indicates the primary phrase for the token (0-3)
     */
    function mint(uint256 primaryId) external payable {
        require(mintEnabled == true, "Token minting disabled");
        require(msg.value == mintPrice, "Incorrect price");
        require(primaryId < REEL_ID, "Invalid primary id");

        uint256 _nextTokenId = nextTokenId[primaryId];
        require(_nextTokenId < SIZE, "Primary token limit exceeded");

        uint256 tokenId = primaryId * SIZE + _nextTokenId;

        nextTokenId[primaryId] = _nextTokenId + 1;

        _mint(msg.sender, tokenId);
    }


    /***********************************|
    |   Public Getters - URIs           |
    |__________________________________*/

    /**
     * @dev Function to return a tokens URI string
     * @param tokenId the Id of the NFT metadata to query
     */
    function tokenURI(uint tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString(), '.json'));
    }

    /**
     * @dev Function to return a list of next token Ids
     */
    function getNextTokenIds() external view returns (uint256[5] memory nextTokenIds) {
        for (uint256 i = 0; i < 5; i++) {
            nextTokenIds[i] = nextTokenId[i];
        }
    }


    /***********************************|
    |        Admin                      |
    |__________________________________*/

    /**
     * @dev Function to mint Reel NFTs. Restricted to contract owner
     */
    function mintReel() external onlyOwner {
        uint256 _nextTokenId = nextTokenId[REEL_ID];
        require(_nextTokenId < REEL_LIMIT, "Reel token limit exceeded");

        uint256 tokenId = REEL_ID * SIZE + _nextTokenId;

        nextTokenId[REEL_ID] = _nextTokenId + 1;

        _mint(msg.sender, tokenId);
    }

    /**
     * @dev Function to update base token URI. Restricted to contract owner
     * @param _baseURI string of the new baseURI
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @dev Function to update minting price. Restricted to contract owner
     * @param newPrice new price of minting in wei
     */
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    /**
     * @dev Function to update token URIs in batches. Restricted to contract owner
     * @param enabled Bool value to be set for mintEnabled
     */
    function _setMintEnabled(bool enabled) external onlyOwner {
        mintEnabled = enabled;
    }

    /**
     * @dev Function to withdraw contract ETH balance. Restricted to contract owner
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}