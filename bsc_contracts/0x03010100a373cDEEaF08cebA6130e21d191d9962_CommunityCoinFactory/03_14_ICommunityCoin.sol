// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStructs.sol";
import "../minimums/libs/MinimumsLib.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
interface ICommunityCoin {
    
    struct UserData {
        uint256 unstakeable; // total unstakeable across pools
        uint256 unstakeableBonuses;
        MinimumsLib.UserStruct tokensLocked;
        MinimumsLib.UserStruct tokensBonus;
        // lists where user staked or obtained bonuses
        EnumerableSetUpgradeable.AddressSet instancesList;
    }

    struct InstanceStruct {
        uint256 _instanceStaked;
        
        uint256 redeemable;
        // //      user
        // mapping(address => uint256) usersStaked;
        //      user
        mapping(address => uint256) unstakeable;
        //      user
        mapping(address => uint256) unstakeableBonuses;
        
    }

    function initialize(
        string calldata name,
        string calldata symbol,
        address poolImpl,
        address hook,
        address instancesImpl,
        uint256 discountSensitivity,
        IStructs.CommunitySettings calldata communitySettings,
        address costManager,
        address producedBy
    ) external;

    enum Strategy{ UNSTAKE, REDEEM} 

    event InstanceCreated(address indexed erc20token, address instance);
    
    error InsufficientBalance(address account, uint256 amount);
    error InsufficientAmount(address account, uint256 amount);
    error StakeNotUnlockedYet(address account, uint256 locked, uint256 remainingAmount);
    error TrustedForwarderCanNotBeOwner(address account);
    error DeniedForTrustedForwarder(address account);
    error OwnTokensPermittedOnly();
    error UNSTAKE_ERROR();
    error REDEEM_ERROR();
    error HookTransferPrevent(address from, address to, uint256 amount);
    error AmountExceedsAllowance(address account,uint256 amount);
    error AmountExceedsMaxTariff();
    
    function issueWalletTokens(address account, uint256 amount, uint256 priceBeforeStake, uint256 donatedAmount) external;

}