// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/StakingNFT/StakingNFT.sol";
import "contracts/libraries/StakingNFT/StakingNFTStorage.sol";
import "contracts/libraries/governance/GovernanceMaxLock.sol";

contract MockStakingNFT is StakingNFT {
    uint256 internal _dummy = 0;

    function mintMock(uint256 amount_) public returns (uint256) {
        return StakingNFT.mint(amount_);
    }

    function mintToMock(address to_, uint256 amount_, uint256 duration_) public returns (uint256) {
        return StakingNFT.mintTo(to_, amount_, duration_);
    }

    function mintNFTMock(address to_, uint256 amount_) public returns (uint256) {
        return StakingNFT._mintNFT(to_, amount_);
    }

    function burnMock(uint256 tokenID_) public returns (uint256, uint256) {
        return StakingNFT.burn(tokenID_);
    }

    function burnToMock(address to_, uint256 tokenID_) public returns (uint256, uint256) {
        return StakingNFT.burnTo(to_, tokenID_);
    }

    function burnNFTMock(
        address from_,
        address to_,
        uint256 tokenID_
    ) public returns (uint256, uint256) {
        return StakingNFT._burn(from_, to_, tokenID_);
    }

    function collectEthMock(uint256 tokenID_) public returns (uint256) {
        return StakingNFT.collectEth(tokenID_);
    }

    function collectEthToMock(address to_, uint256 tokenID_) public returns (uint256) {
        return StakingNFT.collectEthTo(to_, tokenID_);
    }

    function collectTokenMock(uint256 tokenID_) public returns (uint256) {
        return StakingNFT.collectToken(tokenID_);
    }

    function collectTokenToMock(address to_, uint256 tokenID_) public returns (uint256) {
        return StakingNFT.collectTokenTo(to_, tokenID_);
    }

    function depositEthMock(uint8 magic) public payable {
        StakingNFT.depositEth(magic);
    }

    function lockPositionMock(
        address caller_,
        uint256 tokenID_,
        uint256 duration_
    ) public returns (uint256) {
        return StakingNFT.lockPosition(caller_, tokenID_, duration_);
    }

    function lockOwnPositionMock(uint256 tokenID_, uint256 duration_) public returns (uint256) {
        return StakingNFT.lockOwnPosition(tokenID_, duration_);
    }

    function lockPositionLowMock(uint256 tokenID_, uint256 duration_) public returns (uint256) {
        return StakingNFT._lockPosition(tokenID_, duration_);
    }

    function lockWithdrawMock(uint256 tokenID_, uint256 duration_) public returns (uint256) {
        return StakingNFT.lockWithdraw(tokenID_, duration_);
    }

    function lockWithdrawLowMock(uint256 tokenID_, uint256 duration_) public returns (uint256) {
        return StakingNFT._lockWithdraw(tokenID_, duration_);
    }

    function depositTokenMock(uint8 magic, uint256 amount) public {
        StakingNFT.depositToken(magic, amount);
    }

    function tripCBMock() public {
        StakingNFT.tripCB();
    }

    function tripCBLowMock() public {
        _tripCB();
    }

    function resetCBLowMock() public {
        _resetCB();
    }

    function skimExcessEthMock(address to_) public returns (uint256) {
        return StakingNFT.skimExcessEth(to_);
    }

    function skimExcessTokenMock(address to_) public returns (uint256) {
        return StakingNFT.skimExcessToken(to_);
    }

    function incrementMock() public returns (uint256) {
        _dummy = 0;
        return _increment();
    }

    function collectMock(
        uint256 shares_,
        Accumulator memory state_,
        Position memory p_,
        uint256 positionAccumulatorValue_
    ) public returns (Accumulator memory, Position memory, uint256, uint256) {
        _dummy = 0;
        return StakingNFT._calculateCollection(shares_, state_, p_, positionAccumulatorValue_);
    }

    function depositMock(
        uint256 delta_,
        Accumulator memory state_
    ) public returns (Accumulator memory) {
        _dummy = 0;
        return StakingNFT._deposit(delta_, state_);
    }

    function slushSkimMock(
        uint256 shares_,
        uint256 accumulator_,
        uint256 slush_
    ) public returns (uint256, uint256) {
        _dummy = 0;
        return StakingNFT._slushSkim(shares_, accumulator_, slush_);
    }

    function getTotalSharesMock() public view returns (uint256) {
        return StakingNFT.getTotalShares();
    }

    function getTotalReserveEthMock() public view returns (uint256) {
        return StakingNFT.getTotalReserveEth();
    }

    function getTotalReserveALCAMock() public view returns (uint256) {
        return StakingNFT.getTotalReserveALCA();
    }

    function estimateEthCollectionMock(uint256 tokenID_) public view returns (uint256) {
        return StakingNFT.estimateEthCollection(tokenID_);
    }

    function estimateTokenCollectionMock(uint256 tokenID_) public view returns (uint256) {
        return StakingNFT.estimateTokenCollection(tokenID_);
    }

    function estimateExcessEthMock() public view returns (uint256) {
        return StakingNFT.estimateExcessEth();
    }

    function estimateExcessTokenMock() public view returns (uint256) {
        return StakingNFT.estimateExcessToken();
    }

    function getPositionMock(
        uint256 tokenID_
    ) public view returns (uint256, uint256, uint256, uint256, uint256) {
        return StakingNFT.getPosition(tokenID_);
    }

    function tokenURIMock(uint256 tokenID_) public view returns (string memory) {
        return StakingNFT.tokenURI(tokenID_);
    }

    function circuitBreakerStateMock() public view returns (bool) {
        return circuitBreakerState();
    }

    function getCountMock() public view returns (uint256) {
        return _getCount();
    }

    function getAccumulatorScaleFactorMock() public pure returns (uint256) {
        return StakingNFT.getAccumulatorScaleFactor();
    }

    function getMaxMintLockMock() public pure returns (uint256) {
        return StakingNFT.getMaxMintLock();
    }

    function collectPure(
        uint256 shares_,
        Accumulator memory state_,
        Position memory p_,
        uint256 positionAccumulatorValue_
    ) public pure returns (Accumulator memory, Position memory, uint256, uint256) {
        return StakingNFT._calculateCollection(shares_, state_, p_, positionAccumulatorValue_);
    }

    function depositPure(
        uint256 delta_,
        Accumulator memory state_
    ) public pure returns (Accumulator memory) {
        return StakingNFT._deposit(delta_, state_);
    }

    function slushSkimPure(
        uint256 shares_,
        uint256 accumulator_,
        uint256 slush_
    ) public pure returns (uint256, uint256) {
        return StakingNFT._slushSkim(shares_, accumulator_, slush_);
    }
}