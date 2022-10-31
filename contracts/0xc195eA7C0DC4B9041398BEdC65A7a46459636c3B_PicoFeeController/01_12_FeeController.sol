// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IAggregationRouterV4.sol";
import "./interfaces/IUniswapV3PoolImmutables.sol";

/**
 * @notice Contract perform swap of tokens using 1inch and also deduct Fee Percentage as described
 * by the owner. 1inch uses mulitple protocols or exchanges to get the swap at best price.
 * @dev Contract uses 1inch Aggregation Router for token swap depends on route data and exchange, contract
 * also have feature to set fees percent and also collect Eth and token Fees for Owner.
 * Refer for AggegationRouter:https://bscscan.com/address/0x1111111254fb6c44bAC0beD2854e76F90643097d#code
 * Refer: https://docs.1inch.io/docs/aggregation-protocol/smart-contract/AggregationRouterV4
 * Contract uses Ownable, ReentrancyGuard and Pausable library for for Owner Rights and Security Concerns.
 */
contract PicoFeeController is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    uint256 private constant _ONE_FOR_ZERO_MASK = 1 << 255;
    uint256 private constant _WETH_WRAP_MASK = 1 << 254;

    IERC20 private constant _ETH_ADDRESS =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 private constant _ZERO_ADDRESS = IERC20(address(0));

    address public aggregationRouter;

    uint16 public constant denominator = 10000;

    uint16 public feesPercentage;

    event FeesCollected(
        address indexed accountAddress,
        IERC20 fromTokenAddress,
        IERC20 toTokenAddress,
        uint256 swapAmount,
        uint256 feeAmount
    );

    /**
     * @dev constructor initalizes the aggregation router and percentage(in basis points).
     * Eg- For 1.24% fees percentage basis points is 124.
     * AggregationRouterV4 address is deployed at - 0x1111111254fb6c44bAC0beD2854e76F90643097d
     * Refer: https://bscscan.com/address/0x1111111254fb6c44bAC0beD2854e76F90643097d#code
     */
    constructor(address _aggregationRouter, uint16 _percentage) {
        require(
            _aggregationRouter != address(0),
            "Enter a valid aggregation Router Address"
        );
        aggregationRouter = _aggregationRouter;
        feesPercentage = _percentage;
    }

    receive() external payable {}

    /**
     * @dev Function to set Fee Percentage(only in basis points). For eg- For 1.24%, parameter will
     * take 124 as number for fee Percent. Only the owner of contract can set fee Percentage
     * @param _newPercentage New fees Percent(in basis points) that owner can set.
     */

    function setFeePercentage(uint16 _newPercentage) external onlyOwner {
        feesPercentage = _newPercentage;
    }

    /**
     * @dev Function to change Aggregation Router Address. Currently, Aggregation
     * Router Version 4 is deployed by 1inch, but if aggregation router version
     * is updated in future by 1inch, the function can update the aggregation router
     * address
     * @param _aggregationRouter New aggregation router address that owner can set.
     */

    function updateAggregationRouter(address _aggregationRouter)
        external
        onlyOwner
    {
        require(
            _aggregationRouter != address(0),
            "Enter a valid aggregation Router Address"
        );
        aggregationRouter = _aggregationRouter;
    }

    /**
     * @dev Function to collect token fees stored in contract's address for all tokens.
     * Tokens are transferd to owner's account address. Only be called by the owner of the contract.
     * @param _tokenAddress Token Address owner want to collect.
     */
    function collectTokensFee(address[] calldata _tokenAddress)
        external
        onlyOwner
    {
        require(_tokenAddress.length < 30, "limit exceeded");
        uint256 balance;
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            balance = IERC20(_tokenAddress[i]).balanceOf(address(this));
            IERC20(_tokenAddress[i]).safeTransfer(msg.sender, balance);
        }
    }

    /**
     * @dev Function to collect Eth fees stored in contract's address. Can only be called by the
     * owner of the contract
     */
    function collectEthfee() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "transfer failed");
    }

    /**
     *@notice used to pause smart contract's swap functions
     *@dev only owner can call the pause function
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     *@notice used to unpause smart contract's swap functions
     *@dev only owner can call the unpause function
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Calls if route of swap involves all protocol Exchanges (except uniswap,
     * uniswapV3 and clipperswap) for tokens swap using 1inch.
     * @dev Encoded data gets decoded for Excutor or caller, swap description and route data.
     * Refer: https://docs.1inch.io/docs/aggregation-protocol/smart-contract/AggregationRouterV4 for more
     * information related to each parameter
     * Function fetches Balance of source token & destination token in contract's address
     *  before swap by calling _intialProcessing function,
     * checks if Eth is in any source token or destination token, based on that
     * calls 1inch's Aggregation Router swap function with token amount for swap. And then
     * calls _finalProcessing function to transfer destination token & token amount after swap.
     * Refer above link for more information related to swap function on Aggregation Router.
     * @param data Encoded bytes data which includes swap information, caller
     * address, swap route and other Swap Description parameters.
     */

    function swap(bytes calldata data)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        (
            IAggregationExecutor executor,
            IAggregationRouterV4.SwapDescription memory desc,
            bytes memory _data
        ) = abi.decode(
                data[4:],
                (
                    IAggregationExecutor,
                    IAggregationRouterV4.SwapDescription,
                    bytes
                )
            );
        require(desc.minReturnAmount > 0, "Minimum return should not be zero");
        require(
            desc.dstReceiver == address(this),
            "another reciever not supported"
        );
        (uint256 balanceBefore, bool isEthDst) = _initialProcessing(
            desc.srcToken,
            desc.dstToken,
            desc.amount
        );
        if (_isETH(desc.srcToken)) {
            IAggregationRouterV4(aggregationRouter).swap{value: desc.amount}(
                executor,
                desc,
                _data
            );
        } else {
            IAggregationRouterV4(aggregationRouter).swap(executor, desc, _data);
        }

        _finalProcessing(
            desc.dstToken,
            isEthDst,
            balanceBefore,
            desc.minReturnAmount
        );
    }

    /**
     * @notice Calls if route of swap involves Uniswap Exchange for tokens swap using 1inch.
     * @dev Encoded data gets decoded for amount, minReturnAmount, pools and source token.
     * Refer: https://docs.1inch.io/docs/aggregation-protocol/smart-contract/UnoswapRouter for more
     * information related to each parameter
     * Function fetches Balance of source token & destination token in contract's address
     *  before swap by calling _intialProcessing function,
     * checks if Eth is in any source token or destination token, based on that
     * calls 1inch's Aggregation Router unoswap function with token amount for swap. And then
     * calls _finalProcessing function to transfer destination token & token amount after swap.
     * Refer above link for more information related to unoswap function on Aggregation Router.
     * @param data Encoded bytes data which includes swap information related to token amount, caller
     * address, swap route and other Swap Description parameters.
     * @param dstToken Destination Token Address as IERC20 type. Destination token is token which
     * user will get after swap.
     */

    function uniswapSwap(bytes calldata data, address dstToken)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        (
            IERC20 srcToken,
            uint256 amount,
            uint256 minReturnAmount,
            bytes32[] memory pools
        ) = abi.decode(data[4:], (IERC20, uint256, uint256, bytes32[]));
        require(minReturnAmount > 0, "Minimum return should not be zero");
        (uint256 balanceBefore, bool isEthDst) = _initialProcessing(
            srcToken,
            IERC20(dstToken),
            amount
        );

        if (_isETH(srcToken)) {
            IAggregationRouterV4(aggregationRouter).unoswap{value: amount}(
                IERC20(srcToken),
                amount,
                minReturnAmount,
                pools
            );
        } else {
            IAggregationRouterV4(aggregationRouter).unoswap(
                IERC20(srcToken),
                amount,
                minReturnAmount,
                pools
            );
        }

        _finalProcessing(
            IERC20(dstToken),
            isEthDst,
            balanceBefore,
            minReturnAmount
        );
    }

    /**
     * @notice Calls if route of swap involves UniswapV3 Exchange for tokens swap using 1inch.
     * @dev Encoded data gets decode for amount, minReturnAmount and pools.
     * Refer: https://docs.1inch.io/docs/aggregation-protocol/smart-contract/UnoswapV3Router for more
     * information related to each parameter
     * Function fetches Balance of source token & destination token before swap by calling
     *  _intialProcessing, checks if Eth is in any source token or destination token, based on that
     * calls 1inch's Aggregation Router uniswapV3swap function with token amount for swap. And then
     * calls _finalProcessing function to transfer destination token & token amount after swap.
     * Refer above link for more information related to uniswapV3 swap function on Aggregation Router.
     * @param data Encoded bytes data which includes swap information related to token amount, caller
     * address, swap route and other Swap Description parameters.
     * @param dstToken Destination Token Address as IERC20 type. Destination token is token which
     * user will get after swap.
     */

    function uniswapV3Swap(bytes calldata data, address dstToken)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        (uint256 amount, uint256 minReturnAmount, uint256[] memory pools) = abi
            .decode(data[4:], (uint256, uint256, uint256[]));
        require(minReturnAmount > 0, "Minimum return should not be zero");
        IERC20 srcToken;
        bool wrapWeth = pools[0] & _WETH_WRAP_MASK > 0;
        if (wrapWeth) {
            srcToken = _ETH_ADDRESS;
        } else {
            bool zeroForOne = pools[0] & _ONE_FOR_ZERO_MASK == 0;
            address tokenPool = address(uint160(pools[0]));
            if (zeroForOne) {
                srcToken = IERC20(IUniswapV3PoolImmutables(tokenPool).token0());
            } else {
                srcToken = IERC20(IUniswapV3PoolImmutables(tokenPool).token1());
            }
        }

        (uint256 balanceBefore, bool isEthDst) = _initialProcessing(
            srcToken,
            IERC20(dstToken),
            amount
        );
        if (_isETH(IERC20(srcToken))) {
            IAggregationRouterV4(aggregationRouter).uniswapV3Swap{
                value: amount
            }(amount, minReturnAmount, pools);
        } else {
            IAggregationRouterV4(aggregationRouter).uniswapV3Swap(
                amount,
                minReturnAmount,
                pools
            );
        }

        _finalProcessing(
            IERC20(dstToken),
            isEthDst,
            balanceBefore,
            minReturnAmount
        );
    }

    /**
     * @notice Calls if route of swap involves Clipper Exchange for tokens swap using 1inch.
     * @dev Function fetches Balance of source token & destination token before swap by calling
     *  _intialProcessing, checks if Eth is in any source token or destination token, based on that
     * calls 1inch's Aggregation Router clipperswap function with token amount for swap. And then
     * calls _finalProcessing function to transfer token amount after swap.
     * Refer: https://docs.1inch.io/docs/aggregation-protocol/smart-contract/ClipperRouter for more
     * information related to clipperswap function on Aggregation Router.
     * @param srcToken Source Token Address as IERC20 type. Source Token is token which user want to swap.
     * @param dstToken Destination Token Address as IERC20 type. Destination token is token which
     * user will get after swap.
     * @param amount Token Amount
     * @param minReturn Minimum Return Amount
     */

    function clipperSwap(
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 amount,
        uint256 minReturn
    ) external payable nonReentrant whenNotPaused {
        require(minReturn > 0, "Minimum return should not be zero");

        (uint256 balanceBefore, bool isEthDst) = _initialProcessing(
            srcToken,
            dstToken,
            amount
        );

        if (_isETH(srcToken)) {
            IAggregationRouterV4(aggregationRouter).clipperSwap{value: amount}(
                srcToken,
                dstToken,
                amount,
                minReturn
            );
        } else {
            IAggregationRouterV4(aggregationRouter).clipperSwap(
                srcToken,
                dstToken,
                amount,
                minReturn
            );
        }

        _finalProcessing(dstToken, isEthDst, balanceBefore, minReturn);
    }

    /**
     * @dev Function stores balance of eth or token from contract's address before swap and calls for
     * _processTransferandApproval function with amount & source token address.
     * @param _srcToken Source Token Address as IERC20 type. Source Token is token which user want to swap.
     * @param _dstToken Destination Token Address as IERC20 type. Destination token is token which
     * user will get after swap.
     * @param _amount Token Amount
     * @return _balanceBefore Returns amount of eth or Token in contract's address before swap.
     * @return _isEthDst Returns bool as 'true' if eth is Destination Address else 'false' for other
     * token address
     */

    function _initialProcessing(
        IERC20 _srcToken,
        IERC20 _dstToken,
        uint256 _amount
    ) internal returns (uint256 _balanceBefore, bool _isEthDst) {
        uint256 actualAmount = _calculateAmountWithFees(_amount);

        if (_isETH(_srcToken)) {
            _balanceBefore = _fetchTokenBalance(address(_dstToken));
            require(msg.value == actualAmount, "less input tokens");
        } else {
            _isEthDst = _isETH(_dstToken);
            if (_isEthDst) {
                _balanceBefore = _fetchETHBalance();
            } else {
                _balanceBefore = _fetchTokenBalance(address(_dstToken));
            }
            _processTransferAndApproval(
                address(_srcToken),
                actualAmount,
                _amount
            );
        }
        emit FeesCollected(
            msg.sender,
            _srcToken,
            _dstToken,
            _amount,
            (actualAmount - _amount)
        );
    }

    /**
     * @dev Function stores balance after swap based on Eth is Destination Address or not. Checks
     * condition for slippage and transfer Eth or Token back to 'caller'
     * @param _dstToken Destination Token Address as IERC20 type.
     * @param _isEthDst 'bool' input as 'true' if Destination Address is eth Address else 'false'
     * @param _balanceBefore Actual token Balance before swap
     * @param _minReturn Minimum Return Amount
     */

    function _finalProcessing(
        IERC20 _dstToken,
        bool _isEthDst,
        uint256 _balanceBefore,
        uint256 _minReturn
    ) internal {
        uint256 _balanceAfter;
        if (_isEthDst) {
            _balanceAfter = _fetchETHBalance();
        } else {
            _balanceAfter = _fetchTokenBalance(address(_dstToken));
        }

        require(
            (_balanceAfter - _balanceBefore) >= _minReturn,
            "slippage too high"
        );

        if (_isEthDst) {
            payable(msg.sender).transfer(_balanceAfter - _balanceBefore);
        } else {
            _dstToken.safeTransfer(
                msg.sender,
                (_balanceAfter - _balanceBefore)
            );
        }
    }

    /**
     * @dev Function transfers the token amount from 'caller' to contract's address.
     * Approves for Aggregation Router of 1inch with 'zero' amount as to change the approve amount
     * you first have to reduce the addresses` allowance to zero by calling `approve(_spender, 0)`
     *  if it is not already 0 to mitigate the race condition described here:
     *  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * Approves for Aggregation Router of 1inch with amount to swap.
     * @param _token Token Address
     * @param _actualAmount Entire Token Amount
     * @param _amount Swap Amount
     */

    function _processTransferAndApproval(
        address _token,
        uint256 _actualAmount,
        uint256 _amount
    ) internal {
        IERC20(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _actualAmount
        );
        IERC20(_token).safeApprove(aggregationRouter, 0);
        IERC20(_token).safeApprove(aggregationRouter, _amount);
    }

    /**
     * @dev Function calculates the Amount with Fees included. Calculates using denominator value declared
     * as constant which is '10000' and feesPercentage which is initalized by the Owner(in basis points).
     * Eg- Suppose if amount is '1000' and feePercentage is 2% (200 basis points) then function will
     * calculate as (1000 * 10000) / (10000 - 200) which will be (approx) 1020.
     * @param  _amount Token Amount
     * @return Returns Amount with Fees included.
     */

    function _calculateAmountWithFees(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        return (_amount * denominator) / (denominator - feesPercentage);
    }

    /**
     * @dev Function to fetch Token balance from the contract's address.
     * @param _token Address
     * @return Return token amount balance in the contract's address.
     */

    function _fetchTokenBalance(address _token)
        internal
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(address(this));
    }

    /**
     * @dev Function to fetch ether balance from the contract's address.
     * @return Return number of Ether amount stored in the contract's address.
     */

    function _fetchETHBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Function with input parameter as ERC20 token returns 'bool' as 'true' if token address is
     * is zero address or default eth address  else returns 'false' for any other address.
     * @param _token Token Address as IERC20 type.
     * @return Returns 'bool' as 'true' for eth address and zero address else returns 'false'
     */

    function _isETH(IERC20 _token) internal pure returns (bool) {
        return (_token == _ZERO_ADDRESS || _token == _ETH_ADDRESS);
    }
}