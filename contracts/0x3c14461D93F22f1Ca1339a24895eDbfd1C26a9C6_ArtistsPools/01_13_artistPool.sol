// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract PoolTokenWrapper {
    using SafeMath for uint256;
    IERC20 public token;

    constructor(IERC20 _erc20Address) {
        token = IERC20(_erc20Address);
    }

    uint256 private _totalSupply;
    // Objects balances [id][address] => balance
    mapping(uint256 => mapping(address => uint256)) internal _balances;
    mapping(address => uint256) private _accountBalances;
    mapping(uint256 => uint256) private _poolBalances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOfAccount(address account) public view returns (uint256) {
        return _accountBalances[account];
    }

    function balanceOfPool(uint256 id) public view returns (uint256) {
        return _poolBalances[id];
    }

    function balanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        return _balances[id][account];
    }

    function stake(uint256 id, uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _poolBalances[id] = _poolBalances[id].add(amount);
        _accountBalances[msg.sender] = _accountBalances[msg.sender].add(amount);
        _balances[id][msg.sender] = _balances[id][msg.sender].add(amount);
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 id, uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _poolBalances[id] = _poolBalances[id].sub(amount);
        _accountBalances[msg.sender] = _accountBalances[msg.sender].sub(amount);
        _balances[id][msg.sender] = _balances[id][msg.sender].sub(amount);
        token.transfer(msg.sender, amount);
    }

    function transfer(
        uint256 fromId,
        uint256 toId,
        uint256 amount
    ) public virtual {
        _poolBalances[fromId] = _poolBalances[fromId].sub(amount);
        _balances[fromId][msg.sender] = _balances[fromId][msg.sender].sub(
            amount
        );

        _poolBalances[toId] = _poolBalances[toId].add(amount);
        _balances[toId][msg.sender] = _balances[toId][msg.sender].add(amount);
    }

    function _rescuePineapples(address account, uint256 id) internal {
        uint256 amount = _balances[id][account];

        _totalSupply = _totalSupply.sub(amount);
        _poolBalances[id] = _poolBalances[id].sub(amount);
        _accountBalances[msg.sender] = _accountBalances[msg.sender].sub(amount);
        _balances[id][account] = _balances[id][account].sub(amount);
        token.transfer(account, amount);
    }
}

interface MEME721 {
    function totalSupply(uint256 _id) external view returns (uint256);

    function maxSupply(uint256 _id) external view returns (uint256);

    function mint(address _to, uint256 _baseTokenID) external returns (uint256);

    function create(uint256 _maxSupply) external returns (uint256 tokenId);
}

interface Auction {
    function create(
        uint256 poolID,
        address artistAddress,
        uint256 start,
        uint256 duration,
        uint256 extension, // in minutes
        address nftAddress,
        bool isArtistContract,
        bool isERC721,
        uint256 nftTokenID,
        address nftHolder,
        bool isFunBid
    ) external returns (uint256 id);
}

