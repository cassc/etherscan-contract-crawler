// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { GovernanceParameter, ITenderizer } from "./ITenderizer.sol";
import "../token/ITenderToken.sol";
import { ITenderSwapFactory, ITenderSwap } from "../tenderswap/TenderSwapFactory.sol";
import "../tenderfarm/TenderFarmFactory.sol";
import "../libs/MathUtils.sol";
import "../helpers/SelfPermit.sol";

/**
 * @title Tenderizer is the base contract to be implemented.
 * @notice Tenderizer is responsible for all Protocol interactions (staking, unstaking, claiming rewards)
 * while also keeping track of user depsotis/withdrawals and protocol fees.
 * @dev New implementations are required to inherit this contract and override any required internal functions.
 */
abstract contract Tenderizer is Initializable, ITenderizer, SelfPermit {
    using SafeERC20 for IERC20;

    uint256 private constant MAX_FEE = 5 * 10**20;

    IERC20 public steak;
    ITenderToken public tenderToken;
    ITenderFarm public tenderFarm;
    ITenderSwap public tenderSwap;

    address public node;

    uint256 public protocolFee;
    uint256 public liquidityFee;
    uint256 public currentPrincipal; // Principal since last claiming earnings

    address public gov;

    modifier onlyGov() {
        _onlyGov();
        _;
    }

    function _initialize(
        IERC20 _steak,
        string memory _symbol,
        address _node,
        uint256 _protocolFee,
        uint256 _liquidityFee,
        ITenderToken _tenderTokenTarget,
        TenderFarmFactory _tenderFarmFactory,
        ITenderSwapFactory _tenderSwapFactory
    ) internal initializer {
        steak = _steak;
        node = _node;
        protocolFee = _protocolFee;
        liquidityFee = _liquidityFee;

        gov = msg.sender;

        // Clone TenderToken
        ITenderToken tenderToken_ = ITenderToken(Clones.clone(address(_tenderTokenTarget)));
        string memory tenderTokenSymbol = string(abi.encodePacked("t", _symbol));
        require(tenderToken_.initialize(_symbol, _symbol, ITotalStakedReader(address(this))), "FAIL_INIT_TENDERTOKEN");
        tenderToken = tenderToken_;

        tenderSwap = _tenderSwapFactory.deploy(
            ITenderSwapFactory.Config({
                token0: IERC20(address(tenderToken_)),
                token1: _steak,
                lpTokenName: string(abi.encodePacked(tenderTokenSymbol, "-", _symbol, " Swap Token")),
                lpTokenSymbol: string(abi.encodePacked(tenderTokenSymbol, "-", _symbol, "-SWAP"))
            })
        );

        // Transfer ownership from tenderizer to deployer so params an be changed directly
        // and no additional functions are needed on the tenderizer
        tenderSwap.transferOwnership(msg.sender);

        tenderFarm = _tenderFarmFactory.deploy(
            IERC20(address(tenderSwap.lpToken())),
            tenderToken_,
            ITenderizer(address(this))
        );
    }

    /// @inheritdoc ITenderizer
    function deposit(uint256 _amount) external override {
        _depositHook(msg.sender, _amount);
    }

    /// @inheritdoc ITenderizer
    function depositWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        selfPermit(address(steak), _amount, _deadline, _v, _r, _s);

        _depositHook(msg.sender, _amount);
    }

    /// @inheritdoc ITenderizer
    function unstake(uint256 _amount) external override returns (uint256) {
        require(_amount > 0, "ZERO_AMOUNT");

        require(tenderToken.burn(msg.sender, _amount), "TENDER_BURN_FAILED");
        // Execute state updates to pending withdrawals
        // Unstake tokens
        uint256 id = _unstake(msg.sender, node, _amount);
        currentPrincipal -= _amount;
        return id;
    }

    /// @inheritdoc ITenderizer
    function rescueUnlock() external override onlyGov returns (uint256) {
        return _unstake(address(this), node, _tokensToMigrate(node));
    }

    /// @inheritdoc ITenderizer
    function withdraw(uint256 _unstakeLockID) external override {
        // Execute state updates to pending withdrawals
        // Transfer tokens to _account
        _withdraw(msg.sender, _unstakeLockID);
    }

    /// @inheritdoc ITenderizer
    function rescueWithdraw(uint256 _unstakeLockID) external override onlyGov {
        _withdraw(address(this), _unstakeLockID);
    }

    /// @inheritdoc ITenderizer
    function claimRewards() external override {
        _claimRewards();
    }

    /// @inheritdoc ITenderizer
    function totalStakedTokens() external view override returns (uint256) {
        return _totalStakedTokens();
    }

    function _tokensToMigrate(
        address /*_node*/
    ) internal view virtual returns (uint256) {
        return currentPrincipal;
    }

    /// @inheritdoc ITenderizer
    function stake(uint256 _amount) external override onlyGov {
        // Execute state updates
        // approve pendingTokens for staking
        // Stake tokens
        _stake(_amount);
    }

    function setGov(address _gov) external virtual override onlyGov {
        emit GovernanceUpdate(GovernanceParameter.GOV, abi.encode(gov), abi.encode(_gov));
        gov = _gov;
    }

    function setNode(address _node) external virtual override onlyGov {
        emit GovernanceUpdate(GovernanceParameter.NODE, abi.encode(node), abi.encode(_node));
        node = _node;
    }

    function setSteak(IERC20 _steak) external virtual override onlyGov {
        emit GovernanceUpdate(GovernanceParameter.STEAK, abi.encode(steak), abi.encode(_steak));
        steak = _steak;
    }

    function setProtocolFee(uint256 _protocolFee) external virtual override onlyGov {
        require(_protocolFee <= MAX_FEE, "FEE_EXCEEDS_MAX");
        emit GovernanceUpdate(GovernanceParameter.PROTOCOL_FEE, abi.encode(protocolFee), abi.encode(_protocolFee));
        protocolFee = _protocolFee;
    }

    function setLiquidityFee(uint256 _liquidityFee) external virtual override onlyGov {
        require(_liquidityFee <= MAX_FEE, "FEE_EXCEEDS_MAX");
        emit GovernanceUpdate(GovernanceParameter.LIQUIDITY_FEE, abi.encode(liquidityFee), abi.encode(_liquidityFee));
        liquidityFee = _liquidityFee;
    }

    function setStakingContract(address _stakingContract) external override onlyGov {
        _setStakingContract(_stakingContract);
    }

    function setTenderFarm(ITenderFarm _tenderFarm) external override onlyGov {
        emit GovernanceUpdate(GovernanceParameter.TENDERFARM, abi.encode(tenderFarm), abi.encode(_tenderFarm));
        tenderFarm = _tenderFarm;
    }

    /// @inheritdoc ITenderizer
    function calcDepositOut(uint256 _amountIn) external view override returns (uint256) {
        return _calcDepositOut(_amountIn);
    }

    // Internal functions

    function _depositHook(address _for, uint256 _amount) internal {
        require(_amount > 0, "ZERO_AMOUNT");

        // Calculate tenderTokens to be minted
        uint256 amountOut = _calcDepositOut(_amount);

        // mint tenderTokens
        require(tenderToken.mint(_for, amountOut), "TENDER_MINT_FAILED");

        // Transfer tokens to tenderizer
        steak.safeTransferFrom(_for, address(this), _amount);

        _deposit(_for, _amount);
    }

    function _calcDepositOut(uint256 _amountIn) internal view virtual returns (uint256) {
        return _amountIn;
    }

    function _deposit(address _account, uint256 _amount) internal virtual;

    function _stake(uint256 _amount) internal virtual;

    function _unstake(
        address _account,
        address _node,
        uint256 _amount
    ) internal virtual returns (uint256 unstakeLockID);

    function _withdraw(address _account, uint256 _unstakeLockID) internal virtual;

    function _claimRewards() internal virtual {
        _claimSecondaryRewards();

        int256 rewards = _processNewStake();

        if (rewards > 0) {
            uint256 rewards_ = uint256(rewards);
            uint256 pFees = _calculateFees(rewards_, protocolFee);
            uint256 lFees = _calculateFees(rewards_, liquidityFee);
            currentPrincipal += (rewards_ - pFees - lFees);

            _collectFees(pFees);
            _collectLiquidityFees(lFees);
        } else if (rewards < 0) {
            uint256 rewards_ = uint256(-rewards);
            currentPrincipal -= rewards_;
        }

        _stake(steak.balanceOf(address(this)));
    }

    function _claimSecondaryRewards() internal virtual;

    function _processNewStake() internal virtual returns (int256 rewards);

    function _collectFees(uint256 fees) internal virtual {
        tenderToken.mint(gov, fees);
        currentPrincipal += fees;
        emit ProtocolFeeCollected(fees);
    }

    function _collectLiquidityFees(uint256 liquidityFees) internal virtual {
        // Don't transfer liquidity provider fees if there is no liquidity being farmed
        if (tenderFarm.nextTotalStake() <= 0) return;

        uint256 balBefore = tenderToken.balanceOf(address(this));
        tenderToken.mint(address(this), liquidityFees);
        currentPrincipal += liquidityFees;
        uint256 balAfter = tenderToken.balanceOf(address(this));
        uint256 stakeDiff = balAfter - balBefore;
        // minting sometimes generates a little less, due to share calculation
        // hence using the balance to transfer here
        tenderToken.approve(address(tenderFarm), stakeDiff);
        tenderFarm.addRewards(stakeDiff);
        emit LiquidityFeeCollected(stakeDiff);
    }

    function _calculateFees(uint256 _rewards, uint256 _feePerc) internal pure returns (uint256 fees) {
        return MathUtils.percOf(_rewards, _feePerc);
    }

    function _totalStakedTokens() internal view virtual returns (uint256) {
        return currentPrincipal;
    }

    function _setStakingContract(address _stakingContract) internal virtual;

    function _onlyGov() internal view {
        require(msg.sender == gov);
    }
}