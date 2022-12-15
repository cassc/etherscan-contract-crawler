// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Receiver.sol";
import "./Governable.sol";
import "./interfaces/IERC1155.sol";
import "./interfaces/IRoyaltyConfig.sol";

contract BounceFixedEndEnglishAuctionNFT is Configurable, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    bytes32 internal constant FeeConfigContract =       bytes32("EANFT::FeeConfigContract");
    bytes32 internal constant TxFeeRatio =              bytes32("EANFT::TxFeeRatio");
    bytes32 internal constant MinValueOfBotHolder =     bytes32("EANFT::MinValueOfBotHolder");
    bytes32 internal constant BotToken =                bytes32("EANFT::BotToken");
    bytes32 internal constant DisableErc721 =           bytes32("EANFT::DisableErc721");
    bytes32 internal constant DisableErc1155 =          bytes32("EANFT::DisableErc1155");
    uint    internal constant TypeErc721                = 0;
    uint    internal constant TypeErc1155               = 1;

    struct Pool {
        // address of pool creator
        address payable creator;
        // pool name
        string name;
        // address of sell token
        address token0;
        // address of buy token
        address token1;
        // token id of token0
        uint tokenId;
        // amount of token id of token0
        uint tokenAmount0;
        // maximum amount of token1 that creator want to swap
        uint amountMax1;
        // minimum amount of token1 that creator want to swap
        uint amountMin1;
        // minimum incremental amount of token1
        uint amountMinIncr1;
        // the duration in seconds the pool will be closed
        uint duration;
        // the timestamp in seconds the pool will be closed
        uint closeAt;
        // NFT token type
        uint nftType;
    }

    Pool[] public pools;

    // pool index => a flag that if creator is claimed the pool
    mapping(uint => bool) public creatorClaimedP;
    // pool index => the swap pool only allow BOT holder to take part in
    mapping(uint => bool) public onlyBotHolderP;
    // pool index => the candidate of winner who bid the highest amount1 in current round
    mapping(uint => address payable) public currentBidderP;
    // pool index => the highest amount1 in current round
    mapping(uint => uint) public currentBidderAmount1P;
    // pool index => reserve amount of token1
    mapping(uint => uint) public reserveAmount1P;

    // creator address => pool index => whether the account create the pool.
    mapping(address => mapping(uint => bool)) public myCreatedP;
    // account => pool index => bid amount1
    mapping(address => mapping(uint => uint)) public myBidderAmount1P;
    // account => pool index => claim flag
    mapping(address => mapping(uint => bool)) public myClaimedP;

    // pool index => bid count
    mapping(uint => uint) public bidCountP;

    uint unlocked;
    uint public totalTxFee;

    event Created(address indexed sender, uint indexed index, Pool pool);
    event Bid(address indexed sender, uint indexed index, uint amount1);
    event CreatorClaimed(address indexed sender, uint indexed index, uint tokenId, uint amount0, uint amount1);
    event BidderClaimed(address indexed sender, uint indexed index, uint tokenId, uint amount0, uint amount1);

    function initial(address _governor, address feeConfigContract, address botToken) public initializer {
        super.initialize(_governor);

        unlocked = 1;
        config[TxFeeRatio] = 0.01 ether;
        config[MinValueOfBotHolder] = 1 ether;

        config[FeeConfigContract] = uint(feeConfigContract);
        config[BotToken] = uint(botToken); // AUCTION
    }

    function createErc721(
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // maximum amount of token1
        uint amountMax1,
        // minimum amount of token1
        uint amountMin1,
        // minimum incremental amount of token1
        uint amountMinIncr1,
        // reserve amount of token1
        uint amountReserve1,
        // duration
        uint duration,
        // only bot holder can bid the pool
        bool onlyBot
    ) public {
        require(!getDisableErc721(), "ERC721 pool is disabled");
        uint tokenAmount0 = 1;
        _create(name, token0, token1, tokenId, tokenAmount0, amountMax1, amountMin1, amountMinIncr1, amountReserve1, duration, onlyBot, TypeErc721);
    }

    function createErc1155(
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // amount of token id of token0
        uint tokenAmount0,
        // maximum amount of token1
        uint amountMax1,
        // minimum amount of token1
        uint amountMin1,
        // minimum incremental amount of token1
        uint amountMinIncr1,
        // reserve amount of token1
        uint amountReserve1,
        // duration
        uint duration,
        // only bot holder can bid the pool
        bool onlyBot
    ) public {
        require(!getDisableErc1155(), "ERC1155 pool is disabled");
        _create(name, token0, token1, tokenId, tokenAmount0, amountMax1, amountMin1, amountMinIncr1, amountReserve1, duration, onlyBot, TypeErc1155);
    }

    function _create(
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // amount of token id of token0
        uint tokenAmount0,
        // maximum amount of token1
        uint amountMax1,
        // minimum amount of token1
        uint amountMin1,
        // minimum incremental amount of token1
        uint amountMinIncr1,
        // reserve amount of token1
        uint amountReserve1,
        // duration
        uint duration,
        // only bot holder can bid the pool
        bool onlyBot,
        // NFT token type
        uint nftType
    ) private {
        address payable creator = msg.sender;

//        require(tx.origin == msg.sender, "disallow contract caller");
        require(tokenAmount0 != 0, "invalid tokenAmount0");
        require(amountReserve1 == 0 || amountReserve1 >= amountMin1, "invalid amountReserve1");
        require(amountMax1 == 0 || (amountMax1 >= amountReserve1 && amountMax1 >= amountMin1), "invalid amountMax1");
        require(amountMinIncr1 != 0, "invalid amountMinIncr1");
        require(duration != 0, "invalid duration");
        require(bytes(name).length <= 32, "the length of name is too long");

        // transfer tokenId of token0 to this contract
        if (nftType == TypeErc721) {
            IERC721(token0).safeTransferFrom(creator, address(this), tokenId);
        } else {
            IERC1155(token0).safeTransferFrom(creator, address(this), tokenId, tokenAmount0, "");
        }

        // creator pool
        Pool memory pool;
        pool.creator = creator;
        pool.name = name;
        pool.token0 = token0;
        pool.token1 = token1;
        pool.tokenId = tokenId;
        pool.tokenAmount0 = tokenAmount0;
        pool.amountMax1 = amountMax1;
        pool.amountMin1 = amountMin1;
        pool.amountMinIncr1 = amountMinIncr1;
        pool.duration = duration;
        pool.closeAt = now.add(duration);
        pool.nftType = nftType;

        uint index = pools.length;
        reserveAmount1P[index] = amountReserve1;
        myCreatedP[msg.sender][index] = true;
        if (onlyBot) {
            onlyBotHolderP[index] = onlyBot;
        }

        pools.push(pool);

        emit Created(msg.sender, index, pool);
    }

    function bid(
        // pool index
        uint index,
        // amount of token1
        uint amount1
    ) external payable
        lock
        isPoolExist(index)
        checkBotHolder(index)
        isPoolNotClosed(index)
    {
        address payable sender = msg.sender;

        Pool storage pool = pools[index];
//        require(tx.origin == msg.sender, "disallow contract caller");
        require(pool.creator != sender, "creator can't bid the pool created by self");
        require(amount1 != 0, "invalid amount1");
        require(amount1 >= pool.amountMin1, "the bid amount is lower than minimum bidder amount");
        require(amount1 >= currentBidderAmount(index), "the bid amount is lower than the current bidder amount");

        if (pool.token1 == address(0)) {
            require(amount1 == msg.value, "invalid ETH amount");
        } else {
            IERC20(pool.token1).safeTransferFrom(sender, address(this), amount1);
        }

        // return ETH to previous bidder
        if (currentBidderP[index] != address(0) && currentBidderAmount1P[index] > 0) {
            if (pool.token1 == address(0)) {
                currentBidderP[index].transfer(currentBidderAmount1P[index]);
            } else {
                IERC20(pool.token1).safeTransfer(currentBidderP[index], currentBidderAmount1P[index]);
            }
        }

        // record new winner
        currentBidderP[index] = sender;
        currentBidderAmount1P[index] = amount1;
        bidCountP[index] = bidCountP[index] + 1;
        myBidderAmount1P[sender][index] = amount1;

        emit Bid(sender, index, amount1);

        if (pool.amountMax1 > 0 && pool.amountMax1 <= amount1) {
            _creatorClaim(index);
            _bidderClaim(sender, index);
        }
    }

    function creatorClaim(uint index) external
        isPoolExist(index)
        isPoolClosed(index)
    {
        require(isCreator(msg.sender, index), "sender is not pool's creator");
        _creatorClaim(index);
    }

    function _creatorClaim(uint index) private {
        require(!creatorClaimedP[index], "creator has claimed");
        creatorClaimedP[index] = true;

        Pool memory pool = pools[index];
        uint amount1 = currentBidderAmount1P[index];
        if (currentBidderP[index] != address(0) && amount1 >= reserveAmount1P[index]) {
            (uint platformFee, uint royaltyFee, uint _actualAmount1) = IRoyaltyConfig(getFeeConfigContract())
                .getFeeAndRemaining(pools[index].token0, amount1);
            uint totalFee = platformFee.add(royaltyFee);
            if (pool.token1 == address(0)) {
                // transfer ETH to creator
                if (_actualAmount1 > 0) {
                    pool.creator.transfer(_actualAmount1);
                }
                IRoyaltyConfig(getFeeConfigContract())
                    .chargeFeeETH{value: totalFee}(pools[index].token0, platformFee, royaltyFee);
            } else {
                IERC20(pool.token1).safeTransfer(pool.creator, _actualAmount1);
                IERC20(pool.token1).safeApprove(getFeeConfigContract(), totalFee);
                IRoyaltyConfig(getFeeConfigContract())
                    .chargeFeeToken(pools[index].token0, pools[index].token1, address(this), platformFee, royaltyFee);
            }
            emit CreatorClaimed(pool.creator, index, pool.tokenId, 0, amount1);
        } else {
            // transfer token0 back to creator
            if (pool.nftType == TypeErc721) {
                IERC721(pool.token0).safeTransferFrom(address(this), pool.creator, pool.tokenId);
                emit CreatorClaimed(pool.creator, index, pool.tokenId, 1, 0);
            } else {
                IERC1155(pool.token0).safeTransferFrom(address(this), pool.creator, pool.tokenId, pool.tokenAmount0, "");
                emit CreatorClaimed(pool.creator, index, pool.tokenId, pool.tokenAmount0, 0);
            }
        }
    }

    function bidderClaim(uint index) external
        isPoolExist(index)
        isPoolClosed(index)
    {
        _bidderClaim(msg.sender, index);
    }

    function withdrawFee(address payable to, uint amount) external governance {
        totalTxFee = totalTxFee.sub(amount);
        to.transfer(amount);
    }

    function setFeeConfigContract(address feeConfigContract) external governance {
        config[FeeConfigContract] = uint(feeConfigContract);
    }

    function transferGovernor(address _governor) external {
        require(msg.sender == governor || governor == address(0), "invalid governor");
        governor = _governor;
    }

    function _bidderClaim(address payable sender, uint index) private {
        require(currentBidderP[index] == sender, "sender is not winner");
        require(!myClaimedP[sender][index], "sender has claimed");
        myClaimedP[sender][index] = true;

        uint amount1 = currentBidderAmount1P[index];
        Pool memory pool = pools[index];
        if (amount1 >= reserveAmount1P[index]) {
            // transfer token0 to bidder
            if (pool.nftType == TypeErc721) {
                IERC721(pool.token0).safeTransferFrom(address(this), sender, pool.tokenId);
                emit BidderClaimed(sender, index, pool.tokenId, 1, 0);
            } else {
                IERC1155(pool.token0).safeTransferFrom(address(this), sender, pool.tokenId, pool.tokenAmount0, "");
                emit BidderClaimed(sender, index, pool.tokenId, pool.tokenAmount0, 0);
            }
        } else {
            // transfer token1 back to bidder
            if (pool.token1 == address(0)) {
                sender.transfer(amount1);
            } else {
                IERC20(pool.token1).safeTransfer(sender, amount1);
            }
            emit BidderClaimed(sender, index, pool.tokenId, 0, amount1);
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return this.onERC1155Received.selector;
    }

    function getPoolCount() external view returns (uint) {
        return pools.length;
    }

    function currentBidderAmount(uint index) public view returns (uint) {
        Pool memory pool = pools[index];
        uint amount = pool.amountMin1;

        if (currentBidderP[index] != address(0)) {
            amount = currentBidderAmount1P[index].add(pool.amountMinIncr1);
        } else if (pool.amountMin1 == 0) {
            amount = pool.amountMinIncr1;
        }

        return amount;
    }

    function isCreator(address target, uint index) private view returns (bool) {
        if (pools[index].creator == target) {
            return true;
        }
        return false;
    }

    function getTxFeeRatio() public view returns (uint) {
        return config[TxFeeRatio];
    }

    function getMinValueOfBotHolder() public view returns (uint) {
        return config[MinValueOfBotHolder];
    }

    function getDisableErc721() public view returns (bool) {
        return config[DisableErc721] != 0;
    }

    function getDisableErc1155() public view returns (bool) {
        return config[DisableErc1155] != 0;
    }

    function getBotToken() public view returns (address) {
        return address(config[BotToken]);
    }

    function getFeeConfigContract() public view returns (address) {
        return address(config[FeeConfigContract]);
    }

    modifier checkBotHolder(uint index) {
        if (onlyBotHolderP[index]) {
            require(
                getMinValueOfBotHolder() > 0 && IERC20(getBotToken()).balanceOf(msg.sender) >= getMinValueOfBotHolder(),
                "BOT is not enough"
            );
        }
        _;
    }

    modifier isPoolClosed(uint index) {
        require(pools[index].closeAt <= now || creatorClaimedP[index], "this pool is not closed");
        _;
    }

    modifier isPoolNotClosed(uint index) {
        require(pools[index].closeAt > now && !creatorClaimedP[index], "this pool is closed");
        _;
    }

    modifier isPoolExist(uint index) {
        require(index < pools.length, "this pool does not exist");
        _;
    }

    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
}