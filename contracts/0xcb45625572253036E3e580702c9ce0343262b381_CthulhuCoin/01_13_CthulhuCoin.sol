// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract CthulhuCoin is ERC20Permit, Ownable {
    uint256 public constant MAX_SUPPLY =        1_000_000_000_000 ether;
    uint256 public constant V_GIFT_SUPPLY =       150_000_000_000 ether;
    uint256 public constant STAKING_POOL_SUPPLY = 150_000_000_000 ether;
    uint256 public constant LP_POOL_SUPPLY =      150_000_000_000 ether;
    uint256 public constant CONTRIBUTOR_REWARD =   50_000_000_000 ether;
    uint256 public constant HOLDER_SUPPLY =       500_000_000_000 ether;

    address public constant V_ADDRESS = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
    address public constant STAKING_VAULT_ADDRESS = 0xC0e9F3D72A68594F3D90637F9FdbcfB93973892a;
    address public constant LP_VAULT_ADDRESS = 0x6eF59CD30D9036340384F3a3C73d0f2813B77472;
    address public constant CONTRIBUTOR_VAULT_ADDRESS = 0x6c1F6399AC49A85ec70982C83447B9C9C35Eb255;

    uint256 public _holderClaimed;
    address public _claimer;

    constructor() ERC20("CthulhuCoin", "CTH") ERC20Permit("CthulhuCoin") {
        require(
            MAX_SUPPLY == LP_POOL_SUPPLY + STAKING_POOL_SUPPLY + V_GIFT_SUPPLY + CONTRIBUTOR_REWARD + HOLDER_SUPPLY
        );

        _mint(V_ADDRESS, V_GIFT_SUPPLY);
        _mint(STAKING_VAULT_ADDRESS, STAKING_POOL_SUPPLY);
        _mint(LP_VAULT_ADDRESS, LP_POOL_SUPPLY);
        _mint(CONTRIBUTOR_VAULT_ADDRESS, CONTRIBUTOR_REWARD);
    }

    function holderClaim(address holder, uint256 amount) external {
        require(_claimer == msg.sender, "CthulhuCoin: Not Claimer");
        require(_holderClaimed + amount <= HOLDER_SUPPLY, "CthulhuCoin: Exceed supply");
        _holderClaimed += amount;
        _mint(holder, amount);
    }

    function sweepRestHolderShares() external onlyOwner {
        uint256 rest = HOLDER_SUPPLY - _holderClaimed;
        if (rest > 0) {
            _mint(msg.sender, rest);
            _holderClaimed += rest;
        }
    }

    function setClaimer(address claimer) external onlyOwner {
        _claimer = claimer;
    }
}