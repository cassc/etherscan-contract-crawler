// SPDX-License-Identifier: AGPL-3.0-only

/*      -.:````:::..        Arbor allows DAOs and other on-chain        .A
      /`:``-..-`   ..:.     entities to borrow stablecoins using       .AAA:
   ./`.:       \:``   :.    their tokens as collateral with fixed    .AAAAAA:
 ./`::`          \.--`` :.       rates and no liquidations.       .:AA.:AAAA:
./_.::            \.    .:                                       :AA..AAAAAA:
||  ::             |--``::.                                     :AA..AAAAAAA:
||_ ::             |.___.::                        ...         :AA..AAAAAAA`
|| `::             ||`|`:::                   .:AAAAAAAAA:.    .A..AAAAAAA`
||_\::             || | |::                  .AAAAAAAAAAAAAAA:  A..AAAA`
|| `::             ||\|/|::                .AAAAA.  AAAAAAAAAA:.:.``
||_\::             || | |::               .AAAAAAA```..........`:`..AA.
|| `:: An Arbor to ||/|\|::                    ``AAAAAAAAAAAAA` .AA..AAA.
||_\::  help DAOs  || | |::                          ``````     AAAA..ABG.
|| `::    Grow     ||\|/|::                                    .AAAAA..AAA.
||_\::             || | |::      For more information about    .AAAAAAA.AA.
|| `::             ||/|\|::         Arbor Finance, visit        .AAAAAAA.AA.
||_\::             ||_  |::         https://arbor.garden         .AAAAAA:AA.
`` `::                `` ::                                        .AAAAAAAA.
    ::                   ::                                            .AAAAA.
    ::                      Authors: Bookland Luckyrobot Namaskar          `*/

pragma solidity 0.8.9;

import {IBondFactory} from "./interfaces/IBondFactory.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {FixedPointMathLib} from "./utils/FixedPointMathLib.sol";

import "./Bond.sol";

/** 
    @title Bond Factory
    @author Arbor Finance
    @notice This factory contract issues new bond contracts.
    @dev This uses a cloneFactory to save on gas costs during deployment.
        See OpenZeppelin's "Clones" proxy.
*/
contract BondFactory is IBondFactory, AccessControl {
    using SafeERC20 for IERC20Metadata;
    using FixedPointMathLib for uint256;

    /// @notice Max length of the Bond.
    uint256 internal constant MAX_TIME_TO_MATURITY = 3650 days;

    /**
        @notice The max number of decimals for the paymentToken and
            collateralToken.
    */
    uint8 internal constant MAX_DECIMALS = 18;

    /// @notice The role required to issue bonds.
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    /// @notice The role given to allowed tokens.
    bytes32 public constant ALLOWED_TOKEN = keccak256("ALLOWED_TOKEN");

    /// @inheritdoc IBondFactory
    address public immutable tokenImplementation;

    /// @inheritdoc IBondFactory
    mapping(address => bool) public isBond;

    /// @inheritdoc IBondFactory
    bool public isIssuerAllowListEnabled = true;

    /// @inheritdoc IBondFactory
    bool public isTokenAllowListEnabled = true;

    /**
        @dev If allow list is enabled, only allow-listed issuers are
            able to call functions.
    */
    modifier onlyIssuer() {
        if (isIssuerAllowListEnabled) {
            _checkRole(ISSUER_ROLE, _msgSender());
        }
        _;
    }

    /*
        When deployed, the deployer will be granted the DEFAULT_ADMIN_ROLE. This
        gives the ability to call `grantRole` to grant access to the ISSUER_ROLE
        as well as the ability to toggle if the allow list is enabled or not at
        any time.
    */
    constructor() {
        tokenImplementation = address(new Bond());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @inheritdoc IBondFactory
    function setIsIssuerAllowListEnabled(bool _isIssuerAllowListEnabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isIssuerAllowListEnabled = _isIssuerAllowListEnabled;
        emit IssuerAllowListEnabled(_isIssuerAllowListEnabled);
    }

    function setIsTokenAllowListEnabled(bool _isTokenAllowListEnabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isTokenAllowListEnabled = _isTokenAllowListEnabled;
        emit TokenAllowListEnabled(_isTokenAllowListEnabled);
    }

    /// @inheritdoc IBondFactory
    function createBond(
        string memory name,
        string memory symbol,
        uint256 maturity,
        address paymentToken,
        address collateralToken,
        uint256 collateralTokenAmount,
        uint256 convertibleTokenAmount,
        uint256 bonds
    ) external onlyIssuer returns (address clone) {
        if (bonds == 0) {
            revert ZeroBondsToMint();
        }
        if (paymentToken == collateralToken) {
            revert TokensMustBeDifferent();
        }
        if (collateralTokenAmount < convertibleTokenAmount) {
            revert CollateralTokenAmountLessThanConvertibleTokenAmount();
        }
        if (
            maturity <= block.timestamp ||
            maturity > block.timestamp + MAX_TIME_TO_MATURITY
        ) {
            revert InvalidMaturity();
        }
        if (
            IERC20Metadata(paymentToken).decimals() > MAX_DECIMALS ||
            IERC20Metadata(collateralToken).decimals() > MAX_DECIMALS
        ) {
            revert TooManyDecimals();
        }
        if (isTokenAllowListEnabled) {
            _checkRole(ALLOWED_TOKEN, paymentToken);
            _checkRole(ALLOWED_TOKEN, collateralToken);
        }

        clone = Clones.clone(tokenImplementation);

        isBond[clone] = true;
        uint256 collateralRatio = collateralTokenAmount.divWadDown(bonds);
        uint256 convertibleRatio = convertibleTokenAmount.divWadDown(bonds);
        _deposit(_msgSender(), clone, collateralToken, collateralTokenAmount);

        Bond(clone).initialize(
            name,
            symbol,
            _msgSender(),
            maturity,
            paymentToken,
            collateralToken,
            collateralRatio,
            convertibleRatio,
            bonds
        );

        emit BondCreated(
            clone,
            name,
            symbol,
            _msgSender(),
            maturity,
            paymentToken,
            collateralToken,
            collateralTokenAmount,
            convertibleTokenAmount,
            bonds
        );
    }

    function _deposit(
        address owner,
        address clone,
        address collateralToken,
        uint256 collateralToDeposit
    ) internal {
        IERC20Metadata(collateralToken).safeTransferFrom(
            owner,
            clone,
            collateralToDeposit
        );
        uint256 collateralInContract = IERC20Metadata(collateralToken)
            .balanceOf(clone);

        /*
            For a valid deposit, the balance of collateralToken in the clone
            at initialization must be at least the collateralToDeposit. This
            ensures that the bonds minted are all at least backed by the 
            appropriate collateral ratio. There is a chance the bond already has
            been given some amount of the tokens due to deterministic contract
            creation. This check therefore allows an excess of tokens, but in
            the case of a token taking a fee, will disallow creation if there
            is an insufficient amount.
        */
        if (collateralToDeposit > collateralInContract) {
            revert InvalidDeposit();
        }
    }
}