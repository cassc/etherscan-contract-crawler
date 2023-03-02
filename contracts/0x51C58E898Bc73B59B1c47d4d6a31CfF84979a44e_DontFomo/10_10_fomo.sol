// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

pragma solidity >=0.8.7;

contract KeysWrapper {
    using SafeMath for uint256;

    //WINNER
    mapping(uint256 => uint256) internal _winnerBonus;
    mapping(uint256 => uint256) internal _artistBonus;
    //KEYS
    mapping(uint256 => uint256) internal totalKeys;
    mapping(uint256 => uint256) internal totalKeysRewarded;
    mapping(uint256 => uint256) internal totalKeysPhantom;
    mapping(uint256 => mapping(address => uint256)) internal balanceOfKeys;
    mapping(uint256 => mapping(address => uint256)) internal balanceOfPhantom;

    function getTotalKeys(uint256 id) public view returns (uint256) {
        return totalKeys[id];
    }

    function winnerBonus(uint256 id) public view returns (uint256) {
        return _winnerBonus[id];
    }

    function artistBonus(uint256 id) public view returns (uint256) {
        return _artistBonus[id];
    }

    function bonusOf(uint256 id, address account)
        public
        view
        returns (uint256)
    {
        uint256 _totalKeys = totalKeys[id];
        if (_totalKeys == 0) {
            return 0;
        }

        uint256 totalRewardedWithPhantom = totalKeysRewarded[id].add(
            totalKeysPhantom[id]
        );
        uint256 balanceOfRewardedWithPhantom = totalRewardedWithPhantom
            .mul(balanceOfKeys[id][account])
            .div(_totalKeys);

        uint256 _balanceOfPhantom = balanceOfPhantom[id][account];
        if (balanceOfRewardedWithPhantom > _balanceOfPhantom) {
            return balanceOfRewardedWithPhantom.sub(_balanceOfPhantom);
        }
        return 0;
    }

    function poolInfoByAddress(address account, uint256 id)
        public
        view
        returns (
            uint256 winnerPool,
            uint256 keysTotal,
            uint256 keys,
            uint256 bonus
        )
    {
        winnerPool = _winnerBonus[id];
        keysTotal = totalKeys[id];
        keys = balanceOfKeys[id][account];
        bonus = bonusOf(id, account);
    }

    function incrementBalanceOfKeys(address owner, uint256 amount, uint256 id) internal {
        balanceOfKeys[id][owner] = balanceOfKeys[id][owner].add(amount);
        totalKeys[id] = totalKeys[id].add(amount);
    }

    function incrementBalanceOfPhantom(address owner, uint256 amount, uint256 id) internal {
        balanceOfPhantom[id][owner] = balanceOfPhantom[id][owner].add(amount);
        totalKeysPhantom[id] = totalKeysPhantom[id].add(amount);
    }

    function decrementBalanceOfKeys(address owner, uint256 amount, uint256 id) internal {
        balanceOfKeys[id][owner] = balanceOfKeys[id][owner].sub(amount);
        totalKeys[id] = totalKeys[id].sub(amount);
    }

    function decrementBalanceOfPhantom(address owner, uint256 amount, uint256 id) internal {
        balanceOfPhantom[id][owner] = balanceOfPhantom[id][owner].sub(amount);
        totalKeysPhantom[id] = totalKeysPhantom[id].sub(amount);
    }

    function purchase(uint256 id, uint256 value, uint256 keysAmount) internal {
        // 50% keys bonus, 30% winner bonus, 20% artist bonus
        uint256 keysBonusAdd = value.div(2);
        uint256 winnerBonusAdd = value.mul(3).div(10);
        _winnerBonus[id] = _winnerBonus[id].add(winnerBonusAdd);
        _artistBonus[id] = _artistBonus[id].add(value.sub(keysBonusAdd).sub(winnerBonusAdd));

        uint256 totalKeysRewardedWithPhantom = totalKeysRewarded[id].add(
            totalKeysPhantom[id]
        );

        uint256 newPhantom = totalKeys[id] == 0
            ? totalKeysRewarded[id] == 0
                ? keysAmount.mul(1e8)
                : 0
            : totalKeysRewardedWithPhantom.mul(keysAmount).div(totalKeys[id]);

        //update keys rewards
        totalKeysRewarded[id] = totalKeysRewarded[id].add(keysBonusAdd);

        incrementBalanceOfKeys(msg.sender, keysAmount, id);
        incrementBalanceOfPhantom(msg.sender, newPhantom, id);
    }

    function withdrawKeyBonus(uint256 id) internal virtual {
        uint256 amount = bonusOf(id, msg.sender);
        if(amount > 0){
            // update reward
            totalKeysRewarded[id] = totalKeysRewarded[id].sub(amount);
            // unbound
            uint256 keys = balanceOfKeys[id][msg.sender];
            uint256 phantom = balanceOfPhantom[id][msg.sender];
            decrementBalanceOfKeys(msg.sender, keys, id);
            decrementBalanceOfPhantom(msg.sender, phantom, id);

            // bound
            uint256 totalKeysRewardedWithPhantom = totalKeysRewarded[id].add(
                totalKeysPhantom[id]
            );
            uint256 newPhantom = totalKeys[id] == 0
            ? 0 : totalKeysRewardedWithPhantom.mul(keys).div(totalKeys[id]);
            incrementBalanceOfKeys(msg.sender, keys, id);
            incrementBalanceOfPhantom(msg.sender, newPhantom, id);            
            payable(msg.sender).transfer(amount);
        }
    }

    function _end(
        uint256 id,
        address winnerAddress,
        address artistAddress
    ) internal {
        // artist
        uint256 artistFee = _artistBonus[id];
        if(artistFee > 0){
            _artistBonus[id] = 0;
            payable(artistAddress).transfer(artistFee);
        }
        // winner
        uint256 winnerFee = _winnerBonus[id];
        if(winnerFee > 0){
            _winnerBonus[id] = 0;
            payable(winnerAddress).transfer(winnerFee);
        }
    }
}

