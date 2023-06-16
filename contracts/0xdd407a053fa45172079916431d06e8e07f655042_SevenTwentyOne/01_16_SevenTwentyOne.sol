// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title Seven Twenty One Token
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract SevenTwentyOne is ERC721, Ownable {
    using SafeMath for uint256;

    bool public mintingIsActive = false;
    string public PROVENANCE =
        "e0226b57469edf5240bf0985c33f5d18d569040669ac365956d9c6b4b31ce75e";
    string public OPENSEA_STORE_METADATA =
        "ipfs://QmR4tfopGKsw65EzLUgw45ETyajnhm8TrFucoi2SdE6nJa";

    uint256 public MAX_TOTAL_TOKENS;
    uint256 public REVEAL_TIMESTAMP;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    /**
     * @dev Creates the token supply
     *
     * Requirements:
     *
     * - `name` name of the token.
     * - `symbol` uhm, yeah that.
     * - `baseURI` where the token JSON will be located, including ending /.
     * - `maxNftSupply` total supply of the token.
     * - `saleStart` 1 is immediate
     *
     * - `baseURI` setBaseURI is disabled
     *
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 maxNftSupply,
        uint256 saleStart
    ) ERC721(name, symbol) {
        MAX_TOTAL_TOKENS = maxNftSupply;
        REVEAL_TIMESTAMP = saleStart;
        _setBaseURI(baseURI);
    }

    /**
     *  @dev Get contract metadata to make OpenSea happy
     */
    function contractURI() public view returns (string memory) {
        return OPENSEA_STORE_METADATA;
    }

    /**
     *  @dev Set the IPFS baseURI, including ending `/` where JSON is located
     */
    /** 
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    */

    /**
     *  @dev Mint tokens for community
     */
    function mintCommunityTokens(uint256 numberOfTokens) public onlyOwner {
        require(numberOfTokens <= MAX_TOTAL_TOKENS);
        require(
            numberOfTokens <= MAX_TOTAL_TOKENS,
            "Can not mint more than the total supply."
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOTAL_TOKENS,
            "Minting would exceed max supply of Tokens"
        );
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalSupply() < MAX_TOTAL_TOKENS) {
                _safeMint(msg.sender, supply + i);
            }
        }
    }

    /**
     *  @dev Mint token to an address
     */
    function mintTokenTransfer(address to, uint256 numberOfTokens)
        public
        onlyOwner
    {
        require(numberOfTokens <= MAX_TOTAL_TOKENS);
        require(
            numberOfTokens <= MAX_TOTAL_TOKENS,
            "Can not mint more than the total supply."
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOTAL_TOKENS,
            "Minting would exceed max supply of Tokens"
        );
        require(
            address(to) != address(this),
            "Cannot mint to contract itself."
        );
        require(address(to) != address(0), "Cannot mint to the null address.");
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalSupply() < MAX_TOTAL_TOKENS) {
                _safeMint(to, supply + i);
            }
        }
    }

    /**
     *  @dev Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        mintingIsActive = !mintingIsActive;
    }

    /**
     * @dev Set the starting index for the collection
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        startingIndex =
            uint256(blockhash(startingIndexBlock)) %
            MAX_TOTAL_TOKENS;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex =
                uint256(blockhash(block.number - 1)) %
                MAX_TOTAL_TOKENS;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * @dev Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        startingIndexBlock = block.number;
    }
}