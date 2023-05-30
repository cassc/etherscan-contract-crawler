// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FlappyMoonBird is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 1000000000 * 10**18;

    uint256 public constant PRE_SEED_A_PERCENT = 8;
    address public constant PRE_SEED_A_ADDRESS = 0x304267D632cF226299A4802Efd2321e00FA5E2eB;

    uint256 public constant PRE_SEED_B_PERCENT = 8;
    address public constant PRE_SEED_B_ADDRESS = 0x8211492A888eAEc2AD94e0cf39287E3bec50dE21;

    uint256 public constant COMMUNITY_PERCENT = 41;
    address public constant COMMUNITY_ADDRESS = 0xFD91Bc8E8a06a984fD6a6eEC795b807d622E9d47;

    uint256 public constant DEVELOPMENT_PERCENT = 15;
    address public constant DEVELOPMENT_ADDRESS = 0xb190a8d581Ea91caA1036766225C34ba8e890269;

    uint256 public constant ECOSYSTEM_PERCENT = 16;
    address public constant ECOSYSTEM_ADDRESS = 0x88B3A074a1F666fA5C4926Eb1d79ffcE806195C6;

    uint256 public constant MARKETING_PERCENT = 12;
    address public constant MARKETING_ADDRESS = 0x6aEE3f1d538b99c306b5bA404Fc45B7cB73ff301;


    constructor() ERC20("Flappy Moon Bird", "FMB") {
        _mint(PRE_SEED_A_ADDRESS, TOTAL_SUPPLY * PRE_SEED_A_PERCENT / 100);
        _mint(PRE_SEED_B_ADDRESS, TOTAL_SUPPLY * PRE_SEED_B_PERCENT / 100);
        _mint(COMMUNITY_ADDRESS, TOTAL_SUPPLY * COMMUNITY_PERCENT / 100);
        _mint(DEVELOPMENT_ADDRESS, TOTAL_SUPPLY * DEVELOPMENT_PERCENT / 100);
        _mint(ECOSYSTEM_ADDRESS, TOTAL_SUPPLY * ECOSYSTEM_PERCENT / 100);
        _mint(MARKETING_ADDRESS, TOTAL_SUPPLY * MARKETING_PERCENT / 100);
    }

    
}