// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../burn/IBurnVF.sol";
import "./VFBurnIslandExtensions.sol";

contract VFBurnIslandV1 is VFBurnIslandExtensions, ReentrancyGuard {
    using ECDSA for bytes32;

    struct Eruption {
        uint256 startTime;
        uint256 openTime;
    }

    mapping(string => Eruption) public eruptionConfig;

    //Address of burn signer
    address private _burnSigner;

    //Address to burn tokens to
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    error EruptionContractCannotBeZero();
    error InvalidBurnSignature();
    error InvalidBurnType();
    error RecipientCountDoesNotMatchTokenCount();
    error EruptionNotStarted();
    error EruptionHasEnded();

    /**
     * @dev Initializes the contract by setting a `signer`, `controlContractAddress`,
     * and `tokenContractAddress` to the sales contract.
     */
    constructor(
        address signer,
        address controlContractAddress
    ) VFBurnIslandExtensions(controlContractAddress) {
        _burnSigner = signer;
    }

    /**
     * @dev Update the burn signer address with `signer`
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function setBurnSigner(address signer) external onlyRole(getAdminRole()) {
        _burnSigner = signer;
    }

    function setEruptionConfig(
        string calldata eruptionId,
        uint256 startTime,
        uint256 openTime
    ) external onlyRole(getAdminRole()) {
        eruptionConfig[eruptionId] = Eruption({
            startTime: startTime,
            openTime: openTime
        });
    }

    /**
     * @dev Send tokens to burn island
     *
     * Requirements:
     *
     * - `contractAddress` must support the IERC721 interface
     * - `signature` must be signed by the burn signer address
     * - `nonce` must be unique
     * - `tokenIds` must be owned by the sender
     */
    function sendTokensToBurnIsland(
        string calldata eruptionId,
        string calldata burnId,
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256 nonce,
        bytes calldata signature
    ) external nonReentrant {
        bytes32 txHash = _getTxHash(
            eruptionId,
            burnId,
            _msgSender(),
            contractAddress,
            tokenIds,
            nonce
        );

        if (!_isValidBurnSignature(txHash, signature)) {
            revert InvalidBurnSignature();
        }

        if (contractAddress == address(0)) {
            revert EruptionContractCannotBeZero();
        }

        Eruption memory eruption = eruptionConfig[eruptionId];

        if (block.timestamp < eruption.startTime || eruption.startTime == 0) {
            revert EruptionNotStarted();
        }

        if (block.timestamp > (eruption.startTime + eruption.openTime)) {
            revert EruptionHasEnded();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            IBurnVF(contractAddress).transferFrom(
                _msgSender(),
                address(this),
                tokenIds[i]
            );
        }
    }

    function burnTokens(
        uint256 burnType,
        address contractAddress,
        uint256[] calldata tokenIds
    ) external nonReentrant onlyRole(getAdminRole()) {
        if (contractAddress == address(0)) {
            revert EruptionContractCannotBeZero();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (burnType == 0) {
                IBurnVF(contractAddress).transferFrom(
                    address(this),
                    BURN_ADDRESS,
                    tokenIds[i]
                );
            } else if (burnType == 1) {
                IBurnVF(contractAddress).burn(tokenIds[i]);
            } else if (burnType == 2) {
                IBurnVF(contractAddress).burn(address(this), tokenIds[i]);
            } else {
                revert InvalidBurnType();
            }
        }
    }

    function returnTokens(
        address contractAddress,
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external nonReentrant onlyRole(getAdminRole()) {
        if (contractAddress == address(0)) {
            revert EruptionContractCannotBeZero();
        }

        if (recipients.length != tokenIds.length) {
            revert RecipientCountDoesNotMatchTokenCount();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            IBurnVF(contractAddress).transferFrom(
                address(this),
                recipients[i],
                tokenIds[i]
            );
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public pure override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(VFBurnIslandExtensions).interfaceId;
    }

    /**
     * @dev Validate a burn id is signed by the burn signer address
     */
    function _isValidBurnSignature(
        bytes32 txHash,
        bytes calldata signature
    ) internal view returns (bool isValid) {
        address signer = txHash.toEthSignedMessageHash().recover(signature);
        return signer == _burnSigner;
    }

    /**
     * @dev Get the hash of a burn transaction
     */
    function _getTxHash(
        string calldata eruptionId,
        string calldata burnId,
        address sender,
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    eruptionId,
                    burnId,
                    sender,
                    contractAddress,
                    tokenIds,
                    nonce
                )
            );
    }
}