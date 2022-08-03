// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OperatorAbility is OwnableUpgradeable {

    event OperatorAddressAdded(address user);
    event OperatorAddressRemoved(address user);

    address[] operatorsAddress;
    mapping(address => uint256) public operatorsMap;

    modifier onlyOperator() {
        require(operatorsMap[msg.sender] > 0, "onlyOperator: caller is not the operator");
        _;
    }

    function getOperatorsAddress()public view returns(address[] memory){
        address[] memory ret = new address[](operatorsAddress.length);
        for (uint8 i = 0; i < operatorsAddress.length; ++i) {
            ret[i] = operatorsAddress[i];
        }
        return ret;
    }

    function removeOperatorFromArray(address forRemove) private returns(bool){

        for (uint8 i = 0; i < operatorsAddress.length - 1; ++i) {
            if (operatorsAddress[i] == forRemove) {
                address swap = operatorsAddress[i];
                operatorsAddress[i] = operatorsAddress[operatorsAddress.length - 1];
                operatorsAddress[operatorsAddress.length - 1] = swap;
                break;
            }
        }

        if(operatorsAddress[operatorsAddress.length - 1] == forRemove){
            operatorsAddress.pop();
            return true;
        }

        return false;

    }

    function addOperatorAddress(address _operatorAddress) public onlyOwner {
        require(_operatorAddress != address(0), "The _operatorAddress is not valid");
        require(operatorsMap[_operatorAddress] == 0, "The _operatorAddress is already exist as an operator");
        operatorsAddress.push(_operatorAddress);
        operatorsMap[_operatorAddress] = 1;
        emit OperatorAddressAdded(_operatorAddress);

    }

    function removeOperatorAddress(address _operatorAddress) public onlyOwner {
        require(_operatorAddress != address(0), "The _operatorAddress is not valid");
        require(operatorsMap[_operatorAddress] > 0, "The _operatorAddress is not exist as an operator");

        require(removeOperatorFromArray(_operatorAddress), "Can not find Operator to remove");
        delete operatorsMap[_operatorAddress];

        emit OperatorAddressRemoved(_operatorAddress);

    }

}