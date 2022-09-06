// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./NFTingErrors.sol";

abstract contract PreAuthorization is Ownable {
    mapping(address => bool) private isAuthorizedAddress;
    address[] private authorizedAddresses;
    mapping(address => uint256) private addressToIndex;

    event OperatorAuthorized(address _operator);
    event OperaturUnauthorized(address _operator);

    function _isAuthorizedOperator(address _operator)
        internal
        view
        returns (bool)
    {
        return isAuthorizedAddress[_operator];
    }

    function authorizeOperator(address _operator) public onlyOwner {
        isAuthorizedAddress[_operator] = true;
        addressToIndex[_operator] = authorizedAddresses.length;
        authorizedAddresses.push(_operator);

        emit OperatorAuthorized(_operator);
    }

    function unauthorizeOperator(address _operator) public onlyOwner {
        if (authorizedAddresses.length == 0) {
            revert NoAuthorizedOperator();
        } else if (authorizedAddresses.length > 1) {
            uint256 index = addressToIndex[_operator];
            address lastOperator = authorizedAddresses[
                authorizedAddresses.length - 1
            ];
            authorizedAddresses[index] = lastOperator;
            addressToIndex[lastOperator] = index;
        }

        delete addressToIndex[_operator];
        delete isAuthorizedAddress[_operator];
        authorizedAddresses.pop();

        emit OperaturUnauthorized(_operator);
    }

    function getAllAuthorizedAddresses()
        public
        view
        returns (address[] memory)
    {
        return authorizedAddresses;
    }
}