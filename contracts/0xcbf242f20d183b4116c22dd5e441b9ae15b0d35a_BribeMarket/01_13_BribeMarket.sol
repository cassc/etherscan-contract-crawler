// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IBribeVault} from "./interfaces/IBribeVault.sol";
import {Common} from "./libraries/Common.sol";
import {Errors} from "./libraries/Errors.sol";

contract BribeMarket is AccessControl, ReentrancyGuard {
    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

    uint256 public constant MAX_PERIODS = 10;
    uint256 public constant MAX_PERIOD_DURATION = 30 days;

    // Name (identifier) of the market, also used for rewardIdentifiers
    // Immutable after initialization
    string public PROTOCOL;

    // Address of the bribeVault
    // Immutable after initialization
    address public BRIBE_VAULT;

    // Maximum number of periods
    uint256 public maxPeriods;

    // Period duration
    uint256 public periodDuration;

    // Whitelisted bribe tokens
    address[] private _allWhitelistedTokens;

    // Blacklisted voters
    address[] private _allBlacklistedVoters;

    // Arbitrary bytes mapped to deadlines
    mapping(bytes32 => uint256) public proposalDeadlines;

    // Tracks whitelisted tokens
    mapping(address => uint256) public indexOfWhitelistedToken;

    // Tracks blacklisted voters
    mapping(address => uint256) public indexOfBlacklistedVoter;

    bool private _initialized;

    event Initialize(
        address bribeVault,
        address admin,
        string protocol,
        uint256 maxPeriods,
        uint256 periodDuration
    );
    event GrantTeamRole(address teamMember);
    event RevokeTeamRole(address teamMember);
    event SetProposals(bytes32[] proposals, uint256 indexed deadline);
    event SetProposalsById(
        uint256 indexed proposalIndex,
        bytes32[] proposals,
        uint256 indexed deadline
    );
    event SetProposalsByAddress(bytes32[] proposals, uint256 indexed deadline);
    event AddWhitelistedTokens(address[] tokens);
    event RemoveWhitelistedTokens(address[] tokens);
    event SetMaxPeriods(uint256 maxPeriods);
    event SetPeriodDuration(uint256 periodDuration);
    event AddBlacklistedVoters(address[] voters);
    event RemoveBlacklistedVoters(address[] voters);

    modifier onlyAuthorized() {
        if (
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) &&
            !hasRole(TEAM_ROLE, msg.sender)
        ) revert Errors.NotAuthorized();
        _;
    }

    modifier onlyInitializer() {
        if (_initialized) revert Errors.AlreadyInitialized();
        _;
        _initialized = true;
    }

    /**
        @notice Initialize the contract
        @param  _bribeVault  Bribe vault address
        @param  _admin       Admin address
        @param  _protocol    Protocol name
        @param  _maxPeriods  Maximum number of periods
        @param  _periodDuration  Period duration
     */
    function initialize(
        address _bribeVault,
        address _admin,
        string calldata _protocol,
        uint256 _maxPeriods,
        uint256 _periodDuration
    ) external onlyInitializer {
        if (_bribeVault == address(0)) revert Errors.InvalidAddress();
        if (bytes(_protocol).length == 0) revert Errors.InvalidProtocol();
        if (_maxPeriods == 0 || _maxPeriods > MAX_PERIODS)
            revert Errors.InvalidMaxPeriod();
        if (_periodDuration == 0 || _periodDuration > MAX_PERIOD_DURATION)
            revert Errors.InvalidPeriodDuration();

        BRIBE_VAULT = _bribeVault;
        PROTOCOL = _protocol;
        maxPeriods = _maxPeriods;
        periodDuration = _periodDuration;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        emit Initialize(
            _bribeVault,
            _admin,
            _protocol,
            _maxPeriods,
            _periodDuration
        );
    }

    /**
        @notice Set multiple proposals with arbitrary bytes data as identifiers under the same deadline
        @param  _identifiers  bytes[]  identifiers
        @param  _deadline     uint256  Proposal deadline
     */
    function setProposals(
        bytes[] calldata _identifiers,
        uint256 _deadline
    ) external onlyAuthorized {
        uint256 identifiersLen = _identifiers.length;
        if (identifiersLen == 0) revert Errors.InvalidAddress();
        if (_deadline < block.timestamp) revert Errors.InvalidDeadline();

        bytes32[] memory proposalIds = new bytes32[](identifiersLen);

        uint256 i;
        do {
            if (_identifiers[i].length == 0) revert Errors.InvalidIdentifier();

            proposalIds[i] = keccak256(abi.encodePacked(_identifiers[i]));

            _setProposal(proposalIds[i], _deadline);

            ++i;
        } while (i < identifiersLen);

        emit SetProposals(proposalIds, _deadline);
    }

    /**
        @notice Set proposals based on the index of the proposal and the number of choices
        @param  _proposalIndex  uint256  Proposal index
        @param  _choiceCount    uint256  Number of choices to be voted for
        @param  _deadline       uint256  Proposal deadline
     */
    function setProposalsById(
        uint256 _proposalIndex,
        uint256 _choiceCount,
        uint256 _deadline
    ) external onlyAuthorized {
        if (_choiceCount == 0) revert Errors.InvalidChoiceCount();
        if (_deadline < block.timestamp) revert Errors.InvalidDeadline();

        bytes32[] memory proposalIds = new bytes32[](_choiceCount);

        uint256 i;
        do {
            proposalIds[i] = keccak256(abi.encodePacked(_proposalIndex, i));

            _setProposal(proposalIds[i], _deadline);

            ++i;
        } while (i < _choiceCount);

        emit SetProposalsById(_proposalIndex, proposalIds, _deadline);
    }

    /**
        @notice Set multiple proposals for many addresses under the same deadline
        @param  _addresses  address[]  addresses (eg. gauge addresses)
        @param  _deadline   uint256    Proposal deadline
     */
    function setProposalsByAddress(
        address[] calldata _addresses,
        uint256 _deadline
    ) external onlyAuthorized {
        uint256 addressesLen = _addresses.length;
        if (addressesLen == 0) revert Errors.InvalidAddress();
        if (_deadline < block.timestamp) revert Errors.InvalidDeadline();

        bytes32[] memory proposalIds = new bytes32[](addressesLen);

        uint256 i;
        do {
            if (_addresses[i] == address(0)) revert Errors.InvalidAddress();

            proposalIds[i] = keccak256(abi.encodePacked(_addresses[i]));

            _setProposal(proposalIds[i], _deadline);

            ++i;
        } while (i < addressesLen);

        emit SetProposalsByAddress(proposalIds, _deadline);
    }

    /**
        @notice Grant the team role to an address
        @param  _teamMember  address  Address to grant the teamMember role
     */
    function grantTeamRole(
        address _teamMember
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_teamMember == address(0)) revert Errors.InvalidAddress();
        _grantRole(TEAM_ROLE, _teamMember);

        emit GrantTeamRole(_teamMember);
    }

    /**
        @notice Revoke the team role from an address
        @param  _teamMember  address  Address to revoke the teamMember role
     */
    function revokeTeamRole(
        address _teamMember
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!hasRole(TEAM_ROLE, _teamMember)) revert Errors.NotTeamMember();
        _revokeRole(TEAM_ROLE, _teamMember);

        emit RevokeTeamRole(_teamMember);
    }

    /**
        @notice Set maximum periods for submitting bribes ahead of time
        @param  _periods  uint256  Maximum periods
     */
    function setMaxPeriods(
        uint256 _periods
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_periods == 0 || _periods > MAX_PERIODS)
            revert Errors.InvalidMaxPeriod();

        maxPeriods = _periods;

        emit SetMaxPeriods(_periods);
    }

    /**
        @notice Set period duration per voting round
        @param  _periodDuration  uint256  Period duration
     */
    function setPeriodDuration(
        uint256 _periodDuration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_periodDuration == 0 || _periodDuration > MAX_PERIOD_DURATION)
            revert Errors.InvalidPeriodDuration();

        periodDuration = _periodDuration;

        emit SetPeriodDuration(_periodDuration);
    }

    /**
        @notice Add whitelisted tokens
        @param  _tokens  address[]  Tokens to add to whitelist
     */
    function addWhitelistedTokens(
        address[] calldata _tokens
    ) external onlyAuthorized {
        uint256 tLen = _tokens.length;
        for (uint256 i; i < tLen; ) {
            if (_tokens[i] == address(0)) revert Errors.InvalidAddress();
            if (_tokens[i] == BRIBE_VAULT)
                revert Errors.NoWhitelistBribeVault();
            if (isWhitelistedToken(_tokens[i]))
                revert Errors.TokenWhitelisted();

            // Perform creation op for the unordered key set
            _allWhitelistedTokens.push(_tokens[i]);
            indexOfWhitelistedToken[_tokens[i]] =
                _allWhitelistedTokens.length -
                1;

            unchecked {
                ++i;
            }
        }

        emit AddWhitelistedTokens(_tokens);
    }

    /**
        @notice Remove whitelisted tokens
        @param  _tokens  address[]  Tokens to remove from whitelist
     */
    function removeWhitelistedTokens(
        address[] calldata _tokens
    ) external onlyAuthorized {
        uint256 tLen = _tokens.length;
        for (uint256 i; i < tLen; ) {
            if (!isWhitelistedToken(_tokens[i]))
                revert Errors.TokenNotWhitelisted();

            // Perform deletion op for the unordered key set
            // by swapping the affected row to the end/tail of the list
            uint256 index = indexOfWhitelistedToken[_tokens[i]];
            address tail = _allWhitelistedTokens[
                _allWhitelistedTokens.length - 1
            ];

            _allWhitelistedTokens[index] = tail;
            indexOfWhitelistedToken[tail] = index;

            delete indexOfWhitelistedToken[_tokens[i]];
            _allWhitelistedTokens.pop();

            unchecked {
                ++i;
            }
        }

        emit RemoveWhitelistedTokens(_tokens);
    }

    /**
        @notice Add blacklisted voters
        @param  _voters  address[]  Voters to add to blacklist
     */
    function addBlacklistedVoters(
        address[] calldata _voters
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 vLen = _voters.length;
        for (uint256 i; i < vLen; ) {
            if (_voters[i] == address(0)) revert Errors.InvalidAddress();
            if (isBlacklistedVoter(_voters[i]))
                revert Errors.VoterBlacklisted();

            _allBlacklistedVoters.push(_voters[i]);
            indexOfBlacklistedVoter[_voters[i]] =
                _allBlacklistedVoters.length -
                1;

            unchecked {
                ++i;
            }
        }

        emit AddBlacklistedVoters(_voters);
    }

    /**
        @notice Remove blacklisted voters
        @param  _voters  address[]  Voters to remove from blacklist
     */
    function removeBlacklistedVoters(
        address[] calldata _voters
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 vLen = _voters.length;
        for (uint256 i; i < vLen; ) {
            if (!isBlacklistedVoter(_voters[i]))
                revert Errors.VoterNotBlacklisted();

            // Perform deletion op for the unordered key set
            // by swapping the affected row to the end/tail of the list
            uint256 index = indexOfBlacklistedVoter[_voters[i]];
            address tail = _allBlacklistedVoters[
                _allBlacklistedVoters.length - 1
            ];

            _allBlacklistedVoters[index] = tail;
            indexOfBlacklistedVoter[tail] = index;

            delete indexOfBlacklistedVoter[_voters[i]];
            _allBlacklistedVoters.pop();

            unchecked {
                ++i;
            }
        }

        emit RemoveBlacklistedVoters(_voters);
    }

    /**
        @notice Deposit bribe for a proposal (ERC20 tokens only)
        @param  _proposal          bytes32  Proposal
        @param  _token             address  Token
        @param  _amount            uint256  Token amount
        @param  _maxTokensPerVote  uint256  Max amount of token per vote
        @param  _periods           uint256  Number of periods the bribe will be valid
     */
    function depositBribe(
        bytes32 _proposal,
        address _token,
        uint256 _amount,
        uint256 _maxTokensPerVote,
        uint256 _periods
    ) external nonReentrant {
        _depositBribe(
            _proposal,
            _token,
            _amount,
            _maxTokensPerVote,
            _periods,
            0,
            ""
        );
    }

    /**
        @notice Deposit bribe for a proposal (ERC20 tokens only) using permit
        @param  _proposal          bytes32  Proposal
        @param  _token             address  Token
        @param  _amount            uint256  Token amount
        @param  _maxTokensPerVote  uint256  Max amount of token per vote
        @param  _periods           uint256  Number of periods the bribe will be valid
        @param  _permitDeadline    uint256  Deadline for permit signature
        @param  _signature         bytes    Permit signature
     */
    function depositBribeWithPermit(
        bytes32 _proposal,
        address _token,
        uint256 _amount,
        uint256 _maxTokensPerVote,
        uint256 _periods,
        uint256 _permitDeadline,
        bytes memory _signature
    ) external nonReentrant {
        _depositBribe(
            _proposal,
            _token,
            _amount,
            _maxTokensPerVote,
            _periods,
            _permitDeadline,
            _signature
        );
    }

    /**
        @notice Return the list of currently whitelisted token addresses
     */
    function getWhitelistedTokens() external view returns (address[] memory) {
        return _allWhitelistedTokens;
    }

    /**
        @notice Return the list of currently blacklisted voter addresses
     */
    function getBlacklistedVoters() external view returns (address[] memory) {
        return _allBlacklistedVoters;
    }

    /**
        @notice Get bribe from BribeVault
        @param  _proposal          bytes32  Proposal
        @param  _proposalDeadline  uint256  Proposal deadline
        @param  _token             address  Token
        @return bribeToken         address  Token address
        @return bribeAmount        address  Token amount
     */
    function getBribe(
        bytes32 _proposal,
        uint256 _proposalDeadline,
        address _token
    ) external view returns (address bribeToken, uint256 bribeAmount) {
        (bribeToken, bribeAmount) = IBribeVault(BRIBE_VAULT).getBribe(
            keccak256(
                abi.encodePacked(
                    address(this),
                    _proposal,
                    _proposalDeadline,
                    _token
                )
            )
        );
    }

    /**
        @notice Return whether the specified token is whitelisted
        @param  _token  address Token address to be checked
     */
    function isWhitelistedToken(address _token) public view returns (bool) {
        if (_allWhitelistedTokens.length == 0) {
            return false;
        }

        return
            indexOfWhitelistedToken[_token] != 0 ||
            _allWhitelistedTokens[0] == _token;
    }

    /**
        @notice Return whether the specified address is blacklisted
        @param  _voter  address Voter address to be checked
     */
    function isBlacklistedVoter(address _voter) public view returns (bool) {
        if (_allBlacklistedVoters.length == 0) {
            return false;
        }

        return
            indexOfBlacklistedVoter[_voter] != 0 ||
            _allBlacklistedVoters[0] == _voter;
    }

    /**
        @notice Deposit bribe for a proposal (ERC20 tokens only) with optional permit parameters
        @param  _proposal          bytes32  Proposal
        @param  _token             address  Token
        @param  _amount            uint256  Token amount
        @param  _maxTokensPerVote  uint256  Max amount of token per vote
        @param  _periods           uint256  Number of periods the bribe will be valid
        @param  _permitDeadline    uint256  Deadline for permit signature
        @param  _signature         bytes    Permit signature
     */
    function _depositBribe(
        bytes32 _proposal,
        address _token,
        uint256 _amount,
        uint256 _maxTokensPerVote,
        uint256 _periods,
        uint256 _permitDeadline,
        bytes memory _signature
    ) internal {
        uint256 proposalDeadline = proposalDeadlines[_proposal];
        if (proposalDeadline < block.timestamp) revert Errors.DeadlinePassed();
        if (_periods == 0 || _periods > maxPeriods)
            revert Errors.InvalidPeriod();
        if (_token == address(0)) revert Errors.InvalidAddress();
        if (!isWhitelistedToken(_token)) revert Errors.TokenNotWhitelisted();
        if (_amount == 0) revert Errors.InvalidAmount();

        IBribeVault(BRIBE_VAULT).depositBribe(
            Common.DepositBribeParams({
                proposal: _proposal,
                token: _token,
                briber: msg.sender,
                amount: _amount,
                maxTokensPerVote: _maxTokensPerVote,
                periods: _periods,
                periodDuration: periodDuration,
                proposalDeadline: proposalDeadline,
                permitDeadline: _permitDeadline,
                signature: _signature
            })
        );
    }

    /**
        @notice Set a single proposal
        @param  _proposal  bytes32  Proposal
        @param  _deadline  uint256  Proposal deadline
     */
    function _setProposal(bytes32 _proposal, uint256 _deadline) internal {
        proposalDeadlines[_proposal] = _deadline;
    }
}