// SPDX-License-Identifier: MIT

// Partially derived from OpenZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/406c83649bd6169fc1b578e08506d78f0873b276/contracts/utils/Address.sol

pragma solidity >=0.7.6 <0.8.0;

/**
 * @dev Upgrades the address type to check if it is a contract.
 */
library AddressIsContract {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}