// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "../utils/Ownable.sol";

/// Tempus Token with initial supply that be increased by up to 2% yearly after 4 years.
/// Holders have the ability to burn their own tokens.
/// Token holders have the ability to vote and participate in governance.
/// It also supports delegating voting rights.
contract TempusToken is Ownable, ERC20Votes {
    /// @dev initial supply to be minted
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000e18;

    /// @dev Minimum time between mints
    uint256 public constant MIN_TIME_BETWEEN_MINTS = 1 days * 365;

    /// @dev Cap on the percentage of totalSupply that can be minted at each mint
    uint256 public constant MINT_CAP = 2;

    /// @dev The timestamp after which minting may occur
    uint256 public immutable mintingAllowedAfter;

    /// @dev The timestamp of last minting
    uint256 public lastMintingTime;

    constructor() ERC20("Tempus", "TEMP") ERC20Permit("Tempus") {
        mintingAllowedAfter = block.timestamp + 4 * 365 * 1 days;
        lastMintingTime = block.timestamp;
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    /// Creates `amount` new tokens for `to`.
    /// @param account Recipient address to mint tokens to
    /// @param amount Number of tokens to mint
    function mint(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Can not mint to 0x0.");
        require(block.timestamp >= mintingAllowedAfter, "Minting not allowed yet.");
        require(block.timestamp >= (lastMintingTime + MIN_TIME_BETWEEN_MINTS), "Not enough time between mints.");
        require(amount <= ((MINT_CAP * totalSupply()) / 100), "Mint cap limit.");

        lastMintingTime = block.timestamp;
        _mint(account, amount);
    }

    /// Destroys `amount` tokens from the caller.
    /// @param amount Number of tokens to burn.
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}