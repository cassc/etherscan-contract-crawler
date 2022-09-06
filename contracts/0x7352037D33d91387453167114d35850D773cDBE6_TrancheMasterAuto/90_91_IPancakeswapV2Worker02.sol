// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IWorker {
    /// @dev Work on a (potentially new) position. Optionally send token back to Vault.
    function work(
        uint256 id,
        address user,
        uint256 debt,
        bytes calldata data
    ) external;

    /// @dev Re-invest whatever the worker is working on.
    function reinvest() external;

    /// @dev Return the amount of wei to get back if we are to liquidate the position.
    function health(uint256 id) external view returns (uint256);

    /// @dev Liquidate the given position to token. Send all token back to its Vault.
    function liquidate(uint256 id) external;

    /// @dev SetStretegy that be able to executed by the worker.
    function setStrategyOk(address[] calldata strats, bool isOk) external;

    /// @dev Set address that can be reinvest
    function setReinvestorOk(address[] calldata reinvestor, bool isOk) external;

    /// @dev Base Token that worker is working on
    function baseToken() external view returns (address);

    /// @dev Farming Token that worker is working on
    function farmingToken() external view returns (address);
}