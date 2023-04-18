// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MetalorianSwap a USD stablecoin Pool
/// @author JorgeLpzGnz & CarlosMario714
/// @notice A Liquidity protocol based in the CPAMM ( Constant product Automated Market Maker ) 
contract MetalorianSwap is ERC20, Ownable {

    using SafeERC20 for IERC20Metadata;

    /**************************************************************/
    /********************* POOL DATA ******************************/

    IERC20Metadata public immutable token1; 

    IERC20Metadata public immutable token2; 

    /// @notice the total reserves of the token 1
    uint public totalToken1;

    /// @notice the total reserves of the token 2
    uint public totalToken2;

    /// @notice fee charge per trade designated to LP
    uint16 public tradeFee = 30;

    /// @notice fee charge per trade designated to protocol creator
    uint16 public protocolFee = 20;

    /// @notice the maximum tradable percentage of the reserves
    /// @dev that maximum will be this settable percentage of the respective token reserves
    uint16 public maxTradePercentage = 1000;

    /// @notice Fees recipient
    address public feeRecipient;

    /// @notice all the pool info ( used in getPoolInfo )
    struct PoolInfo {
        IERC20Metadata token1;
        IERC20Metadata token2;
        uint totalToken1;
        uint totalToken2;
        uint totalSupply;
        uint16 tradeFee;
        uint16 protocolFee;
        uint16 maxTradePercentage;
    }

    /**************************************************************/
    /*************************** EVENTS ***************************/

    /// @param owner contract owner address
    /// @param newProtocolFee new creator fee
    event NewProtocolFee( address owner, uint16 newProtocolFee );

    /// @param owner contract owner address
    /// @param newTradeFee new fee cost per trade
    event NewTradeFee( address owner, uint16 newTradeFee );

    /// @param owner contract owner address
    /// @param newTradePercentage new maximum tradable percentage of the reserves
    event NewMaxTradePercentage( address owner, uint16 newTradePercentage );

    /// @param newRecipient address of the new recipient
    event NewFeeRecipient( address indexed newRecipient );
    
    /// @param user user deposit address
    /// @param amountToken1 deposited amount of the first token
    /// @param amountToken2 deposited amount of the second token
    /// @param shares amount of LP tokens minted
    /// @param totalSupply new LP tokens total supply
    event NewLiquidity( address indexed user, uint amountToken1, uint amountToken2, uint shares, uint totalSupply );

    /// @param user user withdraw address
    /// @param amountToken1 amount withdrawn of the first token
    /// @param amountToken2 amount withdrawn of the second token
    /// @param shares amount of LP tokens burned
    /// @param totalSupply new LP tokens total supply
    event LiquidityWithdrawal( address indexed user, uint amountToken1, uint amountToken2, uint shares, uint totalSupply );

    /// @param user user trade address
    /// @param protocolFee incoming amount 
    /// @param amountIn incoming amount 
    /// @param amountOut output amount
    event Swap( address indexed user, uint protocolFee, uint amountIn, uint amountOut);


    /// @param _token1Address address of the first stablecoin 
    /// @param _token2Address address of the second stablecoin 
    /// @param _name the name and symbol of the LP token
    constructor (address _token1Address, address _token2Address, string memory _name, address _feeRecipient) ERC20( _name, _name ) {

        token1 = IERC20Metadata( _token1Address );

        token2 = IERC20Metadata( _token2Address );

        feeRecipient = _feeRecipient;

    }

    /**************************************************************/
    /************************** MODIFIERS *************************/

    /// @notice it checks if the pool have funds 
    modifier isActive {

        require( totalSupply() > 0, "Error: contract has no funds");

        _;

    }

    /// @notice it checks the user has the sufficient balance
    /// @param _amount the amount to check
    modifier checkShares( uint _amount) {

        require( _amount > 0, "Error: Invalid Amount, value = 0");
        
        require( balanceOf( msg.sender ) >= _amount, "Error: Insufficient LP balance");

        _;

    }

    /**************************************************************/
    /**************************** UTILS ***************************/

    /// @notice decimals representation
    function decimals() public pure override returns( uint8 ) {

        return 6;
        
    }

    /// @notice this returns the minimum between the given numbers
    function _min( uint x, uint y ) private pure returns( uint ) {

        return x <= y ? x : y;

    }

    /// @notice this returns the maximum between the given numbers
    function _max( uint x, uint y ) private pure returns( uint ) {

        return x >= y ? x : y;

    }

    /// @notice it updates the current reserves
    /// @param _amountToken1 the new total reserves of token 1
    /// @param _amountToken2 the new total reserves of token 2
    function _updateBalances( uint _amountToken1, uint _amountToken2) private {

        totalToken1 = _amountToken1;

        totalToken2 = _amountToken2;

    }

    /// @notice this verify if two numbers are equal
    /// @dev if they are not equal, take the minimum + 1 to check if it is equal to the largest
    /// this to handle possible precision errors
    /// @param x amount 1
    /// @param y amount 2
    function _isEqual( uint x, uint y ) private pure returns ( bool ) {

        if ( x == y) return true;

        else return _min( x, y ) + 1 == _max( x, y );

    }

    /// @notice it multiply the amount by the respective ERC20 decimal representation
    /// @param _amount the amount to multiply
    /// @param _decimals the decimals representation to multiply 
    function _handleDecimals( uint _amount, uint8 _decimals ) private pure returns ( uint ) {
        
        if ( _decimals > 6 ) return _amount * 10 ** ( _decimals - 6 );

        else return _amount;
        
    }

    /// @notice this returns the maximum tradable amount of the reserves
    /// @param _totalTokenOut the total reserves of the output token
    function maxTrade( uint _totalTokenOut ) public view returns ( uint maxTradeAmount ) {
        
        maxTradeAmount = ( _totalTokenOut * maxTradePercentage ) / 10000;

    }

    /**************************************************************/
    /******************** ESTIMATION FUNCTIONS ********************/

    /// @notice returns how much shares ( LP tokens ) send to user
    /// @dev amount1 and amount2 must have the same proportion in relation to reserves
    /// @dev use this formula to calculate _amountToken1 and _amountToken2
    /// x = totalToken1, y = totalToken2, dx = amount of token 1, dy = amount of token 2
    /// dx = x * dy / y to prioritize amount of token 1
    /// dy = y * dx / x to prioritize amount of token 2
    /// @param _amountToken1 amount of token 1 to add at the pool
    /// @param _amountToken2 amount of token 2 to add at the pool
    function estimateShares( uint _amountToken1, uint _amountToken2 ) public view returns ( uint _shares ) {

        if( totalSupply() == 0 ) {

            require( _amountToken1 == _amountToken2, "Error: Genesis Amounts must be the same" );

            _shares = _amountToken1;

        } else {

            uint share1 = (_amountToken1 * totalSupply()) / totalToken1;

            uint share2 = (_amountToken2 * totalSupply()) / totalToken2;

            require( _isEqual( share1, share2) , "Error: equivalent value not provided");
            
            _shares = _min( share1, share2 );
            
        }

        require( _shares > 0, "Error: shares with zero value" );
        
    }

    /// @notice returns the number of token 1 and token 2 that is send depending on the number of LP tokens given as parameters ( shares )
    /// @param _shares amount of LP tokens to estimate withdrawal
    function estimateWithdrawalAmounts( uint _shares ) public view isActive returns( uint amount1, uint amount2 ) {

        require ( _shares <= totalSupply(), "Error: insufficient pool balance");

        amount1 = ( totalToken1 * _shares ) / totalSupply();

        amount2 = ( totalToken2 * _shares ) / totalSupply();

    }

    /// @notice returns the amount of exit token to send in a trade
    /// @param _amountIn amount of token input 
    /// @param _totalTokenIn total reserves of token input 
    /// @param _totalTokenOut total reserves of token output
    function estimateSwap( uint _amountIn, uint _totalTokenIn, uint _totalTokenOut ) public view returns ( uint amountIn, uint amountOut, uint creatorFee ) {

        require( _amountIn > 0 && _totalTokenIn > 0 && _totalTokenOut > 0, "Swap Error: Input amount with 0 value not valid");
        
        uint amountInWithoutFee = ( _amountIn * ( 10000 - ( tradeFee + protocolFee ) ) ) / 10000;

        creatorFee = ( _amountIn * protocolFee ) / 10000;

        amountIn = _amountIn - creatorFee ;
        
        amountOut = ( _totalTokenOut * amountInWithoutFee ) / ( _totalTokenIn + amountInWithoutFee );

        require( amountOut <= maxTrade( _totalTokenOut ), "Swap Error: output value is greater than the limit");

    }

    /**************************************************************/
    /*********************** VIEW FUNCTIONS ***********************/

    /// @notice it returns the current pool info
    function getPoolInfo() public view returns ( PoolInfo memory _poolInfo ) {

        _poolInfo = PoolInfo({
            token1: token1,
            token2: token2,
            totalToken1: totalToken1,
            totalToken2: totalToken2,
            totalSupply: totalSupply(),
            tradeFee: tradeFee,
            protocolFee: protocolFee,
            maxTradePercentage: maxTradePercentage
        });
    
    }

    /**************************************************************/
    /*********************** SET FUNCTIONS ************************/

    /// @dev to calculate how much pass to the new percentages
    /// percentages precision is on 2 decimal representation so multiply the
    /// percentage by 100, EJ: 0,3 % == 30
    /// @notice set a new protocol fee
    /// @param _newProtocolFee new trade fee percentage
    function setProtocolFee( uint16 _newProtocolFee ) public onlyOwner returns ( bool ) {

        protocolFee = _newProtocolFee;

        emit NewProtocolFee( owner(), _newProtocolFee);

        return true;

    }

    /// @notice set a new trade fee
    /// @param _newTradeFee new trade fee percentage
    function setTradeFee( uint16 _newTradeFee ) public onlyOwner returns ( bool ) {

        tradeFee = _newTradeFee;

        emit NewTradeFee( owner(), _newTradeFee);

        return true;

    }

    /// @notice set a new maximum tradable percentage
    /// @param _newTradePercentage new trade fee percentage
    function setMaxTradePercentage( uint16 _newTradePercentage ) public onlyOwner returns ( bool ) {

        maxTradePercentage = _newTradePercentage;

        emit NewMaxTradePercentage( owner(), _newTradePercentage);

        return true;

    }

    /// @notice set a new fee recipient
    /// @param _newRecipient address of the new recipient
    function setFeeRecipient( address _newRecipient ) public onlyOwner returns( bool ) {

        require( feeRecipient != _newRecipient, "New Recipient can be the same than current");

        feeRecipient = _newRecipient;

        emit NewFeeRecipient( _newRecipient );

        return true;

    }

    /**************************************************************/
    /*********************** POOL FUNCTIONS ***********************/
    
    /// @notice add new liquidity
    /// @dev amount1 and amount2 must have the same proportion in relation to reserves
    /// @dev use this formula to calculate _amountToken1 and _amountToken2
    /// x = totalToken1, y = totalToken2, dx = amount of token 1, dy = amount of token 2
    /// dx = x * dy / y to prioritize amount of token 1
    /// dy = y * dx / x to prioritize amount of token 2
    /// @param _amountToken1 amount of token 1 to add at the pool
    /// @param _amountToken2 amount of token 2 to add at the pool
    /// @return bool returns true on success transaction
    function addLiquidity( uint _amountToken1, uint _amountToken2 ) public returns ( bool )  {

        uint _shares = estimateShares( _amountToken1, _amountToken2 );

        token1.safeTransferFrom( msg.sender, address( this ), _handleDecimals( _amountToken1, token1.decimals() ) );

        token2.safeTransferFrom( msg.sender, address( this ), _handleDecimals( _amountToken2, token2.decimals() ) );

        _mint( msg.sender, _shares );

        _updateBalances( totalToken1 + _amountToken1, totalToken2 + _amountToken2 );

        emit NewLiquidity( msg.sender, _amountToken1, _amountToken2, _shares, totalSupply() );

        return true;

    }

    /// @notice withdraw liquidity
    /// @param _shares amount of LP tokens to withdrawal
    /// @return bool returns true on success transaction
    function withdrawLiquidity( uint _shares ) public isActive checkShares( _shares ) returns ( bool ) {

        ( uint amount1, uint amount2 ) = estimateWithdrawalAmounts( _shares );

        require( amount1 > 0 && amount2 > 0, "Withdraw Error: amounts with zero value");

        token1.safeTransfer( msg.sender, _handleDecimals( amount1, token1.decimals() )  );

        token2.safeTransfer( msg.sender, _handleDecimals( amount2, token2.decimals() ) );

        _burn( msg.sender, _shares);

        _updateBalances( totalToken1 - amount1, totalToken2 - amount2 );

        emit LiquidityWithdrawal( msg.sender, amount1, amount2, _shares, totalSupply() );

        return true;

    }

    /// @notice trade tokens
    /// @param _tokenIn address of the input token 
    /// @param _amountIn amount of input token
    /// @param _minAmountOut The minimum expected that the pool will return to the user
    /// @return bool returns true on success transaction
    function swap( address _tokenIn, uint _amountIn, uint _minAmountOut ) public isActive returns ( bool ) {

        // input token must be one of two the pool tokens

        require( _tokenIn == address(token1) || _tokenIn == address(token2), "Trade Error: invalid token");

        bool isToken1 = _tokenIn == address(token1);

        ( IERC20Metadata tokenIn, IERC20Metadata tokeOut, uint _totalTokenIn, uint _totalTokenOut ) = isToken1 
            ? ( token1, token2, totalToken1, totalToken2 )
            : ( token2, token1, totalToken2, totalToken1 );

        // get trade amounts

        ( uint amountIn, uint amountOut, uint creatorFee ) = estimateSwap( _amountIn, _totalTokenIn, _totalTokenOut );

        require( amountOut >= _minAmountOut, "Trade Error: Output amount is less than expected");

        // send the protocol fee
        
        tokenIn.safeTransferFrom( msg.sender, feeRecipient, _handleDecimals( creatorFee, tokenIn.decimals() ) );

        // receive the input tokens

        tokenIn.safeTransferFrom( msg.sender, address( this ), _handleDecimals( amountIn, tokenIn.decimals() ) );

        // send the tokens to the user

        tokeOut.safeTransfer( msg.sender, _handleDecimals( amountOut, tokeOut.decimals() ) );

        // update current balances

        if ( isToken1 ) _updateBalances( totalToken1 + amountIn, totalToken2 - amountOut );

        else _updateBalances( totalToken1 - amountOut, totalToken2 + amountIn );

        emit Swap( msg.sender, creatorFee, amountIn ,amountOut);

        return true;

    }

}