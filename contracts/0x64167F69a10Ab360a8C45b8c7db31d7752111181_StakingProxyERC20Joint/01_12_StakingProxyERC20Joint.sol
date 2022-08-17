// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./StakingProxyBase.sol";
import "./interfaces/IFraxFarmERC20NoReturn.sol";
import "./interfaces/IJointVaultManager.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';


contract StakingProxyERC20Joint is StakingProxyBase, ReentrancyGuard{
    using SafeERC20 for IERC20;

    enum PlatformType{
        Unknown,
        Temple
    }

    address public immutable jointManager;
    bool public proxySetFromJoint;
    PlatformType public immutable jointPlatform;

    constructor(address _manager, PlatformType _platformType) {
        jointManager = _manager;
        jointPlatform = _platformType;
    }

    modifier onlyJointManager() {
        require(jointManager == msg.sender, "!auth_jmng");
        _;
    }

    function vaultType() external pure override returns(VaultType){
        return VaultType.Erc20Joint;
    }

    function vaultVersion() external pure override returns(uint256){
        return 1;
    }

    //initialize vault
    function initialize(address _owner, address _stakingAddress, address _stakingToken, address _rewardsAddress) external override{
        require(owner == address(0),"already init");

        //check manager
        require(IJointVaultManager(jointManager).isAllowed(_owner),"!auth");

        //set variables
        owner = _owner;
        stakingAddress = _stakingAddress;
        stakingToken = _stakingToken;
        rewards = _rewardsAddress;

        //set infinite approval
        IERC20(stakingToken).approve(_stakingAddress, type(uint256).max);
    }

    function jointSetVeFXSProxy(address _proxy) external onlyJointManager{
        //checkpoint rewards
        _checkpointFarm();

        //set the vefxs proxy
        _setVeFXSProxy(_proxy);

        //if joint manager requires setting, dont allow main admin to revert back
        proxySetFromJoint = true;

        //checkpoint rewards again
        _checkpointFarm();
    }

    function setVeFXSProxy(address _proxy) external override onlyAdmin{
        require(!proxySetFromJoint,"!setproxy");
        require(_proxy == vefxsProxy || _proxy == IJointVaultManager(jointManager).jointownerProxy(),"!jointproxy" );
        //set the vefxs proxy
        _setVeFXSProxy(_proxy);
    }


    //create a new locked state of _secs timelength
    function stakeLocked(uint256 _liquidity, uint256 _secs) external onlyOwner nonReentrant{
        if(_liquidity > 0){
            //pull tokens from user
            IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), _liquidity);

            //stake (use balanceof in case of change during transfer)
            IFraxFarmERC20NoReturn(stakingAddress).stakeLocked(IERC20(stakingToken).balanceOf(address(this)), _secs);
        }
        
        //checkpoint rewards
        _checkpointRewards();
    }

    //add to a current lock
    function lockAdditional(bytes32 _kek_id, uint256 _addl_liq) external onlyOwner nonReentrant{
        if(_addl_liq > 0){
            //pull tokens from user
            IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), _addl_liq);

            //add stake (use balanceof in case of change during transfer)
            IFraxFarmERC20NoReturn(stakingAddress).lockAdditional(_kek_id, IERC20(stakingToken).balanceOf(address(this)));
        }
        
        //checkpoint rewards
        _checkpointRewards();
    }

    //withdraw a staked position
    function withdrawLocked(bytes32 _kek_id) external onlyOwner nonReentrant{

        //withdraw directly to owner(msg.sender)
        IFraxFarmERC20NoReturn(stakingAddress).withdrawLocked(_kek_id, msg.sender);

        //checkpoint rewards
        _checkpointRewards();
    }


    //helper function to combine earned tokens on staking contract and any tokens that are on this vault
    function earned() external view override returns (address[] memory token_addresses, uint256[] memory total_earned) {
        //get list of reward tokens
        address[] memory rewardTokens = IFraxFarmERC20NoReturn(stakingAddress).getAllRewardTokens();
        uint256[] memory stakedearned = IFraxFarmERC20NoReturn(stakingAddress).earned(address(this));
        
        token_addresses = new address[](rewardTokens.length + IRewards(rewards).rewardTokenLength());
        total_earned = new uint256[](rewardTokens.length + IRewards(rewards).rewardTokenLength());
        //add any tokens that happen to be already claimed but sitting on the vault
        //(ex. withdraw claiming rewards)
        for(uint256 i = 0; i < rewardTokens.length; i++){
            token_addresses[i] = rewardTokens[i];
            total_earned[i] = stakedearned[i] + IERC20(rewardTokens[i]).balanceOf(address(this));
        }

        IRewards.EarnedData[] memory extraRewards = IRewards(rewards).claimableRewards(address(this));
        for(uint256 i = 0; i < extraRewards.length; i++){
            token_addresses[i+rewardTokens.length] = extraRewards[i].token;
            total_earned[i+rewardTokens.length] = extraRewards[i].amount;
        }
    }

    /*
    claim flow:
        claim rewards directly to the vault
        calculate fees to send to fee deposit
        send fxs to a holder contract for fees
        get reward list of tokens that were received
        send all remaining tokens to owner

    A slightly less gas intensive approach could be to send rewards directly to a holder contract and have it sort everything out.
    However that makes the logic a bit more complex as well as runs a few future proofing risks
    */
    function getReward() external override{
        getReward(true);
    }

    //get reward with claim option.
    //_claim bool is for the off chance that rewardCollectionPause is true so getReward() fails but
    //there are tokens on this vault for cases such as withdraw() also calling claim.
    //can also be used to rescue tokens on the vault
    function getReward(bool _claim) public override{

        //claim
        if(_claim){
            IFraxFarmERC20NoReturn(stakingAddress).getReward(address(this));
        }

        //process fxs fees
        _processFxsJoint();

        //get list of reward tokens
        address[] memory rewardTokens = IFraxFarmERC20NoReturn(stakingAddress).getAllRewardTokens();

        //transfer
        _transferTokens(rewardTokens);

        //extra rewards
        _processExtraRewards();
    }

    //auxiliary function to supply token list(save a bit of gas + dont have to claim everything)
    //_claim bool is for the off chance that rewardCollectionPause is true so getReward() fails but
    //there are tokens on this vault for cases such as withdraw() also calling claim.
    //can also be used to rescue tokens on the vault
    function getReward(bool _claim, address[] calldata _rewardTokenList) external override{

        //claim
        if(_claim){
            IFraxFarmERC20NoReturn(stakingAddress).getReward(address(this));
        }

        //process fxs fees
        _processFxsJoint();

        //transfer
        _transferTokens(_rewardTokenList);

        //extra rewards
        _processExtraRewards();
    }


    function _processFxsJoint() internal{

        //send fxs fees to fee deposit
        uint256 fxsBalance = IERC20(fxs).balanceOf(address(this));

        //owner fees
        (uint256 feeAmount, address depositAddress) = IJointVaultManager(jointManager).getOwnerFee(fxsBalance,usingProxy);
        if(feeAmount > 0){
            IERC20(fxs).transfer(depositAddress, feeAmount);
        }

        //coowner fees
        (feeAmount, depositAddress) = IJointVaultManager(jointManager).getJointownerFee(fxsBalance,usingProxy);
        if(feeAmount > 0){
            IERC20(fxs).transfer(depositAddress, feeAmount);
        }

        //transfer remaining fxs to owner
        fxsBalance = IERC20(fxs).balanceOf(address(this));
        if(fxsBalance > 0){
            IERC20(fxs).transfer(owner, fxsBalance);
        }
    }

}