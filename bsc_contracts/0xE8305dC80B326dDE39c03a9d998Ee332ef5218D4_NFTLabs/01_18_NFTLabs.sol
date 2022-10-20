pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTLabs is Ownable, ERC721, ERC721Enumerable, ERC721URIStorage {
    using Strings for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    struct TokenLockInfo {
        uint256 lockedAt;
        uint256 lastPurchaseAt;
        uint256 lockId;
    }

    struct LockInfo {
        uint256 period; //
        uint256 weight;
    }

    struct NFTForSale {
        uint256 tokenId;
        uint256 basePrice;
    }

    uint256 public constant FEE_DECIMALS = 100000;

    Counters.Counter private _tokenIdCounter;
    address public paymentToken; // default MMPRO
    string public baseUri;

    mapping(uint256 => TokenLockInfo) public mapTokenLockInfo;
    LockInfo[] public listLockInfo;
    uint256 public tokenPool;
    uint256 public totalWeight;
    uint256 public startDate;
    uint256 public unlockPeriod = 10 * 60; //30 * 24 * 60 * 60; // month

    uint256 public NFTPrice;
    uint256 public resaleFee;
    NFTForSale[] public nftsForSale;

    bool public isPaused;

    constructor(string memory name, string memory symbol, string memory uri, address _paymentToken, uint256 price, uint256 _resalesFee, uint256 _startDate) ERC721(name, symbol) {

        //        LockInfo memory tier1Lock = LockInfo(30 * 24 * 60 * 60, 1000);
        //        LockInfo memory tier2Lock = LockInfo(180 * 24 * 60 * 60, 1200);
        //        LockInfo memory tier3Lock = LockInfo(360 * 24 * 60 * 60, 1500)
        LockInfo memory tier1Lock = LockInfo(10 * 60, 1000);
        LockInfo memory tier2Lock = LockInfo(60 * 60, 1200);
        LockInfo memory tier3Lock = LockInfo(120 * 60, 1500);

        startDate = _startDate;

        listLockInfo.push(tier1Lock);
        listLockInfo.push(tier2Lock);
        listLockInfo.push(tier3Lock);

        setBaseURI(uri);
        paymentToken = _paymentToken;
        NFTPrice = price;
        resaleFee = _resalesFee;
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

    function unlock(uint256 tokenId) public {
        require(!isPaused, "paused");

        require(ownerOf(tokenId) == _msgSender(), "Not owner");

        TokenLockInfo memory tokenLockInfo = mapTokenLockInfo[tokenId];
        LockInfo memory lockInfo = listLockInfo[tokenLockInfo.lockId];

        require(_canUnlock(tokenLockInfo, lockInfo), "Unlock is not available now");
        _purchase(tokenLockInfo, lockInfo);
        _unlock(tokenId, lockInfo);

    }

    function canUnlock(uint256 tokenId) view public returns (bool){
        TokenLockInfo memory tokenLockInfo = mapTokenLockInfo[tokenId];
        LockInfo memory lockInfo = listLockInfo[tokenLockInfo.lockId];

        return _canUnlock(tokenLockInfo, lockInfo);
    }

    function purchase(uint256 tokenId) public {
        require(!isPaused, "paused");
        require(ownerOf(tokenId) == _msgSender(), "Not owner");

        TokenLockInfo memory tokenLockInfo = mapTokenLockInfo[tokenId];
        LockInfo memory lockInfo = listLockInfo[tokenLockInfo.lockId];
        _purchase(tokenLockInfo, lockInfo);
    }

    function getRewardAmount(uint256 tokenId, uint256 unlockAt) view public returns (uint256){
        TokenLockInfo memory tokenLockInfo = mapTokenLockInfo[tokenId];
        LockInfo memory lockInfo = listLockInfo[tokenLockInfo.lockId];

        return _getRewardAmount(tokenLockInfo, lockInfo, unlockAt);
    }

    function changeLockId(uint256 tokenId, uint256 newLockId) external {
        require(!isPaused, "paused");
        require(ownerOf(tokenId) == _msgSender(), "Not owner");

        TokenLockInfo memory tokenLockInfo = mapTokenLockInfo[tokenId];
        LockInfo memory oldLockInfo = listLockInfo[tokenLockInfo.lockId];
        LockInfo memory newLockInfo = listLockInfo[newLockId];

        require(newLockInfo.period > oldLockInfo.period, "Incorrect lock changes");

        totalWeight -= oldLockInfo.weight;
        totalWeight += newLockInfo.weight;

        tokenLockInfo.lockId = newLockId;
        mapTokenLockInfo[tokenId] = tokenLockInfo;
    }

    function topUpLockPool(uint256 amount) external onlyOwner {
        require(!isPaused, "paused");

        require(IERC20(paymentToken).balanceOf(_msgSender()) >= amount, "Insufficient balance");

        IERC20(paymentToken).safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );
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
        uint256 fee = getAbsoluteFee(price);

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

    function getAbsoluteFee(uint256 basePrice) view public returns (uint256) {
        return (basePrice * resaleFee) / FEE_DECIMALS;
    }

    function setResaleFee(uint256 newFee) external onlyOwner {
        resaleFee = newFee;
    }

    function _purchase(TokenLockInfo memory tokenLockInfo, LockInfo memory lockInfo) private {
        uint256 reward = _getRewardAmount(tokenLockInfo, lockInfo, block.timestamp);
        require(reward > 0, "Reward is 0");

        IERC20(paymentToken).safeTransferFrom(
            address(this),
            _msgSender(),
            reward
        );
    }

    function _unlock(uint256 tokenId, LockInfo memory lockInfo) private {
        _burn(tokenId);
        totalWeight -= lockInfo.weight;
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
        TokenLockInfo memory tokenLock = TokenLockInfo(block.timestamp, block.timestamp, lockId);
        mapTokenLockInfo[tokenId] = tokenLock;
        totalWeight += _getWeightOfLock(lockId);
    }

    function _getWeightOfLock(uint256 lockId) view private returns (uint256){
        LockInfo memory lock = listLockInfo[lockId];
        return lock.weight;
    }

    function _getRewardAmount(TokenLockInfo memory tokenLockInfo, LockInfo memory lockInfo, uint256 unlockAt) view private returns (uint256) {
        uint256 periodsGone = (unlockAt - startDate) / unlockPeriod;
        uint256 nearestPurchaseDatestamp = periodsGone * unlockPeriod + startDate;
        uint256 reward;
        if (nearestPurchaseDatestamp <= tokenLockInfo.lastPurchaseAt) {
            reward = 0;
        } else {
            uint256 deltaTime = nearestPurchaseDatestamp - tokenLockInfo.lastPurchaseAt;

            reward = (deltaTime * tokenPool * lockInfo.weight) / (totalWeight * unlockPeriod);
        }
        if (reward < tokenPool) {
            return reward;
        } else {
            return tokenPool;
        }
    }

    function _getIndexInNftForSaleByToken(uint256 tokenId) private returns (uint256){
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

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function getURI(uint256 tokenId) pure private returns (string memory) {
        return string(abi.encodePacked(tokenId.toString(), ".json"));
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
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

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        uint256 index = _getIndexInNftForSaleByToken(tokenId);
        if (index < nftsForSale.length) {
            _removeNftForSale(index);
        }
    }

}