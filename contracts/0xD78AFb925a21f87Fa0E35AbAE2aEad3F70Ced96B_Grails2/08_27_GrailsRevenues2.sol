// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "grails/season-01/IGrailsRevenues.sol";
import "./IGrailsRoyaltyRouter.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Grails Revenues 2
 * @author PROOF
 * @notice This contract collects all Grail revenues (primary and secondary),
 * which will later be distributed to the respective artists and PROOF treasury
 * according to pre-agreed shares.
 * We opted to centralize the management of funds completely for the following
 * reasons:
 * - To keep the identity of Grail artists secret until after the reveal.
 * - As a workaround because marketplaces like OpenSea and X2Y2 don't support
 *   ERC2981 or multiple royalty receivers in a collection. As a result,
 *   there is some level of off-chain trust that is unavoidable.
 * - To avoid any confusion and possible mistakes in payouts, we also use this
 *   for marketplaces that do support ERC2981.
 * @notice This contract handles the ERC2981 creator fee computation (i.e. the
 * royalty percentage for each season) and rounting for all Grails contracts.
 */
contract GrailsRevenues2 is AccessControlEnumerable, IGrailsRoyaltyRouter {
    using Address for address payable;

    // =========================================================================
    //                           Events
    // =========================================================================

    /**
     * @notice Emitted by disburseBalance() when ETH revenues distributed.
     */
    event Disbursed(address indexed to, uint256 value);

    /**
     * @notice Emitted by disburseBalance() when ERC20 revenues distributed.
     */
    event Disbursed(IERC20 indexed token, address indexed to, uint256 value);

    /**
     * @dev Emitted when ETH payment is received by the fallback function.
     */
    event ValueReceived(address indexed from, uint256 value);

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if a specified royalty fraction is invalid.
     */
    error InvalidBasisPoints();

    /**
     * @notice Thrown if a method call is not authorized.
     */
    error UnauthorizedCall();

    /**
     * @notice Throw if attempting to send funds to the zero address.
     */
    error SendToZeroAddress();

    // =========================================================================
    //                           Types
    // =========================================================================

    /**
     * @notice Struct defining a disbursment, i.e. the amount of tokens and
     * their receiver.
     */
    struct Disbursement {
        address payable to;
        uint256 amount;
    }

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice Role that is allowed to modify royalty shares and disburs funds.
     */
    bytes32 public constant FUNDS_ADMIN_ROLE = keccak256("FUNDS_ADMIN_ROLE");

    /**
     * @notice Defines that we operate in terms of basis points (permyriads)
     * when referring to royalty shares.
     */
    uint256 public constant FEE_DENOMINATOR = 10000;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Stores the royalty share for each Grails season.
     */
    mapping(uint256 => uint256) public secondaryRoyaltyBasisPointsBySeason;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(address admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        secondaryRoyaltyBasisPointsBySeason[1] = FEE_DENOMINATOR / 10; // 10%
        secondaryRoyaltyBasisPointsBySeason[2] = FEE_DENOMINATOR / 10; // 10%
    }

    receive() external payable {
        emit ValueReceived(msg.sender, msg.value);
    }

    // =========================================================================
    //                           Royalty Routing
    // =========================================================================

    /**
     * @notice Computes the ERC2981 compatible royalties for a given season.
     * @dev Routes all ERC2981 revenues to this contract.
     */
    function royaltyInfo(
        uint256 season,
        uint256,
        uint256,
        uint256 salePrice
    ) public view virtual returns (address, uint256) {
        uint256 royaltyAmount = (salePrice *
            secondaryRoyaltyBasisPointsBySeason[season]) / FEE_DENOMINATOR;

        return (address(this), royaltyAmount);
    }

    /**
     * @notice Changes the royalty share for a given season.
     */
    function setSecondaryRoyaltyBasisPoints(uint256 season, uint256 basisPoints)
        external
        onlyAdmin
    {
        if (basisPoints > FEE_DENOMINATOR) revert InvalidBasisPoints();
        secondaryRoyaltyBasisPointsBySeason[season] = basisPoints;
    }

    // =========================================================================
    //                           Disbursement
    // =========================================================================

    /**
     * @notice Disburses the ETH revenues amongst artists and treasury.
     * @param shares Individual values SHOULD sum to the current balance of the
     * contract to allow for a clear audit trail.
     */
    function disburseBalance(Disbursement[] calldata shares)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < shares.length; ++i) {
            if (shares[i].to == address(0)) revert SendToZeroAddress();
            (shares[i].to).sendValue(shares[i].amount);
            emit Disbursed(shares[i].to, shares[i].amount);
        }
    }

    /**
     * @notice Disburses the ERC20 revenues amongst artists and treasury.
     * @param shares Individual values SHOULD sum to the current balance of the
     * contract to allow for a clear audit trail.
     */
    function disburseBalance(IERC20 token, Disbursement[] calldata shares)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < shares.length; ++i) {
            if (shares[i].to == address(0)) revert SendToZeroAddress();
            token.transfer(shares[i].to, shares[i].amount);
            emit Disbursed(token, shares[i].to, shares[i].amount);
        }
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Requires that the caller is an administrator.
     * @dev Either a member of DEFAULT_ADMIN_ROLE or FUNDS_ADMIN_ROLE.
     */
    modifier onlyAdmin() {
        if (
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) &&
            !hasRole(FUNDS_ADMIN_ROLE, msg.sender)
        ) revert UnauthorizedCall();
        _;
    }

    // =========================================================================
    //                           Season 1 compatibility
    // =========================================================================

    /**
     * @notice Returns the address to which revenues for the specified Grail
     * of season 1 should be sent.
     * @dev This function is needed because the Grails 1 contract expects a
     * different routing interface.
     */
    function receiver(uint8) external view returns (address) {
        return address(this);
    }

    /**
     * @notice Returns the royalty basis points for the specified Grail of
     * season 1.
     * @dev This function is needed because the Grails 1 contract expects a
     * different routing interface.
     */
    function royaltyBasisPoints(uint8) external view returns (uint256) {
        return secondaryRoyaltyBasisPointsBySeason[1];
    }

    // =========================================================================
    //                           Internal
    // =========================================================================

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return
            // for backwards compatibility
            interfaceId == type(IGrailsRevenues).interfaceId ||
            interfaceId == type(IGrailsRoyaltyRouter).interfaceId ||
            AccessControlEnumerable.supportsInterface(interfaceId);
    }
}