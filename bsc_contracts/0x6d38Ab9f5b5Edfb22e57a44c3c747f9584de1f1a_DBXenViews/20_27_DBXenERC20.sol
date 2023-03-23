// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/**
 * Reward token contract to be used by the dbxen protocol.
 * The entire amount is minted by the main dbxen contract 
 * (DBXen.sol - which is the owner of this contract)
 * directly to an account when it claims rewards.
 */
contract DBXenERC20 is ERC20Permit {

    /**
     * The address of the DBXen.sol contract instance.
     */
    address public immutable owner;

    /**
     * Sets the owner address. 
     * Called from within the DBXen.sol constructor.
     */
    constructor() ERC20("DBXen Token", "DXN")
    ERC20Permit("DBXen Token") {
        owner = msg.sender;
    }

    /**
     * The total supply is naturally capped by the distribution algorithm 
     * implemented by the main dbxen contract, however an additional check 
     * that will never be triggered is added to reassure the reader.
     * 
     * @param account the address of the reward token reciever
     * @param amount wei to be minted
     */
    function mintReward(address account, uint256 amount) external {
        require(msg.sender == owner, "DBXen: caller is not DBXen contract.");
        require(super.totalSupply() < 5010000000000000000000000, "DBXen: max supply already minted");
        _mint(account, amount);
    }
}