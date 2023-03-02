// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

}


contract QuacksTransfer is Ownable {
    IERC20 public quacks;
    address public feeReceiver;
    uint256 public feePercentage;

    constructor(address quackAddress, address feeReceiver_, uint256 feePercentage_) {
        quacks = IERC20(quackAddress);
        feeReceiver = feeReceiver_;
        feePercentage = feePercentage_;
    }

    function transfer(address to, uint256 amount) public {
        uint256 chargedFee = amount * feePercentage / 100;
        if(chargedFee == 0) {
            chargedFee = 1;
        }
        bool success = quacks.transferFrom(_msgSender(), to, amount - chargedFee);
        require(success);
        success = quacks.transferFrom(_msgSender(), feeReceiver, chargedFee);
        require(success);
    }

    function setFeeReceiver(address feeReceiver_) public onlyOwner {
        feeReceiver = feeReceiver_;
    }

    function setFeePercentage(uint256 feePercentage_) public onlyOwner {
        feePercentage = feePercentage_;
    }
}