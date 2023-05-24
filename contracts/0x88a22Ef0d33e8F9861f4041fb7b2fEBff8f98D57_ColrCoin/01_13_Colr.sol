// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


contract ColrCoin is ERC20, Ownable {
    using Address for address;

    uint256 private TotalSupply = 100000000 * 10 ** decimals();
    uint256 public taxFees = 0;
    
    address public feeReceiver = 0xf5508Cc02e965A5d61FC3bd3E722111533012CfB;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) public _isExcludedFromFee;
    uint256 public numTokensSellToAddToLiquidity = 200000 * 10** decimals();
    uint256 public numTokensSellToAddToETH = 100000 * 10** decimals();
    mapping (address => bool) public _isRestrictedlisted;
    uint256 public maxWalletBalance = 20000000000 * 10 ** decimals(); // 2% of total supply;
    uint256 public maxTxAmount = 20000000000 * 10 ** decimals(); // 2% of total supply
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    uint256 tax = 700;
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );


constructor() ERC20("Colr Coin", "COLR") {

    _mint(owner(), TotalSupply);		

     IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a);
                // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
                // set the rest of the contract variables
                 uniswapV2Router = _uniswapV2Router;  

                //exclude owner and this contract from fee
                _isExcludedFromFee[owner()] = true;
                _isExcludedFromFee[address(uniswapV2Router)] = true;
                _isExcludedFromFee[feeReceiver] = true;
                _isExcludedFromFee[address(this)] = true;
  }

function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");
        require(!_isRestrictedlisted[from] && !_isRestrictedlisted[to], "This address is Restricted");
         if (from != owner() && to != uniswapV2Pair || from != address(this) && to != uniswapV2Pair){
                require(balanceOf(to)+(amount) <= maxWalletBalance,"Balance is exceeding maxWalletBalance");
                require(amount <= maxTxAmount,"Transfer amount exceeds the maxTxAmount.");
         }

        if (from == uniswapV2Pair || to == uniswapV2Pair) {
            if (from != uniswapV2Pair) {
                uint256 contractLiquidityBalance = balanceOf(address(this)) - taxFees;
                if (contractLiquidityBalance >= numTokensSellToAddToLiquidity) {
                    _swapAndLiquify(numTokensSellToAddToLiquidity);
                }
                if ((taxFees) >= numTokensSellToAddToETH) {
                    _swapTokensForETH(numTokensSellToAddToETH);
                    taxFees -= numTokensSellToAddToETH;
                    bool sent = payable(feeReceiver).send(address(this).balance);
                    require(sent, "Failed to send ETH");
                }
            }

            uint256 transferAmount;
            if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                transferAmount = amount;
            } 
            else {
                uint256 teamTax = ((amount * tax) / 10000);
                transferAmount = amount - teamTax;
                taxFees += teamTax;

                super._transfer(from, address(this), teamTax);
            }
            super._transfer(from, to, transferAmount);
        } 
        else {
            super._transfer(from, to, amount);
        }
    }

 function excludeFromFee(address account, bool status) public onlyOwner {
        _isExcludedFromFee[account] = status;
    }

function transferOwnership(address newOwner) public override onlyOwner{
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    super._transfer(owner(), newOwner, balanceOf(owner()));
    _transferOwnership(newOwner);
}

function _swapAndLiquify(uint256 contractTokenBalance) private {
        uint256 half = (contractTokenBalance / 2);
        uint256 otherHalf = (contractTokenBalance - half);

        uint256 initialBalance = address(this).balance;

        _swapTokensForETH(half);

        uint256 newBalance = (address(this).balance - initialBalance);

        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
     //Remove from Restrictedlist
 function removeFromRestrictedList(address account) external onlyOwner {
    _isRestrictedlisted[account] = false;
    }

     //Add to Restrictedlist
    function addToRestrictedList(address account) external onlyOwner {
    require(account != owner(),"Owner address can not be on restricted list");
    _isRestrictedlisted[account] = true;
    }

   function setTaxForLiquidityAndMarketing(uint256 _taxForTeam)
        public
        onlyOwner
        returns (bool)
    {
        require(_taxForTeam <= 100, "ERC20: total tax must not be greater than 10%");
        tax = _taxForTeam;

        return true;
    }

     function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            feeReceiver,
            block.timestamp
        );
    }

function setFeeRecieverAddress(address newWallet)
        public
        onlyOwner
        returns (bool)
    {
        require(newWallet != DEAD, "LP Pair cannot be the Dead wallet, or 0!");
        require(newWallet != address(0), "LP Pair cannot be the Dead wallet, or 0!");
        feeReceiver = newWallet;
        return true;
    }


function setNumTokensSellToAddToLiquidity(uint256 _numTokensSellToAddToLiquidity, uint256 _numTokensSellToAddToETH)
        public
        onlyOwner
        returns (bool)
    {
        require(_numTokensSellToAddToLiquidity < TotalSupply / 9800, "Cannot liquidate more than 2% of the supply at once!");
        require(_numTokensSellToAddToETH < TotalSupply / 9800, "Cannot liquidate more than 2% of the supply at once!");
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity * 10** decimals();
        numTokensSellToAddToETH = _numTokensSellToAddToETH * 10** decimals();

        return true;
    }

  function withdrawStuckedFunds(uint256 amount) external onlyOwner {
        // This is the current recommended method to use.
        (bool sent,) = owner().call{value: amount}("");
        require(sent, "Failed to send ETH");
    }

    // Withdraw stuked tokens 
    function withdrawStuckedTokens(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success){
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

 function airdrop(address[] memory wallets, uint256[] memory amounts) external onlyOwner {
        require(wallets.length == amounts.length, "arrays must be the same length");
        require(wallets.length <= 200, "Can only airdrop 200 wallets per txn due to gas limits");
            
        for (uint i=0; i<wallets.length; i++) {
            address wallet = wallets[i];
            uint256 amount = amounts[i] * 10 ** decimals();
            transfer(wallet, amount);
        }
        }
    receive() external payable {}
}