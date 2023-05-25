// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import {IRedeemableToken} from "proof/redemption/interfaces/IRedeemableToken.sol";
import {DiamondExhibition} from "../exhibition/DiamondExhibition.sol";
import {DiamondExhibitionRegularPass} from "../passes/DiamondExhibitionRegularPass.sol";
import {DiamondExhibitionChoicePass} from "../passes/DiamondExhibitionChoicePass.sol";
import {DiamondExhibitionSeller} from "./DiamondExhibitionSeller.sol";

/**
 * @notice Seller that redeems a Diamond Pass (either a Day One or Regular pass) for a piece in the Diamond Exhibition.
 */
contract DiamondPassRedeemer is DiamondExhibitionSeller {
    /**
     * @notice Emitted when the callback to the `IRedeemableToken` contract fails.
     */
    error RedeemableCallbackFailed(IRedeemableToken token, bytes reason);

    /**
     * @notice Emitted when the `IRedeemableToken` contract is not a valid pass.
     */
    error InvalidRedeemableToken(IRedeemableToken token);

    /**
     * @notice The regular Diamond Exhibition pass.
     */
    DiamondExhibitionRegularPass public immutable regularPass;

    /**
     * @notice The Day One Diamond Exhibition pass.
     */
    DiamondExhibitionChoicePass public immutable dayOnePass;

    constructor(
        DiamondExhibition exhibition,
        DiamondExhibitionRegularPass regularPass_,
        DiamondExhibitionChoicePass dayOnePass_
    ) DiamondExhibitionSeller(exhibition) {
        dayOnePass = dayOnePass_;
        regularPass = regularPass_;
    }

    /**
     * @notice Encodes a purchase.
     * @param redeemable The `IRedeemableToken` contract to redeem.
     * @param passId The tokenId of the pass to redeem.
     * @param projectId The project ID to purchase.
     */
    struct Purchase {
        IRedeemableToken redeemable;
        uint256 passId;
        uint8 projectId;
    }

    /**
     * @notice Redeems the given passes and purchases pieces in the Diamond Exhibition.
     */
    function purchase(Purchase[] calldata purchases) external {
        uint8[] memory projectIds = new uint8[](purchases.length);

        for (uint256 i = 0; i < purchases.length; ++i) {
            if (purchases[i].redeemable != regularPass && purchases[i].redeemable != dayOnePass) {
                revert InvalidRedeemableToken(purchases[i].redeemable);
            }

            try purchases[i].redeemable.redeem(msg.sender, purchases[i].passId) {}
            catch (bytes memory reason) {
                revert RedeemableCallbackFailed(purchases[i].redeemable, reason);
            }
            projectIds[i] = purchases[i].projectId;
        }

        _purchase(msg.sender, projectIds);
    }
}