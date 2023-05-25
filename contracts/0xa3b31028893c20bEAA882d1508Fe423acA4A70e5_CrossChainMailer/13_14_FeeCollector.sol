pragma solidity ^0.8.16;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract FeeCollector is Ownable {
    error InsufficientFee(uint256 actual, uint256 expected);

    /// @notice The fee to pay for sending a message.
    /// @dev The intention is only set to non-zero when deployed non-mainnet chains, used to discourage spam.
    uint256 public fee;

    /// @notice Allows owner to set a new fee.
    /// @param _fee The new fee to use.
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /// @notice Allows owner to claim all fees sent to this contract.
    function claimFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}