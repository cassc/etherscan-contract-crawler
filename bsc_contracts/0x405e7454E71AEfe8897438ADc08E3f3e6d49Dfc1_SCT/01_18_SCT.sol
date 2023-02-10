// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract SCT is ERC20Votes, Ownable {

    address constant public teamAddress = 0x5b65072c237eAcf464C55c37353Fdd5BFc265780;
    address constant public stakingAddress = 0xa883d6C55fc19a317499e36E6DFAb69BA3Ef728d;
    address constant public foundationAddress1 = 0xf8145A718056c21F1fbD595495Fb9Eeb5193C5f1;
    address constant public foundationAddress2 = 0x2731Eaf090b955E3f64B9e3547bB817482f65a52;
    address constant public marketAddress = 0xB39F929bf20cD7D5B273f824045e17e1C608beCC;
    address constant public sponsorAddress = 0x6C8A740CA525116c930B8Fe0f16CDc127C6FB108;
    address constant public userAddress = 0xea6b4801ced150F82a61A9b2FA9BA62c45286275;

    uint256 constant public teamAmount = 750_000_000 * 10**18;
    uint256 constant public stakingAmount = 250_000_000 * 10**18;
    uint256 constant public foundationAmount1 = 1_000_000_000 * 10**18;
    uint256 constant public foundationAmount2 = 1500_000_000 * 10**18;
    uint256 constant public marketAmount = 500_000_000 * 10**18;
    uint256 constant public sponsorAmount = 500_000_000 * 10**18;
    uint256 constant public userAmount = 500_000_000 * 10**18;
    uint256 constant public perMintAmount = 10_000_000 * 10**18;
    uint256 constant public ONE_DAY = 24 hours;

    uint256 public LAST_MINT_TIME;
    address public nucleusAddress;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) ERC20Permit(name) {
        _mint(teamAddress, teamAmount);
        _mint(stakingAddress, stakingAmount);
        _mint(foundationAddress1, foundationAmount1);
        _mint(foundationAddress2, foundationAmount2);
        _mint(marketAddress, marketAmount);
        _mint(sponsorAddress, sponsorAmount);
        _mint(userAddress, userAmount);
        LAST_MINT_TIME = block.timestamp + 180 * ONE_DAY;
    }

    function updateNucleus(address nucleusAddress_) external onlyOwner {
        require(nucleusAddress_ != address(0), "invalid address");
        nucleusAddress = nucleusAddress_;
    }

    function mint() public onlyOwner {
        require(nucleusAddress != address(0), "invalid nucleus address");
        require(block.timestamp > (LAST_MINT_TIME + ONE_DAY), "not reached mint time");
        uint256 mintRanges = (block.timestamp - LAST_MINT_TIME) / ONE_DAY;
        uint256 amount = mintRanges * perMintAmount;

        LAST_MINT_TIME += mintRanges * ONE_DAY;
        _mint(nucleusAddress, amount);
    }
}