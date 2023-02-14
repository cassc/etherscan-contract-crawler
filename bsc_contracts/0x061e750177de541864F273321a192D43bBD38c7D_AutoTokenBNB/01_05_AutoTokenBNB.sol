// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AutoTokenBNB is ERC20 {
    uint8 private constant VESTING_INDEX = 0;
    uint8 private constant INVALID_INDEX = 1;

    uint256[5] private _pools_amount = [
        150 * 10**(6 + 8)
    ];

    bool[5] public _minted_pool;
    address private _owner;

    constructor(
    ) public ERC20("Auto", "AUT") {

        _setupDecimals(8);
        _owner = msg.sender;

        _minted_pool[VESTING_INDEX] = false;
    }

    function addLocker(uint8 pool_index, address pool_address) external {
        require(msg.sender == _owner);
        require(pool_address != address(0), "AutoToken: ZERO ADDRESS");
        require(pool_index >= VESTING_INDEX);
        require(pool_index <= VESTING_INDEX);
        require(_minted_pool[pool_index] == false);

        _mint(pool_address, _pools_amount[pool_index]);
        _minted_pool[pool_index] = true;
    }
}