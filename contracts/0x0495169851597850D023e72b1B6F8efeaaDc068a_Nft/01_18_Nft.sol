// SPDX-License-Identifier: UNLICENSED

// Code by zipzinger and cmtzco
// DEFIBOYS
// defiboys.com

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

import "./Unlockable.sol";
import "./NftManager.sol";

library SwapMapping {
    struct Map {
        uint256[] tradableNfts;
        mapping(uint256 => uint256) price;
        mapping(uint256 => uint256) indexOf;
        mapping(uint256 => bool) inserted;
    }

    function get(Map storage map, uint256 nftId)
        external
        view
        returns (uint256)
    {
        return map.price[nftId];
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        external
        view
        returns (uint256)
    {
        return map.tradableNfts[index];
    }

    function size(Map storage map) external view returns (uint256) {
        return map.tradableNfts.length;
    }

    function set(
        Map storage map,
        uint256 key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.price[key] = val;
        } else {
            map.inserted[key] = true;
            map.price[key] = val;
            map.indexOf[key] = map.tradableNfts.length;
            map.tradableNfts.push(key);
        }
    }

    function remove(Map storage map, uint256 key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.price[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.tradableNfts.length - 1;
        uint256 lastKey = map.tradableNfts[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.tradableNfts[index] = lastKey;
        map.tradableNfts.pop();
    }
}


contract Nft is ERC721Enumerable, ERC721Pausable, Ownable, Unlockable {
    using Address for address payable;
    using SwapMapping for SwapMapping.Map;

    event NFTRoyaltyPaid(address payable addressPaid, uint256 paymentAmount);

    SwapMapping.Map private _swapMap;
    string public baseURI;
    uint256 public nftIndex;
    uint256 public maxNftCount;
    uint256 public currentPrice;
    address payable public artistAddress;
    address payable public nftManagerAddress;
    mapping(uint256 => address payable) public royaltyRecipients;
    mapping(uint256 => uint256) public royaltyPercents;
    uint256 public royaltyCount;
    string public contractMetadataURI;

    constructor(
        uint256 _maxNftCount,
        address payable _nftManagerAddress,
        uint256 _currentPrice,
        address payable _artistAddress,
        uint256 _royaltyPercent,
        string memory nftName,
        string memory nftSymbol,
        bool _unlockable
    ) ERC721(nftName, nftSymbol) {
        require(_currentPrice > 0, "NFT sale price cant be 0");
        _pause();
        unlockableContent = _unlockable;
        nftIndex = 0;
        royaltyCount = 0;
        maxNftCount = _maxNftCount;
        currentPrice = _currentPrice;
        artistAddress = _artistAddress;
        setNewRoyalty(_artistAddress, _royaltyPercent);
        uint256 nftPercent = SafeMath.sub(9500, _royaltyPercent);
        nftManagerAddress = _nftManagerAddress;

        address payable nftWallet = payable(msg.sender);
        setNewRoyalty(nftWallet, nftPercent);
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function listedTokens() external view returns (uint256[] memory) {
        return _swapMap.tradableNfts;
    }

    function ownedTokens(address payable _addr)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_addr);
        uint256[] memory result = new uint256[](balance);
        uint256 balId;

        for (balId = 0; balId < balance; balId++) {
            result[balId] = tokenOfOwnerByIndex(_addr, balId);
        }

        return result;
    }

    function sumRoyalties() private view returns (uint256) {
        uint256 royaltySum = 0;
        uint256 id;

        if (royaltyCount == 0) {
            return 0;
        }

        for (id = 1; id <= royaltyCount; id++) {
            royaltySum = SafeMath.add(royaltySum, royaltyPercents[id]);
        }
        return royaltySum;
    }

    function setRoyalty(
        uint256 _id,
        address payable _addr,
        uint256 _royaltyPercent
    ) external onlyOwner {
        require(_id <= royaltyCount, "Invalid royalty id provided");
        uint256 newRoyaltySum = SafeMath.sub(
            SafeMath.add(sumRoyalties(), _royaltyPercent),
            royaltyPercents[_id]
        );
        require(newRoyaltySum <= 9500, "Royalty overflow");

        setRoyaltyAddress(_id, _addr);
        setRoyaltyPercent(_id, _royaltyPercent);
    }

    function setNewRoyalty(address payable _addr, uint256 _royaltyPercent)
        public
        onlyOwner
    {
        uint256 newRoyaltySum = SafeMath.add(sumRoyalties(), _royaltyPercent);
        require(newRoyaltySum <= 9500, "Royalty overflow");

        uint256 _id = SafeMath.add(royaltyCount, 1);
        setRoyaltyAddress(_id, _addr);
        setRoyaltyPercent(_id, _royaltyPercent);
        royaltyCount += 1;
    }

    function setRoyaltyAddress(uint256 _id, address payable _addr) internal {
        royaltyRecipients[_id] = _addr;
    }

    function setRoyaltyPercent(uint256 _id, uint256 _royaltyPercent) internal {
        royaltyPercents[_id] = _royaltyPercent;
    }

    function setArtistAddress(address payable _artistAddress)
        external
        onlyOwner
    {
        royaltyRecipients[1] = _artistAddress;
    }

    function setCurrentPrice(uint256 _currentPrice) external onlyOwner {
        require(_currentPrice > 0, "NFT sale price must be higher than 0.");
        currentPrice = _currentPrice;
    }

    function setMaxNFTCount(uint256 _count) external onlyOwner {
        require(_count >= nftIndex, "maxNFTCount must be larger than nftIndex");
        maxNftCount = _count;
    }

    function collectDust() external onlyOwner {
        msg.sender.call{value: address(this).balance}("");
    }

    function nftBuy() external payable {
        require(msg.value >= currentPrice, "Send more money. Buy failed");
        require(!paused(), "Nft not released yet");

        uint256 testNum = SafeMath.add(nftIndex, 1);
        require(testNum <= maxNftCount, "NFT sold out");

        nftIndex += 1;

        _safeMint(msg.sender, nftIndex);

        _swapMap.remove(nftIndex);

        _payRoyalties(2, msg.value);
        _payRoyalties(1, msg.value);
    }

    function _payRoyalties(uint256 _royaltyIndex, uint256 _value) private {
        require(_royaltyIndex > 0, "Invalid royaltyIndex");

        uint256 payPercent = royaltyPercents[_royaltyIndex];
        uint256 paymentAmount = SafeMath.div(
            SafeMath.mul(uint256(_value), uint256(payPercent)),
            uint256(10000)
        );

        Address.sendValue(royaltyRecipients[_royaltyIndex], paymentAmount);

        if (_royaltyIndex == 1) {
            emit NFTRoyaltyPaid(
                royaltyRecipients[_royaltyIndex],
                paymentAmount
            );
        }
    }

    function nftList(uint256 _id, uint256 _price) external {
        require(
            _isApprovedOrOwner(msg.sender, _id),
            "You aren't the owner of this NFT"
        );
        require(_price > 0, "Swap price must be > 0");
        approve(nftManagerAddress, _id);
        _swapMap.set(_id, _price);
    }

    function nftSwap(uint256 _id) external payable {
        require(_swapMap.inserted[_id], "NFT: NFT not available for swap");
        require(_swapMap.price[_id] > 0, "NFT: NFT not available for swap");
        require(
            msg.value >= _swapMap.price[_id],
            "NFT: Insufficient money sent for swap"
        );

        address payable originalOwner = payable(ownerOf(_id));

        _nftManagerSwap(msg.sender, _id);

        uint256 maxPayoutForRoyalties = SafeMath.div(
            SafeMath.mul(uint256(msg.value), uint256(2000)),
            uint256(10000)
        );
        uint256 salePayoutForSeller = SafeMath.sub(
            msg.value,
            maxPayoutForRoyalties
        );

        Address.sendValue(originalOwner, salePayoutForSeller);

        _payRoyalties(2, maxPayoutForRoyalties);
        _payRoyalties(1, maxPayoutForRoyalties);

        _swapMap.remove(_id);
    }

    function nftListCancel(uint256 _id) public {
        require(
            _isApprovedOrOwner(msg.sender, _id),
            "You arent the owner of this NFT"
        );
        _swapMap.remove(_id);
    }

    function setManagerAddress(address payable _addr) external onlyOwner {
        nftManagerAddress = _addr;
    }

    function _nftManagerSwap(address _recipient, uint256 _id) private {
        NftManager(nftManagerAddress).swap(_recipient, _id);
    }

    function nftManagerPerformSwap(address _recipient, uint256 _tokenID)
        external
    {
        require(msg.sender == nftManagerAddress, "Caller not nftManager");
        address originalOwner = ownerOf(_tokenID);
        safeTransferFrom(originalOwner, _recipient, _tokenID);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseURIInput) external onlyOwner {
        baseURI = _baseURIInput;
    }

    function getTradeStatus(uint256 _id) public view returns (bool) {
        if (!_swapMap.inserted[_id]) {
            return false;
        }
        return _swapMap.inserted[_id];
    }

    function getTradePrice(uint256 _id) external view returns (uint256) {
        if (!_swapMap.inserted[_id]) {
            return 0;
        }
        return _swapMap.price[_id];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721Pausable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
        ERC721Pausable._beforeTokenTransfer(from, to, tokenId);
        if (getTradeStatus(tokenId)) {
            nftListCancel(tokenId);
        }
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        if (getTradeStatus(tokenId)) {
            nftListCancel(tokenId);
        }

        _approve(to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        super.supportsInterface(interfaceId);
    }

    function setContractURI(string memory _uri) external onlyOwner {
        contractMetadataURI = _uri;
    }

    function contractURI() external view returns (string memory) {
        return contractMetadataURI;
    }
}