// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);

}

uint8 constant NORMAL = 9;

contract TokenBalance {
    using SafeMath for uint256;

    string public DESCRIPTION = "ICHIPowah Interperter for wallet balance";


    /**
     * @notice returns total supply in 9 decimals
     * @param instance the address of the token for this interperter usage
     */
    function getSupply(address instance) public view returns (uint256 supply) {
        IERC20 token = IERC20(instance);
        if (token.decimals() > NORMAL) {
            supply = token.totalSupply().div(10 ** (token.decimals() - NORMAL));
        } else if(token.decimals() < NORMAL) {
            supply = token.totalSupply().mul(10 ** (NORMAL - token.decimals()));
        } else {
            supply = token.totalSupply();
        }
    }

    /**
     * @notice gets ICHI Powah in 9 decimals
     * @param instance address of the token for this interperter usage 
     * @param user wallet address
     */
    function getPowah(address instance, address user, bytes32 /*params*/) public view returns (uint256 balance) {
        IERC20 token = IERC20(instance);
        if (token.decimals() > NORMAL) {
            balance = token.balanceOf(user).div(10 ** (token.decimals() - NORMAL));
        } else if(token.decimals() < NORMAL) {
            balance = token.balanceOf(user).mul(10 ** (NORMAL - token.decimals()));
        } else {
            balance = token.balanceOf(user);
        }
    }
}