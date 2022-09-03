// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IAuction {
    function bid(address pool, uint256 amount) external;

    function ownerOfDebt(address pool) external view returns (address);

    /// @notice States of auction
    /// @dev None: A pool is not default and auction can't be started
    /// @dev NotStarted: A pool is default and auction can be started
    /// @dev Active: An auction is started
    /// @dev Finished: An auction is finished but NFT is not claimed
    /// @dev Closed: An auction is finished and NFT is claimed
    enum State {
        None,
        NotStarted,
        Active,
        Finished,
        Closed
    }

    function state(address pool) external view returns (State);
}