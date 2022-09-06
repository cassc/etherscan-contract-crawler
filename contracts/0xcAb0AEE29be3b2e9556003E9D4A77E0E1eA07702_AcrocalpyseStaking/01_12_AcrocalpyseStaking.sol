// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IAcrocalpyse is IERC721 {
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

contract AcrocalpyseStaking is Ownable, Pausable, IERC721Receiver {
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 10420;

    // allow rewards
    uint256 public allowRewardsEarningsUntil;

    // signer address for verification
    address public signerAddress;

    // paper token address
    IERC20 public paperTokenAddress;

    // Acrocalypse (ACROC) address
    IAcrocalpyse public nftTokenAddress;

    // Token Staking
    struct StakedToken {
        address owner;
        uint256 tokenId;
        uint256 stakePool;
        uint256 rewardsPerDay;
        uint256 pool1RewardsPerDay;
        uint256 creationTime;
        uint256 lockedUntilTime;
        uint256 lastClaimTime;
    }

    // Mapping to store all the tokens staked
    mapping(uint256 => StakedToken) public stakedTokens;

    uint256 public totalStaked;
    uint256 public totalPool1Staked;
    uint256 public totalPool2Staked;
    uint256 public totalPool3Staked;

    constructor(IERC20 _paperTokenAddress, IAcrocalpyse _nftTokenAddress) {
        signerAddress = _msgSender();
        allowRewardsEarningsUntil = block.timestamp + 731 * 86400; // solhint-disable-line not-rely-on-time

        if (address(_paperTokenAddress) != address(0)) {
            paperTokenAddress = IERC20(_paperTokenAddress);
        }

        if (address(_nftTokenAddress) != address(0)) {
            nftTokenAddress = IAcrocalpyse(_nftTokenAddress);
        }
    }

    //external
    fallback() external payable {}

    receive() external payable {} // solhint-disable-line no-empty-blocks

    modifier callerIsUser() {
        // solhint-disable-next-line avoid-tx-origin
        require(tx.origin == _msgSender(), "Cannot be called by a contract");
        _;
    }

    function stake(
        bytes memory signature,
        uint256 stakePool,
        uint256[] memory tokenIds,
        uint256[] memory rewardsPerDay,
        uint256[] memory pool1RewardsPerDay
    ) external payable whenNotPaused callerIsUser {
        require(block.timestamp < allowRewardsEarningsUntil, "Staking period expired"); // solhint-disable-line not-rely-on-time
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(_msgSender(), stakePool, tokenIds, rewardsPerDay, pool1RewardsPerDay))
        );

        // verifying the signature
        require(ECDSA.recover(hash, signature) == signerAddress, "Invalid Access");

        // token validation
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // validating the token ids if already staked or not
            require(stakedTokens[tokenIds[i]].owner == address(0), "Token ID already staked");

            // validating the token ownership
            require(nftTokenAddress.ownerOf(tokenIds[i]) == _msgSender(), "Token owner mismatch");

            uint256 lockedDays = 7; // pool 1
            uint256 lockedDaysTimePeriod = 604800;

            if (stakePool == 1) {
                totalPool1Staked++;
            } else if (stakePool == 2) {
                // pool 2
                lockedDays = 45;
                lockedDaysTimePeriod = 3888000;
                totalPool2Staked++;
            } else if (stakePool == 3) {
                // pool 3
                lockedDays = 90;
                lockedDaysTimePeriod = 7776000;
                totalPool3Staked++;
            }

            uint256 lockedUntil = block.timestamp + lockedDaysTimePeriod; // solhint-disable-line not-rely-on-time
            if (lockedUntil > allowRewardsEarningsUntil) {
                lockedUntil = allowRewardsEarningsUntil;
            }

            stakedTokens[tokenIds[i]] = StakedToken({
                owner: _msgSender(),
                tokenId: tokenIds[i],
                stakePool: stakePool,
                rewardsPerDay: rewardsPerDay[i],
                pool1RewardsPerDay: pool1RewardsPerDay[i],
                creationTime: block.timestamp, // solhint-disable-line not-rely-on-time
                lastClaimTime: 0,
                lockedUntilTime: lockedUntil
            });
        }

        totalStaked += tokenIds.length;

        // Transfer the tokens to the contract
        for (uint256 i = 0; i < tokenIds.length; i++) {
            nftTokenAddress.safeTransferFrom(_msgSender(), address(this), tokenIds[i]);
        }
    }

    function claim(uint256[] memory tokenIds) external payable whenNotPaused callerIsUser {
        require(_claim(tokenIds, _msgSender(), false), "Error Claiming");
    }

    function claimAndUnstake(uint256[] memory tokenIds) external payable whenNotPaused callerIsUser {
        bool claimStatus = _claim(tokenIds, _msgSender(), true);
        require(claimStatus, "Error Claiming");

        bool unstakeStatus = _unstake(tokenIds, _msgSender(), false);
        require(unstakeStatus, "Error Unstaking");
    }

    function _claim(
        uint256[] memory tokenIds,
        address senderAddress,
        bool isUnstaking
    ) internal returns (bool) {
        require(tokenIds.length > 0, "Token Ids not set");

        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            StakedToken memory sToken = stakedTokens[tokenIds[i]];

            // slither-disable-next-line incorrect-equality
            require(sToken.owner == senderAddress, "Invalid Token Access");

            totalRewards += calculateTokenUnclaimedRewards(tokenIds[i]);

            if (!isUnstaking) {
                // slither-disable-next-line incorrect-equality
                if (sToken.stakePool == 1) {
                    // extending the lock time by 7 days
                    uint256 lockedUntil = block.timestamp + 604800; // solhint-disable-line not-rely-on-time
                    if (lockedUntil > allowRewardsEarningsUntil) {
                        lockedUntil = allowRewardsEarningsUntil;
                    }
                    sToken.lockedUntilTime = lockedUntil;
                }

                sToken.lastClaimTime = block.timestamp; // solhint-disable-line not-rely-on-time
                stakedTokens[tokenIds[i]] = sToken;
            }
        }

        // Transfer the $PAPER Tokens
        bool success = paperTokenAddress.transfer(senderAddress, totalRewards.div(86400));
        require(success, "Unable to transfer tokens");

        return true;
    }

    function _unstake(
        uint256[] memory tokenIds,
        address senderAddress,
        bool isAdmin
    ) internal returns (bool) {
        require(tokenIds.length > 0, "Token Ids not set");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            StakedToken memory sToken = stakedTokens[tokenIds[i]];
            require(sToken.owner != address(0), "Token not staked");

            // only the Owner of the token or Admin can do unstaking
            if (!isAdmin) {
                // slither-disable-next-line incorrect-equality
                require(sToken.owner == senderAddress, "Invalid Token Access");
                require(sToken.lockedUntilTime <= block.timestamp, "Unable to unstake a locked token"); // solhint-disable-line not-rely-on-time
            }

            if (sToken.stakePool == 1) {
                totalPool1Staked--;
            } else if (sToken.stakePool == 2) {
                totalPool2Staked--;
            } else if (sToken.stakePool == 3) {
                totalPool3Staked--;
            }

            totalStaked--;
            delete stakedTokens[tokenIds[i]];

            nftTokenAddress.safeTransferFrom(address(this), sToken.owner, tokenIds[i]);
        }

        return true;
    }

    function calculateTokenUnclaimedRewards(uint256 tokenId) public view returns (uint256) {
        StakedToken memory sToken = stakedTokens[tokenId];
        require(sToken.owner != address(0), "Unstaked Token");

        // solhint-disable-next-line not-rely-on-time
        uint256 currentTimestamp = block.timestamp;
        uint256 rewardsUntilTimestamp = currentTimestamp > allowRewardsEarningsUntil
            ? allowRewardsEarningsUntil
            : currentTimestamp;

        uint256 claimStartTimestamp = sToken.lastClaimTime > 0 ? sToken.lastClaimTime : sToken.creationTime;
        // lastClaimTime is always updated with block.timestamp after claim
        if (claimStartTimestamp > rewardsUntilTimestamp) {
            claimStartTimestamp = rewardsUntilTimestamp;
        }

        uint256 timeDifference = 0;
        uint256 totalRewards = 0;

        if (sToken.stakePool == 2 || sToken.stakePool == 3) {
            if (rewardsUntilTimestamp <= sToken.lockedUntilTime) {
                timeDifference = rewardsUntilTimestamp - claimStartTimestamp;
                totalRewards = timeDifference.mul(sToken.rewardsPerDay);
            } else {
                if (claimStartTimestamp <= sToken.lockedUntilTime) {
                    timeDifference = sToken.lockedUntilTime - claimStartTimestamp;
                    totalRewards = timeDifference.mul(sToken.rewardsPerDay);

                    timeDifference = rewardsUntilTimestamp - sToken.lockedUntilTime;
                    totalRewards += timeDifference.mul(sToken.pool1RewardsPerDay);
                } else {
                    timeDifference = rewardsUntilTimestamp - claimStartTimestamp;
                    totalRewards = timeDifference.mul(sToken.pool1RewardsPerDay);
                }
            }
        } else if (sToken.stakePool == 1) {
            timeDifference = rewardsUntilTimestamp - claimStartTimestamp;
            totalRewards = timeDifference.mul(sToken.rewardsPerDay);
        }

        return totalRewards;
    }

    function stakedOwnerTokens(address owner) external view returns (StakedToken[] memory _ownerStakedTokens) {
        require(owner != address(0), "zero address");

        uint256 ownerStakedCount = 0;
        uint256[] memory stakedTokenIds = nftTokenAddress.walletOfOwner(address(this));
        for (uint256 i = 0; i < stakedTokenIds.length; ++i) {
            if (owner == stakedTokens[stakedTokenIds[i]].owner) {
                ++ownerStakedCount;
            }
        }

        StakedToken[] memory ownerStakedTokens = new StakedToken[](ownerStakedCount);
        uint256 ownedTokenIndex = 0;

        if (ownerStakedCount > 0) {
            for (uint256 i = 0; i < stakedTokenIds.length; ++i) {
                if (owner == stakedTokens[stakedTokenIds[i]].owner) {
                    ownerStakedTokens[ownedTokenIndex] = stakedTokens[stakedTokenIds[i]];
                    ownedTokenIndex++;
                }
            }
        }

        return ownerStakedTokens;
    }

    function checkTokensStakedStatus(uint256[] memory tokenIds) external view returns (bool[] memory stakedStatus) {
        require(tokenIds.length > 0 && tokenIds.length <= MAX_SUPPLY, "Token Ids not set");

        bool[] memory tokenIdsStakedStatus = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (stakedTokens[tokenIds[i]].owner != address(0)) {
                tokenIdsStakedStatus[i] = true;
            }
        }
        return tokenIdsStakedStatus;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setSignerAddress(address newSignerAddress) external onlyOwner {
        if (address(newSignerAddress) != address(0)) {
            signerAddress = newSignerAddress;
        }
    }

    function setNFTAddress(IAcrocalpyse newAddress) external onlyOwner {
        if (address(newAddress) != address(0)) {
            nftTokenAddress = IAcrocalpyse(newAddress);
        }
    }

    function setPaperTokenAddress(IERC20 newAddress) external onlyOwner {
        if (address(newAddress) != address(0)) {
            paperTokenAddress = IERC20(newAddress);
        }
    }

    function getTotalStakedCounters()
        external
        view
        returns (
            uint256 _totalStaked,
            uint256 _totalPool1Staked,
            uint256 _totalPool2Staked,
            uint256 _totalPool3Staked
        )
    {
        return (totalStaked, totalPool1Staked, totalPool2Staked, totalPool3Staked);
    }

    function setTotalStakedCounters(
        uint256 _totalStaked,
        uint256 _totalPool1Staked,
        uint256 _totalPool2Staked,
        uint256 _totalPool3Staked
    ) external onlyOwner {
        totalStaked = _totalStaked;
        totalPool1Staked = _totalPool1Staked;
        totalPool2Staked = _totalPool2Staked;
        totalPool3Staked = _totalPool3Staked;
    }

    function setAllowRewardsEarningUntil(uint256 newAllowRewardsEarningsUntil) external onlyOwner {
        allowRewardsEarningsUntil = newAllowRewardsEarningsUntil;
    }

    function unstakeAdmin(uint256[] memory tokenIds) external onlyOwner {
        require(_unstake(tokenIds, address(0), true), "Error Unstaking");
    }

    function viewContractTokenBalance(IERC20 tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function withdrawTokens(IERC20 tokenAddress, uint256 percentageWithdrawl) external onlyOwner {
        uint256 balance = viewContractTokenBalance(tokenAddress);

        require(balance > 0, "No funds available");
        require(percentageWithdrawl > 0 && percentageWithdrawl <= 100, "Withdrawl percent invalid");

        bool success = IERC20(tokenAddress).transfer(owner(), balance.mul(percentageWithdrawl).div(100));

        require(success, "Withdrawl failed");
    }

    function withdraw(uint256 percentWithdrawl) external onlyOwner {
        require(address(this).balance > 0, "No funds available");
        require(percentWithdrawl > 0 && percentWithdrawl <= 100, "Invalid Withdrawl percent");

        Address.sendValue(payable(owner()), (address(this).balance * percentWithdrawl) / 100);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external view override returns (bytes4) {
        require(operator == address(this), "Invalid operator");
        require(stakedTokens[tokenId].owner == from, "Invalid Token Owner");

        return IERC721Receiver.onERC721Received.selector;
    }
}