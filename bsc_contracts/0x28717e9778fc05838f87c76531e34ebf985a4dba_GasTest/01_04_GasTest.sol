// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../contracts-generated/Versioned.sol";


contract GasTest is Initializable, 
                    Versioned 
{
    uint256[1000] private _gap_;

    event ReadStorage(uint256 total);
    event Add(uint256 total);

    mapping(uint256 => uint256) private _slots;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() 
        initializer 
        public 
    {
    }

    function writeStorage(uint256[] calldata keys, uint256[] calldata values) 
        public 
    {
        require(keys.length == values.length, "keys/values mismatch");
        for (uint256 index = 0; index < keys.length; index++) {
            _slots[keys[index]] = values[index];
        }
    }

    function readStorage(uint256[] calldata keys) 
        public
    {
        uint256 total = 0;
        for (uint256 index = 0; index < keys.length; index++) {
            total += _slots[keys[index]];
        }
        emit ReadStorage(total);
    }

    function add(uint256[] calldata values)
        public
    {
        uint256 total = 0;
        for (uint256 index = 0; index < values.length; index++) {
            total += values[index];
        }
        emit Add(total);
    }
}