// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IBribeVault} from "./interfaces/IBribeVault.sol";

contract BribeBase is AccessControl, ReentrancyGuard {
    address public immutable BRIBE_VAULT;
    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

    // Used for generating the bribe and reward identifiers
    bytes32 public immutable PROTOCOL;

    // Arbitrary bytes mapped to deadlines
    mapping(bytes32 => uint256) public proposalDeadlines;

    // Voter addresses mapped to addresses which will claim rewards on their behalf
    mapping(address => address) public rewardForwarding;

    // Tracks whitelisted tokens
    mapping(address => uint256) public indexOfWhitelistedToken;
    address[] public allWhitelistedTokens;

    event GrantTeamRole(address teamMember);
    event RevokeTeamRole(address teamMember);
    event SetProposal(bytes32 indexed proposal, uint256 deadline);
    event DepositBribe(
        bytes32 indexed proposal,
        address indexed token,
        uint256 amount,
        bytes32 bribeIdentifier,
        bytes32 rewardIdentifier,
        address indexed briber
    );
    event SetRewardForwarding(address from, address to);
    event AddWhitelistTokens(address[] tokens);
    event RemoveWhitelistTokens(address[] tokens);

    constructor(address _BRIBE_VAULT, string memory _PROTOCOL) {
        require(_BRIBE_VAULT != address(0), "Invalid _BRIBE_VAULT");
        BRIBE_VAULT = _BRIBE_VAULT;

        require(bytes(_PROTOCOL).length != 0, "Invalid _PROTOCOL");
        PROTOCOL = keccak256(abi.encodePacked(_PROTOCOL));

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyAuthorized() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(TEAM_ROLE, msg.sender),
            "Not authorized"
        );
        _;
    }

    /**
        @notice Grant the team role to an address
        @param  teamMember  address  Address to grant the teamMember role
     */
    function grantTeamRole(address teamMember)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(teamMember != address(0), "Invalid teamMember");
        _grantRole(TEAM_ROLE, teamMember);

        emit GrantTeamRole(teamMember);
    }

    /**
        @notice Revoke the team role from an address
        @param  teamMember  address  Address to revoke the teamMember role
     */
    function revokeTeamRole(address teamMember)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(hasRole(TEAM_ROLE, teamMember), "Invalid teamMember");
        _revokeRole(TEAM_ROLE, teamMember);

        emit RevokeTeamRole(teamMember);
    }

    /**
        @notice Return the list of currently whitelisted token addresses
     */
    function getWhitelistedTokens() external view returns (address[] memory) {
        return allWhitelistedTokens;
    }

    /**
        @notice Return whether the specified token is whitelisted
        @param  token  address Token address to be checked
     */
    function isWhitelistedToken(address token) public view returns (bool) {
        if (allWhitelistedTokens.length == 0) {
            return false;
        }

        return
            indexOfWhitelistedToken[token] != 0 ||
            allWhitelistedTokens[0] == token;
    }

    /**
        @notice Add whitelist tokens
        @param  tokens  address[]  Tokens to add to whitelist
     */
    function addWhitelistTokens(address[] calldata tokens)
        external
        onlyAuthorized
    {
        for (uint256 i; i < tokens.length; ++i) {
            require(tokens[i] != address(0), "Invalid token");
            require(tokens[i] != BRIBE_VAULT, "Cannot whitelist BRIBE_VAULT");
            require(
                !isWhitelistedToken(tokens[i]),
                "Token already whitelisted"
            );

            // Perform creation op for the unordered key set
            allWhitelistedTokens.push(tokens[i]);
            indexOfWhitelistedToken[tokens[i]] =
                allWhitelistedTokens.length -
                1;
        }

        emit AddWhitelistTokens(tokens);
    }

    /**
        @notice Remove whitelist tokens
        @param  tokens  address[]  Tokens to remove from whitelist
     */
    function removeWhitelistTokens(address[] calldata tokens)
        external
        onlyAuthorized
    {
        for (uint256 i; i < tokens.length; ++i) {
            require(isWhitelistedToken(tokens[i]), "Token not whitelisted");

            // Perform deletion op for the unordered key set
            // by swapping the affected row to the end/tail of the list
            uint256 index = indexOfWhitelistedToken[tokens[i]];
            address tail = allWhitelistedTokens[
                allWhitelistedTokens.length - 1
            ];

            allWhitelistedTokens[index] = tail;
            indexOfWhitelistedToken[tail] = index;

            delete indexOfWhitelistedToken[tokens[i]];
            allWhitelistedTokens.pop();
        }

        emit RemoveWhitelistTokens(tokens);
    }

    /**
        @notice Set a single proposal
        @param  proposal  bytes32  Proposal
        @param  deadline  uint256  Proposal deadline
     */
    function _setProposal(bytes32 proposal, uint256 deadline) internal {
        require(proposal != bytes32(0), "Invalid proposal");
        require(deadline > block.timestamp, "Deadline must be in the future");

        proposalDeadlines[proposal] = deadline;

        emit SetProposal(proposal, deadline);
    }

    /**
        @notice Generate the BribeVault identifier based on a scheme
        @param  proposal          bytes32  Proposal
        @param  proposalDeadline  uint256  Proposal deadline
        @param  token             address  Token
        @return identifier        bytes32  BribeVault identifier
     */
    function generateBribeVaultIdentifier(
        bytes32 proposal,
        uint256 proposalDeadline,
        address token
    ) public view returns (bytes32 identifier) {
        return
            keccak256(
                abi.encodePacked(PROTOCOL, proposal, proposalDeadline, token)
            );
    }

    /**
        @notice Generate the reward identifier based on a scheme
        @param  proposalDeadline  uint256  Proposal deadline
        @param  token             address  Token
        @return identifier        bytes32  Reward identifier
     */
    function generateRewardIdentifier(uint256 proposalDeadline, address token)
        public
        view
        returns (bytes32 identifier)
    {
        return keccak256(abi.encodePacked(PROTOCOL, proposalDeadline, token));
    }

    /**
        @notice Get bribe from BribeVault
        @param  proposal          bytes32  Proposal
        @param  proposalDeadline  uint256  Proposal deadline
        @param  token             address  Token
        @return bribeToken        address  Token address
        @return bribeAmount       address  Token amount
     */
    function getBribe(
        bytes32 proposal,
        uint256 proposalDeadline,
        address token
    ) external view returns (address bribeToken, uint256 bribeAmount) {
        return
            IBribeVault(BRIBE_VAULT).getBribe(
                generateBribeVaultIdentifier(proposal, proposalDeadline, token)
            );
    }

    /**
        @notice Deposit bribe for a proposal (ERC20 tokens only)
        @param  proposal  bytes32  Proposal
        @param  token     address  Token
        @param  amount    uint256  Token amount
     */
    function depositBribeERC20(
        bytes32 proposal,
        address token,
        uint256 amount
    ) external nonReentrant {
        uint256 proposalDeadline = proposalDeadlines[proposal];
        require(
            proposalDeadlines[proposal] > block.timestamp,
            "Proposal deadline has passed"
        );
        require(token != address(0), "Invalid token");
        require(isWhitelistedToken(token), "Token is not whitelisted");
        require(amount != 0, "Bribe amount must be greater than 0");

        bytes32 bribeIdentifier = generateBribeVaultIdentifier(
            proposal,
            proposalDeadline,
            token
        );
        bytes32 rewardIdentifier = generateRewardIdentifier(
            proposalDeadline,
            token
        );

        IBribeVault(BRIBE_VAULT).depositBribeERC20(
            bribeIdentifier,
            rewardIdentifier,
            token,
            amount,
            msg.sender
        );

        emit DepositBribe(
            proposal,
            token,
            amount,
            bribeIdentifier,
            rewardIdentifier,
            msg.sender
        );
    }

    /**
        @notice Deposit bribe for a proposal (native token only)
        @param  proposal  bytes32  Proposal
     */
    function depositBribe(bytes32 proposal) external payable nonReentrant {
        uint256 proposalDeadline = proposalDeadlines[proposal];
        require(
            proposalDeadlines[proposal] > block.timestamp,
            "Proposal deadline has passed"
        );
        require(msg.value != 0, "Bribe amount must be greater than 0");

        bytes32 bribeIdentifier = generateBribeVaultIdentifier(
            proposal,
            proposalDeadline,
            BRIBE_VAULT
        );
        bytes32 rewardIdentifier = generateRewardIdentifier(
            proposalDeadline,
            BRIBE_VAULT
        );

        // NOTE: Native token bribes have BRIBE_VAULT set as the address
        IBribeVault(BRIBE_VAULT).depositBribe{value: msg.value}(
            bribeIdentifier,
            rewardIdentifier,
            msg.sender
        );

        emit DepositBribe(
            proposal,
            BRIBE_VAULT,
            msg.value,
            bribeIdentifier,
            rewardIdentifier,
            msg.sender
        );
    }

    /**
        @notice Voters can opt in or out of reward-forwarding
        @notice Opt-in: A voter sets another address to forward rewards to
        @notice Opt-out: A voter sets their own address or the zero address
        @param  to  address  Account that rewards will be sent to
     */
    function setRewardForwarding(address to) external {
        rewardForwarding[msg.sender] = to;

        emit SetRewardForwarding(msg.sender, to);
    }
}