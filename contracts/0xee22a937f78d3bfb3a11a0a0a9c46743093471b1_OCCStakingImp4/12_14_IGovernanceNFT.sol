// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IAccessControl.sol";

/**
 * @title GovernanceNFT: ERC721 NFT with URI storage for metadata used for governance in Discord
 * @dev ERC721 contains logic for NFT storage and metadata.
 */
interface IGovernanceNFT is IERC721, IAccessControl {
    event Minted(
        uint256 indexed id,
        address indexed holder
        // TODO: add list of traits
    );
    event Burned(
        uint256 indexed id,
        address indexed holder
    );

    /**
     * @dev Mint a NFT for a user
     * @param user Address that should receive the NFT
     */
    function mint(address user) external;

    /**
     * @dev Burn a NFT of a user
     * @param user Address that should have the NFT burned. Information about the holder is enough because there is as most one NFT per user.
     */
    function burn(address user) external;

    /**
     * @dev Get NFT id of user or 0 for none.
     * 
     * @param user The address of the NFT owner.
     * @return Returns the id of the NFT for the given address and 0 if the address has no NFTs.
     */
    function getNFTHoldBy(address user) external view returns (uint256);

    /**
     * @dev Each address can at most have one NFT. This function assigns as id to a user by convertng the address to uint256
     * @param user address of the user
     */
    function getIDForAddress(address user) external pure returns (uint256);


    function ISSUER_ROLE() external pure returns (bytes32);
}