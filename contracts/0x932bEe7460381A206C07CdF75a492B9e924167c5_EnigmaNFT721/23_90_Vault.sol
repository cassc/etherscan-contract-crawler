// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "../utils/AuthorizationBitmap.sol";
import "../utils/Types.sol";
import "../utils/BlockchainUtils.sol";

/// @notice A RBAC based Vault contract:
///             - Requires a signed payload
///             - If signature is ok, the transaction will be forwarded using call
/// @dev This contract was inspired by
///      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/MinimalForwarder.sol
contract Vault is AccessControlUpgradeable, ERC1155Holder, ERC721Holder {
    using AuthorizationBitmap for AuthorizationBitmap.Bitmap;

    bytes32 public constant ADMIN_ROLE = 0x00;
    bytes32 public constant SIGNER_ROLE = bytes32(uint256(0x01));

    AuthorizationBitmap.Bitmap private authorizationBitmap;

    struct ForwardRequest {
        address to;
        uint256 value;
        uint256 nonce;
        bytes data;
    }

    function initialize(address admin, address[] calldata signers) public initializer {
        __AccessControl_init();
        _setupRole(ADMIN_ROLE, admin);
        // Setup signers
        uint256 signersLength = signers.length;
        for (uint256 i = 0; i < signersLength; i++) {
            _setupRole(SIGNER_ROLE, signers[i]);
        }
    }

    /// @notice Signature verification function.
    /// @param req request to be checked against the signature
    /// @param signature signature made by one of the SIGNERS.
    ///                  It requires the chainId to be included in the signature as first param as well
    ///                  as the contract address
    /// @dev signature payload is bade by chainId + req.to + req.value + req.nonce + keccak256(req.data)
    function verify(ForwardRequest calldata req, Signature calldata signature) public view returns (bool) {
        require(!authorizationBitmap.isAuthProcessed(req.nonce), "Vault: already processed");

        bytes32 hash =
            keccak256(
                abi.encodePacked(
                    BlockchainUtils.getChainID(),
                    address(this),
                    req.to,
                    req.value,
                    req.nonce,
                    keccak256(req.data)
                )
            );
        address signer =
            ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
                signature.v,
                signature.r,
                signature.s
            );
        return hasRole(SIGNER_ROLE, signer);
    }

    /// @notice Executes a transaction if the provided signature was made by someone whose role is SIGNER_ROLE.
    ///         - It will use this contract as msg.sender (ie. execute a call)
    ///         - Requests can only be executed once so they cannot be replayed
    ///         - It doesn't care who the signer is as long as the signature is ok
    /// @param req Request to be executed
    /// @param signature Signature made by a SIGNER that matches the req
    function execute(ForwardRequest calldata req, Signature calldata signature)
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