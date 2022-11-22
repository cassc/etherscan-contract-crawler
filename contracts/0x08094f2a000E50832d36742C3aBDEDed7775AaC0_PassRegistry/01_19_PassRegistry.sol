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
    mapping(bytes32 => address) hashToOwner;
    mapping(bytes32 => string) hashToName;
    mapping(uint => PassInfo) passInfo;
    CountersUpgradeable.Counter internal passId;
    mapping(bytes32 => bool) reserveNames;
    mapping(address => bool) userActivated;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * The size of the __gap array is calculated so that the amount of storage used by a
     * contract always adds up to the same number (in this case 50 storage slots).
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[42] private __gap;
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

    function initialize(
        address _admin,
        string memory _name,
        string memory _symbol
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        __ERC721_init(_name, _symbol);
        passId._value = 100000;
    }

    function updatePassIdStart(uint _start) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        passId._value = _start;
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
        bytes32 hashedName = keccak256(abi.encodePacked(_name));
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

        emit LockPass(msg.sender, passNum);
    }

    /**
     * @notice lock a name with given passid
     */
    function lockName(uint _passId, string memory _name) external {
        bytes32 hashedName = keccak256(abi.encodePacked(_name));
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
            return false;
        }

        //lock name
        hashToName[_hashedName] = _name;
        hashToOwner[_hashedName] = msg.sender;
        passInfo[_passId].passHash = _hashedName;
        // init invatations at first time
        if (userInvitesMax[msg.sender] == 0) {
            userInvitedNum[msg.sender] = 0;
            userInvitesMax[msg.sender] = 3 * balanceOf(msg.sender);
        }

        emit LockName(msg.sender, _passId, _name);
        return true;
    }

    function lockAndMint(string memory _name, address _to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        passId.increment();
        uint _passId = passId.current();
        passInfo[_passId] = PassInfo({passId: _passId, passClass: ClassC, passHash: 0});
        _mint(msg.sender, _passId);
        bytes32 hashedName = keccak256(abi.encodePacked(_name));
        delete reserveNames[hashedName];
        require(_lockName(_passId, _name, hashedName, 2), "IN");
        _transfer(msg.sender, _to, _passId);
    }

    /**
     * @notice request user's pass list
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
        return hashToName[_hash];
    }

    function getUserByHash(bytes32 _hash) public view returns (address) {
        return hashToOwner[_hash];
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
        return reserveNames[keccak256(bytes(_name))];
    }

    /**
     * @notice check if name has already been registered
     */
    function nameExists(string memory _name) public view returns (bool) {
        // is locked before
        bytes32 nameHash = keccak256(bytes(_name));
        if (reserveNames[nameHash]) {
            return true;
        }
        if (hashToOwner[nameHash] == address(0)) {
            return false;
        }
        return true;
    }

    function nameAvaliable(uint _minLen, string memory _name) public view returns (bool) {
        if (!lenValid(_minLen, _name)) {
            return false;
        }

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

        string memory nameInfo;
        PassInfo memory _passInfo = passInfo[tokenId];
        if (_passInfo.passHash != 0) {
            nameInfo = string(
                abi.encodePacked(bytes(getNameByHash(_passInfo.passHash)), bytes(".doid%20locked"))
            );
        } else nameInfo = "no%20name%20locked%20yet";

        return
            string(
                abi.encodePacked(
                    bytes("data:application/json;utf8,%7B%22name%22%3A%22DOID%20Lock%20Pass%20%23"),
                    tokenId.toString(),
                    bytes("%22%2C%22description%22%3A%22A%20DOID%20lock%20pass%2C%20with%20"),
                    bytes(nameInfo),
                    bytes(
                        ".%22%2C%22image%22%3A%22data%3Aimage%2Fsvg%2Bxml%3Butf8%2C"
                        "%253Csvg%2520xmlns%253D%2522http%253A%252F%252Fwww.w3.org%252F2000%252Fsvg%2522%2520viewBox%253D%25220%25200%2520128%2520150%2522%2520fill%253D%2522%2523373737%2522%253E%253Cdefs%253E%253CradialGradient%2520cx%253D%252230%2525%2522%2520cy%253D%2522-30%2525%2522%2520r%253D%25222%2522%2520id%253D%2522a%2522%253E%253Cstop%2520offset%253D%252220%2525%2522%2520stop-color%253D%2522%2523FFEA94%2522%252F%253E%253Cstop%2520offset%253D%252245%2525%2522%2520stop-color%253D%2522%2523D39750%2522%252F%253E%253Cstop%2520offset%253D%252280%2525%2522%2520stop-color%253D%2522%252351290F%2522%252F%253E%253C%252FradialGradient%253E%253C%252Fdefs%253E%253Crect%2520width%253D%2522100%2525%2522%2520height%253D%2522100%2525%2522%2520fill%253D%2522url(%2523a)%2522%252F%253E%253Cpath%2520fill-rule%253D%2522evenodd%2522%2520d%253D%2522M23.712%252015.99l2.6%25201.378c.338.208.546.546.546.936v5.902c0%2520.364-.182.676-.468.884l-2.756%25201.768a1.037%25201.037%25200%252001-1.092.052l-2.21-1.196%25203.796-2.288.026-4.42-2.86-1.508zm-1.69%25207.41l.624.312-2.418%25201.482-.624-.312zm-.416-1.066l.624.312-2.418%25201.482-.65-.312zm21.008-6.578q.91%25200%25201.664.312.754.312%25201.326.832.546.52.858%25201.248.286.702.286%25201.534%25200%2520.832-.286%25201.534-.312.728-.858%25201.248-.572.546-1.326.832-.754.312-1.664.312-.91%25200-1.664-.312-.754-.286-1.3-.832-.546-.52-.858-1.248-.312-.702-.312-1.534%25200-.832.312-1.534.312-.728.858-1.248t1.3-.832q.754-.312%25201.664-.312zm-22.568-3.12l2.106%25201.118-3.796%25202.314-.026%25204.394%25202.86%25201.534-2.418%25201.508-2.496-1.352c-.416-.208-.65-.65-.65-1.092v-5.668c0-.416.208-.832.572-1.066l2.548-1.638c.39-.26.884-.286%25201.3-.052zm13.858%25203.354q.754%25200%25201.43.312.676.312%25201.17.806.494.52.78%25201.196.286.676.286%25201.43%25200%2520.728-.286%25201.404-.286.676-.78%25201.196-.494.494-1.17.806-.65.312-1.43.312h-2.418a.456.456%25200%252001-.442-.442v-6.552c0-.26.208-.468.442-.468zm15.6%25200c.26%25200%2520.442.208.442.468v6.552a.438.438%25200%252001-.442.442h-1.066c-.26%25200-.468-.208-.468-.442v-6.552a.465.465%25200%252001.468-.468zm4.836%25200q.754%25200%25201.43.312.676.312%25201.17.806.494.52.78%25201.196.286.676.286%25201.43%25200%2520.728-.286%25201.404-.286.676-.78%25201.196-.494.494-1.17.806-.65.312-1.43.312h-2.418a.456.456%25200%252001-.442-.442v-6.552c0-.26.208-.468.442-.468zm-11.778%25201.664q-.416%25200-.806.156-.364.156-.65.416-.286.286-.468.676-.156.364-.156.832%25200%2520.442.156.806.182.39.468.676.286.26.65.416.39.156.806.156.416%25200%2520.806-.156.364-.156.65-.416.312-.286.468-.676.156-.364.156-.806%25200-.468-.156-.832-.156-.39-.468-.676-.286-.26-.65-.416-.39-.156-.806-.156zm-9.152-.078h-.156c-.156%25200-.286.13-.286.312v3.536a.289.289%25200%252000.286.286h.156q.494%25200%2520.91-.156.39-.156.65-.416.286-.286.416-.65.156-.39.156-.832%25200-.442-.156-.832-.13-.39-.416-.65-.26-.286-.676-.442-.39-.156-.884-.156zm20.488%25200h-.13a.3.3%25200%252000-.312.312v3.536c0%2520.156.13.286.312.286h.13q.52%25200%2520.91-.156t.676-.416q.26-.286.416-.65.13-.39.13-.832%25200-.442-.13-.832-.156-.39-.442-.65-.26-.286-.65-.442-.416-.156-.91-.156zM23.01%252015.132l.624.312-2.418%25201.482-.624-.312zm-.442-1.066l.65.338-2.418%25201.482-.65-.338z%2522%252F%253E%253C%252Fsvg%253E"
                        "%22%7D"
                    )
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