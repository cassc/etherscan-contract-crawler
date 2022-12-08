// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IPaperKeyManager.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

/// @custom:security-contact [email protected]
contract PaperKeyManagerUpgradeable is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IPaperKeyManager
{
    mapping(address => address) private contractToPaperKeyMapping;
    mapping(address => mapping(bytes32 => bool))
        private contractToNoncesMapping;

    using ECDSAUpgradeable for bytes32;

    event RegisteredPaperKey(
        address indexed contractAddress,
        address indexed paperKey
    );
    event UpdatedPaperKey(
        address indexed contractAddress,
        address indexed paperKey
    );
    event DeletedPaperKey(address indexed contractAddress);
    event Verified(bytes32 indexed nonce, bytes indexed signature);

    modifier batchCallCompliant(
        address[] calldata _contracts,
        address[] calldata _paperKey
    ) {
        require(
            _contracts.length == _paperKey.length,
            "_contracts and _paperKey arguments have different length"
        );
        require(
            _contracts.length < 200,
            "Trying to update to many contracts at once"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function checkRegisteredKey(address _contractAddress)
        external
        view
        override
        returns (address)
    {
        return contractToPaperKeyMapping[_contractAddress];
    }

    function register(address _paperKey) public override returns (bool) {
        contractToPaperKeyMapping[msg.sender] = _paperKey;
        emit RegisteredPaperKey(msg.sender, _paperKey);
        return true;
    }

    function registerBatch(
        address[] calldata _contracts,
        address[] calldata _paperKeys
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        batchCallCompliant(_contracts, _paperKeys)
        returns (bool)
    {
        for (uint8 i = 0; i < _contracts.length; ++i) {
            address contractAddress = _contracts[i];
            address paperKey = _paperKeys[i];
            contractToPaperKeyMapping[contractAddress] = paperKey;
            emit RegisteredPaperKey(contractAddress, paperKey);
        }
        return true;
    }

    function verify(
        bytes32 _hash,
        bytes32 _nonce,
        bytes calldata _signature
    ) external override returns (bool) {
        bytes32 signedMessage = keccak256(abi.encodePacked(_hash, _nonce));
        bytes32 signedHash = ECDSAUpgradeable.toEthSignedMessageHash(
            signedMessage
        );
        address recoveredAddress = signedHash.recover(_signature);
        require(
            recoveredAddress == contractToPaperKeyMapping[msg.sender],
            "Invalid signature or hash"
        );
        require(
            !contractToNoncesMapping[msg.sender][_nonce],
            "Signature already used"
        );
        contractToNoncesMapping[msg.sender][_nonce] = true;
        emit Verified(_nonce, _signature);
        return true;
    }

    function update(address _contractAddress, address _newPaperKey)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        require(
            contractToPaperKeyMapping[_contractAddress] != address(0),
            "_contractAddress has not been registered"
        );
        contractToPaperKeyMapping[_contractAddress] = _newPaperKey;
        emit UpdatedPaperKey(_contractAddress, _newPaperKey);
        return true;
    }

    function updateBatch(
        address[] calldata _contracts,
        address[] calldata _paperKeys
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        batchCallCompliant(_contracts, _paperKeys)
        returns (bool)
    {
        for (uint8 i = 0; i < _contracts.length; ++i) {
            address contractAddress = _contracts[i];
            address paperKey = _paperKeys[i];
            update(contractAddress, paperKey);
        }
        return true;
    }

    function remove(address _contractAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        require(
            contractToPaperKeyMapping[_contractAddress] != address(0),
            "_contractAddress does not exists"
        );
        delete contractToPaperKeyMapping[_contractAddress];
        emit DeletedPaperKey(_contractAddress);
        return true;
    }

    function removeBatch(address[] calldata _contractAddresses)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        for (uint256 i = 0; i < _contractAddresses.length; ++i) {
            address contractAddress = _contractAddresses[i];
            remove(contractAddress);
        }
        return true;
    }

    /// DO NOT REMOVE
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}