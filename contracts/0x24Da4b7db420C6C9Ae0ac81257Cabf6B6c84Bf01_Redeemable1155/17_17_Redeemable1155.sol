pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Redeemable1155 is ERC1155, AccessControlEnumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // ----------------- Events -------------------- //

    event Mint(address _minter, uint256 _tokenId);

    // ----------------- Errors -------------------- //

    // @notice error when address is zero address
    error InvalidAddress();

    // @notice error when caller is not redemption agent
    /// @param caller of the call
    error Unauthorized(address caller);

    // Error for empty constructor arguments
    /// @param arg The argument that was sent
    error EmptyConstructorArgument(string arg);

    // ----------------- Max Supply -------------------- //

    uint public constant MAX_SUPPLY = 3333;

    // ----------------- White List -------------------- //

    struct WhitelistedUser {
        address whitelistedAddress;
        uint256 mintsRemaining;
    }

    mapping(address => uint256) public whitelistedUsers;

    // ----------------- Mint Period Related  -------------------- //

    uint256 public mintStartDate;
    uint256 public mintEndDate;
    bool public isMintActive;

    // ----------------- Misc  -------------------- //

    // constant for empty string
    bytes32 private constant EMPTY_STRING = keccak256(bytes(""));

    // ----------------- Role Definitions -------------------- //

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant REDEMPTION_AGENT_ROLE =
        keccak256("REDEMPTION_AGENT_ROLE");

    // ----------------- Role Assignments -------------------- //

    // Address of the contract owner.
    address ownerAddress;
    address pendingOwnerAddress;

    // ----------------- Role Checks -------------------- //

    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, msg.sender));
        _;
    }
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwnerAddress);
        _;
    }
    modifier onlyOwnerOrAdmin() {
        require(
            hasRole(OWNER_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender),
            "Unauthorized"
        );
        _;
    }

    modifier onlyOwnerAdminOrOperator() {
        require(
            hasRole(OWNER_ROLE, msg.sender) ||
                hasRole(ADMIN_ROLE, msg.sender) ||
                hasRole(OPERATOR_ROLE, msg.sender),
            "Unauthorized"
        );
        _;
    }

    modifier onlyOwnerAdminOrOperatorOrRedemptionAgent() {
        require(
            hasRole(OWNER_ROLE, msg.sender) ||
                hasRole(ADMIN_ROLE, msg.sender) ||
                hasRole(OPERATOR_ROLE, msg.sender) ||
                hasRole(REDEMPTION_AGENT_ROLE, msg.sender),
            "Unauthorized"
        );
        _;
    }

    modifier onlyRedemptionAgent() {
        require(hasRole(REDEMPTION_AGENT_ROLE, msg.sender), "Unauthorized");
        _;
    }

    // ----------------- Constructor -------------------- //

    constructor(
        // _uri should point to a file that specifies all the characteristics of a token: name, symbol, description, etc.
        string memory _uri,
        address _redemptionAgentAddress,
        address _adminAddress,
        address _operatorAddress,
        address _ownerAddress
    ) ERC1155(_uri) {
        if (keccak256(bytes(_uri)) == EMPTY_STRING) {
            revert EmptyConstructorArgument("uri");
        }
        if (
            _redemptionAgentAddress == address(0) ||
            _ownerAddress == address(0) ||
            _adminAddress == address(0)
        ) {
            revert InvalidAddress();
        }

        ownerAddress = _ownerAddress;
        _setupRole(OWNER_ROLE, _ownerAddress);
        _setupRole(REDEMPTION_AGENT_ROLE, _redemptionAgentAddress);
        _setupRole(ADMIN_ROLE, _adminAddress);
        _setupRole(OPERATOR_ROLE, _operatorAddress);
        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
        _setRoleAdmin(REDEMPTION_AGENT_ROLE, ADMIN_ROLE);
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
        _setURI(_uri);
    }

    //-------------------------------Update the Token URI --------------------------------- //
    // @notice Update the metadata URI. Access limited to REDEMPTION_AGENT
    function updateTokenURI(
        string memory _newURI
    ) external onlyOwnerAdminOrOperatorOrRedemptionAgent {
        if (keccak256(bytes(_newURI)) == EMPTY_STRING) {
            revert EmptyConstructorArgument("uri");
        }
        _setURI(_newURI);
    }

    //-------------------------------Add User to White List --------------------------------- //

    function addUsersToWhitelist(
        WhitelistedUser[] memory _users
    ) public onlyOwnerAdminOrOperator {
        for (uint i = 0; i < _users.length; i++) {
            whitelistedUsers[_users[i].whitelistedAddress] = _users[i]
                .mintsRemaining;
        }
    }

    //------------------------------- Minting Period  --------------------------------- //

    function setMintingPeriod(
        uint256 startDate,
        uint256 endDate
    ) public onlyOwnerAdminOrOperator {
        require(startDate < endDate);
        mintStartDate = startDate;
        mintEndDate = endDate;
    }

    function updateMintStatus(bool isActive) public onlyOwnerAdminOrOperator {
        isMintActive = isActive;
    }

    //-------------------------------Perform the Mint --------------------------------- //

    function mint() public {
        uint256 mintsRemaining = whitelistedUsers[msg.sender];
        require(isMintActive, "Minting is not active");
        require(
            block.timestamp >= mintStartDate && block.timestamp <= mintEndDate
        );
        require(mintsRemaining > 0, "No mints remaining");
        require(_tokenIds.current() < MAX_SUPPLY);
        require((_tokenIds.current() + mintsRemaining) <= MAX_SUPPLY);

        for (mintsRemaining; mintsRemaining > 0; mintsRemaining--) {
            _tokenIds.increment();

            uint256 currentTokenId = _tokenIds.current();

            //deduct one mint from the available mints for the sender
            whitelistedUsers[msg.sender] -= 1;
            _mint(msg.sender, currentTokenId, 1, "");

            emit Mint(msg.sender, currentTokenId);
        }
    }

    // ----------------- Role Management -------------------- //
    function grantAdmin(address user) public onlyOwner {
        _grantRole(ADMIN_ROLE, user);
    }

    function revokeAdmin(address user) public onlyOwner {
        _revokeRole(ADMIN_ROLE, user);
    }

    function grantOperator(address user) public onlyOwner {
        _grantRole(OPERATOR_ROLE, user);
    }

    function revokeOperator(address user) public onlyOwner {
        _revokeRole(OPERATOR_ROLE, user);
    }

    function grantRedemptionAgentRole(
        address _address
    ) public onlyOwnerOrAdmin {
        _grantRole(REDEMPTION_AGENT_ROLE, _address);
    }

    function transferOwnership(address _newOwnerAddress) public onlyOwner {
        pendingOwnerAddress = _newOwnerAddress;
    }

    function acceptOwnership() public onlyPendingOwner {
        _revokeRole(OWNER_ROLE, ownerAddress);
        ownerAddress = pendingOwnerAddress;
        _grantRole(OWNER_ROLE, ownerAddress);
    }

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }
}