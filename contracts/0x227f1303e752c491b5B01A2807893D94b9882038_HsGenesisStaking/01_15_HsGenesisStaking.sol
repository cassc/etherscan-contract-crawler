// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HsGenesisStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    bool public paused = true;

    // Stake struct
    struct Stake {
        uint256 tokenId;
        uint256 lockPeriod;
        uint256 lockedUntil;
        uint256 startDate;
        address owner;
    }

    mapping(uint256 => Stake) public vault;

    event NFTStaked(
        address owner,
        uint256 tokenId,
        uint256 lockPeriod,
        uint256 lockedUntil,
        uint256 startDate
    );
    event NFTUnstaked(address owner, uint256 tokenId, uint256 startDate);

    ERC721Enumerable nft;

    constructor(ERC721Enumerable _nft) {
        nft = _nft;
    }

    uint256 public totalStaked;

    uint256 private constant lockTime1 = 90 days;
    uint256 private constant lockTime2 = 180 days;
    uint256 private constant lockTime3 = 365 days;

    uint256 public MaxNftTime1 = 2500;
    uint256 public MaxNftTime2 = 1750;
    uint256 public MaxNftTime3 = 1250;

    uint256 public NftStakedForTime1 = 0;
    uint256 public NftStakedForTime2 = 0;
    uint256 public NftStakedForTime3 = 0;

    function stake(uint256[] calldata tokenIds, uint256[] calldata _lockPeriod)
        external
        nonReentrant
    {
        require(!paused, "Staking is paused");
        uint256 tokenId;
        totalStaked += tokenIds.length;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            uint256 _lockPeriodUINT = _lockPeriod[i] * 1 days;
            require(
                nft.isApprovedForAll(msg.sender, address(this)) == true,
                "NFT: PLEASE APPROVE THIS CONTRACT"
            );
            require(
                _lockPeriodUINT == lockTime1 ||
                    _lockPeriodUINT == lockTime2 ||
                    _lockPeriodUINT == lockTime3,
                "NFT: LOCK PERIOD MUST BE 3,6 OR 12 MONTHS"
            );
            require(
                nft.ownerOf(tokenId) == msg.sender,
                "YOU ARE NOT THE NFT OWNER"
            );

            uint256 lockPeriodTime = _lockPeriod[i];
            uint256 lockedUntil = block.timestamp + _lockPeriodUINT;

            if (lockPeriodTime == 1 && NftStakedForTime1 < MaxNftTime1) {
                NftStakedForTime1 += 1;
                emit NFTStaked(
                    msg.sender,
                    tokenId,
                    lockPeriodTime,
                    lockedUntil,
                    block.timestamp
                );
                nft.transferFrom(msg.sender, address(this), tokenId);
            } else if (lockPeriodTime == 2 && NftStakedForTime2 < MaxNftTime2) {
                NftStakedForTime2 += 1;
                emit NFTStaked(
                    msg.sender,
                    tokenId,
                    lockPeriodTime,
                    lockedUntil,
                    block.timestamp
                );
                nft.transferFrom(msg.sender, address(this), tokenId);
            } else if (lockPeriodTime == 3 && NftStakedForTime3 < MaxNftTime3) {
                NftStakedForTime3 += 1;
                emit NFTStaked(
                    msg.sender,
                    tokenId,
                    lockPeriodTime,
                    lockedUntil,
                    block.timestamp
                );
                nft.transferFrom(msg.sender, address(this), tokenId);
            } else revert("Reached maximum nfts staked.");

            vault[tokenId] = Stake({
                owner: msg.sender,
                tokenId: uint256(tokenId),
                lockPeriod: lockPeriodTime,
                lockedUntil: lockedUntil,
                startDate: block.timestamp
            });
        }
    }

    function _unstake(uint256[] calldata tokenIds) external nonReentrant {
        uint256 tokenId;
        totalStaked -= tokenIds.length;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake storage staked = vault[tokenId];
            require(
                staked.owner == msg.sender,
                "YOU ARE NOT THE OWNER OF THIS NFT"
            );
            require(
                block.timestamp > staked.lockedUntil,
                "NFT: YOUR NFT IS STILL LOCKED"
            );

            if (staked.lockPeriod == 1) {
                NftStakedForTime1 -= 1;
            } else if (staked.lockPeriod == 2) {
                NftStakedForTime2 -= 1;
            } else NftStakedForTime3 -= 1;

            delete vault[tokenId];
            emit NFTUnstaked(msg.sender, tokenId, block.timestamp);
            nft.transferFrom(address(this), msg.sender, tokenId);
        }
    }

    function getNftInfo(uint256[] calldata tokenIds)
        public
        view
        returns (
            uint256[] memory tokenIdsReturn,
            uint256[] memory lockedUPeriodsReturn,
            uint256[] memory lockedUntilReturn,
            uint256[] memory startDateReturn,
            address[] memory ownerReturn
        )
    {
        uint256 tokenId;
        uint256[] memory tokensIds = new uint256[](tokenIds.length);
        uint256[] memory lockPeriods = new uint256[](tokenIds.length);
        uint256[] memory startDates = new uint256[](tokenIds.length);
        address[] memory owners = new address[](tokenIds.length);
        uint256[] memory lockPeriodsTime = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake storage staked = vault[tokenId];
            tokensIds[i] = staked.tokenId;
            lockPeriods[i] = staked.lockedUntil;
            startDates[i] = staked.startDate;
            owners[i] = staked.owner;
            lockPeriodsTime[i] = staked.lockPeriod;
        }

        return (tokenIds, lockPeriodsTime, lockPeriods, startDates, owners);
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 balance = 0;
        uint256 supply = nft.totalSupply();
        for (uint256 i = 1; i <= supply; i++) {
            if (vault[i].owner == account) {
                balance += 1;
            }
        }
        return balance;
    }

    function tokensOfOwner(address account)
        public
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 supply = nft.totalSupply();
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (vault[tokenId].owner == account) {
                tmp[index] = vault[tokenId].tokenId;
                index += 1;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
}