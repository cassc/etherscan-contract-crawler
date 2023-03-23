pragma solidity ^0.8.10;

// SPDX-License-Identifier: BUSL-1.1

import { IDataStructures } from "./IDataStructures.sol";

interface IBalanceReporter {
    /// @notice Report an increased KNOT balance that has come from beacon chain inflation rewards
    /// @dev This method only cares about active balance increases when effective balance is 32 (otherwise a slashing or leaking is assumed to have happened)
    /// @param _stakeHouse Associated StakeHouse for the KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    /// @param _eth2Report Beacon chain report for the given KNOT
    /// @param _signatureMetadata Signature over ETH2 data report ensuring the integrity of the data against a public node
    function balanceIncrease(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _signatureMetadata
    ) external;

    /// @notice When a KNOT has voluntarily withdrawn from the beacon chain, it can be reported here (for a healthy KNOT i.e. no bal reduction / slashing)
    /// @dev Assumption is that no slashing has happened and if it has, the appropriate slashing method should be called
    /// @param _stakeHouse Associated StakeHouse for the KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    /// @param _eth2Report Beacon chain report for the given KNOT
    /// @param _signatureMetadata Authenticating the beacon chain report
    function voluntaryWithdrawal(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _signatureMetadata
    ) external;

    /// @dev Adaptor extension for reporting a balance reduction and or slashing
    /// @param _stakeHouse Associated StakeHouse for the KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    /// @param _eth2Report Beacon chain report for the given KNOT
    /// @param _signatureMetadata Authenticating the beacon chain report
    function slash(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _signatureMetadata
    ) external;

    /// @notice Allows for reporting of a balance reduction of a validator that is still performing duties + topping up that SLOT at the same time
    /// @param _stakeHouse Associated StakeHouse for the KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    /// @param _slasher Address slashing the validator's collateralised SLOT registry
    /// @param _buyAmount Amount of SLOT purchasing in the same transaction which is not the same as amount being slashed (dictated by latest balance)
    /// @param _eth2Report Beacon chain report for the given KNOT
    /// @param _signatureMetadata Authenticating the beacon chain report
    function slashAndTopUpSlot(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        address _slasher,
        uint256 _buyAmount,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _signatureMetadata
    ) external payable;

    /// @dev Adaptor extension for topping up slashed SLOT tokens
    /// @param _stakeHouse Associated StakeHouse for the KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    /// @param _recipient - Address receiving the collateralised SLOT tokens
    /// @param _amount - Amount being bought
    function topUpSlashedSlot(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        address _recipient,
        uint256 _amount
    ) external payable;

    /// @notice for a healthy and active KNOT that wants to exit the StakeHouse universe and burn all their dETH and SLOT, use this method
    /// @dev This method assumes msg.sender owns all tokens
    /// @param _stakeHouse Associated StakeHouse for the KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    /// @param _eth2Report Beacon chain report for the given KNOT
    /// @param _signatureMetadata Authenticating the beacon chain report
    function rageQuitKnot(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _signatureMetadata
    ) external payable;

    /// @notice for a healthy and active KNOT that wants to exit the StakeHouse universe and burn all their dETH and SLOT, use this method if multi party coordination is required via signatures
    /// @param _stakeHouse Address of the registry containing the KNOT
    /// @param _blsPublicKey BLS public key of the KNOT that is part of the house
    /// @param _ethRecipient Account that will be the recipient of the ETH that comes from the beacon chain balance of the BLS public key
    /// @param _eth2Report Beacon chain report containing the latest state of the KNOT
    /// @param _reportAndTokenHolderSignatures Signatures for report, free floating slot owner, savETH index owner and collateralised SLOT holders
    function multipartyRageQuit(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        address _ethRecipient,
        address _freeFloatingSlotOwner,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature[] calldata _reportAndTokenHolderSignatures
    ) external payable;

    /// @notice Allows a KNOT owner to manually top up a KNOT by sending ETH to the Ethereum Foundation deposit contract
    /// @param _blsPublicKey KNOT ID i.e. BLS public key of the validator
    function topUpKNOT(bytes calldata _blsPublicKey) external payable;
}