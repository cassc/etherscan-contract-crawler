// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./lib/Governable.sol";
import "./lib/interface.sol";


contract SwapAPE is Configurable {
    using SafeMathUpgradeable for uint256;

    mapping(uint256 => uint256) public finished;
    mapping(uint256 => uint256) public totalSwapA;
    mapping(uint256 => uint256) public totalSwapB;
    mapping(address => mapping(uint256 => uint256)) public userTotalSwapA;
    mapping(address => mapping(uint256 => uint256)) public userTotalSwapB;
    mapping(address => mapping(uint256 => bool)) public canceled;
    mapping(uint256 => uint256) public swapTxFee;
    uint256 internal constant PoolTypeSell = 0;
    uint256 internal constant PoolTypeBuy = 1;
    bytes32 internal constant TxFeeRatio            = bytes32("TxFeeRatio");
    bytes32 internal constant MinValueOfBotHolder   = bytes32("MinValueOfBotHolder");

    struct CreateReq {
        // tokenA swap to tokenB
        string name;
        IERC20 tokenA;
        IERC20 tokenB;
        uint256 totalAmountA;
        uint256 totalAmountB;
        uint256 poolType;
    }

    struct Pool {
        string name;
        address creator;
        IERC20 tokenA;
        IERC20 tokenB;
        uint256 totalAmountA;
        uint256 totalAmountB;
        uint256 poolType;
    }

    Pool[] public pools;
    event Created(uint indexed index, address indexed sender, Pool pool);
    event Cancel(uint256 indexed index, address indexed sender, uint256 amountA, uint256 txFee);
    event Swapped(uint256 indexed index, address indexed sender, uint256 amountA, uint256 amountB, uint256 txFee);


    function initialize(uint256 txFeeRatio, uint256 minBotHolder) public initializer {
        super.__Ownable_init();
        config[TxFeeRatio] = txFeeRatio;
        config[MinValueOfBotHolder] = minBotHolder;
    }

    function create(CreateReq memory req) external payable {
        // create pool, transfer tokenA to pool
        uint256 index = pools.length;
        require(tx.origin == msg.sender, "invalid caller");
        require(req.totalAmountA != 0 && req.totalAmountB != 0, "invalid total amount");
        require(req.poolType == PoolTypeSell || req.poolType == PoolTypeBuy, "invalid poolType");
        require(bytes(req.name).length <= 15, "length of name is too long");
        // require(req.tokenA != address(0) && req.tokenB != address(0), "invalid token address");
        uint tokenABalanceBefore = req.tokenA.balanceOf(address(this));
        req.tokenA.transferFrom(msg.sender, address(this), req.totalAmountA);
        require(req.tokenA.balanceOf(address(this)).sub(tokenABalanceBefore) == req.totalAmountA,"not support deflationary token");
        Pool memory pool;
        pool.name = req.name;
        pool.creator = msg.sender;
        pool.tokenA = req.tokenA;
        pool.tokenB = req.tokenB;
        pool.totalAmountA = req.totalAmountA;
        pool.totalAmountB = req.totalAmountB;
        pool.poolType = req.poolType;
        pools.push(pool);
        emit Created(index, msg.sender, pool);
    }

    function swap(uint index, uint amountB) external isPoolExist(index) {
        address sender = msg.sender;
        Pool memory pool = pools[index];
        require(tx.origin == msg.sender, "invalid caller");
        require(!canceled[msg.sender][index], "Swap: pool has been cancel");
        require(pool.totalAmountB > totalSwapB[index], "Swap: amount is zero");

        uint256 spillAmountB = 0;
        uint256 _amountB = pool.totalAmountB.sub(totalSwapB[index]);
        if (_amountB > amountB) {
            _amountB = amountB;
        } else {
            spillAmountB = amountB.sub(_amountB);
        }

        uint256 amountA = _amountB.mul(pool.totalAmountA).div(pool.totalAmountB);
        uint256 _amountA = pool.totalAmountA.sub(totalSwapA[index]);
        if (_amountA > amountA) {
            _amountA = amountA;
        }

        totalSwapA[index] = totalSwapA[index].add(_amountA);
        totalSwapB[index] = totalSwapB[index].add(_amountB);
        userTotalSwapA[sender][index] = userTotalSwapA[sender][index].add(_amountA);
        userTotalSwapB[sender][index] = userTotalSwapB[sender][index].add(_amountB);

        if (pool.totalAmountB == totalSwapB[index]) {
            finished[index] = block.timestamp;
        }

        if (spillAmountB > 0) {
            pool.tokenB.transfer(msg.sender, spillAmountB);
        }

        pool.tokenB.transferFrom(msg.sender, address(this), amountB);
        pool.tokenA.transfer(msg.sender, _amountA);

        uint256 fee = _amountB.mul(getTxFeeRatio()).div(10000);
        swapTxFee[index] = swapTxFee[index].add(fee);
        uint256 _realAmountB = _amountB.sub(fee);
        if (_realAmountB > 0) {
            pool.tokenB.transfer(pool.creator, _realAmountB);
        }
        emit Swapped(index, msg.sender, _amountA, _realAmountB, fee);
    }

    function cancel(uint256 index) external {
        require(index < pools.length, "this pool does not exist");
        Pool memory pool = pools[index];
        require(msg.sender == pool.creator, "Cancel: not creator");
        require(!canceled[msg.sender][index], "Cancel: canceled");
        canceled[msg.sender][index] = true;

        uint256 unSwapAmount = pool.totalAmountA.sub(totalSwapA[index]);
        if (unSwapAmount > 0) {
            pool.tokenA.transfer(pool.creator, unSwapAmount);
        }

        emit Cancel(index, msg.sender, unSwapAmount, 0);
    }

    function getTxFeeRatio() public view returns (uint) {
        return config[TxFeeRatio];
    }

    function getPoolCount() public view returns (uint) {
        return pools.length;
    }

    function setTxFeeRatio(uint256 _txFeeRatio) external onlyOwner {
        config[TxFeeRatio] = _txFeeRatio;
    }

    modifier isPoolExist(uint index) {
        require(index < pools.length, "this pool does not exist");
        _;
    }
}