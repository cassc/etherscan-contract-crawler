// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { NonblockingLzAppUpgradeable } from "./lzApp/NonblockingLzAppUpgradeable.sol";
import { SignatureCheckerUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

import { ISpectreAllocations } from "./interfaces/ISpectreAllocations.sol";

bytes32 constant CLAIM_HASH = keccak256(
    "Claim(bytes32 project,address to,uint256 amount)"
);

enum MessageType {
    CLAIM
}

struct ClaimStatus {
    uint128 amountClaimed;
    uint128 pendingClaim;
    bool claiming;
}

struct ProjectConfig {
    uint16 dstChainId;
    bool configured;
}

contract SpectreClaimDelegator is
    EIP712Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    NonblockingLzAppUpgradeable
{
    event SendMessage(uint256 indexed nonce, bytes indexed payload);
    event ReceiveMessage(
        uint256 indexed nonce,
        uint16 indexed dstChainId,
        bytes indexed payload
    );

    mapping(bytes32 => mapping(address => ClaimStatus)) claims;
    mapping(bytes32 => ProjectConfig) configuredProjects;
    ISpectreAllocations allocations;
    address signer;

    function initialize(
        address _allocations,
        address _endpoint,
        address _signer,
        string calldata _name,
        string calldata _version
    ) external initializer {
        __EIP712_init(_name, _version);
        __Ownable_init();
        __ReentrancyGuard_init();
        __LzAppUpgradeable_init(_endpoint);
        allocations = ISpectreAllocations(_allocations);
        signer = _signer;
    }

    /**
     * Claim delegation for a project that is not on the Ethereum blockchain.
     * Delegates call using LayerZero to destination chain where the claim is
     * then processed.
     * @param project bytes32 representation of project name
     * @param to address of claimer
     * @param amount amount of tokens to claim based on investment share
     * @param adapterParams relayer gas parameters for LayerZero relayer
     * @param signature proof that Spectre has verified the parameters
     */
    function claim(
        bytes32 project,
        address to,
        uint128 amount,
        bytes calldata adapterParams,
        bytes calldata signature
    ) external payable nonReentrant {
        _safeCheckClaim(project, to, amount, signature);
        ClaimStatus storage claimStatus = claims[project][to];
        require(!claimStatus.claiming, "claim: already claiming");
        ProjectConfig storage conf = configuredProjects[project];
        require(conf.configured, "claim: project not configured");
        _checkGasLimit(
            conf.dstChainId,
            uint16(MessageType.CLAIM),
            adapterParams,
            0
        );

        bytes memory payload = abi.encode(project, to, amount);

        claimStatus.claiming = true;
        claimStatus.pendingClaim = amount;
        _lzSend(
            conf.dstChainId,
            payload,
            payable(msg.sender),
            address(0),
            adapterParams,
            msg.value
        );

        emit SendMessage(
            lzEndpoint.getOutboundNonce(conf.dstChainId, address(this)),
            payload
        );
    }

    function claimStatus(bytes32 project, address claimer)
        external
        view
        returns (ClaimStatus memory)
    {
        return claims[project][claimer];
    }

    function projectConfig(bytes32 project)
        external
        view
        returns (ProjectConfig memory)
    {
        require(
            configuredProjects[project].configured,
            "projectConfig: not configured"
        );
        return configuredProjects[project];
    }

    function configureProject(bytes32 project, uint16 dstChainId)
        external
        onlyOwner
    {
        ProjectConfig storage conf = configuredProjects[project];
        require(!conf.configured, "configureProject: already configured");
        conf.dstChainId = dstChainId;
        conf.configured = true;
    }

    function updateProject(bytes32 project, uint16 dstChainId)
        external
        onlyOwner
    {
        ProjectConfig storage conf = configuredProjects[project];
        require(conf.configured, "configureProject: not configured");
        conf.dstChainId = dstChainId;
    }

    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "setSigner: address is zero");
        signer = _signer;
    }

    function _safeCheckClaim(
        bytes32 project,
        address to,
        uint256 amount,
        bytes calldata signature
    ) internal {
        bytes32 hash = _getHash(project, to, amount);
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                signer,
                hash,
                signature
            ),
            "_safeCheckClaim: invalid signature"
        );
    }

    function _getHash(
        bytes32 project,
        address to,
        uint256 amount
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(CLAIM_HASH, project, to, amount)
        );

        return _hashTypedDataV4(structHash);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        (bytes32 project, address to, bool success) = abi.decode(
            _payload,
            (bytes32, address, bool)
        );
        if (success) {
            ClaimStatus storage claimStatus = claims[project][to];
            claimStatus.amountClaimed += claimStatus.pendingClaim;
            claimStatus.pendingClaim = 0;
            claimStatus.claiming = false;
        }

        emit ReceiveMessage(_nonce, _srcChainId, _payload);
    }

    receive() external payable {}
}