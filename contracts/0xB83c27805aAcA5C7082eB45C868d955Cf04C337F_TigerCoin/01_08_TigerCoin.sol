// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TigerCoin is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 100_000_000_000_000 ether;
    uint256 public constant TEAM_SUPPLY = 10_000_000_000_000 ether;
    uint256 public constant TIGER_DAO_SUPPLY = 35_000_000_000_000 ether;
    uint256 public constant HOLDER_SUPPLY = 55_000_000_000_000 ether;

    address public constant TEAM_ADDRESS = 0x0e1cE03d1fD3E1619D6faEa03333B54A300c1199;
    address public constant TIGER_DAO_ADDRESS = 0xd35D8552BdE94Dd520565bdE50964F6aD1155Ccd;

    uint256 public _holderClaimed;
    address public _claimer; 

    constructor() ERC20("TigerCoin", "TIGER") {
        require(MAX_SUPPLY == TEAM_SUPPLY + TIGER_DAO_SUPPLY + HOLDER_SUPPLY);

        _mint(TEAM_ADDRESS, TEAM_SUPPLY);
        _mint(TIGER_DAO_ADDRESS, TIGER_DAO_SUPPLY);
    }

    function holderClaim(address holder, uint256 amount) external {
        require(_claimer == msg.sender, "TigerCoin: Not Claimer");
        require(_holderClaimed + amount <= HOLDER_SUPPLY, "TigerCoin: Exceed supply");
        _holderClaimed += amount;
        _mint(holder, amount);
    }

    function sweepRestHolderShares() external onlyOwner {
        uint256 rest = HOLDER_SUPPLY - _holderClaimed;
        if (rest > 0) {
            _mint(TEAM_ADDRESS, rest);
        }
    }

    function setClaimer(address claimer) external onlyOwner {
        _claimer = claimer;
    }
}