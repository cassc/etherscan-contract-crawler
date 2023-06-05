// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** @title Proposal
 * Interface specification for proposals. Any proposal submitted in the
 * policy decision process must implement this interface.
 */
interface Proposal {
    /** The name of the proposal.
     *
     * This should be relatively unique and descriptive.
     */
    function name() external view returns (string memory);

    /** A longer description of what this proposal achieves.
     */
    function description() external view returns (string memory);

    /** A URL where voters can go to see the case in favour of this proposal,
     * and learn more about it.
     */
    function url() external view returns (string memory);

    /** Called to enact the proposal.
     *
     * This will be called from the root policy contract using delegatecall,
     * with the direct proposal address passed in as _self so that storage
     * data can be accessed if needed.
     *
     * @param _self The address of the proposal contract.
     */
    function enacted(address _self) external;
}