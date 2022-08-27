//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../v1/A3SWallet.sol";

library A3SWalletHelper {
    function deployWallet(bytes32 salt) external returns (address) {
        address newWallet = Create2Upgradeable.deploy(
            0,
            salt,
            walletBytecode()
        );

        return newWallet;
    }

    function walletBytecode() public view returns (bytes memory) {
        bytes memory bytecode = type(A3SWallet).creationCode;
        return abi.encodePacked(bytecode, abi.encode(address(this)));
    }

    function walletAddress(bytes32 salt) external view returns (address) {
        return
            Create2Upgradeable.computeAddress(
                salt,
                keccak256(walletBytecode())
            );
    }
}