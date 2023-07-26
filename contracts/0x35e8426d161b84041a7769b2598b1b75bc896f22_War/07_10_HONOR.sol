// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "ERC20.sol";
import "Ownable.sol";

contract HONOR is ERC20, Ownable {
    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) public controllers;

    // Staking supply
    uint256 public constant MAXIMUM_STAKING_SUPPLY = 184120000 ether;

    // Community fund supply
    uint256 public constant MAXIMUM_COMMUNITY_FUND_SUPPLY = 100000000 ether;

    // Public sale supply
    uint256 public constant MAXIMUM_PUBLIC_SALES_SUPPLY = 30000000 ether;

    // Team reserve supply
    uint256 public constant MAXIMUM_TEAM_RESERVE_SUPPLY = 60500000 ether;

    // Minted amount
    uint256 public totalStakingSupply;
    uint256 public totalCommunityFundSupply;
    uint256 public totalPublicSalesSupply;
    uint256 public totalTeamReserveSupply;

    constructor() ERC20("HONOR", "HON") {}

    /**
     * mints $HONOR from staking supply to a recipient
     * @param to the recipient of the $HONOR
     * @param amount the amount of $HONOR to mint
     */
    function stakingMint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        require(
            totalStakingSupply + amount <= MAXIMUM_STAKING_SUPPLY,
            "Maximum staking supply exceeded"
        );
        _mint(to, amount);
        totalStakingSupply += amount;
    }

    /**
     * mints $HONOR from community fund supply to a recipient
     * @param to the recipient of the $HONOR
     * @param amount the amount of $HONOR to mint
     */
    function communityFundMint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        require(
            totalCommunityFundSupply + amount <= MAXIMUM_COMMUNITY_FUND_SUPPLY,
            "Maximum community fund supply exceeded"
        );
        _mint(to, amount);
        totalCommunityFundSupply += amount;
    }

    /**
     * mints $HONOR from public sales supply to a recipient
     * @param to the recipient of the $HONOR
     * @param amount the amount of $HONOR to mint
     */
    function publicSalesMint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        require(
            totalPublicSalesSupply + amount <= MAXIMUM_PUBLIC_SALES_SUPPLY,
            "Maximum public sales supply exceeded"
        );
        _mint(to, amount);
        totalPublicSalesSupply += amount;
    }

    /**
     * mints $HONOR from team reserve supply to a recipient
     * @param to the recipient of the $HONOR
     * @param amount the amount of $HONOR to mint
     */
    function teamReserveMint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        require(
            totalTeamReserveSupply + amount <= MAXIMUM_TEAM_RESERVE_SUPPLY,
            "Maximum team reserve supply exceeded"
        );
        _mint(to, amount);
        totalTeamReserveSupply += amount;
    }

    /**
     * burns $HONOR from a holder
     * @param from the holder of the $HONOR
     * @param amount the amount of $HONOR to burn
     */
    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }

    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disable
     */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}