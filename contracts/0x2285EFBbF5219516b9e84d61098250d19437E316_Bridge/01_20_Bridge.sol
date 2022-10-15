// SPDX-License-Identifier: Apache-2.0.
pragma solidity 0.8.10;

import {IStarknetMessaging} from "./interfaces/IStarknetMessaging.sol";
import {RayMathNoRounding} from "./libraries/math/RayMathNoRounding.sol";
import {IAaveIncentivesController} from "./interfaces/IAaveIncentivesController.sol";
import {IATokenWithPool} from "./interfaces/IATokenWithPool.sol";
import {ILendingPool} from "./interfaces/ILendingPool.sol";
import {IBridge} from "./interfaces/IBridge.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {IScaledBalanceToken} from "@aave/core-v3/contracts/interfaces/IScaledBalanceToken.sol";
import {Initializable} from "./dependencies/Initializable.sol";
import {Cairo} from "./libraries/helpers/Cairo.sol";
import {Errors} from "./libraries/helpers/Errors.sol";
import {GPv2SafeERC20} from "@aave/core-v3/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {WadRayMath} from "@aave/core-v3/contracts/protocol/libraries/math/WadRayMath.sol";

contract Bridge is IBridge, Initializable {
    using WadRayMath for uint256;
    using RayMathNoRounding for uint256;
    using GPv2SafeERC20 for IERC20;

    IStarknetMessaging public _messagingContract;
    uint256 public _l2Bridge;
    address[] public _approvedL1Tokens;
    IERC20 public _rewardToken;
    IAaveIncentivesController public _incentivesController;
    mapping(address => ATokenData) public _aTokenData;
    uint256 public constant BRIDGE_REVISION = 0x1;

    /**
     * @dev Only valid l2 token addresses will can be approved if the function is marked by this modifier.
     **/
    modifier onlyValidL2Address(uint256 l2Address) {
        require(
            Cairo.isValidL2Address(l2Address),
            Errors.B_L2_ADDRESS_OUT_OF_RANGE
        );
        _;
    }

    /// @inheritdoc IBridge
    function getAvailableRewards() public view returns (uint256) {
        uint256 claimable = _incentivesController.getRewardsBalance(
            _approvedL1Tokens,
            address(this)
        );
        uint256 claimed = _rewardToken.balanceOf(address(this));
        return claimable + claimed;
    }

    /**
     * @notice Initializes the Bridge
     * @dev Function is invoked by the proxy contract when the bridge contract is added
     * @param l2Bridge L2 bridge address
     * @param messagingContract Starknet messaging contract address
     * @param incentivesController Address of Aave IncentivesController
     * @param l1Tokens Array of l1 tokens
     * @param l2Tokens Array of l2 tokens
     * @param ceilings Array of max amount that can be bridged for each aToken without taking into account the interest growth
     **/
    function initialize(
        uint256 l2Bridge,
        address messagingContract,
        address incentivesController,
        address[] calldata l1Tokens,
        uint256[] calldata l2Tokens,
        uint256[] calldata ceilings
    ) external virtual onlyValidL2Address(l2Bridge) initializer {
        require(
            address(incentivesController) != address(0),
            Errors.B_INVALID_INCENTIVES_CONTROLLER_ADDRESS
        );
        _messagingContract = IStarknetMessaging(messagingContract);
        _l2Bridge = l2Bridge;
        _incentivesController = IAaveIncentivesController(incentivesController);
        _rewardToken = IERC20(_incentivesController.REWARD_TOKEN());

        _approveBridgeTokens(l1Tokens, l2Tokens, ceilings);
    }

    /// @inheritdoc IBridge
    function deposit(
        address l1AToken,
        uint256 l2Recipient,
        uint256 amount,
        uint16 referralCode,
        bool fromUnderlyingAsset
    ) external override onlyValidL2Address(l2Recipient) returns (uint256) {
        require(
            IScaledBalanceToken(l1AToken).scaledBalanceOf(address(this)) +
                amount <=
                _aTokenData[l1AToken].ceiling,
            Errors.B_ABOVE_CEILING
        );
        IERC20 underlyingAsset = _aTokenData[l1AToken].underlyingAsset;
        ILendingPool lendingPool = _aTokenData[l1AToken].lendingPool;
        require(
            underlyingAsset != IERC20(address(0)),
            Errors.B_ATOKEN_NOT_APPROVED
        );
        require(amount > 0, Errors.B_INSUFFICIENT_AMOUNT);
        // deposit aToken or underlying asset

        if (fromUnderlyingAsset) {
            underlyingAsset.safeTransferFrom(msg.sender, address(this), amount);
            lendingPool.deposit(
                address(underlyingAsset),
                amount,
                address(this),
                referralCode
            );
        } else {
            IERC20(l1AToken).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
        }

        // update L2 state and emit deposit event

        uint256 rewardsIndex = _getCurrentRewardsIndex(l1AToken);

        uint256 staticAmount = _dynamicToStaticAmount(
            amount,
            address(underlyingAsset),
            lendingPool
        );
        uint256 l2MsgNonce = _messagingContract.l1ToL2MessageNonce();
        _sendDepositMessage(
            l1AToken,
            msg.sender,
            l2Recipient,
            staticAmount,
            block.number,
            rewardsIndex
        );
        emit Deposit(
            msg.sender,
            l1AToken,
            staticAmount,
            l2Recipient,
            block.number,
            rewardsIndex,
            l2MsgNonce
        );

        return staticAmount;
    }

    /// @inheritdoc IBridge
    function withdraw(
        address l1AToken,
        uint256 l2sender,
        address recipient,
        uint256 staticAmount,
        uint256 l2RewardsIndex,
        bool toUnderlyingAsset
    ) external override {
        require(recipient != address(0), Errors.B_INVALID_ADDRESS);
        require(staticAmount > 0, Errors.B_INSUFFICIENT_AMOUNT);

        _consumeMessage(
            l1AToken,
            l2sender,
            recipient,
            staticAmount,
            l2RewardsIndex,
            toUnderlyingAsset ? 1 : 0
        );

        address underlyingAsset = address(
            _aTokenData[l1AToken].underlyingAsset
        );
        ILendingPool lendingPool = _aTokenData[l1AToken].lendingPool;
        uint256 amount = _staticToDynamicAmount(
            staticAmount,
            underlyingAsset,
            lendingPool
        );

        if (toUnderlyingAsset) {
            lendingPool.withdraw(underlyingAsset, amount, recipient);
        } else {
            IERC20(l1AToken).safeTransfer(recipient, amount);
        }

        emit Withdrawal(l1AToken, l2sender, recipient, amount);

        // update L2 state

        uint256 l1CurrentRewardsIndex = _getCurrentRewardsIndex(l1AToken);

        _sendIndexUpdateMessage(
            l1AToken,
            msg.sender,
            block.number,
            l1CurrentRewardsIndex
        );

        emit L2StateUpdated(l1AToken, l1CurrentRewardsIndex);

        // transfer rewards

        uint256 rewardsAmount = _computeRewardsDiff(
            staticAmount,
            l2RewardsIndex,
            l1CurrentRewardsIndex
        );
        if (rewardsAmount > 0) {
            _transferRewards(recipient, rewardsAmount);
            emit RewardsTransferred(l2sender, recipient, rewardsAmount);
        }
    }

    /// @inheritdoc IBridge
    function updateL2State(address l1AToken) external override {
        uint256 rewardsIndex = _getCurrentRewardsIndex(l1AToken);

        _sendIndexUpdateMessage(
            l1AToken,
            msg.sender,
            block.number,
            rewardsIndex
        );

        emit L2StateUpdated(l1AToken, rewardsIndex);
    }

    /// @inheritdoc IBridge
    function receiveRewards(
        uint256 l2sender,
        address recipient,
        uint256 amount
    ) external override {
        require(recipient != address(0), Errors.B_INVALID_ADDRESS);
        require(amount > 0, Errors.B_INSUFFICIENT_AMOUNT);
        //check if enough rewards are available on the bridge before consuming the message from l2
        require(getAvailableRewards() >= amount, Errors.B_NOT_ENOUGH_REWARDS);
        _consumeBridgeRewardMessage(l2sender, recipient, amount);
        _transferRewards(recipient, amount);
        emit RewardsTransferred(l2sender, recipient, amount);
    }

    function getRevision() internal pure virtual returns (uint256) {
        return BRIDGE_REVISION;
    }

    /**
     * @notice Approves a new L1<->L2 token bridge in a loop, shouldn't be porvided by a large array of aTokens for gas opt.
     * @dev Function is invoked at initialize
     **/
    function _approveBridgeTokens(
        address[] calldata l1Tokens,
        uint256[] calldata l2Tokens,
        uint256[] calldata ceilings
    ) internal {
        require(
            l1Tokens.length == l2Tokens.length &&
                l1Tokens.length == ceilings.length,
            Errors.B_MISMATCHING_ARRAYS_LENGTH
        );
        for (uint256 i = 0; i < l1Tokens.length; i++) {
            _approveToken(l1Tokens[i], l2Tokens[i], ceilings[i]);
        }
    }

    /**
     * @notice Approves a new L1<->L2 token bridge.
     * @dev Function is invoked only by bridge admin
     * @param l1AToken token address
     * @param l2Token token address
     **/
    function _approveToken(
        address l1AToken,
        uint256 l2Token,
        uint256 ceiling
    ) internal onlyValidL2Address(l2Token) {
        require(l1AToken != address(0), Errors.B_INVALID_ADDRESS);

        require(
            _aTokenData[l1AToken].l2TokenAddress == 0,
            Errors.B_TOKEN_ALREADY_APPROVED
        );

        require(
            IATokenWithPool(l1AToken).getIncentivesController() ==
                _incentivesController,
            Errors.B_INVALID_INCENTIVES_CONTROLLER_ADDRESS
        );

        IERC20 underlyingAsset = IERC20(
            IATokenWithPool(l1AToken).UNDERLYING_ASSET_ADDRESS()
        );
        ILendingPool lendingPool = IATokenWithPool(l1AToken).POOL();
        underlyingAsset.approve(address(lendingPool), type(uint256).max);

        _aTokenData[l1AToken] = ATokenData(
            l2Token,
            underlyingAsset,
            lendingPool,
            ceiling
        );
        _approvedL1Tokens.push(l1AToken);
        emit ApprovedBridge(l1AToken, l2Token, ceiling);
    }

    function _sendDepositMessage(
        address l1Token,
        address from,
        uint256 l2Recipient,
        uint256 amount,
        uint256 blockNumber,
        uint256 currentRewardsIndex
    ) internal {
        uint256[] memory payload = new uint256[](9);
        payload[0] = uint256(uint160(from));
        payload[1] = l2Recipient;
        payload[2] = _aTokenData[l1Token].l2TokenAddress;
        (payload[3], payload[4]) = Cairo.toSplitUint(amount);
        (payload[5], payload[6]) = Cairo.toSplitUint(blockNumber);
        (payload[7], payload[8]) = Cairo.toSplitUint(currentRewardsIndex);

        _messagingContract.sendMessageToL2(
            _l2Bridge,
            Cairo.DEPOSIT_HANDLER,
            payload
        );
    }

    function _sendIndexUpdateMessage(
        address l1Token,
        address from,
        uint256 blockNumber,
        uint256 currentRewardsIndex
    ) internal {
        uint256[] memory payload = new uint256[](6);
        payload[0] = uint256(uint160(from));
        payload[1] = _aTokenData[l1Token].l2TokenAddress;
        (payload[2], payload[3]) = Cairo.toSplitUint(blockNumber);
        (payload[4], payload[5]) = Cairo.toSplitUint(currentRewardsIndex);

        _messagingContract.sendMessageToL2(
            _l2Bridge,
            Cairo.INDEX_UPDATE_HANDLER,
            payload
        );
    }

    function _consumeMessage(
        address l1Token,
        uint256 l2sender,
        address recipient,
        uint256 amount,
        uint256 l2RewardsIndex,
        uint256 toUnderlyingAsset
    ) internal {
        uint256[] memory payload = new uint256[](9);
        payload[0] = Cairo.WITHDRAW_MESSAGE;
        payload[1] = uint256(uint160(l1Token));
        payload[2] = l2sender;
        payload[3] = uint256(uint160(recipient));
        (payload[4], payload[5]) = Cairo.toSplitUint(amount);
        (payload[6], payload[7]) = Cairo.toSplitUint(l2RewardsIndex);
        payload[8] = toUnderlyingAsset;

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        _messagingContract.consumeMessageFromL2(_l2Bridge, payload);
    }

    function _dynamicToStaticAmount(
        uint256 amount,
        address asset,
        ILendingPool lendingPool
    ) internal view returns (uint256) {
        return amount.rayDiv(lendingPool.getReserveNormalizedIncome(asset));
    }

    function _staticToDynamicAmount(
        uint256 amount,
        address asset,
        ILendingPool lendingPool
    ) internal view returns (uint256) {
        return amount.rayMul(lendingPool.getReserveNormalizedIncome(asset));
    }

    /**
     * @notice gets the latest rewards index of the given aToken on L1.
     **/

    function _getCurrentRewardsIndex(address l1AToken)
        internal
        view
        returns (uint256)
    {
        (
            uint256 index,
            uint256 emissionPerSecond,
            uint256 lastUpdateTimestamp
        ) = _incentivesController.getAssetData(l1AToken);
        uint256 distributionEnd = _incentivesController.DISTRIBUTION_END();
        uint256 totalSupply = IScaledBalanceToken(l1AToken).scaledTotalSupply();

        if (
            emissionPerSecond == 0 ||
            totalSupply == 0 ||
            lastUpdateTimestamp == block.timestamp ||
            lastUpdateTimestamp >= distributionEnd
        ) {
            return index;
        }

        uint256 currentTimestamp = block.timestamp > distributionEnd
            ? distributionEnd
            : block.timestamp;
        uint256 timeDelta = currentTimestamp - lastUpdateTimestamp;
        return
            (emissionPerSecond * timeDelta * 10**uint256(18)) /
            totalSupply +
            index;
    }

    function _computeRewardsDiff(
        uint256 amount,
        uint256 l2RewardsIndex,
        uint256 l1RewardsIndex
    ) internal pure returns (uint256) {
        // l1RewardsIndex and l1RewardsIndex are both in wad, so the result of next line is also in wad.
        return amount.wadMul(l1RewardsIndex - l2RewardsIndex);
    }

    function _consumeBridgeRewardMessage(
        uint256 l2sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256[] memory payload = new uint256[](5);
        payload[0] = Cairo.BRIDGE_REWARD_MESSAGE;
        payload[1] = l2sender;
        payload[2] = uint256(uint160(recipient));
        (payload[3], payload[4]) = Cairo.toSplitUint(amount);

        _messagingContract.consumeMessageFromL2(_l2Bridge, payload);
    }

    /**
     * @notice claims pending rewards of the l1 bridge by calling the aave Incentives Controller and transfers them back to the l1 recipient
     * @param recipient of rewards tokens
     * @param rewardsAmount to be transferred to recipient
     **/
    function _transferRewards(address recipient, uint256 rewardsAmount)
        internal
    {
        address self = address(this);
        uint256 rewardBalance = _rewardToken.balanceOf(self);

        if (rewardBalance < rewardsAmount) {
            rewardBalance += _incentivesController.claimRewards(
                _approvedL1Tokens,
                rewardsAmount - rewardBalance,
                self
            );
        }

        if (rewardBalance >= rewardsAmount) {
            _rewardToken.safeTransfer(recipient, rewardsAmount);
            return;
        }
        revert(Errors.B_NOT_ENOUGH_REWARDS);
    }

    function startDepositCancellation(
        address l1Token,
        uint256 amount,
        uint256 l2Recipient,
        uint256 rewardsIndex,
        uint256 blockNumber,
        uint256 nonce
    ) external onlyValidL2Address(l2Recipient) {
        uint256[] memory payload = new uint256[](9);
        payload[0] = uint256(uint160(msg.sender));
        payload[1] = l2Recipient;
        payload[2] = _aTokenData[l1Token].l2TokenAddress;
        (payload[3], payload[4]) = Cairo.toSplitUint(amount);
        (payload[5], payload[6]) = Cairo.toSplitUint(blockNumber);
        (payload[7], payload[8]) = Cairo.toSplitUint(rewardsIndex);

        _messagingContract.startL1ToL2MessageCancellation(
            _l2Bridge,
            Cairo.DEPOSIT_HANDLER,
            payload,
            nonce
        );
        emit StartedDepositCancellation(
            l2Recipient,
            rewardsIndex,
            blockNumber,
            amount,
            nonce
        );
    }

    function cancelDeposit(
        address l1AToken,
        uint256 amount,
        uint256 l2Recipient,
        uint256 rewardsIndex,
        uint256 blockNumber,
        uint256 nonce
    ) external onlyValidL2Address(l2Recipient) {
        uint256[] memory payload = new uint256[](9);
        payload[0] = uint256(uint160(msg.sender));
        payload[1] = l2Recipient;
        payload[2] = _aTokenData[l1AToken].l2TokenAddress;
        (payload[3], payload[4]) = Cairo.toSplitUint(amount);
        (payload[5], payload[6]) = Cairo.toSplitUint(blockNumber);
        (payload[7], payload[8]) = Cairo.toSplitUint(rewardsIndex);

        _messagingContract.cancelL1ToL2Message(
            _l2Bridge,
            Cairo.DEPOSIT_HANDLER,
            payload,
            nonce
        );

        address underlyingAsset = address(
            _aTokenData[l1AToken].underlyingAsset
        );
        ILendingPool lendingPool = _aTokenData[l1AToken].lendingPool;
        uint256 dynamicAmount = _staticToDynamicAmount(
            amount,
            underlyingAsset,
            lendingPool
        );

        //transfer aTokens back to depositor
        IERC20(l1AToken).safeTransfer(msg.sender, dynamicAmount);

        //claim any accrued rewards for the depositor during the cancellation period
        uint256 currentRewardsIndex = _getCurrentRewardsIndex(l1AToken);
        uint256 rewardsAmount = _computeRewardsDiff(
            amount,
            rewardsIndex,
            currentRewardsIndex
        );

        if (rewardsAmount > 0) {
            _transferRewards(msg.sender, rewardsAmount);
            emit RewardsTransferred(_l2Bridge, msg.sender, rewardsAmount);
        }

        emit CancelledDeposit(
            l2Recipient,
            msg.sender,
            rewardsIndex,
            blockNumber,
            dynamicAmount,
            nonce
        );
    }
}