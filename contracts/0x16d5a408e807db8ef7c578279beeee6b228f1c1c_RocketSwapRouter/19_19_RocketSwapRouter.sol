// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.9;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

import "./lib/@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "./lib/@balancer-labs/v2-interfaces/contracts/solidity-utils/misc/IWETH.sol";

import "./interface/RocketStorageInterface.sol";
import "./interface/RocketDepositPool.sol";
import "./interface/RocketDAOProtocolSettingsDepositInterface.sol";
import "./interface/IrETH.sol";

/// @notice Routes swaps through Uniswap and Balancer liquidity sources
contract RocketSwapRouter {
    // Rocket Pool immutables
    RocketStorageInterface immutable rocketStorage;

    // Uniswap immutables
    ISwapRouter public immutable uniswapRouter;
    IQuoter public immutable uniswapQuoter;
    uint24 immutable uniswapPoolFee;

    // Balance immutables
    IVault public immutable balancerVault;
    bytes32 public immutable balancerPoolId;

    // Token addresses
    IrETH public immutable rETH;
    IWETH public immutable WETH;

    // Errors
    error LessThanMinimum(uint256 amountOut);
    error TransferFailed();

    /// @param _rocketStorage Address of Rocket Pool's main RocketStorage contract
    /// @param _wethAddress Address of WETH token
    /// @param _uniswapRouter Address of UniswapV2Router02
    /// @param _uniswapPoolFee The fee to identify which Uniswap pool to use
    /// @param _balancerVault Address of Balancer's vault contract
    /// @param _balancerPoolId ID of the liquidity pool on balancer to use
    constructor(address _rocketStorage, address _wethAddress, address _uniswapRouter, uint24 _uniswapPoolFee, address _uniswapQuoter, address _balancerVault, bytes32 _balancerPoolId) {
        rocketStorage = RocketStorageInterface(_rocketStorage);
        rETH = IrETH(rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))));
        WETH = IWETH(_wethAddress);

        uniswapRouter = ISwapRouter(_uniswapRouter);
        uniswapQuoter = IQuoter(_uniswapQuoter);
        uniswapPoolFee = _uniswapPoolFee;

        balancerVault = IVault(_balancerVault);
        balancerPoolId = _balancerPoolId;
    }

    receive() external payable {}

    /// @notice Executes a swap of ETH to rETH
    /// @param _uniswapPortion The portion to swap via Uniswap
    /// @param _balancerPortion The portion to swap via Balancer
    /// @param _minTokensOut Swap will revert if at least this amount of rETH is not output
    /// @param _idealTokensOut If the protocol can provide a better swap than this, it will swap as much as possible that way
    function swapTo(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut) external payable {
        // Get addresses from Rocket Pool
        RocketDepositPoolInterface depositPool = RocketDepositPoolInterface(rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketDepositPool"))));
        RocketDAOProtocolSettingsDepositInterface depositSettings = RocketDAOProtocolSettingsDepositInterface(rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketDAOProtocolSettingsDeposit"))));

        // Record balance before the swap
        uint256 balanceBefore = rETH.balanceOf(msg.sender);

        uint256 toExchange = msg.value;
        uint256 toDepositPool = 0;

        // Check in-protocol mint rate
        if (rETH.getRethValue(msg.value) >= _idealTokensOut) {
            // Query deposit pool settings
            bool depositPoolEnabled = depositSettings.getDepositEnabled();

            // If deposits are enabled, work out how much space there is and subtract that from amount swapping on exchanges
            if (depositPoolEnabled) {
                uint256 depositPoolBalance = depositPool.getBalance();
                uint256 maxDepositBalance = depositSettings.getMaximumDepositPoolSize();

                if (depositPoolBalance < maxDepositBalance) {
                    uint256 minDeposit = depositSettings.getMinimumDeposit();

                    toDepositPool = maxDepositBalance - depositPoolBalance;
                    if (toDepositPool > msg.value) {
                        toDepositPool = msg.value;
                    }

                    // Check deposit pool minimum deposit amount
                    if (toDepositPool < minDeposit) {
                        toDepositPool = 0;
                    } else {
                        toExchange = toExchange - toDepositPool;
                    }
                }
            }
        }

        // Calculate splits
        uint256 totalPortions = _uniswapPortion + _balancerPortion;
        uint256 toUniswap = toExchange * _uniswapPortion / totalPortions;
        uint256 toBalancer = toExchange - toUniswap;

        // Convert toExchange ETH to WETH
        WETH.deposit{value : toExchange}();

        // Execute swaps
        uniswapSwap(toUniswap, address(WETH), address(rETH), msg.sender);
        balancerSwap(toBalancer, address(WETH), address(rETH), payable(msg.sender));
        depositPoolDeposit(depositPool, toDepositPool, msg.sender);

        // Verify minimum out
        uint256 balanceAfter = rETH.balanceOf(msg.sender);
        uint256 amountOut = balanceAfter - balanceBefore;
        if (amountOut < _minTokensOut) {
            revert LessThanMinimum(amountOut);
        }
    }

    /// @notice Executes a swap of rETH to ETH. User should approve this contract to spend their rETH before calling.
    /// @param _uniswapPortion The portion to swap via Uniswap
    /// @param _balancerPortion The portion to swap via Balancer
    /// @param _minTokensOut Swap will revert if at least this amount of ETH is not output
    /// @param _idealTokensOut If the protocol can provide a better swap than this, it will swap as much as possible that way
    function swapFrom(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut, uint256 _tokensIn) external {
        // Record balance before the swap
        uint256 balanceBefore = msg.sender.balance;

        uint256 toExchange = _tokensIn;
        uint256 toBurn = 0;

        // Check in-protocol burn rate
        if (rETH.getEthValue(_tokensIn) >= _idealTokensOut) {
            uint256 totalCollateral = rETH.getTotalCollateral();
            if (totalCollateral > 0) {
                if (_tokensIn > totalCollateral) {
                    toBurn = totalCollateral;
                    toExchange = _tokensIn - toBurn;
                } else {
                    toBurn = _tokensIn;
                    toExchange = 0;
                }
            }
        }

        // Calculate splits
        uint256 totalPortions = _uniswapPortion + _balancerPortion;
        uint256 toUniswap = toExchange * _uniswapPortion / totalPortions;
        uint256 toBalancer = toExchange - toUniswap;

        // Collect tokens
        rETH.transferFrom(msg.sender, address(this), _tokensIn);

        // Execute swaps
        uniswapSwap(toUniswap, address(rETH), address(WETH), address(this));
        balancerSwap(toBalancer, address(rETH), address(WETH), payable(this));
        rethBurn(toBurn);

        // Convert WETH back to ETH
        WETH.withdraw(WETH.balanceOf(address(this)));
        (bool result,) = msg.sender.call{value : address(this).balance}("");
        if (!result) {
            revert TransferFailed();
        }

        // Verify minimum out
        uint256 balanceAfter = msg.sender.balance;
        uint256 amountOut = balanceAfter - balanceBefore;
        if (amountOut < _minTokensOut) {
            revert LessThanMinimum(amountOut);
        }
    }

    /// @dev Perform a swap via Rocket Pool deposit pool
    /// @param _depositPool Instance of the deposit pool
    /// @param _amount Amount of ETH to deposit
    /// @param _recipient Recipient of the minted rETH tokens
    function depositPoolDeposit(RocketDepositPoolInterface _depositPool, uint256 _amount, address _recipient) private {
        if (_amount == 0) {
            return;
        }

        _depositPool.deposit{value : _amount}();

        if (_recipient != address(this)) {
            uint256 rETHBalance = rETH.balanceOf(address(this));
            rETH.transfer(_recipient, rETHBalance);
        }
    }

    /// @dev Perform a burn of rETH via Rocket Pool
    /// @param _amount Amount of rETH to burn
    function rethBurn(uint256 _amount) private {
        if (_amount == 0) {
            return;
        }

        rETH.burn(_amount);
    }

    /// @dev Perform a swap via Uniswap
    /// @param _amount Amount of ETH to swap
    /// @param _from The token input
    /// @param _to The token output
    /// @param _recipient The recipient of the output tokens
    function uniswapSwap(uint256 _amount, address _from, address _to, address _recipient) private {
        if (_amount == 0) {
            return;
        }

        // Perform swap (don't care about amountOutMinimum here as we check overall slippage at end)
        ISwapRouter.ExactInputSingleParams memory params =
        ISwapRouter.ExactInputSingleParams({
            tokenIn : _from,
            tokenOut : _to,
            fee : uniswapPoolFee,
            recipient : _recipient,
            deadline : block.timestamp,
            amountIn : _amount,
            amountOutMinimum : 0,
            sqrtPriceLimitX96 : 0
        });

        // Approve the router to spend our WETH
        TransferHelper.safeApprove(_from, address(uniswapRouter), _amount);

        // The call to `exactInputSingle` executes the swap.
        uniswapRouter.exactInputSingle(params);
    }

    /// @dev Perform a swap via Balancer
    /// @param _amount Amount of ETH to swap
    /// @param _from The token input
    /// @param _to The token output
    /// @param _recipient The recipient of the output tokens
    function balancerSwap(uint256 _amount, address _from, address _to, address payable _recipient) private {
        if (_amount == 0) {
            return;
        }

        IVault.SingleSwap memory swap;
        swap.poolId = balancerPoolId;
        swap.kind = IVault.SwapKind.GIVEN_IN;
        swap.assetIn = IAsset(_from);
        swap.assetOut = IAsset(_to);
        swap.amount = _amount;

        IVault.FundManagement memory fundManagement;
        fundManagement.sender = address(this);
        fundManagement.recipient = _recipient;
        fundManagement.fromInternalBalance = false;
        fundManagement.toInternalBalance = false;

        // Approve the vault to spend our WETH
        TransferHelper.safeApprove(_from, address(balancerVault), _amount);

        // Execute swap
        balancerVault.swap(swap, fundManagement, 0, block.timestamp);
    }

    /// @notice Calculates optimal values for a swap from ETH to rETH. Very gas inefficient. Should be called offline
    /// via `eth_call` and should not be used on-chain
    /// @param _amount The amount of ETH to swap
    /// @param _steps The more number of steps used the more optimal the swap will be (10 is a reasonable number for most swaps)
    function optimiseSwapTo(uint256 _amount, uint256 _steps) external returns (uint256[2] memory portions, uint256 amountOut) {
        return optimiseSwap(address(WETH), address(rETH), _amount, _steps);
    }

    /// @notice Calculates optimal values for a swap from rETH to ETH. Very gas inefficient. Should be called offline
    /// via `eth_call` and should not be used on-chain
    /// @param _amount The amount of ETH to swap
    /// @param _steps The more number of steps used the more optimal the swap will be (10 is a reasonable number for most swaps)
    function optimiseSwapFrom(uint256 _amount, uint256 _steps) external returns (uint256[2] memory portions, uint256 amountOut) {
        return optimiseSwap(address(rETH), address(WETH), _amount, _steps);
    }

    /// @dev Simulates a call to `IVault.queryBatchSwap` and returns the amount out
    function simulateBalancerQuote(
        IVault.SwapKind kind,
        IVault.BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        IVault.FundManagement memory funds
    ) internal returns (uint256) {
        bytes memory input = abi.encodeWithSelector(IVault.queryBatchSwap.selector, kind, swaps, assets, funds);
        bytes memory output = RocketSwapRouter(this).simulate(address(balancerVault), input);
        int256[] memory assetDeltas = abi.decode(output, (int256[]));
        return uint256(-assetDeltas[1]);
    }

    /// @dev Simulates a call to Uniswap's `IQuoter` and returns the amount out
    function simulateUniswapQuote(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) internal returns (uint256 amountOut) {
        bytes memory input = abi.encodeWithSelector(uniswapQuoter.quoteExactInputSingle.selector, tokenIn, tokenOut, fee, amountIn, sqrtPriceLimitX96);
        bytes memory output = RocketSwapRouter(this).simulate(address(uniswapQuoter), input);
        return abi.decode(output, (uint256));
    }

    /// @dev Internal logic for swap optimisation
    function optimiseSwap(address _from, address _to, uint256 _amount, uint256 _steps) private returns (uint256[2] memory portions, uint256 amountOut) {
        uint256 perStep = _amount / _steps;

        IVault.BatchSwapStep[] memory balancerSwapStep = new IVault.BatchSwapStep[](1);
        balancerSwapStep[0].assetInIndex = 0;
        balancerSwapStep[0].assetOutIndex = 1;
        balancerSwapStep[0].poolId = balancerPoolId;
        balancerSwapStep[0].amount = perStep;

        IVault.FundManagement memory funds;
        funds.sender = address(this);
        funds.recipient = payable(address(this));
        funds.fromInternalBalance = false;
        funds.toInternalBalance = false;

        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(_from);
        assets[1] = IAsset(_to);

        uint256[2] memory lastOut;
        lastOut[0] = simulateUniswapQuote(_from, _to, uniswapPoolFee, perStep, 0);
        lastOut[1] = simulateBalancerQuote(IVault.SwapKind.GIVEN_IN, balancerSwapStep, assets, funds);

        uint256[2] memory delta;
        delta[0] = lastOut[0];
        delta[1] = lastOut[1];

        portions[0] = 0;
        portions[1] = 0;
        amountOut = 0;

        for (uint256 i = 0; i < _steps; i++) {
            if (delta[1] > delta[0]) {
                portions[1]++;
                amountOut += delta[1];

                if (i < _steps - 1) {
                    // Get amountOut of next step
                    balancerSwapStep[0].amount = perStep * (portions[1] + 1);
                    uint256 nextOut = simulateBalancerQuote(IVault.SwapKind.GIVEN_IN, balancerSwapStep, assets, funds);
                    delta[1] = nextOut - lastOut[1];
                    lastOut[1] = nextOut;
                }
            } else {
                portions[0]++;
                amountOut += delta[0];

                if (i < _steps - 1) {
                    // Get amountOut of next step
                    uint256 nextOut = simulateUniswapQuote(_from, _to, uniswapPoolFee, perStep * (portions[0] + 1), 0);
                    delta[0] = nextOut - lastOut[0];
                    lastOut[0] = nextOut;
                }
            }
        }
    }

    /// @notice Internal functionality that must be exposed externally as an implementation detail
    /// https://github.com/gnosis/util-contracts/blob/main/contracts/storage/StorageAccessible.sol
    function simulate(
        address targetContract,
        bytes memory calldataPayload
    ) public returns (bytes memory response) {
        require(msg.sender == address(this));

        // Suppress compiler warnings about not using parameters, while allowing
        // parameters to keep names for documentation purposes. This does not
        // generate code.
        targetContract;
        calldataPayload;

        assembly {
            let internalCalldata := mload(0x40)
            // Store `simulateAndRevert.selector`.
            mstore(internalCalldata, "\xb4\xfa\xba\x09")
            // Abuse the fact that both this and the internal methods have the
            // same signature, and differ only in symbol name (and therefore,
            // selector) and copy calldata directly. This saves us approximately
            // 250 bytes of code and 300 gas at runtime over the
            // `abi.encodeWithSelector` builtin.
            calldatacopy(
            add(internalCalldata, 0x04),
            0x04,
            sub(calldatasize(), 0x04)
            )

            // `pop` is required here by the compiler, as top level expressions
            // can't have return values in inline assembly. `call` typically
            // returns a 0 or 1 value indicated whether or not it reverted, but
            // since we know it will always revert, we can safely ignore it.
            pop(call(
            gas(),
            address(),
            0,
            internalCalldata,
            calldatasize(),
            // The `simulateAndRevert` call always reverts, and instead
            // encodes whether or not it was successful in the return data.
            // The first 32-byte word of the return data contains the
            // `success` value, so write it to memory address 0x00 (which is
            // reserved Solidity scratch space and OK to use).
            0x00,
            0x20
            ))


            // Allocate and copy the response bytes, making sure to increment
            // the free memory pointer accordingly (in case this method is
            // called as an internal function). The remaining `returndata[0x20:]`
            // contains the ABI encoded response bytes, so we can just write it
            // as is to memory.
            let responseSize := sub(returndatasize(), 0x20)
            response := mload(0x40)
            mstore(0x40, add(response, responseSize))
            returndatacopy(response, 0x20, responseSize)

            if iszero(mload(0x00)) {
                revert(add(response, 0x20), mload(response))
            }
        }
    }

    /// @notice Internal functionality that must be exposed externally as an implementation detail
    /// https://github.com/gnosis/util-contracts/blob/main/contracts/storage/StorageSimulation.sol
    function simulateAndRevert(
        address targetContract,
        bytes memory calldataPayload
    ) public {
        require(msg.sender == address(this));

        assembly {
            let success := call(
                gas(),
                targetContract,
                0,
                add(calldataPayload, 0x20),
                mload(calldataPayload),
                0,
                0
            )

            mstore(0x00, success)
            mstore(0x20, returndatasize())
            returndatacopy(0x40, 0, returndatasize())
            revert(0, add(returndatasize(), 0x40))
        }
    }
}