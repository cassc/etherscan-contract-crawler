/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router02 {
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
}

contract Presale is Ownable {
    using SafeMath for uint256;

    bool public isInit;
    bool public isDeposit;
    bool public isRefund;
    bool public isFinish;
    bool public burnTokens = true;
    address public creatorWallet;
    address public teamWallet;
    address public weth;
    uint8 public tokenDecimals = 18;
    uint256 public ethRaised;
    uint256 public percentageRaised;
    uint256 public tokensSold;

    struct Pool {
        uint64 startTime;
        uint64 endTime;
        uint256 tokenDeposit;
        uint256 tokensForSale;
        uint256 tokensForLiquidity;
        uint8 liquidityPortion;
        uint256 hardCap;
        uint256 softCap;
        uint256 maxBuy;
        uint256 minBuy;
    }

    IERC20 public tokenInstance;
    IUniswapV2Factory public UniswapV2Factory;
    IUniswapV2Router02 public UniswapV2Router02;
    Pool public pool;

    mapping(address => uint256) public ethContribution;

    modifier onlyActive() {
        require(block.timestamp >= pool.startTime, "Sale must be active.");
        require(block.timestamp <= pool.endTime, "Sale must be active.");
        _;
    }

    modifier onlyInactive() {
        require(
            block.timestamp < pool.startTime ||
                block.timestamp > pool.endTime ||
                ethRaised >= pool.hardCap,
            "Sale must be inactive."
        );
        _;
    }

    modifier onlyRefund() {
        require(
            isRefund == true ||
                (block.timestamp > pool.endTime && ethRaised < pool.softCap),
            "Refund unavailable."
        );
        _;
    }

    constructor(
        IERC20 _tokenInstance,
        address _uniswapv2Router,
        address _uniswapv2Factory,
        address _teamWallet,
        address _weth
    ) {
        require(_uniswapv2Router != address(0), "Invalid router address");
        require(_uniswapv2Factory != address(0), "Invalid factory address");

        isInit = false;
        isDeposit = false;
        isFinish = false;
        isRefund = false;
        ethRaised = 0;

        teamWallet = _teamWallet;
        weth = _weth;
        tokenInstance = _tokenInstance;
        creatorWallet = address(payable(msg.sender));
        UniswapV2Router02 = IUniswapV2Router02(_uniswapv2Router);
        UniswapV2Factory = IUniswapV2Factory(_uniswapv2Factory);

        require(
            UniswapV2Factory.getPair(address(tokenInstance), weth) ==
                address(0),
            "IUniswap: Pool exists."
        );

        tokenInstance.approve(_uniswapv2Router, tokenInstance.totalSupply());
    }

    event Liquified(
        address indexed _token,
        address indexed _router,
        address indexed _pair
    );

    event Canceled(
        address indexed _inititator,
        address indexed _token,
        address indexed _presale
    );

    event Bought(address indexed _buyer, uint256 _tokenAmount);

    event Refunded(address indexed _refunder, uint256 _tokenAmount);

    event Deposited(address indexed _initiator, uint256 _totalDeposit);

    event Claimed(address indexed _participent, uint256 _tokenAmount);

    event RefundedRemainder(address indexed _initiator, uint256 _amount);

    event BurntRemainder(address indexed _initiator, uint256 _amount);

    event Withdraw(address indexed _creator, uint256 _amount);

    /*
     * Reverts ethers sent to this address whenever requirements are not met
     */
    receive() external payable {
        if (
            block.timestamp >= pool.startTime && block.timestamp <= pool.endTime
        ) {
            buyTokens(_msgSender());
        } else {
            revert("Presale is closed");
        }
    }

    /*
    * Initiates the arguments of the sale
    @dev arguments must be pa   ssed in wei (amount*10**18)
    */
    function initSale(
        uint64 _startTime,
        uint64 _endTime,
        uint256 _tokenDeposit,
        uint256 _tokensForSale,
        uint256 _tokensForLiquidity,
        uint8 _liquidityPortion,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _maxBuy,
        uint256 _minBuy
    ) external onlyOwner onlyInactive {
        require(isInit == false, "Sale no initialized");
        require(_startTime >= block.timestamp, "Invalid start time.");
        require(_endTime > block.timestamp, "Invalid end time.");
        require(_tokenDeposit > 0, "Invalid token deposit.");
        require(_tokensForSale < _tokenDeposit, "Invalid tokens for sale.");
        require(
            _tokensForLiquidity < _tokenDeposit,
            "Invalid tokens for liquidity."
        );
        require(_softCap >= _hardCap / 2, "SC must be >= HC/2.");
        require(_liquidityPortion >= 50, "Liquidity must be >=50.");
        require(_liquidityPortion <= 100, "Invalid liquidity.");
        require(_minBuy < _maxBuy, "Min buy must greater than max.");
        require(_minBuy > 0, "Min buy must exceed 0.");

        Pool memory newPool = Pool(
            _startTime,
            _endTime,
            _tokenDeposit,
            _tokensForSale,
            _tokensForLiquidity,
            _liquidityPortion,
            _hardCap,
            _softCap,
            _maxBuy,
            _minBuy
        );

        pool = newPool;

        isInit = true;
    }

    /*
     * Once called the owner deposits tokens into pool
     */
    function deposit() external onlyOwner {
        require(!isDeposit, "Tokens already deposited.");
        require(isInit, "Not initialized yet.");

        uint256 totalDeposit = _getTokenDeposit();

        isDeposit = true;

        require(
            tokenInstance.transferFrom(msg.sender, address(this), totalDeposit),
            "Deposit failed."
        );

        emit Deposited(msg.sender, totalDeposit);
    }

    /*
     * Finish the sale - Create Uniswap v2 pair, add liquidity, take fees, withrdawal funds, burn/refund unused tokens
     */
    function finishSale() external onlyOwner onlyInactive {
        require(ethRaised >= pool.softCap, "Soft Cap is not met.");
        require(
            block.timestamp > pool.startTime,
            "Can not finish before start"
        );
        require(!isFinish, "Sale already launched.");
        require(!isRefund, "Refund process.");

        percentageRaised = _getPercentageFromValue(ethRaised, pool.hardCap);
        tokensSold = _getValueFromPercentage(
            percentageRaised,
            pool.tokensForSale
        );
        uint256 tokensForLiquidity = _getValueFromPercentage(
            percentageRaised,
            pool.tokensForLiquidity
        );
        isFinish = true;

        //add liquidity
        (uint256 amountToken, uint256 amountETH, ) = UniswapV2Router02
            .addLiquidityETH{value: _getLiquidityEth()}(
            address(tokenInstance),
            tokensForLiquidity,
            tokensForLiquidity,
            _getLiquidityEth(),
            owner(),
            block.timestamp + 600
        );

        require(
            amountToken == tokensForLiquidity &&
                amountETH == _getLiquidityEth(),
            "Providing liquidity failed."
        );

        emit Liquified(
            address(tokenInstance),
            address(UniswapV2Router02),
            UniswapV2Factory.getPair(address(tokenInstance), weth)
        );

        //withrawal eth
        uint256 ownerShareEth = _getOwnerEth();

        if (ownerShareEth > 0) {
            payable(creatorWallet).transfer(ownerShareEth);
        }

        //If HC is not reached, burn or refund the remainder
        if (ethRaised < pool.hardCap) {
            uint256 remainder = _getUserTokens(pool.hardCap - ethRaised) +
                (pool.tokensForLiquidity - tokensForLiquidity);
            if (burnTokens == true) {
                require(
                    tokenInstance.transfer(
                        0x000000000000000000000000000000000000dEaD,
                        remainder
                    ),
                    "Unable to burn."
                );
                emit BurntRemainder(msg.sender, remainder);
            } else {
                require(
                    tokenInstance.transfer(creatorWallet, remainder),
                    "Refund failed."
                );
                emit RefundedRemainder(msg.sender, remainder);
            }
        }
    }

    /*
    * The owner can decide to close the sale if it is still active
    NOTE: Creator may call this function even if the Hard Cap is reached, to prevent it use:
     require(ethRaised < pool.hardCap)
    */
    function cancelSale() external onlyOwner onlyActive {
        require(!isFinish, "Sale finished.");
        pool.endTime = 0;
        isRefund = true;

        if (tokenInstance.balanceOf(address(this)) > 0) {
            uint256 tokenDeposit = _getTokenDeposit();
            tokenInstance.transfer(msg.sender, tokenDeposit);
            emit Withdraw(msg.sender, tokenDeposit);
        }
        emit Canceled(msg.sender, address(tokenInstance), address(this));
    }

    /*
     * Allows participents to claim the tokens they purchased
     */
    function claimTokens() external onlyInactive {
        require(isFinish, "Sale is still active.");
        require(!isRefund, "Refund process.");

        uint256 tokensAmount = _getUserTokens(ethContribution[msg.sender]);
        ethContribution[msg.sender] = 0;
        require(
            tokenInstance.transfer(msg.sender, tokensAmount),
            "Claim failed."
        );
        emit Claimed(msg.sender, tokensAmount);
    }

    /*
     * Refunds the Eth to participents
     */
    function refund() external onlyInactive onlyRefund {
        uint256 refundAmount = ethContribution[msg.sender];

        require(refundAmount > 0, "No refund amount");
        require(address(this).balance >= refundAmount, "No amount available");

        ethContribution[msg.sender] = 0;
        address payable refunder = payable(msg.sender);
        refunder.transfer(refundAmount);
        emit Refunded(refunder, refundAmount);
    }

    /*
     * Withdrawal tokens on refund
     */
    function withrawTokens() external onlyOwner onlyInactive onlyRefund {
        if (tokenInstance.balanceOf(address(this)) > 0) {
            uint256 tokenDeposit = _getTokenDeposit();
            require(
                tokenInstance.transfer(msg.sender, tokenDeposit),
                "Withdraw failed."
            );
            emit Withdraw(msg.sender, tokenDeposit);
        }
    }

    /*
     * If requirements are passed, updates user"s token balance based on their eth contribution
     */
    function buyTokens(address _contributor) public payable onlyActive {
        require(isDeposit, "Tokens not deposited.");
        require(_contributor != address(0), "Transfer to 0 address.");
        require(msg.value != 0, "Wei Amount is 0");
        require(msg.value >= pool.minBuy, "Min buy is not met.");
        require(
            msg.value + ethContribution[_contributor] <= pool.maxBuy,
            "Max buy limit exceeded."
        );
        require(ethRaised + msg.value <= pool.hardCap, "HC Reached.");

        ethRaised += msg.value;
        ethContribution[msg.sender] += msg.value;
    }

    /*
     * Internal functions, called when calculating balances
     */
    function _getUserTokens(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(tokensSold).div(ethRaised);
    }

    function _getLiquidityEth() internal view returns (uint256) {
        return _getValueFromPercentage(pool.liquidityPortion, ethRaised);
    }

    function _getOwnerEth() internal view returns (uint256) {
        uint256 liquidityEthFee = _getLiquidityEth();
        return ethRaised - liquidityEthFee;
    }

    function _getTokenDeposit() internal view returns (uint256) {
        return pool.tokenDeposit;
    }

    function _getPercentageFromValue(uint256 currentValue, uint256 maxValue)
        private
        pure
        returns (uint256)
    {
        require(currentValue <= maxValue, "Number too high");

        return currentValue.mul(100).div(maxValue);
    }

    function _getValueFromPercentage(
        uint256 currentPercentage,
        uint256 maxValue
    ) private pure returns (uint256) {
        require(currentPercentage <= 100, "Number too high");

        return maxValue.mul(currentPercentage).div(100);
    }
}