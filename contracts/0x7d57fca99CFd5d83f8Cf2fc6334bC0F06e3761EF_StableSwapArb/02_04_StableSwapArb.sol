// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "solmate/tokens/ERC20.sol";
import "../src/iSaddleStablePool.sol";
import "../src/iCurvePool.sol";

/// @notice Arbitrageur's interface for interacting with StableSwap contracts.
/// @author Coindex Capital
/// @dev Check readme for more details.
contract StableSwapArb {

    /*//////////////////////////////////////////////////////////////
    //                        ENUMS AND STRUCTS
    //////////////////////////////////////////////////////////////*/

    enum SwapPoolInterface {SADDLE, CURVE}

    /*//////////////////////////////////////////////////////////////
    //                         STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public owner;

    /*//////////////////////////////////////////////////////////////
    //                         CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) payable{
        owner = _owner;
    }

    /*//////////////////////////////////////////////////////////////
    //                         EVENTS
    //////////////////////////////////////////////////////////////*/

    event ExecutedArbitrage(address poolAddress);
    event BalanceWithdraw(address ercAddr, uint256 amount);

    /*//////////////////////////////////////////////////////////////
    //                         ERRORS
    //////////////////////////////////////////////////////////////*/

    error INVALID_ADDRESS(address addr);
    error NOT_AUTHORIZED(address _addr);
    error TIMED_OUT(uint initialBlock, uint finalBlock);
    error MIN_LP_EXPECTED(uint256 expectedLPTokens, uint256 tokensReceived);
    error NOT_IMPLEMENTED();
    error INVALID_SIZES();
    error FAIL_WITHDRAW(address ercAddr, uint256 amount);

    /*//////////////////////////////////////////////////////////////
    //                         MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert NOT_AUTHORIZED(msg.sender);
        _;
    }

    /*//////////////////////////////////////////////////////////////
    //                         VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getOwner() public view returns (address) {
        return owner;
    }

    /*//////////////////////////////////////////////////////////////
    //                         MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes the arbitrage trade
    /// @param _amounts: Amounts of each token to be deposited.
    /// @param _pool_address: The pool's address.
    /// @param _pool_interface: The pool's interface.
    /// @param _lp_token_address: The pool's LP token address (should be ERC20 compliant).
    /// @param _max_block_limit: The minimum block number to be executed
    /// @param _min_lp_token_expected: The minimum amount of LP tokens expected to be received. This serves to prevent bad/late execution.
    function executeArbitrage(
        uint256[] memory _amounts,
        address _pool_address,
        SwapPoolInterface _pool_interface,
        address _lp_token_address,
        address[] memory _tokens,
        uint256 _max_block_limit,
        uint256 _min_lp_token_expected) external onlyOwner
    {
        // Check if pool and lp_token is valid
        if (_pool_address == address(0)) revert INVALID_ADDRESS(_pool_address);
        if (_lp_token_address == address(0)) revert INVALID_ADDRESS(_lp_token_address);
        if (_tokens.length != _amounts.length) revert INVALID_SIZES();

        // Check if current block is less than _max_block_limit
        if (block.number > _max_block_limit) revert TIMED_OUT(_max_block_limit, block.number);

        // Approve tokens to pool
        for (uint i = 0; i < _tokens.length; i++) {
            ERC20 token = ERC20(_tokens[i]);
            if (_amounts[i] > 0) {
                token.approve(_pool_address, _amounts[i]);
            }
        }

        if (_pool_interface == SwapPoolInterface.SADDLE) {
            iSaddleStablePool poolContract = iSaddleStablePool(_pool_address);

            uint256 new_lp = poolContract.addLiquidity(_amounts, 0, block.timestamp + 5);

            // Check if _min_lp_token_expected is greater or equal than the amount of LP tokens received
            if (new_lp < _min_lp_token_expected) revert MIN_LP_EXPECTED(_min_lp_token_expected, new_lp);

            // Execute Arbitrage
            ERC20 lp_token = ERC20(_lp_token_address);
            lp_token.approve(_pool_address, new_lp);
            uint256[] memory min_amounts = new uint256[](_tokens.length);
            poolContract.removeLiquidity(new_lp, min_amounts, block.timestamp + 5);

        } else if (_pool_interface == SwapPoolInterface.CURVE) {
            CurvePool poolContract = CurvePool(_pool_address);

            uint256 new_lp = poolContract.add_liquidity(_amounts, 0);

            // Check if _min_lp_token_expected is greater or equal than the amount of LP tokens received
            if (new_lp < _min_lp_token_expected) revert MIN_LP_EXPECTED(_min_lp_token_expected, new_lp);

            // Execute Arbitrage
            ERC20 lp_token = ERC20(_lp_token_address);
            lp_token.approve(_pool_address, new_lp);
            uint256[] memory min_amounts = new uint256[](_tokens.length);
            poolContract.remove_liquidity(new_lp, min_amounts);
        } else {
            revert NOT_IMPLEMENTED();
        }

        // Emit event
        emit ExecutedArbitrage(_pool_address);
    }

    /// @notice Destroy current contract and return resources to owner.
    function self_destroy() external onlyOwner
    {
        selfdestruct(payable(owner));
    }

    /// @notice Withdraws ERC20 token from the contract to owner.
    /// @param _token_address: The token's address.
    function withdrawToken(address _token_address) external onlyOwner
    {
        ERC20 token = ERC20(_token_address);
        uint256 balance = token.balanceOf(address(this));
        bool success = token.transfer(owner, balance);
        if (!success) revert FAIL_WITHDRAW(_token_address, balance);
        emit BalanceWithdraw(_token_address, balance);
    }

    /// @notice Payable function to receive native blockchain tokens (e.g. ETH, MATIC, etc).
    receive() external payable {}
    fallback() external payable {}
}