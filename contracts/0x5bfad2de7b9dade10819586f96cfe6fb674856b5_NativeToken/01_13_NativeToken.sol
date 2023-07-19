// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {INativeToken} from "../interfaces/INativeToken.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IGaugeController} from "../interfaces/IGaugeController.sol";

/// @title NativeToken
/// @author leNFT
/// @notice Token contract for the native token of the protocol
/// @dev Provides functionality distributing native tokens
contract NativeToken is
    INativeToken,
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable
{
    uint256 private constant MAX_CAP = 1e27; // 1 billion tokens max cap
    IAddressProvider private immutable _addressProvider;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IAddressProvider addressProvider) {
        _addressProvider = addressProvider;
        _disableInitializers();
    }

    /// @notice Initializes the contract with the specified parameters
    function initialize() external initializer {
        __ERC20_init("leNFT Token", "LE");
        __ReentrancyGuard_init();
    }

    /// @notice Gets the maximum supply of the token
    /// @return The maximum supply of the token
    function getCap() public pure returns (uint256) {
        return MAX_CAP;
    }

    /// @notice Internal function to mint tokens and assign them to the specified account
    /// @param account The account to receive the tokens
    /// @param amount The amount of tokens to mint
    function _mint(address account, uint256 amount) internal override {
        require(amount > 0, "NT:M:AMOUNT_0");
        require(
            ERC20Upgradeable.totalSupply() + amount <= getCap(),
            "NT:M:CAP_EXCEEDED"
        );
        ERC20Upgradeable._mint(account, amount);
    }

    /// @notice Internal function to burn tokens from the specified account
    /// @param account The account to burn tokens from
    /// @param amount The amount of tokens to burn
    function _burn(address account, uint256 amount) internal override {
        require(amount > 0, "NT:B:AMOUNT_0");
        ERC20Upgradeable._burn(account, amount);
    }

    /// @notice Mints vested tokens to the specified receiver
    /// @dev The caller must be the native token vesting contract.
    /// @param receiver The address to receive the vested tokens.
    /// @param amount The amount of vested tokens to mint.
    function mintVestingTokens(
        address receiver,
        uint256 amount
    ) external override {
        require(
            msg.sender == _addressProvider.getNativeTokenVesting(),
            "NT:MVT:NOT_VESTING"
        );
        _mint(receiver, amount);
    }

    /// @notice Mints genesis tokens and assigns them to the Genesis NFT contract
    /// @dev The caller must be the Genesis NFT contract.
    /// @param amount The amount of tokens to mint
    function mintGenesisTokens(uint256 amount) external {
        require(
            msg.sender == _addressProvider.getGenesisNFT(),
            "NT:MGT:NOT_GENESIS"
        );
        _mint(msg.sender, amount);
    }

    /// @notice Burns the specified amount of tokens for the Genesis contract.
    /// @dev The caller must be the Genesis NFT contract.
    /// @param amount The amount of Genesis tokens to burn.
    function burnGenesisTokens(uint256 amount) external {
        require(
            msg.sender == _addressProvider.getGenesisNFT(),
            "NT:BGT:NOT_GENESIS"
        );
        _burn(msg.sender, amount);
    }

    /// @notice Mints the specified amount of gauge rewards to the specified receiver.
    /// @dev The caller must be an approved gauge.
    /// @param receiver The address to receive the gauge rewards.
    /// @param amount The amount of gauge rewards to mint.
    function mintGaugeRewards(
        address receiver,
        uint256 amount
    ) external override {
        require(
            IGaugeController(_addressProvider.getGaugeController()).isGauge(
                msg.sender
            ),
            "NT:MGR:NOT_GAUGE"
        );
        _mint(receiver, amount);
    }

    /// @notice Mints the specified amount of rebates to the specified receiver.
    /// @dev The caller must be the voting escrow contract.
    /// @param receiver The address to receive the rebates.
    /// @param amount The amount of rebates to mint.
    function mintRebates(address receiver, uint256 amount) external override {
        require(
            msg.sender == _addressProvider.getVotingEscrow(),
            "NT:MR:NOT_VOTING_ESCROW"
        );
        _mint(receiver, amount);
    }
}