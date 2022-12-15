//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Interfaces.sol";
import "./Libraries.sol";

contract TaxDistributor is ITaxDistributor {
    using SafeMath for uint256;

    address immutable public tokenPair;
    address immutable public routerAddress;
    address immutable private _token;
    address immutable private _wbnb;

    IDEXRouter private _router;

    bool public override inSwap;
    uint256 public override lastSwapTime;

    uint256 immutable public maxSellTax;
    uint256 immutable public maxBuyTax;

    enum TaxType { WALLET, DIVIDEND, LIQUIDITY, DISTRIBUTOR, BURN }
    struct Tax {
        string taxName;
        uint256 buyTaxPercentage;
        uint256 sellTaxPercentage;
        uint256 taxPool;
        TaxType taxType;
        address location;
        uint256 share;
        bool convertToNative;
    }
    Tax[] public taxes;

    event TaxesDistributed(uint256 tokensSwapped, uint256 ethReceived);
    event DistributionError(string text);

    modifier onlyToken() {
        require(msg.sender == _token, "no permissions");
        _;
    }

    modifier swapLock() {
        require(inSwap == false, "already swapping");
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address router, address pair, address wbnb, uint256 _maxSellTax, uint256 _maxBuyTax) {
        require(wbnb != address(0), "pairedToken cannot be 0 address");
        require(pair != address(0), "pair cannot be 0 address");
        require(router != address(0), "router cannot be 0 address");
        _token = msg.sender;
        _wbnb = wbnb;
        _router = IDEXRouter(router);
        maxSellTax = _maxSellTax;
        maxBuyTax = _maxBuyTax;
        tokenPair = pair;
        routerAddress = router;
    }

    receive() external override payable {}

    function createWalletTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.WALLET, wallet, 0, convertToNative));
    }

    function createDistributorTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.DISTRIBUTOR, wallet, 0, convertToNative));
    }
    
    function createDividendTax(string memory name, uint256 buyTax, uint256 sellTax, address dividendDistributor, bool convertToNative) external override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.DIVIDEND, dividendDistributor, 0, convertToNative));
    }
    
    function createBurnTax(string memory name, uint256 buyTax, uint256 sellTax) external override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.BURN, address(0), 0, false));
    }

    function createLiquidityTax(string memory name, uint256 buyTax, uint256 sellTax, address holder) external override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.LIQUIDITY, holder, 0, false));
    }

    function distribute() external payable override onlyToken swapLock {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = _wbnb;
        IERC20 token = IERC20(_token);

        uint256 totalTokens;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].taxType == TaxType.LIQUIDITY) {
                uint256 half = taxes[i].taxPool.div(2);
                totalTokens += taxes[i].taxPool.sub(half);
            } else if (taxes[i].convertToNative) {
                totalTokens += taxes[i].taxPool;
            }
        }
        totalTokens = checkTokenAmount(token, totalTokens);
        if (checkTokenAmount(token, totalTokens) != totalTokens) {
            emit DistributionError("Insufficient tokens to swap. Please add more tokens");
            return;
        }

        uint256[] memory amts = _router.swapExactTokensForETH(
            totalTokens,
            0,
            path,
            address(this),
            block.timestamp + 300
        );
        uint256 amountBNB = address(this).balance;

        if (totalTokens != amts[0] || amountBNB != amts[1] ) {
            emit DistributionError("Unexpected amounts returned from swap");
        }

        // Calculate the distribution
        uint256 toDistribute = amountBNB;
        for (uint256 i = 0; i < taxes.length; i++) {

            if (taxes[i].convertToNative || taxes[i].taxType == TaxType.LIQUIDITY) {
                if (i == taxes.length - 1) {
                    taxes[i].share = toDistribute;
                } else if (taxes[i].taxType == TaxType.LIQUIDITY) {
                    uint256 half = taxes[i].taxPool.div(2);
                    uint256 share = amountBNB.mul(taxes[i].taxPool.sub(half)).div(totalTokens);
                    taxes[i].share = share;
                    toDistribute = toDistribute.sub(share);
                } else {
                    uint256 share = amountBNB.mul(taxes[i].taxPool).div(totalTokens);
                    taxes[i].share = share;
                    toDistribute = toDistribute.sub(share);
                }
            }
        }

        // Distribute the coins
        for (uint256 i = 0; i < taxes.length; i++) {
            
            if (taxes[i].taxType == TaxType.WALLET) {
                if (taxes[i].convertToNative) {
                    payable(taxes[i].location).transfer(taxes[i].share);
                } else {
                    token.transfer(taxes[i].location, checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == TaxType.DISTRIBUTOR) {
                if (taxes[i].convertToNative) {
                    payable(taxes[i].location).transfer(taxes[i].share);
                } else {
                    token.approve(taxes[i].location, taxes[i].taxPool);
                    IWalletDistributor(taxes[i].location).receiveToken(_token, address(this), checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == TaxType.DIVIDEND) {
               if (taxes[i].convertToNative) {
                    IDividendDistributor(taxes[i].location).depositNative{value: taxes[i].share}();
                } else {
                    IDividendDistributor(taxes[i].location).depositToken(address(this), checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == TaxType.BURN) {
                IBurnable(_token).burn(checkTokenAmount(token, taxes[i].taxPool));
            }
            else if (taxes[i].taxType == TaxType.LIQUIDITY) {
                if(taxes[i].share > 0){
                    uint256 half = checkTokenAmount(token, taxes[i].taxPool.div(2));
                    _router.addLiquidityETH{value: taxes[i].share}(
                        _token,
                        half,
                        0,
                        0,
                        taxes[i].location,
                        block.timestamp + 300
                    );
                }
            }
            
            taxes[i].taxPool = 0;
            taxes[i].share = 0;
        }

        emit TaxesDistributed(totalTokens, amountBNB);

        lastSwapTime = block.timestamp;
    }

    function getSellTax() public override onlyToken view returns (uint256) {
        uint256 taxAmount;
        for (uint256 i = 0; i < taxes.length; i++) {
            taxAmount += taxes[i].sellTaxPercentage;
        }
        return taxAmount;
    }

    function getBuyTax() public override onlyToken view returns (uint256) {
        uint256 taxAmount;
        for (uint256 i = 0; i < taxes.length; i++) {
            taxAmount += taxes[i].buyTaxPercentage;
        }
        return taxAmount;
    }
    
    function setTaxWallet(string memory taxName, address wallet) external override onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].taxType == TaxType.WALLET && compareStrings(taxes[i].taxName, taxName)) {
                taxes[i].location = wallet;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
    }

    function setSellTax(string memory taxName, uint256 taxPercentage) external override onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (compareStrings(taxes[i].taxName, taxName)) {
                taxes[i].sellTaxPercentage = taxPercentage;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
        require(getSellTax() <= maxSellTax, "tax cannot be set this high");
    }

    function setBuyTax(string memory taxName, uint256 taxPercentage) external override onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            //if (taxes[i].taxName == taxName) {
            if (compareStrings(taxes[i].taxName, taxName)) {
                taxes[i].buyTaxPercentage = taxPercentage;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
        require(getBuyTax() <= maxBuyTax, "tax cannot be set this high");
    }

    function takeSellTax(uint256 value) external override onlyToken returns (uint256) {
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].sellTaxPercentage > 0) {
                uint256 taxAmount = value.mul(taxes[i].sellTaxPercentage).div(10000);
                taxes[i].taxPool += taxAmount;
                value = value.sub(taxAmount);
            }
        }
        return value;
    }

    function takeBuyTax(uint256 value) external override onlyToken returns (uint256) {
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].buyTaxPercentage > 0) {
                uint256 taxAmount = value.mul(taxes[i].buyTaxPercentage).div(10000);
                taxes[i].taxPool += taxAmount;
                value = value.sub(taxAmount);
            }
        }
        return value;
    }
    
    
    
    // Private methods
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function checkTokenAmount(IERC20 token, uint256 amount) private view returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        if (balance > amount) {
            return amount;
        }
        return balance;
    }
}
