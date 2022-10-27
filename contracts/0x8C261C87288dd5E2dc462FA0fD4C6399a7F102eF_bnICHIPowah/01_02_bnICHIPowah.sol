// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IStake {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

uint256 constant NINE_DECIMALS = 1e9;

contract bnICHIPowah {
    using SafeMath for uint256;

    string public DESCRIPTION = "ICHIPowah Interperter for Bancor V3 ICHI tokens";

    function getSupply(address instance) public view returns (uint256 bnIchi) {
        IStake bnIchiTokenStake = IStake(instance);
        bnIchi = bnIchiTokenStake.totalSupply();
    }

    function getPowah(address instance, address user, bytes32 /*params*/) public view returns (uint256 bnIchi) {
        IERC20 bnIchiToken = IERC20(instance);
        bnIchi = bnIchiToken.balanceOf(user);
    }
}