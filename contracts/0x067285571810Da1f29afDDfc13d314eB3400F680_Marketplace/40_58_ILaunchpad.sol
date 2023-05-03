//SPDX-License-Identifier: MIT
/**
 * Launchpad Registry Interface
 * @author @brougkr
 */
pragma solidity 0.8.19;
interface ILaunchpad 
{ 
    /**
     * @dev Returns Next ProjectID From ArtBlocks Contract
     */
    function ViewNextABProjectID() external view returns(uint);

    /**
     * @dev Returns Launchpad Registry Address
     */
    function ViewAddressLaunchpadRegistry() external view returns(address);

    /**
     * @dev Returns Marketplace Address
     */
    function ViewAddressMarketplace() external view returns(address);

    /**
     * @dev Returns LiveMint Address
     */
    function ViewAddressLiveMint() external view returns (address);

    /**
     * @dev Returns Mint Pass Factory Address
     */
    function ViewAddressMintPassFactory() external view returns (address);
}

/**
 * @dev Launchpad Registry Interface
 */
interface ILaunchpadRegistry 
{ 
    function __NewMintPassURI(uint MintPassProjectID, string memory NewURI) external; 
    function ViewBaseURIMintPass(uint MintPassProjectID) external view returns (string memory);
}