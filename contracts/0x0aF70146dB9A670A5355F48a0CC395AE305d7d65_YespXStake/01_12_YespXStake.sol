// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';

error StakeBelowThreshhold();
error WithdrawBeforeLockupEnd();
error WithdrawOverBalance();
error XChainUnderfunded();
error BadDestinationChains();

contract YespXStake is Ownable, AxelarExecutable, ReentrancyGuard {

    event StakingEntered(address indexed user, uint256 amount, uint256 timestamp);
    event StakingExited(address indexed user, uint256 amount, uint256 timestamp);

    mapping(address => uint256) public amountStaked;
    mapping(address => uint256) public stakingEnteredTimestamp;

    IERC20 constant public YESPTOKEN = IERC20(0x46ccA329970B33e1a007DD4ef0594A1cedb3E72a); //YESP token
    IERC20Permit constant public YESPTOKENPERMIT = IERC20Permit(0x46ccA329970B33e1a007DD4ef0594A1cedb3E72a); //YESP token
    IAxelarGasService private constant gasReceiver = IAxelarGasService(0x2d5d7d31F671F86C782533cc367F14109a082712); //Ethereum

    uint256 public lockupTime = 86400;
    enum DiscountTier { NO_TIER, TIER_1, TIER_2, TIER_3 }
    mapping(DiscountTier => uint256) public discountThresholds;

    // Mapping of chain name => recipient address. Verifier is stored as a string for Axelar.
    // Stored chain names are in Title Case - "Polygon" "Ethereum" "Moonbeam" etc.
    mapping(string => string) public stakingVerifier;

    constructor()
    AxelarExecutable(0x4F4495243837681061C4743b74B3eEdf548D56A5) // Ethereum
    {
        discountThresholds[DiscountTier.TIER_1] = 1 * 10**18; // 1 YESP;
        discountThresholds[DiscountTier.TIER_2] = 1 * 10**6 * 10**18; // 10m YESP;
        discountThresholds[DiscountTier.TIER_3] = 5 * 10**6 * 10**18; // 50m YESP;
        stakingVerifier["Polygon"] = "0x1e0A2c2570Ec5490f9a6816AA36f9F1E3f02Dbc2";
    }
    using SafeERC20 for IERC20;

    // If staking is entered with a position already staked, this function will add to the existing amount and 
    // renew the staking period. Tier 1 staking amount is the minimum required.
    function enterStaking(uint256 amount, string[] calldata stakingChains) external payable nonReentrant {
        if (amountStaked[msg.sender] + amount < discountThresholds[DiscountTier.TIER_1])
            revert StakeBelowThreshhold();
        
        amountStaked[msg.sender] += amount;
        stakingEnteredTimestamp[msg.sender] = block.timestamp;

        YESPTOKEN.safeTransferFrom(msg.sender, address(this), amount);

        setRemoteValue(amountStaked[msg.sender], stakingChains, msg.sender);

        emit StakingEntered(msg.sender, amount, block.timestamp);
    }

    // Same as above, but support ERC20Permit.
    function enterStakingWithPermit(uint256 amount, string[] calldata stakingChains, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external payable nonReentrant {
        if (amountStaked[msg.sender] + amount < discountThresholds[DiscountTier.TIER_1])
            revert StakeBelowThreshhold();
        
        amountStaked[msg.sender] += amount;
        stakingEnteredTimestamp[msg.sender] = block.timestamp;

        YESPTOKENPERMIT.permit(msg.sender, address(this), YESPTOKEN.balanceOf(msg.sender), deadline, v, r, s);
        YESPTOKEN.safeTransferFrom(msg.sender, address(this), amount);

        setRemoteValue(amountStaked[msg.sender], stakingChains, msg.sender);

        emit StakingEntered(msg.sender, amount, block.timestamp);
    }

    // Withdraw a certain amount of tokens from the currently staked amount. Must be after lockup period.
    function exitStaking(uint256 amount, string[] calldata stakingChains) external payable nonReentrant {
        if (amount > amountStaked[msg.sender])
            revert WithdrawOverBalance();

        uint256 timeStakingEntered = stakingEnteredTimestamp[msg.sender];
        if (block.timestamp - timeStakingEntered < lockupTime)
            revert WithdrawBeforeLockupEnd();
        
        amountStaked[msg.sender] -= amount;

        YESPTOKEN.safeTransferFrom(address(this), msg.sender, amount);

        setRemoteValue(amountStaked[msg.sender], stakingChains, msg.sender);

        emit StakingExited(msg.sender, amount, block.timestamp);
    }

    //Returns amount, staking entered time
    function getStakingPosition(address user) external view returns (uint256, uint256) {
        return (amountStaked[user], stakingEnteredTimestamp[user]);
    }

    //Returns current unlock time
    function getUnlockTime(address user) external view returns(uint256) {
        return stakingEnteredTimestamp[user] + lockupTime;
    }

    function isUserDiscountElegible(address user) external view returns(bool) {
        return amountStaked[user] >= discountThresholds[DiscountTier.TIER_1];
    }

    function userDiscountTier(address user) external view returns (DiscountTier) {
        if (amountStaked[user] >= discountThresholds[DiscountTier.TIER_3])
            return (DiscountTier.TIER_3);
        if (amountStaked[user] >= discountThresholds[DiscountTier.TIER_2])
            return (DiscountTier.TIER_2);
        if (amountStaked[user] >= discountThresholds[DiscountTier.TIER_1])
            return (DiscountTier.TIER_1);
        return DiscountTier.NO_TIER;
    }

    // Call this function to update the value of this contract along with all its siblings'.
    function setRemoteValue(
        uint256 value_,
        string[] calldata destinationChains,
        address user
    ) internal {
        uint256 len = destinationChains.length;
        uint256[] memory gasArray = divvyGas(msg.value, len);
        bytes memory payload = abi.encode(user, value_);

        if (msg.value == 0)
            revert XChainUnderfunded();
        
        if (msg.value > 0) {
            for (uint i; i<len;) {
                if (emptyString(stakingVerifier[destinationChains[i]]))
                    revert BadDestinationChains();

                gasReceiver.payNativeGasForContractCall{ value: gasArray[i] }(
                    address(this),
                    destinationChains[i],
                    stakingVerifier[destinationChains[i]],
                    payload,
                    user
                );
                gateway.callContract(destinationChains[i], stakingVerifier[destinationChains[i]], payload);
                unchecked{++i;}
            }
        }
    }

    //Admin functions (unstake for user, add a new chain, manually update a staking value, change lockup or thresholds).
    function adminExitStaking(address user) external onlyOwner {
        uint256 amount = amountStaked[user];
        amountStaked[user] -= amount;

        YESPTOKEN.safeTransferFrom(address(this), user, amount);

        emit StakingExited(user, amount, block.timestamp);
    }

    function adminSetRemote(uint256 amount, string[] calldata destinationChains, address user) external payable onlyOwner {
        setRemoteValue(amount, destinationChains, user);
    }

    function adminAddChain(string calldata chainName, string memory verifierContract) external onlyOwner {
        stakingVerifier[chainName] = verifierContract;
    }

    function adminSetLockup(uint256 lockup) external onlyOwner {
        lockupTime = lockup; // in seconds
    }

    function adminSetDiscountThreshold(DiscountTier tier, uint256 threshold) external onlyOwner {
        discountThresholds[tier] = threshold;
    }

    // Divides the gas value among multiple chains for message posting
    function divvyGas(uint256 value, uint256 parts) internal pure returns (uint256[] memory) {
        uint256 baseGas = value/parts;
        uint256 remainder = value%baseGas;
        uint256[] memory gasArray = new uint256[](parts);
        for(uint i; i<parts;) {
            gasArray[i] = baseGas;
            unchecked {++i;}
        }
        gasArray[gasArray.length - 1] += remainder;
        return gasArray;
    }

    function emptyString(string memory _input) internal pure returns (bool){
        return bytes(_input).length == 0;
    }

}