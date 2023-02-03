// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FeesSplitter is Ownable {
    using SafeERC20 for IERC20;

    event ETHReceived(address from, uint256 amount);

    uint256 public constant PERCENTAGE_SCALE = 1e6;
    address[] public accounts;
    uint32[] public percentAllocations;

    constructor(address[] memory _accounts, uint32[] memory _percentAllocations)
    {
        accounts = _accounts;
        percentAllocations = _percentAllocations;
        checkPercentages(_percentAllocations);
    }

    receive() external payable virtual {
        emit ETHReceived(_msgSender(), msg.value);
    }

    function distributeETH() public {
        uint256 amountToSplit = address(this).balance;

        // distribute remaining balance
        // overflow should be impossible in for-loop index
        // cache accounts length to save gas
        uint256 accountsLength = accounts.length;
        for (uint256 i = 0; i < accountsLength; ++i) {
            // overflow should be impossible with validated allocations
            uint256 amt = _scaleAmountByPercentage(
                amountToSplit,
                percentAllocations[i]
            );

            (bool success, ) = accounts[i].call{value: amt}("");
            require(success, "unable to send eth, recipient may have reverted");
        }
    }

    function distributeERC20(IERC20 token) public {
        uint256 amountToSplit = token.balanceOf(address(this));
        uint256 accountsLength = accounts.length;
        for (uint256 i = 0; i < accountsLength; ++i) {
            // overflow should be impossible with validated allocations
            uint256 amt = _scaleAmountByPercentage(
                amountToSplit,
                percentAllocations[i]
            );

            token.transfer(accounts[i], amt);
        }
    }

    function updateSplit(
        address[] memory _accounts,
        uint32[] memory _percentAllocations
    ) external onlyOwner {
        accounts = _accounts;
        percentAllocations = _percentAllocations;
        checkPercentages(_percentAllocations);
    }

    function checkPercentages(uint32[] memory _percentAllocations)
        public
        view
        onlyOwner
    {
        uint32 sum = 0;
        for (uint256 i = 0; i < _percentAllocations.length; i++) {
            sum += _percentAllocations[i];
        }
        require(sum == PERCENTAGE_SCALE, "invalid percentages");
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawERC20(IERC20 token) external onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    function _scaleAmountByPercentage(uint256 amount, uint256 scaledPercent)
        internal
        pure
        returns (uint256 scaledAmount)
    {
        // use assembly to bypass checking for overflow & division by 0
        // scaledPercent has been validated to be < PERCENTAGE_SCALE)
        // & PERCENTAGE_SCALE will never be 0
        // pernicious ERC20s may cause overflow, but results do not affect ETH & other ERC20 balances
        assembly {
            /* eg (100 * 2*1e4) / (1e6) */
            scaledAmount := div(mul(amount, scaledPercent), PERCENTAGE_SCALE)
        }
    }
}