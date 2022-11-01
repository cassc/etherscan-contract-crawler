// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleHNSOracle is Ownable {
    using ECDSA for bytes32;
    address public notary;
    event NotaryChanged(address indexed oldNotary, address indexed newNotary);

    constructor(address _notary) {
        notary = _notary;
    }

    function setNotary(address _notary) external onlyOwner {
        emit NotaryChanged(notary, _notary);
        notary = _notary;
    }

    function verify(bytes32 nodeID, address registryAddress, address ownerAddress, bool locked,
        uint256 expire, bytes memory signature) public view returns (bool) {
        require(expire > block.timestamp, "proof expired");

        // must recover notary address
        return _hashMessage(nodeID, registryAddress, ownerAddress, locked, expire).recover(signature) == notary;
    }

    function _hashMessage(bytes32 nodeID, address registryAddress,
        address ownerAddress, bool locked, uint256 expire) internal pure returns(bytes32) {
        return keccak256(abi.encode(nodeID, registryAddress, ownerAddress, locked, expire))
               .toEthSignedMessageHash();
    }
}