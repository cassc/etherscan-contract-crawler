// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

//
//    ฅ^•ﻌ•^ฅ
//
//     alpha cat coin
//      integrated burn + tax to eth, ban wallets
//                           
//     ██          ██                      
//   ██░░██      ██░░██                    
//   ██░░░░██████░░░░██                    
// ██░░░░░░░░░░░░░░░░░░██                  
// ██░░░░░░░░░░░░░░░░░░██                  
// ██░░██░░░░░░░░██░░░░██                  
// ██░░██░░░░░░░░██░░░░██    ████          
// ██░░░░░░░░░░░░░░░░░░██  ██    ██        
//   ████▒▒▒▒▒▒▒▒▒▒████    ██    ██        
//       ██░░▒▒▒▒░░░░░░██    ██    ██      
//       ██░░██░░████░░░░██  ██░░░░██      
//       ██░░████░░░░██░░██  ██░░░░██      
//       ██  ████░░░░░░░░████▒▒▒▒▒▒██      
//       ██  ██    ░░░░░░██▒▒▒▒████        
//       ██████████████████████            
//                                        
//  █████   ██████  █████  ████████ 
// ██   ██ ██      ██   ██    ██    
// ███████ ██      ███████    ██    
// ██   ██ ██      ██   ██    ██    
// ██   ██  ██████ ██   ██    ██    
//
// @AlphaCatCoin twitter
// @AlphaCatCoin telegram

contract AlphaCat is ERC20, Ownable, ReentrancyGuard {
    mapping(address => bool) private _isBanned;
    mapping(address => uint256) private _fromTaxRate;
    mapping(address => uint256) private _toTaxRate;

    uint256 private constant DEN = 1e18;
    uint256 private constant MAX_TAX = 3.5e17; //35%
    
    uint256 public swapAt = 0;
    address public beneficiary;
    bool private inSwap = false;

    IUniswapV2Router02 public uniswapV2Router;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    // ฅ^•ﻌ•^ฅ
    constructor(uint256 totalSupply) ERC20("Alpha Cat", "ACAT") {
        beneficiary = msg.sender;
        swapAt = totalSupply;
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        super._approve(address(this), address(uniswapV2Router), totalSupply);
        _mint(msg.sender, totalSupply);
    }

    // ¯\_₍⸍⸌̣ʷ̣̫⸍̣⸌₎_/¯
    function _transfer(
        address from, address to, uint256 amount
    ) internal override {
        require(!isBanned(from), "address is banned");

        uint256 _amount = amount;

        if(isBeneficiary(to) == false) {
            uint256 tax = getFromTax(from) + getToTax(to);
            if(tax > MAX_TAX) { tax = MAX_TAX; }

            if (tax > 0) {
                // Burn, leave the rest for swap
                uint256 total = ((_amount * tax) / DEN); 
                uint256 split = total / 2;
                _burn(from, split);
                super._transfer(from, address(this), split);
                _amount = _amount - total;
            }

            uint256 stored = balanceOf(address(this));
            if(!inSwap && stored > swapAt) {
                _swapTokensForEth(swapAt);
            }
        }

        super._transfer(from, to, _amount);
    }

    // (=^ ◡ ^=)
    function isBanned(address _user) public view returns (bool) {
        return _isBanned[_user];
    }

    // (^ ⌒ ^) ~
    function banSomeone(address _user) external onlyOwner {
        require(_user != beneficiary, "no ban");
        _isBanned[_user] = true;
    }

    // (=^ ◡ ^=)
    function unbanSomeone(address _user) external onlyOwner {
        _isBanned[_user] = false;
    }

    // (^._.^)ﾉ
    function isBeneficiary(address _user) public view returns (bool) {
        return _user == beneficiary;
    }

    // (^._.^)ﾉ
    function setBeneficiary(address _user) external onlyOwner {
        beneficiary = _user;
    }

    // $ /ᐠ. ᴗ.ᐟ\
    function getFromTax(address from) public view returns (uint256) {
        return _fromTaxRate[from];
    }

    // $ /ᐠ. ᴗ.ᐟ\
    function getToTax(address to) public view returns (uint256) {
        return _toTaxRate[to];
    }

    // $ /ᐠ. ᴗ.ᐟ\
    function fromTax(address _address, uint256 tax) public onlyOwner {
        require(tax <= MAX_TAX, "over max");
        _fromTaxRate[_address] = tax;
    }

    // $ /ᐠ. ᴗ.ᐟ\
    function toTax(address _address, uint256 tax) public onlyOwner {
        require(tax <= MAX_TAX, "over max");
        _toTaxRate[_address] = tax;
    }

    // (^._.^)ﾉ
    function setSwapAmt(uint256 amount) external onlyOwner {
        swapAt = amount;
    }

    // (^._.^)ﾉ
    function setRouter(address _address) external onlyOwner {
        uniswapV2Router = IUniswapV2Router02(_address);
        super._approve(address(this), _address, type(uint256).max);
    }

    // #### /ᐠ. ᴗ.ᐟ\ ####
    function burn(uint256 amount) external virtual {
        _burn(_msgSender(), amount);
    }

    // ㅇㅅㅇ ;)
    function ownerBurn(address _user, uint256 amount) external onlyOwner {
        _burn(_user, amount);
    }

    // $(=⌒ ‿‿ ⌒=)$
    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, 
            path,
            beneficiary,
            block.timestamp
        );
    }

    // ฅ^•ﻌ•^ฅ
    receive() external payable {}

    // o(^・x・^)o
    function clearToken(ERC20 token) external onlyOwner {
        token.transfer(beneficiary, token.balanceOf(address(this)));
    }

    // /ᐠ｡‸｡ᐟ\ 
    function clearETH() external onlyOwner {
        address payable to = payable(beneficiary);
        to.transfer(address(this).balance);
    }
}