pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title MAΞTHSTRO Ethereum Radio Tip Contract
/// @author MAΞTHSTRO
/// @notice Handles tips and donations for the MAΞTHSTRO Ethereum Radio.
/// 	To support the project, any Ethereum address can:
/// 		1. send ETH or ERC20 to the contract address (donation)
/// 		2. send at least 0.1 eth and send a message to the Radio (tip)
contract MaethstroEthRadioTip {
    /// Address of the MAΞTHSTRO team
    address payable internal owner;

    /// Current number of tips
    uint256 number = 0;

    /// @notice Event emitted when someone does a tip
    /// @dev tip content is only stored in the event data, not in contract state
    event Tip(
        uint256 indexed _number,
        address _from,
        string _message,
        uint256 _value
    );

    constructor(address payable _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can perform this action");
        _;
    }

    /// @notice Donate eth and send a message to the MAΞTHSTRO Ethereum Radio
    /// @param _message message to display on the radio (only 64 first characters are printed)
    /// @dev tip and message are processed off-chain, minimum tip is defined on the radio
    function tip(string  calldata _message)
        external
        payable
    {
        emit Tip(++number, msg.sender,  _message, msg.value);
    }

    /// @notice Owner withdraws all tokens of an ERC20 on the contract
    /// @param _erc20 address of the ERC20 to withdraw
    function withdraw(address _erc20) external onlyOwner {
        ERC20 token = ERC20(_erc20);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    /// @notice Owner withdraws all ETH on the contract
    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}