// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./BAMM.sol";


contract BLens {
    struct UserInfo {
        uint256 bammUserBalance;
        uint256 bammTotalSupply;

        uint256 thusdUserBalance;
        uint256 collateralUserBalance;

        uint256 thusdTotal;
        uint256 collateralTotal;
    }

    function getUserInfo(address user, BAMM bamm) external view returns(UserInfo memory info) {
        info.bammUserBalance = bamm.balanceOf(user);
        info.bammTotalSupply = bamm.totalSupply();
        
        StabilityPool sp = bamm.SP();
        info.thusdTotal = sp.getCompoundedTHUSDDeposit(address(bamm));
        info.collateralTotal = bamm.getCollateralBalance();

        info.thusdUserBalance = info.thusdTotal * info.bammUserBalance / info.bammTotalSupply;
        info.collateralUserBalance = info.collateralTotal * info.bammUserBalance / info.bammTotalSupply;        
    }
}