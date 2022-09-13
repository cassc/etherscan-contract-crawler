// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IVoteEscrow} from "./interfaces/Angle/IVoteEscrow.sol";

contract YearnAngleVoter {
    using SafeERC20 for IERC20;
    
    address constant public angle = address(0x31429d1856aD1377A8A0079410B297e1a9e214c2);
    
    address constant public veAngle = address(0x0C462Dbb9EC8cD1630f1728B2CFD2769d09f0dd5);
    
    address public governance;
    address public pendingGovernance;
    address public proxy;
    
    constructor() public {
        governance = address(0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52);
    }
    
    function getName() external pure returns (string memory) {
        return "YearnAngleVoter";
    }
    
    function setProxy(address _proxy) external {
        require(msg.sender == governance, "!governance");
        proxy = _proxy;
    }
    
    function createLock(uint256 _value, uint256 _unlockTime) external {
        require(msg.sender == proxy || msg.sender == governance, "!authorized");
        IERC20(angle).approve(veAngle, _value);
        IVoteEscrow(veAngle).create_lock(_value, _unlockTime);
    }
    
    function increaseAmount(uint _value) external {
        require(msg.sender == proxy || msg.sender == governance, "!authorized");
        IERC20(angle).approve(veAngle, _value);
        IVoteEscrow(veAngle).increase_amount(_value);
    }
    
    function release() external {
        require(msg.sender == proxy || msg.sender == governance, "!authorized");
        IVoteEscrow(veAngle).withdraw();
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        pendingGovernance = _governance;
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "!pending_governance");
        governance = msg.sender;
        pendingGovernance = address(0);
    }
    
    function execute(address to, uint value, bytes calldata data) external returns (bool, bytes memory) {
        require(msg.sender == proxy || msg.sender == governance, "!governance");
        (bool success, bytes memory result) = to.call{value: value}(data);
        
        return (success, result);
    }
}