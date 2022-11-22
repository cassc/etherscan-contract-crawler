// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./BalenseaMarketplace.sol";

contract AceWalletStaking is Ownable {
    BalenseaMarketplace private marketplace;

    // nft collection address => token ID => staking details
    mapping(address => mapping(uint256 => Stake)) public stakingList;

    modifier onlySupportedNFT(address _nft) {
        require(marketplace.creators(_nft) != address(0), "NFT not supported");
        _;
    }

    event StakeNFT(address nft, uint256 tokenId, address owner, uint256 date);
    event UnstakeNFT(
        address nft,
        uint256 tokenId,
        address owner,
        uint256 stakingDate,
        uint256 unstakingDate,
        string poolId
    );

    struct Stake {
        uint256 stakingDatetime;
        address owner;
        string poolId;
    }

    constructor(address _marketplace) {
        marketplace = BalenseaMarketplace(_marketplace);
    }

    function stake(
        address _nft,
        uint256 _tokenId,
        string calldata poolId
    ) external onlySupportedNFT(_nft) {
        require(
            IERC721(_nft).ownerOf(_tokenId) == msg.sender,
            "NFT is not owned by sender"
        );
        require(
            IERC721(_nft).isApprovedForAll(msg.sender, address(this)),
            "Owner not yet approve contract"
        );

        Stake memory newStake = Stake(block.timestamp, msg.sender, poolId);
        stakingList[_nft][_tokenId] = newStake;

        IERC721(_nft).transferFrom(msg.sender, address(this), _tokenId);

        emit StakeNFT(_nft, _tokenId, msg.sender, newStake.stakingDatetime);
    }

    function unstake(address _nft, uint256 _tokenId)
        external
        onlySupportedNFT(_nft)
    {
        require(
            stakingList[_nft][_tokenId].owner == msg.sender,
            "NFT is not owned by sender"
        );

        Stake memory data = stakingList[_nft][_tokenId];
        delete stakingList[_nft][_tokenId];

        IERC721(_nft).transferFrom(address(this), data.owner, _tokenId);

        emit UnstakeNFT(
            _nft,
            _tokenId,
            data.owner,
            data.stakingDatetime,
            block.timestamp,
            data.poolId
        );
    }

    function isStaking(address _nft, uint256 _tokenId)
        external
        view
        returns (bool)
    {
        Stake memory target = stakingList[_nft][_tokenId];
        return (target.owner != address(0)) && (target.stakingDatetime != 0);
    }
}