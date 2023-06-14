// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ShaggyCoin is ERC20, AccessControl, Ownable {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private constant MAX_SUPPLY = 30_000_000_000 * (10**18); // Maximum supply of 30 billion tokens
    uint256 private constant OWNER_ALLOCATION = 30_000_000_000 * (10**18) * 30 / 100; // 30% of tokens for the owner
    uint256 private constant MARKETING_ALLOCATION = 30_000_000_000 * (10**18) * 3 / 100; // 3% of tokens for marketing
    uint256 private constant DEVELOPMENT_ALLOCATION = 30_000_000_000 * (10**18) * 5 / 100; // 5% of tokens for development
    uint256 private constant CEX_ALLOCATION = 30_000_000_000 * (10**18) * 10 / 100; // 10% of tokens for CEX listing
    uint256 private constant LIQUIDITY_ALLOCATION = 30_000_000_000 * (10**18) * 52 / 100; // 52% of tokens for liquidity

    // Fee percentages
    uint256 private constant TRANSFER_FEE = 1; // 1% transfer fee
    uint256 private constant SWAP_FEE = 1; // 1% swap fee
    uint256 private constant BUY_FEE = 2; // 2% fee on buy transactions

    constructor() ERC20("Shaggy Coin", "SHAGGY") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        _mint(msg.sender, OWNER_ALLOCATION);
        _mint(address(this), MARKETING_ALLOCATION.add(DEVELOPMENT_ALLOCATION).add(CEX_ALLOCATION).add(LIQUIDITY_ALLOCATION));
    }

    /**
     * @dev Creates `amount` new tokens and assigns them to the specified `account`.
     * Can only be called by an account with the MINTER_ROLE.
     * @param account The account to which tokens will be minted.
     * @param amount The amount of tokens to mint.
     */
    function mint(address account, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(totalSupply().add(amount) <= MAX_SUPPLY, "Max supply exceeded");
        _mint(account, amount);
    }

    /**
     * @dev Overrides the transfer function to include additional logic.
     * @param sender The address from which tokens are transferred.
     * @param recipient The address to which tokens are transferred.
     * @param amount The amount of tokens to transfer.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");

        uint256 feeAmount = 0;
        if (sender != owner() && recipient != owner()) {
            if (recipient == address(this)) {
                feeAmount = amount.mul(SWAP_FEE).div(100);
            } else if (msg.sender == owner()) {
                feeAmount = amount.mul(BUY_FEE).div(100);
            } else {
                feeAmount = amount.mul(TRANSFER_FEE).div(100);
            }
        }

        uint256 transferAmount = amount.sub(feeAmount);

        super._transfer(sender, recipient, transferAmount);

        if (feeAmount > 0) {
            super._transfer(sender, address(this), feeAmount);
        }
    }
}