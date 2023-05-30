// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * Interface to the digital media store external contract that is
 * responsible for storing the common digital media and collection data.
 * This allows for new token contracts to be deployed and continue to reference
 * the digital media and collection data.
 */
abstract contract ApprovedCreatorRegistryInterface {
    function getVersion() public pure virtual returns (uint256);

    function typeOfContract() public pure virtual returns (string calldata);

    function isOperatorApprovedForCustodialAccount(
        address _operator,
        address _custodialAddress
    ) public view virtual returns (bool);
}