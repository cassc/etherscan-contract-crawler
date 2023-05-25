// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract NFTPledge is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    struct TokenStakeInfo {
        uint64 tokenId;
        uint64 startTimestamp;
        uint64 stakeDays;
        uint64 extrData;
    }

    mapping(address => EnumerableSet.UintSet) userStake;
    mapping(address => uint256) public userStakeScore;
    IERC721 NFT;

    event ApproveStake(address owner, uint256 tokenId);
    event TransferStake(address owner, uint256 tokenId, bytes data);

    constructor() {
        NFT = IERC721(msg.sender);
    }

    function numberStake(address owner) external view returns (uint256) {
        return userStake[owner].length();
    }

    function getStakeInfos(
        address owner,
        uint256 from,
        uint256 limit
    ) external view returns (uint256 total, TokenStakeInfo[] memory items) {
        total = userStake[owner].length();
        uint256 length = from > total ? 0 : from + limit >= total ? total - from : limit;
        items = new TokenStakeInfo[](length);
        for (uint256 index = 0; index < length; index++) {
            items[index] = _unpackedTokenStake(userStake[owner].at(from + index));
        }
    }

    function stakeNFT(uint256 _tokenId) external {
        //approve this address
        NFT.transferFrom(msg.sender, address(this), _tokenId);
        _stakeNFT(msg.sender, _tokenId);

        emit ApproveStake(msg.sender, _tokenId);
    }

    function _stakeNFT(address _owner, uint256 _tokenId) private {
        uint256 pake = _packTokenStake(uint64(_tokenId), uint64(block.timestamp), 7, 0);
        userStake[_owner].add(pake);
    }

    function unStakeNFT(uint256[] calldata indexs) external {
        for (uint i = 0; i < indexs.length; i++) {
            TokenStakeInfo memory info = _unpackedTokenStake(userStake[msg.sender].at(indexs[i]));
            require(info.startTimestamp + (info.stakeDays * 1 days) < block.timestamp, "lock time");
            NFT.transferFrom(address(this), msg.sender, info.tokenId);
        }
        userStakeScore[msg.sender] += 10 * indexs.length;
        for (uint i = 0; i < indexs.length; i++) {
            userStake[msg.sender].remove(indexs[i]);
        }
    }

    function unStakeNFT(uint256 index) external {
        TokenStakeInfo memory info = _unpackedTokenStake(userStake[msg.sender].at(index));
        require(info.startTimestamp + (info.stakeDays * 1 days) < block.timestamp, "lock time");
        NFT.transferFrom(address(this), msg.sender, info.tokenId);
        userStakeScore[msg.sender] += 10;
    }

    function subScore(address owner, uint256 score) external onlyOwner {
        require(userStakeScore[owner] >= score);
        userStakeScore[owner] -= score;
    }

    function _unpackedTokenStake(uint256 packed) private pure returns (TokenStakeInfo memory stake) {
        stake.tokenId = uint64(packed >> 192);
        stake.startTimestamp = uint64(packed >> 128);
        stake.stakeDays = uint64(packed >> 64);
        stake.extrData = uint64(packed);
    }

    function _packTokenStake(
        uint64 tokenId,
        uint64 startTimestamp,
        uint64 stakeDays,
        uint64 extrData
    ) private pure returns (uint256 result) {
        assembly {
            mstore(0x20, extrData)
            mstore(0x18, stakeDays)
            mstore(0x10, startTimestamp)
            mstore(0x8, tokenId)
            result := mload(0x20)
        }
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external onlyOwner returns (bytes4) {
        require(_operator == _from, "only TokenId Owner");
        require(NFT.ownerOf(_tokenId) == address(this), "not transfer");

        _stakeNFT(_from, _tokenId);

        emit TransferStake(_from, _tokenId, _data);
        return this.onERC721Received.selector;
    }
}