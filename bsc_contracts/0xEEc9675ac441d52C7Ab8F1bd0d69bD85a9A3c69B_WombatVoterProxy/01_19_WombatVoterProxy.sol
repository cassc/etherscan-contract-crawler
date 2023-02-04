// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./Interfaces/IVirtualBalanceRewardPool.sol";
import "./Interfaces/IWombatVoterProxy.sol";
import "./Interfaces/Wombat/IBribe.sol";
import "./Interfaces/Wombat/IMasterWombatV2.sol";
import "./Interfaces/Wombat/IMasterWombatV3.sol";
import "./Interfaces/Wombat/IVeWom.sol";
import "./Interfaces/Wombat/IVoter.sol";
import "@shared/lib-contracts/contracts/Dependencies/TransferHelper.sol";

contract WombatVoterProxy is IWombatVoterProxy, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using TransferHelper for address;

    address public wom;
    IMasterWombatV2 public masterWombat;
    address public veWom;

    address public booster;
    address public depositor;

    IVoter public voter;
    address public bribeManager;
    uint256 constant FEE_DENOMINATOR = 10000;
    uint256 public bribeCallerFee;
    uint256 public bribeProtocolFee;
    address public bribeFeeCollector;

    modifier onlyBooster() {
        require(msg.sender == booster, "!auth");
        _;
    }

    modifier onlyDepositor() {
        require(msg.sender == depositor, "!auth");
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function setParams(
        address _masterWombat,
        address _booster,
        address _depositor
    ) external onlyOwner {
        require(booster == address(0), "!init");

        require(_masterWombat != address(0), "invalid _masterWombat!");
        require(_booster != address(0), "invalid _booster!");
        require(_depositor != address(0), "invalid _depositor!");

        masterWombat = IMasterWombatV2(_masterWombat);
        wom = masterWombat.wom();
        veWom = masterWombat.veWom();

        booster = _booster;
        depositor = _depositor;

        emit BoosterUpdated(_booster);
        emit DepositorUpdated(_depositor);
    }

    function setVoter(address _voter) external onlyOwner {
        require(_voter != address(0), "invalid _voter!");

        voter = IVoter(_voter);
    }

    function setBribeManager(address _bribeManager) external onlyOwner {
        require(_bribeManager != address(0), "invald _bribeManager!");

        bribeManager = _bribeManager;
    }

    function setBribeCallerFee(uint256 _bribeCallerFee) external onlyOwner {
        require(_bribeCallerFee <= 100, "invalid _bribeCallerFee!");
        bribeCallerFee = _bribeCallerFee;
    }

    function setBribeProtocolFee(uint256 _bribeProtocolFee) external onlyOwner {
        require(_bribeProtocolFee <= 2000, "invalid _bribeProtocolFee!");
        bribeProtocolFee = _bribeProtocolFee;
    }

    function setBribeFeeCollector(address _bribeFeeCollector)
        external
        onlyOwner
    {
        require(
            _bribeFeeCollector != address(0),
            "invalid _bribeFeeCollector!"
        );
        bribeFeeCollector = _bribeFeeCollector;
    }

    function getLpToken(uint256 _pid) external view override returns (address) {
        (address token, , , , , , ) = masterWombat.poolInfo(_pid);
        return token;
    }

    function getLpTokenV2(address _masterWombat, uint256 _pid)
        public
        view
        override
        returns (address)
    {
        address token;
        if (_masterWombat == address(masterWombat)) {
            (token, , , , , , ) = masterWombat.poolInfo(_pid);
        } else {
            (token, , , , , , , ) = IMasterWombatV3(_masterWombat).poolInfoV3(
                _pid
            );
        }

        return token;
    }

    function getBonusTokens(uint256 _pid)
        public
        view
        override
        returns (address[] memory)
    {
        (address[] memory bonusTokenAddresses, ) = masterWombat
            .rewarderBonusTokenInfo(_pid);
        for (uint256 i = 0; i < bonusTokenAddresses.length; i++) {
            if (bonusTokenAddresses[i] == address(0)) {
                // bnb
                bonusTokenAddresses[i] = AddressLib.PLATFORM_TOKEN_ADDRESS;
            }
        }
        return bonusTokenAddresses;
    }

    function getBonusTokensV2(address _masterWombat, uint256 _pid)
        public
        view
        override
        returns (address[] memory)
    {
        // V2 & V3 have the same interface
        (address[] memory bonusTokenAddresses, ) = IMasterWombatV3(
            _masterWombat
        ).rewarderBonusTokenInfo(_pid);
        for (uint256 i = 0; i < bonusTokenAddresses.length; i++) {
            if (bonusTokenAddresses[i] == address(0)) {
                // bnb
                bonusTokenAddresses[i] = AddressLib.PLATFORM_TOKEN_ADDRESS;
            }
        }
        return bonusTokenAddresses;
    }

    function deposit(uint256 _pid, uint256 _amount)
        external
        override
        onlyBooster
        returns (address[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        (address token, , , , , , ) = masterWombat.poolInfo(_pid);
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >= _amount, "insufficient balance");

        IERC20(token).safeApprove(address(masterWombat), 0);
        IERC20(token).safeApprove(address(masterWombat), balance);
        masterWombat.deposit(_pid, balance);
        (rewardTokens, rewardAmounts) = _claimRewards(_pid);

        emit Deposited(_pid, balance);
    }

    function depositV2(
        address _masterWombat,
        uint256 _pid,
        uint256 _amount
    )
        external
        override
        onlyBooster
        returns (address[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        address token = getLpTokenV2(_masterWombat, _pid);
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >= _amount, "insufficient balance");

        IERC20(token).safeApprove(_masterWombat, 0);
        IERC20(token).safeApprove(_masterWombat, balance);
        // V2 & V3 have the same interface
        IMasterWombatV3(_masterWombat).deposit(_pid, balance);
        (rewardTokens, rewardAmounts) = _claimRewardsV2(_masterWombat, _pid);

        emit DepositedV2(_masterWombat, _pid, balance);
    }

    // Withdraw partial funds
    function withdraw(uint256 _pid, uint256 _amount)
        public
        override
        onlyBooster
        returns (address[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        (address token, , , , , , ) = masterWombat.poolInfo(_pid);
        uint256 _balance = IERC20(token).balanceOf(address(this));
        if (_balance < _amount) {
            masterWombat.withdraw(_pid, _amount.sub(_balance));
            (rewardTokens, rewardAmounts) = _claimRewards(_pid);
        }
        IERC20(token).safeTransfer(booster, _amount);

        emit Withdrawn(_pid, _amount);
    }

    // Withdraw partial funds
    function withdrawV2(
        address _masterWombat,
        uint256 _pid,
        uint256 _amount
    )
        public
        override
        onlyBooster
        returns (address[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        address token = getLpTokenV2(_masterWombat, _pid);
        uint256 _balance = IERC20(token).balanceOf(address(this));
        if (_balance < _amount) {
            // V2 & V3 have the same interface
            IMasterWombatV3(_masterWombat).withdraw(
                _pid,
                _amount.sub(_balance)
            );
            (rewardTokens, rewardAmounts) = _claimRewardsV2(
                _masterWombat,
                _pid
            );
        }
        IERC20(token).safeTransfer(booster, _amount);

        emit WithdrawnV2(_masterWombat, _pid, _amount);
    }

    function withdrawAll(uint256 _pid)
        external
        override
        onlyBooster
        returns (address[] memory, uint256[] memory)
    {
        (address token, , , , , , ) = masterWombat.poolInfo(_pid);
        uint256 amount = balanceOfPool(_pid).add(
            IERC20(token).balanceOf(address(this))
        );
        return withdraw(_pid, amount);
    }

    function withdrawAllV2(address _masterWombat, uint256 _pid)
        external
        override
        onlyBooster
        returns (address[] memory, uint256[] memory)
    {
        address token = getLpTokenV2(_masterWombat, _pid);
        uint256 amount = balanceOfPoolV2(_masterWombat, _pid).add(
            IERC20(token).balanceOf(address(this))
        );
        return withdrawV2(_masterWombat, _pid, amount);
    }

    function claimRewards(uint256 _pid)
        external
        override
        onlyBooster
        returns (address[] memory, uint256[] memory)
    {
        // call deposit with _amount == 0 to claim current rewards
        masterWombat.deposit(_pid, 0);

        return _claimRewards(_pid);
    }

    function claimRewardsV2(address _masterWombat, uint256 _pid)
        external
        override
        onlyBooster
        returns (address[] memory, uint256[] memory)
    {
        // call deposit with _amount == 0 to claim current rewards
        IMasterWombatV3(_masterWombat).deposit(_pid, 0);

        return _claimRewardsV2(_masterWombat, _pid);
    }

    // send claimed rewards to booster
    function _claimRewards(uint256 _pid)
        internal
        returns (address[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        address[] memory bonusTokenAddresses = getBonusTokens(_pid);
        rewardTokens = new address[](1 + bonusTokenAddresses.length);
        rewardAmounts = new uint256[](1 + bonusTokenAddresses.length);

        uint256 _balance = IERC20(wom).balanceOf(address(this));
        rewardTokens[0] = wom;
        rewardAmounts[0] = _balance;
        IERC20(wom).safeTransfer(booster, _balance);
        emit RewardsClaimed(_pid, _balance);

        for (uint256 i = 0; i < bonusTokenAddresses.length; i++) {
            address bonusTokenAddress = bonusTokenAddresses[i];
            uint256 bonusTokenBalance = TransferHelper.balanceOf(
                bonusTokenAddress,
                address(this)
            );
            rewardTokens[1 + i] = bonusTokenAddress;
            rewardAmounts[1 + i] = bonusTokenBalance;
            if (bonusTokenBalance == 0) {
                continue;
            }
            bonusTokenAddress.safeTransferToken(booster, bonusTokenBalance);

            emit BonusRewardsClaimed(
                _pid,
                bonusTokenAddress,
                bonusTokenBalance
            );
        }
    }

    // send claimed rewards to booster
    function _claimRewardsV2(address _masterWombat, uint256 _pid)
        internal
        returns (address[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        address[] memory bonusTokenAddresses = getBonusTokensV2(
            _masterWombat,
            _pid
        );
        rewardTokens = new address[](1 + bonusTokenAddresses.length);
        rewardAmounts = new uint256[](1 + bonusTokenAddresses.length);

        uint256 _balance = IERC20(wom).balanceOf(address(this));
        rewardTokens[0] = wom;
        rewardAmounts[0] = _balance;
        IERC20(wom).safeTransfer(booster, _balance);
        emit RewardsClaimedV2(_masterWombat, _pid, _balance);

        for (uint256 i = 0; i < bonusTokenAddresses.length; i++) {
            address bonusTokenAddress = bonusTokenAddresses[i];
            uint256 bonusTokenBalance = TransferHelper.balanceOf(
                bonusTokenAddress,
                address(this)
            );
            rewardTokens[1 + i] = bonusTokenAddress;
            rewardAmounts[1 + i] = bonusTokenBalance;
            if (bonusTokenBalance == 0) {
                continue;
            }
            bonusTokenAddress.safeTransferToken(booster, bonusTokenBalance);

            emit BonusRewardsClaimedV2(
                _masterWombat,
                _pid,
                bonusTokenAddress,
                bonusTokenBalance
            );
        }
    }

    function balanceOfPool(uint256 _pid)
        public
        view
        override
        returns (uint256)
    {
        (uint256 amount, , , ) = masterWombat.userInfo(_pid, address(this));
        return amount;
    }

    function balanceOfPoolV2(address _masterWombat, uint256 _pid)
        public
        view
        override
        returns (uint256)
    {
        (uint256 amount, , , ) = IMasterWombatV3(_masterWombat).userInfo(
            _pid,
            address(this)
        );
        return amount;
    }

    function migrate(
        uint256 _pid,
        address _masterWombat,
        address _newMasterWombat
    )
        external
        override
        onlyBooster
        returns (
            uint256 newPid,
            address[] memory rewardTokens,
            uint256[] memory rewardAmounts
        )
    {
        if (_masterWombat == address(0)) {
            _masterWombat = address(masterWombat);
        }

        address token = getLpTokenV2(_masterWombat, _pid);
        // will revert if not exist
        newPid = IMasterWombatV3(_newMasterWombat).getAssetPid(token);
        uint256 balanceOfOld = balanceOfPoolV2(_masterWombat, _pid);
        uint256 balanceofNewBefore = balanceOfPoolV2(_newMasterWombat, newPid);

        uint256[] memory pids = new uint256[](1);
        pids[0] = _pid;
        IMasterWombatV2(_masterWombat).migrate(pids);

        uint256 balanceOfNewAfter = balanceOfPoolV2(_newMasterWombat, newPid);
        require(
            balanceOfNewAfter.sub(balanceofNewBefore) >= balanceOfOld,
            "migration failed"
        );

        (rewardTokens, rewardAmounts) = _claimRewardsV2(_masterWombat, _pid);
    }

    function lockWom(uint256 _lockDays) external override onlyDepositor {
        uint256 balance = IERC20(wom).balanceOf(address(this));

        if (balance == 0) {
            return;
        }

        IERC20(wom).safeApprove(veWom, 0);
        IERC20(wom).safeApprove(veWom, balance);

        IVeWom(veWom).mint(balance, _lockDays);

        emit WomLocked(balance, _lockDays);
    }

    function unlockWom(uint256 _slot) external onlyOwner {
        IVeWom(veWom).burn(_slot);

        emit WomUnlocked(_slot);
    }

    function vote(
        address[] calldata _lpVote,
        int256[] calldata _deltas,
        address[] calldata _rewarders,
        address _caller
    )
        external
        override
        returns (address[][] memory rewardTokens, uint256[][] memory feeAmounts)
    {
        require(msg.sender == bribeManager, "!auth");
        uint256 length = _lpVote.length;
        require(length == _rewarders.length, "Not good rewarder length");
        uint256[][] memory bribeRewards = voter.vote(_lpVote, _deltas);

        rewardTokens = new address[][](length);
        feeAmounts = new uint256[][](length);

        for (uint256 i = 0; i < length; i++) {
            uint256[] memory rewardAmounts = bribeRewards[i];
            (, , , , , , address bribesContract) = voter.infos(_lpVote[i]);
            feeAmounts[i] = new uint256[](rewardAmounts.length);
            if (bribesContract != address(0)) {
                rewardTokens[i] = _getBribeRewardTokens(bribesContract);
                for (uint256 j = 0; j < rewardAmounts.length; j++) {
                    uint256 rewardAmount = rewardAmounts[j];
                    if (rewardAmount > 0) {
                        uint256 protocolFee = bribeFeeCollector != address(0)
                            ? rewardAmount.mul(bribeProtocolFee).div(
                                FEE_DENOMINATOR
                            )
                            : 0;
                        if (protocolFee > 0) {
                            rewardTokens[i][j].safeTransferToken(
                                bribeFeeCollector,
                                protocolFee
                            );
                        }
                        uint256 callerFee = _caller != address(0)
                            ? rewardAmount.mul(bribeCallerFee).div(
                                FEE_DENOMINATOR
                            )
                            : 0;
                        if (callerFee != 0) {
                            rewardTokens[i][j].safeTransferToken(
                                bribeManager,
                                callerFee
                            );
                            feeAmounts[i][j] = callerFee;
                        }
                        rewardAmount = rewardAmount.sub(protocolFee).sub(
                            callerFee
                        );

                        if (AddressLib.isPlatformToken(rewardTokens[i][j])) {
                            IVirtualBalanceRewardPool(_rewarders[i])
                                .queueNewRewards{value: rewardAmount}(
                                rewardTokens[i][j],
                                rewardAmount
                            );
                        } else {
                            _approveTokenIfNeeded(
                                rewardTokens[i][j],
                                _rewarders[i],
                                rewardAmount
                            );
                            IVirtualBalanceRewardPool(_rewarders[i])
                                .queueNewRewards(
                                    rewardTokens[i][j],
                                    rewardAmount
                                );
                        }
                    }
                }
            }
        }

        emit Voted(_lpVote, _deltas, _rewarders, _caller);
    }

    function pendingBribeCallerFee(address[] calldata _pendingPools)
        external
        view
        override
        returns (
            address[][] memory rewardTokens,
            uint256[][] memory callerFeeAmount
        )
    {
        // Warning: Arguments do not take into account repeated elements in the pendingPools list
        uint256[][] memory pending = voter.pendingBribes(
            _pendingPools,
            address(this)
        );
        uint256 length = pending.length;
        rewardTokens = new address[][](length);
        callerFeeAmount = new uint256[][](length);
        for (uint256 i; i < length; i++) {
            (, , , , , , address bribesContract) = voter.infos(
                _pendingPools[i]
            );
            rewardTokens[i] = _getBribeRewardTokens(bribesContract);
            callerFeeAmount[i] = new uint256[](rewardTokens[i].length);
            for (uint256 j; j < pending[i].length; j++) {
                callerFeeAmount[i][j] = pending[i][j].mul(bribeCallerFee).div(
                    FEE_DENOMINATOR
                );
            }
        }
    }

    function _getBribeRewardTokens(address _bribesContract)
        internal
        view
        returns (address[] memory)
    {
        address[] memory rewardTokens = IBribe(_bribesContract).rewardTokens();
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            // if rewardToken is 0, native token is used as reward token
            if (rewardTokens[i] == address(0)) {
                rewardTokens[i] = AddressLib.PLATFORM_TOKEN_ADDRESS;
            }
        }
        return rewardTokens;
    }

    function _approveTokenIfNeeded(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _to) < _amount) {
            IERC20(_token).safeApprove(_to, 0);
            IERC20(_token).safeApprove(_to, type(uint256).max);
        }
    }

    receive() external payable {}
}