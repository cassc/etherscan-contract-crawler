// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICustomError {
    /**********************************
     * Generic errors
     **********************************/
    error ZeroOwnerSet();

    /**********************************
     * Initializable
     **********************************/
    error ContractAlreadyInitialized();
    error ContractIsNotInitializing();
    error ContractIsInitializing();

    /**********************************
     * ReentrancyGuardUpgradeable
     **********************************/
    error ReentrantCall();

    /**********************************
     * PausableUpgradeable
     **********************************/
    error PausablePaused();
    error PausableNotPaused();

    /**********************************
     * UUPSUpgradeable
     **********************************/
    error MustBeCalledThroughDelegatecall();
    error MustBeCalledThroughActiveProxy();

    /**********************************
     * ERC1967UpgradeUpgradeable
     **********************************/
    error NewImplementationIsNotContract();
    error UnsupportedProxiableUUID();
    error NewImplementationIsNotUUPS();
    error NewAdminIsZeroAddress();
    error NewBeaconIsNotContract();
    error BeaconImplementationIsNotContract();
    error DelegateCallToNonContract();

    /**********************************
     * ERC721
     **********************************/
    error InvalidTokenID();
    error ApproveToCurrentOwner();
    error CallerNotTokenOwnerOrApproved();
    error TransferToNonERC721ReceiverImplementer();
    error MintToZeroAddress();
    error TokenAlreadyMinted();
    error TransferFromIncorrectOwner();
    error TransferToZeroAddress();
    error ApproveToCaller();

    /**********************************
     * ERC20Upgradeable
     **********************************/
    error DecreasedAllowanceBelowZero();
    error TransferFromZeroAddress();
    error TransferAmountExceedsBalance();
    error BurnFromZeroAddress();
    error BurnAmountExceedsBalance();
    error ApproveFromZeroAddress();
    error ApproveToZeroAddress();
    error InsufficientAllowance();

    /**********************************
     * SafeERC20Upgradeable
     **********************************/
    error ApproveFromNonZeroToNonZeroAllowance();
    error PermitDidNotSucceed();
    error ERC20OperationDidNotSucceed();
}