interface MEME1155 {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;
}

contract KeyHelper {
    using SafeMath for uint256;

    function sqrt(uint x) public pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function eth(uint256 _keys) 
        public
        pure
        returns(uint256)  
    {
        return _keys.mul(74999921875000).add((_keys.add(_keys.mul(_keys))).div(2).mul(1562500000));
    }

    function keyPrice(uint256 _num) 
        public
        pure
        returns(uint256)  
    {   
        return _num.mul(1562500000).add(74999921875000);
    }

    function eth(uint256 _curkeys, uint256 _keys) public pure returns(uint256){
        return eth(_keys.add(_curkeys)).sub(eth(_curkeys));
    }

    function keys(uint256 _eth) public pure returns(uint256){
        return (sqrt(_eth.mul(3125000000).add(5624988281256103515625000000)).sub(74999921875000)).div(1562500000);
    }

    function keys(uint256 _curEth, uint256 _eth) public pure returns(uint256){
        return keys(_eth.add(_curEth)).sub(keys(_curEth));
    }
}

contract DontFomo is
    KeysWrapper,
    KeyHelper,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private auctionID;
    mapping(uint256 => mapping(address => uint256)) public minted;

    // info about a particular auction
    struct AuctionInfo {
        uint256 auctionID;
        address artist;
        uint256 duration;
        uint256 auctionStart;
        uint256 auctionEnd;
        uint256 originalAuctionEnd;
        uint256 extension;
        address highestBidder;
        bool auctionEnded;
        NFTInfo nftInfo;
    }

    struct NFTInfo {
        address nftAddress;
        uint256 tokenID;
    }

    mapping(uint256 => AuctionInfo) public auctionsById;
    uint256[] public auctions;

    // Events that will be fired on changes.
    event BidPlaced(address indexed user, uint256 indexed id, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed id, uint256 amount);
    event Ended(address indexed user, uint256 indexed id, uint256 amount);

    function initialize(
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function auctionStart(uint256 id) public view returns (uint256) {
        return auctionsById[id].auctionStart;
    }

    function artist(uint256 id) public view returns (address) {
        return auctionsById[id].artist;
    }

    function auctionEnd(uint256 id) public view returns (uint256) {
        return auctionsById[id].auctionEnd;
    }

    function pingappleNFTTokenID(uint256 id) public view returns (uint256) {
        return auctionsById[id].nftInfo.tokenID;
    }

    function highestBidder(uint256 id) public view returns (address) {
        return auctionsById[id].highestBidder;
    }

    function highestBid(uint256 id) public view returns (uint256) {
        return KeyHelper.keyPrice(getTotalKeys(id));
    }

    function ended(uint256 id) public view returns (bool) {
        return block.timestamp >= auctionsById[id].auctionEnd;
    }

    function blockTime() public view returns (uint256) {
        return block.timestamp;
    }

    function create(
        address artistAddress,
        uint256 start,
        uint256 duration,  // in minutes
        uint256 extension // in minutes
    ) external onlyOwner returns (uint256 id) {
        AuctionInfo storage auction = auctionsById[auctionID.current()];
        require(
            auction.artist == address(0),
            "Create: auction already created"
        );

        auction.auctionID = auctionID.current();
        auction.artist = artistAddress;
        auction.duration = duration * 60;
        auction.auctionStart = start;
        auction.auctionEnd = start.add(auction.duration);
        auction.originalAuctionEnd = start.add(auction.duration);
        auction.extension = extension * 60;

        auctions.push(auctionID.current());
        auctionID.increment();

        return auction.auctionID;
    }

    function setNFT(uint256 id, address nftAddress, uint256 tokenID) external onlyOwner{
        AuctionInfo storage auction = auctionsById[id];
        auction.nftInfo.nftAddress = nftAddress;
        auction.nftInfo.tokenID = tokenID;
    }

    function ethFee(uint256 id, uint256 keys) public view returns(uint256){
        return KeyHelper.eth(getTotalKeys(id), keys);
    }

    function keyCount(uint256 id, uint256 eth) public view returns(uint256){
        return KeyHelper.keys(KeyHelper.eth(getTotalKeys(id)), eth);
    }

    function bid(uint256 id) public nonReentrant payable{
        AuctionInfo storage auction = auctionsById[id];
        require(
            msg.value >= highestBid(id),
            "Purchase: not enough eth"
        );
        require(
            block.timestamp >= auction.auctionStart,
            "Purchase: auction has not started"
        );
        require(
            block.timestamp <= auction.auctionEnd,
            "Purchase: auction has ended"
        );
        require(
            auction.artist != address(0),
            "Purchase: auction does not exist"
        );

        uint256 keys = keyCount(id, msg.value);
        // max 1000 keys
        keys = keys > 1000 ? 1000 : keys;

        uint256 amount = ethFee(id, keys);

        require(
            msg.value >= amount,
            "Purchase: not enough eth"
        );

        // refund
        if(msg.value.sub(amount) > 0){
            payable(msg.sender).transfer(msg.value.sub(amount));
        }

        auction.highestBidder = msg.sender;

        auction.auctionEnd = auction.extension.mul(keys).add(auction.auctionEnd);
        if(auction.auctionEnd - block.timestamp > auction.duration){
            auction.auctionEnd = block.timestamp.add(auction.duration);
        }

        purchase(id, amount, keys);

        emit BidPlaced(msg.sender, id, keys);
    }

    function withdrawBonus(uint256 id) public nonReentrant {
        AuctionInfo memory auction = auctionsById[id];
        uint256 amount = bonusOf(id, msg.sender);
        require(
            auction.artist != address(0),
            "WithdrawBonus: auction does not exist"
        );
        require(amount > 0, "WithdrawBonus: cannot withdraw 0");

        withdrawKeyBonus(id);
        emit Withdrawn(msg.sender, id, amount);
    }

    function withdrawArtistFee(uint256 id) public nonReentrant {
        // artist
        AuctionInfo memory auction = auctionsById[id];

        uint256 artistFee = _artistBonus[id];
        if(artistFee > 0){
            _artistBonus[id] = 0;
            payable(auction.artist).transfer(artistFee);
        }
    }

    function end(uint256 id) public nonReentrant {
        AuctionInfo storage auction = auctionsById[id];
        require(
            block.timestamp >= auction.auctionEnd,
            "End: the auction has not ended"
        );
        require(
            !auction.auctionEnded,
            "End: auction already ended"
        );

        auction.auctionEnded = true;

        _end(
            id,
            auction.highestBidder,
            auction.artist
        );
    }

    function redeem(uint256 id) public nonReentrant {
        AuctionInfo storage auction = auctionsById[id];
        uint256 nfts = balanceOfKeys[id][msg.sender].sub(minted[id][msg.sender]);
        require(
            nfts > 0,
            "Redeem: no redeemable"
        );    
        address nftAddress = auction.nftInfo.nftAddress;
        uint256 tokenID = auction.nftInfo.tokenID;
        MEME1155(nftAddress).mint(msg.sender, tokenID, nfts);
        minted[id][msg.sender] = minted[id][msg.sender].add(nfts);
    }
}