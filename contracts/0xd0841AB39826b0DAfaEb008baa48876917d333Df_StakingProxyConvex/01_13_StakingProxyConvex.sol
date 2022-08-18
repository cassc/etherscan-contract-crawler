// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/ICurveConvex.sol";
import "./interfaces/IConvexWrapper.sol";
import "./StakingProxyBase.sol";
import "./interfaces/IFraxFarmERC20.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';



contract StakingProxyConvex is StakingProxyBase, ReentrancyGuard{
    using SafeERC20 for IERC20;

    address public constant poolRegistry = address(0x7413bFC877B5573E29f964d572f421554d8EDF86);
    address public constant convexCurveBooster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

    address public curveLpToken;
    address public convexDepositToken;

    constructor() {
    }

    function vaultType() external pure override returns(VaultType){
        return VaultType.Convex;
    }

    function vaultVersion() external pure override returns(uint256){
        return 3;
    }

    //initialize vault
    function initialize(address _owner, address _stakingAddress, address _stakingToken, address _rewardsAddress) external override{
        require(owner == address(0),"already init");

        //set variables
        owner = _owner;
        stakingAddress = _stakingAddress;
        stakingToken = _stakingToken;
        rewards = _rewardsAddress;

        //get tokens from pool info
        (address _lptoken, address _token,,, , ) = ICurveConvex(convexCurveBooster).poolInfo(IConvexWrapper(_stakingToken).convexPoolId());
    
        curveLpToken = _lptoken;
        convexDepositToken = _token;

        //set infinite approvals
        IERC20(_stakingToken).approve(_stakingAddress, type(uint256).max);
        IERC20(_lptoken).approve(_stakingToken, type(uint256).max);
        IERC20(_token).approve(_stakingToken, type(uint256).max);
    }


    //create a new locked state of _secs timelength with a Curve LP token
    function stakeLockedCurveLp(uint256 _liquidity, uint256 _secs) external onlyOwner nonReentrant returns (bytes32 kek_id){
        if(_liquidity > 0){
            //pull tokens from user
            IERC20(curveLpToken).safeTransferFrom(msg.sender, address(this), _liquidity);

            //deposit into wrapper
            IConvexWrapper(stakingToken).deposit(_liquidity, address(this));

            //stake
            kek_id = IFraxFarmERC20(stakingAddress).stakeLocked(_liquidity, _secs);
        }
        
        //checkpoint rewards
        _checkpointRewards();
    }

    //create a new locked state of _secs timelength with a Convex deposit token
    function stakeLockedConvexToken(uint256 _liquidity, uint256 _secs) external onlyOwner nonReentrant returns (bytes32 kek_id){
        if(_liquidity > 0){
            //pull tokens from user
            IERC20(convexDepositToken).safeTransferFrom(msg.sender, address(this), _liquidity);

            //stake into wrapper
            IConvexWrapper(stakingToken).stake(_liquidity, address(this));

            //stake into frax
            kek_id = IFraxFarmERC20(stakingAddress).stakeLocked(_liquidity, _secs);
        }
        
        //checkpoint rewards
        _checkpointRewards();
    }

    //create a new locked state of _secs timelength
    function stakeLocked(uint256 _liquidity, uint256 _secs) external onlyOwner nonReentrant returns (bytes32 kek_id){
        if(_liquidity > 0){
            //pull tokens from user
            IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), _liquidity);

            //stake
            kek_id = IFraxFarmERC20(stakingAddress).stakeLocked(_liquidity, _secs);
        }
        
        //checkpoint rewards
        _checkpointRewards();
    }

    //add to a current lock
    function lockAdditional(bytes32 _kek_id, uint256 _addl_liq) external onlyOwner nonReentrant{
        if(_addl_liq > 0){
            //pull tokens from user
            IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), _addl_liq);

            //add stake
            IFraxFarmERC20(stakingAddress).lockAdditional(_kek_id, _addl_liq);
        }
        
        //checkpoint rewards
        _checkpointRewards();
    }

    //add to a current lock
    function lockAdditionalCurveLp(bytes32 _kek_id, uint256 _addl_liq) external onlyOwner nonReentrant{
        if(_addl_liq > 0){
            //pull tokens from user
            IERC20(curveLpToken).safeTransferFrom(msg.sender, address(this), _addl_liq);

            //deposit into wrapper
            IConvexWrapper(stakingToken).deposit(_addl_liq, address(this));

            //add stake
            IFraxFarmERC20(stakingAddress).lockAdditional(_kek_id, _addl_liq);
        }
        
        //checkpoint rewards
        _checkpointRewards();
    }

    //add to a current lock
    function lockAdditionalConvexToken(bytes32 _kek_id, uint256 _addl_liq) external onlyOwner nonReentrant{
        if(_addl_liq > 0){
            //pull tokens from user
            IERC20(convexDepositToken).safeTransferFrom(msg.sender, address(this), _addl_liq);

            //stake into wrapper
            IConvexWrapper(stakingToken).stake(_addl_liq, address(this));

            //add stake
            IFraxFarmERC20(stakingAddress).lockAdditional(_kek_id, _addl_liq);
        }
        
        //checkpoint rewards
        _checkpointRewards();
    }

    // Extends the lock of an existing stake
    function lockLonger(bytes32 _kek_id, uint256 new_ending_ts) external onlyOwner nonReentrant{
        //update time
        IFraxFarmERC20(stakingAddress).lockAdditional(_kek_id, new_ending_ts);

        //checkpoint rewards
        _checkpointRewards();
    }

    //withdraw a staked position
    //frax farm transfers first before updating farm state so will checkpoint during transfer
    function withdrawLocked(bytes32 _kek_id) external onlyOwner nonReentrant{        
        //withdraw directly to owner(msg.sender)
        IFraxFarmERC20(stakingAddress).withdrawLocked(_kek_id, msg.sender);

        //checkpoint rewards
        _checkpointRewards();
    }

    //withdraw a staked position
    //frax farm transfers first before updating farm state so will checkpoint during transfer
    function withdrawLockedAndUnwrap(bytes32 _kek_id) external onlyOwner nonReentrant{
        //withdraw
        IFraxFarmERC20(stakingAddress).withdrawLocked(_kek_id, address(this));

        //unwrap
        IConvexWrapper(stakingToken).withdrawAndUnwrap(IERC20(stakingToken).balanceOf(address(this)));
        IERC20(curveLpToken).transfer(owner,IERC20(curveLpToken).balanceOf(address(this)));

        //checkpoint rewards
        _checkpointRewards();
    }

    //helper function to combine earned tokens on staking contract and any tokens that are on this vault
    function earned() external view override returns (address[] memory token_addresses, uint256[] memory total_earned) {
        //get list of reward tokens
        address[] memory rewardTokens = IFraxFarmERC20(stakingAddress).getAllRewardTokens();
        uint256[] memory stakedearned = IFraxFarmERC20(stakingAddress).earned(address(this));
        IConvexWrapper.EarnedData[] memory convexrewards = IConvexWrapper(stakingToken).earned(address(this));

        uint256 extraRewardsLength = IRewards(rewards).rewardTokenLength();
        token_addresses = new address[](rewardTokens.length + extraRewardsLength + convexrewards.length);
        total_earned = new uint256[](rewardTokens.length + extraRewardsLength + convexrewards.length);

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

        //add convex farm earned tokens
        for(uint256 i = 0; i < convexrewards.length; i++){
            token_addresses[i+rewardTokens.length+extraRewardsLength] = convexrewards[i].token;
            total_earned[i+rewardTokens.length+extraRewardsLength] = convexrewards[i].amount;
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
            //claim frax farm
            IFraxFarmERC20(stakingAddress).getReward(address(this));
            //claim convex farm and forward to owner
            IConvexWrapper(stakingToken).getReward(address(this),owner);

            //double check there have been no crv/cvx claims directly to this address
            uint256 b = IERC20(crv).balanceOf(address(this));
            if(b > 0){
                IERC20(crv).safeTransfer(owner, b);
            }
            b = IERC20(cvx).balanceOf(address(this));
            if(b > 0){
                IERC20(cvx).safeTransfer(owner, b);
            }
        }

        //process fxs fees
        _processFxs();

        //get list of reward tokens
        address[] memory rewardTokens = IFraxFarmERC20(stakingAddress).getAllRewardTokens();

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
            //claim frax farm
            IFraxFarmERC20(stakingAddress).getReward(address(this));
            //claim convex farm and forward to owner
            IConvexWrapper(stakingToken).getReward(address(this),owner);
        }

        //process fxs fees
        _processFxs();

        //transfer
        _transferTokens(_rewardTokenList);

        //extra rewards
        _processExtraRewards();
    }

}