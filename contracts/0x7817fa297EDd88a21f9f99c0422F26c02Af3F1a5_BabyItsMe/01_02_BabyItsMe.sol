// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.20;

import "src/Verifier.sol";

contract BabyItsMe is Verifier {
    // This is the BabyJubjub public key A = (x, y) we want to impersonate.
    uint256 constant PK_X = 4342719913949491028786768530115087822524712248835451589697801404893164183326;
    uint256 constant PK_Y = 4826523245007015323400664741523384119579596407052839571721035538011798951543;

    mapping(address => uint256) public solved;

    // Make sure you first call `verifyProof` with the actual proof,
    // and then use your solving address as the solution.
    function verify(uint256 _start, uint256 _solution) external view returns (bool) {
        return solved[address(uint160(_solution))] == _start;
    }

    // The zkSNARK verifier expects as public inputs the BabyJubjub public key
    // A that is signing the message M and the message itself.
    // The zero knowledge proof shows that the msg.sender knows a valid
    // signature (s, R) for public key A and message M, without revealing the
    // signature.
    function verifyProof(Proof memory _proof) external returns (bool) {
        uint256 start = generate(msg.sender);
        bool user_solved = 0 == verify([PK_X, PK_Y, start, uint256(uint160(msg.sender))], _proof);
        if (user_solved) {
            solved[msg.sender] = start;
            return true;
        }

        return false;
    }

    // Specific message that the challenger has to sign.
    // We remove the 3 LSB to make the number fit in the used prime field.
    function generate(address _who) public pure returns (uint256) {
        return uint256(keccak256(abi.encode("Baby it's me, ", _who))) >> 3;
    }
}