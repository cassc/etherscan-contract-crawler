//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import { IVerifier } from "./IVerifier.sol";

interface IZkpAirdrop {
    error ZKPL__AlreadySpent();
    error ZKPL__Expired();
    error ZKPL__InvalidProof();
    error ZKPL__InvalidRoot();
    error ZKPL__LengthMismatch();
    error ZKPL__ZeroAddress();

    event RootAdded(uint256 newRoot);

    event VerifierUpdated(IVerifier previousVerifier, IVerifier newAddress);

    event Withdrawn(address asset, address recipient, uint256 value, uint256 nullifierHash);

    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    struct WithdrawInput {
        uint256 root;
        uint256 nullifierHash;
        uint256 value;
        address recipient;
        address asset;
        uint256 deadline;
    }

    function withdraw(Proof calldata proof_, WithdrawInput calldata withdrawInput_) external;
}