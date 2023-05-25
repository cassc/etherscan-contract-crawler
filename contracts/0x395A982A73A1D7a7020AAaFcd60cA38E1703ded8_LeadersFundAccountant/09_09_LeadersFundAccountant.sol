// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IAlphaFund } from "./IAlphaFund.sol";
import { IDelegationRegistry } from "./IDelegationRegistry.sol";

/*
I see you nerd! ⌐⊙_⊙
*/

contract LeadersFundAccountant is Ownable, Pausable, ReentrancyGuard {
    address constant public RL_CONTRACT = 0x163a7af239b409E79a32fC6b437Fda51dd8fa5F0;
    address constant public DELEGATE_CASH_CONTRACT = 0x00000000000076A84feF008CDAbe6409d2FE638B;

    IAlphaFund public alphaFund;

    mapping (uint256 => bytes32) public merkleRoots;
    mapping (uint256 => uint256) public payoutsPerShare;
    mapping(uint256 => mapping(address => bool)) public claimed;

    // errors
    error InvalidProof();
    error AlreadyClaimed();
    error NotEnoughShares();
    error InvalidPayoutId(uint256 payId);
    error InvalidDelegate(address requester, address vault);

    event PayoutReleased(address to, address vault, uint256 numShares, uint256 payoutId, uint256 amount);
    event PayoutDelegated(address to, address vault, uint256 numSharesDelegated, uint256 numSharesBought, uint256 payoutId, uint256 buyInAmount);

    constructor(address alphaFundAddress) {
        alphaFund = IAlphaFund(alphaFundAddress);
        _pause();
    }

    function setAlphaFundAddress(address alphaFundAddress) external onlyOwner {
        alphaFund = IAlphaFund(alphaFundAddress);
    }

    function setPayout(bytes32 merkleRoot, uint256 newPayoutId, uint256 payoutPerShare) external payable onlyOwner {
        merkleRoots[newPayoutId] = merkleRoot;
        payoutsPerShare[newPayoutId] = payoutPerShare;
    }

    function withdraw(uint256 amount) external onlyOwner {
        Address.sendValue(payable(msg.sender), amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function hashLeaf(address holder, uint256 numShares) public pure returns (bytes32) {
        return keccak256(
            bytes.concat(
                keccak256(
                    abi.encode(holder, numShares)
                )
            )
        );
    }

    function claimPayout(uint256 payId, uint256 numShares, address vault, bytes32[] calldata merkleProof) external nonReentrant whenNotPaused {
        address requester = _verifyClaim(payId, numShares, vault, merkleProof);

        uint256 amount = payoutsPerShare[payId] * numShares;

        // Interactions
        Address.sendValue(payable(msg.sender), amount);
        emit PayoutReleased(msg.sender, requester, numShares, payId, amount);
    }

    function delegatePayout(uint256 payId, uint256 numShares, uint256 numSharesDelegated, uint256 numSharesToBuy, address vault, bytes32[] calldata merkleProof) external payable nonReentrant whenNotPaused {
        if (numSharesDelegated > numShares) {
            revert NotEnoughShares();
        }

        address requester = _verifyClaim(payId, numShares, vault, merkleProof);

        // Interaction #1: Buy Alpha tokens
        uint256 buyInAmount = payoutsPerShare[payId] * numSharesDelegated + msg.value;
        alphaFund.buyIn{value: buyInAmount}(numSharesToBuy, msg.sender);
        emit PayoutDelegated(msg.sender, requester, numSharesDelegated, numSharesToBuy, payId, buyInAmount);

        // Interaction #2: Claim the rest
        if (numShares > numSharesDelegated) {
            uint256 numSharesToClaim = numShares - numSharesDelegated;
            uint256 claimAmount = payoutsPerShare[payId] * numSharesToClaim;

            Address.sendValue(payable(msg.sender), claimAmount);
            emit PayoutReleased(msg.sender, requester, numSharesToClaim, payId, claimAmount);
        }
    }

    function _verifyClaim(uint256 payId, uint256 numShares, address vault, bytes32[] calldata merkleProof) internal returns (address) {
        address requester = msg.sender;

        // Check for valid payout Id
        if (merkleRoots[payId] == 0) {
            revert InvalidPayoutId(payId);
        }

        // Delegate cash check if the claim is delegated
        if (vault != address(0)) { 
            bool isDelegateValid = IDelegationRegistry(DELEGATE_CASH_CONTRACT).checkDelegateForContract(msg.sender, vault, RL_CONTRACT);
            if (!isDelegateValid) {
                revert InvalidDelegate(msg.sender, vault);
            }
            requester = vault;
        }

        // Check to confirm not already claimed
        if(claimed[payId][requester]) {
            revert AlreadyClaimed();
        }

        // Check merkle proof for valid holder and shares
        if (!MerkleProof.verify(merkleProof, merkleRoots[payId], hashLeaf(requester, numShares))) {
            revert InvalidProof();
        }

        // Effects before interactions
        claimed[payId][requester] = true;

        return requester;
    }

    receive () external payable virtual {
        //
    }
}