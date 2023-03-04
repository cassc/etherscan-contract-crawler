// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IAlligator.sol";
import {INounsDAOV2} from "./interfaces/INounsDAOV2.sol";
import {IRule} from "./interfaces/IRule.sol";
import {ENSHelper} from "./ENSHelper.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Proxy is IERC1271 {
    address internal immutable alligator;
    address internal immutable governor;

    constructor(address _governor) {
        alligator = msg.sender;
        governor = _governor;
    }

    function isValidSignature(bytes32 hash, bytes calldata signature) external view override returns (bytes4) {
        return IAlligator(alligator).isValidProxySignature(address(this), hash, signature);
    }

    function setENSReverseRecord(string calldata name) external {
        require(msg.sender == alligator);
        IENSReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148).setName(name);
    }

    fallback() external payable {
        require(msg.sender == alligator);
        address addr = governor;

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := call(gas(), addr, callvalue(), 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // `receive` is omitted to minimize contract size
}

contract Alligator is IAlligator, ENSHelper {
    // =============================================================
    //                             ERRORS
    // =============================================================

    error BadSignature();
    error NotDelegated(address from, address to, uint8 requiredPermissions);
    error TooManyRedelegations(address from, address to);
    error NotValidYet(address from, address to, uint32 willBeValidFrom);
    error NotValidAnymore(address from, address to, uint32 wasValidUntil);
    error TooEarly(address from, address to, uint32 blocksBeforeVoteCloses);
    error InvalidCustomRule(address from, address to, address customRule);

    // =============================================================
    //                       IMMUTABLE STORAGE
    // =============================================================

    INounsDAOV2 public immutable governor;

    uint8 internal constant PERMISSION_VOTE = 1;
    uint8 internal constant PERMISSION_SIGN = 1 << 1;
    uint8 internal constant PERMISSION_PROPOSE = 1 << 2;

    bytes32 internal constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    bytes32 internal constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");

    /// @notice The maximum priority fee used to cap gas refunds in `castRefundableVote`
    uint256 public constant MAX_REFUND_PRIORITY_FEE = 2 gwei;

    /// @notice The vote refund gas overhead, including 7K for ETH transfer and 29K for general transaction overhead
    uint256 public constant REFUND_BASE_GAS = 36000;

    /// @notice The maximum gas units the DAO will refund voters on; supports about 9,190 characters
    uint256 public constant MAX_REFUND_GAS_USED = 200_000;

    /// @notice The maximum basefee the DAO will refund voters on
    uint256 public constant MAX_REFUND_BASE_FEE = 200 gwei;

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

    /// @notice Deploy a new Proxy for an owner deterministically.
    function create(address owner) public returns (address endpoint) {
        endpoint = address(new Proxy{salt: bytes32(uint256(uint160(owner)))}(address(governor)));
        emit ProxyDeployed(owner, endpoint);

        if (ensNameHash != 0) {
            string memory reverseName = registerDeployment(endpoint);
            Proxy(payable(endpoint)).setENSReverseRecord(reverseName);
        }
    }

    /// @notice Validate subdelegation rules and make a proposal to the governor.
    function propose(
        address[] calldata authority,
        address[] calldata targets,
        uint256[] calldata values,
        string[] calldata signatures,
        bytes[] calldata calldatas,
        string calldata description
    ) external returns (uint256 proposalId) {
        address proxy = proxyAddress(authority[0]);
        // Create a proposal first so the custom rules can validate it
        proposalId = INounsDAOV2(proxy).propose(targets, values, signatures, calldatas, description);
        validate(msg.sender, authority, PERMISSION_PROPOSE, proposalId, 0xFF);
    }

    /// @notice Validate subdelegation rules and cast a vote on the governor.
    function castVote(address[] calldata authority, uint256 proposalId, uint8 support) external {
        validate(msg.sender, authority, PERMISSION_VOTE, proposalId, support);

        address proxy = proxyAddress(authority[0]);
        INounsDAOV2(proxy).castVote(proposalId, support);
        emit VoteCast(proxy, msg.sender, authority, proposalId, support);
    }

    /// @notice Validate subdelegation rules and cast a vote with reason on the governor.
    function castVoteWithReason(
        address[] calldata authority,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public {
        validate(msg.sender, authority, PERMISSION_VOTE, proposalId, support);

        address proxy = proxyAddress(authority[0]);
        INounsDAOV2(proxy).castVoteWithReason(proposalId, support, reason);
        emit VoteCast(proxy, msg.sender, authority, proposalId, support);
    }

    /// @notice Validate subdelegation rules and cast multiple votes with reason on the governor.
    function castVotesWithReasonBatched(
        address[][] calldata authorities,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public {
        address[] memory proxies = new address[](authorities.length);
        address[] memory authority;
        for (uint256 i; i < authorities.length; ) {
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

    /// @notice Validate subdelegation rules and cast multiple votes with reason on the governor.
    /// Refunds the gas used to cast the votes, if possible.
    function castRefundableVotesWithReasonBatched(
        address[][] calldata authorities,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external {
        uint256 startGas = gasleft();
        castVotesWithReasonBatched(authorities, proposalId, support, reason);
        _refundGas(startGas);
    }

    /// @notice Validate subdelegation rules and cast a vote by signature on the governor.
    function castVoteBySig(
        address[] calldata authority,
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
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

    /// @notice Validate subdelegation rules and sign a hash.
    function sign(address[] calldata authority, bytes32 hash) external {
        validate(msg.sender, authority, PERMISSION_SIGN, 0, 0xFE);

        address proxy = proxyAddress(authority[0]);
        validSignatures[proxy][hash] = true;
        emit Signed(proxy, authority, hash);
    }

    /// @notice Subdelegate an address with rules.
    function subDelegate(address to, Rules calldata rules, bool createProxy) external {
        if (createProxy) {
            if (proxyAddress(msg.sender).code.length == 0) {
                create(msg.sender);
            }
        }

        subDelegations[msg.sender][to] = rules;
        emit SubDelegation(msg.sender, to, rules);
    }

    /// @notice Subdelegate multiple addresses with rules.
    function subDelegateBatched(address[] calldata targets, Rules[] calldata rules, bool createProxy) external {
        require(targets.length == rules.length);

        if (createProxy) {
            if (proxyAddress(msg.sender).code.length == 0) {
                create(msg.sender);
            }
        }

        for (uint256 i; i < targets.length; ) {
            subDelegations[msg.sender][targets[i]] = rules[i];

            unchecked {
                ++i;
            }
        }

        emit SubDelegations(msg.sender, targets, rules);
    }

    // Refill Alligator's balance for gas refunds
    receive() external payable {}

    // =============================================================
    //                         VIEW FUNCTIONS
    // =============================================================

    /// @notice Validate subdelegation rules.
    function validate(
        address sender,
        address[] memory authority,
        uint8 permissions,
        uint256 proposalId,
        uint8 support
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
                        IRule(rules.customRule).validate(address(governor), sender, proposalId, support) !=
                        IRule.validate.selector
                    ) {
                        revert InvalidCustomRule(from, to, rules.customRule);
                    }
                }

                from = to;
            }
        }

        if (from == sender) {
            return;
        }

        revert NotDelegated(from, sender, permissions);
    }

    /// @notice Returns the `IERC1271.isValidSignature` if signature is valid, or 0 if not.
    function isValidProxySignature(
        address proxy,
        bytes32 hash,
        bytes calldata data
    ) public view returns (bytes4 magicValue) {
        if (data.length > 0) {
            (address[] memory authority, bytes memory signature) = abi.decode(data, (address[], bytes));
            address signer = ECDSA.recover(hash, signature);
            validate(signer, authority, PERMISSION_SIGN, 0, 0xFE);
            return IERC1271.isValidSignature.selector;
        }
        return validSignatures[proxy][hash] ? IERC1271.isValidSignature.selector : bytes4(0);
    }

    /// @notice Returns the address of the proxy contract for a given owner
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

    // =============================================================
    //                       INTERNAL FUNCTIONS
    // =============================================================

    function _refundGas(uint256 startGas) internal {
        unchecked {
            uint256 balance = address(this).balance;
            if (balance == 0) {
                return;
            }
            uint256 basefee = min(block.basefee, MAX_REFUND_BASE_FEE);
            uint256 gasPrice = min(tx.gasprice, basefee + MAX_REFUND_PRIORITY_FEE);
            uint256 gasUsed = min(startGas - gasleft() + REFUND_BASE_GAS, MAX_REFUND_GAS_USED);
            uint256 refundAmount = min(gasPrice * gasUsed, balance);
            (bool refundSent, ) = msg.sender.call{value: refundAmount}("");
            emit RefundableVote(msg.sender, refundAmount, refundSent);
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IENSReverseRegistrar {
    function setName(string memory name) external returns (bytes32 node);
}