// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
* @notice IFireCatReserves
*/
interface IFireCatReserves {
    /**
    * @notice All reserves of contract.
    * @dev Fetch data from _totalReserves.
    * @return totalReserves.
    */
    function totalReserves() external view returns (uint256);

    /**
    * @notice check reserves by address.
    * @dev Fetch reserves from _userReserves.
    * @param user address.
    * @return reserves.
    */
    function reservesOf(address user) external view returns (uint256);

    /**
    * @notice The reserves token of contract.
    * @dev Fetch data from _reservesToken.
    * @return reservesToken.
    */
    function reservesToken() external view returns (address);

    /**
    * @notice The interface of reserves adding.
    * @dev transfer WBNB to contract.
    * @param user address.
    * @param addAmount uint256.
    * @return actualAddAmount.
    */
    function addReserves(address user, uint256 addAmount) external returns (uint256);

    /**
    * @notice The interface of reserves withdrawn.
    * @dev Transfer WBNB to owner.
    * @param amount uint256.
    * @return actualSubAmount.
    */
    function withdrawReserves(uint256 amount) external returns (uint);

    /**
    * @notice The interface of IERC20 withdrawn, not include reserves token.
    * @dev Trasfer token to owner.
    * @param token address.
    * @param to address.
    * @param amount uint256.
    * @return actualSubAmount.
    */
    function withdrawRemaining(address token, address to, uint256 amount) external returns (uint);
}