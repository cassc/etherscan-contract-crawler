/**
 *Submitted for verification at Etherscan.io on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @uniswap\lib\contracts\libraries\TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

pragma solidity ^0.8.0;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

contract Miner is Ownable {
    IERC20 public usdt;
    mapping(uint256 => uint256) public minerPriceOf;
    mapping(address => mapping(uint256 => uint256)) public userMinerOf;
    mapping(uint256 => bool) public minerStoped;
    PriceRule[3] public poolRateOfPrice;
    // Oracle address
    AggregatorInterface public usdOracle;
    uint256 constant TENTHOUSANDTH = 10000;
    uint256 public totalMiners;
    uint256 public buyPool;
    address public manager;
    address public userWithdrawAddr;
    address public trader;

    IUniswapV2Router02 public uniswapV2Router;
    PriceRule[3] public poolRateOfPrice1;
    address public uniswapPair;

    bool priceSwitch;
    struct PriceRule {
        uint256 index;
        uint256 minPrice;
        uint256 maxPrice;
        uint256 buyPoolProp;
    }

    event OracleChanged(address oracle);

    event BuyMiner(
        address indexed addr,
        uint256 indexed amount,
        uint256 indexed miner,
        uint256 num
    );

    event ToPool(uint256 indexed amount);
    event OutPool(uint256 indexed amount);

    event SwapETHForTokens(uint256 indexed amountIn, address[] path);
    event SwapTokensForETH(uint256 indexed amountIn, address[] path);

    constructor(
        IERC20 _usdt,
        AggregatorInterface _usdOracle,
        address _manager,
        address _userWithdrawAddr,
        address _trader
    ) {
        minerPriceOf[1] = 1000 * 1e6;
        usdt = _usdt;
        poolRateOfPrice[0] = PriceRule(1, 0, 2000 * 1e8, 0);
        poolRateOfPrice[1] = PriceRule(2, 2000 * 1e8, 3000 * 1e8, 5000);
        poolRateOfPrice[2] = PriceRule(3, 3000 * 1e8, 0, 10000);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        usdOracle = _usdOracle;
        uniswapV2Router = _uniswapV2Router;
        manager = _manager;
        uniswapPair = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;
        userWithdrawAddr = _userWithdrawAddr;
        trader = _trader;
    }

    function switchPrice(bool _switch) public onlyOwner {
        priceSwitch = _switch;
    }

    function updatePriceRule(
        bool _switch,
        uint256 _index,
        PriceRule memory _rule
    ) public onlyOwner {
        require(_index > 0 && _index <= 3);
        if (_switch) poolRateOfPrice1[_index - 1] = _rule;
        else poolRateOfPrice[_index - 1] = _rule;
    }

    function stop(uint256 _miner) public onlyOwner {
        minerStoped[_miner] = true;
    }

    function start(uint256 _miner) public onlyOwner {
        minerStoped[_miner] = false;
    }

    function updateWithdrawAddr(address _addr) public onlyOwner {
        require(_addr != address(0));
        userWithdrawAddr = _addr;
    }

    function updateManger(address _addr) public onlyOwner {
        require(_addr != address(0));
        manager = _addr;
    }

    function updateTrader(address _addr) public onlyOwner {
        require(_addr != address(0));
        trader = _addr;
    }

    function updateMiner(uint256 _miner, uint256 _amount) public onlyOwner {
        minerPriceOf[_miner] = _amount;
    }

    function updateOraclePrice(address _oracle) public onlyOwner {
        require(_oracle != address(0));
        usdOracle = AggregatorInterface(_oracle);
        emit OracleChanged(_oracle);
    }

    function getPoolProp() public view returns (uint256 _prop) {
        uint256 _price = uint256(usdOracle.latestAnswer());
        PriceRule[3] memory _poolRateOfPrice = poolRateOfPrice;
        if (priceSwitch) {
            _poolRateOfPrice = poolRateOfPrice1;
        }
        for (uint256 i = 0; i < _poolRateOfPrice.length; i++) {
            if (
                _poolRateOfPrice[i].minPrice == 0 &&
                _price <= _poolRateOfPrice[i].maxPrice
            ) {
                _prop = _poolRateOfPrice[i].buyPoolProp;
                break;
            } else if (
                _price > _poolRateOfPrice[i].minPrice &&
                _poolRateOfPrice[i].maxPrice > 0 &&
                _price <= _poolRateOfPrice[i].maxPrice
            ) {
                _prop = _poolRateOfPrice[i].buyPoolProp;
                break;
            } else if (
                _poolRateOfPrice[i].maxPrice == 0 &&
                _price > _poolRateOfPrice[i].minPrice
            ) {
                _prop = _poolRateOfPrice[i].buyPoolProp;
                break;
            }
        }
    }

    function getMiners(address _addr, uint256 _num)
        public
        view
        returns (uint256[] memory _result)
    {
        _result = new uint256[](_num);
        for (uint256 i = 1; i <= _num; i++) {
            _result[i - 1] = userMinerOf[_addr][i];
        }
    }

    function getChainPrice() public view returns (uint256) {
        return uint256(usdOracle.latestAnswer());
    }

    function buyMiner(uint256 _miner, uint256 _num) public {
        uint256 _mprice = minerPriceOf[_miner];
        require(
            _mprice > 0 && _num > 0,
            "The current mining machine is not allowed to buy !!!"
        );
        require(
            !minerStoped[0] && !minerStoped[_miner],
            "Mining machines are no longer available for sale."
        );
        uint256 _amount = _mprice * _num;
        TransferHelper.safeTransferFrom(
            address(usdt),
            msg.sender,
            address(this),
            _amount
        );
        uint256 _prop = getPoolProp();
        uint256 _toPool = 0;
        if (_prop > 0) {
            _toPool = (_amount * _prop) / TENTHOUSANDTH;
        }
        if (_toPool < _amount) {
            _swapTokensForEth(_amount - _toPool);
        }
        if (_toPool > 0) {
            buyPool += _toPool;
            emit ToPool(_toPool);
        }
        totalMiners += _amount;
        userMinerOf[msg.sender][_miner] += _num;
        emit BuyMiner(msg.sender, _amount, _miner, _num);
    }

    function swapTokensForEth(uint256 _amount) public {
        require(_amount > 0);
        require(trader != address(0) && trader == msg.sender, "unauthorized");
        require(buyPool >= _amount, "Insufficient assets available !!!");

        _swapTokensForEth(_amount);
        buyPool -= _amount;
        emit OutPool(_amount);
    }

    function swapEthForTokens(uint256 _amount) public {
        require(_amount > 0);
        require(trader != address(0) && trader == msg.sender, "unauthorized");
        require(
            address(this).balance >= _amount,
            "Insufficient assets available !!!"
        );
        uint256 _u = _swapEthForTokens(_amount);
        buyPool += _u;

        emit ToPool(_u);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = uniswapV2Router.WETH();

        TransferHelper.safeApprove(
            address(usdt),
            address(uniswapV2Router),
            tokenAmount
        );

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        emit SwapTokensForETH(tokenAmount, path);
    }

    function _swapEthForTokens(uint256 tokenAmount)
        private
        returns (uint256 _target)
    {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(usdt);
        uint256[] memory result = uniswapV2Router.swapExactETHForTokens{
            value: tokenAmount
        }(0, path, address(this), block.timestamp);
        _target = result[1];
        emit SwapETHForTokens(tokenAmount, path);
    }

    function userWithdraw(
        address _rec,
        address _token,
        uint256 _amount
    ) public {
        require(
            userWithdrawAddr != address(0) && userWithdrawAddr == msg.sender,
            "unauthorized"
        );
        require(_rec != address(0), "The recipient cannot be 0 address!!!");
        if (_token == address(0)) {
            require(
                address(this).balance >= _amount,
                "Insufficient assets available !!!"
            );
            payable(_rec).transfer(_amount);
        } else {
            uint256 balance = IERC20(_token).balanceOf(address(this));
            require(balance >= _amount, "Insufficient contract assets!!!");
            TransferHelper.safeTransfer(address(_token), _rec, _amount);
        }
    }

    function withdraw(address _token, uint256 _amount) public {
        require(manager != address(0) && manager == msg.sender, "unauthorized");
        if (_token == address(0)) {
            require(
                address(this).balance >= _amount,
                "Insufficient assets available !!!"
            );
            payable(msg.sender).transfer(_amount);
        } else {
            uint256 balance = IERC20(_token).balanceOf(address(this));
            require(balance >= _amount, "Insufficient contract assets!!!");
            TransferHelper.safeTransfer(address(_token), msg.sender, _amount);
        }
    }

    receive() external payable {}
}