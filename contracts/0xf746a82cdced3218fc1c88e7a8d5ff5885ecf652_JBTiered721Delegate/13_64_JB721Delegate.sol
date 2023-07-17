// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IJBFundingCycleDataSource } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleDataSource.sol";
import { IJBDirectory } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import { IJBPayDelegate } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol";
import { IJBRedemptionDelegate } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRedemptionDelegate.sol";
import { IJBPaymentTerminal } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import { JBConstants } from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBConstants.sol";
import { JBPayParamsData } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBPayParamsData.sol";
import { JBDidPayData } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBDidPayData.sol";
import { JBDidRedeemData } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBDidRedeemData.sol";
import { JBRedeemParamsData } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBRedeemParamsData.sol";
import { JBPayDelegateAllocation } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBPayDelegateAllocation.sol";
import { JBRedemptionDelegateAllocation } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBRedemptionDelegateAllocation.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import { PRBMath } from "@paulrberg/contracts/math/PRBMath.sol";

import { IJB721Delegate } from "../interfaces/IJB721Delegate.sol";
import { ERC721 } from "./ERC721.sol";

/// @title JB721Delegate
/// @notice This delegate makes NFTs available to a project's contributors upon payment, and allows project owners to enable NFT redemption for treasury assets.
abstract contract JB721Delegate is
    ERC721,
    IJB721Delegate,
    IJBFundingCycleDataSource,
    IJBPayDelegate,
    IJBRedemptionDelegate
{
    //*********************************************************************//
    // --------------------------- custom errors ------------------------- //
    //*********************************************************************//

    error INVALID_PAYMENT_EVENT();
    error INVALID_REDEMPTION_EVENT();
    error UNAUTHORIZED_TOKEN(uint256 _tokenId);
    error UNEXPECTED_TOKEN_REDEEMED();
    error INVALID_REDEMPTION_METADATA();

    //*********************************************************************//
    // --------------- public immutable stored properties ---------------- //
    //*********************************************************************//

    /// @notice The Juicebox project ID this contract's functionality applies to.
    uint256 public override projectId;

    /// @notice The directory of terminals and controllers for projects.
    IJBDirectory public override directory;

    //*********************************************************************//
    // ------------------------- external views -------------------------- //
    //*********************************************************************//

    /// @notice This function gets called when the project receives a payment. It sets this contract as the delegate to get a callback from the terminal. Part of IJBFundingCycleDataSource.
    /// @param _data The Juicebox standard project payment data.
    /// @return weight The weight that tokens should get minted in accordance with.
    /// @return memo A memo to be forwarded to the event.
    /// @return delegateAllocations Amount to be sent to delegates instead of adding to local balance.
    function payParams(JBPayParamsData calldata _data)
        public
        view
        virtual
        override
        returns (uint256 weight, string memory memo, JBPayDelegateAllocation[] memory delegateAllocations)
    {
        // Forward the received weight and memo, and use this contract as a pay delegate.
        weight = _data.weight;
        memo = _data.memo;
        delegateAllocations = new JBPayDelegateAllocation[](1);
        delegateAllocations[0] = JBPayDelegateAllocation(this, 0);
    }

    /// @notice This function gets called when the project's (NFT) token holders redeem. Part of IJBFundingCycleDataSource.
    /// @param _data Standard Juicebox project redemption data.
    /// @return reclaimAmount Amount to be reclaimed from the treasury.
    /// @return memo A memo to be forwarded to the event.
    /// @return delegateAllocations Amount to be sent to delegates instead of being added to the beneficiary.
    function redeemParams(JBRedeemParamsData calldata _data)
        public
        view
        virtual
        override
        returns (uint256 reclaimAmount, string memory memo, JBRedemptionDelegateAllocation[] memory delegateAllocations)
    {
        // Make sure fungible project tokens aren't also being redeemed.
        if (_data.tokenCount > 0) revert UNEXPECTED_TOKEN_REDEEMED();

        // Check the 4 bytes interfaceId and handle the case where the metadata was not intended for this contract
        // Skip 32 bytes reserved for generic extension parameters.
        if (_data.metadata.length < 36 || bytes4(_data.metadata[32:36]) != type(IJB721Delegate).interfaceId) {
            revert INVALID_REDEMPTION_METADATA();
        }

        // Set the only delegate allocation to be a callback to this contract.
        delegateAllocations = new JBRedemptionDelegateAllocation[](1);
        delegateAllocations[0] = JBRedemptionDelegateAllocation(this, 0);

        // Decode the metadata
        (,, uint256[] memory _decodedTokenIds) = abi.decode(_data.metadata, (bytes32, bytes4, uint256[]));

        // Get a reference to the redemption rate of the provided tokens.
        uint256 _redemptionWeight = redemptionWeightOf(_decodedTokenIds, _data);

        // Get a reference to the total redemption weight.
        uint256 _total = totalRedemptionWeight(_data);

        // Get a reference to the linear proportion.
        uint256 _base = PRBMath.mulDiv(_data.overflow, _redemptionWeight, _total);

        // These conditions are all part of the same curve. Edge conditions are separated because fewer operation are necessary.
        if (_data.redemptionRate == JBConstants.MAX_REDEMPTION_RATE) {
            return (_base, _data.memo, delegateAllocations);
        }

        // Return the weighted overflow, and this contract as the delegate so that tokens can be deleted.
        return (
            PRBMath.mulDiv(
                _base,
                _data.redemptionRate
                    + PRBMath.mulDiv(_redemptionWeight, JBConstants.MAX_REDEMPTION_RATE - _data.redemptionRate, _total),
                JBConstants.MAX_REDEMPTION_RATE
                ),
            _data.memo,
            delegateAllocations
        );
    }

    //*********************************************************************//
    // -------------------------- public views --------------------------- //
    //*********************************************************************//

    /// @notice Returns the cumulative redemption weight of the given token IDs relative to the `totalRedemptionWeight`.
    /// @param _tokenIds The token IDs to calculate the cumulative redemption weight for.
    /// @param _data Standard Juicebox project redemption data.
    /// @return The cumulative redemption weight of the specified token IDs.
    function redemptionWeightOf(uint256[] memory _tokenIds, JBRedeemParamsData calldata _data)
        public
        view
        virtual
        returns (uint256)
    {
        _tokenIds; // Prevents unused var compiler and natspec complaints.
        _data; // Prevents unused var compiler and natspec complaints.
        return 0;
    }

    /// @notice Calculates the cumulative redemption weight of all token IDs.
    /// @param _data Standard Juicebox project redemption data.
    /// @return Total cumulative redemption weight of all token IDs.
    function totalRedemptionWeight(JBRedeemParamsData calldata _data) public view virtual returns (uint256) {
        _data; // Prevents unused var compiler and natspec complaints.
        return 0;
    }

    /// @notice Indicates if this contract adheres to the specified interface.
    /// @dev See {IERC165-supportsInterface}.
    /// @param _interfaceId The ID of the interface to check for adherence to.
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return _interfaceId == type(IJB721Delegate).interfaceId
            || _interfaceId == type(IJBFundingCycleDataSource).interfaceId
            || _interfaceId == type(IJBPayDelegate).interfaceId || _interfaceId == type(IJBRedemptionDelegate).interfaceId
            || _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
    }

    //*********************************************************************//
    // -------------------------- constructor ---------------------------- //
    //*********************************************************************//

    /// @notice Initializes the contract with project details and ERC721 token details.
    /// @param _projectId The ID of the project this contract's functionality applies to.
    /// @param _directory The directory of terminals and controllers for projects.
    /// @param _name The name of the token.
    /// @param _symbol The symbol representing the token.
    function _initialize(uint256 _projectId, IJBDirectory _directory, string memory _name, string memory _symbol)
        internal
    {
        ERC721._initialize(_name, _symbol);

        projectId = _projectId;
        directory = _directory;
    }

    //*********************************************************************//
    // ---------------------- external transactions ---------------------- //
    //*********************************************************************//

    /// @notice Mints an NFT to the contributor (_data.beneficiary) upon project payment if conditions are met. Part of IJBPayDelegate.
    /// @dev Reverts if the calling contract is not one of the project's terminals.
    /// @param _data Standard Juicebox project payment data.
    function didPay(JBDidPayData calldata _data) external payable virtual override {
        uint256 _projectId = projectId;

        // Make sure the caller is a terminal of the project, and that the call is being made on behalf of an interaction with the correct project.
        if (
            msg.value != 0 || !directory.isTerminalOf(_projectId, IJBPaymentTerminal(msg.sender))
                || _data.projectId != _projectId
        ) revert INVALID_PAYMENT_EVENT();

        // Process the payment.
        _processPayment(_data);
    }

    /// @notice Burns specified NFTs upon token holder redemption, reclaiming funds from the project's balance to _data.beneficiary. Part of IJBRedeemDelegate.
    /// @dev Reverts if the calling contract is not one of the project's terminals.
    /// @param _data Standard Juicebox project redemption data.
    function didRedeem(JBDidRedeemData calldata _data) external payable virtual override {
        // Make sure the caller is a terminal of the project, and that the call is being made on behalf of an interaction with the correct project.
        if (
            msg.value != 0 || !directory.isTerminalOf(projectId, IJBPaymentTerminal(msg.sender))
                || _data.projectId != projectId
        ) revert INVALID_REDEMPTION_EVENT();

        // Check the 4 bytes interfaceId and handle the case where the metadata was not intended for this contract.
        // Skip 32 bytes reserved for generic extension parameters.
        if (_data.metadata.length < 36 || bytes4(_data.metadata[32:36]) != type(IJB721Delegate).interfaceId) {
            revert INVALID_REDEMPTION_METADATA();
        }

        // Decode the metadata.
        (,, uint256[] memory _decodedTokenIds) = abi.decode(_data.metadata, (bytes32, bytes4, uint256[]));

        // Get a reference to the number of token IDs being checked.
        uint256 _numberOfTokenIds = _decodedTokenIds.length;

        // Keep a reference to the token ID being iterated upon.
        uint256 _tokenId;

        // Iterate through all tokens, burning them if the owner is correct.
        for (uint256 _i; _i < _numberOfTokenIds;) {
            // Set the token's ID.
            _tokenId = _decodedTokenIds[_i];

            // Make sure the token's owner is correct.
            if (_owners[_tokenId] != _data.holder) revert UNAUTHORIZED_TOKEN(_tokenId);

            // Burn the token.
            _burn(_tokenId);

            unchecked {
                ++_i;
            }
        }

        // Call the hook.
        _didBurn(_decodedTokenIds);
    }

    //*********************************************************************//
    // ---------------------- internal transactions ---------------------- //
    //*********************************************************************//

    /// @notice Process a received payment.
    /// @param _data Standard Juicebox project payment data.
    function _processPayment(JBDidPayData calldata _data) internal virtual {
        _data; // Prevents unused var compiler and natspec complaints.
    }

    /// @notice Executes after tokens have been burned via redemption.
    /// @param _tokenIds The IDs of the tokens that were burned.
    function _didBurn(uint256[] memory _tokenIds) internal virtual {
        _tokenIds;
    }
}