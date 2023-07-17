// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Error: transfer attempt while protocol is paused.
 */
error ProtocolPaused(address sender, address recipient, uint256 amount);

/**
 * @dev Error: attempt to enable transferability before the end of the non-transferability period.
 */
error TransferabilityCannotBeEnabled();

/**
 * @dev Error: total supply minted is not equal to max supply.
 * @param currentTotalSupply total supply attempted to be minted.
 * @param expectedTotalSupply expected total supply.
 */
error InvalidTotalSupply(
    uint256 currentTotalSupply,
    uint256 expectedTotalSupply
);

/**
 * @dev Error: only the merkle distributor can call this method.
 */
error OnlyMerkleDistributorCanCallThisMethod();

/**
 * @dev Error: attempt to mint foundation tokens from an address without permission.
 */
error OnlyFoundationMinterCanCallThis();

/**
 * @title Diva Governance Token.
 * @author ShamirLabs
 * @notice This token is used to govern the Diva Protocol.
 * @dev This token is non transferable for a period of time after deployment.
 * This period is defined by the MINIMUM_NON_TRANSFERABILITY_PERIOD period.
 */
contract DivaToken is Pausable, ERC20Votes, Ownable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000_000_000_000_000_000_000; // 1 Billion DIVA tokens total supply.
    uint256 public constant FOUNDATION_SUPPLY =
        115_850_000_000_000_000_000_000_000; // 115850000 DIVA tokens for delayed minting to the foundation.
    uint256 public constant MINIMUM_NON_TRANSFERABILITY_PERIOD = 10 weeks; // transferability can be enabled 10 weeks after deployment (only by governance).

    uint256 public immutable nonTransferabilityPeriodEnd; // timestamp when transferability can be enabled.
    address private immutable foundationMinter; // address allowed to mint tokens for the foundation when legally constituted.

    mapping(address => bool) private allowedTransferee; // whitelisted addresses for token distribution.
    address private merkleDistributor;

    struct Recipient {
        address to;
        uint256 amount;
    }

    /**
     * @notice Constructor: DivaToken ERC20 token.
     * @param _name ERC20 token name.
     * @param _symbol ERC20 token symbol.
     */
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        // @dev This token is non transferable for a given period of time after deployment.
        _pause();

        // @dev Whitelisting the zero address to allow token minting.
        allowedTransferee[address(0)] = true;

        // @dev Setting the timestamp from which transferability can be enabled.
        nonTransferabilityPeriodEnd =
            block.timestamp +
            MINIMUM_NON_TRANSFERABILITY_PERIOD;

        foundationMinter = msg.sender;
    }

    /**
     * @notice This function is used to enable transferability of the token.
     * @dev Unpauses the transferability of the ERC20 token and renounces ownership of the contract.
     */
    function unpause() public onlyOwner {
        // @dev enforce that transferability can only be enabled after the non-transferability period.
        if (block.timestamp < nonTransferabilityPeriodEnd)
            revert TransferabilityCannotBeEnabled();

        renounceOwnership();

        _unpause();
    }

    /**
     * @notice This function is used to distribute the tokens to the DAO and other recipients and transfer ownership of the contract to the DAO.
     * @dev This function can only be called by the owner of the contract (the DAO) only once.
     * @param _recipients An array of Recipient structs containing the address of the recipient and the amount of tokens to be minted for them.
     * @param airdrop A Recipient struct containing the address of the airdrop contract and the amount of tokens to be minted for it.
     * @param _dao The address of the DAO.
     */
    function distributeAndTransferOwnership(
        Recipient[] calldata _recipients,
        Recipient calldata airdrop,
        address _dao
    ) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_recipients[i].to, _recipients[i].amount);
        }

        _mint(airdrop.to, airdrop.amount);
        allowedTransferee[airdrop.to] = true;

        merkleDistributor = airdrop.to;

        if (totalSupply() != (MAX_SUPPLY - FOUNDATION_SUPPLY))
            revert InvalidTotalSupply(
                totalSupply(),
                MAX_SUPPLY - FOUNDATION_SUPPLY
            );

        _transferOwnership(_dao);
    }

    /**
     * @notice This function is used to mint the tokens for the foundation.
     * @param _foundation The address of the foundation.
     */
    function mintFoundationDistribution(address _foundation) external {
        if (msg.sender != foundationMinter)
            revert OnlyFoundationMinterCanCallThis();
        _mint(_foundation, FOUNDATION_SUPPLY);

        if (totalSupply() != MAX_SUPPLY)
            revert InvalidTotalSupply(totalSupply(), MAX_SUPPLY);
    }

    /**
     * @notice This function is used to delegate votes after claiming process.
     * @param account The address of the account to delegate from.
     */
    function delegateFromMerkleDistributor(address account) external {
        if (msg.sender != merkleDistributor)
            revert OnlyMerkleDistributorCanCallThisMethod();
        super._delegate(account, account);
    }

    // @dev custom _beforeTokenTransfer method that allows transfer from whitelisted addresses.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override(ERC20) {
        if (paused() && !(allowedTransferee[from])) {
            revert ProtocolPaused(from, to, amount);
        }
    }

    // The functions below are overrides required.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20Votes) {
        super._burn(account, amount);
    }
}