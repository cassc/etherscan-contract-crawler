// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {SuperallowlistERC20} from "../lib/superallowlist/src/SuperallowlistERC20.sol";

/**
 * @title Open Exchange Token (OX)
 * @notice OX is an ERC20 token deployed initially on Ethereum mainnet. It has a 
   maximum supply of 9,860,000,000 tokens, which is approx. 100 times the total supply of 
   the FLEX token on flexstatistics.com. OX implements a mutable minting mechanism
   through authorized "Minter" addresses and includes functionalities from the 
   SuperallowlistERC20 contract for managing the denylist and superallowlist.
 * @author opnxj
 */
contract OpenExchangeToken is SuperallowlistERC20 {
    // 100 times the max supply of FLEX on flexstatistics.com
    uint256 public constant MAX_MINTABLE_SUPPLY = 9_860_000_000 ether;
    uint256 public constant INITIAL_MINT_TO_TREASURY = 500_000_000 ether; // 500M
    uint256 public totalMintedSupply;
    bool public mintingStopped;

    mapping(address => bool) public minters;

    event MintingStopped();
    event MinterSet(address indexed minter, bool isMinter);

    modifier mintingNotStopped() {
        require(!mintingStopped, "Minting has been stopped");
        _;
    }

    modifier onlyMinters() {
        require(minters[msg.sender], "Sender is not a Minter");
        _;
    }

    constructor(
        address treasury
    ) SuperallowlistERC20("Open Exchange Token", "OX", 18) {
        totalMintedSupply += INITIAL_MINT_TO_TREASURY;
        _mint(treasury, INITIAL_MINT_TO_TREASURY);
    }

    /**
     * @notice Stops the future minting of tokens on this chain (not all chains)
     * @dev Only callable by the contract owner
     */
    function stopMinting() external onlyOwner {
        mintingStopped = true;
        emit MintingStopped();
    }

    /**
     * @notice Updates the Minter status of an address
     * @dev Only callable by the contract owner
     * @param minter The address for which the Minter status is being updated
     * @param isMinter Boolean indicating whether the address should be assigned or revoked the Minter role
     */
    function setMinter(address minter, bool isMinter) external onlyOwner {
        minters[minter] = isMinter;
        emit MinterSet(minter, isMinter);
    }

    /**
     * @notice Mints new OX tokens and assigns them to the specified address
     * @dev Only callable by addresses with the Minter role
     * @param to The address to which the newly minted tokens will be assigned
     * @param amount The amount of tokens to mint and assign to the `to` address
     */
    function mint(
        address to,
        uint256 amount
    ) external mintingNotStopped onlyMinters {
        require(
            totalMintedSupply + amount <= MAX_MINTABLE_SUPPLY,
            "Exceeds maximum supply"
        );
        totalMintedSupply += amount;
        _mint(to, amount);
    }

    /**
     * @notice Burns a specific amount of tokens
     * @dev This function permanently removes tokens from the total supply
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}