// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

//  =============================================
//   _   _  _  _  _  ___  ___  ___  ___ _    ___
//  | \_/ || || \| ||_ _|| __|| __|| o ) |  | __|
//  | \_/ || || \\ | | | | _| | _| | o \ |_ | _|
//  |_| |_||_||_|\_| |_| |___||___||___/___||___|
//
//  Website: https://minteeble.com
//  Email: [email protected]
//
//  =============================================

interface IReferralSystem {
    /// @dev Struct representing a Rank, so a list of percentages for levels
    struct Rank {
        uint256[] levels;
        uint256 score;
    }

    /// @dev Struct representing a RefInfo, so a model used when asking info
    /// for a specific acount referral hierarchy
    struct RefInfo {
        address account;
        uint256 percentage;
    }

    function getRefInfo(address _account)
        external
        view
        returns (RefInfo[] memory);

    function inviterOf(address _account) external view returns (address);

    function accountRankOf(address _account) external view returns (uint256);

    function ranksLength() external view returns (uint256);

    function addRank() external;

    function removeRank() external;

    function setRankScoreLimit(uint256 _rankIndex, uint256 _newScore) external;

    function addLevel(uint256 _rankIndex, uint256 _percentage) external;

    function editLevel(
        uint256 _rankIndex,
        uint256 _levelIndex,
        uint256 _percentage
    ) external;

    function removeLevel(uint256 _rankIndex) external;

    function getLevels(uint256 _rankIndex)
        external
        view
        returns (uint256[] memory);

    function setAccountRank(address _account, uint256 _rankIndex) external;

    function setInvitation(address _inviter, address _invitee) external;

    function addAction(address _account) external returns (RefInfo[] memory);

    function hasInviter(address _account) external view returns (bool);
}

