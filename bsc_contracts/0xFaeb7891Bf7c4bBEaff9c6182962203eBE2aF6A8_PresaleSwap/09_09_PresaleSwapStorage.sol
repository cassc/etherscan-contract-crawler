// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


contract PresaleSwapStorage {
    /// @dev constants
    string public constant nameStorage = "PresaleStorage V1.2.1";

    /// @dev variables
    uint public rate;
    uint public hardCap;
    uint public startTime;
    uint public endTime;
    uint public minSwap;
    uint public maxSwap;
    bool public swapOn;
    uint public tokenSupply;
    uint public swapTotal;

    /// @dev maps to support the process
    mapping(address => uint) public swaps;
    mapping(address => uint) public claims;

    /// @dev events
    event Swapped(address indexed owner, uint amount);
    event InvestTokensForwarded(uint amount);
    event timeUpdated(uint end);
    event SwapEnabledUpdated(bool flag);
    event hardCapFilled(address indexed _from);

    /// @dev modifiers
    modifier swapEnabled() {
        require(swapOn == true, "Presale: Swapping is disabled");
        _;
    }
    modifier onProgress() {
        require(
            block.timestamp < endTime && block.timestamp >= startTime,
            "Presale: Not in progress"
        );
        _;
    }
}