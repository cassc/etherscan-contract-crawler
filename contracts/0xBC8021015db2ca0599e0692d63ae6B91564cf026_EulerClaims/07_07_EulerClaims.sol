// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**********
By clicking "I agree to the terms to claim redemption" on the euler.finance web interface or executing the EulerClaims smart contract and accepting the redemption, I hereby irrevocably and unconditionally release all claims I (or my company or other separate legal entity) may have against Euler Labs, Ltd., the Euler Foundation, the Euler Decentralized Autonomous Organization, members of the Euler Decentralized Autonomous Organization, and any of their agents, affiliates, officers, employees, or principals related to this matter, whether such claims are known or unknown at this time and regardless of how such claims arise and the laws governing such claims (which shall include but not be limited to any claims arising out of Euler’s terms of use).  This release constitutes an express and voluntary binding waiver and relinquishment to the fullest extent permitted by law.  If I am acting for or on behalf of a company (or other such separate entity), by clicking "I agree to the terms to claim redemption" on the euler.finance web interface or executing the EulerClaims smart contract and accepting the redemption and agreement, I confirm that I am duly authorised to enter into this contract on its behalf.

This agreement and all disputes relating to or arising under this agreement (including the interpretation, validity or enforcement thereof) will be governed by and subject to the laws of England and Wales and the courts of London, England shall have exclusive jurisdiction to determine any such dispute.  To the extent that the terms of this release are inconsistent with any previous agreement and/or Euler’s terms of use, I accept that these terms take priority and, where necessary, replace the previous terms.
**********/

contract EulerClaims is ReentrancyGuard {
    //
    // The following is a hash of the above terms and conditions.
    //
    // By sending a transaction and claiming the redemption tokens, I understand and manifest my assent
    // and agreement to be bound by the enforceable contract on this page, and agree that all claims or
    // disputes under this agreement will be resolved exclusively by the courts of London, England in
    // accordance with the laws of England and Wales. If I am acting for or on behalf of a company (or
    // other such separate entity), by signing and sending a transaction I confirm that I am duly
    // authorised to enter into this contract on its behalf.
    //
    bytes32 constant private termsAndConditionsHash = 0x427a506ff6e15bd1b7e4e93da52c8ec95f6af1279618a2f076946e83d8294996;

    string public constant name = "EulerClaims";

    address public owner;
    bytes32 public merkleRoot;
    mapping(uint => bool) public alreadyClaimed; // index -> yes/no

    struct TokenAmount {
        address token;
        uint amount;
    }

    event OwnerChanged(address indexed newOwner);
    event ClaimedAndAgreed(uint indexed index, address indexed account);
    event ClaimedByOwner(uint indexed index);
    event MerkleRootUpdated(bytes32 indexed newMerkleRoot);

    // Owner functions

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "unauthorized");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "owner is zero");
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }

    function updateMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
        emit MerkleRootUpdated(newMerkleRoot);
    }

    function recoverTokens(uint[] calldata indexList, TokenAmount[] calldata tokenAmounts) external onlyOwner nonReentrant {
        for (uint i = 0; i < indexList.length; ++i) {
            uint index = indexList[i];
            require(!alreadyClaimed[index], "already claimed");
            alreadyClaimed[index] = true;
            emit ClaimedByOwner(index);
        }

        for (uint i = 0; i < tokenAmounts.length; ++i) {
            SafeERC20.safeTransfer(IERC20(tokenAmounts[i].token), owner, tokenAmounts[i].amount);
        }
    }

    function recoverEth(uint amount) external onlyOwner nonReentrant {
        (bool success,) = owner.call{value: amount}("");
        require(success, "send eth failed");
    }

    // Public functions

    /// @notice Claim tokens from Euler Redemption
    /// @param acceptanceToken Custom token demonstrating the caller's agreement with the Terms and Conditions of the claim (see contract source code)
    /// @param index Index of distribution being claimed in the merkle tree
    /// @param tokenAmounts List of (token, amount) pairs for this claim
    /// @param proof Merkle proof that validates this claim
    function claimAndAgreeToTerms(bytes32 acceptanceToken, uint index, TokenAmount[] calldata tokenAmounts, bytes32[] calldata proof) external nonReentrant {
        require(acceptanceToken == keccak256(abi.encodePacked(msg.sender, termsAndConditionsHash)), "please read the terms and conditions");

        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encode(index, msg.sender, tokenAmounts))), "proof invalid");

        require(!alreadyClaimed[index], "already claimed");
        alreadyClaimed[index] = true;
        emit ClaimedAndAgreed(index, msg.sender);

        for (uint i = 0; i < tokenAmounts.length; ++i) {
            SafeERC20.safeTransfer(IERC20(tokenAmounts[i].token), msg.sender, tokenAmounts[i].amount);
        }
    }
}