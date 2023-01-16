// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Forwarder {
    using Address for address payable;
    using SafeERC20 for IERC20;

    address public sink;

    receive() external payable {
        payable(sink).sendValue(msg.value);
    }

    function init(address _sink) external {
        sink = _sink;
    }

    function updateSink(address _sink) external {
        require(msg.sender == sink, "Caller is not the sink");
        sink = _sink;
    }

    function flush(address erc20TokenContract) external {
        if (erc20TokenContract == address(0)) {
            flushNative();
        } else {
            flushERC20(erc20TokenContract);
        }
    }

    function flushNative() public {
        uint256 forwarderBalance = address(this).balance;
        require(forwarderBalance > 0, "Forwarder is empty");

        payable(sink).sendValue(forwarderBalance);
    }

    function flushERC20(address erc20TokenContract) public {
        IERC20 erc20 = IERC20(erc20TokenContract);
        uint256 forwarderBalance = erc20.balanceOf(address(this));
        require(forwarderBalance > 0, "Forwarder is empty");

        erc20.safeTransfer(sink, forwarderBalance);
    }
}