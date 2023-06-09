// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/TransferHelper.sol";
import "./modules/Configurable.sol";

contract NFTFixedswap is Initializable, Ownable, Configurable, IERC721Receiver {
    using SafeMath for uint;
    using Address for address;

    bytes32 internal constant TxFeeRatio            = bytes32("FPNFT::TxFeeRatio");
    bytes32 internal constant MinValueOfBotHolder   = bytes32("FPNFT::MinValueOfBotHolder");
    bytes32 internal constant BotToken              = bytes32("FPNFT::BotToken");
    bytes32 internal constant DisableErc721         = bytes32("FPNFT::DisableErc721");
    bytes32 internal constant DisableErc1155        = bytes32("FPNFT::DisableErc1155");
    uint    internal constant TypeErc721            = 0;
    uint    internal constant TypeErc1155           = 1;

    struct Pool {
        // address of pool creator
        address creator;
        // address of sell token
        address token0;
        // address of buy token
        address token1;
        // token id of token0
        uint tokenId;
        // total amount of token0
        uint amountTotal0;
        // total amount of token1
        uint amountTotal1;
        // NFT token type
        uint nftType;
        // open at
        uint openAt;
        // pool name
        string name;
    }

    Pool[] public pools;

    // creator address => pool index => whether the account create the pool.
    mapping(address => mapping(uint => bool)) public myCreatedP;

    // pool index => the swap pool only allow BOT holder to take part in
    mapping(uint => bool) public onlyBotHolderP;

    // pool index => a flag that if creator is canceled the pool
    mapping(uint => bool) public creatorCanceledP;
    // pool index => a flag that if the pool is finished
    mapping(uint => bool) public swappedP;

    // check if token0 in whitelist
    bool public checkToken0;
    // token0 address => true or false
    mapping(address => bool) public token0List;

    // pool index => swapped amount of token0
    mapping(uint => uint) public swappedAmount0P;
    // pool index => swapped amount of token1
    mapping(uint => uint) public swappedAmount1P;

    uint public totalTxFee;

    event Created(address indexed sender, uint indexed index);
    event Canceled(address indexed sender, uint indexed index, uint unswappedAmount0);
    event Swapped(address indexed sender, uint indexed index, uint swappedAmount0, uint swappedAmount1);

    modifier checkBotHolder(uint index) {
        if (onlyBotHolderP[index]) {
            require(
            getMinValueOfBotHolder() > 0 && IERC20(getBotToken()).balanceOf(msg.sender) >= getMinValueOfBotHolder(),
                "BOT is not enough"
            );
        }
        _;
    }

    modifier isPoolNotSwap(uint index) {
        require(!swappedP[index], "this pool is swapped");
        _;
    }

    modifier isPoolExist(uint index) {
        require(index < pools.length, "this pool does not exist");
        _;
    }

    function initialize(address botToken) public initializer {
        config[MinValueOfBotHolder] = 1 ether;
        config[BotToken] = uint(uint160(botToken)); 
    }

    function createErc721(
        string memory name,
        address token0,
        address token1,
        uint tokenId,
        uint amountTotal1,
        uint openAt,
        bool onlyBot
    ) external {
        require(!getDisableErc721(), "ERC721 pool is disabled");
        if (checkToken0) {
            require(token0List[token0], "invalid token0");
        }
        uint amountTotal0 = 1;
        _create(
           name, token0, token1, tokenId, amountTotal0, amountTotal1, openAt, onlyBot, TypeErc721
        );
    }

    function createErc1155(
        string memory name,
        address token0,
        address token1,
        uint tokenId,
        uint amountTotal0,
        uint amountTotal1,
        uint openAt,
        bool onlyBot
    ) external {
        require(!getDisableErc1155(), "ERC1155 pool is disabled");
        if (checkToken0) {
            require(token0List[token0], "invalid token0");
        }
        _create(
           name, token0, token1, tokenId, amountTotal0, amountTotal1, openAt, onlyBot, TypeErc1155
        );
    }

    function swap(uint index, uint amount0) external payable isPoolExist(index) checkBotHolder(index) isPoolNotSwap(index) {
        require(!creatorCanceledP[index], "creator has canceled this pool");

        Pool storage pool = pools[index];
        require(pool.creator != msg.sender, "creator can't swap the pool created by self");
        require(amount0 >= 1 && amount0 <= pool.amountTotal0, "invalid amount0");
        require(swappedAmount0P[index].add(amount0) <= pool.amountTotal0, "pool filled or invalid amount0");
        require(pool.openAt <= block.timestamp, "pool is not open");

        uint amount1 = amount0.mul(pool.amountTotal1).div(pool.amountTotal0);
        swappedAmount0P[index] = swappedAmount0P[index].add(amount0);
        swappedAmount1P[index] = swappedAmount1P[index].add(amount1);
        if (swappedAmount0P[index] == pool.amountTotal0) {
            // mark pool is swapped
            swappedP[index] = true;
        }

        // transfer amount of token1 to creator
        if (pool.token1 == address(0)) {
            require(amount1 == msg.value, "invalid ETH amount");
            TransferHelper.safeTransferETH(pool.creator, amount1);
        } else {
            TransferHelper.safeTransferFrom(pool.token1, msg.sender, pool.creator, amount1);
        }

        // transfer tokenId of token0 to sender
        if (pool.nftType == TypeErc721) {
            IERC721(pool.token0).safeTransferFrom(address(this), msg.sender, pool.tokenId);
        } else {
            IERC1155(pool.token0).safeTransferFrom(address(this), msg.sender, pool.tokenId, amount0, "");
        }

        emit Swapped(msg.sender, index, amount0, amount1);
    }

    function cancel(uint index) external isPoolExist(index) isPoolNotSwap(index) {
        require(isCreator(msg.sender, index), "sender is not pool creator");
        require(!creatorCanceledP[index], "creator has canceled this pool");
        creatorCanceledP[index] = true;

        Pool memory pool = pools[index];
        if (pool.nftType == TypeErc721) {
            IERC721(pool.token0).safeTransferFrom(address(this), pool.creator, pool.tokenId);
        } else {
            IERC1155(pool.token0).safeTransferFrom(address(this), pool.creator, pool.tokenId, pool.amountTotal0.sub(swappedAmount0P[index]), "");
        }

        emit Canceled(msg.sender, index, pool.amountTotal0.sub(swappedAmount0P[index]));
    }

    function enableCheckToken0(bool enable) external onlyOwner {
        checkToken0 = enable;
    }

    function addToken0List(address[] memory token0List_) external onlyOwner {
        for (uint i = 0; i < token0List_.length; i++) {
            token0List[token0List_[i]] = true;
        }
    }

    function removeToken0List(address[] memory token0List_) external onlyOwner {
        for (uint i = 0; i < token0List_.length; i++) {
            delete token0List[token0List_[i]];
        }
    }

    function setConfig(bytes32 key, uint value) external onlyOwner {
        _setConfig(key, value);
    }
    
    function setConfig(bytes32 key, uint index, uint value) external onlyOwner {
        _setConfig(bytes32(uint(key) ^ index), value);
    }

    function setConfig(bytes32 key, address addr, uint value) external onlyOwner {
        _setConfig(bytes32(uint(key) ^ uint(uint160(addr))), value);
    }

    function withdrawFee(address payable to, uint amount) external onlyOwner {
        totalTxFee = totalTxFee.sub(amount);
        TransferHelper.safeTransferETH(to, amount);
    }

    function isCreator(address target, uint index) public view returns (bool) {
        if (pools[index].creator == target) {
            return true;
        }
        return false;
    }

    function getMinValueOfBotHolder() public view returns (uint) {
        return config[MinValueOfBotHolder];
    }

    function getBotToken() public view returns (address) {
        return address(uint160(config[BotToken]));
    }

    function getDisableErc721() public view returns (bool) {
        return config[DisableErc721] != 0;
    }

    function getDisableErc1155() public view returns (bool) {
        return config[DisableErc1155] != 0;
    }

    function getPoolCount() external view returns (uint) {
        return pools.length;
    }

    function onERC721Received(address, address, uint, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint, uint, bytes calldata) external pure returns(bytes4) {
        return this.onERC1155Received.selector;
    }

    function _create(
        string memory name,
        address token0,
        address token1,
        uint tokenId,
        uint amountTotal0,
        uint amountTotal1,
        uint openAt,
        bool onlyBot,
        uint nftType
    ) private {
        // require(tx.origin == msg.sender, "disallow contract caller");
        require(amountTotal1 != 0, "the value of amountTotal1 is zero.");
        require(bytes(name).length <= 32, "the length of name is too long");

        // transfer tokenId of token0 to this contract
        if (nftType == TypeErc721) {
            require(amountTotal0 == 1, "invalid amountTotal0");
            IERC721(token0).safeTransferFrom(msg.sender, address(this), tokenId);
        } else {
            require(amountTotal0 != 0, "invalid amountTotal0");
            IERC1155(token0).safeTransferFrom(msg.sender, address(this), tokenId, amountTotal0, "");
        }

        // creator pool
        Pool memory pool;
        pool.creator = msg.sender;
        pool.name = name;
        pool.token0 = token0;
        pool.token1 = token1;
        pool.tokenId = tokenId;
        pool.amountTotal0 = amountTotal0;
        pool.amountTotal1 = amountTotal1;
        pool.nftType = nftType;
        pool.openAt = openAt;

        uint index = pools.length;
        myCreatedP[msg.sender][index] = true;
        if (onlyBot) {
            onlyBotHolderP[index] = onlyBot;
        }

        pools.push(pool);

        emit Created(msg.sender, index);
    }

}