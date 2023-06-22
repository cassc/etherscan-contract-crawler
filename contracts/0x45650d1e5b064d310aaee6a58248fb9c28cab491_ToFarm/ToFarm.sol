/**
 *Submitted for verification at Etherscan.io on 2023-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IERC20 {
    function balanceOf(address account) external returns(uint256);
    function allowance(address from, address to) external returns(uint256);
    function approve(address to, uint256 amount) external returns(bool);
    function transfer(address to, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
}

interface IFarm {
    function startFarming(uint256 amount, uint256 period) external;
}

interface IMultiFarm {
    function startFarming(address token, uint256 amount, uint256 period) external;
}

contract ToFarm {
    error MismatchLangths();
    error BadFarm(uint256 index);

    function farm(address token, uint256 period, address[] calldata farms, uint256[] calldata amounts) external {
        if (farms.length != amounts.length) revert MismatchLangths();

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        IERC20(token).transferFrom(msg.sender, address(this), totalAmount);

        for (uint256 i = 0; i < farms.length; i++) {
            IERC20(token).approve(farms[i], amounts[i]);
            try IFarm(farms[i]).startFarming(amounts[i], period) {}
            catch {
                try IMultiFarm(farms[i]).startFarming(token, amounts[i], period) {}
                catch {
                    revert BadFarm(i);
                }    
            }
        }
    }
}