pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DolaPayroll {
    using SafeERC20 for IERC20;

    mapping(address => Recipient) public recipients;

    address public constant treasuryAddress = 0x926dF14a23BE491164dCF93f4c468A50ef659D5B;
    address public constant governance = 0x926dF14a23BE491164dCF93f4c468A50ef659D5B;
    IERC20 public constant DOLA = IERC20(0x865377367054516e17014CcdED1e7d814EDC9ce4);
    
    uint256 public yearlyPeriod = 365 days;
    address public fundingCommittee = 0x77C64eEF5F4781Dd6e9405a8a77D80567CFD37E0;

    struct Recipient {
        uint256 lastClaim;
        uint256 ratePerSecond;
        uint256 startTime;
    }

    event NewRecipient(address recipient, uint256 amount);
    event RecipientRemoved(address recipient, uint256 amount);
    event AmountWithdrawn(address recipient, uint256 amount);
    event UpdatedFundingCommittee(address from, address to);

    constructor() public {}

    /**
     * @notice Add a new salary recipient. No notion of stop time. payment can be cancelled by committee or governance at any future time
     * @param _newRecipient new recipient of salary
     * @param _yearlyAmount monthly salary
     */
    function addRecipient(address _newRecipient, uint256 _yearlyAmount) external {
        require(msg.sender == governance || msg.sender == fundingCommittee, "DolaPayroll::addRecipient: only governance or funding committee!");
        require(recipients[_newRecipient].ratePerSecond == 0, "DolaPayroll::addRecipient: recipient already exists!");
        require(_newRecipient != address(0), "DolaPayroll::addRecipient: zero address!");
        require(_newRecipient != address(this), "DolaPayroll::addRecipient: recipient can't be this contract");
        require(_yearlyAmount > 0, "DolaPayroll::addRecipient: amount must be greater than 0");
        // ensure amount is gte to month period else, payment rate per second will be 0
        require(_yearlyAmount >= yearlyPeriod, "DolaPayroll:addRecipient: amount too low for month period!");

        // no notion of end time so using month period, which gov or committee can update. rate per second is calculated on monthly basis
        uint256 amountPerSecond = _div256(_yearlyAmount, yearlyPeriod);

        recipients[_newRecipient] = Recipient({
            lastClaim: 0,
            ratePerSecond: amountPerSecond,
            startTime: block.timestamp
        });

        emit NewRecipient(_newRecipient, _yearlyAmount);
    }

    /**
     * @notice Remove recipient from receiving salary
     * @param _recipient recipient to whom it may concern
     */
    function removeRecipient(address _recipient) external {
        require(msg.sender == governance || msg.sender == fundingCommittee || msg.sender == _recipient, "DolaPayroll::removeRecipient: only governance or funding committee");
        require(recipients[_recipient].ratePerSecond != 0, "DolaPayroll::removeRecipient: recipient does not exist!");

        // calculate remaining balances and delete recipient entry from recipients mapping, then transfer remaining dola to recipient
        Recipient memory recipient = recipients[_recipient];
        uint256 delta = _delta(_recipient);
        uint256 amount;
        if (delta > 0) {
            // transfer remaining unclaimed to recipient
            amount = _balanceOf(_recipient, delta);
            DOLA.safeTransferFrom(treasuryAddress, _recipient, amount);
        }

        delete recipients[_recipient];
        emit RecipientRemoved(_recipient, amount);
    }

    /**
    * @notice withdraw salary
    */
    function withdraw() external {
        require(recipients[msg.sender].ratePerSecond != 0, "DolaPayroll::withdraw: not a recipient!");
        uint256 delta = _delta(msg.sender);
        require(delta > 0, "DolayPayroll::withdraw: not enough time elapsed!");
        
        Recipient storage recipient = recipients[msg.sender];
        recipient.lastClaim = block.timestamp;
        uint256 amount = _balanceOf(msg.sender, delta);
        DOLA.safeTransferFrom(treasuryAddress, msg.sender, amount);

        emit AmountWithdrawn(msg.sender, amount);
    }

    function _delta(address _recipient) internal view returns (uint256) {
        Recipient memory recipient = recipients[_recipient];
        if (recipient.startTime >= block.timestamp) return 0;
        uint256 delta;
        if (recipient.lastClaim == 0) {
            delta = _sub256(block.timestamp, recipient.startTime);
        } else {
            delta = _sub256(block.timestamp, recipient.lastClaim);
        }
        return delta;
    }

    /**
     * @notice Update funding committee
     * @param _newFundingCommittee The new funding committee address
     */
    function updateFundingCommittee(address _newFundingCommittee) external {
        require(msg.sender == governance, "DolaPayroll::updateFundingCommittee: only governance!");
        require(_newFundingCommittee != address(0), "DolaPayroll::updateFundingCommittee: address 0!");
        require(_newFundingCommittee != address(this), "DolaPayroll::updateFundingCommittee: payroll address");

        address from = fundingCommittee;
        fundingCommittee = _newFundingCommittee;
        emit UpdatedFundingCommittee(from, _newFundingCommittee);
    }

    /**
     * @notice check balance of salary recipient at current block time
     * @param _recipient address of salary recipient
     */
    function balanceOf(address _recipient) external view returns (uint256) {
        uint256 delta = _delta(_recipient);
        if (delta == 0) return 0;

        return _balanceOf(_recipient, delta);
    }

    // avoid recalculating delta
    function _balanceOf(address _recipient, uint256 delta) internal view returns (uint256) {
        Recipient memory recipient = recipients[_recipient];
        return _mul256(recipient.ratePerSecond, delta);
    }

    function _mul256(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }

    function _div256(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "division by 0");
        uint256 c = a / b;
        return c;
    }

    function _add256(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function _sub256(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "subtraction underflow");
        uint256 c = a - b;
        return c;
    }
}