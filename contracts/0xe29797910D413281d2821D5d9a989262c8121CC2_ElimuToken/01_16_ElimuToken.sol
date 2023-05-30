// SPDX-License-Identifier: MIT

// https://docs.soliditylang.org/en/v0.8.0/layout-of-source-files.html#pragma
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ElimuToken is ERC20Capped, ERC20Burnable, ERC20Snapshot, AccessControl {

    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev {ERC20-_mint} is used instead of {_mint} in order to prevent TypeError: 
     * "Immutable variables cannot be read during contract creation time." For details, see
     * https://github.com/OpenZeppelin/openzeppelin-contracts/issues/2580
     */
    constructor() ERC20("elimu.ai", "ELIMU") ERC20Capped(387_000_000 * 10 ** decimals()) {
        // Configure access control
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SNAPSHOT_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        // Pre-mint 38,700,000 tokens (10% of the total supply cap)
        ERC20._mint(msg.sender, 38_700_000 * 10 ** decimals());
    }

    function snapshot() public {
        require(hasRole(SNAPSHOT_ROLE, msg.sender));
        _snapshot();
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender));
        require(SafeMath.add(totalSupply(), amount) <= getMaxTotalSupplyForTimestamp(block.timestamp), "ElimuToken: max total supply exceeded for current timestamp");
        _mint(to, amount);
    }

    /**
     * @dev Calculates the maximum total supply for the current time.
     * 
     * 90% of the total supply cap will be minted between 2021-07-01 and 2030-07-01.
     * 
     * No more than 10% of the total supply cap can be minted per year. This corresponds to 
     * 10% / 12 months = ~0.83% per month (~0.03% per day).
     */
    function getMaxTotalSupplyForTimestamp(uint256 timestampInSeconds) public view returns (uint256) {
        uint256 startTimeInSeconds = 1625097600; // 2021-07-01 00:00:00 UTC
        if (timestampInSeconds <= startTimeInSeconds) {
            // The current time is not after the start time

            // Return the amount of tokens that were pre-minted (see constructor)
            return totalSupply();
        } else {
            // The current time is after the start time

            uint256 totalSupplyPreMinted = SafeMath.div(SafeMath.mul(cap(), 10), 100); // 10% of the total supply cap
            uint256 totalSupplyInMintingPeriod = SafeMath.div(SafeMath.mul(cap(), 90), 100); // 90% of the total supply cap

            uint256 numberOfSecondsPassedSinceStartTime = SafeMath.sub(timestampInSeconds, startTimeInSeconds);
            uint256 totalNumberOfSecondsInMintingPeriod = SafeMath.mul(365 days, 9); // 9 years (2021 --> 2030)

            if (numberOfSecondsPassedSinceStartTime < totalNumberOfSecondsInMintingPeriod) {
                // The minting period is still on-going

                // Calculate the mintable amount based on how many days have passed since the start time
                uint256 supplyUnlockedForMinting = SafeMath.div(SafeMath.mul(totalSupplyInMintingPeriod, numberOfSecondsPassedSinceStartTime), totalNumberOfSecondsInMintingPeriod);

                // Return the amount of tokens that were pre-minted plus the amount unlocked for minting
                return SafeMath.add(totalSupplyPreMinted, supplyUnlockedForMinting);
            } else {
                // The minting period has ended

                return cap();
            }
        }
    }

    /**
     * @dev Overrides {_mint} function defined in two base classes. See 
     * https://docs.soliditylang.org/en/develop/contracts.html#inheritance
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    /**
     * @dev Overrides {_beforeTokenTransfer} function defined in two base classes. See 
     * https://docs.soliditylang.org/en/develop/contracts.html#inheritance
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }
}