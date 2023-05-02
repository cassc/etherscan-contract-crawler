// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@solmate/tokens/ERC20.sol";
import "./interfaces/IStake2.sol";
import "@solmate/auth/Owned.sol";

/**
 * @title Zenith Token
 */
contract ZTH is Owned, ERC20("Zenith", "ZTH", 18) {
    uint256 private constant _MAX_SUPPLY = 1_000_000_000 * 1e18; //1b

    mapping(address => bool) public miners;

    constructor(address _owner) Owned(_owner) {
        assert(_owner!=address(0));
    }

    function mint(address to, uint256 amount) external {
        if (!miners[msg.sender]) revert NotMiner();
        if (totalSupply + amount > _MAX_SUPPLY) revert MaxSupplyReached();
        _mint(to, amount);
    }

    function setMiner(address miner, bool isMiner) external onlyOwner {
        miners[miner] = isMiner;
        emit SetMiner(miner, isMiner);
    }

    event SetMiner(address indexed miner, bool isMiner);

    error MaxSupplyReached();
    error NotMiner();
}