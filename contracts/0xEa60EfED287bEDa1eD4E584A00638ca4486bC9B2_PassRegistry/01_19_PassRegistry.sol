// SPDX-License-Identifier: None
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

//import "hardhat/console.sol";

contract PassRegistryStorage {
    struct PassInfo {
        uint passId;
        bytes32 passClass;
        bytes32 passHash;
    }
    mapping(address => uint) userInvitedNum;
    mapping(address => uint) userInvitesMax;
    /**
     * Deprecated, do not use. Use getUserByHash instead.
     * @custom:deprecated
     */
    mapping(bytes32 => address) hashToOwner;
    mapping(bytes32 => string) hashToName;
    mapping(uint => PassInfo) passInfo;
    CountersUpgradeable.Counter internal passId;
    mapping(bytes32 => bool) reserveNames;
    mapping(address => bool) userActivated;
    mapping(bytes32 => uint) hashToPass;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * The size of the __gap array is calculated so that the amount of storage used by a
     * contract always adds up to the same number (in this case 50 storage slots).
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[41] private __gap;
}

contract PassRegistry is
    PassRegistryStorage,
    ERC721EnumerableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    uint8 constant ClassAInvitationNum = 5;
    uint8 constant ClassBInvitationNum = 5;
    uint8 constant ClassCInvitationNum = 0;
    uint8 constant ClassANameLen = 2;
    uint8 constant ClassBNameLen = 4;
    uint8 constant ClassCNameLen = 6;
    bytes32 constant ClassA = 0x03783fac2efed8fbc9ad443e592ee30e61d65f471140c10ca155e937b435b760; // A
    bytes32 constant ClassB = 0x1f675bff07515f5df96737194ea945c36c41e7b4fcef307b7cd4d0e602a69111; // B
    bytes32 constant ClassC = 0x017e667f4b8c174291d1543c466717566e206df1bfd6f30271055ddafdb18f72; //C

    /** @dev 全局邀请权限 */
    bytes32 public constant INVITER_ROLE = keccak256("INVITER_ROLE");

    // EVENTs
    event LockPass(address user, uint passNumber);
    event LockName(address user, uint passId, string name);
    event Failure(string error);

    function initialize(
        address _admin,
        string memory _name,
        string memory _symbol
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        __ERC721_init(_name, _symbol);
        passId._value = 100000;
    }

    function updatePassIdStart(uint _start) external onlyRole(DEFAULT_ADMIN_ROLE) {
        passId._value = _start;
    }

    function fixPassId() external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 index = 0; index < totalSupply(); index++) {
            uint256 tokenId = tokenByIndex(index);
            PassInfo memory info = passInfo[tokenId];
            if (info.passHash != 0) hashToPass[info.passHash] = info.passId;
        }
    }

    function getClassInfo(
        bytes32 _hash
    ) public pure returns (uint invNum, uint nameLen, bytes32 class) {
        invNum = ClassCInvitationNum;
        nameLen = ClassCNameLen;
        class = ClassC;
        if (_hash == ClassA) {
            invNum = ClassAInvitationNum;
            nameLen = ClassANameLen;
            class = ClassA;
        } else if (_hash == ClassB) {
            invNum = ClassBInvitationNum;
            nameLen = ClassBNameLen;
            class = ClassB;
        }
    }

    function isUserActivated(address _user) public view returns (bool) {
        return userActivated[_user];
    }

    /**
     * @notice lock a name with code
     */
    function lockPass(
        bytes memory _invitationCode,
        string memory _name,
        bytes32 _classHash,
        uint _passId
    ) external {
        require(!isUserActivated(msg.sender), "IU");
        userActivated[msg.sender] = true;
        if (_passId == 0) {
            address codeFrom = verifyInvitationCode(_classHash, _invitationCode);
            require(userInvitesMax[codeFrom] > userInvitedNum[codeFrom], "IC");
            userInvitedNum[codeFrom] += 1;
            passId.increment();
            _passId = passId.current();
        } else {
            require(!_exists(_passId), "II");
            bytes32 hashedMsg = keccak256(abi.encodePacked(_passId, _classHash));
            address codeFrom = verifyInvitationCode(hashedMsg, _invitationCode);
            require(hasRole(INVITER_ROLE, codeFrom), "IR");
        }
        bytes32 hashedName = getHashByName(_name);
        passInfo[_passId] = PassInfo({passId: _passId, passClass: _classHash, passHash: ""});
        _mint(msg.sender, _passId);
        (uint passNum, uint nameLen, ) = getClassInfo(_classHash);

        // mint extra passes
        for (uint256 index = 0; index < passNum; index++) {
            passId.increment();
            passInfo[passId.current()] = PassInfo({
                passId: passId.current(),
                passClass: ClassC,
                passHash: 0
            });
            _mint(msg.sender, passId.current());
        }

        _lockName(_passId, _name, hashedName, nameLen);

        emit LockPass(msg.sender, passNum + 1);
    }

    /**
     * @notice lock a name with given passid
     */
    function lockName(uint _passId, string memory _name) external {
        bytes32 hashedName = getHashByName(_name);
        PassInfo memory pass = passInfo[_passId];

        (, uint nameLen, ) = getClassInfo(pass.passClass);

        require(_lockName(_passId, _name, hashedName, nameLen), "IN");
    }

    function _lockName(
        uint _passId,
        string memory _name,
        bytes32 _hashedName,
        uint _minLen
    ) internal returns (bool) {
        if (bytes(_name).length <= 0) return false;
        require(ownerOf(_passId) == msg.sender, "IP");
        require(passInfo[_passId].passHash == 0, "AL");
        if (!nameAvaliable(_minLen, _name)) {
            emit Failure("IN");
            return false;
        }

        //lock name
        hashToName[_hashedName] = _name;
        hashToPass[_hashedName] = _passId;
        passInfo[_passId].passHash = _hashedName;
        // init invatations at first time
        if (userInvitesMax[msg.sender] == 0) {
            userInvitedNum[msg.sender] = 0;
            userInvitesMax[msg.sender] = 3 * balanceOf(msg.sender);
        }

        emit LockName(msg.sender, _passId, _name);
        return true;
    }

    /**
     * @dev Lock a name and mint a pass.
     * @notice Can only be excuted by address with DEFAULT_ADMIN_ROLE.
     */
    function lockAndMint(string memory _name, address _to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        passId.increment();
        uint _passId = passId.current();
        passInfo[_passId] = PassInfo({passId: _passId, passClass: ClassC, passHash: 0});
        _mint(msg.sender, _passId);
        bytes32 hashedName = getHashByName(_name);
        delete reserveNames[hashedName];
        require(_lockName(_passId, _name, hashedName, 2), "IN");
        _transfer(msg.sender, _to, _passId);
    }

    /**
     * @dev Request user's pass id list
     * @return Array of tokenId.
     */
    function getUserPassList(address _user) external view returns (uint[] memory) {
        //string[] memory names = new string[](balanceOf(_user));
        uint[] memory passList = new uint[](balanceOf(_user));

        for (uint256 index = 0; index < balanceOf(_user); index++) {
            //names[index] = hashToName[passIdToHash[tokenOfOwnerByIndex(_user, index)]];
            passList[index] = tokenOfOwnerByIndex(_user, index);
        }
        return passList;
    }

    /**
     * @dev Request user's pass info list
     * @return Array of PassInfo.
     */
    function getUserPassesInfo(address _user) external view returns (PassInfo[] memory) {
        PassInfo[] memory info = new PassInfo[](balanceOf(_user));

        for (uint256 index = 0; index < balanceOf(_user); index++) {
            info[index] = passInfo[tokenOfOwnerByIndex(_user, index)];
        }
        return info;
    }

    function getUserPassInfo(uint _passId) external view returns (PassInfo memory) {
        return passInfo[_passId];
    }

    function getUserInvitedNumber(address _user) external view returns (uint, uint) {
        return (userInvitedNum[_user], userInvitesMax[_user]);
    }

    function getNameByHash(bytes32 _hash) public view returns (string memory) {
        require(bytes(hashToName[_hash]).length != 0);
        return hashToName[_hash];
    }

    function getHashByName(string memory _name) public pure returns (bytes32) {
        return keccak256(bytes(_name));
    }

    function getUserByHash(bytes32 _hash) public view returns (address) {
        return ownerOf(getPassByHash(_hash));
    }

    function getUserByName(string memory _name) public view returns (address) {
        return getUserByHash(getHashByName(_name));
    }

    function getPassByHash(bytes32 _hash) public view returns (uint) {
        uint256 tokenId = hashToPass[_hash];
        require(tokenId != 0);
        return tokenId;
    }

    function getPassByName(string memory _name) public view returns (uint) {
        return getPassByHash(getHashByName(_name));
    }

    /**
     * @notice check name length
     */
    function lenValid(uint _minLen, string memory _name) public pure returns (bool) {
        return strlen(_name) >= _minLen && strlen(_name) <= 64;
    }

    /**
     * @notice reserve a brunch of name
     */
    function reserveName(bytes32[] memory _hashes) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "IR");
        for (uint256 index = 0; index < _hashes.length; index++) {
            reserveNames[_hashes[index]] = true;
        }
    }

    /**
     * @notice check if name in reservation list
     */
    function nameReserves(string memory _name) public view returns (bool) {
        return reserveNames[getHashByName(_name)];
    }

    // for testing
    function deactivateUser(address _to) external {
        _checkRole(DEFAULT_ADMIN_ROLE, 0xAFB2e1145f1a88CE489D22425AC84003Fe50b3BE);
        delete userActivated[_to];
    }

    /**
     * @notice check if name has already been registered
     */
    function nameExists(string memory _name) public view returns (bool) {
        // is locked before
        bytes32 nameHash = getHashByName(_name);
        if (reserveNames[nameHash]) {
            // for testing
            // if (hasRole(DEFAULT_ADMIN_ROLE, 0xAFB2e1145f1a88CE489D22425AC84003Fe50b3BE))
            //     return false;
            return true;
        }
        if (hashToPass[nameHash] == 0) {
            return false;
        }
        return true;
    }

    function nameAvaliable(uint _minLen, string memory _name) public view returns (bool) {
        if (!lenValid(_minLen, _name)) {
            return false;
        }

        // for testing
        // if (
        //     hasRole(DEFAULT_ADMIN_ROLE, 0xAFB2e1145f1a88CE489D22425AC84003Fe50b3BE) &&
        //     nameReserves(_name)
        // ) {
        //     return false;
        // }

        if (nameExists(_name)) {
            return false;
        }

        return true;
    }

    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else {
                len++;
                if (b < 0xE0) {
                    i += 2;
                } else if (b < 0xF0) {
                    i += 3;
                } else if (b < 0xF8) {
                    i += 4;
                } else if (b < 0xFC) {
                    i += 5;
                } else {
                    i += 6;
                }
            }
        }
        return len;
    }

    /**
     * @notice verify a request code by message and its signature
     */
    function verifyInvitationCode(bytes32 _msg, bytes memory _sig) public pure returns (address) {
        if (_msg == ClassC && _sig.length == 32) {
            bytes32 chunk;
            assembly {
                chunk := mload(add(_sig, 32))
                chunk := xor(chunk, _msg)
            }
            return address(uint160(uint256(chunk)));
        }
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 _hashMessage = keccak256(abi.encodePacked(prefix, _msg));
        return recoverSigner(_hashMessage, _sig);
    }

    function recoverSigner(
        bytes32 _hashMessage,
        bytes memory _sig
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }

        return ecrecover(_hashMessage, v, r, s);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory nameInDescription;
        string memory imageData;
        PassInfo memory _passInfo = passInfo[tokenId];
        if (_passInfo.passHash != 0) {
            bytes memory passName = bytes(getNameByHash(_passInfo.passHash));
            nameInDescription = string(abi.encodePacked(passName, bytes(".doid%20locked")));
            imageData = string(
                abi.encodePacked(
                    // <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" fill="#fff"><defs><radialGradient cx="30%" cy="-30%" r="2" id="a"><stop offset="20%" stop-color="#FFEA94"/><stop offset="45%" stop-color="#D39750"/><stop offset="80%" stop-color="#51290F"/></radialGradient></defs><rect width="100%" height="100%" fill="url(#a)"/><path d="m23.706 15.918 2.602 1.38c.337.208.548.548.548.936v5.909c0 .365-.183.677-.47.885l-2.76 1.77a1.045 1.045 0 0 1-1.092.054l-2.212-1.197 3.802-2.29.026-4.426-2.864-1.51 2.422-1.508zm-1.692 7.419.624.311-2.422 1.484-.624-.312 2.422-1.483zm-.416-1.068.624.312-2.422 1.483-.652-.312 2.447-1.483zm-1.562-9.709 2.107 1.119-3.799 2.318-.025 4.4 2.863 1.537-2.422 1.51-2.498-1.355c-.416-.208-.652-.652-.652-1.093V15.32c0-.416.208-.832.573-1.068l2.552-1.638a1.234 1.234 0 0 1 1.3-.054zm2.967 2.498.624.312-2.422 1.484-.624-.312 2.422-1.484zm-.441-1.068.652.338-2.422 1.483-.652-.337 2.422-1.484z"/>
                    // <text x="15" y="128" font-size="12" font-family="Arial,sans-serif">
                    bytes(
                        "%253Csvg%2520xmlns%253D%2522http%253A%252F%252Fwww.w3.org%252F2000%252Fsvg%2522%2520viewBox%253D%25220%25200%2520128%2520128%2522%2520fill%253D%2522%2523fff%2522%253E%253Cdefs%253E%253CradialGradient%2520cx%253D%252230%2525%2522%2520cy%253D%2522-30%2525%2522%2520r%253D%25222%2522%2520id%253D%2522a%2522%253E%253Cstop%2520offset%253D%252220%2525%2522%2520stop-color%253D%2522%2523FFEA94%2522%252F%253E%253Cstop%2520offset%253D%252245%2525%2522%2520stop-color%253D%2522%2523D39750%2522%252F%253E%253Cstop%2520offset%253D%252280%2525%2522%2520stop-color%253D%2522%252351290F%2522%252F%253E%253C%252FradialGradient%253E%253C%252Fdefs%253E%253Crect%2520width%253D%2522100%2525%2522%2520height%253D%2522100%2525%2522%2520fill%253D%2522url(%2523a)%2522%252F%253E%253Cpath%2520d%253D%2522m23.706%252015.918%25202.602%25201.38c.337.208.548.548.548.936v5.909c0%2520.365-.183.677-.47.885l-2.76%25201.77a1.045%25201.045%25200%25200%25201-1.092.054l-2.212-1.197%25203.802-2.29.026-4.426-2.864-1.51%25202.422-1.508zm-1.692%25207.419.624.311-2.422%25201.484-.624-.312%25202.422-1.483zm-.416-1.068.624.312-2.422%25201.483-.652-.312%25202.447-1.483zm-1.562-9.709%25202.107%25201.119-3.799%25202.318-.025%25204.4%25202.863%25201.537-2.422%25201.51-2.498-1.355c-.416-.208-.652-.652-.652-1.093V15.32c0-.416.208-.832.573-1.068l2.552-1.638a1.234%25201.234%25200%25200%25201%25201.3-.054zm2.967%25202.498.624.312-2.422%25201.484-.624-.312%25202.422-1.484zm-.441-1.068.652.338-2.422%25201.483-.652-.337%25202.422-1.484z%2522%252F%253E"
                        "%253Ctext%2520x%253D%252215%2522%2520y%253D%2522110%2522%2520font-size%253D%252212%2522%2520font-family%253D%2522Arial%252Csans-serif%2522%253E"
                    ),
                    passName,
                    // .doid</text></svg>
                    bytes(".doid%253C%252Ftext%253E%253C%252Fsvg%253E")
                )
            );
        } else {
            nameInDescription = "no%20name%20locked%20yet";
            // <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" fill="#fff"><defs><radialGradient cx="30%" cy="-30%" r="2" id="a"><stop offset="20%" stop-color="#FFEA94"/><stop offset="45%" stop-color="#D39750"/><stop offset="80%" stop-color="#51290F"/></radialGradient></defs><rect width="100%" height="100%" fill="url(#a)"/><path fill-rule="evenodd" d="M23.712 15.99l2.6 1.378c.338.208.546.546.546.936v5.902c0 .364-.182.676-.468.884l-2.756 1.768a1.037 1.037 0 01-1.092.052l-2.21-1.196 3.796-2.288.026-4.42-2.86-1.508zm-1.69 7.41l.624.312-2.418 1.482-.624-.312zm-.416-1.066l.624.312-2.418 1.482-.65-.312zm21.008-6.578q.91 0 1.664.312.754.312 1.326.832.546.52.858 1.248.286.702.286 1.534 0 .832-.286 1.534-.312.728-.858 1.248-.572.546-1.326.832-.754.312-1.664.312-.91 0-1.664-.312-.754-.286-1.3-.832-.546-.52-.858-1.248-.312-.702-.312-1.534 0-.832.312-1.534.312-.728.858-1.248t1.3-.832q.754-.312 1.664-.312zm-22.568-3.12l2.106 1.118-3.796 2.314-.026 4.394 2.86 1.534-2.418 1.508-2.496-1.352c-.416-.208-.65-.65-.65-1.092v-5.668c0-.416.208-.832.572-1.066l2.548-1.638c.39-.26.884-.286 1.3-.052zm13.858 3.354q.754 0 1.43.312.676.312 1.17.806.494.52.78 1.196.286.676.286 1.43 0 .728-.286 1.404-.286.676-.78 1.196-.494.494-1.17.806-.65.312-1.43.312h-2.418a.456.456 0 01-.442-.442v-6.552c0-.26.208-.468.442-.468zm15.6 0c.26 0 .442.208.442.468v6.552a.438.438 0 01-.442.442h-1.066c-.26 0-.468-.208-.468-.442v-6.552a.465.465 0 01.468-.468zm4.836 0q.754 0 1.43.312.676.312 1.17.806.494.52.78 1.196.286.676.286 1.43 0 .728-.286 1.404-.286.676-.78 1.196-.494.494-1.17.806-.65.312-1.43.312h-2.418a.456.456 0 01-.442-.442v-6.552c0-.26.208-.468.442-.468zm-11.778 1.664q-.416 0-.806.156-.364.156-.65.416-.286.286-.468.676-.156.364-.156.832 0 .442.156.806.182.39.468.676.286.26.65.416.39.156.806.156.416 0 .806-.156.364-.156.65-.416.312-.286.468-.676.156-.364.156-.806 0-.468-.156-.832-.156-.39-.468-.676-.286-.26-.65-.416-.39-.156-.806-.156zm-9.152-.078h-.156c-.156 0-.286.13-.286.312v3.536a.289.289 0 00.286.286h.156q.494 0 .91-.156.39-.156.65-.416.286-.286.416-.65.156-.39.156-.832 0-.442-.156-.832-.13-.39-.416-.65-.26-.286-.676-.442-.39-.156-.884-.156zm20.488 0h-.13a.3.3 0 00-.312.312v3.536c0 .156.13.286.312.286h.13q.52 0 .91-.156t.676-.416q.26-.286.416-.65.13-.39.13-.832 0-.442-.13-.832-.156-.39-.442-.65-.26-.286-.65-.442-.416-.156-.91-.156zM23.01 15.132l.624.312-2.418 1.482-.624-.312zm-.442-1.066l.65.338-2.418 1.482-.65-.338z"/></svg>
            imageData = "%253Csvg%2520xmlns%253D%2522http%253A%252F%252Fwww.w3.org%252F2000%252Fsvg%2522%2520viewBox%253D%25220%25200%2520128%2520128%2522%2520fill%253D%2522%2523fff%2522%253E%253Cdefs%253E%253CradialGradient%2520cx%253D%252230%2525%2522%2520cy%253D%2522-30%2525%2522%2520r%253D%25222%2522%2520id%253D%2522a%2522%253E%253Cstop%2520offset%253D%252220%2525%2522%2520stop-color%253D%2522%2523FFEA94%2522%252F%253E%253Cstop%2520offset%253D%252245%2525%2522%2520stop-color%253D%2522%2523D39750%2522%252F%253E%253Cstop%2520offset%253D%252280%2525%2522%2520stop-color%253D%2522%252351290F%2522%252F%253E%253C%252FradialGradient%253E%253C%252Fdefs%253E%253Crect%2520width%253D%2522100%2525%2522%2520height%253D%2522100%2525%2522%2520fill%253D%2522url(%2523a)%2522%252F%253E%253Cpath%2520fill-rule%253D%2522evenodd%2522%2520d%253D%2522M23.712%252015.99l2.6%25201.378c.338.208.546.546.546.936v5.902c0%2520.364-.182.676-.468.884l-2.756%25201.768a1.037%25201.037%25200%252001-1.092.052l-2.21-1.196%25203.796-2.288.026-4.42-2.86-1.508zm-1.69%25207.41l.624.312-2.418%25201.482-.624-.312zm-.416-1.066l.624.312-2.418%25201.482-.65-.312zm21.008-6.578q.91%25200%25201.664.312.754.312%25201.326.832.546.52.858%25201.248.286.702.286%25201.534%25200%2520.832-.286%25201.534-.312.728-.858%25201.248-.572.546-1.326.832-.754.312-1.664.312-.91%25200-1.664-.312-.754-.286-1.3-.832-.546-.52-.858-1.248-.312-.702-.312-1.534%25200-.832.312-1.534.312-.728.858-1.248t1.3-.832q.754-.312%25201.664-.312zm-22.568-3.12l2.106%25201.118-3.796%25202.314-.026%25204.394%25202.86%25201.534-2.418%25201.508-2.496-1.352c-.416-.208-.65-.65-.65-1.092v-5.668c0-.416.208-.832.572-1.066l2.548-1.638c.39-.26.884-.286%25201.3-.052zm13.858%25203.354q.754%25200%25201.43.312.676.312%25201.17.806.494.52.78%25201.196.286.676.286%25201.43%25200%2520.728-.286%25201.404-.286.676-.78%25201.196-.494.494-1.17.806-.65.312-1.43.312h-2.418a.456.456%25200%252001-.442-.442v-6.552c0-.26.208-.468.442-.468zm15.6%25200c.26%25200%2520.442.208.442.468v6.552a.438.438%25200%252001-.442.442h-1.066c-.26%25200-.468-.208-.468-.442v-6.552a.465.465%25200%252001.468-.468zm4.836%25200q.754%25200%25201.43.312.676.312%25201.17.806.494.52.78%25201.196.286.676.286%25201.43%25200%2520.728-.286%25201.404-.286.676-.78%25201.196-.494.494-1.17.806-.65.312-1.43.312h-2.418a.456.456%25200%252001-.442-.442v-6.552c0-.26.208-.468.442-.468zm-11.778%25201.664q-.416%25200-.806.156-.364.156-.65.416-.286.286-.468.676-.156.364-.156.832%25200%2520.442.156.806.182.39.468.676.286.26.65.416.39.156.806.156.416%25200%2520.806-.156.364-.156.65-.416.312-.286.468-.676.156-.364.156-.806%25200-.468-.156-.832-.156-.39-.468-.676-.286-.26-.65-.416-.39-.156-.806-.156zm-9.152-.078h-.156c-.156%25200-.286.13-.286.312v3.536a.289.289%25200%252000.286.286h.156q.494%25200%2520.91-.156.39-.156.65-.416.286-.286.416-.65.156-.39.156-.832%25200-.442-.156-.832-.13-.39-.416-.65-.26-.286-.676-.442-.39-.156-.884-.156zm20.488%25200h-.13a.3.3%25200%252000-.312.312v3.536c0%2520.156.13.286.312.286h.13q.52%25200%2520.91-.156t.676-.416q.26-.286.416-.65.13-.39.13-.832%25200-.442-.13-.832-.156-.39-.442-.65-.26-.286-.65-.442-.416-.156-.91-.156zM23.01%252015.132l.624.312-2.418%25201.482-.624-.312zm-.442-1.066l.65.338-2.418%25201.482-.65-.338z%2522%252F%253E%253C%252Fsvg%253E";
        }

        return
            string(
                abi.encodePacked(
                    // {"name":"DOID Lock Pass #
                    bytes("data:application/json;utf8,%7B%22name%22%3A%22DOID%20Lock%20Pass%20%23"),
                    tokenId.toString(),
                    // ","description":"A DOID lock pass, with
                    bytes("%22%2C%22description%22%3A%22A%20DOID%20lock%20pass%2C%20with%20"),
                    bytes(nameInDescription),
                    // .","image":"data:image/svg+xml;utf8,
                    bytes(".%22%2C%22image%22%3A%22data%3Aimage%2Fsvg%2Bxml%3Butf8%2C"),
                    bytes(imageData),
                    // "}
                    bytes("%22%7D")
                )
            );
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}