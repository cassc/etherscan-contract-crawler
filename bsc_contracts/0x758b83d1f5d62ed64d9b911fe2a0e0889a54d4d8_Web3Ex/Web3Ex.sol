/**
 *Submitted for verification at BscScan.com on 2023-03-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function setDefault(Counter storage counter) internal {
        counter._value = 100000;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Web3Ex {
    using Counters for Counters.Counter;    // 引入自增变量工具
    using SafeMath for uint;                // 引入安全计算工具
    using SafeMath for uint256;             // 引入安全计算工具
    address public owner;                   // 发布者

    Counters.Counter private _tradeId_;     // 自增变量-交易id 

    address public ReceiveAddress; // 接收地址/出币地址
    address public USDTContractAddress = 0x55d398326f99059fF775485246999027B3197955; // USDT合约地址
    address public WEB3ContractAddress = 0xB385cF66FD3AEFd70605E297A79825471E89d32F; // WEB3合约地址

    uint public ExRate = 10000000; // 汇率 1web3 = 0.8usdt （800000000 / 1000000000） （0.8 * 10亿 / 1 * 10亿）

    bool public isOpen = true;
    

    constructor() {
        owner = msg.sender;
        ReceiveAddress = msg.sender;
    }

    // 权限检测
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // 开启状态控制
    modifier onlyIsOpen {
        require(isOpen == true, "Error: transaction closed");
        _;
    }

    // 交易明细的结构体
    struct tradeDetail {
        uint tradeId;            // 交易id
        uint createTime;         // 交易时间
        uint amount;             // 交易数量
        address wallet;      // 交易地址
        string exchange;       // 交易方式
    }

    // 记录交易明细列表
    mapping(uint => tradeDetail) tradeMapping;

    // 打印交易
    event TradeLog(uint indexed tradeId, address wallet, uint amount, string exchange, uint createTime);

    // 设置USDT合约地址
    function setUsdtContract(address _address) public onlyOwner {
        USDTContractAddress = _address;
    }

    // 设置WEB3合约地址
    function setWeb3Contract(address _address) public onlyOwner {
        WEB3ContractAddress = _address; 
    }

    // 设置接收/出币地址
    function setReceiveAddress(address _address) public onlyOwner {
        ReceiveAddress = _address;
    }

    // 设置汇率
    function setExRate(uint _rate) public onlyOwner {
        ExRate = _rate;
    }

    // 修改开启/关闭状态
    function changeIsOpen(bool _flag) public onlyOwner{
        isOpen = _flag;
    }

    // 兑换USDT
    // 兑换100个usdt 需要 125个web3
    // 数量
    function toUsdtByAmount(uint amount) public payable onlyIsOpen {
        // 实际需要的web3的数量
        uint actualAmount = amount.mul(1000000000).div(ExRate);
        // 划转WEB3
        IERC20(WEB3ContractAddress).transferFrom(msg.sender, ReceiveAddress, actualAmount);
        // 划转USDT
        IERC20(USDTContractAddress).transferFrom(ReceiveAddress, msg.sender, amount);
        // 交易id自增
        _tradeId_.increment();
        // 记录交易
        tradeDetail memory trade = tradeMapping[_tradeId_.current()];
        trade.tradeId = _tradeId_.current();                            // 自增Id
        trade.createTime = block.timestamp;                             // 交易时间
        trade.amount = amount;                                          // 交易数量          
        trade.wallet = msg.sender;                                      // 交易地址
        trade.exchange = "tuba";                                      // 交易方式
        tradeMapping[_tradeId_.current()] = trade;
        // 打印交易
        emit TradeLog(_tradeId_.current(), msg.sender, amount, "tuba", block.timestamp);
    }

    // 兑换USDT
    // 给100个web3 可以兑换 80usdt
    // 成交额
    function toUsdtByQuota(uint amount) public payable onlyIsOpen {
        // 实际兑换的usdt的数量
        uint actualAmount = amount.mul(ExRate).div(1000000000);
        // 划转WEB3
        IERC20(WEB3ContractAddress).transferFrom(msg.sender, ReceiveAddress, amount);
        // 划转USDT
        IERC20(USDTContractAddress).transferFrom(ReceiveAddress, msg.sender, actualAmount);
        // 交易id自增
        _tradeId_.increment();
        // 记录交易
        tradeDetail memory trade = tradeMapping[_tradeId_.current()];
        trade.tradeId = _tradeId_.current();                            // 自增Id
        trade.createTime = block.timestamp;                             // 交易时间
        trade.amount = amount;                                          // 交易数量          
        trade.wallet = msg.sender;                                      // 交易地址
        trade.exchange = "tubq";                                      // 交易方式
        tradeMapping[_tradeId_.current()] = trade;
        // 打印交易
        emit TradeLog(_tradeId_.current(), msg.sender, amount, "tubq", block.timestamp);
    }

    // 兑换WEB3
    // 兑换100个web3 需要 80个usdt
    // 数量
    function toWeb3ByAmount(uint amount) public payable onlyIsOpen {
        // 实际需要usdt的数量
        uint actualAmount = amount.mul(ExRate).div(1000000000);
        // 划转USDT
        IERC20(USDTContractAddress).transferFrom(msg.sender, ReceiveAddress, actualAmount);
        // 划转WEB3
        IERC20(WEB3ContractAddress).transferFrom(ReceiveAddress, msg.sender, amount);
        // 交易id自增
        _tradeId_.increment();
        // 记录交易
        tradeDetail memory trade = tradeMapping[_tradeId_.current()];
        trade.tradeId = _tradeId_.current();                            // 自增Id
        trade.createTime = block.timestamp;                             // 交易时间
        trade.amount = amount;                                          // 交易数量          
        trade.wallet = msg.sender;                                      // 交易地址
        trade.exchange = "twba";                                      // 交易方式
        tradeMapping[_tradeId_.current()] = trade;
        // 打印交易
        emit TradeLog(_tradeId_.current(), msg.sender, amount, "twba", block.timestamp);
    }

    
    // 兑换WEB3
    // 给100个usdt 可以兑换 125个web3
    // 数量
    function toWeb3ByQuota(uint amount) public payable onlyIsOpen {
        // 实际可兑换web3的数量
        uint actualAmount = amount.mul(1000000000).div(ExRate);
        // 划转USDT
        IERC20(USDTContractAddress).transferFrom(msg.sender, ReceiveAddress, amount);
        // 划转WEB3
        IERC20(WEB3ContractAddress).transferFrom(ReceiveAddress, msg.sender, actualAmount);
        // 交易id自增
        _tradeId_.increment();
        // 记录交易
        tradeDetail memory trade = tradeMapping[_tradeId_.current()];
        trade.tradeId = _tradeId_.current();                            // 自增Id
        trade.createTime = block.timestamp;                             // 交易时间
        trade.amount = amount;                                          // 交易数量          
        trade.wallet = msg.sender;                                      // 交易地址
        trade.exchange = "twbq";                                        // 交易方式
        tradeMapping[_tradeId_.current()] = trade;
        // 打印交易
        emit TradeLog(_tradeId_.current(), msg.sender, amount, "twbq", block.timestamp);
    }

    // 根据钱包地址查询交易
    function getTradeListByWallet(address wallet) public view returns(tradeDetail[] memory) {
        uint tradeTotal = _tradeId_.current();
        tradeDetail[] memory list = new tradeDetail[](tradeTotal);
        for (uint i = 0; i < tradeTotal; i++) {
            if (tradeMapping[i+1].wallet == wallet) {
                list[i] = tradeMapping[i+1];
            }
        }
        return list;
    }

    // 查询所有交易
    function getTradeListAll() public view returns(tradeDetail[] memory) {
        uint tradeTotal = _tradeId_.current();
        tradeDetail[] memory list = new tradeDetail[](tradeTotal);
        for (uint i = 0; i < tradeTotal; i++) {
            list[i] = tradeMapping[i+1];
        }
        return list;
    }
}