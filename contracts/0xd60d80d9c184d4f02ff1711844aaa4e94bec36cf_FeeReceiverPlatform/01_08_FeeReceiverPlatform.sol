// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IBooster.sol";
import "./interfaces/IVoterProxy.sol";
import "./interfaces/IFeeReceiver.sol";
import "./interfaces/IRewards.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';



contract FeeReceiverPlatform is IFeeReceiver {
    using SafeERC20 for IERC20;

    address public constant fxs = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    address public constant vefxsRevenueShare = address(0x31c5E6D1891d2Af49dEc041D41a3A663E03F8F24);
    address public constant treasury = address(0x1389388d01708118b497f59521f6943Be2541bb7);

    event RewardsDistributed(address indexed token, uint256 amount);

    constructor() {
    }

    function processFees() external {
        uint256 tokenbalance = IERC20(fxs).balanceOf(address(this));
        //process
        if(tokenbalance > 0){
            //send to treasury
             IERC20(fxs).transfer(treasury,tokenbalance);
            emit RewardsDistributed(fxs, tokenbalance);
        }

        //also process vefxs revenue share
        IFeeReceiver(vefxsRevenueShare).processFees();
    }

}