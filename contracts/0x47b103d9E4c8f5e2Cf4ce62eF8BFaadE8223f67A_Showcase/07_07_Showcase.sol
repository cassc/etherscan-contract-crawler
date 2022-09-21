// SPDX-License-Identifier: MIT
/*
_____   ______________________   ____________________________   __
___  | / /__  ____/_  __ \__  | / /__  __ \__    |___  _/__  | / /
__   |/ /__  __/  _  / / /_   |/ /__  /_/ /_  /| |__  / __   |/ / 
_  /|  / _  /___  / /_/ /_  /|  / _  _, _/_  ___ |_/ /  _  /|  /  
/_/ |_/  /_____/  \____/ /_/ |_/  /_/ |_| /_/  |_/___/  /_/ |_/  
 ___________________________________________________________ 
  S Y N C R O N A U T S: The Bravest Souls in the Metaverse

*/

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Showcase is Ownable {
    using SafeERC20 for IERC20;

    /// @notice Address that receives the funds for the showcase slots
    address public treasuryAddress;
    /// @notice Cost of purchasing a slot in ETH
    uint256 public pricePerSlot;
    /// @notice Keeps track of the number of slots that a user has paid for
    mapping(address => uint256) public numSlotsPaid;

    constructor(address _treasuryAddress) {
        treasuryAddress = _treasuryAddress;
        pricePerSlot = 10**15; //0.001ETH
    }

    /// @notice User calls this function to pay for a number of showcase slots
    /// @param _newSlots The number of slots that the user wants to purchase
    function payForSlots(uint256 _newSlots) external payable {
        require(
            msg.value == pricePerSlot * _newSlots,
            "Incorrect Payment Amount"
        );

        (bool sent, ) = payable(treasuryAddress).call{value: msg.value}("");

        require(sent, "Failed to send Ether");

        numSlotsPaid[msg.sender] = numSlotsPaid[msg.sender] + _newSlots;
    }

    /// @notice Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Fallback function is called when msg.data is not empty
    fallback() external payable {}

    /// @notice Sets the address to receive funds for the showcase slots
    /// @param _newTreasuryAddress New address to receive funds
    function setTreasuryAddress(address _newTreasuryAddress) public onlyOwner {
        treasuryAddress = _newTreasuryAddress;
    }

    /// @notice Sets cost of purchasing a slot in ETH
    /// @param _newPricePerSlot New address to receive funds
    function setPricePerSlot(uint256 _newPricePerSlot) public onlyOwner {
        pricePerSlot = _newPricePerSlot;
    }
}