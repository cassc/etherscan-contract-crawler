// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import '@balancer-labs/v2-vault/contracts/interfaces/IMinimalSwapInfoPool.sol';
import '@balancer-labs/v2-vault/contracts/interfaces/IVault.sol';
import '@balancer-labs/v2-pool-utils/contracts/BalancerPoolToken.sol';

import './core/Storage.sol';
import './core/ProportionalLiquidity.sol';
import './core/FXSwaps.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Pausable} from '@openzeppelin/contracts/utils/Pausable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import './core/lib/OZSafeMath.sol';
import './core/lib/ABDKMathQuad.sol';

contract FXPool is IMinimalSwapInfoPool, BalancerPoolToken, Ownable, Storage, ReentrancyGuard, Pausable {
    using ABDKMath64x64 for int128;
    using ABDKMathQuad for int128;
    using ABDKMath64x64 for uint256;
    using OZSafeMath for uint256;

    uint256 public protocolPercentFee;
    int128 private constant ONE_WEI = 0x12;
    address public collectorAddress = address(0);
    uint256 public totalUnclaimedFeesInNumeraire = 0;

    struct SwapData {
        address originAddress;
        uint256 originAmount;
        address targetAddress;
        uint256 targetAmount;
        uint256 outputAmount;
    }

    // EVENTS
    event ParametersSet(uint256 alpha, uint256 beta, uint256 delta, uint256 epsilon, uint256 lambda);
    event AssetIncluded(address indexed numeraire, address indexed reserve, uint256 weight);
    event AssimilatorIncluded(
        address indexed derivative,
        address indexed numeraire,
        address indexed reserve,
        address assimilator
    );
    event EmergencyAlarm(bool isEmergency);
    event ChangeCollectorAddress(address newCollector);
    event OnJoinPool(bytes32 poolId, uint256 lptAmountMinted, uint256[] amountsDeposited);
    event OnExitPool(bytes32 poolId, uint256 lptAmountBurned, uint256[] amountsWithdrawn);
    event EmergencyWithdraw(bytes32 poolId, uint256 lptAmountBurned, uint256[] amountsWithdrawn);

    event Trade(
        address indexed trader,
        address indexed origin,
        address indexed target,
        uint256 originAmount,
        uint256 targetAmount
    );
    event FeesCollected(address recipient, uint256 feesCollected);
    event FeesAccrued(uint256 feesCollected);
    event ProtocolFeeShareUpdated(address updater, uint256 newProtocolPercentage);

    modifier isVault() {
        require(msg.sender == address(curve.vault), 'FXPool/caller-not-vault');
        _;
    }

    constructor(
        address[] memory _assetsToRegister,
        IVault vault,
        uint256 _protocolPercentFee,
        // uint256 _percentFeeGov,
        // address _governance,
        string memory _name,
        string memory _symbol
    ) BalancerPoolToken(_name, _symbol) {
        // Initialization on the vault
        protocolPercentFee = _protocolPercentFee;
        curve.vault = vault;

        bytes32 poolId = vault.registerPool(IVault.PoolSpecialization.TWO_TOKEN);
        curve.poolId = poolId;
        curve.fxPoolAddress = address(this);
        // Pass in zero addresses for Asset Managers
        // Functions below assume this token order
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = IERC20(_assetsToRegister[0]);
        tokens[1] = IERC20(_assetsToRegister[1]);

        vault.registerTokens(poolId, tokens, new address[](2));
    }

    /// @dev Initialize pool first to set assets, assimilators and weights
    function initialize(address[] memory _assets, uint256[] memory _assetWeights) external onlyOwner {
        require(_assetWeights.length == 2, 'FXPool/assetWeights-must-be-length-two');
        require(_assets.length % 5 == 0, 'FXPool/assets-must-be-divisible-by-five');

        for (uint256 i = 0; i < _assetWeights.length; i++) {
            uint256 ix = i * 5;

            numeraires.push(_assets[ix]);
            derivatives.push(_assets[ix]);

            reserves.push(_assets[2 + ix]);
            if (_assets[ix] != _assets[2 + ix]) derivatives.push(_assets[2 + ix]);

            includeAsset(
                //   curve,
                _assets[ix], // numeraire
                _assets[1 + ix], // numeraire assimilator
                _assets[2 + ix], // reserve
                _assets[3 + ix], // reserve assimilator
                // _assets[4 + ix], // reserve approve to
                _assetWeights[i]
            );
        }
    }

    /// @dev Returns the vault for this pool
    /// @return The vault for this pool
    function getVault() external view returns (IVault) {
        return curve.vault;
    }

    /// @dev Returns poolId from vault
    /// @return The poolId of this pool
    function getPoolId() external view override returns (bytes32) {
        return curve.poolId;
    }

    /// @dev Returns fee for psi/omega
    /// @return fee_
    function getFee() private view returns (int128 fee_) {
        int128 _gLiq;

        // Always pairs
        int128[] memory _bals = new int128[](2);

        for (uint256 i = 0; i < _bals.length; i++) {
            int128 _bal = Assimilators.viewNumeraireBalance(curve.assets[i].addr, address(curve.vault), curve.poolId);

            _bals[i] = _bal;

            _gLiq += _bal;
        }

        fee_ = CurveMath.calculateFee(_gLiq, _bals, curve.beta, curve.delta, curve.weights);
    }

    /// @dev Set pool curve dimensions needed to calculate liquidity functions and swaps
    function setParams(
        uint256 _alpha,
        uint256 _beta,
        uint256 _feeAtHalt,
        uint256 _epsilon,
        uint256 _lambda
    ) external onlyOwner {
        require(0 < _alpha && _alpha < 1e18, 'FXPool/parameter-invalid-alpha');

        require(_beta < _alpha, 'FXPool/parameter-invalid-beta');

        require(_feeAtHalt <= 5e17, 'FXPool/parameter-invalid-max');

        require(_epsilon <= 1e16, 'FXPool/parameter-invalid-epsilon');

        require(_lambda <= 1e18, 'FXPool/parameter-invalid-lambda');

        int128 _omega = getFee();

        curve.alpha = (_alpha + 1).divu(1e18);

        curve.beta = (_beta + 1).divu(1e18);

        curve.delta = (_feeAtHalt).divu(1e18).div(uint256(2).fromUInt().mul(curve.alpha.sub(curve.beta))) + ONE_WEI;

        curve.epsilon = (_epsilon + 1).divu(1e18);

        curve.lambda = (_lambda + 1).divu(1e18);

        int128 _psi = getFee();

        require(_omega >= _psi, 'FXPool/parameters-increase-fee');

        emit ParametersSet(_alpha, _beta, curve.delta.mulu(1e18), _epsilon, _lambda);
    }

    /// @dev add assets in storage
    function includeAsset(
        address _numeraire,
        address _numeraireAssim,
        address _reserve,
        address _reserveAssim,
        //   address _reserveApproveTo,
        uint256 _weight
    ) private {
        require(_numeraire != address(0), 'FXPool/numeraire-cannot-be-zeroth-address');

        require(_numeraireAssim != address(0), 'FXPool/numeraire-assimilator-cannot-be-zeroth-address');

        require(_reserve != address(0), 'FXPool/reserve-cannot-be-zeroth-address');

        require(_reserveAssim != address(0), 'FXPool/reserve-assimilator-cannot-be-zeroth-address');

        require(_weight < 1e18, 'FXPool/weight-must-be-less-than-one');

        // if (_numeraire != _reserve) IERC20(_numeraire).safeApprove(_reserveApproveTo, uint256(-1));
        Storage.Assimilator storage _numeraireAssimilator = curve.assimilators[_numeraire];

        _numeraireAssimilator.addr = _numeraireAssim;

        _numeraireAssimilator.ix = uint8(curve.assets.length);

        Storage.Assimilator storage _reserveAssimilator = curve.assimilators[_reserve];

        _reserveAssimilator.addr = _reserveAssim;

        _reserveAssimilator.ix = uint8(curve.assets.length);

        int128 __weight = _weight.divu(1e18).add(uint256(1).divu(1e18));

        curve.weights.push(__weight);

        curve.assets.push(_numeraireAssimilator);

        emit AssetIncluded(_numeraire, _reserve, _weight);

        emit AssimilatorIncluded(_numeraire, _numeraire, _reserve, _numeraireAssim);

        if (_numeraireAssim != _reserveAssim) {
            emit AssimilatorIncluded(_reserve, _numeraire, _reserve, _reserveAssim);
        }
    }

    /// @dev View curve dimensions/parameters
    function viewParameters()
        external
        view
        returns (
            uint256 alpha_,
            uint256 beta_,
            uint256 delta_,
            uint256 epsilon_,
            uint256 lambda_
        )
    {
        alpha_ = curve.alpha.mulu(1e18);

        beta_ = curve.beta.mulu(1e18);

        delta_ = curve.delta.mulu(1e18);

        epsilon_ = curve.epsilon.mulu(1e18);

        lambda_ = curve.lambda.mulu(1e18);
    }

    /// @dev Hook called by the Vault on swaps to quote prices and execute trade
    /// @param swapRequest The request which contains the details of the swap
    /// currentBalanceTokenIn The input token balance scaled to the base token decimals that the assimilators expect
    /// currentBalanceTokenOut The output token balance scaled to the quote token decimals (6 for USDC) that the assimilators expect
    /// @return the amount of the output or input token amount of for swap
    function onSwap(
        SwapRequest memory swapRequest,
        uint256,
        uint256
    ) external override whenNotPaused isVault returns (uint256) {
        require(msg.sender == address(curve.vault), 'Non Vault caller');

        bool isTargetSwap = swapRequest.kind == IVault.SwapKind.GIVEN_OUT;
        SwapData memory data;
        int128 fees;

        if (isTargetSwap) {
            // unpack swapRequest from external caller (FE or another contract)
            data = SwapData(
                address(swapRequest.tokenIn),
                0, // cause we're in targetSwap not originSwap
                address(swapRequest.tokenOut),
                swapRequest.amount,
                0
            );

            (data.outputAmount, fees) = FXSwaps.viewTargetSwap(
                curve,
                data.originAddress,
                data.targetAddress,
                data.targetAmount
            );
        } else {
            // unpack swapRequest from external caller (FE or another contract)
            data = SwapData(
                address(swapRequest.tokenIn),
                swapRequest.amount,
                address(swapRequest.tokenOut),
                0, // cause we're in originSwap not targetSwap
                0
            );

            (data.outputAmount, fees) = FXSwaps.viewOriginSwap(
                curve,
                data.originAddress,
                data.targetAddress,
                data.originAmount
            );
        }

        _calculateAndStoreUnclaimedProtocolFee(fees);
        emit Trade(msg.sender, data.originAddress, data.targetAddress, data.originAmount, data.outputAmount);
        return data.outputAmount;
    }

    /// @dev Hook for joining the pool that must be called from the vault.
    ///      It mints a proportional number of tokens compared to current LP pool,
    ///      based on the maximum input the user indicates.
    /// @param poolId The balancer pool id, checked to ensure non erroneous vault call
    // @param sender Unused by this pool but in interface
    /// @param recipient The address which will receive lp tokens.
    /// @param currentBalances The current pool balances, sorted by address low to high.  length 2
    // @param latestBlockNumberUsed last block number unused in this pool
    /// @param userData Abi encoded fixed length 2 array containing max inputs also sorted by
    ///                 address low to high
    /// @return amountsIn The actual amounts of token the vault should move to this pool
    /// @return dueProtocolFeeAmounts The amounts of each token to pay as protocol fees
    function onJoinPool(
        bytes32 poolId,
        address, // sender
        address recipient,
        uint256[] memory, // @todo for vault transfers
        uint256,
        uint256,
        bytes calldata userData
    )
        external
        override
        whenNotPaused
        isVault
        returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts)
    {
        (uint256 totalDepositNumeraire, address[] memory assetAddresses) = abi.decode(userData, (uint256, address[]));

        _enforceCap(totalDepositNumeraire);

        (uint256 lpTokens, uint256[] memory amountToDeposit) = ProportionalLiquidity.proportionalDeposit(
            curve,
            totalDepositNumeraire
        );

        {
            amountsIn = new uint256[](2);
            amountsIn[0] = amountToDeposit[_getAssetIndex(assetAddresses[0])];
            amountsIn[1] = amountToDeposit[_getAssetIndex(assetAddresses[1])];
        }

        // minting protocol fees before increasing the value of totalSupply
        _mintProtocolFees();
        BalancerPoolToken._mintPoolTokens(recipient, lpTokens);

        {
            dueProtocolFeeAmounts = new uint256[](2);
            dueProtocolFeeAmounts[0] = 0;
            dueProtocolFeeAmounts[1] = 0;
        }

        emit OnJoinPool(poolId, lpTokens, amountToDeposit);
    }

    /// @dev Hook for leaving the pool that must be called from the vault.
    ///      It burns a proportional number of tokens compared to current LP pool,
    ///      based on the minium output the user wants.
    /// @param poolId The balancer pool id, checked to ensure non erroneous vault call
    /// @param sender The address which is the source of the LP token
    // @param recipient Unused by this pool but in interface
    /// @param currentBalances The current pool balances, sorted by address low to high.  length 2
    // @param latestBlockNumberUsed last block number unused in this pool
    // @param protocolSwapFee The percent of pool fees to be paid to the Balancer Protocol
    /// @param userData Abi encoded uint256 which is the number of LP tokens the user wants to
    ///                 withdraw
    /// @return amountsOut The number of each token to send to the caller
    /// @return dueProtocolFeeAmounts The amounts of each token to pay as protocol fees
    function onExitPool(
        bytes32 poolId,
        address sender,
        address,
        uint256[] memory, // @todo for vault transfers
        uint256,
        uint256,
        bytes calldata userData
    ) external override isVault returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts) {
        (uint256 tokensToBurn, address[] memory assetAddresses) = abi.decode(userData, (uint256, address[]));

        uint256[] memory amountToWithdraw = emergency
            ? ProportionalLiquidity.emergencyProportionalWithdraw(curve, tokensToBurn)
            : ProportionalLiquidity.proportionalWithdraw(curve, tokensToBurn);

        // change state here since calculation using the previous supply is needed before deducting in the state
        // minting protocol fees before decreasing the value of totalSupply

        // burn first then mint protocol fees
        _mintProtocolFees();
        BalancerPoolToken._burnPoolTokens(sender, tokensToBurn);

        {
            amountsOut = new uint256[](2);
            amountsOut[0] = amountToWithdraw[_getAssetIndex(assetAddresses[0])];
            amountsOut[1] = amountToWithdraw[_getAssetIndex(assetAddresses[1])];
        }

        {
            dueProtocolFeeAmounts = new uint256[](2);
            dueProtocolFeeAmounts[0] = 0;
            dueProtocolFeeAmounts[1] = 0;
        }

        if (emergency) {
            emit EmergencyWithdraw(poolId, tokensToBurn, amountToWithdraw);
        } else {
            emit OnExitPool(poolId, tokensToBurn, amountToWithdraw);
        }
    }

    // ADMIN AND ACCESS CONTROL FUNCTIONS
    /// @notice Governance sets someone's pause status, enable only withdraw

    // SETTERS
    function setPaused() external onlyOwner {
        bool currentStatus = paused();

        if (currentStatus) {
            _unpause();
        } else {
            _pause();
        }
    }

    /// @notice Set cap for pool
    /// @param _cap cap value
    function setCap(uint256 _cap) external onlyOwner {
        (uint256 total, ) = liquidity();
        require(_cap > total, 'FXPool/cap-is-not-greater-than-total-liquidity');
        curve.cap = _cap;
    }

    /// @notice Set emergency alarm
    /// @param _emergency turn on or off
    function setEmergency(bool _emergency) external onlyOwner {
        emergency = _emergency;
        emit EmergencyAlarm(_emergency);
    }

    /// @notice Change collector address
    /// @param _collectorAddress collector's new address
    function setCollectorAddress(address _collectorAddress) external onlyOwner {
        collectorAddress = _collectorAddress;
        emit ChangeCollectorAddress(_collectorAddress);
    }

    /// @notice Change protocol percentage in fees
    /// @param _protocolPercentFee collector's new address
    function setProtocolPercentFee(uint256 _protocolPercentFee) external onlyOwner {
        protocolPercentFee = _protocolPercentFee;
        emit ProtocolFeeShareUpdated(msg.sender, protocolPercentFee);
    }

    // UTILITY VIEW FUNCTIONS

    /// @notice views the total amount of liquidity in the curve in numeraire value and format - 18 decimals
    /// @return total_ the total value in the curve
    /// @return individual_ the individual values in the curve
    function liquidity() public view returns (uint256 total_, uint256[] memory individual_) {
        return ProportionalLiquidity.viewLiquidity(curve);
    }

    /// @notice view the assimilator address for a derivative
    /// @return assimilator_ the assimilator address
    function assimilator(address _derivative) public view returns (address assimilator_) {
        assimilator_ = curve.assimilators[_derivative].addr;
    }

    /// @notice view LP tokens and token needed for deposit
    function viewDeposit(uint256 totalDepositNumeraire)
        external
        view
        whenNotPaused
        returns (uint256, uint256[] memory)
    {
        return ProportionalLiquidity.viewProportionalDeposit(curve, totalDepositNumeraire);
    }

    /// @notice view tokens to be received given LP tokens to burn
    function viewWithdraw(uint256 _curvesToBurn) external view returns (uint256[] memory) {
        return ProportionalLiquidity.viewProportionalWithdraw(curve, _curvesToBurn);
    }

    // INTERNAL LOGIC FUNCTIONS

    /// @dev get asset arrangement of the token in the vault
    function _getAssetIndex(address _assetAddress) internal view returns (uint256) {
        require(_assetAddress == derivatives[0] || _assetAddress == derivatives[1], 'FXPool/address-not-a-derivative');

        if (_assetAddress == derivatives[0]) {
            return 0;
        } else {
            return 1;
        }
    }

    function _enforceCap(uint256 _amount) private view {
        if (curve.cap == 0) return;

        (uint256 total, ) = liquidity();

        require(total + _amount < curve.cap, 'FXPool/amount-beyond-set-cap');
    }

    function _calculateAndStoreUnclaimedProtocolFee(int128 fees) private {
        // check if the protocol fee is on and fees are not negative. if both conditions are met, don't store fee
        if (_isProtocolMintingOn() && fees > 0) {
            uint256 feesToAdd = fees.abs().mulu(1e18).mul(protocolPercentFee).div(1e2);

            totalUnclaimedFeesInNumeraire += feesToAdd;

            emit FeesAccrued(feesToAdd);
        }
    }

    function _mintProtocolFees() private {
        if (_isProtocolMintingOn()) {
            (int128 _oGLiq, ) = ProportionalLiquidity.getGrossLiquidityAndBalancesForDeposit(curve);

            uint256 lpTokenFeeAmount = (_oGLiq.inv()).mulu(totalUnclaimedFeesInNumeraire);

            lpTokenFeeAmount = lpTokenFeeAmount.mul(totalSupply()).div(1e18);

            totalUnclaimedFeesInNumeraire = 0;
            BalancerPoolToken._mintPoolTokens(collectorAddress, lpTokenFeeAmount);

            emit FeesCollected(collectorAddress, lpTokenFeeAmount);
        }
    }

    function _isProtocolMintingOn() private view returns (bool) {
        return collectorAddress != address(0) && totalSupply() > 0;
    }
}