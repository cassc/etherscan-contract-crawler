// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/// @notice This is the Staking Contract for the Vendetta Society NFT Collection

error VSStaking__NotOwner();
error VSStaking__TokenAlreadyStaked();
error VSStaking__TransferFailed();
error VSStaking__StakingNotOpen();

contract VSStaking is ERC721Holder, Ownable {

    /// @notice Object Structure for Token ID Staking Info
    struct Stake {
        uint256 timestamp;
        address owner;
    }

    /// @notice Minimum Time an NFT has to be staked to recieve rewards (30 days)
    uint256 public minimumTime = 2592000;

    /// @notice Vendetta Society Minting Contract Address
    IERC721A public nftAddress;

    bool public isStakingOpen;

    event NFTStaked(address owner, uint256 tokenId, uint256 timestamp);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 timestamp);

    /// @notice Get staking details for a given Token ID
    mapping(uint256 => Stake) public vault;

    /// @param _nftAddress Vendetta Society Minting Contract Address
    constructor(address _nftAddress) {
        nftAddress = IERC721A(_nftAddress);
        isStakingOpen = false;
    }

    /// @notice Stakes a given token ID. Token ID is transferred from sender to this contract
    /// @param _tokenIds[] Token ID
    function stakeMany(uint256[] calldata _tokenIds) public {
        if (!isStakingOpen) revert VSStaking__StakingNotOpen();

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 currentTokenId = _tokenIds[i];
            if (nftAddress.ownerOf(currentTokenId) == msg.sender) {
                vault[currentTokenId] = Stake({
                    timestamp: uint256(block.timestamp),
                    owner: msg.sender
                });
                nftAddress.transferFrom(msg.sender, address(this), currentTokenId);
                emit NFTStaked(msg.sender, currentTokenId, block.timestamp);
            }
        }
    }

    /// @notice Unstakes an array of given Token IDs. Token ID is transferred from this contract to sender
    /// @param _tokenIds[] Token IDs
    function unstakeMany(uint256[] calldata _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 currentTokenId = _tokenIds[i];
            Stake memory staked = vault[currentTokenId];
            if (staked.owner == msg.sender) {
                delete vault[currentTokenId];
                nftAddress.transferFrom(address(this), msg.sender, currentTokenId);
                emit NFTUnstaked(msg.sender, currentTokenId, block.timestamp);
            }
        }
    }

    /// @notice Force Unstaked an array of token IDs. Owner Only
    /// @param _tokenIds[] Array of Token Ids
    function forceUnstakeMany(uint256[] calldata _tokenIds) public onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 currentTokenId = _tokenIds[i];
            Stake memory staked = vault[currentTokenId];
            if (staked.timestamp != 0) {
                delete vault[currentTokenId];
                nftAddress.transferFrom(address(this), staked.owner, currentTokenId);
                emit NFTUnstaked(staked.owner, currentTokenId, block.timestamp);
            }
        }
    }

    /// @notice Sends a divided number of ETH to all valid token Ids. 
    /// @param _validTokenIds All token IDs who have staked for at least 30 days
    function depositAndDistributeRewards(uint256[] memory _validTokenIds) public payable onlyOwner {
        uint256 reward = msg.value / _validTokenIds.length;

        for (uint i = 0; i < _validTokenIds.length; i++) {
            uint256 tokenId = _validTokenIds[i];
            Stake memory stakeDetails = vault[tokenId];
            if (block.timestamp - stakeDetails.timestamp >= minimumTime) {
                (bool os,) = payable(stakeDetails.owner).call{value: reward}("");
                if (!os) revert VSStaking__TransferFailed();
            }
        }
    }

    /// @notice Sets the 'isStakingOpen' state variable
    /// @param _status True / False
    function toggleStakingOpen(bool _status) public onlyOwner {
        isStakingOpen = _status;
    }

    /// @notice Sets the NFT address
    /// @param _nftAddress Vendetta Society Minting Contract Address
    function setNftAddress(address _nftAddress) public onlyOwner {
        nftAddress = IERC721A(_nftAddress);
    }

    /// @notice Sets the minimum time for a valid staker
    /// @param _minimumTime Seconds amount of minimum time
    function setMinimumTime(uint256 _minimumTime) public onlyOwner {
        minimumTime = _minimumTime;
    }

    function isValidStaker(uint256 _tokenId) public view returns (bool status, address owner) {
        Stake memory stakeDetails = vault[_tokenId];
        if (stakeDetails.timestamp == 0) {
            return (false, stakeDetails.owner);
        }
        if (block.timestamp - stakeDetails.timestamp >= minimumTime) {
            return (true, stakeDetails.owner);
        } else {
            return (false, stakeDetails.owner);
        }
    }

    /// @notice Withdraws all ETH from contract
    function withdraw() public payable onlyOwner {
        (bool os,) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}