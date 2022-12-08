// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IWhitelist.sol";
import "./interfaces/IEmissionBooster.sol";
import "./libraries/ErrorCodes.sol";

contract Whitelist is IWhitelist, AccessControl, ReentrancyGuard {
    /// @notice The right part is the keccak-256 hash of variable name
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);

    /// @notice EmissionBooster contract
    IEmissionBooster public immutable emissionBooster;

    /// @notice A maximum number of members. When membership reaches this number, no new members may
    /// join.
    uint256 public maxMembers;

    /// @notice The total number of members stored in the map.
    uint256 public memberCount;

    /// @notice Boolean variable. Protocol operation mode. In whitelist mode, only members
    /// from whitelist and who have NFT can work with protocol.
    bool public whitelistModeEnabled = true;

    // @notice Mapping of "accounts in the WhiteList"
    mapping(address => bool) public accountMembership;

    constructor(
        address _admin,
        IEmissionBooster emissionBooster_,
        uint256 _maxMembers,
        address[] memory memberList
    ) {
        require(memberList.length <= _maxMembers, ErrorCodes.MEMBERSHIP_LIMIT);

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(GATEKEEPER, _admin);
        emissionBooster = emissionBooster_;
        maxMembers = _maxMembers;

        uint256 savedMembers = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (accountMembership[memberList[i]]) {
                continue;
            }
            accountMembership[memberList[i]] = true;
            savedMembers++;
            emit MemberAdded(memberList[i]);
        }
        memberCount = savedMembers;
    }

    /// @inheritdoc IWhitelist
    function addMember(address newAccount) external onlyRole(GATEKEEPER) {
        require(!accountMembership[newAccount], ErrorCodes.MEMBER_ALREADY_ADDED);
        require(memberCount < maxMembers, ErrorCodes.MEMBERSHIP_LIMIT_REACHED);

        accountMembership[newAccount] = true;
        memberCount++;

        emit MemberAdded(newAccount);
    }

    /// @inheritdoc IWhitelist
    function removeMember(address accountToRemove) external onlyRole(GATEKEEPER) {
        require(accountMembership[accountToRemove], ErrorCodes.MEMBER_NOT_EXIST);

        delete accountMembership[accountToRemove];
        memberCount--;

        emit MemberRemoved(accountToRemove);
    }

    /// @inheritdoc IWhitelist
    function turnOffWhitelistMode() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        whitelistModeEnabled = false;
        emit WhitelistModeWasTurnedOff();
        emissionBooster.enableEmissionBoosting();
    }

    /// @inheritdoc IWhitelist
    function setMaxMembers(uint256 newThreshold) external onlyRole(GATEKEEPER) {
        require(newThreshold >= memberCount, ErrorCodes.MEMBERSHIP_LIMIT);
        maxMembers = newThreshold;
        emit MaxMemberAmountChanged(newThreshold);
    }

    /// @inheritdoc IWhitelist
    function isWhitelisted(address who) external view returns (bool) {
        return !whitelistModeEnabled || accountMembership[who] || emissionBooster.isAccountHaveTiers(who);
    }
}