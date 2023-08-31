// SPDX-License-Identifier: MIT
// contracts/FUCOIN.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FUCOIN is ERC20 {
    uint256 public immutable MAX_SUPPLY;

    mapping(address => address) public referrer;

    mapping(address => bool) public holders;

    struct Reward {
        uint256 mintAmount;
        uint256 firstAmount;
        uint256 secondAmount;
    }
    Reward[] public rewards;

    event Referrer(address from, address to);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() ERC20("FUCOIN", "FU") {
        MAX_SUPPLY = 99_0000_0000 * 10 ** decimals();

        _mint(_msgSender(), 2_0000_0000 * 10 ** decimals());

        rewards.push(Reward(5_0000_0000 * 10 ** decimals(), 5000 * 10 ** decimals(), 10000 * 10 ** decimals()));
        rewards.push(Reward(6_0000_0000 * 10 ** decimals(), 2000 * 10 ** decimals(), 3000 * 10 ** decimals()));
        rewards.push(Reward(9_0000_0000 * 10 ** decimals(), 1000 * 10 ** decimals(), 2000 * 10 ** decimals()));
        rewards.push(Reward(8_0000_0000 * 10 ** decimals(), 500 * 10 ** decimals(), 1000 * 10 ** decimals()));
        rewards.push(Reward(9_0000_0000 * 10 ** decimals(), 200 * 10 ** decimals(), 300 * 10 ** decimals()));
        rewards.push(Reward(8_0000_0000 * 10 ** decimals(), 100 * 10 ** decimals(), 200 * 10 ** decimals()));
        rewards.push(Reward(9_0000_0000 * 10 ** decimals(), 50 * 10 ** decimals(), 100 * 10 ** decimals()));
        rewards.push(Reward(9_0000_0000 * 10 ** decimals(), 20 * 10 ** decimals(), 30 * 10 ** decimals()));
        rewards.push(Reward(9_0000_0000 * 10 ** decimals(), 10 * 10 ** decimals(), 20 * 10 ** decimals()));
        rewards.push(Reward(9_0000_0000 * 10 ** decimals(), 5 * 10 ** decimals(), 10 * 10 ** decimals()));
        rewards.push(Reward(9_0000_0000 * 10 ** decimals(), 2 * 10 ** decimals(), 3 * 10 ** decimals()));
        rewards.push(Reward(9_0000_0000 * 10 ** decimals(), 1 * 10 ** decimals(), 2 * 10 ** decimals()));
    }

    function _afterTokenTransfer(address from, address to, uint256) internal override {
        if (from != address(0)) {
            _reward(from, to);
        }

        holders[to] = true;
    }

    function _reward(address from, address to) internal {
        if (holders[to]) {
            return;
        }

        (uint256 firstAmount, uint256 secondAmount) = getReward();
        if (firstAmount > 0) {
            _mint(from, firstAmount);
        }

        if (secondAmount > 0 && referrer[from] != address(0)) {
            _mint(referrer[from], secondAmount);
        }

        referrer[to] = from;
        emit Referrer(from, to);
    }

    function getReward() public view returns (uint256 firstAmount, uint256 secondAmount) {
        uint256 mintAmount = 0;
        for (uint i = 0; i < rewards.length; i++) {
            mintAmount += rewards[i].mintAmount;
            if (totalSupply() < mintAmount) {
                firstAmount = rewards[i].firstAmount;
                secondAmount = rewards[i].secondAmount;
                break;
            }
        }
    }

    function _mint(address account, uint256 amount) internal override {
        if (totalSupply() + amount > MAX_SUPPLY) {
            return;
        }

        super._mint(account, amount);
    }
}