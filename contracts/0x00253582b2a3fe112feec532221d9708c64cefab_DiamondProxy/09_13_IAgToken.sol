// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import { IERC20 } from "oz/token/ERC20/IERC20.sol";

/// @title IAgToken
/// @author Angle Labs, Inc.
/// @notice Interface for the stablecoins `AgToken` contracts
interface IAgToken is IERC20 {
    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                              MINTER ROLE ONLY FUNCTIONS                                            
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Lets a whitelisted contract mint agTokens
    /// @param account Address to mint to
    /// @param amount Amount to mint
    function mint(address account, uint256 amount) external;

    /// @notice Burns `amount` tokens from a `burner` address after being asked to by `sender`
    /// @param amount Amount of tokens to burn
    /// @param burner Address to burn from
    /// @param sender Address which requested the burn from `burner`
    /// @dev This method is to be called by a contract with the minter right after being requested
    /// to do so by a `sender` address willing to burn tokens from another `burner` address
    /// @dev The method checks the allowance between the `sender` and the `burner`
    function burnFrom(uint256 amount, address burner, address sender) external;

    /// @notice Burns `amount` tokens from a `burner` address
    /// @param amount Amount of tokens to burn
    /// @param burner Address to burn from
    /// @dev This method is to be called by a contract with a minter right on the AgToken after being
    /// requested to do so by an address willing to burn tokens from its address
    function burnSelf(uint256 amount, address burner) external;

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                TREASURY ONLY FUNCTIONS                                             
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Adds a minter in the contract
    /// @param minter Minter address to add
    /// @dev Zero address checks are performed directly in the `Treasury` contract
    function addMinter(address minter) external;

    /// @notice Removes a minter from the contract
    /// @param minter Minter address to remove
    /// @dev This function can also be called by a minter wishing to revoke itself
    function removeMinter(address minter) external;

    /// @notice Sets a new treasury contract
    /// @param _treasury New treasury address
    function setTreasury(address _treasury) external;

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                  EXTERNAL FUNCTIONS                                                
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether an address has the right to mint agTokens
    /// @param minter Address for which the minting right should be checked
    /// @return Whether the address has the right to mint agTokens or not
    function isMinter(address minter) external view returns (bool);

    /// @notice Amount of decimals of the stablecoin
    function decimals() external view returns (uint8);
}