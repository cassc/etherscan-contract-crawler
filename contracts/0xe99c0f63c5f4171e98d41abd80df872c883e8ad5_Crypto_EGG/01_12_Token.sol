/*
Let’s set a #twitter record together and beat #ElonMusk in his own platform. 
Beating the current most liked tweet of Elon (4,6 million)! We got this! 

https://twitter.com/cryptoeggeth/status/1672340849156407296

$EGG -> $1
$EGG Target = $6,000,000,000 Marketcap

Website: https://cryptoegg.org/
Telegram Group: https://t.me/cryptoeggeth
Twitter: https://twitter.com/cryptoeggeth

@@@@@@@@@@@@@@@@@@@#5?~^::^[email protected]@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@&5!:          .~5&@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@&Y:                :J&@@@@@@@@@@@@@@
@@@@@@@@@@@@@P^  .   ........   .  ^[email protected]@@@@@@@@@@@@
@@@@@@@@@@@&?.... ..............  ...7&@@@@@@@@@@@
@@@@@@@@@@#~ ..  ................  .. ~#@@@@@@@@@@
@@@@@@@@@#~.... .................. ....^#@@@@@@@@@
@@@@@@@@&~.... .................... ....^#@@@@@@@@
@@@@@@@@7..... .................... [email protected]@@@@@@@
@@@@@@@Y.:.... .................... ....:[email protected]@@@@@@
@@@@@@#^:::...  ..................  ...:::^#@@@@@@
@@@@@@J::::.... .................. ....::::[email protected]@@@@@
@@@@@&!::::..... ................ .....::::~&@@@@@
@@@@@#^^::::.....  ............  .....::::^^[email protected]@@@@
@@@@@B^^^::::......    ....    ......::::^^^[email protected]@@@@
@@@@@&~^^^:::::.......      ........::::^^^~#@@@@@
@@@@@@J^~^^:::::..................:::::^^^^[email protected]@@@@@
@@@@@@#!~~^^^::::::............::::::^^^[email protected]@@@@@
@@@@@@@G~~~^^^^::::::::::::::::::::^^^^[email protected]@@@@@@
@@@@@@@@G!~~~^^^^^:::::::::::::::^^^^[email protected]@@@@@@@
@@@@@@@@@&J~~~~~^^^^^^^::::^^^^^^^~~~~~J#@@@@@@@@@
@@@@@@@@@@@BJ!~~~~~^^^^^^^^^^^^[email protected]@@@@@@@@@@
@@@@@@@@@@@@@&PJ!~~~~~~~~~~~~~~~~!JP#@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@&BPJ?7!~~~~!7?J5B&@@@@@@@@@@@@@@@@
*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./TokenRecover.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract Crypto_EGG is ERC20, ERC20Burnable, Ownable, TokenRecover {
    
    uint256 public swapThreshold;
    
    uint256 private _eggmapPending;
    uint256 private _liquidityPending;

    address public eggmapAddress;
    uint16[3] public eggmapFees;

    address public lpTokensReceiver;
    uint16[3] public liquidityFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;
 
    event SwapThresholdUpdated(uint256 swapThreshold);

    event eggmapAddressUpdated(address eggmapAddress);
    event eggmapFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event eggmapFeeSent(address recipient, uint256 amount);

    event LpTokensReceiverUpdated(address lpTokensReceiver);
    event liquidityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event liquidityAdded(uint amountToken, uint amountCoin, uint liquidity);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);
 
    constructor()
        ERC20(unicode"Crypto EGG", unicode"EGG") 
    {
        address supplyRecipient = 0x98bCd7BC3387932647afEb969c97E28D896aADbd;
        
        updateSwapThreshold(3000000 * (10 ** decimals()));

        eggmapAddressSetup(0x0623FB030421E384cF067dff8CC753AB48545eFC);
        eggmapFeesSetup(300, 300, 0);

        lpTokensReceiverSetup(0x0000000000000000000000000000000000000000);
        liquidityFeesSetup(200, 200, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _mint(supplyRecipient, 6000000000 * (10 ** decimals()));
        _transferOwnership(0x98bCd7BC3387932647afEb969c97E28D896aADbd);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function _swapTokensForCoin(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerV2.WETH();

        _approve(address(this), address(routerV2), tokenAmount);

        routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function updateSwapThreshold(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
        
        emit SwapThresholdUpdated(_swapThreshold);
    }

    function getAllPending() public view returns (uint256) {
        return 0 + _eggmapPending + _liquidityPending;
    }

    function eggmapAddressSetup(address _newAddress) public onlyOwner {
        eggmapAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit eggmapAddressUpdated(_newAddress);
    }

    function eggmapFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        eggmapFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + eggmapFees[0] + liquidityFees[0];
        totalFees[1] = 0 + eggmapFees[1] + liquidityFees[1];
        totalFees[2] = 0 + eggmapFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit eggmapFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function _swapAndLiquify(uint256 tokenAmount) private returns (uint256 leftover) {
        // Sub-optimal method for supplying liquidity
        uint256 halfAmount = tokenAmount / 2;
        uint256 otherHalf = tokenAmount - halfAmount;

        _swapTokensForCoin(halfAmount);

        uint256 coinBalance = address(this).balance;

        if (coinBalance > 0) {
            (uint amountToken, uint amountCoin, uint liquidity) = _addLiquidity(otherHalf, coinBalance);

            emit liquidityAdded(amountToken, amountCoin, liquidity);

            return otherHalf - amountToken;
        } else {
            return otherHalf;
        }
    }

    function _addLiquidity(uint256 tokenAmount, uint256 coinAmount) private returns (uint, uint, uint) {
        _approve(address(this), address(routerV2), tokenAmount);

        return routerV2.addLiquidityETH{value: coinAmount}(address(this), tokenAmount, 0, 0, lpTokensReceiver, block.timestamp);
    }

    function lpTokensReceiverSetup(address _newAddress) public onlyOwner {
        lpTokensReceiver = _newAddress;

        emit LpTokensReceiverUpdated(_newAddress);
    }

    function liquidityFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        liquidityFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + eggmapFees[0] + liquidityFees[0];
        totalFees[1] = 0 + eggmapFees[1] + liquidityFees[1];
        totalFees[2] = 0 + eggmapFees[2] + liquidityFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit liquidityFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function excludeFromFees(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFees[account] = isExcluded;
        
        emit ExcludeFromFees(account, isExcluded);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        
        bool canSwap = getAllPending() >= swapThreshold;
        
        if (!_swapping && !AMMPairs[from] && canSwap) {
            _swapping = true;
            
            if (false || _eggmapPending > 0) {
                uint256 token2Swap = 0 + _eggmapPending;
                bool success = false;

                _swapTokensForCoin(token2Swap);
                uint256 coinsReceived = address(this).balance;
                
                uint256 eggmapPortion = coinsReceived * _eggmapPending / token2Swap;
                if (eggmapPortion > 0) {
                    (success,) = payable(address(eggmapAddress)).call{value: eggmapPortion}("");
                    require(success, "TaxesDefaultRouterWalletCoin: Fee transfer error");
                    emit eggmapFeeSent(eggmapAddress, eggmapPortion);
                }
                _eggmapPending = 0;

            }

            if (_liquidityPending > 0) {
                _swapAndLiquify(_liquidityPending);
                _liquidityPending = 0;
            }

            _swapping = false;
        }

        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (AMMPairs[from]) {
                if (totalFees[0] > 0) txType = 0;
            }
            else if (AMMPairs[to]) {
                if (totalFees[1] > 0) txType = 1;
            }
            else if (totalFees[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                fees = amount * totalFees[txType] / 10000;
                amount -= fees;
                
                _eggmapPending += fees * eggmapFees[txType] / totalFees[txType];

                _liquidityPending += fees * liquidityFees[txType] / totalFees[txType];

                
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        pairV2 = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        _setAMMPair(pairV2, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != pairV2, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        AMMPairs[pair] = isPair;

        if (isPair) { 
        }

        emit AMMPairsUpdated(pair, isPair);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._afterTokenTransfer(from, to, amount);
    }
}