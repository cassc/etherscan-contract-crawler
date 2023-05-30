// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWooStakingProxy {
    /* ----- Events ----- */
    event StakeOnProxy(address indexed user, uint256 amount);
    event UnstakeOnProxy(address indexed user, uint256 amount);
    event SetAutoCompoundOnProxy(address indexed user, bool flag);
    event CompoundMPOnProxy(address indexed user);
    event CompoundAllOnProxy(address indexed user);
    event SetGasForAction(uint8 action, uint256 gas);
    event SetControllerChainId(uint16 chainId);
    event SetControllerOnProxy(address indexed controller);

    /* ----- State Variables ----- */

    function controllerChainId() external view returns (uint16);

    function controller() external view returns (address);

    function want() external view returns (IERC20);

    function balances(address user) external view returns (uint256 balance);

    /* ----- Functions ----- */

    function estimateFees(uint8 _action, uint256 _amount) external view returns (uint256 messageFee);

    function stake(uint256 _amount) external payable;

    function stake(address _user, uint256 _amount) external payable;

    function unstake(uint256 _amount) external payable;

    function unstakeAll() external payable;

    function setAutoCompound(bool _flag) external payable;

    function compoundMP() external payable;

    function compoundAll() external payable;
}