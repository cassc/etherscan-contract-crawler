// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IFeeReceiver.sol";
import "./interfaces/IRewards.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';



contract FeeReceiverVlCvx is IFeeReceiver {
    using SafeERC20 for IERC20;

    address public constant fxs = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    address public constant vlcvx = address(0x72a19342e8F1838460eBFCCEf09F6585e32db86E);
    
    event RewardsDistributed(address indexed token, uint256 amount);

    constructor() {
        IERC20(fxs).approve(vlcvx, type(uint256).max);
    }

    function processFees() external {
        uint256 fxsbalance = IERC20(fxs).balanceOf(address(this));
       
        //process vlcvx rewards
        if(fxsbalance > 0){
            //send to vlcvx
            IRewards(vlcvx).notifyRewardAmount(fxs, fxsbalance);
            emit RewardsDistributed(fxs, fxsbalance);
        }
    }

}