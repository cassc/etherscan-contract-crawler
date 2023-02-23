// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IHATToken is IVotes, IERC20Permit {

    // Amount for minting or burning cannot be zero
    error ZeroAmount();

    // Token transfers had not been enabled yet
    error TransfersDisabled();

    /// @notice An event thats emitted when the minter address is set
    event MinterSet(address indexed minter, uint256 seedAmount);

    /// @notice An event thats emitted when the token is set to transferable
    event TransferableSet();
    
    /**
     * @notice Set the minter address, can only be called by the owner (governance)
     * @param _minter The address of the minter
     * @param _seedAmount The amount of tokens to seed the minter with
     */
    function setMinter(address _minter, uint256 _seedAmount) external;

    function burn(uint256 _amount) external;

    function mint(address _account, uint _amount) external;

}