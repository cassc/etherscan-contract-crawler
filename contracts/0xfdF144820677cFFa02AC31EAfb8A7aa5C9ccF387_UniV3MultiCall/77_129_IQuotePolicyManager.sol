// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DataTypesPeerToPeer} from "../../DataTypesPeerToPeer.sol";

interface IQuotePolicyManager {
    event PairPolicySet(
        address indexed lenderVault,
        address indexed collToken,
        address indexed loanToken,
        bytes singlePolicyData
    );
    event GlobalPolicySet(address indexed lenderVault, bytes globalPolicyData);

    /**
     * @notice sets the global policy
     * @param lenderVault Address of the lender vault
     * @param globalPolicyData Global policy data to be set
     */
    function setGlobalPolicy(
        address lenderVault,
        bytes calldata globalPolicyData
    ) external;

    /**
     * @notice sets the policy for a pair of tokens
     * @param lenderVault Address of the lender vault
     * @param collToken Address of the collateral token
     * @param loanToken Address of the loan token
     * @param pairPolicyData Pair policy data to be set
     */
    function setPairPolicy(
        address lenderVault,
        address collToken,
        address loanToken,
        bytes calldata pairPolicyData
    ) external;

    /**
     * @notice Checks if a borrow is allowed
     * @param borrower Address of the borrower
     * @param lenderVault Address of the lender vault
     * @param generalQuoteInfo General quote info (see DataTypesPeerToPeer.sol)
     * @param quoteTuple Quote tuple (see DataTypesPeerToPeer.sol)
     * @return _isAllowed Flag to indicate if the borrow is allowed
     * @return minNumOfSignersOverwrite Overwrite of minimum number of signers (if zero ignored in quote handler)
     */
    function isAllowed(
        address borrower,
        address lenderVault,
        DataTypesPeerToPeer.GeneralQuoteInfo calldata generalQuoteInfo,
        DataTypesPeerToPeer.QuoteTuple calldata quoteTuple
    ) external view returns (bool _isAllowed, uint256 minNumOfSignersOverwrite);

    /**
     * @notice Gets the address registry
     * @return Address of the address registry
     */
    function addressRegistry() external view returns (address);
}