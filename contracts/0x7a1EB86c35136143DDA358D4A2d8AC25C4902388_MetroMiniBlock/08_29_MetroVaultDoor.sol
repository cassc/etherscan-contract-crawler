// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IMetroVaultStorage.sol";
import "../../nfts/interfaces/IMetroBlockInfo.sol";
import "../../MetToken.sol";

struct EarningInfo {
    uint256 earned;
    uint256 earnRatePerSecond;
}

contract MetroVaultDoor is Ownable {

    uint256 public maxTokenCount = 20_000;

    address public tokenAddress;
    address public vaultAddress;
    address public blockInfoAddress;

    // To be used to migrate to another Vault
    bool claimDisabled;
    bool stakeDisabled;

    event Claimed(address indexed owner, uint256 amount);

    constructor(address _tokenAddress, address _vaultAddress) {
        tokenAddress = _tokenAddress;
        vaultAddress = _vaultAddress;
    }

    function setMaxTokenCount(uint256 _maxTokenCount) external onlyOwner {
        maxTokenCount = _maxTokenCount;
    }

    function setBlockInfoAddress(address _blockInfoAddress) public onlyOwner {
        blockInfoAddress = _blockInfoAddress; 
    }

    function enableClaim() external onlyOwner {
        claimDisabled = false;
    }

    function disableClaim() external onlyOwner {
      claimDisabled = true;
    }
    
    function enableStake() external onlyOwner {
      stakeDisabled = false;
    }

    function disableStake() external onlyOwner {
      stakeDisabled = true;
    }

    function stake(uint256[] calldata tokenIds) external {
        require(!stakeDisabled, 'Staking is disabled');
        IMetroVaultStorage vault = IMetroVaultStorage(vaultAddress);
        vault.stakeBlocks(_msgSender(), tokenIds, 0, 0);
    }

    function unstake(uint256[] calldata tokenIds, uint256[] calldata claimTokenIds) external {
        if (!claimDisabled && claimTokenIds.length > 0) {
          _claim(_msgSender(), claimTokenIds);
        }
        IMetroVaultStorage vault = IMetroVaultStorage(vaultAddress);
        vault.unstakeBlocks(_msgSender(), tokenIds);
    }

    function claim(uint256[] calldata tokenIds) external {
        require(!claimDisabled, 'Claim is disabled');
        _claim(_msgSender(), tokenIds);
    }
    
    function claimForAddress(address account, uint256[] calldata tokenIds) external {
        require(!claimDisabled, 'Claim is disabled');
        _claim(account, tokenIds);
    }

    function _claim(address account, uint256[] calldata tokenIds) internal {
        uint256 earned = 0;

        if (blockInfoAddress == address(0x0)) {
            return;
        }

        uint256 prevTokenId;
        IMetroVaultStorage vault = IMetroVaultStorage(vaultAddress);
        IMetroBlockInfo blockInfoContract = IMetroBlockInfo(blockInfoAddress);

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(prevTokenId < tokenId, 'no duplicates allowed');
            prevTokenId = tokenId;

            uint256 score = blockInfoContract.getBlockScore(tokenId);

            Stake memory staked = vault.getStake(tokenId);
            require(staked.owner == account, "not an owner");

            earned += 1 ether * score * (block.timestamp - staked.timestamp) / 1 days;
        }

        vault.setStakeTimestamp(tokenIds, uint40(block.timestamp));

        if (earned > 0) {
            uint256 boost = blockInfoContract.getHoodBoost(tokenIds);
            earned = boost * earned / 10000;
            MetToken(tokenAddress).mint(account, earned);
        }

        emit Claimed(account, earned);
    }

    function earningInfo(uint256[] calldata tokenIds) external view returns (EarningInfo memory) {
        uint256 totalScore = 0;
        uint256 earned = 0;
        IMetroVaultStorage vault = IMetroVaultStorage(vaultAddress);
        IMetroBlockInfo blockInfoContract = IMetroBlockInfo(blockInfoAddress);

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 score = blockInfoContract.getBlockScore(tokenId);
            totalScore += score;

            Stake memory staked = vault.getStake(tokenId);
            earned += 1 ether * score * (block.timestamp - staked.timestamp) / 1 days;
        }

        uint256 boost = blockInfoContract.getHoodBoost(tokenIds);
        earned = boost * earned / 10000;

        uint256 earnRatePerSecond = totalScore * 1 ether / 1 days;
        earnRatePerSecond = boost * earnRatePerSecond / 10000;

        return EarningInfo(earned, earnRatePerSecond);
    }

    function tokensOfOwner(address account) public view returns (uint256[] memory) {
      return IMetroVaultStorage(vaultAddress).tokensOfOwner(account, 0, maxTokenCount);
    }

    function tokensOfOwnerCustom(address account, uint256 start, uint256 stop) public view returns (uint256[] memory) {
      return IMetroVaultStorage(vaultAddress).tokensOfOwner(account, start, stop);
    }
}