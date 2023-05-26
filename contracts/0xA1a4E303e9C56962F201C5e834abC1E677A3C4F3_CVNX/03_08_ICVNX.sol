// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice ICVNX interface for CVNX contract.
interface ICVNX is IERC20 {
    /// @notice Mint new CVNX tokens.
    /// @param _account Address that receive tokens
    /// @param _amount Tokens amount
    function mint(address _account, uint256 _amount) external;

    /// @notice Lock tokens on holder balance.
    /// @param _tokenOwner Token holder
    /// @param _tokenAmount Amount to lock
    function lock(address _tokenOwner, uint256 _tokenAmount) external;

    /// @notice Unlock tokens on holder balance.
    /// @param _tokenOwner Token holder
    /// @param _tokenAmount Amount to lock
    function unlock(address _tokenOwner, uint256 _tokenAmount) external;

    /// @notice Swap CVN to CVNX tokens
    /// @param _amount Token amount to swap
    function swap(uint256 _amount) external returns (bool);

    /// @notice Transfer stuck tokens
    /// @param _token Token contract address
    /// @param _to Receiver address
    /// @param _amount Token amount
    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;

    /// @notice Set CVNXGovernance contract.
    /// @param _address CVNXGovernance contract address
    function setCvnxGovernanceContract(address _address) external;

    /// @notice Set limit params.
    /// @param _percent Percentage of the total balance available for transfer
    /// @param _limitAmount Max amount available for transfer
    /// @param _period Lock period when user can't transfer tokens
    function setLimit(uint256 _percent, uint256 _limitAmount, uint256 _period) external;

    /// @notice Add address to 'from' whitelist
    /// @param _newAddress New address
    function addFromWhitelist(address _newAddress) external;

    /// @notice Remove address from 'from' whitelist
    /// @param _oldAddress Old address
    function removeFromWhitelist(address _oldAddress) external;

    /// @notice Add address to 'to' whitelist
    /// @param _newAddress New address
    function addToWhitelist(address _newAddress) external;

    /// @notice Remove address from 'to' whitelist
    /// @param _oldAddress Old address
    function removeToWhitelist(address _oldAddress) external;

    /// @notice Change limit activity status.
    function changeLimitActivityStatus() external;
}