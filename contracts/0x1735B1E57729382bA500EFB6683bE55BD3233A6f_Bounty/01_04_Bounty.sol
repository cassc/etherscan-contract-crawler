// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "SafeERC20.sol";

contract Bounty {
    using SafeERC20 for IERC20;

    // target value of bounty fund
    uint256 public bountyFund;

    // token for bounty
    address public token;

    // coordinator address
    address public coordinator;

    // mapping from contestant address to their bounty amount
    mapping(address => uint256) public bounties;

    // Allow function calls only from coordinator
    modifier onlyCoordinator() {
        require(msg.sender == coordinator, "UNAUTHORIZED");
        _;
    }

    // Allow function calls only from EOA
    modifier onlyEOA() {
        uint32 size;
        address callerAddr = msg.sender;
        assembly {
            size := extcodesize(callerAddr)
        }
        require(size == 0, "CONTRACT");
        _;
    }

    constructor (address _coordinator) {
        require(_coordinator != address(0), "BOUNTY_COORDINATOR_ADDRESS");

        coordinator = _coordinator;
    }

    function setFund(address _token) external onlyCoordinator {
        require(_token != address(0), "BOUNTY_TOKEN_ADDRESS");
        require(IERC20(_token).balanceOf(address(this)) > 0, "BALANCE");
        
        token = _token;
        bountyFund = IERC20(token).balanceOf(address(this));
    }

    function setBounties(
        address[] memory _contestants,
        uint256[] memory _bounties,
        uint256 _sumBounty
    ) external onlyCoordinator {
        require(token != address(0), "FUND_NOT_SET");
        require(IERC20(token).balanceOf(address(this)) >= _sumBounty, "INSUFFICIENT_BALANCE");
        require(_sumBounty <= bountyFund, "INCORRECT_SUM");
        require(_contestants.length == _bounties.length, "INCORRECT_ARRAY_LENGTH");

        uint256 sum;
        for (uint256 i = 0; i < _contestants.length; ++i) {
            require(
                (bounties[_contestants[i]] == 0 && _bounties[i] > 0) || 
                (bounties[_contestants[i]] > 0 && _bounties[i] == 0),
                "ONE_ADDRESS_TWO_TIMES"
            );
            bounties[_contestants[i]] = _bounties[i];
            sum += _bounties[i];
        }

        require(_sumBounty == sum, "INCORRECT_INPUT");
    }

    function getMyBounty() external onlyEOA {
        require(bounties[msg.sender] > 0, "ALREADY_PAID");
        uint256 amountToPay = bounties[msg.sender];
        bounties[msg.sender] = 0;
        IERC20(token).safeTransfer(msg.sender, amountToPay);
    }
}