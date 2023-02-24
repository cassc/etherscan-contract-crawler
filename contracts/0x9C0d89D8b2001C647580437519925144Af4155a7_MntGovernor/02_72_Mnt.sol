// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./MntVotes.sol";
import "../libraries/ErrorCodes.sol";
import "../InterconnectorLeaf.sol";
import "../interfaces/IMnt.sol";
import "../interfaces/IWeightAggregator.sol";

contract Mnt is IMnt, MntVotes, AccessControlUpgradeable, InterconnectorLeaf {
    /// @notice Total number of tokens in circulation
    uint256 internal constant TOTAL_SUPPLY = 65_902_270e18; // 65,902,270 MNT

    address public governor;

    mapping(address => uint256) public votingWeight;
    uint256 public totalVotingWeight;

    constructor() {
        _disableInitializers();
    }

    function initialize(address holder, address owner) public initializer {
        __ERC20_init("Minterest", "MNT");
        __ERC20Permit_init("Minterest");
        __ERC20Votes_init(365 days);

        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _mint(holder, TOTAL_SUPPLY);
    }

    /// @dev Hook that is called before any transfer of tokens
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal override {
        IInterconnector interconnector = getInterconnector();
        if (address(interconnector) != address(0)) {
            // this check required only if MNT interconnected with supervisor,
            // otherwise (for example on initial mint) it will be skipped
            require(interconnector.supervisor().isMntTransferAllowed(from, to), ErrorCodes.ADDRESS_IS_BLACKLISTED);
        }
    }

    /**
     * @dev Used to replace `balanceOf` method and pass stored voting power into parent MntVotes contract
     */
    function getStoredVotingPower(address account) internal view override returns (uint256) {
        return votingWeight[account];
    }

    function getStoredTotalVotingPower() internal view override returns (uint256) {
        return totalVotingWeight;
    }

    // // // // Vote updates

    /// @inheritdoc IMnt
    function updateVotingWeight(address account) external {
        require(account != address(0), ErrorCodes.ZERO_ADDRESS);

        uint256 oldWeight = getStoredVotingPower(account);
        uint256 newWeight = weightAggregator().getVotingWeight(account);
        if (newWeight == oldWeight) return;

        if (newWeight > oldWeight) {
            uint256 delta = newWeight - oldWeight;
            _moveVotingPower(address(0), delegates(account), delta);
            totalVotingWeight += delta;
        } else {
            uint256 delta = oldWeight - newWeight;
            _moveVotingPower(delegates(account), address(0), delta);
            totalVotingWeight -= delta;
        }

        votingWeight[account] = newWeight;

        emit VotesUpdated(account, oldWeight, newWeight);
    }

    /// @inheritdoc IMnt
    function updateTotalWeightCheckpoint() external {
        require(msg.sender == address(governor), ErrorCodes.UNAUTHORIZED);
        uint256 oldWeight = _pushTotalWeightCheckpoint();
        emit TotalVotesUpdated(oldWeight, totalVotingWeight);
    }

    // // // // Vote timestamp tracking

    /// @inheritdoc IMnt
    function isParticipantActive(address account_) public view virtual returns (bool) {
        return lastActivityTimestamp(account_) > block.timestamp - maxNonVotingPeriod;
    }

    /// @inheritdoc IMnt
    function updateVoteTimestamp(address account) external {
        require(msg.sender == address(governor), ErrorCodes.UNAUTHORIZED);
        voteTimestamps[account].voted = SafeCast.toUint32(block.timestamp);
    }

    /// @inheritdoc IMnt
    function lastActivityTimestamp(address account) public view virtual returns (uint256) {
        VoteTimestamps memory accountLast = voteTimestamps[account];

        // if the votes are not delegated to anyone, then return the timestamp of the last vote of the account
        address currentDelegate = delegates(account);
        if (currentDelegate == address(0)) return accountLast.voted;

        // if delegate voted after delegation then returns its vote timestamp, otherwise return accounts
        uint32 delegateLastVoted = voteTimestamps[currentDelegate].voted;
        return delegateLastVoted > accountLast.delegated ? delegateLastVoted : accountLast.voted;
    }

    function weightAggregator() internal view returns (IWeightAggregator) {
        return getInterconnector().weightAggregator();
    }

    // // // // Admin zone

    /// @inheritdoc IMnt
    function setGovernor(address newGovernor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(governor == address(0), ErrorCodes.SECOND_INITIALIZATION);
        require(newGovernor != address(0), ErrorCodes.ZERO_ADDRESS);
        governor = newGovernor;
        emit NewGovernor(newGovernor);
    }

    /// @inheritdoc IMnt
    function setMaxNonVotingPeriod(uint256 newPeriod_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newPeriod_ >= 90 days && newPeriod_ <= 2 * 365 days, ErrorCodes.MNT_INVALID_NONVOTING_PERIOD);

        uint256 oldPeriod = maxNonVotingPeriod;
        require(newPeriod_ != oldPeriod, ErrorCodes.IDENTICAL_VALUE);

        emit MaxNonVotingPeriodChanged(oldPeriod, newPeriod_);
        maxNonVotingPeriod = newPeriod_;
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(IERC165, AccessControlUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC20).interfaceId || // EIP-20 - 0x36372b07
            interfaceId == type(IERC20PermitUpgradeable).interfaceId || // EIP-2612 - 0x9d8ff7da
            interfaceId == type(IVotesUpgradeable).interfaceId; // OpenZeppelin Votes - 0xe90fb3f6
    }
}