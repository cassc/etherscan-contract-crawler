// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract TreasuryVester is Initializable {
    address public eul;
    address public recipient;

    uint public vestingAmount;
    uint public vestingBegin;
    uint public vestingCliff;
    uint public vestingEnd;

    uint public lastUpdate;

    /// constructor replacement, executed only once, upon deployment.
    function initialize(
        address eul_,
        address recipient_,
        uint vestingAmount_,
        uint vestingBegin_,
        uint vestingCliff_,
        uint vestingEnd_
    ) public initializer {
        require(eul_ != address(0), 'TreasuryVester::constructor: invalid EUL token contract address');
        require(recipient_ != address(0), 'TreasuryVester::constructor: invalid recipient address');
        require(vestingCliff_ >= vestingBegin_, 'TreasuryVester::constructor: cliff is too early');
        require(vestingEnd_ > vestingCliff_, 'TreasuryVester::constructor: end is too early');

        eul = eul_;
        recipient = recipient_;
        
        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin_;
    }

    /**
     * @notice Sets a recipient address. 
     * Callable by the current recipient only.
     * @param recipient_ The recipient of the vested funds
     */
    function setRecipient(address recipient_) external {
        require(msg.sender == recipient, 'TreasuryVester::setRecipient: unauthorized');
        recipient = recipient_;
    }

    /**
     * @notice Claim an amount of the vested tokens.
     * The claimed amount if any based on the vesting schedule, 
     * will be transferred to the recipient address.
     * If the vesting end timestamp has elapsed, all the vested funds are claimed.
     * Otherwise, the amount to claim, computed based on time delta considering
     * the time difference between current block timestamp and last update
     * divided by the vesting duration (vesting end - vesting begin)
     * Can be called by anyone but funds will only go to the vesting recipient.
     */
    function claim() external {
        require(block.timestamp >= vestingCliff, 'TreasuryVester::claim: not time yet');
        uint amount = getAmountToClaim();
        if (amount > 0) {
            lastUpdate = block.timestamp;
            IERC20Votes(eul).transfer(recipient, amount);
        }
    }

    /**
     * @notice Returns the amount of vested tokens that can be claimed using the claim function.
     * @return amount The amount that can be claimed from the vesting contract
     */
    function getAmountToClaim() public view returns(uint amount) {
        if (block.timestamp < vestingCliff) {
            amount = 0;
        } else if (block.timestamp >= vestingEnd) {
            amount = IERC20Votes(eul).balanceOf(address(this));
        } else {
            amount = vestingAmount * (block.timestamp - lastUpdate) / (vestingEnd - vestingBegin);
        }
    }

    /**
     * @notice Delegates the vested tokens to a delegate address to be used for governance.
     * Only callable by the recipient.
     * @param delegatee_ The address to serve as the delegate
     */
    function delegate(address delegatee_) external {
        require(msg.sender == recipient, 'TreasuryVester::delegate: unauthorized');
        IERC20Votes(eul).delegate(delegatee_);
    }
}

interface IERC20Votes {
    function delegate(address delegatee) external;
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
}