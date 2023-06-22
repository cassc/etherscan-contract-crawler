// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IPoolAddressesProvider} from "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import {IFlashLoanSimpleReceiver} from "aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import {IPool} from "aave-v3-core/contracts/interfaces/IPool.sol";
import {IComet} from "./interfaces/IComet.sol";
import {LibCollateralSwap} from "./libraries/LibCollateralSwap.sol";
import {IWidoCollateralSwap} from "./interfaces/IWidoCollateralSwap.sol";

contract WidoCollateralSwap_Aave is IFlashLoanSimpleReceiver, IWidoCollateralSwap {
    using SafeMath for uint256;

    /// @dev Aave addresses provider contract
    IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;

    /// @dev Aave Pool contract
    IPool public immutable override POOL;

    error InvalidProvider();

    constructor(IPoolAddressesProvider _addressProvider) {
        ADDRESSES_PROVIDER = _addressProvider;
        POOL = IPool(_addressProvider.getPool());
    }

    /// @notice Performs a collateral swap with Aave
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

        POOL.flashLoanSimple(
            address(this),
            finalCollateral.addr,
            finalCollateral.amount,
            data,
            0
        );
    }

    /// @notice Executes an operation after receiving the flash-borrowed asset
    /// @dev Ensure that the contract can return the debt + premium, e.g., has
    ///      enough funds to repay and has approved the Pool to pull the total amount
    /// @param asset The address of the flash-borrowed asset
    /// @param amount The amount of the flash-borrowed asset
    /// @param premium The fee of the flash-borrowed asset
    /// @param params The byte-encoded params passed when initiating the flashloan
    /// @return True if the execution of the operation succeeds, false otherwise
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address /*initiator*/,
        bytes calldata params
    ) external override returns (bool) {
        if (msg.sender != address(POOL)) {
            revert InvalidProvider();
        }

        LibCollateralSwap.performCollateralSwap(asset, amount, premium, params);

        // approve loan provider to pull lent amount + fee
        IERC20(asset).approve(
            address(POOL),
            amount.add(premium)
        );

        return true;
    }
}