// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @title The magical MyExchange token contract.
 * @author int(200/0), slidingpanda
 *
 * @notice A simple ERC20 token with 300 million preminted tokens.
 *         - 1/3 -> 100mio: added to a liq pool myShare:myExchange
 *         - 1/3 -> 100mio: for potential CEX listing
 *         - 1/3 -> 100mio: for 1:1 TEN migration
 */
contract MyExchange is Context, ERC20 {
    uint256 public migrated;
    uint256 public constant MAX_MIGRATE = 1e26;

    bool public migrateIsActive;

    address public tenToken;
    address public daoWallet;
    address public activator;

    /**
     * Constructor that gives activator (like owner) all of the existing tokens.
     */
    constructor(
        string memory name,
        string memory symbol,
        address tenToken_,
        address activator_,
        address daoWallet_
    ) public ERC20(name, symbol) {
        _mint(activator_, 2e26); // totalSupply => 200,000,000 with 18 decimals

        daoWallet = daoWallet_;
        activator = activator_;
        tenToken = tenToken_;
    }

    /**
     * Changes the activator.
	 *
     * @notice Does not need the full functionality of openzeppelin's Ownable.
	 *
     * @param newActivator address of new activator
     */
    function changeActivator(address newActivator) external {
        require(msg.sender == activator, "Changer needs to be activator");

        activator = newActivator;
    }

    /**
     * Shows how much can be migrated.
	 *
	 * @return uint256 migratable amount
     */
    function migrateable() public view returns (uint256) {
        return MAX_MIGRATE - migrated;
    }

    /**
     * Activates the possibility of migrating TEN tokens to myExchange tokens.
     */
    function activateMigration() external {
        require(msg.sender == activator, "Only the activator can activate");

        migrateIsActive = true;
    }

    /**
     * Migrates TEN tokens to myExchange tokens.
	 *
     * @notice TEN tokens are ERC20 tokens, so there is no need for safeTransfer.
	 *
	 * @param amount token amount
     */
    function migrate(uint256 amount) external {
        require(migrateIsActive, "Migration is not active so far");
        require(amount <= migrateable(), "Migration is not possible anymore");

        IERC20(tenToken).transferFrom(msg.sender, daoWallet, amount);

        migrated += amount;

        _mint(msg.sender, amount);
    }

    /**
     * Withdraws ERC20 tokens from the contract.
	 * This contract should not be the owner of any other token.
	 *
     * @param tokenAddr address of the IERC20 token
     * @param to address of the recipient
     */
    function withdrawERC(address tokenAddr, address to) external {
        require(msg.sender == activator, "Caller needs to be the activator");
        IERC20(tokenAddr).transfer(to, IERC20(tokenAddr).balanceOf(address(this)));
    }

    /**
     * Gives the owner the possibility to withdraw ETH which are airdroped or send by mistake to this contract.
	 *
     * @param to recipient of the tokens
     */
    function daoWithdrawETH(address to) external {
        require(msg.sender == activator, "Caller needs to be the activator");
        (bool sent,) = to.call{value: address(this).balance}("");
		
        require(sent, "Failed to send ETH");
    }
}