//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract WhitelistedPoolVerifier {
    using ECDSA for bytes32;

    address private _signer;

    event SignerUpdated(address newSigner);
    
    function getSigner() external view returns (address) {
        return _signer;
    }

    function isValidSignature(string calldata _salt, uint256 _poolId, address _wallet, bytes memory _signature)
        public view returns(bool) {
        return _hash(_salt, _poolId, _wallet)
               .toEthSignedMessageHash()
               .recover(_signature) == _signer;
    }

    function _setSigner(address _newSigner) internal {
        _signer = _newSigner;
        emit SignerUpdated(_signer);
    }

    // hash payload containing: salt + launchpad address + poolId + whitelisted address
    function _hash(string calldata _salt, uint256 _poolId, address _wallet) internal view returns (bytes32) {
        return keccak256(abi.encode(_salt, address(this), _poolId, _wallet));
    }
}