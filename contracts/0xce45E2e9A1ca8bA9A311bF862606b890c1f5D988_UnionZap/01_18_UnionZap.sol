// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "Ownable.sol";
import "SafeERC20.sol";
import "IMultiMerkleStash.sol";
import "IMerkleDistributorV2.sol";
import "IUniV2Router.sol";
import "IWETH.sol";
import "ICvxCrvDeposit.sol";
import "IVotiumRegistry.sol";
import "IUniV3Router.sol";
import "ICurveV2Pool.sol";
import "ISwapper.sol";
import "UnionBase.sol";

contract UnionZap is Ownable, UnionBase {
    using SafeERC20 for IERC20;

    address public votiumDistributor =
        0x378Ba9B73309bE80BF4C2c027aAD799766a7ED5A;

    address private constant SUSHI_ROUTER =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address private constant CVXCRV_DEPOSIT =
        0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae;
    address public constant VOTIUM_REGISTRY =
        0x92e6E43f99809dF84ed2D533e1FD8017eb966ee2;
    address private constant T_TOKEN =
        0xCdF7028ceAB81fA0C6971208e83fa7872994beE5;
    address private constant T_ETH_POOL =
        0x752eBeb79963cf0732E9c0fec72a49FD1DEfAEAC;
    address private constant UNISWAP_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNIV3_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant WETH_TOKEN =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address[] public outputTokens;
    address public platform = 0x9Bc7c6ad7E7Cf3A6fCB58fb21e27752AC1e53f99;

    uint256 private constant DECIMALS = 1e9;
    uint256 public platformFee = 2e7;

    mapping(uint256 => address) private routers;
    mapping(uint256 => uint24) private fees;

    struct tokenContracts {
        address pool;
        address swapper;
        address distributor;
    }

    struct curveSwapParams {
        address pool;
        uint16 ethIndex;
    }

    mapping(address => tokenContracts) public tokenInfo;
    mapping(address => curveSwapParams) public curveRegistry;

    event Received(address sender, uint256 amount);
    event Distributed(uint256 amount, address token, address distributor);
    event VotiumDistributorUpdated(address distributor);
    event FundsRetrieved(address token, address to, uint256 amount);
    event CurvePoolUpdated(address token, address pool);
    event OutputTokenUpdated(
        address token,
        address pool,
        address swapper,
        address distributor
    );
    event PlatformFeeUpdated(uint256 _fee);
    event PlatformUpdated(address indexed _platform);

    constructor() {
        routers[0] = SUSHI_ROUTER;
        routers[1] = UNISWAP_ROUTER;
        fees[0] = 3000;
        fees[1] = 10000;
        curveRegistry[CVX_TOKEN] = curveSwapParams(CURVE_CVX_ETH_POOL, 0);
        curveRegistry[T_TOKEN] = curveSwapParams(T_ETH_POOL, 0);
    }

    /// @notice Add a pool and its swap params to the registry
    /// @param token - Address of the token to swap on Curve
    /// @param params - Address of the pool and WETH index there
    function addCurvePool(address token, curveSwapParams calldata params)
        external
        onlyOwner
    {
        curveRegistry[token] = params;
        IERC20(token).safeApprove(params.pool, 0);
        IERC20(token).safeApprove(params.pool, type(uint256).max);
        emit CurvePoolUpdated(token, params.pool);
    }

    /// @notice Add or update contracts used for distribution of output tokens
    /// @param token - Address of the output token
    /// @param params - The Curve pool and distributor associated w/ the token
    /// @dev No removal options to avoid indexing errors with swaps, pass 0 weight for unused assets
    /// @dev Pool needs to be Curve v2 pool with price oracle
    function updateOutputToken(address token, tokenContracts calldata params)
        external
        onlyOwner
    {
        assert(params.pool != address(0));
        // if we don't have any pool info, it's an addition
        if (tokenInfo[token].pool == address(0)) {
            outputTokens.push(token);
        }
        tokenInfo[token] = params;
        emit OutputTokenUpdated(
            token,
            params.pool,
            params.swapper,
            params.distributor
        );
    }

    /// @notice Remove a pool from the registry
    /// @param token - Address of token associated with the pool
    function removeCurvePool(address token) external onlyOwner {
        IERC20(token).safeApprove(curveRegistry[token].pool, 0);
        delete curveRegistry[token];
        emit CurvePoolUpdated(token, address(0));
    }

    /// @notice Change forwarding address in Votium registry
    /// @param _to - address that will be forwarded to
    /// @dev To be used in case of migration, rewards can be forwarded to
    /// new contracts
    function setForwarding(address _to) external onlyOwner {
        IVotiumRegistry(VOTIUM_REGISTRY).setRegistry(_to);
    }

    /// @notice Updates the part of incentives redirected to the platform
    /// @param _fee - the amount of the new platform fee (in BIPS)
    function setPlatformFee(uint256 _fee) external onlyOwner {
        platformFee = _fee;
        emit PlatformFeeUpdated(_fee);
    }

    /// @notice Updates the address to which platform fees are paid out
    /// @param _platform - the new platform wallet address
    function setPlatform(address _platform)
        external
        onlyOwner
        notToZeroAddress(_platform)
    {
        platform = _platform;
        emit PlatformUpdated(_platform);
    }

    /// @notice Update the votium contract address to claim for
    /// @param _distributor - Address of the new contract
    function updateVotiumDistributor(address _distributor)
        external
        onlyOwner
        notToZeroAddress(_distributor)
    {
        votiumDistributor = _distributor;
        emit VotiumDistributorUpdated(_distributor);
    }

    /// @notice Withdraws specified ERC20 tokens to the multisig
    /// @param tokens - the tokens to retrieve
    /// @param to - address to send the tokens to
    /// @dev This is needed to handle tokens that don't have ETH pairs on sushi
    /// or need to be swapped on other chains (NBST, WormholeLUNA...)
    function retrieveTokens(address[] calldata tokens, address to)
        external
        onlyOwner
        notToZeroAddress(to)
    {
        for (uint256 i; i < tokens.length; ++i) {
            address token = tokens[i];
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(to, tokenBalance);
            emit FundsRetrieved(token, to, tokenBalance);
        }
    }

    /// @notice Execute calls on behalf of contract in case of emergency
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        return (success, result);
    }

    /// @notice Set approvals for the tokens used when swapping
    function setApprovals() external onlyOwner {
        IERC20(CRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, 0);
        IERC20(CRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, type(uint256).max);

        IERC20(CRV_TOKEN).safeApprove(CURVE_CRV_ETH_POOL, 0);
        IERC20(CRV_TOKEN).safeApprove(CURVE_CRV_ETH_POOL, type(uint256).max);

        IERC20(CRV_TOKEN).safeApprove(CVXCRV_DEPOSIT, 0);
        IERC20(CRV_TOKEN).safeApprove(CVXCRV_DEPOSIT, type(uint256).max);

        IERC20(CVXCRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, 0);
        IERC20(CVXCRV_TOKEN).safeApprove(
            CURVE_CVXCRV_CRV_POOL,
            type(uint256).max
        );

        IERC20(CVXCRV_TOKEN).safeApprove(CVXCRV_STAKING_CONTRACT, 0);
        IERC20(CVXCRV_TOKEN).safeApprove(
            CVXCRV_STAKING_CONTRACT,
            type(uint256).max
        );
    }

    /// @notice Swap a token for ETH on Curve
    /// @dev Needs the token to have been added to the registry with params
    /// @param token - address of the token to swap
    /// @param amount - amount of the token to swap
    function _swapToETHCurve(address token, uint256 amount) internal {
        curveSwapParams memory params = curveRegistry[token];
        require(params.pool != address(0));
        IERC20(token).safeApprove(params.pool, 0);
        IERC20(token).safeApprove(params.pool, amount);
        ICurveV2Pool(params.pool).exchange_underlying(
            params.ethIndex ^ 1,
            params.ethIndex,
            amount,
            0
        );
    }

    /// @notice Swap a token for ETH
    /// @param token - address of the token to swap
    /// @param amount - amount of the token to swap
    /// @dev Swaps are executed via Sushi or UniV2 router, will revert if pair
    /// does not exist. Tokens must have a WETH pair.
    function _swapToETH(
        address token,
        uint256 amount,
        address router
    ) internal notToZeroAddress(router) {
        address[] memory _path = new address[](2);
        _path[0] = token;
        _path[1] = WETH_TOKEN;

        IERC20(token).safeApprove(router, 0);
        IERC20(token).safeApprove(router, amount);

        IUniV2Router(router).swapExactTokensForETH(
            amount,
            1,
            _path,
            address(this),
            block.timestamp + 1
        );
    }

    /// @notice Swap a token for ETH on UniSwap V3
    /// @param token - address of the token to swap
    /// @param amount - amount of the token to swap
    /// @param fee - the pool's fee
    function _swapToETHUniV3(
        address token,
        uint256 amount,
        uint24 fee
    ) internal {
        IERC20(token).safeApprove(UNIV3_ROUTER, 0);
        IERC20(token).safeApprove(UNIV3_ROUTER, amount);
        IUniV3Router.ExactInputSingleParams memory _params = IUniV3Router
            .ExactInputSingleParams(
                token,
                WETH_TOKEN,
                fee,
                address(this),
                block.timestamp + 1,
                amount,
                1,
                0
            );
        uint256 _wethReceived = IUniV3Router(UNIV3_ROUTER).exactInputSingle(
            _params
        );
        IWETH(WETH_TOKEN).withdraw(_wethReceived);
    }

    function _isEffectiveOutputToken(address _token, uint32[] calldata _weights)
        internal
        returns (bool)
    {
        for (uint256 j; j < _weights.length; ++j) {
            if (_token == outputTokens[j] && _weights[j] > 0) {
                return true;
            }
        }
        return false;
    }

    /// @notice Claims all specified rewards from Votium
    /// @param claimParams - an array containing the info necessary to claim for
    /// each available token
    /// @dev Used to retrieve tokens that need to be transferred
    function claim(IMultiMerkleStash.claimParam[] calldata claimParams)
        public
        onlyOwner
    {
        require(claimParams.length > 0, "No claims");
        // claim all from votium
        IMultiMerkleStash(votiumDistributor).claimMulti(
            address(this),
            claimParams
        );
    }

    /// @notice Claims all specified rewards and swaps them to ETH
    /// @param claimParams - an array containing the info necessary to claim
    /// @param routerChoices - the router to use for the swap
    /// @param claimBeforeSwap - whether to claim on Votium or not
    /// @param minAmountOut - min output amount in ETH value
    /// @param gasRefund - tx gas cost to refund to caller (ETH amount)
    /// @param weights - weight of output assets (cvxCRV, FXS, CVX...) in bips
    /// @dev routerChoices is a 3-bit bitmap such that
    /// 0b000 (0) - Sushi
    /// 0b001 (1) - UniV2
    /// 0b010 (2) - UniV3 0.3%
    /// 0b011 (3) - UniV3 1%
    /// 0b100 (4) - Curve
    /// Ex: 136 = 010 001 000 will swap token 1 on UniV3, 2 on UniV3, last on Sushi
    /// Passing 0 will execute all swaps on sushi
    /// @dev claimBeforeSwap is used in case 3rd party already claimed on Votium
    /// @dev weights must sum to 10000
    /// @dev gasRefund is computed off-chain w/ tenderly
    function swap(
        IMultiMerkleStash.claimParam[] calldata claimParams,
        uint256 routerChoices,
        bool claimBeforeSwap,
        uint256 minAmountOut,
        uint256 gasRefund,
        uint32[] calldata weights
    ) public onlyOwner {
        require(weights.length == outputTokens.length, "Invalid weight length");
        // claim if applicable
        if (claimBeforeSwap) {
            claim(claimParams);
        }

        // swap all claims to ETH
        for (uint256 i; i < claimParams.length; ++i) {
            address _token = claimParams[i].token;
            uint256 _balance = IERC20(_token).balanceOf(address(this));
            // avoid wasting gas / reverting if no balance
            if (_balance <= 1) {
                continue;
            } else {
                // leave one gwei to lower future claim gas costs
                // https://twitter.com/libevm/status/1474870670429360129?s=21
                _balance -= 1;
            }
            // unwrap WETH
            if (_token == WETH_TOKEN) {
                IWETH(WETH_TOKEN).withdraw(_balance);
            }
            // we handle swaps for output tokens later when distributing
            // so any non-zero output token will be skipped here
            else {
                // skip if output token
                if (_isEffectiveOutputToken(_token, weights)) {
                    continue;
                }
                // otherwise execute the swaps
                uint256 _choice = routerChoices & 7;
                if (_choice >= 4) {
                    _swapToETHCurve(_token, _balance);
                } else if (_choice >= 2) {
                    _swapToETHUniV3(_token, _balance, fees[_choice - 2]);
                } else {
                    _swapToETH(_token, _balance, routers[_choice]);
                }
                routerChoices = routerChoices >> 3;
            }
        }

        // slippage check
        assert(address(this).balance > minAmountOut);

        (bool success, ) = (tx.origin).call{value: gasRefund}("");
        require(success, "ETH transfer failed");
    }

    /// @notice Internal function used to sell output tokens for ETH
    /// @param _token - the token to sell
    /// @param _amount - how much of that token to sell
    function _sell(address _token, uint256 _amount) internal {
        if (_token == CRV_TOKEN) {
            _crvToEth(_amount, 0);
        } else if (_token == CVX_TOKEN) {
            _swapToETHCurve(_token, _amount);
        } else {
            IERC20(_token).safeTransfer(tokenInfo[_token].swapper, _amount);
            ISwapper(tokenInfo[_token].swapper).sell(_amount);
        }
    }

    /// @notice Internal function used to buy output tokens from ETH
    /// @param _token - the token to sell
    /// @param _amount - how much of that token to sell
    function _buy(address _token, uint256 _amount) internal {
        if (_token == CRV_TOKEN) {
            _ethToCrv(_amount, 0);
        } else if (_token == CVX_TOKEN) {
            _ethToCvx(_amount, 0);
        } else {
            (bool success, ) = tokenInfo[_token].swapper.call{value: _amount}(
                ""
            );
            require(success, "ETH transfer failed");
            ISwapper(tokenInfo[_token].swapper).buy(_amount);
        }
    }

    /// @notice Swap or lock all CRV for cvxCRV
    /// @param _minAmountOut - the min amount of cvxCRV expected
    /// @param _lock - whether to lock or swap
    /// @return the amount of cvxCrv obtained
    function _toCvxCrv(uint256 _minAmountOut, bool _lock)
        internal
        returns (uint256)
    {
        uint256 _crvBalance = IERC20(CRV_TOKEN).balanceOf(address(this));
        // swap on Curve if there is a premium for doing so
        if (!_lock) {
            return _swapCrvToCvxCrv(_crvBalance, address(this), _minAmountOut);
        }
        // otherwise deposit & lock
        // slippage check
        assert(_crvBalance > _minAmountOut);
        ICvxCrvDeposit(CVXCRV_DEPOSIT).deposit(_crvBalance, true);
        return _crvBalance;
    }

    /// @notice Compute and takes fees if possible
    /// @dev If not enough ETH to take fees, can be applied on merkle distribution
    /// @param _totalEthBalance - the total ETH value of assets in the contract
    /// @return the ETH value of fees
    function _levyFees(uint256 _totalEthBalance) internal returns (uint256) {
        uint256 _feeAmount = (_totalEthBalance * platformFee) / DECIMALS;
        if (address(this).balance >= _feeAmount) {
            (bool success, ) = (platform).call{value: _feeAmount}("");
            require(success, "ETH transfer failed");
            return _feeAmount;
        }
        return 0;
    }

    function _balanceSalesAndBuy(
        bool lock,
        uint32[] calldata weights,
        uint32[] calldata adjustOrder,
        uint256[] calldata minAmounts,
        uint256[] memory prices,
        uint256[] memory amounts,
        uint256 _totalEthBalance
    ) internal {
        address _outputToken;
        uint256 _orderIndex;

        for (uint256 i; i < adjustOrder.length; ++i) {
            _orderIndex = adjustOrder[i];
            // if weight == 0, the token would have been swapped already so no balance
            if (weights[_orderIndex] > 0) {
                _outputToken = outputTokens[_orderIndex];
                // amount adjustments
                uint256 _desired = (_totalEthBalance * weights[_orderIndex]) /
                    DECIMALS;
                if (amounts[_orderIndex] > _desired) {
                    _sell(
                        _outputToken,
                        (((amounts[_orderIndex] - _desired) * 1e18) /
                            prices[_orderIndex])
                    );
                } else {
                    uint256 _swapAmount = _desired - amounts[_orderIndex];
                    if (i == adjustOrder.length - 1) {
                        _swapAmount = address(this).balance;
                    }
                    _buy(_outputToken, _swapAmount);
                }
                // we need an edge case here since it's too late
                // to update the cvxCRV distributor's stake function
                if (_outputToken == CRV_TOKEN) {
                    // convert all CRV to cvxCRV
                    _toCvxCrv(minAmounts[_orderIndex], lock);
                } else {
                    // slippage check
                    assert(
                        IERC20(_outputToken).balanceOf(address(this)) >
                            minAmounts[_orderIndex]
                    );
                }
            }
        }
    }

    /// @notice Splits contract balance into output tokens as per weights
    /// @param lock - whether to lock or swap crv to cvxcrv
    /// @param weights - weight of output assets (cvxCRV, FXS, CVX) in bips
    /// @param adjustOrder - order in which to process output tokens when adjusting
    /// @param minAmounts - min amount out of each output token (cvxCRV for CRV)
    /// @dev weights must sum to 10000
    /// @dev for adjustOrder token to be processed first should have smallest weight
    ///      but largest balance in contract.
    function adjust(
        bool lock,
        uint32[] calldata weights,
        uint32[] calldata adjustOrder,
        uint256[] calldata minAmounts
    ) public onlyOwner validWeights(weights) {
        require(
            minAmounts.length == outputTokens.length,
            "Invalid min amounts"
        );
        require(
            adjustOrder.length == outputTokens.length,
            "Invalid order length"
        );
        // start calculating the allocations of output tokens
        uint256 _totalEthBalance = address(this).balance;

        uint256[] memory prices = new uint256[](outputTokens.length);
        uint256[] memory amounts = new uint256[](outputTokens.length);
        address _outputToken;

        // first loop to calculate total ETH amounts and store oracle prices
        for (uint256 i; i < weights.length; ++i) {
            if (weights[i] > 0) {
                _outputToken = outputTokens[i];
                prices[i] = ICurveV2Pool(tokenInfo[_outputToken].pool)
                    .price_oracle();
                // compute ETH value of current token balance
                amounts[i] =
                    (IERC20(_outputToken).balanceOf(address(this)) *
                        prices[i]) /
                    1e18;
                // add the ETH value of token to current ETH value in contract
                _totalEthBalance += amounts[i];
            }
        }

        // deduce fees if applicable
        _totalEthBalance -= _levyFees(_totalEthBalance);

        // second loop to balance the amounts with buys and sells before distribution
        // according to order of liquidation specified in adjustOrder
        _balanceSalesAndBuy(
            lock,
            weights,
            adjustOrder,
            minAmounts,
            prices,
            amounts,
            _totalEthBalance
        );
    }

    /// @notice Deposits rewards to their respective merkle distributors
    /// @param weights - weights of output assets (cvxCRV, FXS, CVX...)
    function distribute(uint32[] calldata weights)
        public
        onlyOwner
        validWeights(weights)
    {
        for (uint256 i; i < weights.length; ++i) {
            if (weights[i] > 0) {
                address _outputToken = outputTokens[i];
                address _distributor = tokenInfo[_outputToken].distributor;
                IMerkleDistributorV2(_distributor).freeze();
                // edge case for CRV as we gotta keep using existing distributor
                if (_outputToken == CRV_TOKEN) {
                    _outputToken = CVXCRV_TOKEN;
                }
                uint256 _balance = IERC20(_outputToken).balanceOf(
                    address(this)
                );
                // transfer to distributor
                IERC20(_outputToken).safeTransfer(_distributor, _balance);
                // stake
                IMerkleDistributorV2(_distributor).stake();
                emit Distributed(_balance, _outputToken, _distributor);
            }
        }
    }

    /// @notice Swaps all bribes, adjust according to output token weights and distribute
    /// @dev Wrapper over the swap, adjust & distribute function
    /// @param claimParams - an array containing the info necessary to claim
    /// @param routerChoices - the router to use for the swap
    /// @param claimBeforeSwap - whether to claim on Votium or not
    /// @param gasRefund - tx gas cost to refund to caller (ETH amount)
    /// @param weights - weight of output assets (cvxCRV, FXS, CVX...) in bips
    /// @param adjustOrder - order in which to process output tokens when adjusting
    /// @param minAmounts - min amount out of each output token (cvxCRV for CRV)
    function processIncentives(
        IMultiMerkleStash.claimParam[] calldata claimParams,
        uint256 routerChoices,
        bool claimBeforeSwap,
        bool lock,
        uint256 gasRefund,
        uint32[] calldata weights,
        uint32[] calldata adjustOrder,
        uint256[] calldata minAmounts
    ) external onlyOwner {
        require(
            minAmounts.length == outputTokens.length,
            "Invalid min amounts"
        );
        swap(
            claimParams,
            routerChoices,
            claimBeforeSwap,
            0,
            gasRefund,
            weights
        );
        adjust(lock, weights, adjustOrder, minAmounts);
        distribute(weights);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier validWeights(uint32[] calldata _weights) {
        require(
            _weights.length == outputTokens.length,
            "Invalid weight length"
        );
        uint256 _totalWeights;
        for (uint256 i; i < _weights.length; ++i) {
            _totalWeights += _weights[i];
        }
        require(_totalWeights == DECIMALS, "Invalid weights");
        _;
    }
}