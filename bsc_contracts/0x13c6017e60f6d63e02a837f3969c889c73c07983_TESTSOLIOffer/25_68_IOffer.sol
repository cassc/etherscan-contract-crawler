// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

/**
 * @dev IOffer is the base interface for all offers in the platform
 */
interface IOffer {
    /**
     * @dev Returns true if the sale is initialized and ready for operation
     */
    function getInitialized() external view returns (bool);

    /**
     * @dev Returns true if the sale has finished operations and can no longer sell
     */
    function getFinished() external view returns (bool);

    /**
     * @dev Returns true if the sale has reached a successful state (should be unreversible)
     */
    function getSuccess() external view returns (bool);

    /**
     * @dev Returns the total amount of tokens bought by the specified _investor
     */
    function getTotalBought(address _investor) external view returns (uint256);

    /**
     * @dev Returns the total amount of tokens cashed out by the specified _investor
     */
    function getTotalCashedOut(address _investor)
        external
        view
        returns (uint256);

    /**
     * @dev If the sale is finished, returns the date it finished at
     */
    function getFinishDate() external view returns (uint256);

    /**
     * @dev Prepares the sale for operation
     */
    function initialize() external;

    /**
     * @dev If possible, cashouts tokens for the specified _investor
     */
    function cashoutTokens(address _investor) external returns (bool);
}