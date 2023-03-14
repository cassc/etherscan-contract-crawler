// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./RewardNFT.sol";
import "./PlaceholderNFT.sol";
import "./ReentrancyGuard.sol";
import "./MyOwnable.sol";

contract NFTStakerV2 is ERC721Holder, MyOwnable, ReentrancyGuard {
    ERC721[] public stakedNfts; // 10,000 Quirklings, 5,000 Quirkies

    PlaceholderNFT public placeholderNft;
    RewardNFT public rewardNft;

    uint256 stakeMinimum;
    uint256 stakeMaximum;
    // uint256 stakePeriod = 30 * 24 * 60 * 60; // 30 Days
    uint256 stakePeriod;

    mapping(uint256 => bool) public claimedNfts;

    struct Staker {
        uint256[] tokenIds;
        uint256[] placeholderTokenIds;
        uint256[] timestamps;
    }

    mapping(address => Staker) private stakers;
    address[] stakersAddresses;

    modifier notInitialized() {
        require(!initialized, "Contract instance has already been initialized");
        _;
    }

    bool private initialized;

    event StakeSuccessful(uint256 tokenId, uint256 timestamp);

    event UnstakeSuccessful(uint256 tokenId, bool rewardClaimed);

    function initialize(
        uint256 _stakeMinimum,
        uint256 _stakeMaximum,
        uint256 _stakingPeriod,
        address _ownerAddress,
        address[] memory _stakedNfts,
        address _placeholderNftAddress,
        address _rewardNftAddress
    ) public nonReentrant notInitialized {
        stakeMinimum = _stakeMinimum;
        stakeMaximum = _stakeMaximum;
        stakePeriod = _stakingPeriod;

        _transferOwnership(_msgSender());

        for (uint256 i = 0; i < _stakedNfts.length; i++) {
            stakedNfts.push(ERC721(_stakedNfts[i]));
        }

        placeholderNft = PlaceholderNFT(_placeholderNftAddress);
        rewardNft = RewardNFT(_rewardNftAddress);

        transferOwnership(_ownerAddress);
        initialized = true;
    }

    function tokenIdToCollectionIndex(
        uint256 _tokenId
    ) public pure returns (uint256) {
        if (_tokenId < 10000) return 0;
        return 1;
    }

    // take list of stake Nft, mint same amount of placeHolderNft
    // burning optional (only if there)
    function stake(uint256[] memory _tokenIds) public nonReentrant {
        uint256 _quantity = _tokenIds.length;
        require(
            _quantity >= stakeMinimum && _quantity <= stakeMaximum,
            "Stake amount incorrect"
        );

        for (uint256 i = 0; i < _quantity; i++) {
            require(claimedNfts[_tokenIds[i]] == false, "NFT already claimed");
            require(
                stakedNfts[tokenIdToCollectionIndex(_tokenIds[i])].ownerOf(
                    _tokenIds[i] % 10_000
                ) == msg.sender,
                "You do not own this Nft"
            );
        }

        for (uint256 i = 0; i < _quantity; i++) {
            stakedNfts[tokenIdToCollectionIndex(_tokenIds[i])].safeTransferFrom(
                    msg.sender,
                    address(this),
                    _tokenIds[i] % 10_000
                );
            uint256 _placeholderTokenId = placeholderNft.mintNFT(
                msg.sender,
                _tokenIds[i]
            );
            stakers[msg.sender].tokenIds.push(_tokenIds[i]);
            stakers[msg.sender].placeholderTokenIds.push(_placeholderTokenId);
            stakers[msg.sender].timestamps.push(block.timestamp);

            emit StakeSuccessful(_tokenIds[i], block.timestamp);
        }

        stakersAddresses.push(msg.sender);
    }

    function findIndexForTokenStaker(
        uint256 _tokenId,
        address _stakerAddress
    ) private view returns (uint256, bool) {
        Staker memory _staker = stakers[_stakerAddress];

        uint256 _tokenIndex = 0;
        bool _foundIndex = false;

        uint256 _tokensLength = _staker.tokenIds.length;
        for (uint256 i = 0; i < _tokensLength; i++) {
            // console.log("_staker.tokenIds[i]: ", _staker.tokenIds[i]);
            if (_staker.tokenIds[i] == _tokenId) {
                _tokenIndex = i;
                _foundIndex = true;
                break;
            }
        }

        return (_tokenIndex, _foundIndex);
    }

    function unstake(uint256[] memory _tokenIds) public nonReentrant {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            (uint256 _tokenIndex, bool _foundIndex) = findIndexForTokenStaker(
                _tokenIds[i],
                msg.sender
            );
            require(_foundIndex, "Index not found for this staker.");

            stakedNfts[tokenIdToCollectionIndex(_tokenIds[i])].safeTransferFrom(
                    address(this),
                    msg.sender,
                    _tokenIds[i] % 10_000
                );
            if (
                placeholderNft.ownerOf(
                    stakers[msg.sender].placeholderTokenIds[_tokenIndex]
                ) == msg.sender
            ) {
                placeholderNft.safeTransferFrom(
                    msg.sender,
                    0x000000000000000000000000000000000000dEaD,
                    stakers[msg.sender].placeholderTokenIds[_tokenIndex]
                );
            }

            bool stakingTimeElapsed = block.timestamp >
                stakers[msg.sender].timestamps[_tokenIndex] + stakePeriod;

            if (stakingTimeElapsed) {
                rewardNft.mintNFT(msg.sender, _tokenIds[i]);
                claimedNfts[_tokenIds[i]] = true;
            }
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            (uint256 _tokenIndex, bool _foundIndex) = findIndexForTokenStaker(
                _tokenIds[i],
                msg.sender
            );
            require(_foundIndex, "Index not found for this staker.");
            bool stakingTimeElapsed = block.timestamp >
                stakers[msg.sender].timestamps[_tokenIndex] + stakePeriod;

            removeStakerElement(
                msg.sender,
                _tokenIndex,
                stakers[msg.sender].tokenIds.length - 1
            );

            emit UnstakeSuccessful(_tokenIds[i], stakingTimeElapsed);
        }
    }

    function removeStakerElement(
        address _user,
        uint256 _tokenIndex,
        uint256 _lastIndex
    ) internal {
        stakers[_user].timestamps[_tokenIndex] = stakers[_user].timestamps[
            _lastIndex
        ];
        stakers[_user].timestamps.pop();

        stakers[_user].tokenIds[_tokenIndex] = stakers[_user].tokenIds[
            _lastIndex
        ];
        stakers[_user].tokenIds.pop();

        stakers[_user].placeholderTokenIds[_tokenIndex] = stakers[_user]
            .placeholderTokenIds[_lastIndex];
        stakers[_user].placeholderTokenIds.pop();
    }

    function isTokenStaked(uint256 _tokenId) public view returns (bool) {
        uint256 _tokensLength = stakers[msg.sender].tokenIds.length;
        for (uint256 i = 0; i < _tokensLength; i++) {
            if (stakers[msg.sender].tokenIds[i] == _tokenId) {
                return true;
            }
        }
        return false;
    }

    function getPlaceholderTokenIds(
        address _user
    ) public view returns (uint256[] memory tokenIds) {
        return stakers[_user].placeholderTokenIds;
    }

    function getStakedTokens(
        address _user
    ) public view returns (uint256[] memory tokenIds) {
        return stakers[_user].tokenIds;
    }

    function getStakedTimestamps(
        address _user
    ) public view returns (uint256[] memory timestamps) {
        return stakers[_user].timestamps;
    }

    function getStakerAddresses() public view returns (address[] memory) {
        return stakersAddresses;
    }

    function setStakeMaximum(uint256 _stakeMaximum) public onlyOwner {
        stakeMaximum = _stakeMaximum;
    }
}