/// @title A multi-level referral system contract
/// @notice The ReferralSystem contract can handle a multi-level scenario.
/// Each level is characterized by a percentage. Also it is possible to create multiple ranks, each of
/// which with a different levels structure.
/// @dev The contract is meant to be used inside another contract (owner)
contract ReferralSystem is AccessControlEnumerable, IReferralSystem {
    /// @notice Inviter role
    bytes32 public constant INVITER_ROLE = keccak256("INVITER_ROLE");

    mapping(address => address) internal inviter;
    mapping(address => uint256) internal accountRank;
    Rank[] internal ranks;

    event RefAction(address _from, address indexed _to, uint256 _percentage);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier isValidAccountAddress(address _account) {
        require(
            _account != address(0) && _account != address(this),
            "Invalid account"
        );
        _;
    }

    modifier isValidRankIndex(uint256 _rankIndex) {
        require(_rankIndex < ranks.length, "Invalid rank index");
        _;
    }

    modifier isValidLevelIndex(uint256 _rankIndex, uint256 _levelIndex) {
        require(_rankIndex < ranks.length, "Invalid rank index");
        require(
            _levelIndex < ranks[_rankIndex].levels.length,
            "Invalid level index"
        );
        _;
    }

    modifier requireAdmin(address _account) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _account), "Unauthorized");
        _;
    }

    modifier requireInviterOrHigher(address _account) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(INVITER_ROLE, msg.sender),
            "Unauthorized"
        );
        _;
    }

    /// @notice Gets the number of available ranks
    /// @return Number of available ranks inside the system
    function ranksLength() public view returns (uint256) {
        return ranks.length;
    }

    /// @notice Adds a new empty rank
    function addRank() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256[] memory levels;

        ranks.push(Rank(levels, 0));
    }

    /// @notice Removes the last rank
    function removeRank() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(ranks.length > 0, "No ranks available");

        // Remove rank from top
        ranks.pop();
    }

    function setRankScoreLimit(uint256 _rankIndex, uint256 _newScore)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ranks[_rankIndex].score = _newScore;
    }

    /// @notice Adds a new level for the specified rank
    /// @param _rankIndex Index of the rank to add the level to
    /// @param _percentage Referral percentage of the level to be created
    function addLevel(uint256 _rankIndex, uint256 _percentage)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        isValidRankIndex(_rankIndex)
    {
        ranks[_rankIndex].levels.push(_percentage);
    }

    /// @notice Edits the percentage of an existing level
    /// @param _rankIndex Index of the rank to be edited
    /// @param _levelIndex Index of the level to be edited
    /// @param _percentage New level percentage
    function editLevel(
        uint256 _rankIndex,
        uint256 _levelIndex,
        uint256 _percentage
    )
        public
        requireAdmin(msg.sender)
        isValidLevelIndex(_rankIndex, _levelIndex)
    {
        ranks[_rankIndex].levels[_levelIndex] = _percentage;
    }

    /// @notice Removes the last level of the specified Rank
    /// @param _rankIndex Index of the rank to be removed
    function removeLevel(uint256 _rankIndex)
        public
        requireAdmin(msg.sender)
        isValidRankIndex(_rankIndex)
    {
        require(ranks[_rankIndex].levels.length > 0, "No levels available");

        ranks[_rankIndex].levels.pop();
    }

    /// @notice Gets the levels belonging to the specified Rank
    /// @param _rankIndex Index of the rank to get levels from
    /// @return List of levels
    function getLevels(uint256 _rankIndex)
        public
        view
        requireAdmin(msg.sender)
        isValidRankIndex(_rankIndex)
        returns (uint256[] memory)
    {
        return ranks[_rankIndex].levels;
    }

    function inviterOf(address _account) public view returns (address) {
        return inviter[_account];
    }

    function accountRankOf(address _account)
        public
        view
        virtual
        returns (uint256)
    {
        return accountRank[_account];
    }

    /// @notice Method to manually set the account rank
    /// @param _account Account address
    /// @param _rankIndex Index of the rank to be set
    function setAccountRank(address _account, uint256 _rankIndex)
        public
        requireAdmin(msg.sender)
        isValidRankIndex(_rankIndex)
    {
        accountRank[_account] = _rankIndex;
    }

    function _setInvitation(address _inviter, address _invitee)
        internal
        isValidAccountAddress(_inviter)
        isValidAccountAddress(_invitee)
    {
        require(
            inviter[_invitee] == address(0x0),
            "Invitee has already an inviter"
        );
        require(
            _inviter != _invitee,
            "Inviter and invitee are the same address"
        );

        inviter[_invitee] = _inviter;
        // accountRank[_invitee] = accountRankOf(_inviter);
    }

    /// @notice Creates the invitation (relationship) between inviter and invitee.
    /// The invitee inherits the inviter's rank
    /// @param _inviter Inviter address
    /// @param _invitee Invitee address
    function setInvitation(address _inviter, address _invitee)
        public
        virtual
        requireInviterOrHigher(msg.sender)
    {
        _setInvitation(_inviter, _invitee);
    }

    function _addAction(address _account)
        internal
        virtual
        returns (RefInfo[] memory)
    {
        require(inviter[_account] != address(0x0), "Account has not inviter");

        RefInfo[] memory refInfo = getRefInfo(_account);

        for (uint256 i = 0; i < refInfo.length; i++) {
            emit RefAction(_account, refInfo[i].account, refInfo[i].percentage);
        }

        return refInfo;
    }

    /// @notice Adds a new referral action into the system
    /// @dev Emits the events for each account above the one provided
    /// @param _account Account address that is committing the action
    /// @return The list of referral info for all the accounts above the one provided
    function addAction(address _account)
        public
        virtual
        requireAdmin(msg.sender)
        returns (RefInfo[] memory)
    {
        return _addAction(_account);
    }

    /// @notice Checks if the specified address has an inviter or not
    /// @param _account Account address to be checked
    /// @return True if account has inviter, false otherwise
    function hasInviter(address _account) public view returns (bool) {
        return inviter[_account] != address(0);
    }

    /// @notice Gets the list of Referral actions
    /// @param _account Account to read info from
    /// @return List of referral actions, so the information about the
    /// levels and percentages above the current account
    function getRefInfo(address _account)
        public
        view
        returns (RefInfo[] memory)
    {
        uint256 maxDepth = 10;
        RefInfo[] memory refInfo = new RefInfo[](maxDepth);

        address currentAccount = _account;
        uint256 accountsFound = 0;

        for (
            uint256 currentDepth = 1;
            currentDepth <= maxDepth;
            currentDepth++
        ) {
            address inviterAddr = inviter[currentAccount];

            if (inviterAddr != address(0)) {
                uint256 rankIndex = accountRankOf(inviterAddr);
                uint256 rankDepth = ranks[rankIndex].levels.length;

                if (rankDepth > 0 && currentDepth <= rankDepth) {
                    refInfo[accountsFound] = RefInfo(
                        inviterAddr,
                        ranks[rankIndex].levels[currentDepth - 1]
                    );

                    accountsFound++;
                }

                currentAccount = inviterAddr;
            } else {
                break;
            }
        }

        RefInfo[] memory refInfoFound = new RefInfo[](accountsFound);

        for (
            uint256 levelIndex = 0;
            levelIndex < refInfoFound.length;
            ++levelIndex
        ) {
            refInfoFound[levelIndex] = refInfo[levelIndex];
        }

        return refInfoFound;
    }
}