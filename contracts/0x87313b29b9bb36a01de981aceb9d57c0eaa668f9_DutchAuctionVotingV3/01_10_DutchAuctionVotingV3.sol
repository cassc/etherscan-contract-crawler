// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

contract DutchAuctionVotingV3 is Initializable,
        OwnableUpgradeable {

    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToUintMap;

    struct VoteCount {
        uint256 price;
        uint256 count;
    }

    bytes32 public merkleRoot;
    uint256 public startAt;
    uint256 public endAt;
    uint256 public refundAt;
    uint256 public startingPrice;
    uint256 public discountRate;
    uint256 public maxVotes;

    EnumerableMapUpgradeable.AddressToUintMap private votes;
    EnumerableMapUpgradeable.UintToUintMap private voteCounts;
    mapping (address => bool) private withdraw;
    address public nftContractAddress;

    function initialize() public initializer {
        __Ownable_init();
    }

    function setup(uint256 _startAt,
                   uint256 _startingPrice,
                   uint256 _discountRate,
                   uint256 _duration,
                   uint256 _refundAt,
                   uint256 _maxVotes) external onlyOwner {
        require(_duration > 0, "Duration should larger than 0");
        require(_maxVotes > 0, "Max number of votes should larger than 0");
        require(_refundAt >= (_startAt + _duration), "Refund should start after voting");
        require(_startingPrice >= (_discountRate * (_duration / 3600)), "Invalid starting price or discount rate");

        startAt = _startAt;
        endAt = _startAt + _duration;
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        refundAt = _refundAt;
        maxVotes = _maxVotes;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function vote(bytes32[] calldata proof) external payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(block.timestamp <= endAt, "Voting ended");
        require(votes.length() < maxVotes, "Out of quota");
        require(!votes.contains(msg.sender), "Already voted");
        require(_verify(proof, merkleRoot, _leaf(msg.sender)), "Invalid merkle proof");

        uint256 currPrice = getCurrentPrice();
        require(currPrice / 10 <= msg.value, "Not enough tokens");

        votes.set(msg.sender, msg.value);
        if (voteCounts.contains(currPrice)) {
            voteCounts.set(currPrice, voteCounts.get(currPrice) + 1);
        } else {
            voteCounts.set(currPrice, 1);
        }
    }

    function _leaf(address account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) private pure returns (bool) {
        return MerkleProofUpgradeable.verify(proof, root, leaf);
    }

    function getCurrentPrice() public view returns (uint256) {
        if (block.timestamp > endAt) {
            return 0;
        }

        uint256 timeElapsed = (block.timestamp - startAt) / 3600;
        uint256 discount = discountRate * timeElapsed;
        return startingPrice - discount;
    }

    function withdrawTokens() external {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(block.timestamp > refundAt, "Refund has not started");
        require(votes.contains(msg.sender), "No vote record");
        require(!withdraw[msg.sender], "Already withdraw");
        require(IERC721Upgradeable(nftContractAddress).balanceOf(msg.sender) > 0, "No NFT found");

        withdraw[msg.sender] = true;
        payable(msg.sender).transfer(votes.get(msg.sender));
    }

    function withdrawByOwner(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    function setNFTContractAddress(address addr) external onlyOwner {
        nftContractAddress = addr;
    }

    function numberOfVotes() external view returns (uint256) {
        return votes.length();
    }

    function voteCost(address addr) external view returns (uint256) {
        if (!votes.contains(addr)) {
            return 0;
        }
        return votes.get(addr);
    }

    function getVoterList(uint256 startIndex, uint256 count) external view returns (address[] memory) {
        address[] memory voters;
        if (startIndex >= votes.length()) {
            return voters;
        } else if (startIndex + count >= votes.length()) {
            count = votes.length() - startIndex;
        }

        uint256 index = 0;
        address voter;
        uint256 votePrice;
        voters = new address[](count);
        for (index; index < count; index++) {
            (voter, votePrice) = votes.at(startIndex + index);
            voters[index] = voter;
        }
        return voters;
    }

    function getVotedPrices() external view returns (VoteCount[] memory) {
        VoteCount[] memory voteResult = new VoteCount[](voteCounts.length());

        uint256 index = 0;
        uint256 price;
        uint256 count;
        for (index; index < voteCounts.length(); index++) {
            (price, count) = voteCounts.at(index);
            voteResult[index].price = price;
            voteResult[index].count = count;
        }
        return voteResult;
    }
}