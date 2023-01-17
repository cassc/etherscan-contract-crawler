// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../secutiry/Administered.sol";

contract Sales is Administered {
    /// @dev struct sale
    struct Sale {
        string code;
        address user;
        uint256 amount;
        uint256 timestamp;
    }

    /// @dev list sale
    mapping(uint256 => Sale) public listSales;
    uint256 public countSales = 0;

    /// @dev add sale
    function addSale(
        string memory _code,
        address _user,
        uint256 _amount
    ) external onlyUser {
        _addSale(_code, _user, _amount);
    }

    /// @dev add internal sale
    function _addSale(
        string memory _code,
        address _user,
        uint256 _amount
    ) internal {
        listSales[countSales] = Sale(_code, _user, _amount, block.timestamp);
        countSales++;
    }

    /// @dev get sale
    function getSale(uint256 _countSales) public view returns (Sale memory) {
        return listSales[_countSales];
    }
}