contract ArtistsPools is
    PoolTokenWrapper,
    Ownable,
    IERC1155Receiver,
    IERC721Receiver
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct CardNFT {
        uint256 supply;
        uint256 minted;
        bool isERC721;
        bool isMEME721;
        address nftAddress;
        uint256[] tokenID;
    }

    struct Card {
        uint256 points;
        uint256 releaseTime;
        uint256 mintFee;
        bool isETHFee;
        CardNFT cardNFT;
    }

    struct Pool {
        address owner;
        uint256 periodStart;
        uint256 maxStake;
        uint256 spentPineapples;
        uint256 controllerShare;
        address artist;
        mapping(address => uint256) lastUpdateTime;
        mapping(address => uint256) points;
        mapping(uint256 => Card) cards;
        uint256[] auctions;
    }

    address public controller;
    uint256 public controllerShare;
    address public rescuer;
    bool public open;
    mapping(address => uint256) public pendingWithdrawalsETH;
    mapping(address => uint256) public pendingWithdrawalsMEME;
    mapping(uint256 => Pool) public pools;
    Counters.Counter poolsID;
    mapping(uint256 => Counters.Counter) cardIDs;

    IERC20 public memeToken;
    Auction public auction;
    MEME721 public meme721;

    event UpdatedArtist(uint256 poolId, address artist);
    event PoolAdded(
        uint256 poolId,
        address artist,
        uint256 periodStart,
        uint256 maxStake
    );
    event CardAdded(
        uint256 poolId,
        uint256 cardId,
        uint256 points,
        uint256 mintFee,
        uint256 releaseTime
    );
    event Staked(address indexed user, uint256 poolId, uint256 amount);
    event Withdrawn(address indexed user, uint256 poolId, uint256 amount);
    event Transferred(
        address indexed user,
        uint256 fromPoolId,
        uint256 toPoolId,
        uint256 amount
    );
    event Redeemed(address indexed user, uint256 poolId, uint256 amount);

    modifier updateReward(address account, uint256 id) {
        if (account != address(0)) {
            pools[id].points[account] = earned(account, id);
            pools[id].lastUpdateTime[account] = block.timestamp;
        }
        _;
    }

    modifier poolExists(uint256 id) {
        require(pools[id].owner != address(0), "pool does not exists");
        _;
    }

    modifier cardExists(uint256 pool, uint256 card) {
        require(pools[pool].cards[card].points > 0, "card does not exists");
        _;
    }

    modifier ownerOrPoolOwner(uint256 pool) {
        require(
            owner() == msg.sender || (open && pools[pool].owner == msg.sender),
            "not open to public or you are not the owner of the pool"
        );
        _;
    }

    constructor(
        address _controller,
        address _memeNFTAddress,
        IERC20 _tokenAddress,
        address _auctionAddress
    ) PoolTokenWrapper(_tokenAddress) {
        controller = _controller;
        meme721 = MEME721(_memeNFTAddress);
        memeToken = IERC20(address(_tokenAddress));
        auction = Auction(_auctionAddress);
    }

    function cardBaseInfo(uint256 pool, uint256 card)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            pools[pool].cards[card].points,
            pools[pool].cards[card].releaseTime,
            pools[pool].cards[card].mintFee,
            pools[pool].cards[card].isETHFee
        );
    }

    function cardNFTInfo(uint256 pool, uint256 card)
        public
        view
        returns (
            uint256,
            uint256,
            bool,
            bool,
            address,
            uint256[] memory
        )
    {
        return (
            pools[pool].cards[card].cardNFT.supply,
            pools[pool].cards[card].cardNFT.minted,
            pools[pool].cards[card].cardNFT.isERC721,
            pools[pool].cards[card].cardNFT.isMEME721,
            pools[pool].cards[card].cardNFT.nftAddress,
            pools[pool].cards[card].cardNFT.tokenID
        );
    }

    function earned(address account, uint256 pool)
        public
        view
        returns (uint256)
    {
        Pool storage p = pools[pool];
        uint256 blockTime = block.timestamp;
        return
            p.points[account].add(
                blockTime
                    .sub(
                        p.lastUpdateTime[account] >= p.periodStart
                            ? p.lastUpdateTime[account]
                            : p.periodStart
                    )
                    .mul(balanceOf(account, pool))
                    .div(86400)
            );
    }

    // override PoolTokenWrapper's stake() function
    function stake(uint256 pool, uint256 amount)
        public
        override
        poolExists(pool)
        updateReward(msg.sender, pool)
    {
        Pool storage p = pools[pool];

        require(block.timestamp >= p.periodStart, "pool not open");
        require(
            amount.add(balanceOf(msg.sender, pool)) <= p.maxStake,
            "stake exceeds max"
        );

        super.stake(pool, amount);
        emit Staked(msg.sender, pool, amount);
    }

    // override PoolTokenWrapper's withdraw() function
    function withdraw(uint256 pool, uint256 amount)
        public
        override
        poolExists(pool)
        updateReward(msg.sender, pool)
    {
        require(amount > 0, "cannot withdraw 0");

        super.withdraw(pool, amount);
        emit Withdrawn(msg.sender, pool, amount);
    }

    // override PoolTokenWrapper's transfer() function
    function transfer(
        uint256 fromPool,
        uint256 toPool,
        uint256 amount
    )
        public
        override
        poolExists(fromPool)
        poolExists(toPool)
        updateReward(msg.sender, fromPool)
        updateReward(msg.sender, toPool)
    {
        Pool storage toP = pools[toPool];

        require(block.timestamp >= toP.periodStart, "pool not open");
        require(
            amount.add(balanceOf(msg.sender, toPool)) <= toP.maxStake,
            "stake exceeds max"
        );

        super.transfer(fromPool, toPool, amount);
        emit Transferred(msg.sender, fromPool, toPool, amount);
    }

    function transferAll(uint256 fromPool, uint256 toPool) external {
        transfer(fromPool, toPool, balanceOf(msg.sender, fromPool));
    }

    function exit(uint256 pool) external {
        withdraw(pool, balanceOf(msg.sender, pool));
    }

    function redeem(uint256 pool, uint256 card)
        public
        payable
        poolExists(pool)
        cardExists(pool, card)
        updateReward(msg.sender, pool)
    {
        Pool storage p = pools[pool];
        Card storage c = p.cards[card];
        require(block.timestamp >= c.releaseTime, "card not released");
        require(p.points[msg.sender] >= c.points, "not enough pineapples");
        require(c.cardNFT.minted < c.cardNFT.supply, "Max supply reached");
        if (c.isETHFee) {
            require(msg.value == c.mintFee, "support our artists, send eth");
        } else {
            require(
                memeToken.balanceOf(msg.sender) >= c.mintFee,
                "support our artists, send meme"
            );
        }

        if (c.mintFee > 0) {
            uint256 _controllerShare = c.mintFee.mul(p.controllerShare).div(
                1000
            );
            uint256 _artistRoyalty = c.mintFee.sub(_controllerShare);
            require(
                _artistRoyalty.add(_controllerShare) == c.mintFee,
                "problem with fee"
            );

            if (c.isETHFee) {
                pendingWithdrawalsETH[controller] = pendingWithdrawalsETH[
                    controller
                ].add(_controllerShare);
                pendingWithdrawalsETH[p.artist] = pendingWithdrawalsETH[
                    p.artist
                ].add(_artistRoyalty);
            } else {
                memeToken.transferFrom(msg.sender, address(this), c.mintFee);

                pendingWithdrawalsMEME[controller] = pendingWithdrawalsMEME[
                    controller
                ].add(_controllerShare);
                pendingWithdrawalsMEME[p.artist] = pendingWithdrawalsMEME[
                    p.artist
                ].add(_artistRoyalty);
            }
        }

        p.points[msg.sender] = p.points[msg.sender].sub(c.points);
        p.spentPineapples = p.spentPineapples.add(c.points);

        // mint nfts

        c.cardNFT.minted = c.cardNFT.minted.add(1);

        if (c.cardNFT.isMEME721) {
            meme721.mint(msg.sender, c.cardNFT.tokenID[0]);
        } else if (c.cardNFT.isERC721) {
            for (uint256 i = 0; i < c.cardNFT.supply; ++i) {
                if (
                    IERC721(c.cardNFT.nftAddress).ownerOf(
                        c.cardNFT.tokenID[i]
                    ) == address(this)
                ) {
                    IERC721(c.cardNFT.nftAddress).safeTransferFrom(
                        address(this),
                        msg.sender,
                        c.cardNFT.tokenID[i]
                    );
                    break;
                }
            }
        } else {
            IERC1155(c.cardNFT.nftAddress).safeTransferFrom(
                address(this),
                msg.sender,
                c.cardNFT.tokenID[0],
                1,
                ""
            );
        }

        emit Redeemed(msg.sender, pool, c.points);
    }

    function rescuePineapples(address account, uint256 pool)
        public
        poolExists(pool)
        updateReward(account, pool)
        returns (uint256)
    {
        require(msg.sender == rescuer, "!rescuer");
        Pool storage p = pools[pool];

        uint256 earnedPoints = p.points[account];
        p.spentPineapples = p.spentPineapples.add(earnedPoints);
        p.points[account] = 0;

        // transfer remaining MEME to the account
        if (balanceOf(account, pool) > 0) {
            _rescuePineapples(account, pool);
        }

        emit Redeemed(account, pool, earnedPoints);
        return earnedPoints;
    }

    function setArtist(uint256 pool, address artist)
        public
        poolExists(pool)
        ownerOrPoolOwner(pool)
    {
        pools[pool].artist = artist;
        emit UpdatedArtist(pool, artist);
    }

    function setControllerShare(uint256 _controllerShare) public onlyOwner {
        controllerShare = _controllerShare;
    }

    function setRescuer(address _rescuer) public onlyOwner {
        rescuer = _rescuer;
    }

    function setController(address _controller) public onlyOwner {
        controller = _controller;
    }

    function setOpen(bool _open) public onlyOwner {
        open = _open;
    }

    function setMeme721(address _address) public onlyOwner {
        meme721 = MEME721(_address);
    }

    function setMemeToken(address _address) public onlyOwner {
        memeToken = IERC20(address(_address));
    }

    function setAuction(address _address) public onlyOwner {
        auction = Auction(_address);
    }

    function setPoolReleaseTime(uint256 pool, uint256 time)
        public
        poolExists(pool)
        ownerOrPoolOwner(pool)
    {
        pools[pool].periodStart = time;
    }

    function createAuction(
        uint256 pool,
        address artistAddress,
        uint256 start,
        uint256 duration,
        uint256 extension, // in minutes
        address nftAddress,
        bool isArtistContract,
        bool isERC721,
        uint256 nftTokenID,
        bool isFunBid
    ) public poolExists(pool) ownerOrPoolOwner(pool) {
        uint256 auctionID = auction.create(
            pool,
            artistAddress,
            start,
            duration,
            extension,
            nftAddress,
            isArtistContract,
            isERC721,
            nftTokenID,
            msg.sender,
            isFunBid
        );
        pools[pool].auctions.push(auctionID);
    }

    function createCard(
        uint256 pool,
        uint256 supply,
        uint256 points,
        uint256 mintFee,
        bool isETHFee,
        uint256 releaseTime,
        bool isERC721,
        bool isMEME721,
        address nftAddress,
        uint256[] memory tokenID
    ) public poolExists(pool) {
        require(
            owner() == msg.sender || (open && pools[pool].owner == msg.sender),
            "not open to public or you are not the owner of the pool"
        );
        if (isMEME721) {
            uint256 mintID = meme721.create(supply);
            isERC721 = true;
            nftAddress = address(meme721);
            tokenID[0] = mintID;
        } else {
            // transfer NFTs to contract
            if (isERC721) {
                require(tokenID.length == supply, "invalid tokenID length");
                for (uint256 i = 0; i < supply; ++i)
                    IERC721(nftAddress).safeTransferFrom(
                        msg.sender,
                        address(this),
                        tokenID[i]
                    );
            } else {
                require(tokenID.length == 1, "invalid tokenID length");
                IERC1155(nftAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    tokenID[0],
                    supply,
                    ""
                );
            }
        }

        uint256 id = cardIDs[pool].current();

        Card storage c = pools[pool].cards[id];
        c.points = points * 1e18;
        c.releaseTime = releaseTime;
        c.mintFee = mintFee;
        c.isETHFee = isETHFee;
        c.cardNFT.supply = supply;
        c.cardNFT.minted = 0;
        c.cardNFT.isERC721 = isERC721;
        c.cardNFT.isMEME721 = isMEME721;
        c.cardNFT.nftAddress = nftAddress;
        c.cardNFT.tokenID = tokenID;

        cardIDs[pool].increment();
        emit CardAdded(pool, id, points, mintFee, releaseTime);
    }

    function addCard(
        uint256 pool,
        uint256 supply,
        uint256 points,
        uint256 mintFee,
        bool isETHFee,
        uint256 releaseTime,
        bool isERC721,
        address nftAddress,
        uint256[] memory tokenID
    ) public onlyOwner poolExists(pool) {
        uint256 id = cardIDs[pool].current();

        Card storage c = pools[pool].cards[id];
        c.points = points * 1e18;
        c.releaseTime = releaseTime;
        c.mintFee = mintFee;
        c.isETHFee = isETHFee;
        c.cardNFT.supply = supply;
        c.cardNFT.minted = 0;
        c.cardNFT.isERC721 = isERC721;
        c.cardNFT.nftAddress = nftAddress;
        c.cardNFT.tokenID = tokenID;

        cardIDs[pool].increment();
        emit CardAdded(pool, id, points, mintFee, releaseTime);
    }

    function createPool(uint256 periodStart, address artist)
        public
        returns (uint256)
    {
        require(owner() == msg.sender || open, "not open to public");

        uint256 id = poolsID.current();
        Pool storage p = pools[id];
        p.owner = msg.sender;
        p.periodStart = periodStart;
        p.maxStake = 5 * 1e18;
        p.controllerShare = controllerShare;
        p.artist = artist;

        poolsID.increment();
        emit PoolAdded(id, artist, periodStart, p.maxStake);

        return id;
    }

    function withdrawETHFee() public {
        uint256 amount = pendingWithdrawalsETH[msg.sender];
        require(amount > 0, "nothing to withdraw");
        pendingWithdrawalsETH[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function withdrawMEMEFee() public {
        uint256 amount = pendingWithdrawalsMEME[msg.sender];
        require(amount > 0, "nothing to withdraw");
        pendingWithdrawalsMEME[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function rescue721NFT(
        address nftAddress,
        uint256 nftID,
        address toAddress
    ) external onlyOwner {
        IERC721(nftAddress).safeTransferFrom(address(this), toAddress, nftID);
    }

    function rescue1155NFT(
        address nftAddress,
        uint256 nftID,
        uint256 amount,
        address toAddress
    ) external onlyOwner {
        IERC1155(nftAddress).safeTransferFrom(
            address(this),
            toAddress,
            nftID,
            amount,
            ""
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC1155).interfaceId;
    }
}