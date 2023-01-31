// SPDX-License-Identifier: MIT
// Unagi Contracts v1.0.0 (DistributionManager.sol)
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IMintable {
    function mint(address to, uint256 amount) external;
}

/**
 * @title DistributionManager
 * @dev Allow to distribute a pack of assets only once.
 * @custom:security-contact [email protected]
 */
contract DistributionManager is AccessControl, Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    IERC20 public immutable _CHAMP_TOKEN_CONTRACT;
    IMintable public immutable _MGC_TOKEN_CONTRACT;
    IERC721 public immutable _NFCHAMP_CONTRACT;

    // (UID => used) mapping of UID
    mapping(string => bool) private _UIDs;

    constructor(
        address champTokenAddress,
        address mgcTokenAddress,
        address nfChampAddress
    ) {
        _CHAMP_TOKEN_CONTRACT = IERC20(champTokenAddress);
        _MGC_TOKEN_CONTRACT = IMintable(mgcTokenAddress);
        _NFCHAMP_CONTRACT = IERC721(nfChampAddress);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(DISTRIBUTOR_ROLE, _msgSender());
    }

    /**
     * @dev Pause token transfers.
     *
     * Requirements:
     *
     * - Caller must have role PAUSER_ROLE.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause token transfers.
     *
     * Requirements:
     *
     * - Caller must have role PAUSER_ROLE.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Returns true if UID is already distributed
     */
    function isDistributed(string memory UID) public view returns (bool) {
        return _UIDs[UID];
    }

    /**
     * @dev Distribute a pack of assets.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - Caller must have role DISTRIBUTOR_ROLE.
     * - UID must not have been already distributed.
     */
    function distribute(
        string memory UID,
        address to,
        uint256 champAmount,
        uint256 mgcAmount,
        uint256[] memory tokenIds
    ) external onlyRole(DISTRIBUTOR_ROLE) whenNotPaused {
        _reserveUID(UID);

        if (champAmount > 0) {
            _CHAMP_TOKEN_CONTRACT.transferFrom(_msgSender(), to, champAmount);
        }

        if (mgcAmount > 0) {
            _MGC_TOKEN_CONTRACT.mint(to, mgcAmount);
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _NFCHAMP_CONTRACT.safeTransferFrom(_msgSender(), to, tokenIds[i]);
        }

        emit Distribute(UID);
    }

    /**
     * @dev Reserve an UID
     *
     * Requirements:
     *
     * - UID must be free.
     */
    function _reserveUID(string memory UID) private {
        require(!isDistributed(UID), "DistributionManager: UID must be free.");

        _UIDs[UID] = true;
    }

    event Distribute(string UID);
}