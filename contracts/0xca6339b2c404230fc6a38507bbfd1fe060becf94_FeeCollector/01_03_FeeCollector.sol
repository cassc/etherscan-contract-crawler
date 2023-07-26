// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeCollector is Ownable {
    // Variables
    uint public ownerFees;
    mapping(address => uint) public totalFees;
    mapping(address => uint) public totalClaimed;

    // Errors
    error CollectFail();
    error TransferFail();
    error ZeroTransfer();

    // Events
    event Collect(address user, uint amount);
    event Claim(address user, uint amount);

    /**
        @notice Collect protocol fees specifying referral address
        @param referrer the referrer address
        @param referrerAmount the amount that goes to referrer
        @return status
     */
    function collectWithReferral(
        address referrer,
        uint referrerAmount
    ) external payable returns (bool) {
        if (msg.value < referrerAmount) revert CollectFail();
        totalFees[referrer] = totalFees[referrer] + referrerAmount;
        emit Collect(referrer, referrerAmount);
        ownerFees = ownerFees + msg.value - referrerAmount;
        emit Collect(owner(), msg.value - referrerAmount);
        return true;
    }

    /**
        @notice Collect protocol fees
        @return status
   */
    function collect() public payable returns (bool) {
        ownerFees = ownerFees + msg.value;
        emit Collect(owner(), msg.value);
        return true;
    }

    /**
        @notice Claim fees for msg.sender
   */
    function claim() public {
        claim(msg.sender);
    }

    /**
        @notice Claim fees for the specified user
        @param user the user address
   */
    function claim(address user) public {
        uint trfAmt;
        if (user == owner()) {
            trfAmt = ownerFees - 1;
            /// @dev it is cheaper to not zero balance
            ownerFees = 1;
        } else {
            trfAmt = totalFees[user] - totalClaimed[user];
            totalClaimed[user] = totalClaimed[user] + trfAmt;
        }
        _transfer(user, trfAmt);
        emit Claim(user, trfAmt);
    }

    /**
        @notice Internal function to transfer fees
        @param user the user address
        @param amt the amount of fees to transfer
   */
    function _transfer(address user, uint amt) internal {
        if (amt == 0) revert ZeroTransfer();
        (bool success, ) = payable(user).call{value: amt}("");
        if (!success) revert TransferFail();
    }

    /**
        @notice Transfer ownership of the contract
        @param newOwner the new owner address
   */
    function transferOwnership(address newOwner) public override onlyOwner {
        /// @dev only owner can transferOwnership so claim will claim owner's funds
        claim();
        _transferOwnership(newOwner);
    }

    // Fallback function
    fallback() external payable {
        collect();
    }

    // Receive function
    receive() external payable {
        collect();
    }
}