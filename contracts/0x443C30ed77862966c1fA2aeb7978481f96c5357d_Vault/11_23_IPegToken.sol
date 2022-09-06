// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPegToken is IERC20 {

    /**
     * @return the total shares minted.
     */
    function totalShares() external view returns (uint256);

    /**
     * @return the shares of specified address.
     */
    function sharesOf(address _account) external view returns (uint256);

    /**
     * @dev query the value that can be returned for a specified number of shares.
     * @return underlying units etc usd/eth.
     */
    function getUnderlyingUnitsByShares(uint256 _sharesAmount) external view returns (uint256);

    /**
     * @dev query the shares that can be returned for a specified number of underlying uints.
     * @return the shares.
     */
    function getSharesByUnderlyingUnits(uint256 _underlyingUnits) external view returns (uint256);
    
    /**
     * @dev change the pause state.
     * @param _isPaused.
     */
    function changePauseState(bool _isPaused) external;

    /**
     * @notice Creates `_sharesAmount` shares and assigns them to `_recipient`, increasing the total amount of shares.
     * @dev This doesn't increase the token total supply.
     *
     * Requirements:
     *
     * - `_recipient` cannot be the zero address.
     * - the contract must not be paused.
     */
    function mintShares(address _recipient, uint256 _sharesAmount) external;

    /**
     * @notice Destroys `_sharesAmount` shares from `_account`'s holdings, decreasing the total amount of shares.
     * @dev This doesn't decrease the token total supply.
     *
     * Requirements:
     *
     * - `_account` cannot be the zero address.
     * - `_account` must hold at least `_sharesAmount` shares.
     * - the contract must not be paused.
     */
    function burnShares(address _account, uint256 _sharesAmount) external;

}