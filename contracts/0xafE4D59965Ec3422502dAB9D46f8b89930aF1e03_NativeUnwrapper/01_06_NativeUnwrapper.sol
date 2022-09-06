// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IWETH9.sol";
import "../components/SafeOwnable.sol";

/**
 * @dev NativeUnwrapper unwraps WETH and send ETH back to a Trader.
 *
 *      LiquidityPool is upgradable. WBNB can not send to an upgradable contract. So we unwrap
 *      native asset into NativeUnwrapper first.
 */
contract NativeUnwrapper is SafeOwnable {
    IWETH public immutable weth;
    mapping(address => bool) public whitelist; // contract in this whitelist can send ETH to any Trader

    event Granted(address indexed core);
    event Revoked(address indexed core);

    constructor(address weth_) SafeOwnable() {
        weth = IWETH(weth_);
    }

    receive() external payable {}

    function addWhiteList(address core) external onlyOwner {
        require(!whitelist[core], "CHG"); // not CHanGed
        whitelist[core] = true;
        emit Granted(core);
    }

    function removeWhiteList(address core) external onlyOwner {
        require(whitelist[core], "CHG"); // not CHanGed
        whitelist[core] = false;
        emit Revoked(core);
    }

    function unwrap(address payable to, uint256 rawAmount) external {
        require(whitelist[msg.sender], "SND"); // SeNDer is not authorized
        weth.withdraw(rawAmount);
        Address.sendValue(to, rawAmount);
    }
}