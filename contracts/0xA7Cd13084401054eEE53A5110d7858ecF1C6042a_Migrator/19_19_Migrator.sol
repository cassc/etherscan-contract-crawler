// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Migrator is
    Initializable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public merkleRoot;
    IERC20Upgradeable public moSOLID;

    uint256 public totalClaimedAmount;
    mapping(address => uint256) public claimedAmount;

    event ClaimMoSOLID(address user, uint256 amount, uint256 claimableAmount);

    error InvalidProof();
    error AlreadyClaimed();

    function initialize(
        bytes32 _merkleRoot,
        address _moSOLID,
        address _setter,
        address _admin
    ) public initializer {
        __Pausable_init();
        __AccessControlEnumerable_init();

        _grantRole(SETTER_ROLE, _setter);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        merkleRoot = _merkleRoot;

        moSOLID = IERC20Upgradeable(_moSOLID);
    }

    function pause() public onlyRole(PAUSER_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(SETTER_ROLE) {
        merkleRoot = _merkleRoot;
    }

    function claimMoSOLID(uint256 amount, bytes32[] memory proof)
        external
        whenNotPaused
    {
        if (
            !MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encode(msg.sender, amount))
            )
        ) revert InvalidProof();

        uint256 claimableAmount = amount - claimedAmount[msg.sender];
        if (claimableAmount > 0) {
            claimedAmount[msg.sender] += claimableAmount;
            totalClaimedAmount += claimableAmount;
            moSOLID.safeTransfer(msg.sender, claimableAmount);

            emit ClaimMoSOLID(msg.sender, amount, claimableAmount);
        } else {
            revert AlreadyClaimed();
        }
    }

    function claimMoSOLIDFor(
        address account,
        uint256 amount,
        address receiver,
        bytes32[] memory proof
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (
            !MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encode(account, amount))
            )
        ) revert InvalidProof();

        uint256 claimableAmount = amount - claimedAmount[account];
        if (claimableAmount > 0) {
            claimedAmount[account] += claimableAmount;
            totalClaimedAmount += claimableAmount;
            moSOLID.safeTransfer(receiver, claimableAmount);

            emit ClaimMoSOLID(account, amount, claimableAmount);
        } else {
            revert AlreadyClaimed();
        }
    }
}