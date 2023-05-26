// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Interfaces/IWETH.sol";
import "./Interfaces/IWHAsset.sol";
import "./Interfaces/IWHSwapRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@sushiswap/core/contracts/uniswapv2/libraries/TransferHelper.sol";
import "@sushiswap/core/contracts/uniswapv2/libraries/UniswapV2Library.sol";

/**
 * @author jmonteer
 * @title Whiteheart's Swap+Wrap router using Uniswap-like DEX
 * @notice Contract performing a swap and sending the output to the corresponding WHAsset contract for it to be wrapped into a Hedge Contract
 */
contract WHSwapRouter is IWHSwapRouter, Ownable {
    address public immutable factory; 
    address public immutable WETH;

    // Maps the underlying asset to the corresponding Hedge Contracts
    mapping(address => address) public whAssets;
    
    /**
     * @notice Constructor
     * @param _factory DEX factory contract 
     * @param _WETH Ether ERC20's token address
     */
    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    /**
     * @notice Adds an entry to the underlyingAsset => WHAsset contract. It can be used to set the underlying asset to 0x0 address
     * @param token Asset address
     * @param whAsset WHAsset contract for the underlying asset
     */
    function setWHAsset(address token, address whAsset) external onlyOwner {
        whAssets[token] = whAsset;
    }

    /**
     * @notice Function used by WHAsset contracts to swap underlying assets into USDC, to buy options. Same function than "original" router's function
     * @param amountIn amount of the token being swap
     * @param amountOutMin minimum amount of the asset to be received from the swap
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'insufficient_output_amount');        

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    /**
     * @notice Custom function for swapExactTokensForTokens that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountIn amount of the token being swap
     * @param amountOutMin minimum amount of the asset to be received from the swap
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapExactTokensForTokensAndWrap(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to, 
        uint deadline,
        uint protectionPeriod,
        bool mintToken,
        uint minUSDCPremium
    ) external virtual override ensure(deadline) returns (uint[] memory amounts, uint newTokenId){
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'insufficient_output_amount');        
        
        {
            address[] calldata _path = path;
            TransferHelper.safeTransferFrom(
                _path[0], msg.sender, UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]
            );
        }

        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);
    }

    /**
     * @notice Custom function for swapTokensForExactTokens that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountOut exact amount of output asset expected
     * @param amountInMax maximum amount of tokens to be sent to the DEX
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapTokensForExactTokensAndWrap(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        uint protectionPeriod,
        bool mintToken,
        uint minUSDCPremium
    ) external virtual override ensure(deadline) returns (uint[] memory amounts, uint newTokenId) {
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'excessive_input_amount');
        {
            address[] calldata _path = path;
            TransferHelper.safeTransferFrom(
                _path[0], msg.sender, UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]
            );
        }
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);
    }

    /**
     * @notice Custom function for swapExactETHForTokens that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountOutMin minimum amount of the asset to be received from the swap
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapExactETHForTokensAndWrap(uint amountOutMin, address[] calldata path, address to, uint deadline, uint protectionPeriod,
        bool mintToken, uint minUSDCPremium)
        external
        virtual
        payable
        override
        ensure(deadline)
        returns (uint[] memory amounts, uint newTokenId)
    {           
        address[] memory _path = path; // to avoid stack too deep
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, _path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'insufficient_input_amount');

        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]));   
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);

    }

    /**
     * @notice Custom function for swapETHForExactTokens that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountOut amount of the token being swap
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapETHForExactTokensAndWrap(uint amountOut,
        address[] calldata path,
        address to,
        uint deadline,
        uint protectionPeriod,
        bool mintToken,
        uint minUSDCPremium
    )
        external
        virtual
        payable
        override
        ensure(deadline)
        returns (uint[] memory amounts, uint newTokenId)
    {
        address[] memory _path = path; // to avoid stack too deep
        require(_path[0] == WETH, 'invalid_path');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, _path);
        require(amounts[0] <= msg.value, 'excessive_input_amount');

        IWETH(WETH).deposit{value: amounts[0]}();
        {
            assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]));
        }

        if(msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);
    }

    /**
     * @notice Custom function for swapExactTokensForETH that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountIn amount of the token being swapped
     * @param amountOutMin minimum amount of the output asset to be received
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapExactTokensForETHAndWrap(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint protectionPeriod,
        bool mintToken, uint minUSDCPremium)
        external
        override
        ensure(deadline)
        returns(uint[] memory amounts, uint newTokenId) 
    {
        require(path[path.length - 1] == WETH, 'invalid_path');

        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "insufficient_output_amount");
        {
            address[] calldata _path = path;
            TransferHelper.safeTransferFrom(
                _path[0], msg.sender, UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]
            );
        }        
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);

    }

    /**
     * @notice Custom function for swapTokensForExactETH that wraps the output asset into a Hedge Contract (underlying asset + ATM put option)
     * @param amountOut amount of the output asset to be received
     * @param amountInMax maximum amount of input that user is willing to send to the contract to reach amountOut 
     * @param path ordered list of assets to be swap from, to
     * @param to recipient address of the output of the swap
     * @param deadline maximum timestamp to process the transaction
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
     */
    function swapTokensForExactETHAndWrap(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline, uint protectionPeriod,
        bool mintToken, uint minUSDCPremium)
        external
        override
        ensure(deadline)
        returns (uint[] memory amounts, uint newTokenId)
    {
        require(path[path.length - 1] == WETH, 'invalid_path');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'excessive_input_amount');
        {
            address[] calldata _path = path;
            TransferHelper.safeTransferFrom(
                _path[0], msg.sender, UniswapV2Library.pairFor(factory, _path[0], _path[1]), amounts[0]
            );
        } 
        newTokenId = _swapAndWrap(path, amounts, protectionPeriod, to, mintToken, minUSDCPremium);

    }

    /**
     * @notice Internal function to be called after all swap params have been calc'd. it performs a swap and sends output to corresponding WHAsset contract
     * @param path ordered list of assets to be swap from, to
     * @param amounts list of amounts to send/receive of each of path's asset
     * @param protectionPeriod amount of seconds during which the underlying amount is going to be protected
     * @param mintToken boolean that tells the WHAsset contract whether or not to mint an ERC721 token representing new Hedge Contract
    */
    function _swapAndWrap(address[] calldata path, uint[] memory amounts, uint protectionPeriod, address to, bool mintToken, uint minUSDCPremium) 
        internal
        returns (uint newTokenId)
    {
        address whAsset = whAssets[path[path.length - 1]];
        require(whAsset != address(0), 'whAsset_does_not_exist');
        _swap(amounts, path, whAsset);
        newTokenId = IWHAssetv2(whAsset).wrapAfterSwap(amounts[amounts.length - 1], protectionPeriod, to, mintToken, minUSDCPremium);
    }

    /**
     * @notice Internal function to be called for actually swapping the involved assets. requires the initial amount to have already been sent to the first pair
     * @param amounts list of amounts to send/receive of each of path's asset
     * @param path ordered list of assets to be swap from, to
     * @param _to recipient of swap's output
      */
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for(uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, )  = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    // **** LIBRARY FUNCTIONS **** 
    // from original Uniswap router
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }
}