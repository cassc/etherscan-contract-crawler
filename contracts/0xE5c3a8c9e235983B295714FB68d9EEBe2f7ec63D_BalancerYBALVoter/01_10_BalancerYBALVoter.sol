// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

// These are the core Yearn libraries
import "IERC20.sol";
import "Math.sol";

import "BaseStrategy.sol";

interface VoteEscrow {
    function create_lock(uint, uint) external;
    function increase_amount(uint) external;
    function withdraw() external;
}

contract BalancerYBALVoter {
    using SafeERC20 for IERC20;
    address constant public bal = address(0xba100000625a3754423978a60c9317c58a424e3D);
    address constant public balweth = address(0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56);
    
    address constant public escrow = address(0xC128a9954e6c874eA3d62ce62B468bA073093F25);
    
    address public governance;
    address public strategy;
    
    constructor() public {
        governance = msg.sender;
    }
    
    function getName() external pure returns (string memory) {
        return "BalancerYBALVoter";
    }

    function createLock(uint _value, uint _unlockTime) external {
        require(msg.sender == strategy || msg.sender == governance, "!authorized");
        IERC20(balweth).safeApprove(escrow, 0);
        IERC20(balweth).safeApprove(escrow, _value);
        VoteEscrow(escrow).create_lock(_value, _unlockTime);
    }
    
    function increaseAmount(uint _value) external {
        require(msg.sender == strategy || msg.sender == governance, "!authorized");
        IERC20(balweth).safeApprove(escrow, 0);
        IERC20(balweth).safeApprove(escrow, _value);
        VoteEscrow(escrow).increase_amount(_value);
    }
    
    function release() external {
        require(msg.sender == strategy || msg.sender == governance, "!authorized");
        VoteEscrow(escrow).withdraw();
    }
    
    function setStrategy(address _strategy) external {
        require(msg.sender == governance, "!governance");
        strategy = _strategy;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function execute(address to, uint value, bytes calldata data) external returns (bool, bytes memory) {
        require(msg.sender == strategy || msg.sender == governance, "!governance");
        (bool success, bytes memory result) = to.call{value:value}(data);
        
        return (success, result);
    }
}