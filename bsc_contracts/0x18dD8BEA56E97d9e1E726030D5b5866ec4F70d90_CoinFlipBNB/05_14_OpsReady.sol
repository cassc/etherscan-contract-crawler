// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IOps {
    function gelato() external view returns (address payable);
    function createTaskNoPrepayment(address _execAddress, bytes4 _execSelector, address _resolverAddress, bytes calldata _resolverData, address _feeToken) external returns (bytes32 task);
    function getFeeDetails() external view returns (uint256, address);
    function cancelTask(bytes32 task) external;
}

abstract contract OpsReady {
    address public ops;
    address payable public gelato;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    bool onlyOnce = false;

    modifier onlyOps() {
        require(msg.sender == ops, "OpsReady: onlyOps");
        _;
    }

    function _initialize(address _ops) internal {
        require(!onlyOnce);
        ops = _ops;
        gelato = IOps(_ops).gelato();
        onlyOnce = true;
    }

    function _transfer(uint256 _amount, address _paymentToken) internal {
        if (_paymentToken == ETH) {
            (bool success, ) = gelato.call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), gelato, _amount);
        }
    }
}