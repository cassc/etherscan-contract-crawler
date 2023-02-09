// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interfaces/IERC721A.sol";

// https://twitter.com/TwoPawsDefi
// https://twopaws.io/

//TOKENOMIC TOKEN TWOPAW.
//Total supply 100M
//Add uniswap 75% supply token / 4 ETH, 25% team .
//LP token Burn (0) address.
//Tax: buy and sales of TWOPAW over 80k are taxed at 20%; transfers over 80k are taxed at 1%.
//No tax on buy and sales and transfer of < 80k TWOPAW.
//Auto-added Liquidity: 1.25% of tokens are auto-added to the pair if it has an overabundance of tokens. Liquidity not added from (number of sales NFTDAO * 30000) + 2.5m is used to buy back NFT.
//All tax proceeds are allocated to the protocol for incentives.

//TOKENOMIC PROTOCOL
//The protocol collects 0.3% of the loan amount if it is taken.
//The protocol distributes the 2PAW token from buy and sales of the token and NFT buy/sell itself, stimulating orders.
//NFT Buy 40000 TWOPAW / Sell 30000 TWOPAW
//Only NFT holders can place reward orders!
//1 NFT = 1 Reward order !
//NFTDAO holders are entitled to all the proceeds of the protocol after the sale of 1650 NFTDAO.
//The owner will change to the DAO contract address!
//Reward Formula: Repayment date must be 21 days from now (repayment date + loan amount/ denominator)*(repayment date + loan amount/ denominator).
//Only the DAO can add new denominator & tokens or change them.


interface IProtocol {
    function exchangeFeeBuyPercent() external view returns (uint256);
    function exchangeFeeSellPercent() external view returns (uint256);
    function protocolNFTSellPrice() external view returns (uint256);
    function protocolNFTBuyPrice() external view returns (uint256);
}

contract PawToken is ERC20, Ownable {
    string private _name = "TWOPAW Token";
    string private _symbol = "TWOPAW";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 100000000;


    uint256 public maxTxAmount = 250000 * 10 ** _decimals;
    uint256 public maxWalletAmount = 1000000 * 10 ** _decimals;
    uint256 public amountToLiquify = 2500000 * 10 ** _decimals;
    uint256 public fee = 1;


    address public protocolAddress;
    address public protocolNFT;

    address public devAddress;

    bool public devLocked = true;
    bool inSwapAndLiquify;

    IUniswapV2Router02 public immutable uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniswapV2Pair;

    mapping(address => bool) private _isExcludedFromFee;

    modifier devUnlock {
        if (devLocked){
            require(
                msg.sender == devAddress, "Locked by developer.");
        }
        _;
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address _devAddress) ERC20(_name, _symbol)  {
        _mint(_devAddress, (100000000 * 10 ** _decimals));

        devAddress = _devAddress;

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        _isExcludedFromFee[address(uniswapV2Router)] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[devAddress] = true;
        _isExcludedFromFee[owner()] = true;


    }

    function _transfer(address from, address to, uint256 amount) internal override devUnlock {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");
        if (
            (from == uniswapV2Pair || to == uniswapV2Pair)
            && amount > IProtocol(protocolAddress).protocolNFTBuyPrice() * 2
            && !inSwapAndLiquify) {
            if (from != uniswapV2Pair) {
                uint256 contractBalance = balanceOf(protocolAddress);
                uint256 lockedNFT = IERC721A(protocolNFT).totalSupply() - IERC721(protocolNFT).balanceOf(protocolAddress);
                uint256 lockedTokens = (IProtocol(protocolAddress).protocolNFTSellPrice() * lockedNFT) + amountToLiquify;
                if (contractBalance > lockedTokens + amountToLiquify) {
                    super._transfer(protocolAddress, address(this), amountToLiquify);
                    _swapAndLiquify(amountToLiquify);
                }
            }

            uint256 transferAmount;
            if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                transferAmount = amount;
            } else {
                require(amount <= maxTxAmount, "ERC20: transfer amount exceeds the max transaction amount");
                if (from == uniswapV2Pair) {
                    require((amount + balanceOf(to)) <= maxWalletAmount, "ERC20: balance amount exceeded max wallet amount limit");
                }

                uint256 protocolAmount;
                if(from == uniswapV2Pair) {
                    protocolAmount = (amount * IProtocol(protocolAddress).exchangeFeeBuyPercent() / 100);
                }else if (to == uniswapV2Pair){
                    protocolAmount = (amount * IProtocol(protocolAddress).exchangeFeeSellPercent() / 100);
                }




                if (protocolAmount != 0) {
                    transferAmount = amount - protocolAmount;
                    super._transfer(from, protocolAddress, protocolAmount);
                } else {
                    transferAmount = amount;
                }

            }
            super._transfer(from, to, transferAmount);

        } else {

            if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                super._transfer(from, to, amount);
            } else if (amount > IProtocol(protocolAddress).protocolNFTBuyPrice() * 2) {
                uint256 protocolAmount = (amount * fee / 100);
                uint256 transferAmount = amount - protocolAmount;
                super._transfer(from, protocolAddress, protocolAmount);
                super._transfer(from, to, transferAmount);
            }else {
                super._transfer(from, to, amount);
            }
        }
    }

    function _swapAndLiquify(uint256 _tokenAmount) private lockTheSwap {
        uint256 half = (_tokenAmount / 2);
        uint256 otherHalf = (_tokenAmount - half);
        uint256 initialBalance = address(this).balance;

        _swapTokensForEth(half);

        uint256 newBalance = (address(this).balance - initialBalance);
        _addLiquidity(otherHalf, newBalance);
    }

    function _swapTokensForEth(uint256 _tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();


        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            (block.timestamp + 300)
        );
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private lockTheSwap {
        uniswapV2Router.addLiquidityETH{value : _ethAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            address(this),
            (block.timestamp + 300)
        );
    }

    function setProtocolAndNFTAddresses(address _protocolAddress, address _NFTToken) public onlyOwner {
        protocolAddress = _protocolAddress;
        protocolNFT = _NFTToken;
        _isExcludedFromFee[protocolAddress] = true;
    }

    function setMaxTxAmount() public onlyOwner {
        maxTxAmount = type(uint256).max;
    }

    function setMaxWalletAmount() public onlyOwner {
        maxWalletAmount = type(uint256).max;
    }

    function toggleLock() public onlyOwner {
        devLocked = !devLocked;
    }

    function withdraw() public returns(bytes memory){
        (, bytes memory resp) = devAddress.call{value: address(this).balance}("");
        return resp;
    }

    receive() external payable {
    }

}