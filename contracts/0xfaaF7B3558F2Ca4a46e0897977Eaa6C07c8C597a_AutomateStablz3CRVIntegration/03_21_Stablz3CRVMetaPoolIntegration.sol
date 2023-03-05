//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/fees/IStablzFeeHandler.sol";
import "contracts/integrations/curve/common/ICurve3CRVDepositZap.sol";
import "contracts/integrations/curve/common/ICurve3CRVGauge.sol";
import "contracts/integrations/curve/common/ICurve3CRVBasePool.sol";
import "contracts/integrations/curve/common/ICurve3CRVPool.sol";
import "contracts/integrations/curve/common/ICurve3CRVMinter.sol";
import "contracts/integrations/curve/common/ICurveSwap.sol";
import "contracts/integrations/common/StablzLPIntegration.sol";

/// @title Stablz 3CRV - Meta pool integration
contract Stablz3CRVMetaPoolIntegration is StablzLPIntegration {

    using SafeERC20 for IERC20;

    /// @dev Meta pool specific addresses
    address public immutable CRV_META_POOL;
    address public immutable CRV_GAUGE;

    /// @dev Common Curve contracts
    address public constant CRV_SWAP = 0x81C46fECa27B31F3ADC2b91eE4be9717d1cd3DD7;
    address internal constant CRV_DEPOSIT_ZAP = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;
    address internal constant CRV_MINTER = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    address internal constant CRV_BASE_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    /// @dev Underlying pool token addresses
    address public immutable META_TOKEN;
    address internal constant DAI_TOKEN = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC_TOKEN = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT_TOKEN = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /// @dev Curve tokens
    address internal constant CRV_TOKEN = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant LP_3CRV_TOKEN = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    mapping(address => uint) private _stablecoinIndex;

    uint[3] public emergencyWithdrawnTokens;

    /// @param _metaPool Meta pool address
    /// @param _gauge Gauge address
    /// @param _oracle Oracle address
    /// @param _feeHandler Fee handler address
    constructor(address _metaPool, address _gauge, address _oracle, address _feeHandler) StablzLPIntegration(_oracle, _feeHandler){
        require(_metaPool != address(0), "Stablz3CRVMetaPoolIntegration: _metaPool cannot be the zero address");
        require(_gauge != address(0), "Stablz3CRVMetaPoolIntegration: _gauge cannot be the zero address");
        CRV_META_POOL = _metaPool;
        CRV_GAUGE = _gauge;
        META_TOKEN = ICurve3CRVPool(CRV_META_POOL).coins(0);
        _stablecoinIndex[DAI_TOKEN] = 1;
        _stablecoinIndex[USDC_TOKEN] = 2;
        _stablecoinIndex[USDT_TOKEN] = 3;
    }

    /// @notice Calculate the amount of a given stablecoin received when withdrawing Meta pool LP tokens
    /// @param _stablecoin stablecoin address
    /// @param _metaPoolLPTokens Meta pool LP amount to remove
    /// @return uint Expected number of stablecoin tokens received
    function calcWithdrawalAmount(address _stablecoin, uint _metaPoolLPTokens) external view onlyWithdrawalTokens(_stablecoin) returns (uint) {
        return ICurve3CRVDepositZap(CRV_DEPOSIT_ZAP).calc_withdraw_one_coin(CRV_META_POOL, _metaPoolLPTokens, _getStablecoinIndex(_stablecoin));
    }

    /// @notice Calculate the amount of a given stablecoin received when withdrawing base pool LP (3CRV) tokens
    /// @param _stablecoin stablecoin address
    /// @param _3CRVLPTokens 3CRV LP amount to remove
    /// @return uint Expected number of stablecoin tokens received
    function calcRewardAmount(address _stablecoin, uint _3CRVLPTokens) external view onlyRewardTokens(_stablecoin) returns (uint) {
        return ICurve3CRVBasePool(CRV_BASE_POOL).calc_withdraw_one_coin(_3CRVLPTokens, _getBasePoolStablecoinIndex(_stablecoin));
    }

    /// @notice Check if an address is an accepted deposit token
    /// @param _token Token address
    /// @return bool true if it is a supported deposit token, false if not
    function isDepositToken(address _token) public override view returns (bool) {
        return _token == META_TOKEN || _isBasePoolToken(_token);
    }

    /// @notice Check if an address is an accepted withdrawal token
    /// @param _token Token address
    /// @return bool true if it is a supported withdrawal token, false if not
    function isWithdrawalToken(address _token) public override view returns (bool) {
        return _token == META_TOKEN || _isBasePoolToken(_token);
    }

    /// @notice Check if an address is an accepted reward token
    /// @param _token Token address
    /// @return bool true if it is a supported reward token, false if not
    function isRewardToken(address _token) public override view returns (bool) {
        return _isBasePoolToken(_token);
    }

    /// @notice Get the CRV to 3CRV swap route
    /// @return route Swap route for CRV to 3CRV
    function getCRVTo3CRVRoute() public pure returns (address[9] memory route) {
        route[0] = CRV_TOKEN;
        route[1] = 0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511;
        route[2] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        route[3] = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
        route[4] = USDT_TOKEN;
        route[5] = CRV_BASE_POOL;
        route[6] = LP_3CRV_TOKEN;
        return route;
    }

    /// @notice Get the CRV to 3CRV swap params
    /// @return swapParams Swap params for CRV to 3CRV
    function getCRVTo3CRVSwapParams() public pure returns (uint[3][4] memory swapParams) {
        swapParams[0][0] = 1;
        swapParams[0][2] = 3;
        swapParams[1][0] = 2;
        swapParams[1][2] = 3;
        swapParams[2][0] = 2;
        swapParams[2][2] = 7;
        return swapParams;
    }

    /// @dev Deposit stablecoins
    /// @param _stablecoin stablecoin to deposit
    /// @param _amount amount to deposit
    /// @param _minLPAmount minimum amount of LP to receive
    /// @return lpTokens Amount of LP tokens received from depositing
    function _farmDeposit(address _stablecoin, uint _amount, uint _minLPAmount) internal override returns (uint lpTokens) {
        uint[4] memory amounts = _constructAmounts(_stablecoin, _amount);
        IERC20(_stablecoin).safeIncreaseAllowance(CRV_DEPOSIT_ZAP, _amount);
        lpTokens = ICurve3CRVDepositZap(CRV_DEPOSIT_ZAP).add_liquidity(
            CRV_META_POOL,
            amounts,
            _minLPAmount
        );
        IERC20(CRV_META_POOL).safeIncreaseAllowance(CRV_GAUGE, lpTokens);
        ICurve3CRVGauge(CRV_GAUGE).deposit(lpTokens);
    }

    /// @dev Withdraw stablecoins
    /// @param _stablecoin chosen stablecoin to withdraw
    /// @param _lpTokens LP amount to remove
    /// @param _minAmount minimum amount of _stablecoin to receive
    /// @return received Amount of _stablecoin received from withdrawing _lpToken
    function _farmWithdrawal(address _stablecoin, uint _lpTokens, uint _minAmount) internal override returns (uint received) {
        ICurve3CRVGauge(CRV_GAUGE).withdraw(_lpTokens);

        IERC20(CRV_META_POOL).safeIncreaseAllowance(CRV_DEPOSIT_ZAP, _lpTokens);

        received = ICurve3CRVDepositZap(CRV_DEPOSIT_ZAP).remove_liquidity_one_coin(CRV_META_POOL, _lpTokens, _getStablecoinIndex(_stablecoin), _minAmount);
    }

    /// @dev Claim Curve rewards and convert them to 3CRV
    /// @param _minAmounts Minimum swap amounts for harvesting, index: 0 - USDD => 3CRV, 1 - CRV => 3CRV
    /// @return rewards Amount of 3CRV rewards harvested
    function _farmHarvest(uint[10] memory _minAmounts) internal override returns (uint rewards) {
        if (_minAmounts[0] > 0) {
            /// @dev claim Meta Token rewards, its possible for the gauge contract to changes it's reward token to a token other than the meta token
            /// therefore if this occurs, the owner/oracle should perform an emergency shutdown and a new contract should be redeployed to support this
            ICurve3CRVGauge(CRV_GAUGE).claim_rewards();
            uint metaTokenBalance = IERC20(META_TOKEN).balanceOf(address(this));
            rewards += _exchangeMetaTokenFor3CRV(metaTokenBalance, _minAmounts[0]);
        }
        if (_minAmounts[1] > 0) {
            /// @dev claim CRV rewards, this function call is expensive but is dependant on time since last call, not rewards
            ICurve3CRVMinter(CRV_MINTER).mint(CRV_GAUGE);
            uint crvBalance = IERC20(CRV_TOKEN).balanceOf(address(this));
            rewards += _swapCRVTo3CRV(crvBalance, _minAmounts[1]);
        }
        return rewards;
    }

    /// @dev Withdraw all LP in base tokens
    /// @param _metaPoolLPTokens Amount of Meta pool LP tokens
    /// @param _minAmounts Minimum amounts for withdrawal, index: 0 - 3CRV, 1 - DAI, 2 - USDC, 3 - USDT
    function _farmEmergencyWithdrawal(uint _metaPoolLPTokens, uint[10] memory _minAmounts) internal override {
        ICurve3CRVGauge(CRV_GAUGE).withdraw(_metaPoolLPTokens);

        uint basePoolLPTokens = ICurve3CRVPool(CRV_META_POOL).remove_liquidity_one_coin(_metaPoolLPTokens, 1, _minAmounts[0]);

        uint[3] memory minTokenAmounts = [_minAmounts[1], _minAmounts[2], _minAmounts[3]];
        emergencyWithdrawnTokens = _removeBasePoolLiquidity(basePoolLPTokens, minTokenAmounts);
    }

    /// @dev Transfer pro rata amount of stablecoins to user
    function _withdrawAfterShutdown() internal override {
        _mergeRewards();
        for (uint i; i < 3; i++) {
            address stablecoin = ICurve3CRVBasePool(CRV_BASE_POOL).coins(i);
            uint amount = emergencyWithdrawnTokens[i] * users[_msgSender()].lpBalance / totalActiveDeposits;
            IERC20(stablecoin).safeTransfer(_msgSender(), amount);
        }
    }

    /// @param _stablecoin Stablecoin address
    /// @param _minAmount minimum amount of _stablecoin to receive
    /// @return rewards Rewards claimed in _stablecoin
    function _claimRewards(address _stablecoin, uint _minAmount) internal override returns (uint rewards) {
        _mergeRewards();
        /// @dev rewards are 3CRV LP tokens
        uint heldRewards = users[_msgSender()].heldRewards;
        require(heldRewards > 0, "Stablz3CRVMetaPoolIntegration: No rewards available");

        users[_msgSender()].heldRewards = 0;

        rewards = _removeBasePoolLiquidityOneCoin(heldRewards, _stablecoin, _minAmount);

        IERC20(_stablecoin).safeTransfer(_msgSender(), rewards);
        return rewards;
    }

    /// @dev convert 3CRV fee to USDT and transfer to fee handler contract
    /// @param _minAmount minimum amount of USDT to receive
    function _handleFee(uint _minAmount) internal override {
        uint fee = totalUnhandledFee;
        totalUnhandledFee = 0;

        uint usdtFee = _removeBasePoolLiquidityOneCoin(fee, USDT_TOKEN, _minAmount);

        IERC20(USDT_TOKEN).safeTransfer(feeHandler, usdtFee);
    }

    /// @dev Construct an amounts array for a given stablecoin amount
    /// @param _stablecoin Stablecoin address
    /// @param _amount Amount of tokens
    /// @return amounts Array of amounts with the stablecoin index set to the amount
    function _constructAmounts(address _stablecoin, uint _amount) internal view returns (uint[4] memory amounts) {
        amounts[_stablecoinIndex[_stablecoin]] = _amount;
        return amounts;
    }

    /// @dev remove _lpTokens from base pool as _stablecoin
    /// @param _lpTokens LP amount to remove
    /// @param _stablecoin Stablecoin address
    /// @param _minAmount minimum amount of _stablecoin to receive
    /// @return received Amount of _stablecoin received
    function _removeBasePoolLiquidityOneCoin(uint _lpTokens, address _stablecoin, uint _minAmount) internal returns (uint received) {
        uint stablecoinBalanceBefore = IERC20(_stablecoin).balanceOf(address(this));
        ICurve3CRVBasePool(CRV_BASE_POOL).remove_liquidity_one_coin(_lpTokens, _getBasePoolStablecoinIndex(_stablecoin), _minAmount);
        uint stablecoinBalanceAfter = IERC20(_stablecoin).balanceOf(address(this));
        received = stablecoinBalanceAfter - stablecoinBalanceBefore;
    }

    /// @dev remove _lpTokens from base pool as underlying tokens
    /// @param _lpTokens LP amount to remove
    /// @param _minAmounts minimum amounts of each underlying token to receive
    /// @return received Amounts of each underlying token received
    function _removeBasePoolLiquidity(uint _lpTokens, uint[3] memory _minAmounts) internal returns (uint[3] memory received) {
        uint daiBalanceBefore = IERC20(DAI_TOKEN).balanceOf(address(this));
        uint usdcBalanceBefore = IERC20(USDC_TOKEN).balanceOf(address(this));
        uint usdtBalanceBefore = IERC20(USDT_TOKEN).balanceOf(address(this));
        ICurve3CRVBasePool(CRV_BASE_POOL).remove_liquidity(_lpTokens, _minAmounts);
        uint daiBalanceAfter = IERC20(DAI_TOKEN).balanceOf(address(this));
        uint usdcBalanceAfter = IERC20(USDC_TOKEN).balanceOf(address(this));
        uint usdtBalanceAfter = IERC20(USDT_TOKEN).balanceOf(address(this));
        received[0] = daiBalanceAfter - daiBalanceBefore;
        received[1] = usdcBalanceAfter - usdcBalanceBefore;
        received[2] = usdtBalanceAfter - usdtBalanceBefore;
        return received;
    }

    /// @dev Exchange Meta token for 3CRV if _amount is greater than zero
    /// @param _amount Amount of Meta tokens to swap to 3CRV
    /// @param _minAmount minimum amount of 3CRV to receive
    /// @return received Amount of 3CRV tokens received
    function _exchangeMetaTokenFor3CRV(uint _amount, uint _minAmount) internal returns (uint received) {
        IERC20(META_TOKEN).safeIncreaseAllowance(CRV_META_POOL, _amount);
        received = ICurve3CRVPool(CRV_META_POOL).exchange(
            0,
            1,
            _amount,
            _minAmount
        );
    }

    /// @dev Swap CRV to 3CRV
    /// @param _amount Amount of CRV tokens to swap to 3CRV
    /// @param _minAmount minimum amount of 3CRV to receive
    /// @return received Amount of 3CRV tokens received
    function _swapCRVTo3CRV(uint _amount, uint _minAmount) internal returns (uint received) {
        IERC20(CRV_TOKEN).safeIncreaseAllowance(CRV_SWAP, _amount);
        /// @dev swapping CRV to 3CRV may revert due to the swap contract being killed therefore it is recommended
        /// to harvest frequently to reduce any loss that may occur as a result of the swap contract being killed
        received = ICurveSwap(CRV_SWAP).exchange_multiple(
            getCRVTo3CRVRoute(),
            getCRVTo3CRVSwapParams(),
            _amount,
            _minAmount
        );
    }

    /// @param _token Token address
    /// @return bool true if _token is a base pool token, false if not
    function _isBasePoolToken(address _token) internal view returns (bool) {
        return _stablecoinIndex[_token] > 0;
    }

    /// @param _stablecoin Stablecoin address
    /// @return int128 Index of stablecoin in meta pool combined with base pool
    function _getStablecoinIndex(address _stablecoin) internal view returns (int128) {
        return int128(int(_stablecoinIndex[_stablecoin]));
    }

    /// @param _stablecoin Stablecoin address
    /// @return int128 Index of base pool stablecoin
    function _getBasePoolStablecoinIndex(address _stablecoin) internal view returns (int128) {
        return int128(int(_stablecoinIndex[_stablecoin] - 1));
    }
}