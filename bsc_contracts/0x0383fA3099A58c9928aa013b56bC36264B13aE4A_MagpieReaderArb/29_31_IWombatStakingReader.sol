// SPDX-License-Identifier: MIT

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity ^0.8.0;

interface IWombatStakingReader {
    function masterWombat() external view returns(address);
    struct WombatStakingPool {
        uint256 pid;                // pid on master wombat
        address depositToken;       // token to be deposited on wombat
        address lpAddress;          // token received after deposit on wombat
        address receiptToken;       // token to receive after
        address rewarder;
        address helper;
        address depositTarget;
        bool isActive;
    }

    function pools(address lpAdress)  external view returns(WombatStakingPool memory);
    function isPoolFeeFree(address lpAdress)  external view returns(bool);
    function bribeCallerFee() external view returns(uint256);
    function bribeProtocolFee() external view returns(uint256);
    function wom() external view returns(address);
    function mWom() external view returns(address);

}