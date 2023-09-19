/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

/*

 ______     __   __     ______     __  __    
/\  ___\   /\ "-.\ \   /\  ___\   /\_\_\_\   
\ \  __\   \ \ \-.  \  \ \ \____  \/_/\_\/_  
 \ \_____\  \ \_\\"\_\  \ \_____\   /\_\/\_\ 
  \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/ 
                                             
EnrichX offers decentralized options trading, empowering you to trade, mint, and exercise crypto options with ease.

🛠️ Flash Exercise: Power in Your Hands
🛠️ ERC-20 Standard: Fungibility and Integration
🛠️ Non-Custodial: Your Assets, Your Control
🛠️ Counterparty Risk Eliminated

🛠️ Website: https://www.enrichx.co/
🛠️ Medium: https://enrichx.medium.com/
🛠️ Community: https://t.me/EnrichX
🛠️ Twitter: https://twitter.com/EnrichXFi

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// Contract on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

interface IECOToken is IERC20 {
	function init(address _underlying, address _strikeAsset, bool _isCall, uint256 _strikePrice, uint256 _expiryTime, uint256 _ecoFee, address payable _feeDestination, uint256 _maxExercisedAccounts) external;
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function underlying() external view returns (address);
    function strikeAsset() external view returns (address);
    function feeDestination() external view returns (address);
    function isCall() external view returns (bool);
    function strikePrice() external view returns (uint256);
    function expiryTime() external view returns (uint256);
    function totalCollateral() external view returns (uint256);
    function ecoFee() external view returns (uint256);
	function maxExercisedAccounts() external view returns (uint256);
    function underlyingSymbol() external view returns (string memory);
    function strikeAssetSymbol() external view returns (string memory);
    function underlyingDecimals() external view returns (uint8);
    function strikeAssetDecimals() external view returns (uint8);
    function currentCollateral(address account) external view returns(uint256);
    function unassignableCollateral(address account) external view returns(uint256);
    function assignableCollateral(address account) external view returns(uint256);
    function currentCollateralizedTokens(address account) external view returns(uint256);
    function unassignableTokens(address account) external view returns(uint256);
    function assignableTokens(address account) external view returns(uint256);
    function getCollateralAmount(uint256 tokenAmount) external view returns(uint256);
    function getTokenAmount(uint256 collateralAmount) external view returns(uint256);
    function getBaseExerciseData(uint256 tokenAmount) external view returns(address, uint256);
    function numberOfAccountsWithCollateral() external view returns(uint256);
    function getCollateralOnExercise(uint256 tokenAmount) external view returns(uint256, uint256);
    function collateral() external view returns(address);
    function mintPayable() external payable;
    function mintToPayable(address account) external payable;
    function mint(uint256 collateralAmount) external;
    function mintTo(address account, uint256 collateralAmount) external;
    function burn(uint256 tokenAmount) external;
    function burnFrom(address account, uint256 tokenAmount) external;
    function redeem() external;
    function redeemFrom(address account) external;
    function exercise(uint256 tokenAmount, uint256 salt) external payable;
    function exerciseFrom(address account, uint256 tokenAmount, uint256 salt) external payable;
    function exerciseAccounts(uint256 tokenAmount, address[] calldata accounts) external payable;
    function exerciseAccountsFrom(address account, uint256 tokenAmount, address[] calldata accounts) external payable;
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

/**
 * @title ECOFlashExercise
 * @dev Contract to exercise ECO tokens using Uniswap Flash Swap.
 */
