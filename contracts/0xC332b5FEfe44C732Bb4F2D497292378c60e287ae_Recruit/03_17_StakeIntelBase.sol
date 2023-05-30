// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IINTEL is IERC20 {
    function mint(address to, uint256 amount) external;
}

abstract contract StakeIntelBase is
    ERC721,
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard
{
    IINTEL public intelContract;

    uint256 public rewardRate = 1;

    mapping(uint256 => uint256) public tokenIdToStakeTime;

    enum StakingStatus {
        CONTINUE,
        PAUSE
    }

    StakingStatus public stakingStatus;

    struct Period {
        uint256 startTime;
        uint256 endTime;
        uint256 rewardRate;
    }

    Period[] internal _periods;

    function continueStaking() public onlyOwner {
        Period memory period = Period(block.timestamp, 0, rewardRate);
        _periods.push(period);
        stakingStatus = StakingStatus.CONTINUE;
    }

    function pauseStaking() public onlyOwner {
        _periods[_periods.length - 1].endTime = block.timestamp;
        stakingStatus = StakingStatus.PAUSE;
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        pauseStaking();
        rewardRate = _rewardRate;
        continueStaking();
    }

    function setIntelContract(address _intelContract) internal {
        intelContract = IINTEL(_intelContract);
    }

    function collectableIntelForOne(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        uint256 stakeTime = tokenIdToStakeTime[_tokenId];
        if (stakeTime == 0) {
            return 0;
        }

        uint256 collectable;
        for (uint256 index = 0; index < _periods.length; index++) {
            Period memory period = _periods[index];

            if (period.endTime != 0 && period.endTime < stakeTime) {
                continue;
            }

            uint256 startTime = stakeTime > period.startTime
                ? stakeTime
                : period.startTime;

            uint256 endTime = period.endTime == 0
                ? block.timestamp
                : period.endTime;

            collectable +=
                (((endTime - startTime) * 10**2) /
                    ((24 * 60 * 60) / period.rewardRate)) *
                (10**16);
        }

        return collectable;
        // return
        //     (((block.timestamp - stakeTime) * 10**2) /
        //         ((24 * 60 * 60) / rewardRate)) * (10**16);
    }

    function collectableIntelForAll(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 total = 0;
        uint256[] memory userWallet = walletOfOwner(_owner);
        for (uint256 index = 0; index < userWallet.length; index++) {
            uint256 tokenId = userWallet[index];
            total += collectableIntelForOne(tokenId);
        }
        return total;
    }

    function _collectIntelForOne(uint256 _tokenId) internal returns (uint256) {
        uint256 claimableToken = collectableIntelForOne(_tokenId);
        tokenIdToStakeTime[_tokenId] = block.timestamp;
        intelContract.mint(ownerOf(_tokenId), claimableToken);
        return claimableToken;
    }

    function collectIntelForOne(uint256 _tokenId)
        public
        nonReentrant
        returns (uint256)
    {
        uint256 claimableToken = collectableIntelForOne(_tokenId);
        require(claimableToken > 0, "claimable token amount is 0");
        return _collectIntelForOne(_tokenId);
    }

    function collectIntelForAll(address _owner)
        public
        nonReentrant
        returns (uint256)
    {
        uint256 total = 0;
        uint256[] memory userWallet = walletOfOwner(_owner);
        uint256 claimableToken = collectableIntelForAll(_owner);
        require(claimableToken > 0, "claimable token amount is 0");
        for (uint256 index = 0; index < userWallet.length; index++) {
            uint256 tokenId = userWallet[index];
            total += _collectIntelForOne(tokenId);
        }
        return total;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        if (_exists(tokenId)) {
            _collectIntelForOne(tokenId);
        } else {
            tokenIdToStakeTime[tokenId] = block.timestamp;
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}