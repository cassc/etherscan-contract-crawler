// SPDX-License-Identifier: MIT

/*
 * Created by masataka.eth (@masataka_net)
 */

pragma solidity >=0.7.0 <0.9.0;

interface ISBTwithMint {
    function externalMint(address _address , uint256 _amount ) external;
    function balanceOf(address _owner) external view returns (uint256);
}