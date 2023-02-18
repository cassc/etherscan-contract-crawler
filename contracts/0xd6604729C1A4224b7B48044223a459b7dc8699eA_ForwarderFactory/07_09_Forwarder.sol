// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Errors.sol";
import "./ForwarderFactory.sol";

contract Forwarder {
    using Address for address payable;
    using SafeERC20 for IERC20;

    address public forwarderFactory;

    modifier onlyFactory() {
        if (msg.sender != forwarderFactory) {
            revert Unauthorised();
        }

        _;
    }

    receive() external payable {
        payable(ForwarderFactory(forwarderFactory).sink()).sendValue(msg.value);
    }

    function init(address _forwarderFactory) external {
        if (forwarderFactory != address(0)) {
            revert AlreadyIntialised();
        }

        forwarderFactory = _forwarderFactory;
    }

    function _flushNative(address sink) internal {
        uint256 forwarderBalance = address(this).balance;
        if (forwarderBalance == 0) {
            revert ForwarderNativeZeroBalance();
        }

        payable(sink).sendValue(forwarderBalance);
    }

    function _flushERC20(address sink, address erc20TokenContract) internal {
        IERC20 erc20 = IERC20(erc20TokenContract);
        uint256 forwarderBalance = erc20.balanceOf(address(this));
        if (forwarderBalance == 0) {
            revert ForwarderERC20ZeroBalance(erc20TokenContract);
        }

        erc20.safeTransfer(sink, forwarderBalance);
    }

    function flush(address sink, address erc20TokenContract) external onlyFactory {
        if (erc20TokenContract == address(0)) {
            _flushNative(sink);
        } else {
            _flushERC20(sink, erc20TokenContract);
        }
    }
}