// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.19;

import "./vetMeStake.sol";

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
    assert(c / a == b);
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}
contract VetMeClaim is Ownable{ 
    IERC20 public immutable rewardsToken;

    uint public totalReward;
    uint public totalForStake;
    VetMeStaking vContract;
    mapping(address => bool) public rewarded;

    event Claimed(address sender, uint amount);


    constructor(){
        rewardsToken = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        // totalForStake = _totalForStake;
        vContract = VetMeStaking(0x64C59934A9700a957BE31410327E80B46dC0333d);
    }

    function notifyRewardAmount(uint _amount) external payable {
        onlyOwner();
         require(_amount > 0, "Amount must be greater than zero");
        totalReward += _amount;
    }


    function claimReward() external{
        require(vContract.balanceOf(_msgSender()) > 0,"You have no stake"); 
        require(!rewarded[msg.sender], "Reward has been claimed");
        uint256 roundValue = SafeMath.ceil(vContract.balanceOf(_msgSender()), 10000);

        uint256 user_percentage = SafeMath.div(SafeMath.mul(roundValue, 10000), 151786855 * 10**9); 

        uint  reward = (user_percentage * totalReward) / 10000;

        rewarded[msg.sender] = true;
        rewardsToken.transfer(msg.sender, reward);
        emit Claimed(_msgSender(),reward);
    }

     function redeemReward() external{
        require(totalReward > 0,"No reward in the contract"); 
         onlyOwner();
         rewardsToken.transfer(msg.sender,rewardsToken.balanceOf(address(this)));
         totalReward = 0;
    }

}