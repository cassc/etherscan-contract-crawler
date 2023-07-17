// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ILockERC721.sol";
import "../interfaces/ITOLTransfer.sol";

contract GuardianV3 is Initializable, ITOLTransfer {
    struct UserData {
        address guardian;
        uint256[] lockedAssets;
        mapping(uint256 => uint256) assetToIndex;
    }

    ILockERC721 public LOCKABLE;

    mapping(address => address) public pendingGuardians;
    mapping(address => address) public guardians;
    mapping(address => UserData) public userData;
    mapping(address => mapping(uint256 => address)) public guardianToUsers;
    mapping(address => mapping(address => uint256)) public guardianToUserIndex;
    mapping(address => uint256) public guardianUserCount;

    event GuardianSet(address indexed guardian, address indexed user);
    event GuardianRenounce(address indexed guardian, address indexed user);
    event PendingGuardianSet(
        address indexed pendingGuardian,
        address indexed user
    );

    address public tmpOwner;
    mapping(ILockERC721 => bool) public LOCKABLES;
    mapping(ILockERC721 => mapping(address => UserData))
        public lockablesUserData; // lockable => protege => userdata

    mapping(address => uint256) public renounceLockedUntil; // _protege => timestamp
    mapping(ILockERC721 => bool) public useKeepTOL;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _lockable) public initializer {
        LOCKABLE = ILockERC721(_lockable);
    }

    function initializeV2(
        address[] calldata _lockables
    ) external reinitializer(2) {
        // tmpOwner = address(0x759c5F293EdC487aA02186f0099864Ebc53191C1);
        tmpOwner = address(0xFABB0ac9d68B0B445fB7357272Ff202C5651694a); // dev
        // tmpOwner = address(0x66668460083309F77227f84B211dC5Ab678DbE78); // testnet
        require(msg.sender == tmpOwner);
        for (uint256 i = 0; i < _lockables.length; i++) {
            LOCKABLES[ILockERC721(_lockables[i])] = true;
        }
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == tmpOwner);
        tmpOwner = newOwner;
    }

    function setUseKeepTOL(
        address[] calldata _lockables,
        bool[] calldata _b
    ) external {
        require(msg.sender == tmpOwner);
        for (uint256 i = 0; i < _lockables.length; i++) {
            useKeepTOL[ILockERC721(_lockables[i])] = _b[i];
        }
    }

    function setLockables(
        address[] calldata _lockables,
        bool[] calldata _b
    ) external {
        require(msg.sender == tmpOwner);
        for (uint256 i = 0; i < _lockables.length; i++) {
            LOCKABLES[ILockERC721(_lockables[i])] = _b[i];
        }
    }

    function proposeGuardian(address _guardian) external {
        require(guardians[msg.sender] == address(0), "Guardian set");
        require(msg.sender != _guardian, "Guardian must be a different wallet");

        pendingGuardians[msg.sender] = _guardian;
        emit PendingGuardianSet(_guardian, msg.sender);
    }

    function acceptGuardianship(address _protege) external {
        require(
            pendingGuardians[_protege] == msg.sender,
            "Not the pending guardian"
        );

        pendingGuardians[_protege] = address(0);
        guardians[_protege] = msg.sender;
        userData[_protege].guardian = msg.sender;
        _pushGuardianrray(msg.sender, _protege);
        emit GuardianSet(msg.sender, _protege);
    }

    function renounce(address _protege) external {
        require(guardians[_protege] == msg.sender, "!guardian");
        require(
            block.timestamp >= renounceLockedUntil[_protege],
            "Renounce locked"
        );

        guardians[_protege] = address(0);
        userData[_protege].guardian = address(0);
        _popGuardianrray(msg.sender, _protege);
        emit GuardianRenounce(msg.sender, _protege);
    }

    function getUserData(
        ILockERC721 lockable,
        address owner
    ) internal view returns (UserData storage ud) {
        if (lockable == LOCKABLE) {
            return userData[owner];
        }
        return lockablesUserData[lockable][owner];
    }

    function lockMany(uint256[] calldata _tokenIds) external {
        lockManyLockable(LOCKABLE, _tokenIds);
    }

    function lockManyLockable(
        ILockERC721 lockable,
        uint256[] calldata _tokenIds
    ) public {
        require(
            lockable == LOCKABLE || LOCKABLES[lockable],
            "unsupported lockable"
        );
        address owner = lockable.ownerOf(_tokenIds[0]);
        require(guardians[owner] == msg.sender, "!guardian");

        UserData storage _userData = getUserData(lockable, owner);
        uint256 len = _userData.lockedAssets.length;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(lockable.ownerOf(_tokenIds[i]) == owner, "!owner");
            lockable.lockId(_tokenIds[i]);
            _pushTokenInArray(_userData, _tokenIds[i], len + i);
        }
    }

    function unlockMany(uint256[] calldata _tokenIds) external {
        unlockManyLockable(LOCKABLE, _tokenIds);
    }

    function unlockManyLockable(
        ILockERC721 lockable,
        uint256[] calldata _tokenIds
    ) public {
        require(
            lockable == LOCKABLE || LOCKABLES[lockable],
            "unsupported lockable"
        );
        address owner = lockable.ownerOf(_tokenIds[0]);
        require(guardians[owner] == msg.sender, "!guardian");

        UserData storage _userData = getUserData(lockable, owner);
        uint256 len = _userData.lockedAssets.length;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(lockable.ownerOf(_tokenIds[i]) == owner, "!owner");
            lockable.unlockId(_tokenIds[i]);
            _popTokenFromArray(_userData, _tokenIds[i], len--);
        }
    }

    function unlockManyAndTransfer(
        uint256[] calldata _tokenIds,
        address _recipient
    ) public {
        unlockManyAndTransferLockable(LOCKABLE, _tokenIds, _recipient);
    }

    function unlockManyAndTransferLockable(
        ILockERC721 lockable,
        uint256[] calldata _tokenIds,
        address _recipient
    ) public {
        require(
            lockable == LOCKABLE || LOCKABLES[lockable],
            "unsupported lockable"
        );
        address owner = lockable.ownerOf(_tokenIds[0]);
        require(guardians[owner] == msg.sender, "!guardian");
        bool willUseKeepTOL = useKeepTOL[lockable];

        UserData storage _userData = getUserData(lockable, owner);
        uint256 len = _userData.lockedAssets.length;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(lockable.ownerOf(_tokenIds[i]) == owner, "!owner");
            lockable.unlockId(_tokenIds[i]);
            if (willUseKeepTOL) {
                lockable.keepTOLTransferFrom(owner, _recipient, _tokenIds[i]);
            } else {
                lockable.safeTransferFrom(owner, _recipient, _tokenIds[i]);
            }
            _popTokenFromArray(_userData, _tokenIds[i], len--);
        }
    }

    function getLockedAssetsOfUsers(
        address _user
    ) external view returns (uint256[] memory lockedAssets) {
        return getLockedAssetsOfUsersLockable(LOCKABLE, _user);
    }

    function getLockedAssetsOfUsersLockable(
        ILockERC721 lockable,
        address _user
    ) public view returns (uint256[] memory lockedAssets) {
        UserData storage _userData = getUserData(lockable, _user);

        uint256 len = _userData.lockedAssets.length;
        lockedAssets = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            lockedAssets[i] = _userData.lockedAssets[i];
        }
    }

    function getLockedAssetsOfUsers(
        address _user,
        uint256 _startIndex,
        uint256 _maxLen
    ) external view returns (uint256[] memory lockedAssets) {
        return
            getLockedAssetsOfUsersLockable(
                LOCKABLE,
                _user,
                _startIndex,
                _maxLen
            );
    }

    function getLockedAssetsOfUsersLockable(
        ILockERC721 lockable,
        address _user,
        uint256 _startIndex,
        uint256 _maxLen
    ) public view returns (uint256[] memory lockedAssets) {
        UserData storage _userData = getUserData(lockable, _user);

        uint256 len = _userData.lockedAssets.length;

        if (len == 0 || _startIndex >= len) {
            lockedAssets = new uint256[](0);
        } else {
            _maxLen = (len - _startIndex) < _maxLen
                ? len - _startIndex
                : _maxLen;
            lockedAssets = new uint256[](_maxLen);
            for (uint256 i = _startIndex; i < _startIndex + _maxLen; i++) {
                lockedAssets[i] = _userData.lockedAssets[i];
            }
        }
    }

    function getProtegesFromGuardian(
        address _guardian
    ) external view returns (address[] memory proteges) {
        uint256 len = guardianUserCount[_guardian];
        proteges = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            proteges[i] = guardianToUsers[_guardian][i];
        }
    }

    function _pushTokenInArray(
        UserData storage _userData,
        uint256 _token,
        uint256 _index
    ) internal {
        _userData.lockedAssets.push(_token);
        _userData.assetToIndex[_token] = _index;
    }

    function _popTokenFromArray(
        UserData storage _userData,
        uint256 _token,
        uint256 _len
    ) internal {
        uint256 index = _userData.assetToIndex[_token];
        delete _userData.assetToIndex[_token];
        uint256 lastId = _userData.lockedAssets[_len - 1];
        _userData.assetToIndex[lastId] = index;
        _userData.lockedAssets[index] = lastId;
        _userData.lockedAssets.pop();
    }

    function _pushGuardianrray(address _guardian, address _protege) internal {
        uint256 count = guardianUserCount[_guardian];
        guardianToUsers[_guardian][count] = _protege;
        guardianToUserIndex[_guardian][_protege] = count;
        guardianUserCount[_guardian]++;
    }

    function _popGuardianrray(address _guardian, address _protege) internal {
        uint256 index = guardianToUserIndex[_guardian][_protege];
        delete guardianToUserIndex[_guardian][_protege];
        guardianToUsers[_guardian][index] = guardianToUsers[_guardian][
            guardianUserCount[_guardian] - 1
        ];
        delete guardianToUsers[_guardian][guardianUserCount[_guardian] - 1];
        guardianUserCount[_guardian]--;
    }

    // =============== ITOLTransfer ===============
    function canDoKeepTOLTransfer(
        address from,
        address to
    ) external view returns (bool) {
        return guardians[from] == to || guardians[to] == from;
    }

    function beforeKeepTOLTransfer(address from, address to) external {
        ILockERC721 caller = ILockERC721(msg.sender);
        require(
            caller == LOCKABLE || LOCKABLES[caller],
            "Call must be from lockable contracts"
        );
        require(
            guardians[from] == to || guardians[to] == from,
            "only guardians and their proteges can do keep TOL transfers"
        );

        if (guardians[from] == to) {
            // [from] is a protege
            renounceLockedUntil[from] = block.timestamp + 30 days;
        } else {
            // [to] is a protege
            renounceLockedUntil[to] = block.timestamp + 30 days;
        }
    }
}