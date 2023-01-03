// SPDX-License-Identifier: MIT                                                                            
                                                    
pragma solidity 0.8.17;

import './Ownable.sol';
import './IERC20.sol';

contract TokenHandler is Ownable {
    function sendTokenToOwner(address token) external onlyOwner {
        if(IERC20(token).balanceOf(address(this)) > 0){
            IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
        }
    }
}