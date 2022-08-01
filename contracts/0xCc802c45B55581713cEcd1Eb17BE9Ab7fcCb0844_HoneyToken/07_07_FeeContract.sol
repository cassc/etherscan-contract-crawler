// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract FeeContract {
    uint256 private taxBase = 10e18;

    struct taxValues {
        address target;
        uint256 share;
    }

    taxValues[] _list; 

    constructor(
        address[] memory _addresses, // honeyToLpControl, QueenTax
        uint256[] memory _weights, // 80% al lp y 20% al queentax
        uint256 _taxBase // sumatoria de los pesos
    ) {
        require(_addresses.length == _weights.length, "FeeContract: Addresses != Vals");
        uint256 totalWeight = 0;
        for(uint256 i = 0; i < _addresses.length; i++){
            _list.push(taxValues(_addresses[i], _weights[i]));
            totalWeight += _weights[i];
        }
        require(totalWeight == _taxBase, "totalWeight != weight");
        taxBase = _taxBase;
    }

    function list() public view returns (taxValues[] memory){
        return _list;
    }

    function taxedAmount (uint256 _value) public view returns (uint256) {
        return _value * (100e18 - taxBase)/100e18;
    }

    function taxFor(uint256 _index, uint256 _taxAmount) public view returns(uint256){
        return _taxAmount * _list[_index].share / taxBase;
    }
}