// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import './IRandMath.sol';
import '../airdrop/SwordOfBravery.sol';
import '../staking/Faith.sol';

contract TheForge is Ownable, ReentrancyGuard, Pausable {
    event MintStarOfBravery(address to, uint256 mintQty, uint256 balanceAfterMint);
    event SwordEnhanceSuccess(address owner, uint32 starsUsed, uint8 originalSwordId, uint8 enhancedSwordId);
    event SwordEnhanceFail(address owner, uint32 starsUsed, uint8 originalSwordId);

    IRandMath private __randContract;
    SwordOfBravery private __swordContract;
    Faith private __faithContract;

    // 10% White, 60% Green, 25% Blue, 4.5% Purple, 0.5% Legendary
    uint32[] __breakPoints = [0, 100, 700, 950, 995, 1000]; // left: inclusive, right: exclusive

    uint8 private __legendaryCountLimit = 10;
    uint8 private __legendaryCount = 0;

    mapping(address => uint256) private __starBalances;
    uint256 private __priceInFaith = 2000 * (1e18);

    bool private __enablePurchaseStar = false;
    uint256 private __priceInEther = 0.002 ether;

    constructor(
        address swordAddress,
        address faithAddress,
        address randMathAddress
    ) {
        _pause();
        __swordContract = SwordOfBravery(swordAddress);
        __faithContract = Faith(faithAddress);
        __randContract = IRandMath(randMathAddress);
    }

    function getStarBalance(address account) public view virtual returns (uint256) {
        return __starBalances[account];
    }

    function updateSeed() internal {
        __randContract.seed(_msgSender().balance);
    }

    function faithToStar(uint256 starQty) external nonReentrant nonContractCalls whenNotPaused {
        require(
            __faithContract.balanceOf(_msgSender()) >= starQty * __priceInFaith,
            'Not enough Faith to purchase StarOfBravery'
        );
        __faithContract.transferFrom(_msgSender(), address(this), starQty * __priceInFaith);

        __starBalances[_msgSender()] += starQty;
        emit MintStarOfBravery(_msgSender(), starQty, __starBalances[_msgSender()]);

        updateSeed();
    }

    function purchaseStar(uint256 starQty) external payable nonReentrant nonContractCalls whenNotPaused {
        require(__enablePurchaseStar, 'Sale not start');
        require(msg.value >= starQty * __priceInEther, 'Not enough eth to purchase StarOfBravery');

        if (starQty == 5) {
            __starBalances[_msgSender()] += 6;
            emit MintStarOfBravery(_msgSender(), 6, __starBalances[_msgSender()]);
        } else if (starQty == 10) {
            __starBalances[_msgSender()] += 13;
            emit MintStarOfBravery(_msgSender(), 13, __starBalances[_msgSender()]);
        } else {
            __starBalances[_msgSender()] += starQty;
            emit MintStarOfBravery(_msgSender(), starQty, __starBalances[_msgSender()]);
        }

        updateSeed();
    }

    function enhanceSword(uint8 swordId, uint32 starsApplied) external nonReentrant nonContractCalls whenNotPaused {
        require(getStarBalance(_msgSender()) >= starsApplied, 'Insufficient Star Balance');
        require(__swordContract.balanceOf(_msgSender(), swordId) > 0, 'No Sword Found');
        require(__legendaryCount < __legendaryCountLimit ? swordId < 4 : swordId < 3, 'Maximum Sword Level Reached');

        (uint32 maxRandNum, uint32 starsUsed) = __randContract.getMaxRandNumInRange(
            starsApplied, // max lopps
            __breakPoints[5], // MaxLimit == Range
            __legendaryCount < __legendaryCountLimit ? __breakPoints[4] : __breakPoints[3] // stop loop if larger than peak, inclusive
        );

        uint8 newSwordId;
        unchecked {
            if (maxRandNum < __breakPoints[1]) {
                newSwordId = 0;
            } else if (maxRandNum < __breakPoints[2]) {
                newSwordId = 1;
            } else if (maxRandNum < __breakPoints[3]) {
                newSwordId = 2;
            } else if (maxRandNum < __breakPoints[4] || __legendaryCount >= __legendaryCountLimit) {
                newSwordId = 3;
            } else {
                __legendaryCount++;
                newSwordId = 4;
            }
        }

        // update star balance
        __starBalances[_msgSender()] -= starsUsed;

        // updateSeed();

        if (newSwordId <= swordId) {
            emit SwordEnhanceFail(_msgSender(), starsUsed, swordId);
            return;
        }

        emit SwordEnhanceSuccess(_msgSender(), starsUsed, swordId, newSwordId);

        __swordContract.burn(_msgSender(), swordId, 1);
        __swordContract.mint(_msgSender(), newSwordId, 1, '0x0');
    }

    function setBreakPoints(uint32[] calldata breakPoints) external onlyOwner {
        __breakPoints = breakPoints;
    }

    function getRates() public view returns (uint32, uint32[5] memory) {
        return (
            __breakPoints[5], // total
            [
                __breakPoints[1] - __breakPoints[0],
                __breakPoints[2] - __breakPoints[1],
                __breakPoints[3] - __breakPoints[2],
                __breakPoints[4] - __breakPoints[3],
                __breakPoints[5] - __breakPoints[4]
            ]
        );
    }

    function setMaxLegendaries(uint8 newCount, uint8 newMax) external onlyOwner {
        __legendaryCount = newCount;
        __legendaryCountLimit = newMax;
    }

    function getLegendaryCount() public view returns (uint8) {
        return __legendaryCount;
    }

    function getLegendaryCountLimit() public view returns (uint8) {
        return __legendaryCountLimit;
    }

    function setPriceInFaith(uint256 newPrice) external onlyOwner {
        __priceInFaith = newPrice;
    }

    function getPriceInFaith() public view returns (uint256) {
        return __priceInFaith;
    }

    function setPriceInEther(uint256 newPrice) external onlyOwner {
        __priceInEther = newPrice;
    }

    function getPriceInEther() public view returns (uint256) {
        return __priceInEther;
    }

    function setRandMath(address randMathAddr) external onlyOwner {
        __randContract = IRandMath(randMathAddr);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function startPurchaseStar() public onlyOwner {
        __enablePurchaseStar = true;
    }

    function stopPurchaseStar() public onlyOwner {
        __enablePurchaseStar = false;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function refund(address to, uint256 faithAmount) public onlyOwner {
        __faithContract.transferFrom(address(this), to, faithAmount);
    }

    modifier nonContractCalls() {
        require(msg.sender == tx.origin, 'Call from Smart Contract Not Allowed');
        _;
    }
}