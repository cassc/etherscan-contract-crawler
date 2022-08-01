// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "FlashLoanReceiverBaseV2.sol";
import "Withdrawable.sol";
import "IUniswapV2Pair.sol";
import "IUniswapV2Router02.sol";
import "IUniswapV2Factory.sol";
import "IERC20.sol";


contract FlashloanV2 is FlashLoanReceiverBaseV2, Withdrawable {

    address immutable uniswapRouterAddress;
    address immutable sushiswapRouterAddress;

    constructor(
        address _AaveaddressProvider, 
        address _uniswapRouterAddress,
        address _sushiswapRouterAddress
    ) FlashLoanReceiverBaseV2(_AaveaddressProvider) {
        uniswapRouterAddress = _uniswapRouterAddress;
        sushiswapRouterAddress = _sushiswapRouterAddress;
    }

    enum Exchange {
        UNISWAP,
        SUSHI,
        NONE
    }


    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address /* initiator */,
        bytes calldata params 
    )
        external
        override
        returns (bool)
    {
        address borrowedAsset = assets[0];
        uint borrowedAmount = amounts[0];
        uint premiumAmount = premiums[0];
        
        // This contract now has the funds requested.
        // Your logic goes here.
        require(msg.sender == address(LENDING_POOL), "Not pool");

        (address swappingPair) = abi.decode(params, (address));

        makeArbitrage(borrowedAsset, borrowedAmount, swappingPair);

        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.
        
        // Approve the LendingPool contract allowance to *pull* the owed amount
        //Use this logic when you have multiple assets
        // for (uint i = 0; i < assets.length; i++) {
        //     uint amountOwing = amounts[i].add(premiums[i]);
        //     IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        // }

        uint amountOwing = borrowedAmount + premiumAmount;
        IERC20(borrowedAsset).approve(address(LENDING_POOL), amountOwing);        
        return true;
    }


    function startTransaction(address _borrowAsset, uint256 _borrowAmount, address _swappingPair, address _factoryAddress) public onlyOwner{

        // Get pool address and check if it exists
        address poolAddress = IUniswapV2Factory(_factoryAddress).getPair(
            _borrowAsset,
            _swappingPair
        );

        require(poolAddress != address(0), "PairAddress does not exist!");

        bytes memory _params = abi.encode(_swappingPair);

        address[] memory assets = new address[](1);
        assets[0] = _borrowAsset;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _borrowAmount;

        _flashloan(assets, amounts, _params);
    }


    function _flashloan(address[] memory assets, uint256[] memory amounts, bytes memory params) internal {
        //We send the flashloan amount to this contract (receiverAddress) so we can make the arbitrage trade

        address receiverAddress = address(this);

        address onBehalfOf = address(this);
        // bytes memory params = "";
        uint16 referralCode = 0;

        uint256[] memory modes = new uint256[](assets.length);

        // 0 = no debt (flash), 1 = stable, 2 = variable
        for (uint256 i = 0; i < assets.length; i++) {
            modes[i] = 0;
        }

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }


    function makeArbitrage(address _borrowedAsset, uint _borrowedAmount, address _swappingPair) internal returns(uint256){

        //Write a better comparePrice function
        Exchange result = _comparePrice(_borrowedAmount, _borrowedAsset, _swappingPair);
        uint amountFinal;
        if (result == Exchange.UNISWAP) {

            // e.g sell WETH in uniswap for DAI with high price and buy WETH from sushiswap with lower price
            uint256 amountOut = _swapTokens(
                _borrowedAmount,
                uniswapRouterAddress,
                _borrowedAsset,
                _swappingPair
            );

            amountFinal = _swapTokens(
                amountOut,
                sushiswapRouterAddress,
                _swappingPair,
                _borrowedAsset
            );
        } else if (result == Exchange.SUSHI) {
            
            // e.g sell WETH in sushiswap for DAI with high price and buy WETH from uniswap with lower price
            uint256 amountOut = _swapTokens(
                _borrowedAmount,
                sushiswapRouterAddress,
                _borrowedAsset,
                _swappingPair
            );
            
            amountFinal = _swapTokens(
                amountOut,
                uniswapRouterAddress,
                _swappingPair,
                _borrowedAsset
            );
        }else{
            revert();
        }

        return amountFinal;
    }


    //This compares the prices of the assets on the individual exchanges i.e Uniswap and Sushiswap
    function _comparePrice(uint256 _amount, address _firstToken, address _secondToken) internal view returns (Exchange) {
        uint256 uniswapPrice = _getPrice(
            uniswapRouterAddress,
            _firstToken, //sell token
            _secondToken, //buy token
            _amount
        );

        uint256 sushiswapPrice = _getPrice(
            sushiswapRouterAddress,
            _firstToken, //sell token
            _secondToken, //buy token
            _amount
        );

        // we try to sell ETH with higher price and buy it back with low price to make profit
        if (uniswapPrice > sushiswapPrice) {
            require(
                _checkIfArbitrageIsProfitable(
                    _amount,
                    uniswapPrice,
                    sushiswapPrice
                ),
                "Arbitrage not profitable"
            );
            return Exchange.UNISWAP;
        } else if (uniswapPrice < sushiswapPrice) {
            require(
                _checkIfArbitrageIsProfitable(
                    _amount,
                    sushiswapPrice,
                    uniswapPrice
                ),
                "Arbitrage not profitable"
            );
            return Exchange.SUSHI;
        } else {
            return Exchange.NONE;
        }
    }


    function _swapTokens(
        uint256 amountIn,
        address routerAddress,
        address sell_token,
        address buy_token
    ) internal returns (uint256) {
        IERC20(sell_token).approve(routerAddress, amountIn);

        uint256 amountOutMin = (_getPrice(
            routerAddress,
            sell_token,
            buy_token,
            amountIn
        ) * 95) / 100; //Meaning I am expecting to receive at least 95% of the price out.

        address[] memory path = new address[](2);
        path[0] = sell_token;
        path[1] = buy_token;

        uint256 amountReceived = IUniswapV2Router02(routerAddress)
            .swapExactTokensForTokens(
                amountIn, /**+-Amount of Tokens we are going to Sell.*/
                amountOutMin, /**+-Minimum Amount of Tokens that we expect to receive in exchange for our Tokens.*/
                path, /**+-We tell SushiSwap what token to sell and what token to Buy.*/
                address(this), /**+-Address of where the Output Tokens are going to be received. i.e this contract address(this) */
                block.timestamp + 300 /**+-Time Limit after which an order will be rejected by SushiSwap(It is mainly useful if you send an Order directly from your wallet).*/
            )[1];
        return amountReceived;
    }


    function _checkIfArbitrageIsProfitable(
        uint256 amountIn,
        uint256 higherPrice,
        uint256 lowerPrice
    ) internal pure returns (bool) {
        // Uniswap & Sushiswap have 0.3% fee for every exchange
        // so gain made must be greater than 2 * 0.3% * arbitrage_amount 
        //This means 0.3% for Uniswap and another 0.3% for Sushiswap
        // 0.3 percent means 0.003 or 3/1000

        // difference in ETH
        //Also, here implies that you are getting the value in wei amount.
        //After that, then dividing a wei value by an eth value *higherPrice*, means that we are essentially getting (How many eth is in that wei value)
        // put simply, Wei/eth = how any eth is in the wei
        uint256 difference = ((higherPrice - lowerPrice) * 10**18) /
            higherPrice;

        //Remember, Solidity does not deal with decimals so that is why we are dividing by 1000
        // 0.3 percent means 0.003 or 3/1000
        uint256 paid_fee = (2 * (amountIn * 3)) / 1000;

        //Eth amount minus another Eth
        if (difference > paid_fee) {
            return true;
        } else {
            return false;
        }
    }

    function _getPrice(
        address routerAddress,
        address sell_token,
        address buy_token,
        uint256 amount
    ) internal view returns (uint256) {
        address[] memory pairs = new address[](2);
        pairs[0] = sell_token;
        pairs[1] = buy_token;
        uint256 price = IUniswapV2Router02(routerAddress).getAmountsOut(
            amount,
            pairs
        )[1];

        //The return price is in Eth...So you can always multiply by 10**18 to convert to wei
        return price;
    }

}