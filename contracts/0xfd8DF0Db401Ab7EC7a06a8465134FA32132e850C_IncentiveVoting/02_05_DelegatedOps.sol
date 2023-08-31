// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
    @title Prisma Delegated Operations
    @notice Allows delegation to specific contract functionality. Useful for creating
            wrapper contracts to bundle multiple interactions into a single call.

            Functions that supports delegation should include an `account` input allowing
            the delegated caller to indicate who they are calling on behalf of. In executing
            the call, all internal state updates should be applied for `account` and all
            value transfers should occur to or from the caller.

            For example: a delegated call to `openTrove` should transfer collateral
            from the caller, create the debt position for `account`, and send newly
            minted tokens to the caller.
 */
contract DelegatedOps {
    mapping(address owner => mapping(address caller => bool isApproved)) public isApprovedDelegate;

    modifier callerOrDelegated(address _account) {
        require(msg.sender == _account || isApprovedDelegate[_account][msg.sender], "Delegate not approved");
        _;
    }

    function setDelegateApproval(address _delegate, bool _isApproved) external {
        isApprovedDelegate[msg.sender][_delegate] = _isApproved;
    }
}