contract ECOFlashExercise is IUniswapV2Callee {
    
    /**
     * @dev The Uniswap factory address.
     */
    address immutable public uniswapFactory;
    
    /**
     * @dev The Uniswap Router address.
     */
    address immutable public uniswapRouter;

    /**
     * @dev The WETH address used on Uniswap.
     */
    address immutable public weth;
    
    /**
     * @dev Selector for ERC20 approve function.
     */
    bytes4 immutable internal _approveSelector;
    
    /**
     * @dev Selector for ERC20 transfer function.
     */
    bytes4 immutable internal _transferSelector;
    
    constructor(address _uniswapRouter) {
        uniswapRouter = _uniswapRouter;
        uniswapFactory = IUniswapV2Router02(_uniswapRouter).factory();
        weth = IUniswapV2Router02(_uniswapRouter).WETH();
        
        _approveSelector = bytes4(keccak256(bytes("approve(address,uint256)")));
        _transferSelector = bytes4(keccak256(bytes("transfer(address,uint256)")));
    }
    
    /**
     * @dev To accept ether from the WETH.
     */
    receive() external payable {}
    
    /**
     * @dev Function to get the Uniswap pair for an ECO token.
     * @param ecoToken Address of the ECO token.
     * @return The Uniswap pair for the ECO token.
     */
    function getUniswapPair(address ecoToken) public view returns(address) {
        address underlying = _getUniswapToken(IECOToken(ecoToken).underlying());
        address strikeAsset = _getUniswapToken(IECOToken(ecoToken).strikeAsset());
        return IUniswapV2Factory(uniswapFactory).getPair(underlying, strikeAsset);
    }
    
    /**
     * @dev Function to get the required amount of collateral to be paid to Uniswap and the expected amount to exercise the ECO token.
     * @param ecoToken Address of the ECO token.
     * @param tokenAmount Amount of tokens to be exercised.
     * @param accounts The array of addresses to be exercised. Whether the array is empty the exercise will be executed using the standard method.
     * @return The required amount of collateral to be paid to Uniswap and the expected amount to exercise the ECO token.
     */
    function getExerciseData(address ecoToken, uint256 tokenAmount, address[] memory accounts) public view returns(uint256, uint256) {
        if (tokenAmount > 0) {
            address pair = getUniswapPair(ecoToken);
            if (pair != address(0)) {
                address token0 = IUniswapV2Pair(pair).token0();
                address token1 = IUniswapV2Pair(pair).token1();
                (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
                
                (address exerciseAddress, uint256 expectedAmount) = _getEcoExerciseData(ecoToken, tokenAmount, accounts);
                
				exerciseAddress = _getUniswapToken(exerciseAddress);
                
                uint256 reserveIn = 0; 
                uint256 reserveOut = 0;
                if (exerciseAddress == token0 && expectedAmount < reserve0) {
                    reserveIn = reserve1;
                    reserveOut = reserve0;
                } else if (exerciseAddress == token1 && expectedAmount < reserve1) {
                    reserveIn = reserve0;
                    reserveOut = reserve1;
                }
                
                if (reserveIn > 0 && reserveOut > 0) {
                    uint256 amountRequired = IUniswapV2Router02(uniswapRouter).getAmountIn(expectedAmount, reserveIn, reserveOut);
                    return (amountRequired, expectedAmount);
                }
            }
        }
        return (0, 0);
    }
    
    /**
     * @dev Function to get the estimated collateral to be received through a flash exercise.
     * @param ecoToken Address of the ECO token.
     * @param tokenAmount Amount of tokens to be exercised.
     * @return The estimated collateral to be received through a flash exercise using the standard exercise function.
     */
    function getEstimatedReturn(address ecoToken, uint256 tokenAmount) public view returns(uint256) {
        (uint256 amountRequired,) = getExerciseData(ecoToken, tokenAmount, new address[](0));
        if (amountRequired > 0) {
            (uint256 collateralAmount,) = IECOToken(ecoToken).getCollateralOnExercise(tokenAmount);
            if (amountRequired < collateralAmount) {
                return collateralAmount - amountRequired;
            }
        }
        return 0;
    }
    
    /**
     * @dev Function to flash exercise ECO tokens.
     * The flash exercise uses the flash swap functionality on Uniswap.
     * No asset is required to exercise the ECO token because the own collateral redeemed is used to fulfill the terms of the contract.
     * The account will receive the remaining difference.
     * @param ecoToken Address of the ECO token.
     * @param tokenAmount Amount of tokens to be exercised.
     * @param minimumCollateral The minimum amount of collateral accepted to be received on the flash exercise.
     * @param salt Random number to calculate the start index of the array of accounts to be exercised.
     */
    function flashExercise(address ecoToken, uint256 tokenAmount, uint256 minimumCollateral, uint256 salt) public {
        _flashExercise(ecoToken, tokenAmount, minimumCollateral, salt, new address[](0));
    }
    
    /**
     * @dev Function to flash exercise ECO tokens.
     * The flash exercise uses the flash swap functionality on Uniswap.
     * No asset is required to exercise the ECO token because the own collateral redeemed is used to fulfill the terms of the contract.
     * The account will receive the remaining difference.
     * @param ecoToken Address of the ECO token.
     * @param tokenAmount Amount of tokens to be exercised.
     * @param minimumCollateral The minimum amount of collateral accepted to be received on the flash exercise.
     * @param accounts The array of addresses to get the deposited collateral. 
     */
    function flashExerciseAccounts(
        address ecoToken, 
        uint256 tokenAmount, 
        uint256 minimumCollateral, 
        address[] memory accounts
    ) public {
        require(accounts.length > 0, "ECOFlashExercise::flashExerciseAccounts: Accounts are required");
        _flashExercise(ecoToken, tokenAmount, minimumCollateral, 0, accounts);
    }
    
     /**
     * @dev External function to be called by the Uniswap pair on flash swap transaction.
     * @param sender Address of the sender of the Uniswap swap. It must be the ECOFlashExercise contract.
     * @param amount0Out Amount of token0 on Uniswap pair to be received on the flash swap.
     * @param amount1Out Amount of token1 on Uniswap pair to be received on the flash swap.
     * @param data The ABI encoded with ECO token flash exercise data.
     */
    function uniswapV2Call(
        address sender, 
        uint256 amount0Out, 
        uint256 amount1Out, 
        bytes calldata data
    ) external override {
        require(sender == address(this), "ECOFlashExercise::uniswapV2Call: Invalid sender");
        
        uint256 amountRequired;
        {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        require(msg.sender == IUniswapV2Factory(uniswapFactory).getPair(token0, token1), "ECOFlashExercise::uniswapV2Call: Invalid transaction sender"); 
        require(amount0Out == 0 || amount1Out == 0, "ECOFlashExercise::uniswapV2Call: Invalid out amounts"); 
        
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(msg.sender).getReserves();
        uint256 reserveIn = amount0Out == 0 ? reserve0 : reserve1; 
        uint256 reserveOut = amount0Out == 0 ? reserve1 : reserve0; 
        amountRequired = IUniswapV2Router02(uniswapRouter).getAmountIn((amount0Out + amount1Out), reserveIn, reserveOut);
        }
        
        address ecoToken;
        uint256 tokenAmount; 
        uint256 ethValue = 0;
        uint256 remainingAmount;
        uint256 salt;
        address from;
        address[] memory accounts;
        {
        uint256 minimumCollateral;
        (from, ecoToken, tokenAmount, minimumCollateral, salt, accounts) = abi.decode(data, (address, address, uint256, uint256, uint256, address[]));
        
		(address exerciseAddress, uint256 expectedAmount) = _getEcoExerciseData(ecoToken, tokenAmount, accounts);
        
        require(expectedAmount == (amount1Out + amount0Out), "ECOFlashExercise::uniswapV2Call: Invalid expected amount");
        
        (uint256 collateralAmount,) = IECOToken(ecoToken).getCollateralOnExercise(tokenAmount);
        require(amountRequired <= collateralAmount, "ECOFlashExercise::uniswapV2Call: Insufficient collateral amount");
        
        remainingAmount = collateralAmount - amountRequired;
        require(remainingAmount >= minimumCollateral, "ECOFlashExercise::uniswapV2Call: Minimum amount not satisfied");
        
        if (_isEther(exerciseAddress)) {
            ethValue = expectedAmount;
            IWETH(weth).withdraw(expectedAmount);
        } else {
            _callApproveERC20(exerciseAddress, ecoToken, expectedAmount);
        }
        }
        
        if (accounts.length == 0) {
            IECOToken(ecoToken).exerciseFrom{value: ethValue}(from, tokenAmount, salt);
        } else {
            IECOToken(ecoToken).exerciseAccountsFrom{value: ethValue}(from, tokenAmount, accounts);
        }
        
        address collateral = IECOToken(ecoToken).collateral();
        address uniswapPayment;
        if (_isEther(collateral)) {
            payable(from).transfer(remainingAmount);
            IWETH(weth).deposit{value: amountRequired}();
            uniswapPayment = weth;
        } else {
            _callTransferERC20(collateral, from, remainingAmount); 
            uniswapPayment = collateral;
        }
        
        _callTransferERC20(uniswapPayment, msg.sender, amountRequired); 
    }
	
	/**
     * @dev Internal function to get the ECO tokens exercise data.
     * @param ecoToken Address of the ECO token.
     * @param tokenAmount Amount of tokens to be exercised.
     * @param accounts The array of addresses to be exercised. Whether the array is empty the exercise will be executed using the standard method.
	 * @return The asset and the respective amount that should be sent to get the collateral.
     */
	function _getEcoExerciseData(address ecoToken, uint256 tokenAmount, address[] memory accounts) internal view returns(address, uint256) {
		(address exerciseAddress, uint256 expectedAmount) = IECOToken(ecoToken).getBaseExerciseData(tokenAmount);
		if (accounts.length == 0) {
			expectedAmount = expectedAmount + IECOToken(ecoToken).maxExercisedAccounts();
		} else {
			expectedAmount = expectedAmount + accounts.length;
		}
		return (exerciseAddress, expectedAmount);
	}
	
    /**
     * @dev Internal function to flash exercise ECO tokens.
     * @param ecoToken Address of the ECO token.
     * @param tokenAmount Amount of tokens to be exercised.
     * @param minimumCollateral The minimum amount of collateral accepted to be received on the flash exercise.
     * @param salt Random number to calculate the start index of the array of accounts to be exercised when using standard method.
     * @param accounts The array of addresses to get the deposited collateral. Whether the array is empty the exercise will be executed using the standard method.
     */
    function _flashExercise(
        address ecoToken, 
        uint256 tokenAmount, 
        uint256 minimumCollateral, 
        uint256 salt,
        address[] memory accounts
    ) internal {
        address pair = getUniswapPair(ecoToken);
        require(pair != address(0), "ECOFlashExercise::_flashExercise: Invalid Uniswap pair");
        
        (address exerciseAddress, uint256 expectedAmount) = _getEcoExerciseData(ecoToken, tokenAmount, accounts);

        uint256 amount0Out = 0;
        uint256 amount1Out = 0;
        if (_getUniswapToken(exerciseAddress) == IUniswapV2Pair(pair).token0()) {
            amount0Out = expectedAmount;
        } else {
            amount1Out = expectedAmount;  
        }
        
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), abi.encode(msg.sender, ecoToken, tokenAmount, minimumCollateral, salt, accounts));
    }
    
    /**
     * @dev Internal function to get Uniswap token address.
     * The Ethereum address on ECO must be swapped to WETH to be used on Uniswap.
     * @param token Address of the token on ECO.
     * @return Uniswap token address.
     */
    function _getUniswapToken(address token) internal view returns(address) {
        if (_isEther(token)) {
            return weth;
        } else {
            return token;
        }
    }
    
    /**
     * @dev Internal function to get if the token is for Ethereum (0x0).
     * @param token Address to be checked.
     * @return Whether the address is for Ethereum.
     */ 
    function _isEther(address token) internal pure returns(bool) {
        return token == address(0);
    }
    
    /**
     * @dev Internal function to approve ERC20 tokens.
     * @param token Address of the token.
     * @param spender Authorized address.
     * @param amount Amount to transfer.
     */
    function _callApproveERC20(address token, address spender, uint256 amount) internal {
        (bool success, bytes memory returndata) = token.call(abi.encodeWithSelector(_approveSelector, spender, amount));
        require(success && (returndata.length == 0 || abi.decode(returndata, (bool))), "ECOTokenExercise::_callApproveERC20");
    }
    
    /**
     * @dev Internal function to transfer ERC20 tokens.
     * @param token Address of the token.
     * @param recipient Address of the transfer destination.
     * @param amount Amount to transfer.
     */
    function _callTransferERC20(address token, address recipient, uint256 amount) internal {
        (bool success, bytes memory returndata) = token.call(abi.encodeWithSelector(_transferSelector, recipient, amount));
        require(success && (returndata.length == 0 || abi.decode(returndata, (bool))), "ECOTokenExercise::_callTransferERC20");
    }
}