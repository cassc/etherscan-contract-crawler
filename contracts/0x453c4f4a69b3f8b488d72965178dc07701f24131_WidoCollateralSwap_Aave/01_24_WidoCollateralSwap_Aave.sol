// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IPoolAddressesProvider} from "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import {IFlashLoanSimpleReceiver} from "aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import {IPool} from "aave-v3-core/contracts/interfaces/IPool.sol";
import {IComet} from "./interfaces/IComet.sol";
import {LibCollateralSwap} from "./libraries/LibCollateralSwap.sol";
import {IWidoCollateralSwap} from "./interfaces/IWidoCollateralSwap.sol";
import {WidoRouter} from "../core/WidoRouter.sol";

/// @title WidoCollateralSwap_Aave
/// @notice Contract allows swapping Compound collateral from one token (TokenA) to the other (TokenB) without 
/// closing the borrowing position. The contract makes use of flash loans to first supply TokenB,
/// then withdraws TokenA and swaps it for TokenB and closes the flash loan.
contract WidoCollateralSwap_Aave is IFlashLoanSimpleReceiver, IWidoCollateralSwap, ReentrancyGuard {
    using SafeMath for uint256;

    /// @dev Aave addresses provider contract
    IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;

    /// @dev Aave Pool contract
    IPool public immutable override POOL;
    
    /// @dev Comet Market contract
    IComet public immutable COMET_MARKET;

    /// @dev Wido Router contract
    address public immutable WIDO_ROUTER;

    /// @dev Wido Token Manager contract
    address public immutable WIDO_TOKEN_MANAGER;

    error InvalidProvider();
    error InvalidInitiator();

    constructor(IPoolAddressesProvider _addressProvider, IComet _cometMarket, address payable _widoRouter) {
        ADDRESSES_PROVIDER = _addressProvider;
        POOL = IPool(_addressProvider.getPool());
        COMET_MARKET = _cometMarket;
        WIDO_ROUTER = _widoRouter;
        WIDO_TOKEN_MANAGER = address(WidoRouter(_widoRouter).widoTokenManager());
    }

    /// @notice Performs a Compound collateral swap using flash loan from Aave.
    /// @param existingCollateral The collateral currently locked in the Comet contract
    /// @param finalCollateral The final collateral desired collateral
    /// @param sigs The required signatures to allow and revoke permission to this contract
    /// @param swapCallData The calldata to swap one collateral for the other
    function swapCollateral(
        LibCollateralSwap.Collateral calldata existingCollateral,
        LibCollateralSwap.Collateral calldata finalCollateral,
        LibCollateralSwap.Signatures calldata sigs,
        bytes calldata swapCallData
    ) external override {
        bytes memory data = abi.encode(
            msg.sender,
            COMET_MARKET,
            existingCollateral,
            sigs,
            LibCollateralSwap.WidoSwap(WIDO_ROUTER, WIDO_TOKEN_MANAGER, swapCallData)
        );

        POOL.flashLoanSimple(
            address(this),
            finalCollateral.addr,
            finalCollateral.amount,
            data,
            0
        );
    }

    /// @notice Executes the collateral swap after receiving the flash-borrowed asset
    /// @dev Ensure that the contract can return the debt + premium, e.g., has
    ///      enough funds to repay and has approved the Pool to pull the total amount
    /// @param asset The address of the flash-borrowed asset
    /// @param amount The amount of the flash-borrowed asset
    /// @param premium The fee of the flash-borrowed asset
    /// @param params The byte-encoded params for the collateral swap passed when initiating the flashloan
    /// @return True if the execution of the operation succeeds, false otherwise
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override nonReentrant returns (bool) {
        if (initiator != address(this)) {
            revert InvalidInitiator();
        }
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