// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFTLabs is Ownable, ERC721, ERC721Enumerable {
    using Strings for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    struct TokenLockInfo {
        uint256 lockedAt;
        uint256 lastPurchaseAt;
        uint256 lockId;
        uint256 cumulatedReward;
        uint256 price;
    }

    struct LockInfo {
        uint256 period;
        uint256 weight;
    }

    struct NFTForSale {
        uint256 tokenId;
        uint256 basePrice;
    }

    uint256 public constant FEE_DECIMALS = 100000;

    Counters.Counter private _tokenIdCounter;
    address public paymentToken;

    mapping(uint256 => TokenLockInfo) public mapTokenLockInfo;
    LockInfo[] public listLockInfo;
    mapping(uint256 => uint256) private localMapTokenIdToReward;

    uint256 public tokenPool;
    uint256 public startDate;
    uint256 public purchasePeriod = 30 * 24 * 60 * 60;
    uint256 public lastPurchaseAt;


    uint256 public NFTPrice;
    uint256 public resaleFee;
    NFTForSale[] public nftsForSale;

    bool public isPaused;
    uint256 private migrateTo;
    constructor(string memory name, string memory symbol, address _paymentToken, uint256 price, uint256 _resalesFee, uint256 _startDate, uint256 lastPurchase, uint256 _migrateTo) ERC721(name, symbol) {
        LockInfo memory tier1Lock = LockInfo(1 * 30 * 24 * 60 * 60, 1000);
        LockInfo memory tier2Lock = LockInfo(6 * 30 * 24 * 60 * 60, 2000);
        LockInfo memory tier3Lock = LockInfo(12 * 30 * 24 * 60 * 6, 3000);
        startDate = _startDate;
        lastPurchaseAt = lastPurchase;

        listLockInfo.push(tier1Lock);
        listLockInfo.push(tier2Lock);
        listLockInfo.push(tier3Lock);
        paymentToken = _paymentToken;
        NFTPrice = price;
        resaleFee = _resalesFee;
        migrateTo = _migrateTo;
    }

    function mint(uint256 lockId) public {
        require(block.timestamp > startDate, "Mint is not started yet");
        require(!isPaused, "paused");
        require(lockId < listLockInfo.length, "Incorrect lockId");
        require(IERC20(paymentToken).balanceOf(_msgSender()) >= NFTPrice, "Insufficient balance");
        IERC20(paymentToken).safeTransferFrom(
            _msgSender(),
            address(this),
            NFTPrice
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
        _lockNft(tokenId, lockId);
    }

    function purchase(uint256 tokenId) external {
        require(!isPaused, "paused");
        require(ownerOf(tokenId) == _msgSender(), "Not owner");
        if (lastPurchaseAt + purchasePeriod <= block.timestamp) {cumulateRewards();}
        TokenLockInfo memory tokenLockInfo = mapTokenLockInfo[tokenId];
        require(tokenLockInfo.cumulatedReward > 0, "No purchase available");
        IERC20(paymentToken).transfer(_msgSender(), tokenLockInfo.cumulatedReward);
        tokenLockInfo.cumulatedReward = 0;
        mapTokenLockInfo[tokenId] = tokenLockInfo;
    }

    function cumulateRewards() public {
        require(!isPaused, "paused");
        require(lastPurchaseAt + purchasePeriod <= block.timestamp, "Cumulate not available");
        uint256 cumulateTime = lastPurchaseAt + ((block.timestamp - lastPurchaseAt) / purchasePeriod) * purchasePeriod;
        _cumulateRewards(cumulateTime);
        lastPurchaseAt = cumulateTime;
    }

    function unlock(uint256 tokenId) public {
        require(!isPaused, "paused");
        require(ownerOf(tokenId) == _msgSender(), "Not owner");
        require(canUnlock(tokenId), "unlock not available");

        uint256 rewardWeight = _rewardWeight(tokenId, block.timestamp);
        uint256 totalRewardWight = _totalRewardWeight(block.timestamp);

        uint256 reward = (tokenPool * rewardWeight) / totalRewardWight;
        tokenPool -= reward;

        TokenLockInfo memory tokenLockInfo = mapTokenLockInfo[tokenId];

        IERC20(paymentToken).transfer(
            _msgSender(),
            tokenLockInfo.cumulatedReward + reward + tokenLockInfo.price
        );

        _burn(tokenId);
        delete mapTokenLockInfo[tokenId];
    }

    function changeLockId(uint256 tokenId, uint256 newLockId) external {
        require(!isPaused, "paused");
        require(ownerOf(tokenId) == _msgSender(), "Not owner");
        require(newLockId < listLockInfo.length, "Lock Id not available");

        TokenLockInfo memory tokenLockInfo = mapTokenLockInfo[tokenId];

        require(tokenLockInfo.lockId < newLockId, "Lock Id not available");
        unlock(tokenId);
        mint(newLockId);
    }


    function _rewardWeight(uint256 tokenId, uint256 at) view private returns (uint256) {
        TokenLockInfo memory tokenLockInfo = mapTokenLockInfo[tokenId];
        LockInfo memory lockInfo = listLockInfo[tokenLockInfo.lockId];
        if (tokenLockInfo.lastPurchaseAt >= at) {
            return 0;
        }
        uint256 timePassed = at - tokenLockInfo.lastPurchaseAt;
        return timePassed * lockInfo.weight;
    }

    function _totalRewardWeight(uint256 at) private returns (uint256) {
        uint256 currentTokenId;
        uint256 currentRewardWeight;
        uint256 totalWeight = 0;
        for (uint256 tokenIndex = 0; tokenIndex < totalSupply(); tokenIndex++) {
            currentTokenId = tokenByIndex(tokenIndex);
            currentRewardWeight = _rewardWeight(currentTokenId, at);
            totalWeight += currentRewardWeight;
            localMapTokenIdToReward[currentTokenId] = currentRewardWeight;
        }
        return totalWeight;
    }

    function _cumulateRewards(uint256 cumulateTime) private {
        uint256 currentTokenId;
        uint256 currentRewardWeight;
        uint256 currentReward;

        uint256 totalWeight = _totalRewardWeight(cumulateTime);

        for (uint256 tokenIndex = 0; tokenIndex < totalSupply(); tokenIndex++) {
            currentTokenId = tokenByIndex(tokenIndex);
            currentRewardWeight = localMapTokenIdToReward[currentTokenId];
            currentReward = (tokenPool * currentRewardWeight) / totalWeight;
            TokenLockInfo memory tokenLockInfo = mapTokenLockInfo[currentTokenId];
            tokenLockInfo.lastPurchaseAt = cumulateTime;
            tokenLockInfo.cumulatedReward += currentReward;
            mapTokenLockInfo[currentTokenId] = tokenLockInfo;
        }
        tokenPool = 0;
    }

    function canUnlock(uint256 tokenId) view public returns (bool){
        TokenLockInfo memory tokenLockInfo = mapTokenLockInfo[tokenId];
        LockInfo memory lockInfo = listLockInfo[tokenLockInfo.lockId];
        return _canUnlock(tokenLockInfo, lockInfo);
    }

    function topUpLockPool(uint256 amount) external onlyOwner {
        require(!isPaused, "paused");
        require(IERC20(paymentToken).balanceOf(_msgSender()) >= amount, "Insufficient balance");
        IERC20(paymentToken).safeTransferFrom(_msgSender(), address(this), amount);
        tokenPool = tokenPool + amount;
    }

    function PutUpForSales(uint256 tokenId, uint256 price) external {
        require(!isPaused, "paused");
        require(ownerOf(tokenId) == _msgSender(), "Not owner");
        require(_getIndexInNftForSaleByToken(tokenId) > nftsForSale.length, "Token is already on sale");
        NFTForSale memory currentNftForSale = NFTForSale(tokenId, price);
        nftsForSale.push(currentNftForSale);
    }

    function takeFromSales(uint256 tokenId) public {
        require(!isPaused, "paused");
        require(ownerOf(tokenId) == _msgSender(), "Not owner");
        uint256 index = _getIndexInNftForSaleByToken(tokenId);
        require(index < nftsForSale.length, "Token not for sale");
        _removeNftForSale(index);
    }

    function buyNft(uint256 tokenId) public {
        require(!isPaused, "paused");
        uint256 index = _getIndexInNftForSaleByToken(tokenId);
        require(index < nftsForSale.length, "Token not for sale");
        uint256 price = nftsForSale[index].basePrice;
        uint256 fee = (price * resaleFee) / FEE_DECIMALS;
        require(IERC20(paymentToken).balanceOf(_msgSender()) >= price + fee, "Insufficient balance");
        IERC20(paymentToken).safeTransferFrom(
            _msgSender(),
            address(this),
            fee
        );
        IERC20(paymentToken).safeTransferFrom(
            _msgSender(),
            ownerOf(tokenId),
            price
        );

        _transfer(ownerOf(tokenId), _msgSender(), tokenId);
        _removeNftForSale(index);
    }

    function setResaleFee(uint256 newFee) external onlyOwner {
        resaleFee = newFee;
    }


    function _unlock(uint256 tokenId) private {
        _burn(tokenId);
        delete mapTokenLockInfo[tokenId];
    }

    function _canUnlock(TokenLockInfo memory tokenLockInfo, LockInfo memory lockInfo) view private returns (bool){
        if (block.timestamp > (tokenLockInfo.lockedAt + lockInfo.period)) {
            return true;
        } else {
            return false;
        }
    }

    function _lockNft(uint256 tokenId, uint256 lockId) private {
        TokenLockInfo memory tokenLock = TokenLockInfo(block.timestamp, block.timestamp, lockId, 0, NFTPrice);
        mapTokenLockInfo[tokenId] = tokenLock;
    }

    function _getIndexInNftForSaleByToken(uint256 tokenId) view private returns (uint256){
        for (uint256 i = 0; i < nftsForSale.length; i++) {
            if (nftsForSale[i].tokenId == tokenId) {
                return i;
            }
        }
        return nftsForSale.length + 99;
    }

    function _putNftForSale(uint256 tokenId, uint256 price) private {
        NFTForSale memory currentNftForSale = NFTForSale(tokenId, price);
        nftsForSale.push(currentNftForSale);
    }

    function _removeNftForSale(uint256 ind) private {
        nftsForSale[ind] = nftsForSale[nftsForSale.length - 1];
        nftsForSale.pop();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721) {
        require(_getIndexInNftForSaleByToken(tokenId) > nftsForSale.length, "Token is already on sale");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) {
        require(_getIndexInNftForSaleByToken(tokenId) > nftsForSale.length, "Token is already on sale");
        super.transferFrom(from, to, tokenId);
    }

    function setPaused(bool paused) external onlyOwner {
        isPaused = paused;
    }

    function setPaymentToken(address newPaymentToken) external onlyOwner {
        paymentToken = newPaymentToken;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdrawExtraTokens(
        address token,
        uint256 amount,
        address withdrawTo
    ) external onlyOwner {
        IERC20(token).safeTransfer(withdrawTo, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _migrate(address nftOwner, uint256 tokenId, uint256 lockedAt, uint256 lastPurchaseAt, uint256 lockId, uint256 cumulatedReward, uint256 price) external onlyOwner {
        require(migrateTo > block.timestamp, "OUT_OF_TIME");
        _safeMint(nftOwner, tokenId);
        _tokenIdCounter.increment();
        TokenLockInfo memory tokenLock = TokenLockInfo(lockedAt, lastPurchaseAt, lockId, cumulatedReward, price);
        mapTokenLockInfo[tokenId] = tokenLock;
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
        uint256 index = _getIndexInNftForSaleByToken(tokenId);
        if (index < nftsForSale.length) {
            _removeNftForSale(index);
        }
    }

}