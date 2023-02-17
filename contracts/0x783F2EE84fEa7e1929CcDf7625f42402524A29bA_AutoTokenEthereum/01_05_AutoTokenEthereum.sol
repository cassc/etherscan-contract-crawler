// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AutoTokenEthereum is ERC20 {
    uint8 private constant VESTING_INDEX = 0;
    uint8 private constant INVALID_INDEX = 1;

    // 1500 M total supply
    uint256[5] private _pools_amount = [
        50 * 10**(6 + 8) // COMMUNITY_LOCKER1_SUPPLY, 50M
    ];

    bool[5] public _minted_pool;
    address private _owner;

    constructor(
    ) public ERC20("Auto", "AUT") {

        _setupDecimals(8);
        _owner = msg.sender;
        _mint(msg.sender, 150 * 10**(6 + 8));

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