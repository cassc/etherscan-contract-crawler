// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

import {IERC3156FlashBorrower, IERC3156FlashLender} from "./interfaces/IERC3156.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IComet} from "./interfaces/IComet.sol";
import {LibCollateralSwap} from "./libraries/LibCollateralSwap.sol";
import {IWidoCollateralSwap} from "./interfaces/IWidoCollateralSwap.sol";

contract WidoCollateralSwap_ERC3156 is IERC3156FlashBorrower, IWidoCollateralSwap {
    using SafeMath for uint256;

    /// @dev ERC3156 lender contract
    IERC3156FlashLender public immutable loanProvider;

    /// @dev The typehash for the ERC-3156 `onFlashLoan` return
    bytes32 internal constant ON_FLASH_LOAN_RESPONSE = keccak256("ERC3156FlashBorrower.onFlashLoan");

    error InvalidProvider();

    constructor(IERC3156FlashLender _loanProvider) {
        loanProvider = _loanProvider;
    }

    /// @notice Performs a collateral swap
    /// @param existingCollateral The collateral currently locked in the Comet contract
    /// @param finalCollateral The final collateral desired collateral
    /// @param sigs The required signatures to allow and revoke permission to this contract
    /// @param swap The necessary data to swap one collateral for the other
    /// @param comet The address of the Comet contract to interact with
    function swapCollateral(
        LibCollateralSwap.Collateral calldata existingCollateral,
        LibCollateralSwap.Collateral calldata finalCollateral,
        LibCollateralSwap.Signatures calldata sigs,
        LibCollateralSwap.WidoSwap calldata swap,
        address comet
    ) external override {
        bytes memory data = abi.encode(
            msg.sender,
            comet,
            existingCollateral,
            sigs,
            swap
        );

        loanProvider.flashLoan(
            IERC3156FlashBorrower(this),
            finalCollateral.addr,
            finalCollateral.amount,
            data
        );
    }

    /// @notice Callback to be executed by the flash loan provider
    /// @dev Only allow-listed providers should have access
    function onFlashLoan(
        address /* initiator */,
        address borrowedAsset,
        uint256 borrowedAmount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        if (msg.sender != address(loanProvider)) {
            revert InvalidProvider();
        }

        LibCollateralSwap.performCollateralSwap(borrowedAsset, borrowedAmount, fee, data);

        // approve loan provider to pull lent amount + fee
        IERC20(borrowedAsset).approve(
            address(loanProvider),
            borrowedAmount.add(fee)
        );

        return ON_FLASH_LOAN_RESPONSE;
    }
}