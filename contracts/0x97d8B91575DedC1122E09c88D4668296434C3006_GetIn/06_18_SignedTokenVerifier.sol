// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ECDSA.sol";

contract SignedTokenVerifier {
    using ECDSA for bytes32;

    address private _signer;
    event SignerUpdated(address newSigner);

    constructor() {}

    function _setSigner(address _newSigner) internal {
        _signer = _newSigner;
        emit SignerUpdated(_signer);
    }

    function _hash(
        string calldata _salt,
        uint256[] memory _ticketId,
        uint256[] memory _purchaseUsersId,
        address _address
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _salt,
                    _ticketId,
                    _purchaseUsersId,
                    address(this),
                    _address
                )
            );
    }

    function _recover(bytes32 hash, bytes memory token)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function getAddress(
        string calldata _salt,
        uint256[] memory _ticketId,
        uint256[] memory _purchaseUsersId,
        bytes calldata _token,
        address _address
    ) internal view returns (address) {
        return
            _recover(
                _hash(_salt, _ticketId, _purchaseUsersId, _address),
                _token
            );
    }

    function verifyTokenForAddress(
        string calldata _salt,
        uint256[] memory _ticketId,
        uint256[] memory _purchaseUsersId,
        bytes calldata _token,
        address _address
    ) public view returns (bool) {
        return
            getAddress(_salt, _ticketId, _purchaseUsersId, _token, _address) ==
            _signer;
    }
}