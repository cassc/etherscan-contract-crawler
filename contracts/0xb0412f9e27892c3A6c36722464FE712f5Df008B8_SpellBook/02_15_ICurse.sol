// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ICurse {

    function invocation(address target, uint256 percentage) external;
    function conjuration(address target, uint256 percentage) external;
    function necromancy(address target, address caster, uint256 percentage) external; 
    function alteration(uint256 percentage) external; 
    function divination(uint256 percentage) external; 
    function illusion(address caster) external; 
    
}