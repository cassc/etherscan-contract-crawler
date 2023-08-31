// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./ISec.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "./ISecAccount.sol";

contract Sec is ISec, UUPSUpgradeable, Initializable {
    using ECDSA for bytes32;
    struct OwnerConfig {
        address[] _caAddress;
        address[] _guarding;
        uint256 _retrieveDelay;
    }
    struct Protect {
        address[] _eoa;
        mapping(address => uint256) protectStatus;
    }

    address public dg;

    mapping(address => OwnerConfig) _ownerConfig;

    mapping(address => address) _anOwner;

    mapping(address => Protect) _whoIProtect;

    mapping(address => mapping(address => bool)) caGuarding;

    mapping(address => uint256) public unlockTime;

    function ownerConfig(address owner)
        public
        view
        returns (OwnerConfig memory)
    {
        return _ownerConfig[owner];
    }

    function whoIProtect() public view returns (address[] memory) {
        Protect storage p = _whoIProtect[msg.sender];
        address[] memory addrs = p._eoa;
        uint256 len = addrs.length;
        uint256 caCounts = 0;
        for (uint256 i = 0; i < len; i++) {
            if (p.protectStatus[addrs[i]] == 1) {
                caCounts += _ownerConfig[addrs[i]]._caAddress.length;
            }
        }
        address[] memory protect = new address[](caCounts);
        caCounts = 0;
        for (uint256 i = 0; i < len; i++) {
            if (p.protectStatus[addrs[i]] == 1) {
                uint256 caLen = _ownerConfig[addrs[i]]._caAddress.length;
                for (uint256 j = 0; j < caLen; j++) {
                    protect[caCounts] = _ownerConfig[addrs[i]]._caAddress[j];
                    caCounts++;
                }
            }
        }
        return protect;
    }

    event Regist(address indexed ca, address indexed owner, uint256 registTime);

    function register(address _caOwner) public {
        require(_anOwner[msg.sender] == address(0), "ca address is active");
        _anOwner[msg.sender] = _caOwner;
        _ownerConfig[_caOwner]._caAddress.push(msg.sender);
        if (_ownerConfig[_caOwner]._guarding.length < 1) {
            addGdAccount(dg);
        }
        if (msg.sender.code.length > 0) {
            try ISecAccount(msg.sender).owner() returns (address anOnwer) {
                require(anOnwer == _caOwner, "regist must use ca owner");
            } catch {
                revert("register failed");
            }
            try ISecAccount(msg.sender).registerSuccess() {} catch {
                revert("register failed");
            }
        }
        emit Regist(msg.sender, _caOwner, block.timestamp);
    }

    function getCaAddress(address _owner)
        public
        view
        returns (address[] memory)
    {
        return _ownerConfig[_owner]._caAddress;
    }

    function isGuarding(address _owner, address _guarding)
        public
        view
        returns (bool)
    {
        address eoa;
        if (_owner.code.length > 0) {
            eoa = _anOwner[_owner];
        } else {
            eoa = _owner;
        }
        return caGuarding[eoa][_guarding];
    }

    event AddGD(address indexed eoa, address indexed gd, uint256 addTime);

    function addGdAccount(address gdAccount) public {
        require(msg.sender != gdAccount, "can not add yourself as gurading");
        address sender;
        if (msg.sender.code.length > 0) {
            sender = _anOwner[msg.sender];
            require(sender != gdAccount, "can not add yourself as gurading");
        } else {
            sender = msg.sender;
        }
        require(!caGuarding[sender][gdAccount], "account is your guarding");
        _ownerConfig[sender]._guarding.push(gdAccount);
        caGuarding[sender][gdAccount] = true;
        _whoIProtect[gdAccount]._eoa.push(sender);
        _whoIProtect[gdAccount].protectStatus[sender] = 1;
        emit AddGD(sender, gdAccount, block.timestamp);
    }

    event RmGD(address indexed eoa, address indexed gd, uint256 rmTime);

    function rmGdAccount(address gdAccount) public {
        address sender;
        if (msg.sender.code.length > 0) {
            sender = _anOwner[msg.sender];
        } else {
            sender = msg.sender;
        }
        require(caGuarding[sender][gdAccount], "account must be your guarding");

        OwnerConfig memory oldConfig = _ownerConfig[sender];
        delete _ownerConfig[sender];
        _ownerConfig[sender]._caAddress = oldConfig._caAddress;
        _ownerConfig[sender]._retrieveDelay = oldConfig._retrieveDelay;
        require(
            oldConfig._guarding.length > 1 || oldConfig._guarding[0] != dg,
            "You need at least one default guardian as your guardian!"
        );
        for (uint256 i = 0; i < oldConfig._guarding.length; i++) {
            if (oldConfig._guarding[i] != gdAccount) {
                _ownerConfig[sender]._guarding.push(oldConfig._guarding[i]);
            } else {
                caGuarding[sender][gdAccount] = false;
                _whoIProtect[gdAccount].protectStatus[sender] = 2;
                emit RmGD(sender, gdAccount, block.timestamp);
            }
        }
        if (_ownerConfig[sender]._guarding.length == 0) {
            _ownerConfig[sender]._guarding.push(dg);
            caGuarding[sender][dg] = true;
            _whoIProtect[gdAccount].protectStatus[dg] = 1;
            emit AddGD(sender, dg, block.timestamp);
        }
    }

    function getGdAddress(address _owner)
        public
        view
        returns (address[] memory)
    {
        return _ownerConfig[_owner]._guarding;
    }

    struct RetrieveSign {
        address _gurading;
        bytes _signature;
    }

    event Retrieve(
        address indexed oldOwner,
        address indexed newOwner,
        uint256 indexed retrieveNonce,
        address[] signatures
    );

    function retrieve(
        address anOldOwner,
        address anNewOwner,
        uint256 _nonce,
        uint48 validUntil,
        RetrieveSign[] calldata signatures
    ) public {
        address[] memory signer = checkSign(
            anOldOwner,
            anNewOwner,
            _nonce,
            validUntil,
            signatures
        );
        OwnerConfig memory oldConfig = _ownerConfig[anOldOwner];

        for (uint256 i = 0; i < oldConfig._guarding.length; i++) {
            if (!isGuarding(anNewOwner, oldConfig._guarding[i])) {
                _ownerConfig[anNewOwner]._guarding.push(oldConfig._guarding[i]);
                _whoIProtect[oldConfig._guarding[i]]._eoa.push(anNewOwner);
                _whoIProtect[oldConfig._guarding[i]].protectStatus[
                    anNewOwner
                ] = 1;
                _whoIProtect[oldConfig._guarding[i]].protectStatus[
                    anOldOwner
                ] = 2;
                caGuarding[anNewOwner][oldConfig._guarding[i]] = true;
            }
            caGuarding[anOldOwner][oldConfig._guarding[i]] = false;
        }

        uint256 len = oldConfig._caAddress.length;
        for (uint256 i = 0; i < len; i++) {
            _anOwner[oldConfig._caAddress[i]] = anNewOwner;
            _ownerConfig[anNewOwner]._caAddress.push(oldConfig._caAddress[i]);
            unlockTime[oldConfig._caAddress[i]] =
                block.timestamp +
                oldConfig._retrieveDelay;

            try
                ISecAccount(oldConfig._caAddress[i]).updateOwner(anNewOwner)
            {} catch {
                revert("recover failed");
            }
        }
        delete _ownerConfig[anOldOwner];
        emit Retrieve(anOldOwner, anNewOwner, _nonce, signer);
    }

    function checkSign(
        address anOldOwner,
        address anNewOwner,
        uint256 _nonce,
        uint48 validUntil,
        RetrieveSign[] calldata signatures
    ) public view returns (address[] memory) {
        require(block.timestamp < validUntil, "retrieve out of time");
        require(anOldOwner != anNewOwner, "owner must different");
        require(
            _ownerConfig[anOldOwner]._caAddress.length > 0,
            "you don't have ca address"
        );
        uint256 len = signatures.length;
        require(len >= 1, "at lease one gurading signature");
        require(
            (len * 10) >=
                ((_ownerConfig[anOldOwner]._guarding.length * 10) / 2),
            "don't have enough gurading signature"
        );
        address[] memory signer = new address[](len);
        bytes32 hash = getRetrieveHash(
            anOldOwner,
            anNewOwner,
            _nonce,
            validUntil
        );

        for (uint256 i = 0; i < len; i++) {
            if (signatures[i]._gurading.code.length > 0) {
                try
                    IERC1271(signatures[i]._gurading).isValidSignature(
                        ECDSA.toEthSignedMessageHash(hash),
                        signatures[i]._signature
                    )
                returns (bytes4 result) {
                    if (result != 0x1626ba7e) {
                        try
                            IERC1271(signatures[i]._gurading).isValidSignature(
                                hash,
                                signatures[i]._signature
                            )
                        returns (bytes4 oldResult) {
                            if (oldResult != 0x1626ba7e) {
                                require(false, "gurading sign not pass");
                            }
                        } catch {
                            require(false, "gurading sign not pass");
                        }
                    }
                } catch {
                    require(false, "gurading sign not pass");
                }
            } else {
                require(
                    signatures[i]._gurading ==
                        ECDSA.recover(
                            ECDSA.toEthSignedMessageHash(hash),
                            signatures[i]._signature
                        ),
                    "gurading sign not pass"
                );
            }
            isUniqueAddress(signer, signatures[i]._gurading);
            signer[i] = signatures[i]._gurading;
        }
        return signer;
    }

    event RetrieveDebug(
        address indexed oldOwner,
        address indexed newOwner,
        uint256 indexed retrieveStemp,
        uint256 debugIndex,
        OwnerConfig oldConfig,
        OwnerConfig newConfig
    );

    error SuccessDebug(address oldOwner, address newOwner);

    function checkRetieve(address anOldOwner, address anNewOwner) public {
        OwnerConfig memory oldConfig = _ownerConfig[anOldOwner];

        for (uint256 i = 0; i < oldConfig._guarding.length; i++) {
            if (!isGuarding(anNewOwner, oldConfig._guarding[i])) {
                _ownerConfig[anNewOwner]._guarding.push(oldConfig._guarding[i]);
                _whoIProtect[oldConfig._guarding[i]]._eoa.push(anNewOwner);
                _whoIProtect[oldConfig._guarding[i]].protectStatus[
                    anNewOwner
                ] = 1;
                _whoIProtect[oldConfig._guarding[i]].protectStatus[
                    anOldOwner
                ] = 2;
                caGuarding[anNewOwner][oldConfig._guarding[i]] = true;
                caGuarding[anOldOwner][oldConfig._guarding[i]] = false;
            }
        }
        emit RetrieveDebug(
            anOldOwner,
            anNewOwner,
            block.timestamp,
            0,
            oldConfig,
            _ownerConfig[anNewOwner]
        );
        uint256 len = oldConfig._caAddress.length;
        for (uint256 i = 0; i < len; i++) {
            _anOwner[oldConfig._caAddress[i]] = anNewOwner;
            _ownerConfig[anNewOwner]._caAddress.push(oldConfig._caAddress[i]);
            unlockTime[oldConfig._caAddress[i]] =
                block.timestamp +
                oldConfig._retrieveDelay;

            try
                ISecAccount(oldConfig._caAddress[i]).updateOwner(anNewOwner)
            {} catch {
                revert("recover failed");
            }
        }
        emit RetrieveDebug(
            anOldOwner,
            anNewOwner,
            block.timestamp,
            1,
            oldConfig,
            _ownerConfig[anNewOwner]
        );

        delete _ownerConfig[anOldOwner];
        emit RetrieveDebug(
            anOldOwner,
            anNewOwner,
            block.timestamp,
            2,
            oldConfig,
            _ownerConfig[anNewOwner]
        );
        revert SuccessDebug(anOldOwner, anNewOwner);
    }

    function getRetrieveHash(
        address anOldOwner,
        address anNewOwner,
        uint256 _nonce,
        uint48 validUntil
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encode(anOldOwner, anNewOwner, _nonce, validUntil));
    }

    address[] public administrator;

    mapping(address => uint256) adminIndex;

    function isAdmin(address _admin) public view returns (bool) {
        return adminIndex[_admin] > 0;
    }

    function addControllers(
        address _admin,
        uint256 _nonce,
        uint48 validUntil,
        bytes[] calldata _signature
    ) public returns (address[] memory) {
        require(adminIndex[_admin] == 0, "address is already administrator");

        checkAdminSignature(_admin, _nonce, validUntil, _signature);
        administrator.push(_admin);
        adminIndex[_admin] = administrator.length;
        return administrator;
    }

    function delControllers(
        address _admin,
        uint256 _nonce,
        uint48 validUntil,
        bytes[] calldata _signature
    ) public returns (address[] memory) {
        require(adminIndex[_admin] != 0, "address is not administrator");

        checkAdminSignature(_admin, _nonce, validUntil, _signature);
        uint256 _adminIndex = adminIndex[_admin];

        address lastAddress = administrator[administrator.length - 1];
        administrator[_adminIndex - 1] = lastAddress;
        adminIndex[lastAddress] = _adminIndex;

        adminIndex[_admin] = 0;
        administrator.pop();
        return administrator;
    }

    function checkAdminSignature(
        address _admin,
        uint256 _nonce,
        uint48 validUntil,
        bytes[] calldata _signature
    ) public view {
        require(block.timestamp < validUntil, "retrieve out of time");
        require(
            (_signature.length * 10) >= (administrator.length * 10) / 2,
            "signature is not enough"
        );
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            getAdminHash(_admin, _nonce, validUntil)
        );
        address[] memory signer = new address[](_signature.length);
        for (uint256 i = 0; i < _signature.length; i++) {
            address recoverSigner = ECDSA.recover(hash, _signature[i]);
            require(
                adminIndex[recoverSigner] > 0,
                "signatrue is not from admin"
            );
            isUniqueAddress(signer, recoverSigner);
            signer[i] = recoverSigner;
        }
    }

    function isUniqueAddress(address[] memory _arrayAddress, address newAddress)
        internal
        pure
    {
        for (uint256 i = 0; i < _arrayAddress.length; i++) {
            require(
                _arrayAddress[i] != newAddress,
                "can not use the same account for signature"
            );
        }
    }

    function getAdminHash(
        address _admin,
        uint256 _nonce,
        uint48 validUntil
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_admin, _nonce, validUntil));
    }

    address public authorizedAddress;

    function setAuthorizedAddress(
        address _authorizedAddress,
        uint256 _nonce,
        uint48 validUntil,
        bytes[] calldata _signature
    ) public {
        checkAdminSignature(_authorizedAddress, _nonce, validUntil, _signature);
        authorizedAddress = _authorizedAddress;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        view
        override
    {
        (newImplementation);
        require(newImplementation == authorizedAddress, "unauthorized address");
    }

    function initialize(address _dg) public initializer {
        dg = _dg;
        _anOwner[address(this)] = _dg;
    }

    function getAddr(bytes32 hash, bytes calldata signature)
        public
        pure
        returns (address)
    {
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature);
    }
}