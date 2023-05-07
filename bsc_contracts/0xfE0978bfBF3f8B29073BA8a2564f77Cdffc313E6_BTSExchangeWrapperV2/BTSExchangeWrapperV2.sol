/**
 *Submitted for verification at BscScan.com on 2023-05-06
*/

pragma solidity ^0.8;

interface IUniswapRouter02 {
    function getAmountsOut(uint, address[] memory) external view returns (uint[] memory);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint, address[] calldata, address, uint) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint, uint, address[] calldata, address, uint) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint, uint, address[] calldata, address, uint) external;
    function WETH() external pure returns (address);
}

interface IERC20 {
    function approve(address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

contract BTSExchangeWrapperV2 {
    IUniswapRouter02 uniswapRouter = IUniswapRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public WETH = uniswapRouter.WETH();

    struct TradingStatus {
        uint expectedToken;
        uint receivedToken;
        uint gasUsedBuying;
        uint expectedBaseToken;
        uint receivedBaseToken;
        uint gasUsedSelling;
    }

    receive() external payable {}

    function getPathFromTokenToToken(address _token1, address _token2) private pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _token1;
        path[1] = _token2;
        
        return path;
    }
    
    function buyTokens(
        uint _buyAmount,
        address _baseToken,
        address _snipeToken,
        address _destinationAddress,
        uint _txDeadline
    ) external payable {
        address[] memory path = getPathFromTokenToToken(_baseToken, _snipeToken);

        if (_baseToken == WETH) {
            uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                _buyAmount, 
                path,
                _destinationAddress,
                _txDeadline
            );
        }
        
        else {
            IERC20(_baseToken).approve(address(uniswapRouter), type(uint).max);

            uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _buyAmount,
                0,
                path,
                _destinationAddress,
                _txDeadline
            );
        }
    }

    function sellTokens(
        uint _sellAmount,
        address _baseToken,
        address _snipeToken,
        address _destinationAddress
    ) external {
        IERC20(_snipeToken).approve(address(uniswapRouter), type(uint).max);

        if (_baseToken == WETH)
            uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                _sellAmount,
                0,
                getPathFromTokenToToken(_snipeToken, _baseToken),
                _destinationAddress,
                type(uint).max
            );
        
        else 
            uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _sellAmount,
                0,
                getPathFromTokenToToken(_snipeToken, _baseToken),
                _destinationAddress,
                type(uint).max
            );
    }

    function getTokenValue(uint _tokenBalance, address _baseToken, address _snipeToken) external view returns (uint) {
        return uniswapRouter.getAmountsOut(
            _tokenBalance, 
            getPathFromTokenToToken(_snipeToken, _baseToken)
        )[1];
    }

    function checkTradingStatus(address _baseToken, address _snipeToken) public payable returns (TradingStatus memory) {
        IERC20 baseToken = IERC20(_baseToken);
        IERC20 snipeToken = IERC20(_snipeToken);

        address[] memory buyPath = getPathFromTokenToToken(_baseToken, _snipeToken);
        address[] memory sellPath = getPathFromTokenToToken(_snipeToken, _baseToken);

        uint expectedSnipeTokenAmount = uniswapRouter.getAmountsOut(msg.value, buyPath)[1];

        baseToken.approve(address(uniswapRouter), type(uint).max);
        snipeToken.approve(address(uniswapRouter), type(uint).max);
 
        uint gasLeftBeforeBuying = gasleft();

        if (_baseToken == WETH) {
            uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                0, 
                buyPath, 
                address(this), 
                block.timestamp
            );
        }
        
        else {
            baseToken.transferFrom(msg.sender, address(this), msg.value);

            uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                msg.value,
                0,
                buyPath,
                address(this),
                block.timestamp
            );
        }
        
        uint gasLeftAfterBuying = gasleft();
        
        uint receivedSnipeTokenAmount = snipeToken.balanceOf(address(this));
        uint expectedBaseTokenAmount = uniswapRouter.getAmountsOut(receivedSnipeTokenAmount, sellPath)[1];
        
        uint gasLeftBeforeSelling = gasleft();

        if (_baseToken == WETH) {
            uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                receivedSnipeTokenAmount,
                0,
                sellPath, 
                address(this), 
                block.timestamp
            );
        }
        
        else {
            uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                receivedSnipeTokenAmount,
                0,
                sellPath,
                address(this),
                block.timestamp
            ); 
        }

        uint gasLeftAfterSelling = gasleft();

        uint receivedBaseTokenAmount = _baseToken == WETH ? address(this).balance : baseToken.balanceOf(address(this));
        
        return TradingStatus(
            expectedSnipeTokenAmount,
            receivedSnipeTokenAmount,
            gasLeftBeforeBuying - gasLeftAfterBuying,
            expectedBaseTokenAmount, 
            receivedBaseTokenAmount,
            gasLeftBeforeSelling - gasLeftAfterSelling
        );
    }
}