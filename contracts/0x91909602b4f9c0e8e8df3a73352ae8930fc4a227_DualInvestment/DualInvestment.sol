/**
 *Submitted for verification at Etherscan.io on 2023-09-25
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: xDuplify Loan.sol


pragma solidity ^0.8.11;

//  ==========  External imports. ==========



interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract DualInvestment is Ownable {
    address public USDT_ADDRESS; //  USDT_ADDRESS address
    IERC20 public usdtToken; // IERC20 of USDT
    address public PANCAKE_ROUTER_ADDRESS; // PancakeSwap Router Address
    address public fundManager;

    // User Info
    struct loanMortage {
        uint256 collateralAmount;
        address tokenAddress;
        uint256 tokenAmount;
        uint256 loanAmount;
        uint256 loantimestamp;
    }

    // Emitted when a new mortgage is created
    event MortgageCreated(
        address indexed user,
        address indexed tokenAddress,
        uint256 collateralAmount,
        uint256 loanAmount,
        uint256 timestamp
    );

    // Emitted when a user closes their mortgage
    event MortgageClosed(
        address indexed user,
        address indexed tokenAddress,
        uint256 collateralAmount,
        uint256 loanAmount,
        uint256 receivedAmount,
        uint256 timestamp
    );

    // Emitted when the Fund Manager forces the closure of a deposit
    event DepositClosedByOwner(
        address indexed user,
        address indexed tokenAddress,
        uint256 collateralAmount,
        uint256 loanAmount,
        uint256 receivedAmount
    );

    uint256 private constant MAX_LOSS_BIPS = 3000;

    mapping(address => loanMortage) public loanMortageData;
    // supportedTokens Are Only Allows To Buy Token In this Smart Contract
    mapping(address => bool) public supportedTokens;

    // Create a mapping to store the blacklist status of user addresses
    mapping(address => bool) public blacklist;

    // Mapping from token address to a list of token holders
    mapping(address => address[]) private tokenHolders;

    // Modifier to require that the caller is the Fund Manager
    modifier onlyFundManager() {
        require(
            fundManager == msg.sender,
            "CustomRole: Caller is not the Fund Manager"
        );
        _;
    }

    modifier notBlacklisted() {
        require(!blacklist[msg.sender], "Blacklist: sender is blacklisted");
        _;
    }

    uint256 public limitMortageMultiple = 5;
    uint256 public dueDateGap = 7 days;
    uint256 public totalUSDTalloted = 0;
    uint256 public commisionPercentage = 1000;
    uint256 public intrest_commisionPercentage = 200;
    uint256 public commisionFund = 0;
    uint256 public motrageFund = 0;

    constructor(address _fundManager, address _USDT, address _pancakeRouter) {
        USDT_ADDRESS = _USDT;
        PANCAKE_ROUTER_ADDRESS = _pancakeRouter;
        fundManager = _fundManager;
        usdtToken = IERC20(_USDT);
    }

    // Function for users to deposit a token and receive a mortgage loan in USDT
    // The deposited token will be swapped for USDT on PancakeSwap
    // The loan amount is determined based on the current token price and the mortgage multiple limit
    // The collateral amount is the loan amount minus the user's token deposit amount
    function giveMortage(
        uint256 _USDTtokenAmountDeposite,
        uint256 _loanmultiple,
        address _token_address
    ) public notBlacklisted {
        require(
            limitMortageMultiple >= _loanmultiple,
            "You Can Not Borrow More then Max Loan"
        );
        require(
            _USDTtokenAmountDeposite > 0,
            "_USDTtokenAmountDeposite Can Not Be Zero"
        );
        require(
            checkTheUSDTAvailable(
                _USDTtokenAmountDeposite * _loanmultiple 
            ),
            "Sorry Fund Not Available For DEBT"
        );
        require(
            loanMortageData[msg.sender].collateralAmount == 0,
            "You Already Have Active Deposit"
        );

        require(supportedTokens[_token_address], "Token Is Not Supported");

        uint256 commision = calculateCommison(
            _USDTtokenAmountDeposite,
            _loanmultiple + 1,
            commisionPercentage
        );
        uint256 _amountwithcommision = _USDTtokenAmountDeposite + commision;
        commisionFund = commisionFund + commision;

        usdtToken.transferFrom(msg.sender, address(this), _amountwithcommision);

        motrageFund =
            motrageFund -
            (_USDTtokenAmountDeposite * (_loanmultiple + 1));

        IERC20(USDT_ADDRESS).approve(
            PANCAKE_ROUTER_ADDRESS,
            (_USDTtokenAmountDeposite * _loanmultiple) +
                _USDTtokenAmountDeposite
        );

        buyTokenWithLoanCredits(
            _token_address,
            (_USDTtokenAmountDeposite * _loanmultiple) +
                _USDTtokenAmountDeposite
        );

        loanMortageData[msg.sender].tokenAddress = _token_address;
        loanMortageData[msg.sender].loantimestamp = block.timestamp;
        loanMortageData[msg.sender].collateralAmount = _USDTtokenAmountDeposite;
        loanMortageData[msg.sender].loanAmount =
            (_USDTtokenAmountDeposite * _loanmultiple) +
            _USDTtokenAmountDeposite;

        tokenHolders[_token_address].push(msg.sender);

        emit MortgageCreated(
            msg.sender,
            _token_address,
            _USDTtokenAmountDeposite,
            (_USDTtokenAmountDeposite * _loanmultiple) +
                _USDTtokenAmountDeposite,
            block.timestamp
        );
    }

    function buyTokenWithLoanCredits(
        address _tokenAddress,
        uint256 _amountInUSDT
    ) private {
        address[] memory path = new address[](2);
        path[0] = USDT_ADDRESS;
        path[1] = _tokenAddress;

        uint256[] memory _estimatedAmounts = IPancakeRouter02(
            PANCAKE_ROUTER_ADDRESS
        ).getAmountsOut(_amountInUSDT, path);

        uint256 _minAmount = (_estimatedAmounts[1] * (100 - 90)) / 100;

        uint256[] memory _amountReceived = IPancakeRouter02(
            PANCAKE_ROUTER_ADDRESS
        ).swapExactTokensForTokens(
                _amountInUSDT,
                _minAmount,
                path,
                address(this),
                block.timestamp + 1200
            );

        require(
            _amountReceived[1] >= _minAmount,
            "Received amount is below minimum expected"
        );

        loanMortageData[msg.sender].tokenAmount = _amountReceived[1];
    }

    // Function for users to end their deposit and close their mortgage loan
    // If there is a loss on the deposit (deposit value is less than the loan amount),
    // the user's collateral is used to cover the loss up to a maximum of 30%
    // If there is a profit on the deposit (deposit value is more than the loan amount),
    // the profit is shared between the user and the contract according to the interest commission percentage
    function endDeposite() public notBlacklisted {
        require(
            loanMortageData[msg.sender].collateralAmount != 0,
            "You Don't Have Active Deposit"
        );
        require(
            IERC20(loanMortageData[msg.sender].tokenAddress).approve(
                PANCAKE_ROUTER_ADDRESS,
                loanMortageData[msg.sender].tokenAmount
            ),
            "Approval failed"
        );

        address[] memory path = new address[](2);
        path[0] = loanMortageData[msg.sender].tokenAddress;
        path[1] = USDT_ADDRESS;

        uint256[] memory _estimatedAmounts = IPancakeRouter02(
            PANCAKE_ROUTER_ADDRESS
        ).getAmountsOut(loanMortageData[msg.sender].tokenAmount, path);
        uint256 _minAmount = (_estimatedAmounts[1] * (100 - 90)) / 100;

        uint256[] memory _amountReceived = IPancakeRouter02(
            PANCAKE_ROUTER_ADDRESS
        ).swapExactTokensForTokens(
                loanMortageData[msg.sender].tokenAmount,
                _minAmount,
                path,
                address(this),
                block.timestamp + 1200
            );

        require(
            _amountReceived[1] >= _minAmount,
            "Received amount is below minimum expected"
        );

        if (loanMortageData[msg.sender].loanAmount > _amountReceived[1]) {
            require(
                calculatePercentage(
                    _amountReceived[1],
                    loanMortageData[msg.sender].loanAmount
                ) > 10000 - MAX_LOSS_BIPS,
                "Deposite Is Above 30% Loss"
            );

            uint256 loss_bips = calculatePercentage(
                _amountReceived[1],
                loanMortageData[msg.sender].loanAmount
            );
            uint256 loss_of_users = calculateCommison(
                loanMortageData[msg.sender].collateralAmount,
                1,
                loss_bips
            );
            uint256 loss_of_contract = calculateCommison(
                (loanMortageData[msg.sender].loanAmount -
                    loanMortageData[msg.sender].collateralAmount),
                1,
                loss_bips
            );

            usdtToken.transfer(msg.sender, loss_of_users);
            motrageFund = motrageFund + loss_of_contract;
        } else {
            uint256 _profit = _amountReceived[1] -
                loanMortageData[msg.sender].loanAmount;
            uint256 _intrest_comminsion = calculateCommison(
                _amountReceived[1],
                1,
                intrest_commisionPercentage
            );
            uint256 final_amount_to_user = loanMortageData[msg.sender]
                .collateralAmount + (_profit - _intrest_comminsion);
            motrageFund =
                motrageFund +
                (loanMortageData[msg.sender].loanAmount -
                    loanMortageData[msg.sender].collateralAmount);
            commisionFund = commisionFund + _intrest_comminsion;
            usdtToken.transfer(msg.sender, final_amount_to_user);
        }

        for (
            uint256 i = 0;
            i < tokenHolders[loanMortageData[msg.sender].tokenAddress].length;
            i++
        ) {
            if (
                tokenHolders[loanMortageData[msg.sender].tokenAddress][i] ==
                msg.sender
            ) {
                tokenHolders[loanMortageData[msg.sender].tokenAddress][
                    i
                ] = tokenHolders[loanMortageData[msg.sender].tokenAddress][
                    tokenHolders[loanMortageData[msg.sender].tokenAddress]
                        .length - 1
                ];
                tokenHolders[loanMortageData[msg.sender].tokenAddress].pop();
                break;
            }
        }
        loanMortageData[msg.sender] = loanMortage(0, address(0), 0, 0, 0);

        emit MortgageClosed(
            msg.sender,
            loanMortageData[msg.sender].tokenAddress,
            loanMortageData[msg.sender].collateralAmount,
            loanMortageData[msg.sender].loanAmount,
            _amountReceived[1],
            block.timestamp
        );
    }

    // Function for the Fund Manager to end a user's deposit if the loss is above 30%
    // The deposited token will be swapped for USDT on PancakeSwap
    // The mortgage fund will absorb the loss and the user's deposit will be closed
    function endDepositeByOwner(address _user_addr) public onlyFundManager {
        require(
            loanMortageData[_user_addr].collateralAmount != 0,
            "You Don't Have Active Deposit"
        );

        // Create a path array with the token addresses
        address[] memory path = new address[](2);
        path[0] = loanMortageData[_user_addr].tokenAddress;
        path[1] = USDT_ADDRESS;

        // Estimate the amount of USDT the user should receive in return for their tokens
        uint256[] memory _minamounts = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS)
            .getAmountsOut(loanMortageData[_user_addr].tokenAmount, path);

        // Calculate the _minAmount of USDT to be received by applying the slippage tolerance
        uint256 _minAmount = (_minamounts[1] * (100 - 90)) / 100;

        require(
            loanMortageData[_user_addr].loanAmount > _minAmount,
            "There Is No Loss"
        );
        require(
            calculatePercentage(
                _minAmount,
                loanMortageData[_user_addr].loanAmount
            ) <= 10000 - MAX_LOSS_BIPS,
            "Deposit Is Not Above 30% Loss"
        );

        require(
            IERC20(loanMortageData[_user_addr].tokenAddress).approve(
                PANCAKE_ROUTER_ADDRESS,
                loanMortageData[_user_addr].tokenAmount
            ),
            "Approval failed"
        );

        uint256[] memory _amountReceived = IPancakeRouter02(
            PANCAKE_ROUTER_ADDRESS
        ).swapExactTokensForTokens(
                loanMortageData[_user_addr].tokenAmount,
                _minAmount,
                path,
                address(this),
                block.timestamp + 1200
            );

        require(
            _amountReceived[1] >= _minAmount,
            "Amount received is below the minimum acceptable amount"
        );

        motrageFund = motrageFund + _amountReceived[1];

        for (
            uint256 i = 0;
            i < tokenHolders[loanMortageData[_user_addr].tokenAddress].length;
            i++
        ) {
            if (
                tokenHolders[loanMortageData[_user_addr].tokenAddress][i] ==
                _user_addr
            ) {
                tokenHolders[loanMortageData[_user_addr].tokenAddress][
                    i
                ] = tokenHolders[loanMortageData[_user_addr].tokenAddress][
                    tokenHolders[loanMortageData[_user_addr].tokenAddress]
                        .length - 1
                ];
                tokenHolders[loanMortageData[_user_addr].tokenAddress].pop();
                break;
            }
        }

        loanMortageData[_user_addr] = loanMortage(0, address(0), 0, 0, 0);

        emit DepositClosedByOwner(
            _user_addr,
            loanMortageData[_user_addr].tokenAddress,
            loanMortageData[_user_addr].collateralAmount,
            loanMortageData[_user_addr].loanAmount,
            _amountReceived[1]
        );
    }

    function calculatePercentage(
        uint256 _numerator,
        uint256 _denominator
    ) public pure returns (uint256) {
        require(
            _denominator != 0 && _denominator > _numerator,
            "PercentageCalculator: denominator cannot be zero"
        );

        uint256 percentageBips = (_numerator * 10000) / _denominator;
        return percentageBips;
    }

    function calculateCommison(
        uint256 _amount,
        uint256 _loanmultiple,
        uint256 _bips
    ) public pure returns (uint256) {
        return (_bips * _amount * _loanmultiple) / 10000;
    }

    function checkTheUSDTAvailable(uint256 _amount) public view returns (bool) {
        if (motrageFund >= _amount) {
            return true;
        } else {
            return false;
        }
    }

    // Fetches the price of a specific token in terms of USDT
    // @param _tokenAddress The address of the token for which the price is requested
    // @return The price of the token in USDT
    function getTokenUSDTPrice(
        address _tokenAddress
    ) external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = USDT_ADDRESS;

        uint256[] memory amounts = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS)
            .getAmountsOut(1e18, path);
        return amounts[1]; // returns the price of 1 USDT in the token you specified
    }

    // Fetches the price of USDT in terms of a specific token
    // @param _tokenAddress The address of the token for which the price is requested
    // @return The price of USDT in the specified token
    function getUSDTTokenPrice(
        address _tokenAddress
    ) external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = USDT_ADDRESS;
        path[1] = _tokenAddress;

        uint256[] memory amounts = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS)
            .getAmountsOut(1e18, path);
        return amounts[1]; // returns the price of 1 USDT in the token you specified
    }

    // Fetches the loan mortgage data for the caller of the function
    // @return An array of loanMortage structs containing the loan mortgage data for the caller
    function getUserInfo() public view returns (loanMortage[] memory) {
        loanMortage[] memory user = new loanMortage[](1);
        user[0] = loanMortageData[msg.sender];
        return user;
    }

    // Fetches the loan mortgage data for a specific user (restricted to contract owner)
    // @param _user The address of the user for which the loan mortgage data is requested
    // @return An array of loanMortage structs containing the loan mortgage data for the specified user
    function getUserInfoOnlyOwner(
        address _user
    ) public view onlyOwner returns (loanMortage[] memory) {
        loanMortage[] memory user = new loanMortage[](1);
        user[0] = loanMortageData[_user];
        return user;
    }

    // Fetches the loan mortgage data for a specific user (restricted to the fund manager)
    // @param _user The address of the user for which the loan mortgage data is requested
    // @return An array of loanMortage structs containing the loan mortgage data for the specified user
    function getUserInfoOnlyFundManager(
        address _user
    ) public view onlyFundManager returns (loanMortage[] memory) {
        loanMortage[] memory user = new loanMortage[](1);
        user[0] = loanMortageData[_user];
        return user;
    }

    // Write

    // Adds a user to the blacklist
    // @param user The address of the user to be added to the blacklist
    function addToBlacklist(address user) public onlyOwner {
        blacklist[user] = true;
    }

    // Removes multiple tokens from the list of supported tokens in a batch
    // @param _batch An array of token addresses to be removed
    function removeSupportedTokens(address[] memory _batch) public onlyOwner {
        for (uint256 i = 0; i < _batch.length; i++) {
            supportedTokens[_batch[i]] = false;
        }
    }

    // Adds multiple tokens to the list of supported tokens in a batch
    // @param _batch An array of token addresses to be added
    function addSupportedTokens(address[] memory _batch) public onlyOwner {
        for (uint256 i = 0; i < _batch.length; i++) {
            supportedTokens[_batch[i]] = true;
        }
    }

    // Allows the contract owner to withdraw USDT from the commission fund
    // @param _amountInUSDT The amount of USDT to be withdrawn

    function withdrawUSDT(uint256 _amountInUSDT) public onlyOwner {
        usdtToken.transfer(msg.sender, _amountInUSDT);
    }

    function MistakenTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
    require(_tokenAddress != address(0), "Token address cannot be zero address");
    require(_tokenAmount > 0, "Amount must be greater than zero");

    IERC20 token = IERC20(_tokenAddress);
    uint256 contractBalance = token.balanceOf(address(this));
    require(contractBalance >= _tokenAmount, "Withdraw amount exceeds contract balance");

    token.transfer(msg.sender, _tokenAmount);
    }

    function MistakenEther(uint256 _amount) external onlyOwner {
    require(_amount > 0, "Amount must be greater than zero");
    require(address(this).balance >= _amount, "Withdraw amount exceeds contract ETH balance");

    payable(msg.sender).transfer(_amount);
    }

    // Changes the loan multiple limit
    // @param _newLimit The new loan multiple limit

    function changeLoanMultiple(uint256 _newLimit) public onlyOwner {
        limitMortageMultiple = _newLimit;
    }

    // Function to add funds to the mortgage fund by the owner
    function addMortageFund(uint256 _fund) public onlyOwner {
        require(_fund > 0, "Fund Cannot Be ZERO");

        usdtToken.transferFrom(msg.sender, address(this), _fund);

        motrageFund = motrageFund + _fund;
    }

    // Function to withdraw funds from the mortgage fund by the owner
    function withdrawMortageFund(uint256 _amount) public onlyOwner {
        require(
            motrageFund >= _amount,
            "Amount Cannot Be More that Mortage Fund"
        );

        usdtToken.transfer(msg.sender, _amount);
        motrageFund = motrageFund - _amount;
    }

    // Function to view the list of token holders for a specific token, accessible only by the fund manager
    function getTokenHolders(
        address _tokenAddress
    ) public view onlyFundManager returns (address[] memory) {
        return tokenHolders[_tokenAddress];
    }

    // Function to change the Fund Manager
    function changeFundManager(address _newFundManager) public onlyOwner {
        require(
            _newFundManager != address(0),
            "CustomRole: Fund Manager cannot be the zero address"
        );
        fundManager = _newFundManager;
    }

    receive() external payable {}
}