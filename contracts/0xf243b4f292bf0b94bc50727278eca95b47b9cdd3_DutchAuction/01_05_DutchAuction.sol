// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Address} from "@openzeppelin/utils/Address.sol";
import {MerkleProof} from "@openzeppelin/utils/cryptography/MerkleProof.sol";

import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";

struct AuctionDetails {
    uint256 startTime;
    uint256 endTime;
    uint256 totalTokens;
    uint256 startPrice;
    uint256 minimumPrice;
}

error NoCommitmentRegistered();
error PleaseSendETH();
error AuctionHasNotStarted();
error AuctionHasFinalized();
error AuctionHasNotFinalized();
error ClaimTokensInstead();
error NotInvited();

contract DutchAuction {
    using Address for address payable;

    event FinalizedAuction(uint256 timestamp);
    event ClaimedPRTC(address indexed who, uint256 amount);
    event CommittedETH(address indexed who, uint256 amount);
    event RefundETH(address indexed who, uint256 amount);

    uint256 private constant WAD = 1e18;
    uint256 private constant INVITE_LIST_PERIOD = 2 days;

    IERC20 public immutable prtc;
    address public immutable beneficiary;
    bytes32 public immutable merkleRoot;

    AuctionDetails public auctionDetails;

    uint256 public totalCommitments;
    bool public isAuctionFinalized;

    mapping(address user => uint256 amountCommitted) public commitments;

    constructor(
        IERC20 _prtc,
        address _beneficiary,
        bytes32 _merkleRoot,
        AuctionDetails memory _auctionDetails
    ) {
        prtc = _prtc;
        beneficiary = _beneficiary;
        auctionDetails = _auctionDetails;
        merkleRoot = _merkleRoot;
    }

    /// @notice Method to claim `prtc` tokens if auction is successful.
    /// @dev If auction is successful, user is not required to wait until auction `finalizes`.
    function claimTokens() external {
        if (!auctionSuccessful()) revert AuctionHasNotFinalized();
        if (commitments[msg.sender] == 0) revert NoCommitmentRegistered();

        uint256 amountForUser =
            commitments[msg.sender] * auctionDetails.totalTokens / totalCommitments;

        delete commitments[msg.sender];

        prtc.transfer(msg.sender, amountForUser);

        emit ClaimedPRTC(msg.sender, amountForUser);
    }

    /// @notice Method to claim ETH if auction does not succeed.
    function claimETH() external {
        if (!isAuctionFinalized) revert AuctionHasNotFinalized();
        if (commitments[msg.sender] == 0) revert NoCommitmentRegistered();
        if (auctionSuccessful()) revert ClaimTokensInstead();

        uint256 amount = commitments[msg.sender];

        delete commitments[msg.sender];

        payable(msg.sender).sendValue(amount);

        emit RefundETH(msg.sender, amount);
    }

    /// @notice Method to call for concluding the dutch auction.
    /// @dev If the auction is successful, this method can be called
    /// ahead of time (by anyone) since it will not take any more ETH anyways.
    function finalizeAuction() external {
        if (isAuctionFinalized) revert AuctionHasFinalized();
        if (!(block.timestamp > auctionDetails.endTime || auctionSuccessful())) {
            revert AuctionHasNotFinalized();
        }

        isAuctionFinalized = true;

        if (auctionSuccessful()) {
            // It should be the same as `totalCommitted`
            payable(beneficiary).sendValue(address(this).balance);
        } else {
            // It should be the same as `prtc.balanceOf(address(this))`
            prtc.transfer(beneficiary, auctionDetails.totalTokens);
        }

        emit FinalizedAuction(block.timestamp);
    }

    /// @notice Method to call when participating in the auction.
    /// Must send ETH when calling it.
    /// @dev For a refund to happen, it must be the *last* purchase
    /// that exceeds the amount.
    function commitETH(bytes32[] calldata _mp) external payable {
        if (block.timestamp < auctionDetails.startTime) revert AuctionHasNotStarted();
        if (isAuctionFinalized || auctionSuccessful() || block.timestamp > auctionDetails.endTime) {
            revert AuctionHasFinalized();
        }
        if (msg.value == 0) revert PleaseSendETH();
        if (!_verifyMerkleProof(_mp)) revert NotInvited();

        uint256 commitment = _calculateCommitment(msg.value);

        uint256 maybeRefund = msg.value - commitment;

        commitments[msg.sender] += commitment;
        totalCommitments += commitment;

        emit CommittedETH(msg.sender, commitment);

        if (maybeRefund != 0) {
            payable(msg.sender).sendValue(maybeRefund);
            emit RefundETH(msg.sender, maybeRefund);
        }
    }

    /// @notice If the auction is successful, the contract shouldn't accept any more ETH.
    function auctionSuccessful() public view returns (bool) {
        return tokenPrice() >= clearingPrice();
    }

    /// @notice The greatest value between the the `tokenPrice` and
    /// the `priceFunction`.
    function clearingPrice() public view returns (uint256) {
        uint256 _tokenPrice = tokenPrice();
        uint256 _currentPrice = priceFunction();

        return _tokenPrice > _currentPrice ? _tokenPrice : _currentPrice;
    }

    function tokenPrice() public view returns (uint256) {
        return totalCommitments * WAD / auctionDetails.totalTokens;
    }

    function priceFunction() public view returns (uint256) {
        if (block.timestamp <= auctionDetails.startTime) return auctionDetails.startPrice;
        if (block.timestamp >= auctionDetails.endTime) return auctionDetails.minimumPrice;

        uint256 auctionDuration = auctionDetails.endTime - auctionDetails.startTime;

        uint256 timeSinceAuctionStart = block.timestamp - auctionDetails.startTime;
        uint256 deltaPrice = auctionDetails.startPrice - auctionDetails.minimumPrice;

        return auctionDetails.startPrice - (timeSinceAuctionStart * deltaPrice / auctionDuration);
    }

    function _calculateCommitment(uint256 _amount) internal view returns (uint256) {
        uint256 maxCommitment = auctionDetails.totalTokens * clearingPrice() / WAD;

        if (totalCommitments + _amount <= maxCommitment) return _amount;

        return maxCommitment - totalCommitments;
    }

    function _verifyMerkleProof(bytes32[] calldata mp) internal view returns (bool) {
        if (block.timestamp >= auctionDetails.startTime + INVITE_LIST_PERIOD) return true;

        return MerkleProof.verifyCalldata(mp, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }
}