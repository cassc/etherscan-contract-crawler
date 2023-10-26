// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IERC20Ubiquity.sol";
import "./UbiquityAlgorithmicDollarManager.sol";
import "./interfaces/ITWAPOracle.sol";
import "./BondingShareV2.sol";
import "./interfaces/IUbiquityFormulas.sol";

import "./interfaces/IERC1155Ubiquity.sol";

contract MasterChefV2 {
    using SafeERC20 for IERC20Ubiquity;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct BondingShareInfo {
        uint256 amount; // bonding rights.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of uGOVs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accuGOVPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accuGOVPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        uint256 lastRewardBlock; // Last block number that uGOVs distribution occurs.
        uint256 accuGOVPerShare; // Accumulated uGOVs per share, times 1e12. See below.
    }

    uint256 private _totalShares;

    // Ubiquity Manager
    UbiquityAlgorithmicDollarManager public manager;

    // uGOV tokens created per block.
    uint256 public uGOVPerBlock = 1e18;
    // Bonus muliplier for early uGOV makers.
    uint256 public uGOVmultiplier = 1e18;
    uint256 public minPriceDiffToUpdateMultiplier = 1000000000000000;
    uint256 public lastPrice = 1 ether;
    uint256 public uGOVDivider;
    // Info of each pool.
    PoolInfo public pool;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => BondingShareInfo) private _bsInfo;

    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 indexed bondingShareId
    );

    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 indexed bondingShareId
    );

    // ----------- Modifiers -----------
    modifier onlyTokenManager() {
        require(
            manager.hasRole(manager.UBQ_TOKEN_MANAGER_ROLE(), msg.sender),
            "MasterChef: not UBQ manager"
        );
        _;
    }
    modifier onlyBondingContract() {
        require(
            msg.sender == manager.bondingContractAddress(),
            "MasterChef: not Bonding Contract"
        );
        _;
    }

    constructor(address _manager) {
        manager = UbiquityAlgorithmicDollarManager(_manager);
        pool.lastRewardBlock = block.number;
        pool.accuGOVPerShare = 0; // uint256(1e12);
        uGOVDivider = 5; // 100 / 5 = 20% extra minted ugov for treasury
        _updateUGOVMultiplier();
    }

    function setUGOVPerBlock(uint256 _uGOVPerBlock) external onlyTokenManager {
        uGOVPerBlock = _uGOVPerBlock;
    }

    // the bigger uGOVDivider is the less extra Ugov will be minted for the treasury
    function setUGOVShareForTreasury(uint256 _uGOVDivider)
        external
        onlyTokenManager
    {
        uGOVDivider = _uGOVDivider;
    }

    function setMinPriceDiffToUpdateMultiplier(
        uint256 _minPriceDiffToUpdateMultiplier
    ) external onlyTokenManager {
        minPriceDiffToUpdateMultiplier = _minPriceDiffToUpdateMultiplier;
    }

    // Deposit LP tokens to MasterChef for uGOV allocation.
    function deposit(
        address to,
        uint256 _amount,
        uint256 _bondingShareID
    ) external onlyBondingContract {
        BondingShareInfo storage bs = _bsInfo[_bondingShareID];
        _updatePool();
        if (bs.amount > 0) {
            uint256 pending = ((bs.amount * pool.accuGOVPerShare) / 1e12) -
                bs.rewardDebt;
            _safeUGOVTransfer(to, pending);
        }
        bs.amount += _amount;
        bs.rewardDebt = (bs.amount * pool.accuGOVPerShare) / 1e12;
        _totalShares += _amount;
        emit Deposit(to, _amount, _bondingShareID);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(
        address to,
        uint256 _amount,
        uint256 _bondingShareID
    ) external onlyBondingContract {
        BondingShareInfo storage bs = _bsInfo[_bondingShareID];
        require(bs.amount >= _amount, "MC: amount too high");
        _updatePool();
        uint256 pending = ((bs.amount * pool.accuGOVPerShare) / 1e12) -
            bs.rewardDebt;
        // send UGOV to Bonding Share holder

        _safeUGOVTransfer(to, pending);
        bs.amount -= _amount;
        bs.rewardDebt = (bs.amount * pool.accuGOVPerShare) / 1e12;
        _totalShares -= _amount;
        emit Withdraw(to, _amount, _bondingShareID);
    }

    /// @dev get pending uGOV rewards from MasterChef.
    /// @return amount of pending rewards transfered to msg.sender
    /// @notice only send pending rewards
    function getRewards(uint256 bondingShareID) external returns (uint256) {
        require(
            IERC1155Ubiquity(manager.bondingShareAddress()).balanceOf(
                msg.sender,
                bondingShareID
            ) == 1,
            "MS: caller is not owner"
        );

        // calculate user reward
        BondingShareInfo storage user = _bsInfo[bondingShareID];
        _updatePool();
        uint256 pending = ((user.amount * pool.accuGOVPerShare) / 1e12) -
            user.rewardDebt;
        _safeUGOVTransfer(msg.sender, pending);
        user.rewardDebt = (user.amount * pool.accuGOVPerShare) / 1e12;
        return pending;
    }

    // View function to see pending uGOVs on frontend.
    function pendingUGOV(uint256 bondingShareID)
        external
        view
        returns (uint256)
    {
        BondingShareInfo storage user = _bsInfo[bondingShareID];
        uint256 accuGOVPerShare = pool.accuGOVPerShare;
        uint256 lpSupply = IERC1155Ubiquity(manager.bondingShareAddress())
            .totalSupply();

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = _getMultiplier();

            uint256 uGOVReward = (multiplier * uGOVPerBlock) / 1e18;
            accuGOVPerShare =
                accuGOVPerShare +
                ((uGOVReward * 1e12) / lpSupply);
        }

        return (user.amount * accuGOVPerShare) / 1e12 - user.rewardDebt;
    }

    /**
     * @dev get the amount of shares and the reward debt of a bonding share .
     */
    function getBondingShareInfo(uint256 _id)
        external
        view
        returns (uint256[2] memory)
    {
        return [_bsInfo[_id].amount, _bsInfo[_id].rewardDebt];
    }

    /**
     * @dev Total amount of shares .
     */
    function totalShares() external view virtual returns (uint256) {
        return _totalShares;
    }

    // UPDATE uGOV multiplier
    function _updateUGOVMultiplier() internal {
        // (1.05/(1+abs(1-TWAP_PRICE)))
        uint256 currentPrice = _getTwapPrice();

        bool isPriceDiffEnough = false;
        // a minimum price variation is needed to update the multiplier
        if (currentPrice > lastPrice) {
            isPriceDiffEnough =
                currentPrice - lastPrice > minPriceDiffToUpdateMultiplier;
        } else {
            isPriceDiffEnough =
                lastPrice - currentPrice > minPriceDiffToUpdateMultiplier;
        }

        if (isPriceDiffEnough) {
            uGOVmultiplier = IUbiquityFormulas(manager.formulasAddress())
                .ugovMultiply(uGOVmultiplier, currentPrice);
            lastPrice = currentPrice;
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool() internal {
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        _updateUGOVMultiplier();
        uint256 lpSupply = IERC1155Ubiquity(manager.bondingShareAddress())
            .totalSupply();
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = _getMultiplier();
        uint256 uGOVReward = (multiplier * uGOVPerBlock) / 1e18;
        IERC20Ubiquity(manager.governanceTokenAddress()).mint(
            address(this),
            uGOVReward
        );
        // mint another x% for the treasury
        IERC20Ubiquity(manager.governanceTokenAddress()).mint(
            manager.treasuryAddress(),
            uGOVReward / uGOVDivider
        );
        pool.accuGOVPerShare =
            pool.accuGOVPerShare +
            ((uGOVReward * 1e12) / lpSupply);
        pool.lastRewardBlock = block.number;
    }

    // Safe uGOV transfer function, just in case if rounding
    // error causes pool to not have enough uGOVs.
    function _safeUGOVTransfer(address _to, uint256 _amount) internal {
        IERC20Ubiquity uGOV = IERC20Ubiquity(manager.governanceTokenAddress());
        uint256 uGOVBal = uGOV.balanceOf(address(this));
        if (_amount > uGOVBal) {
            uGOV.safeTransfer(_to, uGOVBal);
        } else {
            uGOV.safeTransfer(_to, _amount);
        }
    }

    function _getMultiplier() internal view returns (uint256) {
        return (block.number - pool.lastRewardBlock) * uGOVmultiplier;
    }

    function _getTwapPrice() internal view returns (uint256) {
        return
            ITWAPOracle(manager.twapOracleAddress()).consult(
                manager.dollarTokenAddress()
            );
    }
}