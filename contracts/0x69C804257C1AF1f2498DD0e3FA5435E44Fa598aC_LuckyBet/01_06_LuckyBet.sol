// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
        function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}



//
//Twitter(X): https://twitter.com/LuckyBetErc
//Website: https://bẹt.com
//Telegram: https://t.me/luckybet_eth
//
contract LuckyBet is Ownable, ERC20 {
    mapping(address => bool) public blacklists;
    address public marketing1 = 0xe41B54aD6465d093D5Eb8189c7d77b1F66c10241;
    address public marketing2 = 0x08C09ef825864B40895A7A9cce461B769841fb2c;
    address public WETH;
    uint256 public beginBlock = 0;
    uint256 public secondBlock = 420;
    uint256 public ethBlock = 420;
    uint256 public buyTax = 10;
    uint256 public sellTax = 30;
    uint256 public tax2 = 5;
    uint256 public limitNumber;
    uint256 public swapNumber;
    bool public blimit = true;
    bool public swapEth = true;
    address public uniswapV2Pair;
    IRouter public _router;

    // bool isTrade = true;
    mapping(address => bool) public whitelists;


    constructor() ERC20("LuckyBet", "LuckyBet") {
        _mint(msg.sender, 100000000 * 10**18);

        _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        WETH = _router.WETH();

        limitNumber = (100000000 * 10**18) / 100;
        swapNumber = (100000000 * 10**18) / 2000;

        ERC20(WETH).approve(address(_router), type(uint256).max);
        _approve(address(this), address(_router), type(uint256).max);
        _approve(owner(), address(_router), type(uint256).max);
    }

    // function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
    //     require(!blacklists[to] && !blacklists[from], "Blacklisted");
    // }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if(uniswapV2Pair == to && beginBlock == 0) {
            beginBlock = block.timestamp;
        }

        if(from == owner() 
        || from == marketing1
        || from == marketing2
        || from == address(_router)
        || to == owner() 
        || to == marketing1
        || to == marketing2
        || to == address(_router)
        || from == address(this)
        || whitelists[from] 
        || whitelists[to]) {
            super._transfer(from, to, amount);
            return;
        }

        // if(!isTrade && to == uniswapV2Pair) {
        //     require(whitelists[to] || whitelists[from], "Blacklisted");
        //     super._transfer(from, to, amount);
        //     return;
        // }

        if(uniswapV2Pair ==  from || uniswapV2Pair ==  to) {
            if(blimit && uniswapV2Pair ==  from && address(_router) != to){
                require((amount + balanceOf(to)) < limitNumber, "limit");
            }
            uint256 tax = 5;
            if(block.timestamp < (beginBlock + secondBlock)){
                if(from == uniswapV2Pair) {
                    tax = buyTax;
                }else if(to == uniswapV2Pair) {
                    tax = sellTax;
                }
            } else {
                tax = tax2;
            }

            uint256 t = tax * amount / 100;
            if(block.timestamp > (beginBlock + ethBlock) && swapEth) {
                super._transfer(from, address(this), t);
                if(!inSwap && uniswapV2Pair ==  to) {
                    swapfee();
                }
            }else{
                super._transfer(from, marketing1, t);
            }
            super._transfer(from, to, amount - t);
            return;
        }
        super._transfer(from, to, amount);
    }

    bool private inSwap;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    function swapfee() private lockTheSwap {
        uint256 balance = balanceOf(address(this));
        address[] memory path = new address[](2);
        if(balance > swapNumber) {
            path[0] = address(this);
            path[1] = WETH;
            _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(balance, 0, path, marketing2, block.timestamp);
        }
    }

    function setlimit(bool _limit, uint256 _limitNumber) external onlyOwner {
        blimit = _limit;
        limitNumber = _limitNumber;
    }

    function setTax(uint256 _buyTax, uint256 _sellTax, uint256 _tax2) external onlyOwner {
        buyTax = _buyTax;
        sellTax = _sellTax;
        tax2 = _tax2;   
    }

    function setSwapEth(bool isSwapEth) public onlyOwner {
        swapEth = isSwapEth;
    }

    function setSwapNumber(uint256 _swapNumber)  external onlyOwner {
        swapNumber = _swapNumber;
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setblacklist(address[] calldata addresses, bool _isBlacklisting) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            blacklists[addresses[i]] = _isBlacklisting;
        }
    }

    function setwhite(address _address, bool _iswhitelisting) external onlyOwner {
        whitelists[_address] = _iswhitelisting;
    }

    function setwhitelist(address[] calldata addresses, bool _iswhitelisting) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelists[addresses[i]] = _iswhitelisting;
        }
    }

    // function setTrade(bool _isTrade) public onlyOwner {
    //     isTrade = _isTrade;
    // }

    function multiTransfer(address[] calldata addresses, uint256[] calldata amounts) public {
        require(addresses.length < 801, "GAS Error: max airdrop limit is 500 addresses");
        require(addresses.length == amounts.length, "Mismatch between Address and token count");

        uint256 sum = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            sum = sum + amounts[i];
        }

        require(balanceOf(msg.sender) >= sum, "Not enough amount in wallet");
        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(msg.sender, addresses[i], amounts[i]);
        }
    }

    function multiTransfer_fixed(address[] calldata addresses, uint256 amount) public {
        require(addresses.length < 2001, "GAS Error: max airdrop limit is 2000 addresses");

        uint256 sum = amount * addresses.length;
        require(balanceOf(msg.sender) >= sum, "Not enough amount in wallet");

        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(msg.sender, addresses[i], amount);
        }
    }


    function errorToken(address _token) external onlyOwner {
        ERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
    
    function withdawOwner(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    receive () external payable  {
    }
}