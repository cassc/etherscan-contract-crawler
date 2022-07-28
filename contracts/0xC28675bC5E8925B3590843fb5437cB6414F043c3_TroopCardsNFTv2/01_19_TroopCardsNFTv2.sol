// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./IEpochRewardDistributorv2.sol";

enum NFTType {
    COMMON,
    RARE,
    UNIQUE
}

/**
 * @title TroopCardsNFT
 * @author iamsahu
 */
contract TroopCardsNFTv2 is ERC721Tradable {
    mapping(address => bool) public rewardDistributor;
    mapping(NFTType => address) public nftTypeRewardDistributor;
    mapping(uint256 => bool) public nftStakeStatus;

    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Troop Cards NFT", "TCNFT", _proxyRegistryAddress)
    {}

    modifier onlyRewardDistributor() {
        require(rewardDistributor[msg.sender]);
        _;
    }

    function baseTokenURI() public pure override returns (string memory) {
        return
            "https://gateway.pinata.cloud/ipfs/QmTztvatuPvieg4RgjieaYmd7forCeEVe26ERyFeFzKpqU/";
    }

    function contractURI() public pure returns (string memory) {
        return
            "https://gateway.pinata.cloud/ipfs/QmbviX7E7kZWZfvn3yE4YReAU27Ej7kudLDeqXp8oKcXjv";
    }

    function setRewardDistributor(address newRewardDistributor, NFTType nftType)
        public
        onlyOwner
    {
        rewardDistributor[newRewardDistributor] = true;
        nftTypeRewardDistributor[nftType] = newRewardDistributor;
    }

    function _stakeNFT(address account, uint256 id) internal {
        require(ownerOf(id) == account, "user doesn't own the nft");
        require(!nftStakeStatus[id], "NFT is already staked");
        nftStakeStatus[id] = true;
    }

    function stakeNFT(address account, uint256 id)
        external
        onlyRewardDistributor
    {
        _stakeNFT(account, id);
    }

    function stakeNFTs(address account, uint256[] memory ids)
        external
        onlyRewardDistributor
    {
        for (uint256 index = 0; index < ids.length; index++) {
            _stakeNFT(account, ids[index]);
        }
    }

    function _unstakeNFT(address account, uint256 id) internal {
        require(ownerOf(id) == account, "user doesn't own the nft");
        require(nftStakeStatus[id], "NFT is not staked");
        nftStakeStatus[id] = false;
    }

    function unstakeNFT(address account, uint256 id)
        external
        onlyRewardDistributor
    {
        _unstakeNFT(account, id);
    }

    function unstakeNFTs(address account, uint256[] memory ids)
        external
        onlyRewardDistributor
    {
        for (uint256 index = 0; index < ids.length; index++) {
            _unstakeNFT(account, ids[index]);
        }
    }

    /**
     * @dev Overrides safeTransferFrom function of ERC1155 to introduce nftStakeStatus check
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        bytes memory _data
    ) public override {
        // check if nft is being used
        require(!nftStakeStatus[_id], "NFT is staked");
        super.safeTransferFrom(_from, _to, _id, _data);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id
    ) public override {
        // check if nft is being used
        require(!nftStakeStatus[_id], "NFT is staked");
        super.safeTransferFrom(_from, _to, _id);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal override {
        address validRewardDistributor = nftTypeRewardDistributor[
            getNFTType(id)
        ];
        if (from != address(0) && validRewardDistributor != address(0)) {
            IEpochRewardDistributorv2(validRewardDistributor)
                .beforeTransferRewards(id, from);
        }
        super._beforeTokenTransfer(from, to, id);
    }

    // function burn(
    //     address _from,
    //     uint256 _id,
    //     uint256 _amount
    // ) public override onlyOwner {
    //     // check if nft is being used
    //     require(!nftStakeStatus[_id], "NFT is staked");
    //     super.burn(_from, _id, _amount);
    // }

    function getNFTType(uint256 nftId) internal pure returns (NFTType) {
        require(nftId != 0, "Invalid NFT ID");

        uint256 effectiveId = ((nftId - 1) % 111) + 1;
        if (effectiveId < 101) return NFTType.COMMON;
        if (effectiveId < 111) return NFTType.RARE;
        return NFTType.UNIQUE;
    }

    function claimAllRewards(
        uint256[] calldata commonNFTs,
        uint256[] calldata rareNFTs,
        uint256[] calldata uniqueNFTs
    ) external {
        if (commonNFTs.length > 0) {
            IEpochRewardDistributorv2(nftTypeRewardDistributor[NFTType.COMMON])
                .claimRewardsOfUser(msg.sender, commonNFTs);
        }
        if (rareNFTs.length > 0) {
            IEpochRewardDistributorv2(nftTypeRewardDistributor[NFTType.RARE])
                .claimRewardsOfUser(msg.sender, commonNFTs);
        }
        if (uniqueNFTs.length > 0) {
            IEpochRewardDistributorv2(nftTypeRewardDistributor[NFTType.UNIQUE])
                .claimRewardsOfUser(msg.sender, commonNFTs);
        }
    }
}