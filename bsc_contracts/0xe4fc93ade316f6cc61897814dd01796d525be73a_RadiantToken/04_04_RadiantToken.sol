// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract RadiantToken is ERC20, Ownable {

    uint256 public constant MAX_TOTAL_SUPPLY = 1_000_000_000 ether;
    address public constant bridgeToken = 0x0C4681e6C0235179ec3D4F4fc4DF3d14FDD96017;
    address public minter = 0xc2054A8C33bfce28De8aF4aF548C48915c455c13;

    modifier onlyMinter {
        require(msg.sender == minter || msg.sender == owner(), "RDNT: only minter");
        _;
    }

    constructor() ERC20("Radiant", "RDNT", 18) {
        // seeding initial liquidity
        _mint(msg.sender, 100_000 ether);
    }

    function mint(address to, uint256 amount) external onlyMinter {
        require(totalSupply + amount <= MAX_TOTAL_SUPPLY, "RDNT: total supply exceeded");
        _mint(to, amount);
    }
}