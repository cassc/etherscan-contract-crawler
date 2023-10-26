// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/ITokenKeeper.sol";

/**
 * @title TokenKeeper
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @notice A contract for managing ERC20 token transfers and approvals.
 * @dev The TokenKeeper contract holds a list of whitelisted contracts which are authorized to call the transfer and approve functions.
 *      Only the owner of the contract can add or remove contracts from the whitelist. The owner can also freeze all transfers.
 */
contract TokenKeeper is OwnableUpgradeable, ITokenKeeper, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    /**
     * @dev Mapping that keeps track of whitelisted contracts. Contracts in this list are allowed to call the transferToken and approveToken functions.
     */
    mapping(address => bool) public whitelistContract;

    /**
     * @dev A boolean variable to indicate if all transfers are frozen.
     */
    bool public isTransferFrozen;

    /**
     * @dev Modifier that allows only the owner or whitelisted contracts to call certain functions.
     */
    modifier onlyOwnerOrWhitelistContract() {
        require(
            whitelistContract[msg.sender] || msg.sender == owner(),
            "TokenKeeper: caller is not owner or whitelist contract"
        );
        _;
    }

    /**
     * @dev Modifier that allows function execution only if transfers are not frozen.
     */
    modifier notFrozen() {
        require(!isTransferFrozen, "TokenKeeper: transfer is frozen");
        _;
    }

    /**
     * @notice Initializes the TokenKeeper contract.
     * @dev Initializes the contract with Ownable upgradeability and sets the isTransferFrozen state to false.
     */
    function __TokenKeeper_init() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        isTransferFrozen = false;
    }

    /**
     * @notice Sets the whitelist status for a contract.
     * @dev Only the contract owner can set the whitelist status of a contract.
     * @param _whitelistContract The address of the contract to be whitelisted or removed from the whitelist.
     * @param _isActive Whether the contract should be whitelisted.
     */
    function setWhitelistContract(address _whitelistContract, bool _isActive) external onlyOwner {
        require(_whitelistContract != address(0), "TokenKeeper: zero address");
        whitelistContract[_whitelistContract] = _isActive;
    }

    /**
     * @notice Sets the transfer frozen status.
     * @dev Only the contract owner can freeze or unfreeze all transfers.
     * @param _isTransferFrozen The new frozen status.
     */
    function setIsTransferFrozen(bool _isTransferFrozen) external onlyOwner {
        isTransferFrozen = _isTransferFrozen;
    }

    /**
     * @notice Transfers a certain amount of an ERC20 token to a recipient.
     * @dev Transfers an ERC20 token from the TokenKeeper contract to a recipient. Only the contract owner or a whitelisted contract can call this function, and only if transfers are not frozen.
     * @param _tokenAddress The address of the ERC20 token to be transferred.
     * @param _receiver The address to receive the tokens.
     * @param _amount The amount of tokens to be transferred.
     */
    function transferToken(
        address _tokenAddress,
        address _receiver,
        uint256 _amount
    ) external override notFrozen onlyOwnerOrWhitelistContract nonReentrant {
        require(_tokenAddress != address(0), "TokenKeeper: zero address");

        IERC20(_tokenAddress).transfer(_receiver, _amount);
    }

    /**
     * @notice Approves a spender to spend a certain amount of an ERC20 token.
     * @dev Approves a spender to spend an ERC20 token on behalf of the TokenKeeper contract. Only the contract owner or a whitelisted contract can call this function, and only if transfers are not frozen.
     * @param _token The address of the ERC20 token.
     * @param _spender The address to be approved as a spender.
     * @param _approveAmount The amount of tokens the spender is approved to spend.
     */
    function approveToken(
        address _token,
        address _spender,
        uint256 _approveAmount
    ) external override notFrozen onlyOwnerOrWhitelistContract nonReentrant {
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_token), _spender, _approveAmount);
    }
}