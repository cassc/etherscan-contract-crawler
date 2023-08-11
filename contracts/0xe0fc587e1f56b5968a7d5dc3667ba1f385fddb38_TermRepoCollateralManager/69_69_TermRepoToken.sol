//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./lib/ExponentialNoError.sol";
import "./lib/TermRepoTokenConfig.sol";
import "./interfaces/ITermRepoToken.sol";
import "./interfaces/ITermRepoTokenErrors.sol";
import "./interfaces/ITermEventEmitter.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/// @author TermLabs
/// @title Term Repo Token
/// @notice This is an ERC-20 contract to track claims to the aggregate repurchase obligations due on the repurchase date across all borrowers to a Term Repo
/// @dev This contract belongs to the Term Servicer group of contracts and is specific to a Term Repo deployment
contract TermRepoToken is
    Initializable,
    ERC20Upgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ExponentialNoError,
    ITermRepoTokenErrors,
    ITermRepoToken
{
    // ========================================================================
    // = Access Roles  ========================================================
    // ========================================================================

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant INITIALIZER_ROLE = keccak256("INITIALIZER_ROLE");

    // ========================================================================
    // = State Variables ======================================================
    // ========================================================================
    uint8 internal decimalPlaces; // NOTE: aligned with purchase token
    bool internal termContractPaired;
    bool public mintingPaused;
    bool public burningPaused;
    uint256 public redemptionValue; // NOTE: number of purchase tokens per unit
    bytes32 public termRepoId;
    uint256 public mintExposureCap;
    TermRepoTokenConfig public config;
    ITermEventEmitter internal emitter;

    // ========================================================================
    // = Modifiers  ===========================================================
    // ========================================================================

    modifier whileMintingNotPaused() {
        if (mintingPaused) {
            revert TermRepoTokenMintingPaused();
        }
        _;
    }

    modifier whileBurningNotPaused() {
        if (burningPaused) {
            revert TermRepoTokenBurningPaused();
        }
        _;
    }

    modifier notTermContractPaired() {
        if (termContractPaired) {
            revert AlreadyTermContractPaired();
        }
        termContractPaired = true;
        _;
    }

    // ========================================================================
    // = Deploy (https://docs.openzeppelin.com/contracts/4.x/upgradeable) =====
    // ========================================================================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata termRepoId_,
        string calldata name_,
        string calldata symbol_,
        address termRepoServicer_,
        uint8 decimalPlaces_,
        uint256 redemptionValue_,
        uint256 mintExposureCap_,
        TermRepoTokenConfig calldata config_
    ) external initializer {
        ERC20Upgradeable.__ERC20_init(name_, symbol_);
        UUPSUpgradeable.__UUPSUpgradeable_init();
        AccessControlUpgradeable.__AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, termRepoServicer_);
        _grantRole(BURNER_ROLE, termRepoServicer_);
        _grantRole(INITIALIZER_ROLE, msg.sender);

        // slither-disable-start reentrancy-no-eth events-maths
        decimalPlaces = decimalPlaces_;
        redemptionValue = redemptionValue_;
        config = config_;
        // slither-disable-end reentrancy-no-eth events-maths

        termRepoId = keccak256(abi.encodePacked(termRepoId_));

        mintExposureCap = mintExposureCap_;

        mintingPaused = false;

        termContractPaired = false;
    }

    function pairTermContracts(
        ITermEventEmitter emitter_
    ) external onlyRole(INITIALIZER_ROLE) notTermContractPaired {
        emitter = emitter_;

        emitter.emitTermRepoTokenInitialized(
            termRepoId,
            address(this),
            redemptionValue
        );
    }

    function resetMintExposureCap(
        uint256 mintExposureCap_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintExposureCap = mintExposureCap_;
    }

    // ========================================================================
    // = Interface/API ========================================================
    // ========================================================================

    /// @notice Calculates the total USD redemption value of all outstanding TermRepoTokens
    /// @return totalRedemptionValue The total redemption value of TermRepoTokens in USD
    function totalRedemptionValue() external view returns (uint256) {
        uint256 totalValue = truncate(
            mul_(
                Exp({mantissa: totalSupply() * expScale}),
                Exp({mantissa: redemptionValue})
            )
        );
        return totalValue;
    }

    /// @notice Burns TermRepoTokens held by an account
    /// @notice Reverts if caller does not have BURNER_ROLE
    /// @param account The address of account holding TermRepoTokens to burn
    /// @param amount The amount of TermRepoTokens to burn without decimal factor
    function burn(
        address account,
        uint256 amount
    ) external override onlyRole(BURNER_ROLE) whileBurningNotPaused {
        _burn(account, amount);
        mintExposureCap += amount;
    }

    /// @notice Burns TermRepoTokens held by an account and returns purchase redemption value of tokens burned
    /// @notice Reverts if caller does not have BURNER_ROLE
    /// @param account The address of account holding TermRepoTokens to burn
    /// @param amount The amount of TermRepoTokens to burn without decimal factor
    /// @return totalRedemptionValue Total redemption value of TermRepoTokens burned
    function burnAndReturnValue(
        address account,
        uint256 amount
    )
        external
        override
        onlyRole(BURNER_ROLE)
        whileBurningNotPaused
        returns (uint256)
    {
        _burn(account, amount);
        mintExposureCap += amount;
        uint256 valueBurned = truncate(
            mul_(
                Exp({mantissa: amount * expScale}),
                Exp({mantissa: redemptionValue})
            )
        );
        return valueBurned;
    }

    /// @notice Mints TermRepoTokens in an amount equal to caller specified target redemption amount
    /// @notice The redemptionValue is the amount of purchase tokens redeemable per unit of TermRepoToken
    /// @notice Reverts if caller does not have MINTER_ROLE
    /// @param account The address of account to mint TermRepoTokens to
    /// @param redemptionAmount The target redemption amount to mint in TermRepoTokens
    /// @return numTokens The amount of Term Repo Tokens minted
    function mintRedemptionValue(
        address account,
        uint256 redemptionAmount
    )
        external
        override
        whileMintingNotPaused
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        uint256 numTokens = truncate(
            div_(
                Exp({mantissa: redemptionAmount * expScale}),
                Exp({mantissa: redemptionValue})
            )
        );
        _mint(account, numTokens);
        return numTokens;
    }

    /// @notice Mints an exact amount of TermRepoTokens
    /// @notice Reverts if caller does not have MINTER_ROLE
    /// @param account The address of account to mint TermRepoTokens to
    /// @param numTokens The exact number of term repo tokens to mint
    function mintTokens(
        address account,
        uint256 numTokens
    )
        external
        override
        whileMintingNotPaused
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        _mint(account, numTokens);
        uint256 redemptionValueMinted = truncate(
            mul_(
                Exp({mantissa: numTokens * expScale}),
                Exp({mantissa: redemptionValue})
            )
        );
        return redemptionValueMinted;
    }

    /// @notice Decrements the mintExposureCap
    /// @notice Reverts if caller does not have MINTER_ROLE
    /// @param supplyMinted The number of Tokens Minted
    function decrementMintExposureCap(
        uint256 supplyMinted
    ) external override onlyRole(MINTER_ROLE) {
        if (supplyMinted > mintExposureCap) {
            revert MintExposureCapExceeded();
        }
        mintExposureCap -= supplyMinted;
    }

    /// @return uint8 A uint8 that specifies how many decimal places a token has
    function decimals() public view virtual override returns (uint8) {
        return decimalPlaces;
    }

    // ========================================================================
    // = Pause Functions ======================================================
    // ========================================================================

    function pauseMinting() external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintingPaused = true;
        emitter.emitTermRepoTokenMintingPaused(termRepoId);
    }

    function unpauseMinting() external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintingPaused = false;
        emitter.emitTermRepoTokenMintingUnpaused(termRepoId);
    }

    function pauseBurning() external onlyRole(DEFAULT_ADMIN_ROLE) {
        burningPaused = true;
        emitter.emitTermRepoTokenBurningPaused(termRepoId);
    }

    function unpauseBurning() external onlyRole(DEFAULT_ADMIN_ROLE) {
        burningPaused = false;
        emitter.emitTermRepoTokenBurningUnpaused(termRepoId);
    }

    // solhint-disable no-empty-blocks
    ///@dev Required override by the OpenZeppelin UUPS module
    function _authorizeUpgrade(
        address
    ) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {}
    // solhint-enable no-empty-blocks
}