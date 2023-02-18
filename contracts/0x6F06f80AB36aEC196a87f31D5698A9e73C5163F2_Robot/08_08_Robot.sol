// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IRobot.sol";
import "../../lib/openzeppelin-contracts/contracts//token/ERC20/extensions/ERC20Burnable.sol";
import "../../lib/openzeppelin-contracts/contracts//access/Ownable.sol";

contract Robot is IRobot, ERC20Burnable, Ownable {
    address public robotTxt;

    modifier onlyRobotTxt() {
        if (msg.sender != robotTxt) revert NotRobotTxt();
        _;
    }

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(address to) external onlyRobotTxt {
        super._mint(to, 1);
    }

    function burn(address from) external override onlyRobotTxt {
        super._burn(from, 1);
    }

    function setRobotTxt(address newRobotTxt) external onlyOwner {
        if (newRobotTxt == address(0)) revert ZeroAddress();
        if (newRobotTxt == robotTxt) revert SameAddress();
        robotTxt = newRobotTxt;
        emit RobotTxtUpdated(newRobotTxt);
    }

    // /// Disable transfers
    function transfer(address to, uint256 amount) public override returns (bool) {
        revert NotTransferable();
    }

    function transferFrom(address, address, uint256) public override returns (bool) {
        revert NotTransferable();
    }
}