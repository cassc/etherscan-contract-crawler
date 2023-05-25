// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Proxy} from "./Proxy.sol";
import {ENSHelper} from "../utils/ENSHelper.sol";
import {INounsDAOV2} from "../interfaces/INounsDAOV2.sol";
import {IRule} from "../interfaces/IRule.sol";
import "../interfaces/IAlligator.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract Alligator is IAlligator, ENSHelper, Ownable, Pausable {
    // =============================================================
    //                             ERRORS
    // =============================================================

    error BadSignature();
    error InvalidAuthorityChain();
    error NotDelegated(address from, address to, uint256 requiredPermissions);
    error TooManyRedelegations(address from, address to);
    error NotValidYet(address from, address to, uint256 willBeValidFrom);
    error NotValidAnymore(address from, address to, uint256 wasValidUntil);
    error TooEarly(address from, address to, uint256 blocksBeforeVoteCloses);
    error InvalidCustomRule(address from, address to, address customRule);

    // =============================================================
    //                       IMMUTABLE STORAGE
    // =============================================================

    INounsDAOV2 public immutable governor;

    uint256 internal constant PERMISSION_VOTE = 1;
    uint256 internal constant PERMISSION_SIGN = 1 << 1;
    uint256 internal constant PERMISSION_PROPOSE = 1 << 2;

    bytes32 internal constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    bytes32 internal constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");

    // =============================================================
    //                        MUTABLE STORAGE
    // =============================================================

    // From => To => Rules
    mapping(address => mapping(address => Rules)) public subDelegations;
    // Proxy address => hash => valid boolean
    mapping(address => mapping(bytes32 => bool)) internal validSignatures;

    // =============================================================
    //                         CONSTRUCTOR
    // =============================================================

    constructor(INounsDAOV2 _governor, string memory _ensName, bytes32 _ensNameHash) ENSHelper(_ensName, _ensNameHash) {
        governor = _governor;
    }

    // =============================================================
    //                       WRITE FUNCTIONS
    // =============================================================

    /**
     * @notice Deploy a new Proxy for an owner deterministically.
     *
     * @param owner The owner of the Proxy.
     * @param registerEnsName Whether to register the ENS name for the Proxy.
     *
     * @return endpoint Address of the Proxy
     */
    function create(address owner, bool registerEnsName) public returns (address endpoint) {
        endpoint = address(new Proxy{salt: bytes32(uint256(uint160(owner)))}(address(governor)));
        emit ProxyDeployed(owner, endpoint);

        if (registerEnsName) {
            if (ensNameHash != 0) {
                string memory reverseName = registerDeployment(endpoint);
                Proxy(payable(endpoint)).setENSReverseRecord(reverseName);
            }
        }
    }

    /**
     * @notice Register ENS name for an already deployed Proxy.
     *
     * @param owner The owner of the Proxy.
     *
     * @dev Reverts if the ENS name is already set.
     */
    function registerProxyDeployment(address owner) public {
        if (ensNameHash != 0) {
            address proxy = proxyAddress(owner);
            string memory reverseName = registerDeployment(proxy);
            Proxy(payable(proxy)).setENSReverseRecord(reverseName);
        }
    }

    /**
     * @notice Validate subdelegation rules and make a proposal to the governor.
     *
     * @param authority The authority chain to validate against.
     * @param targets Target addresses for proposal calls
     * @param values Eth values for proposal calls
     * @param signatures Function signatures for proposal calls
     * @param calldatas Calldatas for proposal calls
     * @param description String description of the proposal
     *
     * @return proposalId Proposal id of new proposal
     */
    function propose(
        address[] calldata authority,
        address[] calldata targets,
        uint256[] calldata values,
        string[] calldata signatures,
        bytes[] calldata calldatas,
        string calldata description
    ) external whenNotPaused returns (uint256 proposalId) {
        address proxy = proxyAddress(authority[0]);
        // Create a proposal first so the custom rules can validate it
        proposalId = INounsDAOV2(proxy).propose(targets, values, signatures, calldatas, description);
        validate(msg.sender, authority, PERMISSION_PROPOSE, proposalId, 0xFF);
    }

    /**
     * @notice Validate subdelegation rules and cast a vote on the governor.
     *
     * @param authority The authority chain to validate against.
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVote(address[] calldata authority, uint256 proposalId, uint8 support) external whenNotPaused {
        validate(msg.sender, authority, PERMISSION_VOTE, proposalId, support);

        address proxy = proxyAddress(authority[0]);
        INounsDAOV2(proxy).castVote(proposalId, support);
        emit VoteCast(proxy, msg.sender, authority, proposalId, support);
    }

    /**
     * @notice Validate subdelegation rules and cast a vote with reason on the governor.
     *
     * @param authority The authority chain to validate against.
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @param reason The reason given for the vote by the voter
     */
    function castVoteWithReason(
        address[] calldata authority,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public whenNotPaused {
        validate(msg.sender, authority, PERMISSION_VOTE, proposalId, support);

        address proxy = proxyAddress(authority[0]);
        INounsDAOV2(proxy).castVoteWithReason(proposalId, support, reason);
        emit VoteCast(proxy, msg.sender, authority, proposalId, support);
    }

    /**
     * @notice Validate subdelegation rules and cast multiple votes with reason on the governor.
     *
     * @param authorities The authority chains to validate against.
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @param reason The reason given for the vote by the voter
     */
    function castVotesWithReasonBatched(
        address[][] calldata authorities,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public whenNotPaused {
        uint256 authorityLength = authorities.length;
        address[] memory proxies = new address[](authorityLength);
        address[] memory authority;

        for (uint256 i; i < authorityLength; ) {
            authority = authorities[i];
            validate(msg.sender, authority, PERMISSION_VOTE, proposalId, support);
            proxies[i] = proxyAddress(authority[0]);
            INounsDAOV2(proxies[i]).castVoteWithReason(proposalId, support, reason);

            unchecked {
                ++i;
            }
        }

        emit VotesCast(proxies, msg.sender, authorities, proposalId, support);
    }

    /**
     * @notice Validate subdelegation rules and cast multiple refundable votes with reason on the governor.
     * Refunds the gas used to cast the votes up to a limit specified in `governor`.
     *
     * Note: The gas used will not be refunded for authority chains resulting in 0 votes cast.
     *
     * @param authorities The authority chains to validate against.
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @param reason The reason given for the vote by the voter
     */
    function castRefundableVotesWithReasonBatched(
        address[][] calldata authorities,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external whenNotPaused {
        uint256 authorityLength = authorities.length;
        address[] memory proxies = new address[](authorityLength);
        address[] memory authority;

        for (uint256 i; i < authorityLength; ) {
            authority = authorities[i];
            validate(msg.sender, authority, PERMISSION_VOTE, proposalId, support);
            proxies[i] = proxyAddress(authority[0]);
            INounsDAOV2(proxies[i]).castRefundableVoteWithReason(proposalId, support, reason);

            unchecked {
                ++i;
            }
        }

        emit VotesCast(proxies, msg.sender, authorities, proposalId, support);
    }

    /**
     * @notice Validate subdelegation rules and cast a vote by signature on the governor.
     *
     * @param authority The authority chain to validate against.
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVoteBySig(
        address[] calldata authority,
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256("Alligator"), block.chainid, address(this))
        );
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);

        if (signatory == address(0)) {
            revert BadSignature();
        }

        validate(signatory, authority, PERMISSION_VOTE, proposalId, support);

        address proxy = proxyAddress(authority[0]);
        INounsDAOV2(proxy).castVote(proposalId, support);
        emit VoteCast(proxy, signatory, authority, proposalId, support);
    }

    /**
     * @notice Validate subdelegation rules and sign a hash.
     *
     * @param authority The authority chain to validate against.
     * @param hash The hash to sign.
     */
    function sign(address[] calldata authority, bytes32 hash) external whenNotPaused {
        validate(msg.sender, authority, PERMISSION_SIGN, 0, 0xFE);

        address proxy = proxyAddress(authority[0]);
        validSignatures[proxy][hash] = true;
        emit Signed(proxy, authority, hash);
    }

    /**
     * @notice Subdelegate an address with rules.
     *
     * @param to The address to subdelegate to.
     * @param rules The rules to apply to the subdelegation.
     * @param createProxy Whether to create a Proxy for the sender, if one doesn't exist.
     */
    function subDelegate(address to, Rules calldata rules, bool createProxy) external {
        if (createProxy) {
            if (proxyAddress(msg.sender).code.length == 0) {
                create(msg.sender, false);
            }
        }

        subDelegations[msg.sender][to] = rules;
        emit SubDelegation(msg.sender, to, rules);
    }

    /**
     * @notice Subdelegate multiple addresses with rules.
     *
     * @param targets The addresses to subdelegate to.
     * @param rules The rules to apply to the subdelegations.
     * @param createProxy Whether to create a Proxy for the sender, if one doesn't exist.
     */
    function subDelegateBatched(address[] calldata targets, Rules[] calldata rules, bool createProxy) external {
        uint256 targetsLength = targets.length;
        require(targetsLength == rules.length);

        if (createProxy) {
            if (proxyAddress(msg.sender).code.length == 0) {
                create(msg.sender, false);
            }
        }

        for (uint256 i; i < targetsLength; ) {
            subDelegations[msg.sender][targets[i]] = rules[i];

            unchecked {
                ++i;
            }
        }

        emit SubDelegations(msg.sender, targets, rules);
    }

    /**
     * @notice Pauses and unpauses propose, vote and sign operations.
     *
     * @dev Only contract owner can toggle pause.
     */
    function _togglePause() external onlyOwner {
        if (!paused()) {
            _pause();
        } else {
            _unpause();
        }
    }

    // =============================================================
    //                         VIEW FUNCTIONS
    // =============================================================

    /**
     * @notice Validate subdelegation rules.
     *
     * @param sender The sender address to validate.
     * @param authority The authority chain to validate against.
     * @param permissions The permissions to validate.
     * @param proposalId The id of the proposal for which validation is being performed.
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain, 0xFF=proposal
     */
    function validate(
        address sender,
        address[] memory authority,
        uint256 permissions,
        uint256 proposalId,
        uint256 support
    ) public view {
        address from = authority[0];

        if (from == sender) {
            return;
        }

        uint256 authorityLength = authority.length;
        address to;
        Rules memory rules;

        /// @dev maxRedelegations would hit block size limit before overflowing
        /// @dev block.number + rules.blocksBeforeVoteCloses fits in uint256
        unchecked {
            for (uint256 i = 1; i < authorityLength; ++i) {
                to = authority[i];
                rules = subDelegations[from][to];

                if ((rules.permissions & permissions) != permissions) {
                    revert NotDelegated(from, to, permissions);
                }
                if (rules.maxRedelegations + i + 1 < authorityLength) {
                    revert TooManyRedelegations(from, to);
                }
                if (block.timestamp < rules.notValidBefore) {
                    revert NotValidYet(from, to, rules.notValidBefore);
                }
                if (rules.notValidAfter != 0) {
                    if (block.timestamp > rules.notValidAfter) revert NotValidAnymore(from, to, rules.notValidAfter);
                }
                if (rules.blocksBeforeVoteCloses != 0) {
                    INounsDAOV2.ProposalCondensed memory proposal = governor.proposals(proposalId);
                    if (proposal.endBlock > block.number + rules.blocksBeforeVoteCloses) {
                        revert TooEarly(from, to, rules.blocksBeforeVoteCloses);
                    }
                }
                if (rules.customRule != address(0)) {
                    if (
                        IRule(rules.customRule).validate(address(governor), sender, proposalId, uint8(support)) !=
                        IRule.validate.selector
                    ) {
                        revert InvalidCustomRule(from, to, rules.customRule);
                    }
                }

                from = to;
            }
        }

        if (from != sender) revert NotDelegated(from, sender, permissions);
    }

    /**
     * @notice Checks if proxy signature is valid.
     *
     * @param proxy The address of the proxy contract.
     * @param hash The hash to validate.
     * @param data The data to validate.
     *
     * @return magicValue `IERC1271.isValidSignature` if signature is valid, or 0 if not.
     */
    function isValidProxySignature(
        address proxy,
        bytes32 hash,
        bytes calldata data
    ) public view returns (bytes4 magicValue) {
        if (data.length > 0) {
            (address[] memory authority, bytes memory signature) = abi.decode(data, (address[], bytes));
            if (proxy != proxyAddress(authority[0])) revert InvalidAuthorityChain();
            address signer = ECDSA.recover(hash, signature);
            validate(signer, authority, PERMISSION_SIGN, 0, 0xFE);
            return IERC1271.isValidSignature.selector;
        }
        return validSignatures[proxy][hash] ? IERC1271.isValidSignature.selector : bytes4(0);
    }

    /**
     * @notice Returns the address of the proxy contract for a given owner
     *
     * @param owner The owner of the Proxy.
     *
     * @return endpoint The address of the Proxy.
     */
    function proxyAddress(address owner) public view returns (address endpoint) {
        endpoint = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            bytes32(uint256(uint160(owner))), // salt
                            keccak256(abi.encodePacked(type(Proxy).creationCode, abi.encode(address(governor))))
                        )
                    )
                )
            )
        );
    }
}