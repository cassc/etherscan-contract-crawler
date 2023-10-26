// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";

import {IVaultManager, Role} from "./interfaces/IVaultManager.sol";
import {IUSDVMain, Delta} from "../usdv/interfaces/IUSDVMain.sol";
import {Vault} from "./libs/Vault.sol";
import {Asset} from "./libs/Asset.sol";
import {Governance} from "./libs/Governance.sol";
import {IVaultRateLimiter} from "./interfaces/IVaultRateLimiter.sol";

struct MinterInfo {
    address addr;
    bool paused;
    bool registered;
}

/// @notice (1) secure the 1:1 peg (2) handle the yield payout (3) handle the remint/redeem fee
contract VaultManager is IVaultManager, Proxied, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeCast for uint;
    using Vault for Vault.Info;
    using Asset for Asset.Info;
    using Governance for Governance.Info;

    uint8 internal constant USDV_DECIMALS = 6;
    uint32 internal constant UINT32_MAX = type(uint32).max;

    IUSDVMain public usdv;

    // governance and fees
    Governance.Info public govInfo;
    mapping(uint32 color => int64) public pendingRemint; // a cached delta pool
    mapping(Role role => uint64 amount) public roleFees;

    // assets
    Vault.Info public usdvVault;
    mapping(address token => Asset.Info) internal assetInfos;
    address[] public assets;
    IVaultRateLimiter public rateLimiter;

    // minter registry
    mapping(address minter => uint32 color) public minterToColor;
    mapping(uint32 color => MinterInfo) public colorToMinter;
    uint32 public maxAssignedColor;

    modifier onlyRole(Role _role) {
        if (msg.sender != govInfo.roles[_role]) revert Unauthorized();
        if (_role == Role.OPERATOR) govInfo.ping();
        _;
    }

    modifier notZeroAmount(uint _amount) {
        if (_amount == 0) revert InvalidAmount();
        _;
    }

    function initialize(
        IUSDVMain _usdv,
        address _lp,
        address _operator,
        address _foundation
    ) external proxied initializer {
        __ReentrancyGuard_init();
        __Pausable_init();

        usdv = _usdv;

        // owner
        govInfo.roles[Role.OWNER] = msg.sender;
        govInfo.fees[Role.OWNER] = Governance.Fee(100, Governance.RESERVE_FEE_BPS_CAP); // 1%

        // foundation
        govInfo.roles[Role.FOUNDATION] = _foundation;
        // use foundation here to store operator redemption fee
        govInfo.fees[Role.FOUNDATION] = Governance.Fee(10, Governance.ONE_HUNDRED_PERCENT); // 0.1%

        // liquidity provider
        govInfo.roles[Role.LIQUIDITY_PROVIDER] = _lp;
        govInfo.fees[Role.LIQUIDITY_PROVIDER] = Governance.Fee(2000, 2000); // 20%

        // operator
        govInfo.roles[Role.OPERATOR] = _operator;
        govInfo.fees[Role.OPERATOR] = Governance.Fee(3000, 3000); // 30%
        govInfo.ping();
    }

    // ========================= OnlyOwner =========================
    // @dev set global pause
    function setPaused(bool _paused) external onlyRole(Role.OWNER) {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setRateLimiter(address _rateLimiter) external onlyRole(Role.OWNER) {
        rateLimiter = IVaultRateLimiter(_rateLimiter);
        emit SetRateLimiter(_rateLimiter);
    }

    /// @dev whitelisting new assets as collateral for issuing USDV
    function registerAsset(address _token) external onlyRole(Role.OWNER) {
        if (_token == address(0x0) || _token == address(usdv)) revert InvalidArgument();
        assetInfos[_token].initialize(_token, USDV_DECIMALS);
        assets.push(_token);
        emit RegisteredAsset(_token);
    }

    // @dev set enabled to false to disable minting of asset
    function setAssetEnabled(address _token, bool _enabled) external onlyRole(Role.OWNER) {
        assetInfos[_token].setEnabled(_enabled);
        emit EnabledAsset(_enabled);
    }

    function setRole(Role _role, address _addr) external {
        // both owner and self are valid for all roles config
        bool validCaller = msg.sender == govInfo.roles[_role] || msg.sender == govInfo.roles[Role.OWNER];

        // foundation can only change the operator if
        //  (a) the operator is address(0x0) or
        //  (b) the operator has not interacted with the contract for 30 day
        if (_role == Role.OPERATOR) {
            if (
                !validCaller &&
                (govInfo.roles[Role.OPERATOR] == address(0) || block.timestamp - govInfo.operatorLastPing > 30 days)
            ) {
                validCaller = msg.sender == govInfo.roles[Role.FOUNDATION];
            }
            govInfo.ping(); // reset operator last ping
        }

        if (!validCaller) revert Unauthorized();
        govInfo.roles[_role] = _addr;
        emit SetRole(_role, _addr);
    }

    // ========================= ByRole =========================
    function setFeeBpsCap(Role _role, uint16 _cap) external {
        if (_role == Role.OPERATOR) {
            _assertLpAndOperatorFeeCap(_cap, Role.LIQUIDITY_PROVIDER);
        } else if (_role == Role.LIQUIDITY_PROVIDER) {
            _assertLpAndOperatorFeeCap(_cap, Role.OPERATOR);
        } else if (_role == Role.FOUNDATION) {
            // use foundation role here to store operator redemption fee
            // foundation sets the fee cap to regulate the behaviour
            if (msg.sender != govInfo.roles[Role.FOUNDATION]) revert Unauthorized();
            if (_cap < Governance.REDEMPTION_FEE_BPS_CAP_MIN || _cap > Governance.ONE_HUNDRED_PERCENT)
                revert InvalidAmount();
        } else {
            // other roles cannot change the fee cap
            revert InvalidArgument();
        }
        govInfo.fees[_role].cap = _cap;
        emit SetFeeBpsCap(_role, _cap);
    }

    function setFeeBps(Role _role, uint16 _bps) external {
        _authenticateFeeRole(_role);
        if (_bps > govInfo.fees[_role].cap) revert InvalidAmount();
        govInfo.fees[_role].bps = _bps;
        emit SetFeeBps(_role, _bps);
    }

    function withdrawFees(Role _role, address _receiver) external nonReentrant whenNotPaused returns (uint64 fees) {
        _authenticateFeeRole(_role);
        fees = roleFees[_role];
        if (fees == 0) revert InvalidAmount();

        // there may be rounding error that the usdv vault balance is not enough to pay the reward
        uint64 balance = usdv.balanceOf(address(this)).toUint64();
        fees = balance >= fees ? fees : balance;

        roleFees[_role] -= fees;

        usdv.transfer(_receiver, fees); // don't check return value, usdv won't fail silently

        emit WithdrewFees(msg.sender, _receiver, fees);
    }

    // ========================= OnlyOperator =========================
    function registerMinter(address _minter) external onlyRole(Role.OPERATOR) returns (uint32 color) {
        if (_minter == address(0x0)) revert InvalidArgument();
        if (minterToColor[_minter] != 0) revert InvalidArgument();

        color = ++maxAssignedColor;
        if (color == UINT32_MAX) revert InvalidColor(color); // theta color invalid

        colorToMinter[color] = MinterInfo(_minter, false, true);
        minterToColor[_minter] = color;
        emit SetMinter(_minter, color);
    }

    /// @dev set paused to true to disable minting of color and minter from withdrawing rewards
    /// @dev does not disable remint as it would break IFG
    function setColorPaused(uint32 _color, bool _paused) external onlyRole(Role.OPERATOR) {
        if (!colorToMinter[_color].registered) revert InvalidColor(_color);
        colorToMinter[_color].paused = _paused;
        emit PausedColor(_color, _paused);
    }

    function ping() external onlyRole(Role.OPERATOR) {
        // ping called in onlyRole modifier
    }

    /// @dev unregistered color will have addr as 0x0, don't need to check color here
    function rotateMinter(uint32 _color, address _newAddr) external onlyRole(Role.OPERATOR) {
        if (_newAddr == address(0x0)) revert InvalidArgument();
        MinterInfo memory minter = colorToMinter[_color];
        if (!minter.registered) revert InvalidColor(_color);

        // new minter must not already be assigned to a color
        if (minterToColor[_newAddr] != 0) revert InvalidArgument();

        minterToColor[minter.addr] = 0;
        colorToMinter[_color].addr = _newAddr;
        minterToColor[_newAddr] = _color;
        emit SetMinter(_newAddr, _color);
    }

    // ========================= OnlyUSDV =========================
    /// @dev if change in delta results in negative vault shares, all vault share changes will be stored (including surplus)
    /// @dev remint fee will still be handled
    /// @dev all colors returned from side chains must be valid, don't need to validate registered color here
    /// @param _deltas position 0 always the surplus
    function remint(Delta[] calldata _deltas, uint64 _remintFee) external nonReentrant whenNotPaused {
        if (msg.sender != address(usdv)) revert Unauthorized();

        (bool pending, uint64 totalBurnt) = validateDeltas(_deltas);

        // handle deficits first
        Delta calldata delta;
        uint64 remintFeeRemaining = _remintFee;
        uint length = _deltas.length;
        for (uint i = 1; i < length; i++) {
            delta = _deltas[i];

            // deficit
            _burnVST(delta.color, delta.amount, pending);

            // pro rata share of remint fee, last minter gets the remainder
            // delta.amount must be negative, checked in burnVST
            if (remintFeeRemaining > 0) {
                uint64 remintFee = i == length - 1
                    ? remintFeeRemaining
                    : uint64((uint(uint64(-delta.amount)) * _remintFee) / totalBurnt);
                remintFeeRemaining -= remintFee;
                usdvVault.addRewardByColor(delta.color, remintFee);
            }
        }
        // handle surplus last, or it may overflow totalShares
        delta = _deltas[0];
        _mintVST(delta.color, delta.amount, pending);

        if (pending) {
            emit PendingRemint(_deltas);
        }
    }

    // ========================= External =========================
    /// @dev mint tokens with collateral
    /// @dev minting disabled when color paused
    /// @param _color color of the token
    /// @param _usdvAmount the amount of USDV to mint
    function mint(
        address _token, // must be whitelisted assets like STBT
        address _receiver, // receiver of the minted USDV
        uint64 _usdvAmount, // target USDV amount to mint
        uint32 _color, // color of the USDV
        bytes32 _memo // a reserved field to record meaning extra data for mint
    ) external nonReentrant whenNotPaused {
        MinterInfo memory minter = colorToMinter[_color];
        if (!minter.registered) revert InvalidColor(_color);
        if (minter.paused) revert ColorPaused();

        _mint(_token, _receiver, _usdvAmount, _color, _memo, true);
    }

    /// @dev if deficit colors are unknown, it will have a delta of 0 and unused
    function redeem(
        address _token,
        address _receiver,
        uint64 _amount,
        uint64 _minAmount,
        uint32[] calldata _deficits
    ) external nonReentrant whenNotPaused notZeroAmount(_amount) returns (uint amountAfterFee) {
        if (_amount > Vault.INT64_MAX) revert Vault.Overflow();

        // burn USDV from msg.sender
        // usdv.burn will burn all surplus then minted
        // only returns negative delta
        Delta[] memory used = usdv.burn(msg.sender, _amount, _deficits);

        int64 pending = int64(_amount);
        for (uint i = 0; i < used.length; i++) {
            Delta memory delta = used[i];
            // delta.amount can be 0, as it only has surplus and no minted
            if (delta.amount < 0) {
                _burnVST(delta.color, delta.amount, false);
                pending += delta.amount;
            } else if (delta.amount > 0) {
                revert InvalidAmount();
            }
        }
        if (pending != 0) revert InvalidAmount();

        rateLimiter.tryBurn(msg.sender, _token, _amount);
        Asset.Info storage asset = assetInfos[_token];
        // transfer collateral to receiver
        amountAfterFee = asset.redeem(govInfo, _receiver, _amount, _minAmount);

        emit Redeemed(msg.sender, _amount);
    }

    /// @dev don't need to consider race condition
    /// @dev must be delta-zero
    /// @dev pending remint won't have unregistered colors, so no need to validate registered color here
    /// @param _deltas position 0 always the surplus, deficit in ascending order
    function clearPendingRemint(Delta[] calldata _deltas) external nonReentrant whenNotPaused {
        int64 totalDelta;

        Delta calldata delta;
        uint32 lastColor = 0;
        for (uint i = 1; i < _deltas.length; i++) {
            delta = _deltas[i];
            if (delta.color <= lastColor) revert InvalidColor(delta.color); // duplicated

            _clampPendingRemint(delta);
            _burnVST(delta.color, delta.amount, false);
            totalDelta += delta.amount;

            lastColor = delta.color;
        }
        // handle surplus last, or it may overflow totalShares
        delta = _deltas[0];

        _clampPendingRemint(delta);
        _mintVST(delta.color, delta.amount, false);
        totalDelta += delta.amount;

        if (totalDelta != 0) revert NotDeltaZero();
    }

    function distributeReward(address[] calldata _tokens) external nonReentrant whenNotPaused {
        (, , , uint32 defaultColor) = usdv.userStates(address(this));
        if (defaultColor == 0) revert InvalidColor(defaultColor);

        uint[] memory amounts = new uint[](_tokens.length);

        for (uint i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            Asset.Info storage asset = assetInfos[token];
            if (!asset.registered) continue; // skip if not registered

            // get distributable reward from rebasing asset
            uint rewardInUSDV = asset.distributable();
            uint limit = rateLimiter.tryMint(msg.sender, token, 0); // refill and get limit

            // cap reward by limit, otherwise it will revert on asset.credit()
            if (rewardInUSDV > limit) rewardInUSDV = limit;
            if (rewardInUSDV == 0) continue; // skip if no reward

            // mint to vault
            _mint(token, address(this), rewardInUSDV.toUint64(), defaultColor, 0x0, false);

            // book yield fees
            uint reserveFee = (rewardInUSDV * govInfo.fees[Role.OWNER].bps) / Governance.ONE_HUNDRED_PERCENT;
            rewardInUSDV -= reserveFee;
            roleFees[Role.OWNER] += reserveFee.toUint64();

            uint lpFee = (rewardInUSDV * govInfo.fees[Role.LIQUIDITY_PROVIDER].bps) / Governance.ONE_HUNDRED_PERCENT;
            roleFees[Role.LIQUIDITY_PROVIDER] += lpFee.toUint64();

            uint operatorFee = (rewardInUSDV * govInfo.fees[Role.OPERATOR].bps) / Governance.ONE_HUNDRED_PERCENT;
            roleFees[Role.OPERATOR] += operatorFee.toUint64();

            // add the afterFee to rewards pool for minters
            rewardInUSDV -= lpFee + operatorFee;
            usdvVault.addReward(rewardInUSDV);

            amounts[i] = rewardInUSDV;
        }

        emit DistributedReward(_tokens, amounts);
    }

    /// @dev msg.sender must be minter unless paused, then it must be operator
    /// @dev unregistered color won't have vault shares, don't need to check color here
    /// @dev also withdraws stored remint fee for the minter if any
    /// @param _color to clearStored for
    function withdrawReward(
        uint32 _color,
        address _receiver
    ) external nonReentrant whenNotPaused returns (uint64 reward) {
        MinterInfo memory minter = colorToMinter[_color];
        if (!minter.registered) revert InvalidColor(_color);
        // if paused, only operator can withdraw
        if (minter.paused) {
            if (msg.sender != govInfo.roles[Role.OPERATOR]) revert Unauthorized();
            govInfo.ping();
        } else if (msg.sender != minter.addr) revert Unauthorized();

        // first settle pending if any, then withdraw
        reward = usdvVault.withdrawPending(_color, usdv.balanceOf(address(this)).toUint64());
        if (reward == 0) revert InvalidAmount();

        usdv.transfer(_receiver, reward); // don't check return value, usdv won't fail silently
        emit WithdrewReward(msg.sender, _receiver, _color, reward);
    }

    // ========================= View =========================
    /// @dev returns deltas of pending remint in range [_startColor, _endColor)
    function getPendingRemints(uint32 _startColor, uint32 _endColor) external view returns (Delta[] memory deltas) {
        _endColor = _endColor == 0 ? maxAssignedColor + 1 : _endColor;

        uint32 index = 0;
        deltas = new Delta[](_endColor - _startColor);
        for (uint32 c = _startColor; c < _endColor; c++) {
            int64 delta = pendingRemint[c];
            if (delta != 0) {
                deltas[index++] = Delta(c, delta);
            }
        }
        // return only the non 0 items
        assembly {
            mstore(deltas, index)
        }
    }

    function colorBookOf(uint32 _color) external view returns (Vault.ColorBook memory) {
        return usdvVault.colorBooks[_color];
    }

    /// @dev rebased rewards, actual distributable subjected to rate limiting
    function distributable(address _token) external view returns (uint) {
        return assetInfos[_token].distributable();
    }

    function redeemOut(address _token, uint64 _amount) external view returns (uint) {
        return assetInfos[_token].redeemOutput(govInfo, _amount);
    }

    function getAssetsLength() external view returns (uint) {
        return assets.length;
    }

    /// @dev returns fees of:
    /// Role.FOUNDATION: redemption fee, withdrawn by operator
    /// Role.OWNER: reserve fee, withdrawn by owner
    /// Role.LIQUIDITY_PROVIDER: lp fee, withdrawn by lp
    /// Role.OPERATOR: operator fee, withdrawn by operator
    function feesOf(Role _role) external view returns (Governance.Fee memory) {
        return govInfo.fees[_role];
    }

    function roleOf(Role _role) public view returns (address) {
        return govInfo.roles[_role];
    }

    function getWithdrawableReward(uint32 _color) external view returns (uint64) {
        return usdvVault.getPendingReward(_color) + usdvVault.colorBooks[_color].rewards;
    }

    function totalShares() external view returns (uint64) {
        return usdvVault.totalShares;
    }

    function validateDeltas(Delta[] calldata _deltas) public view returns (bool invalid, uint64 totalBurnt) {
        for (uint i = 0; i < _deltas.length; i++) {
            Delta calldata delta = _deltas[i];
            if (delta.amount < 0) {
                uint64 burntAmount = uint64(-delta.amount);
                totalBurnt += burntAmount;

                // if deficit (we need to burn shares), check that there is enough shares
                uint64 shares = usdvVault.colorBooks[delta.color].shares;
                if (shares < burntAmount) {
                    invalid = true;
                }
            }
        }
    }

    function assetInfoOf(
        address _token
    ) external view returns (bool enabled, uint usdvToTokenRate, uint collateralized) {
        Asset.Info storage asset = assetInfos[_token];
        return (asset.enabled, asset.usdvToTokenRate, asset.collateralized);
    }

    // ========================= Internal =========================
    /// @dev using int64 for loss so we don't need to do casting when receiving delta
    function _burnVST(uint32 _color, int64 _loss, bool _pending) internal {
        if (_loss >= 0) revert InvalidAmount();
        if (_pending) {
            pendingRemint[_color] += _loss;
        } else {
            // burn shares from minter
            // loss must be < 0, so below casting is safe
            usdvVault.removeShares(_color, uint64(-_loss));
        }
    }

    /// @dev using int64 for gain so we don't need to do casting when receiving delta
    function _mintVST(uint32 _color, int64 _gain, bool _pending) internal {
        if (_gain <= 0) revert InvalidAmount();
        if (_pending) {
            pendingRemint[_color] += _gain;
        } else {
            // mint shares to minter
            // gain must be > 0, so below casting is safe
            usdvVault.addShares(_color, uint64(_gain));
        }
    }

    function _mint(
        address _token,
        address _receiver,
        uint64 _amount,
        uint32 _color,
        bytes32 _memo,
        bool _newFund
    ) internal notZeroAmount(_amount) {
        rateLimiter.tryMint(msg.sender, _token, _amount);
        // transfer collateral from msg.sender
        assetInfos[_token].credit(msg.sender, _amount, _newFund);

        // mint VST to minter
        if (_amount > Vault.INT64_MAX) revert Vault.Overflow();
        _mintVST(_color, int64(_amount), false);

        // if the caller is a donor, dont need to mint new USDV
        if (msg.sender != roleOf(Role.DONOR)) {
            // mint USDV to receiver
            usdv.mint(_receiver, _amount, _color);
        }

        emit Minted(_receiver, _color, _amount, _memo);
    }

    /// @dev authentication:
    /// Role.OPERATOR: operator fee, by operator
    /// Role.FOUNDATION: redemption fee, by operator
    /// Role.LIQUIDITY_PROVIDER: lp fee, by lp
    /// Role.OWNER: reserve fee, by owner
    function _authenticateFeeRole(Role _role) internal {
        if (_role == Role.OPERATOR || _role == Role.FOUNDATION) {
            // operator can change 2 fee types
            if (msg.sender != govInfo.roles[Role.OPERATOR]) revert Unauthorized(); // only operator
            govInfo.ping();
        } else if (_role == Role.LIQUIDITY_PROVIDER || _role == Role.OWNER) {
            if (msg.sender != govInfo.roles[_role]) revert Unauthorized();
        } else {
            revert InvalidArgument();
        }
    }

    function _clampPendingRemint(Delta calldata delta) internal {
        int64 pendingQuota = pendingRemint[delta.color];
        if (pendingQuota == 0) revert InvalidAmount();
        if (pendingQuota ^ delta.amount < 0) revert WrongSign();
        if (delta.amount < 0) {
            // deficit delta more than deficit quota, i.e. revert if quota(-10) > amount(-11)
            if (pendingQuota > delta.amount) revert InvalidAmount();
        } else {
            // surplus delta more than surplus quota, i.e. revert if quota(10) < amount(11)
            if (pendingQuota < delta.amount) revert InvalidAmount();
        }
        pendingRemint[delta.color] -= delta.amount;
    }

    // only owner can set cap for operator and lp
    /// @param _cap to set
    /// @param _cpRole counter party role to check against, either operator or lp
    function _assertLpAndOperatorFeeCap(uint16 _cap, Role _cpRole) internal view {
        if (msg.sender != govInfo.roles[Role.OWNER]) revert Unauthorized();
        if (_cap > Governance.ONE_HUNDRED_PERCENT || govInfo.fees[_cpRole].cap + _cap > Governance.ONE_HUNDRED_PERCENT)
            revert InvalidAmount();
    }
}