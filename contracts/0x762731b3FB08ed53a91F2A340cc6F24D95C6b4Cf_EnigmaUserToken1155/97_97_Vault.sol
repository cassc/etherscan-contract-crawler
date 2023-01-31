// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "../utils/EIP712.sol";
import "../utils/AuthorizationBitmap.sol";
import "../utils/Types.sol";
import "../utils/BlockchainUtils.sol";

/// @notice A RBAC based Vault contract:
///             - Requires a signed payload
///             - If signature is ok, the transaction will be forwarded using call
/// @dev This contract was inspired by
///      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/MinimalForwarder.sol
contract Vault is AccessControlUpgradeable, ERC1155HolderUpgradeable, ERC721HolderUpgradeable, EIP712 {
    using AuthorizationBitmap for AuthorizationBitmap.Bitmap;

    bytes32 public constant ADMIN_ROLE = 0x00;
    bytes32 public constant SIGNER_ROLE = bytes32(uint256(0x01));

    AuthorizationBitmap.Bitmap private authorizationBitmap;
    bytes32 private constant FORWARD_REQUEST_TYPE_HASH =
        keccak256(
            // solhint-disable max-line-length
            "ForwardRequest(address to,uint256 value,uint256 nonce,bytes data)"
        );

    struct ForwardRequest {
        address to;
        uint256 value;
        uint256 nonce;
        bytes data;
    }

    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) EIP712(name, version) {}

    function initialize(address admin, address[] calldata signers) public initializer {
        __AccessControl_init();
        __ERC1155Holder_init();
        __ERC721Holder_init();
        _setupRole(ADMIN_ROLE, admin);
        // Setup signers
        uint256 signersLength = signers.length;
        for (uint256 i = 0; i < signersLength; i++) {
            _setupRole(SIGNER_ROLE, signers[i]);
        }
    }

    /// @notice Signature verification function.
    /// @param req request to be checked against the signature
    /// @param signature signature that authorizes the msg.sender to execute req
    /// @dev signature payload is made by req.to + req.value + req.nonce + keccak256(req.data) + the domain
    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        require(!authorizationBitmap.isAuthProcessed(req.nonce), "Vault: already processed");
        bytes32 digest =
            _hashTypedDataV4(
                keccak256(abi.encode(FORWARD_REQUEST_TYPE_HASH, req.to, req.value, req.nonce, keccak256(req.data)))
            );
        address signer = ECDSAUpgradeable.recover(digest, signature);
        return hasRole(SIGNER_ROLE, signer);
    }

    /// @notice Executes a transaction if the provided signature was made by someone whose role is SIGNER_ROLE.
    ///         - It will use this contract as msg.sender (ie. execute a call)
    ///         - Requests can only be executed once so they cannot be replayed
    ///         - It doesn't care who the signer is as long as the signature is ok
    /// @param req Request to be executed
    /// @param signature Signature made by a SIGNER that matches the req
    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(verify(req, signature), "Vault: signature does not match request");
        authorizationBitmap.setAuthProcessed(req.nonce);

        (bool success, bytes memory returndata) =
            // All the gas is forwarded as this is going to be used by Enigma and not the users
            // This is not a relayer as GSN
            req.to.call{ value: req.value }(req.data);

        require(success, _getRevertMsg(returndata));
        return (success, returndata);
    }

    /// @dev https://ethereum.stackexchange.com/a/83577
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        // solhint-disable-next-line
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}