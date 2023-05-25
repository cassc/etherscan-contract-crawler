// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Admins.sol";

contract Withdraw is Admins {
    using SafeMath for uint256;

    /**
    @notice Struct containing the association between the wallet and its share
    @dev The share can be /100 or /1000 or something else like /50
    */
    struct Part {
        address wallet;
        uint256 salePart;
    }

    /**
    @notice Stock the parts of each wallets
    */
    Part[] public parts;

    /**
    @dev Calculation of the divider for the calculation of each part
    */
    uint256 public saleDivider;

    /**
    @notice Add a new wallet in the withdraw process
    @dev this method is only internal, it's not possible to add someone after the contract minting
    */
    function withdrawAdd(Part memory _part) internal {
        parts.push(_part);
        saleDivider += _part.salePart;
    }

    /**
    @notice Run the transfer of all ETH to the wallets with each % part
    */
    function withdrawSales() public onlyOwnerOrAdmins {

        uint256 balance = address(this).balance;
        require(balance > 0, "Sales Balance = 0");

        for (uint8 i = 0; i < parts.length; i++) {
            if (parts[i].salePart > 0) {
                _withdraw(parts[i].wallet, balance.mul(parts[i].salePart).div(saleDivider));
            }
        }

        _withdraw(owner(), address(this).balance);
    }

    /**
    @notice Do a transfer ETH to _address
    */
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}