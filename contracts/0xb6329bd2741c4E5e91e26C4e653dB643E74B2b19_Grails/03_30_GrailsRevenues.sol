// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./IGrailsRevenues.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract GrailsRevenues is AccessControlEnumerable, IGrailsRevenues {
    using Address for address payable;

    constructor(address admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
    @notice Role that is allowed to modify any and all artist addresses /
    royalty percentages, and also disburse funds.
     */
    bytes32 public constant FUNDS_ADMIN = keccak256("FUNDS_ADMIN");

    /**
    @dev Emitted when payment is received by the fallback function.
     */
    event ValueReceived(address from, uint256 value);

    receive() external payable {
        emit ValueReceived(msg.sender, msg.value);
    }

    uint8 private constant NUM_GRAILS = 20;

    /**
    @dev Requires that the Grail ID is valid.
     */
    modifier grailExists(uint8 grailId) {
        require(grailId < NUM_GRAILS, "Grail doesn't exist");
        _;
    }

    /**
    @notice Primary addresses of each Grail's respective artist.
     */
    address[NUM_GRAILS] public artists;

    /**
    @dev Requires that the caller is either the respective Grail artist, or an
    administrator.
     */
    modifier onlyAdminOrArtist(uint8 grailId) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(FUNDS_ADMIN, msg.sender) ||
                msg.sender == artists[grailId],
            "Not owner nor admin"
        );
        _;
    }

    /**
    @dev Requires that the caller is an administrator; either DEFAULT_ADMIN_ROLE
    or FUNDS_ADMIN.
     */
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(FUNDS_ADMIN, msg.sender),
            "Not funds admin"
        );
        _;
    }

    /**
    @notice Optional override address for each Grail's respective artist to
    redirect payments to a different address to their own. For example, they may
    wish to automatically send all revenues to Coinbase and leave their primary
    address as zero, thereby relinquishing control if they're not comfortable
    with wallet security.
     */
    mapping(uint8 => address) private receivers;

    /**
    @notice Sets the address of the artist for the associated Grail.
     */
    function transferGrailControl(uint8 grailId, address to)
        external
        grailExists(grailId)
        onlyAdminOrArtist(grailId)
    {
        artists[grailId] = to;
    }

    /**
    @notice Sets the recipient of all funds associated with the specific Grail.
    If set to the zero address, the receiver defaults to the artist's address.
    If that too is the zero address, then this contract is the receiver and it
    holds the funds in escrow.
     */
    function setReceiver(uint8 grailId, address rcv)
        external
        grailExists(grailId)
        onlyAdminOrArtist(grailId)
    {
        receivers[grailId] = rcv;
    }

    /**
    @notice Returns the address to which revenues for the specified Grail should
    be sent.
     */
    function receiver(uint8 grailId) external view returns (address) {
        address rcv = _receiver(grailId);
        if (rcv == address(0)) {
            // Artist is yet to set their address so we'll distribute it for
            // them when they do.
            rcv = address(this);
        }
        return rcv;
    }

    /**
    @dev Internal implementation of receiver(), which has to be external as
    it's part of an interface, but is required internally too.
     */
    function _receiver(uint8 grailId)
        internal
        view
        grailExists(grailId)
        returns (address)
    {
        address rcv = receivers[grailId];
        if (rcv == address(0)) {
            rcv = artists[grailId];
        }
        return rcv;
    }

    /**
    @dev The per-Grail basis points of royalties to be requested under ERC2981.
    As the unset value is zero, this is modified to
    DEFAULT_ROYALTY_BASIS_POINTS; to set an explicit zero royalty, set the
    Grail's value to >MAX_BASIS_POINTS. See royaltyBasisPointsFor().
     */
    mapping(uint8 => uint256) private _royaltyBasisPoints;
    uint256 public constant DEFAULT_ROYALTY_BASIS_POINTS = 10 * 100;
    uint256 private constant MAX_BASIS_POINTS = 100 * 100;

    /**
    @notice Sets the royalty basis points for the specified Grail.
     */
    function setRoyaltyBasisPoints(uint8 grailId, uint256 basisPoints)
        external
        grailExists(grailId)
        onlyAdminOrArtist(grailId)
    {
        require(basisPoints <= MAX_BASIS_POINTS, "Over 100%");
        if (basisPoints == 0) {
            // See royaltyBasisPoints() for differentiation between unset and
            // zero values.
            basisPoints = MAX_BASIS_POINTS + 1;
        }
        _royaltyBasisPoints[grailId] = basisPoints;
    }

    /**
    @notice Returns the royalty basis points for the specified Grail, or a
    DEFAULT_ROYALTY_BASIS_POINTS if none is set.
     */
    function royaltyBasisPoints(uint8 grailId)
        external
        view
        grailExists(grailId)
        returns (uint256)
    {
        uint256 basisPoints = _royaltyBasisPoints[grailId];
        // We can't differentiate between a missing value in the map and an
        // explicit zero, so we use an impossible value as a sentinel to signal
        // an explicit zero.
        if (basisPoints > MAX_BASIS_POINTS) {
            return 0;
        }
        if (basisPoints == 0) {
            return DEFAULT_ROYALTY_BASIS_POINTS;
        }
        return basisPoints;
    }

    /**
    @dev Emitted by disburseBalance() when revenues distributed.
     */
    event BalanceShared(uint8 indexed grailId, address to, uint256 value);

    /**
    @notice Total balance shared to each Grail receiver, regardless of which
    address was used as the receiver at the time.
    @dev For more specific counts, see BalanceShared event logs.
     */
    uint256[NUM_GRAILS] public disbursed;

    /**
    @notice Disburses the revenues amongst artists based on the specified split.
    @dev This is a workaround because OpenSea doesn't support ERC2981 and also
    doesn't allow for multiple royalty recipients in a collection. As a result,
    there is some level of off-chain trust that is unavoidable, but can at least
    be audited. Note that by nature of being onlyAdmin, this is non-reentrant.
    @param shares Individual values SHOULD sum to the current balance of the
    contract to allow for a clear audit trail.
     */
    function disburseBalance(Disbursement[] calldata shares)
        external
        onlyAdmin
    {
        for (uint8 i = 0; i < shares.length; i++) {
            uint256 value = shares[i].value;
            if (value == 0) {
                continue;
            }

            address rcv = _receiver(shares[i].grailId);
            require(rcv != address(0), "Send to zero address");
            payable(rcv).sendValue(value);

            emit BalanceShared(shares[i].grailId, rcv, value);
            disbursed[shares[i].grailId] += value;
        }
    }

    /**
    @notice Returns true iff interfaceId is that of IGrailsRevenues or IERC165.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IGrailsRevenues).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}