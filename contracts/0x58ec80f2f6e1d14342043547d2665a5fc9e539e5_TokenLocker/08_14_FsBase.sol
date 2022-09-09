//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./FsOwnable.sol";
import "../lib/Utils.sol";

contract FsBase is Initializable, FsOwnable, GitCommitHash {
    /// @notice We reserve 1000 slots for the base contract in case
    //          we ever need to add fields to the contract.
    //slither-disable-next-line unused-state
    uint256[999] private _____baseGap;

    function nonNull(address _address) internal pure returns (address) {
        require(_address != address(0), "Zero address");
        return _address;
    }

    function nonNull(address _address, string memory message) internal pure returns (address) {
        require(_address != address(0), message);
        return _address;
    }
}