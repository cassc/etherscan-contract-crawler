// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./ERC1155Customizable.sol";

abstract contract Withdrawable is ERC1155Customizable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint16 totalWeight = 10000;

    struct Payee {
        address destination; // address funds are going to
        uint16 weight; // weight of payment
    }

    // Array containing payments to be made on withdrawal
    Payee[] payees;

    // By default we have the sender as the main payee
    constructor() {
        payees.push(Payee({destination: msg.sender, weight: totalWeight}));
    }

    function getPayees()
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        )
    {
        address[] memory payeeList = new address[](payees.length);
        uint256[] memory weights = new uint256[](payees.length);

        for (uint256 i = 0; i < payees.length; i++) {
            payeeList[i] = payees[i].destination;
            weights[i] = payees[i].weight;
        }

        return (payeeList, weights, totalWeight);
    }

    function resetPayees(Payee[] calldata _newPayeeData) external onlyAdmin {
        delete payees;
        totalWeight = 0;
        for (uint256 i = 0; i < _newPayeeData.length; i++) {
            payees.push(_newPayeeData[i]);
            totalWeight += payees[i].weight;
        }
    }

    function withdraw(address _paymentToken) external onlyAdmin {
        uint256 balance = address(this).balance;

        if (_paymentToken != address(0)) {
            balance = IERC20(_paymentToken).balanceOf(address(this));
        }

        for (uint256 j = 0; j < payees.length; j++) {
            uint256 weight = (balance * payees[j].weight).div(totalWeight);
            if (_paymentToken == address(0)) {
                (bool success, ) = payable(payees[j].destination).call{
                    value: weight
                }("");
                require(success, "Payment failure");
            } else {
                IERC20(_paymentToken).safeTransfer(
                    payees[j].destination,
                    weight
                );
            }
        }
    }
}