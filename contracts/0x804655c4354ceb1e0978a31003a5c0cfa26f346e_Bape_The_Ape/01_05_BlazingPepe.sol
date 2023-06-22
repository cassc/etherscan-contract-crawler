// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Bape_The_Ape is ERC20 {
     address private owner;
    uint8 private constant DECIMALS = 18; // Set the number of decimals for the token
    uint256 private constant TOTAL_SUPPLY = 420000000000 * 10**uint256(DECIMALS);

     uint256 private constant BURN_PERCENTAGE = 5;
    uint256 private constant OWNER_PERCENTAGE = 5;

    uint256 public constant FEE_PERCENTAGE = 10;

    bool public feeEnabled = true;

    event TransferWithFee(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 fee
    );

    constructor() ERC20("BlazingPepe", "PepeX10") {
        owner = msg.sender;
        _mint(owner, TOTAL_SUPPLY);
    }

      function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if (feeEnabled) {
            uint256 fee = amount * FEE_PERCENTAGE / 100;
            uint256 burnAmount = fee * BURN_PERCENTAGE / FEE_PERCENTAGE;
            uint256 ownerAmount = fee - burnAmount;

            _burn(msg.sender, burnAmount);
            _transfer(msg.sender, owner, ownerAmount);
            _transfer(msg.sender, recipient, amount - fee);

            emit TransferWithFee(msg.sender, recipient, amount, fee);
        } else {
            _transfer(msg.sender, recipient, amount);
        }

        return true;
    }

    function disableFee() external onlyOwner {
        feeEnabled = false;
    }

    function enableFee() external onlyOwner {
        feeEnabled = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
}