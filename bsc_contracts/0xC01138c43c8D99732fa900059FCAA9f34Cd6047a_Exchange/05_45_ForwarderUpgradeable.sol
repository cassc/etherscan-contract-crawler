// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ForwarderUpgradeable is Initializable, EIP712Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using ECDSAUpgradeable for bytes32;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    struct ForwardRequest {
        address from;
        address to;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 nonce,bytes data)");

    mapping(address => mapping(uint256=> bool)) private _nonces;

    function initialize() initializer public {
        __ForwarderUpgradeable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function __ForwarderUpgradeable_init() internal onlyInitializing {
        __EIP712_init_unchained("Forwarder", "1.0.0");
    }

    function __ForwarderUpgradeable_init_unchained() internal onlyInitializing {}

    function getNonce(address from, uint256 nonce) public view returns (bool) {
        return _nonces[from][nonce];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.nonce, keccak256(req.data)))
        ).recover(signature);
        
        return signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(verify(req, signature), "MinimalForwarder: signature does not match request");

        (bool success, bytes memory returndata) = req.to.call(
            abi.encodePacked(req.data, req.from)
        );

        return (success, returndata);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}