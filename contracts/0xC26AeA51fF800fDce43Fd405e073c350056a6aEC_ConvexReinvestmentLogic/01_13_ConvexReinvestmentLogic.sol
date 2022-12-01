// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../../interfaces/convex/IConvexBooster.sol";
import "../../interfaces/convex/IConvexRewards.sol";
import "../../interfaces/IReinvestment.sol";
import "../../interfaces/convex/ICvx.sol";
import "../../libraries/math/MathUtils.sol";

contract ConvexReinvestmentLogic is Initializable, Ownable, IERC165, IReinvestmentLogic {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUtils for uint256;

    struct UserReward {
        uint256 claimable;
        uint256 integral;
    }

    struct RewardConfig {
        uint256 pid;
        address asset;
        uint256 integral;
        uint256 remaining;
    }

    uint256 public constant VERSION = 1;

    bytes32 internal constant ASSET = 0x0bd4060688a1800ae986e4840aebc924bb40b5bf44de4583df2257220b54b77c; // keccak256(abi.encodePacked("asset"))
    bytes32 internal constant TREASURY = 0xcbd818ad4dd6f1ff9338c2bb62480241424dd9a65f9f3284101a01cd099ad8ac; // keccak256(abi.encodePacked("treasury"))
    bytes32 internal constant LEDGER = 0x2c0e8db8fb1343f00f1c6b57af1cf6bf785c6b487e5c99ae90a4e98907f27011; // keccak256(abi.encodePacked("ledger"))
    bytes32 internal constant FEE_MANTISSA = 0xb438cbc7dd7438566e91798623a0acb324f70180fcab8f4a7f87eec183969271; // keccak256(abi.encodePacked("feeMantissa"))
    bytes32 internal constant RECEIPT = 0x8ad7c532f0538a191f1e436b6ca6710d0a78a349291c8b8f31962a26fb22e7e8; // keccak256(abi.encodePacked("receipt"))
    bytes32 internal constant PLATFORM = 0x3cb058642d3f17bc460bdd6eab42c21564f6b5228beab6a905a2eb32727c49d1; // keccak256(abi.encodePacked("platform"))
    bytes32 internal constant REWARD_POOL = 0xc94c1dc95992436dc73507a124248f855bbb3eb7ba05c35a8968ee0032e7c010; // keccak256(abi.encodePacked("rewardPool"))
    bytes32 internal constant POOL_ID = 0x65c5f051c5b76a70f06341c7e1c7bd57f76bdd400b273318041f003789e75a58; // keccak256(abi.encodePacked("poolId"))
    bytes32 internal constant REWARD_LENGTH = 0x2a8d0d63b9cbf2fc91763d8e08f9093cd174394353698a9d10c9ac16f1471ba9; // keccak256(abi.encodePacked("rewardLength"))
    bytes32 internal constant EMPTY_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470; // keccak256(abi.encodePacked(""))

    ICvx public constant cvx = ICvx(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address public constant CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);

    // ====================== STORAGE ======================

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;

    // ====================== STORAGE ======================

    /**
     * @notice Initialize
     * @param asset_ The asset address
     * @param receipt_ The receipt to receive after investing
     * @param platform_ The investing platform
     * @param rewards_ The side reward to be claim
     * @param treasury_ The protocol treasury
     * @param ledger_ The ledger
     * @param feeMantissa_ Fees applied after divesting
     * @param data Additional data for reinvestment
     **/
    function initialize(
        address asset_,
        address receipt_,
        address platform_,
        address[] memory rewards_,
        address treasury_,
        address ledger_,
        uint256 feeMantissa_,
        bytes memory data
    ) external initializer onlyOwner {
        addressStorage[ASSET] = asset_;
        addressStorage[TREASURY] = treasury_;
        addressStorage[LEDGER] = ledger_;
        uintStorage[FEE_MANTISSA] = feeMantissa_;
        addressStorage[RECEIPT] = receipt_;
        addressStorage[PLATFORM] = platform_;

        (uint256 poolId_, address rewardPool_) = abi.decode(data, (uint256, address));
        uintStorage[POOL_ID] = poolId_;
        addressStorage[REWARD_POOL] = rewardPool_;

        uintStorage[REWARD_LENGTH] = rewards_.length;

        for (uint256 i = 0; i < rewards_.length; i++) {
            setRewards(i, RewardConfig(i, rewards_[i], 0, 0));
        }
    }

    function setTreasury(address treasury_) external override onlyOwner {
        emit UpdatedTreasury(treasury(), treasury_);
        addressStorage[TREASURY] = treasury_;
    }

    function setFeeMantissa(uint256 feeMantissa_) external override onlyOwner {
        require(feeMantissa_ < 1e18, "invalid feeMantissa");
        emit UpdatedFeeMantissa(feeMantissa(), feeMantissa_);
        uintStorage[FEE_MANTISSA] = feeMantissa_;
    }

    /**
     * @notice invest
     * @param amount amount
     **/
    function invest(
        uint256 amount
    ) external override onlyLedger {
        IERC20Upgradeable(asset()).safeTransferFrom(msg.sender, address(this), amount);

        require(IERC20Upgradeable(asset()).balanceOf(address(this)) >= amount, "not enough underlying");

        IERC20Upgradeable(asset()).safeApprove(platform(), 0);
        IERC20Upgradeable(asset()).safeApprove(platform(), amount);
        IConvexBooster(platform()).deposit(poolId(), amount, true);
    }

    /**
     * @notice divest
     * @param amount amount
     **/
    function divest(
        uint256 amount
    ) external override onlyLedger {
        IConvexRewards(rewardPool()).withdraw(amount, true);

        bool successWithdraw = IConvexBooster(platform()).withdraw(poolId(), amount);

        require(successWithdraw, "issue withdrawing from convex");

        require(
            IERC20Upgradeable(asset()).balanceOf(address(this)) >= amount,
            "contract does not hold amount"
        );

        IERC20Upgradeable(asset()).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice checkpoint
     * @param user user
     * @param currBalance currBalance
     **/
    function checkpoint(address user, uint256 currBalance) external override onlyLedger {
        _checkpoint(user, currBalance);
    }

    /**
     * @notice claim
     * @param user user
     * @param currBalance currBalance
     **/
    function claim(address user, uint256 currBalance) external override onlyLedger {
        _checkpointAndClaim(user, currBalance);
    }

    function _checkpoint(address user, uint256 currBalance) internal {
        IConvexRewards(rewardPool()).getReward(address(this), true);

        for (uint256 i = 0; i < rewardLength(); i++) {
            (
            RewardConfig memory reward,
            UserReward memory userReward
            ) = _calculateRewards(user, currBalance, rewards(i), rewardOfInternal(user, i), false);

            setRewards(i, reward);
            setRewardOf(user, i, userReward);
        }
    }

    function _checkpointAndClaim(address user, uint256 currBalance) internal {
        IConvexRewards(rewardPool()).getReward(address(this), true);

        for (uint256 i = 0; i < rewardLength(); i++) {
            (
            RewardConfig memory reward,
            UserReward memory userReward
            ) = _calculateRewards(user, currBalance, rewards(i), rewardOfInternal(user, i), true);

            setRewards(i, reward);
            setRewardOf(user, i, userReward);
        }
    }

    /**
     * @notice Calculate Rewards
     * @param user Address
     * @param currBalance currBalance
     * @param reward memory data
     * @param userReward memory data
     * @param isClaim isClaim
     * @return reward reward
    */
    function _calculateRewards(
        address user,
        uint256 currBalance,
        RewardConfig memory reward,
        UserReward memory userReward,
        bool isClaim
    ) internal returns (RewardConfig memory, UserReward memory) {
        uint256 accruedBalance = IERC20Upgradeable(reward.asset).balanceOf(address(this));

        if (totalSupply() > 0 && accruedBalance > reward.remaining) {
            reward.integral += (accruedBalance - reward.remaining) * 1e20 / totalSupply();
        }

        if (isClaim || reward.integral > userReward.integral) {
            uint256 receivable = (reward.integral - userReward.integral) * currBalance / 1e20;

            if (isClaim) {
                receivable += userReward.claimable;

                uint256 fee = receivable * feeMantissa() / 1e18;
                IERC20Upgradeable(reward.asset).safeTransfer(treasury(), fee);

                IERC20Upgradeable(reward.asset).safeTransfer(user, receivable - fee);
                userReward.claimable = 0;

                // receivable still has fee and reduced from accruedBalance
                accruedBalance -= receivable;
            } else {
                userReward.claimable += receivable;
            }
            userReward.integral = reward.integral;
        }

        if (accruedBalance != reward.remaining) {
            reward.remaining = accruedBalance;
        }

        return (reward, userReward);
    }

    function _calculateGlobalRewards(RewardConfig memory reward) internal view returns (RewardConfig memory) {
        uint256 accruedBalance = IERC20Upgradeable(reward.asset).balanceOf(address(this));

        if (totalSupply() > 0 && accruedBalance > reward.remaining) {
            reward.integral += (accruedBalance - reward.remaining) * 1e20 / totalSupply();
        }

        if (accruedBalance != reward.remaining) {
            reward.remaining = accruedBalance;
        }

        return reward;
    }

    function _convertCrvToCvx(uint256 _amount) internal view returns (uint256){
        uint256 supply = cvx.totalSupply();
        uint256 reductionPerCliff = cvx.reductionPerCliff();
        uint256 totalCliffs = cvx.totalCliffs();
        uint256 maxSupply = cvx.maxSupply();

        uint256 cliff = supply / reductionPerCliff;
        //mint if below total cliffs
        if (cliff < totalCliffs) {
            //for reduction% take inverse of current cliff
            uint256 reduction = totalCliffs - cliff;
            //reduce
            _amount = _amount * reduction / totalCliffs;

            //supply cap check
            uint256 amtTillMax = maxSupply - supply;
            if (_amount > amtTillMax) {
                _amount = amtTillMax;
            }

            //mint
            return _amount;
        }
        return 0;
    }

    /**
     * @return The underlying total supply
     */
    function totalSupply() public view override returns (uint256) {
        return IConvexRewards(rewardPool()).balanceOf(address(this));
    }

    /**
     * @notice rewardOf
     * @param user user
     * @param currBalance Current deposited balance
     * @return Reward[]
     **/
    function rewardOf(address user, uint256 currBalance) public view override returns (Reward[] memory) {
        uint256 supply = totalSupply();
        Reward[] memory _rewards = new Reward[](rewardLength());
        for (uint256 i = 0; i < rewardLength(); i++) {
            RewardConfig memory rewardConfig = rewards(i);
            UserReward memory reward = rewardOfInternal(user, i);

            uint256 totalRewards = IERC20Upgradeable(rewardConfig.asset).balanceOf(address(this));
            uint256 newRewards = totalRewards - rewardConfig.remaining;

            newRewards = newRewards + IConvexRewards(rewardPool()).earned(address(this));

            uint256 globalIntegral = rewardConfig.integral;
            if (supply > 0) globalIntegral = globalIntegral + ((newRewards * 1e20) / supply);
            uint256 newlyClaimable = (currBalance * (globalIntegral - reward.integral)) / 1e20;
            reward.claimable = reward.claimable + newlyClaimable;

            if (rewardConfig.asset == CRV) {
                reward.claimable = reward.claimable + _convertCrvToCvx(newlyClaimable);
            }

            _rewards[i] = Reward(rewardConfig.asset, reward.claimable);
        }
        return _rewards;
    }


    function rewardOfInternal(address user, uint256 index) internal view returns (UserReward memory userReward) {
        bytes memory encodedData = bytesStorage[keccak256(abi.encodePacked("rewardOf", user, index))];

        if (keccak256(encodedData) == EMPTY_HASH) {
            UserReward memory emptyUserReward;
            userReward = emptyUserReward;
        } else {
            (userReward) = abi.decode(encodedData, (UserReward));
        }
    }

    /**
     * @notice setRewardOf
     * @param user user
     * @param index index
     * @param userReward
     **/
    function setRewardOf(
        address user,
        uint256 index,
        UserReward memory userReward
    ) internal {
        bytesStorage[keccak256(abi.encodePacked("rewardOf", user, index))] = abi.encode(userReward);
    }

    /**
     * @notice rewards
     * @param index The index map of reward configuration
     * @return reward rewardConfig
     **/
    function rewards(uint256 index) public view returns (RewardConfig memory reward) {
        bytes memory encodedData = bytesStorage[keccak256(abi.encodePacked("rewards", index))];

        if (keccak256(encodedData) == EMPTY_HASH) {
            RewardConfig memory emptyReward;
            reward = emptyReward;
        } else {
            (reward) = abi.decode(encodedData, (RewardConfig));
        }
    }

    /**
     * @notice setRewards
     * @param index index
     * @param reward reward
     **/
    function setRewards(uint256 index, RewardConfig memory reward) internal {
        bytesStorage[keccak256(abi.encodePacked("rewards", index))] = abi.encode(reward);
    }

    /**
     * @notice rewardLength rewardLength
     * @return length of configured rewards array
     **/
    function rewardLength() public view override returns (uint256) {
        return uintStorage[REWARD_LENGTH];
    }

    /**
     * @notice setRewardLength
     * @param length length
     **/
    function setRewardLength(uint256 length) internal {
        uintStorage[REWARD_LENGTH] = length;
    }

    function asset() public view override returns (address) {
        return addressStorage[ASSET];
    }

    function treasury() public view override returns (address) {
        return addressStorage[TREASURY];
    }

    function ledger() public view override returns (address) {
        return addressStorage[LEDGER];
    }

    function feeMantissa() public view override returns (uint256) {
        return uintStorage[FEE_MANTISSA];
    }


    /**
     * @notice platform
     * @return address of platform (convex)
     **/
    function platform() public view override returns (address) {
        return addressStorage[PLATFORM];
    }

    /**
     * @notice poolId
     * @return configured pool ID
     **/
    function poolId() public view returns (uint256) {
        return uintStorage[POOL_ID];
    }

    /**
     * @notice rewardPool
     * @return address of rewardPool
     **/
    function rewardPool() public view returns (address) {
        return addressStorage[REWARD_POOL];
    }

    function receipt() public view override returns (address) {
        return addressStorage[RECEIPT];
    }

    /**
     * @notice supportsInterface
     * @param interfaceId interfaceId
     * @return whether it supports
     **/
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IReinvestmentLogic).interfaceId;
    }

    /**
     * @notice emergencyWithdraw
     * @return balance
     **/
    function emergencyWithdraw() external override onlyLedger returns (uint256) {
        // retrieve rewards [crv,cvx], transferred to this contract
        IConvexRewards(rewardPool()).getReward(address(this), true);

        // update rewards index
        for (uint256 i = 0; i < rewardLength(); i++) {
            (RewardConfig memory reward) = _calculateGlobalRewards(rewards(i));
            setRewards(i, reward);
        }

        uint256 receiptBalance = IConvexRewards(rewardPool()).balanceOf(address(this));
        IConvexRewards(rewardPool()).withdrawAndUnwrap(receiptBalance, true);

        uint256 balance = IERC20Upgradeable(asset()).balanceOf(address(this));
        IERC20Upgradeable(asset()).safeTransfer(msg.sender, balance);

        return balance;
    }

    /**
     * @notice sweep
     * @param otherAsset
     **/
    function sweep(address otherAsset) external override onlyTreasury {
        require(otherAsset != asset(), "cannot sweep registered asset");
        IERC20Upgradeable(otherAsset).safeTransfer(treasury(), IERC20Upgradeable(otherAsset).balanceOf(address(this)));
    }

    modifier onlyLedger() {
        require(ledger() == msg.sender, "only ledger");
        _;
    }

    modifier onlyTreasury() {
        require(treasury() == msg.sender, "only treasury");
        _;
    }
}