/**
 *Submitted for verification at BscScan.com on 2023-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error NotOwner();
error NotReceiver();
error NotActive();
error BelowMin();
error AboveMax();

/**
 * @title ERC20
 * @dev Interface for ERC20 tokens
 */
interface ERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

/**
 * @title Crowdfunding
 * @dev Fundraising contract for crypto projects, payment token will be specified by owner on constructor
 */
contract Crowdfunding {
    ERC20 public payment;
    bool public isActive = true;
    address public owner;
    address public receiver;
    address public recipient;
    uint256 public min;
    uint256 public max;
    uint256 public sold;
    address[] public participants;
    mapping(address => uint256) public allocations;

    constructor(
        address _payment,
        address _recipient,
        uint256 _min,
        uint256 _max
    ) {
        owner = msg.sender;
        payment = ERC20(_payment);
        recipient = _recipient;
        min = _min;
        max = _max;
    }

    function transferOwnership(address _receiver) public onlyOwner {
        receiver = _receiver;
    }

    function updateOwner() public onlyReceiver {
        owner = receiver;
        receiver = address(0);
    }

    function updatePayment(address _payment) public onlyOwner {
        payment = ERC20(_payment);
    }

    function updateRecipient(address _recipient) public onlyOwner {
        recipient = _recipient;
    }

    function updateMin(uint256 _amount) public onlyOwner {
        min = _amount;
    }

    function updateMax(uint256 _amount) public onlyOwner {
        max = _amount;
    }

    function togglePause() public onlyOwner {
        isActive = !isActive;
    }

    function purchase(uint256 _amount) public onlyActive {
        // validation
        if (_amount < min) {
            revert BelowMin();
        }
        if (allocations[msg.sender] + _amount > max) {
            revert AboveMax();
        }

        // start process
        payment.transferFrom(msg.sender, recipient, _amount);
        if (allocations[msg.sender] == 0) participants.push(msg.sender);
        allocations[msg.sender] += _amount;
        sold += _amount;
    }

    function getParticipantsLength() public view returns (uint256) {
        return participants.length;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier onlyReceiver() {
        if (msg.sender != receiver) {
            revert NotReceiver();
        }
        _;
    }

    modifier onlyActive() {
        if (!isActive) {
            revert NotActive();
        }
        _;
    }
}