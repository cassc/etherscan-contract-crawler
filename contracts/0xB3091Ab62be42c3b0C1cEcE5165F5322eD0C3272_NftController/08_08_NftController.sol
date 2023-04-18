// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./INftController.sol";
import "contracts/lib/Ownable.sol";
import "contracts/lib/HasFactories.sol";
import "contracts/nft/IMintableNft.sol";

contract NftController is INftController, HasFactories, Ownable {
    uint256 immutable _maxMintCount;
    uint256 _mintedCount;
    bool _isGameOver;
    WinData _winData;
    bool _gameStarted;
    uint256 _startGameTime;

    constructor(uint256 maxCount_) {
        _maxMintCount = maxCount_;
    }

    function maxMintCount() external view returns (uint256) {
        return _maxMintCount;
    }

    function mintedCount() external view returns (uint256) {
        return _mintedCount;
    }

    function lappsedMintCount() external view returns (uint256) {
        return _maxMintCount - _mintedCount;
    }

    function addMintedCount(uint256 mintedCount_) external onlyFactory {
        _mintedCount += mintedCount_;
        require(_mintedCount <= _maxMintCount, "max mint count limit");
    }

    function canFactoriesChange(
        address account
    ) internal view virtual override returns (bool) {
        return account == _owner;
    }

    function isGameOver() external view returns (bool) {
        return _isGameOver;
    }

    function checkCanMint() external view {
        require(!this.isGameOver(), "The game is over. Minting is closed");
        require(_mintedCount < _maxMintCount, "No tokens left to mint");
    }

    function setGameOver(WinData calldata data) external {
        _winData = data;
        _isGameOver = true;
        emit OnGameOver(data.winnerAddress, data.nftAddress, data.tokenId);
    }

    function winData() external view returns (WinData memory) {
        return _winData;
    }

    function startGame() external onlyOwner {
        _gameStarted = true;
        _startGameTime = block.timestamp;
    }

    function gameStarted() external view returns (bool) {
        return _gameStarted;
    }

    function startGameTime() external view returns (uint256) {
        return _startGameTime;
    }
}