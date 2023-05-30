// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./MultiSigWalletProxy.sol";
import "./MultiSigWalletImplementation.sol";

contract MultiSigWalletFactory {

    event NewMultiSigWalletCreated(address wallet);

    function createMultiSigWallet(
        address _implementation,
        address[] memory owners,
        uint required,
        uint256 nonce
    ) public payable returns (address payable) {
        bytes32 salt = keccak256(abi.encodePacked(nonce, owners, required));
        bytes memory initCode = abi.encodePacked(
            type(MultiSigWalletProxy).creationCode,
            abi.encode(address(_implementation), abi.encodeWithSignature("initialize(address[],uint256)", owners, required))
        );

        address payable wallet;
        assembly {
            wallet := create2(0, add(initCode, 0x20), mload(initCode), salt)
            if iszero(extcodesize(wallet)) {
                revert(0, 0)
            }
        }

        emit NewMultiSigWalletCreated(wallet);

        return wallet;
    }
    
    function calculateMultiSigWalletAddress(
        address _implementation,
        address[] memory owners,
        uint required,
        uint256 nonce
    ) public view returns (address wallet) {
        bytes32 salt = keccak256(abi.encodePacked(nonce, owners, required));
        bytes memory initCode = abi.encodePacked(
            type(MultiSigWalletProxy).creationCode,
            abi.encode(address(_implementation), abi.encodeWithSignature("initialize(address[],uint256)", owners, required))
        );
        bytes32 hash = keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(initCode)
        ));

        return address(uint160(uint(hash)));
    }

    function createMultiSigWalletWithTransaction(
        address _implementation,
        address[] memory owners,
        uint required,
        uint256 nonce,
        MultiSigWalletImplementation.Transaction memory transaction,
        MultiSigWalletImplementation.Signature[] memory signatures
    ) public payable returns (address payable, bool) {
        address payable wallet = createMultiSigWallet(_implementation, owners, required, nonce);
        bool isOk = MultiSigWalletImplementation(wallet).batchSignature(transaction, signatures);
        return (wallet, isOk);
    }
}