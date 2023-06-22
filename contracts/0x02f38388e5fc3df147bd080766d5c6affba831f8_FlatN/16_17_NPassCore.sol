// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IN.sol";

/**
 * @title NPass contract
 * @author Tony Snark
 * @notice This contract provides basic functionalities to allow minting using the NPass
 * @dev This contract should be used only for testing or testnet deployments
 */
abstract contract NPassCore is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public constant MAX_N_TOKEN_ID = 8888;

    IN public immutable n;
    bool public immutable onlyNHolders;

    /**
     * @notice Construct an NPassCore instance
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param n_ Address of your n instance (only for testing)
     * @param onlyNHolders_ True if only n tokens holders can mint this token
     */
    constructor(
        string memory name,
        string memory symbol,
        IN n_,
        bool onlyNHolders_
    ) ERC721(name, symbol) {
        n = n_;
        onlyNHolders = onlyNHolders_;
    }

    /**
     * @notice Allow a n token holder to mint a token with one of their n token's id
     * @param tokenId Id to be minted
     */
    function mintWithN(uint256 tokenId) public payable virtual nonReentrant {
        require(n.ownerOf(tokenId) == msg.sender, "NFlat:INVALID_OWNER");
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice Allow anyone to mint a token with the supply id if this pass is unrestricted
     * @param tokenId Id to be minted
     */
    function mint(uint256 tokenId) public payable virtual nonReentrant {
        require(!onlyNHolders, "NFlat:OPEN_MINTING_DISABLED");
        require(tokenId > MAX_N_TOKEN_ID, "NFlat:INVALID_ID");
        _safeMint(msg.sender, tokenId);
    }
}