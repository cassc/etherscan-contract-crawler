// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */
interface IMoneyHandler is IAccessControl {
    function totalReleased() external view returns (uint256);

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) external view returns (uint256);

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) external view returns (uint256);

    function collecMny(address collection) external view returns (uint256);

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) external view returns (address);

    function updateCollecMny(address collection, uint256 amount) external;

    function recoverToken(address _token) external;

    function redeem(
        address collection,
        address _token,
        address[] memory payees,
        uint256[] memory sharePerc_
    ) external;
}