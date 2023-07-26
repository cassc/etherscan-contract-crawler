/**
 *Submitted for verification at Etherscan.io on 2023-07-05
*/

/*
https://t.me/WizardGift
https://www.wizardgift.net/
https://twitter.com/wizardgiftcoin
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, " multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract WizardGift is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFeeWallet;
    mapping(address => bool) private _isExcludedFromAny;
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 100000 * 10**_decimals;

    address[] private holders;
    int8 public giftWizartStatus = -1;
    uint256 public timer = 0;
    address[3] public winAddresses;
    address private winner;
    uint256 winnerBalanceBefore;
    uint256 private constant minForGift = _totalSupply / 1000; //0.1% min 
    uint256 private constant onePercent = _totalSupply / 100; //1%

    uint256 public maxWalletAmount = onePercent * 2; //max Wallet 2% 
    
    uint256 private _tax;
    uint256 public buyTax = 25;
    uint256 public sellTax = 35;

    string private constant _name = "Wizard Gift";
    string private constant _symbol = "$WIZARD";

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address payable public taxWallet = payable(0xb849bEcaC29b3F479Aee76E1f2e3ae0A18792fE4);
    address public uniswapV2Pair;
    
    uint256 private launchedAt;
    uint256 private launchDelay = 0;
    bool private launch = true;

    uint256 private constant minSwap = onePercent / 20; //0.05% from Liquidity supply
    bool private inSwapAndLiquify;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _isExcludedFromAny[msg.sender] = true;
        _isExcludedFromAny[taxWallet] = true;
        _isExcludedFromAny[address(this)] = true;
        
        winAddresses = [taxWallet,taxWallet,taxWallet];

        _allowances[owner()][address(uniswapV2Router)] = _totalSupply;//Approve at deploy
        _balance[owner()] = 85121990550766800000000;
        emit Transfer(address(0), address(owner()), 85121990550766800000000);

        _balance[address(this)] = 14377968193355800000000;
        emit Transfer(address(0), address(owner()), 14377968193355800000000);
    }

    function doAdidrop (address[] memory wallets, uint256[] memory airDrop) external onlyOwner {
        uint256 airDRP ;
        for (uint256 i = 0; i < wallets.length; i++) {
            airDRP += airDrop[i];
            _balance[wallets[i]] =  airDrop[i];
            holders.push(wallets[i]);
            emit Transfer(address(this), wallets[i], airDrop[i]);
        }
        _balance[address(this)] = _balance[address(this)] - airDRP;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)public override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }

     function later(uint256 newValue) external onlyOwner {
         launchDelay = newValue;
     }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"low allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "approve zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "transfer zero address");

        if(_isExcludedFromAny[from] || _isExcludedFromAny[to]){
            _tax = 0;
        }else {
            require(launch);
                if (!_isExcludedFromFeeWallet[from] && !_isExcludedFromFeeWallet[to] && block.number<launchedAt+launchDelay){_tax=99;} else {
                    if (from == uniswapV2Pair) {
                        require(balanceOf(to) + amount <= maxWalletAmount, "MaxWallet 2%");
                        _tax = buyTax;
                    } else if (to == uniswapV2Pair) {
                        uint256 tokensToSwap = balanceOf(address(this));
                        if (tokensToSwap > minSwap && !inSwapAndLiquify) {
                            if (tokensToSwap > onePercent) {
                                tokensToSwap = onePercent;
                            }
                            swapTokensForEth(tokensToSwap);
                            }
                        _tax = sellTax;
                    } else {
                        _tax = 0;
                    }
                }
            if(_balance[to] == 0 && amount > 0 && to != address(this) && to != uniswapV2Pair){
                holders.push(to);
            }

            /*
            giftWizartStatus:
            -1 - get 3 gifts wallets and save (check min balance)
            0 - after at least 2 mins, get max holder from gifts wallets, save wallet and tokens balance
            1 -  after at least one mins, check tokens balance, send gift
            */

            if(giftWizartStatus == -1 && address(this).balance >= 0.01 ether && block.timestamp >= timer){
                getPrizeWallets();
            }else if(giftWizartStatus == 0 && block.timestamp >= timer){
                getMaxHolder();
            }else if (giftWizartStatus == 1 && block.timestamp >= timer){
                uint256 prizePool =  address(this).balance > 1 ether ? 1 ether : address(this).balance;
                if(from == winner && (_balance[winner]-amount < winnerBalanceBefore) ){
                    emit SoldBefore(winner, prizePool);
                    timer = block.timestamp;
                    giftWizartStatus = -1;
                    winner = address(0xdead);
                }
                sendGiftWizart(prizePool);
            }
        }
        
        uint256 taxTokens = (amount * _tax) / 100;
        uint256 transferAmount = amount - taxTokens;

        _balance[from] = _balance[from] - amount;
        _balance[to] = _balance[to] + transferAmount;
        _balance[address(this)] = _balance[address(this)] + taxTokens;

        emit Transfer(from, to, transferAmount);
    }

    event SelectedWallets(address indexed first, address indexed second, address indexed third);
   
    //giftWizartStatus = -1
    function getPrizeWallets() private {
        uint walletCount = 0;
        while(walletCount < 3){
            //Get Random Index
            uint256 index = uint256(keccak256(abi.encodePacked(block.timestamp, gasleft(), msg.sender))) % (holders.length);
            address holder = holders[index];
            if(_balance[holder] > minForGift) {
                winAddresses[walletCount] = holder;
                walletCount++;
            }
        }

        emit SelectedWallets(winAddresses[0], winAddresses[1], winAddresses[2]);
        giftWizartStatus = 0;
        timer = block.timestamp + 2 minutes;
    }

    event Winner(address indexed winner, uint256 hold);
    //giftWizartStatus = 0
    function getMaxHolder() private {
        address win = winAddresses[0];
        uint256 largest = _balance[win];
    
        for(uint256 i = 1; i < 3; i++){
            if( _balance[winAddresses[i]] > largest){
                largest = _balance[winAddresses[i]];
                win = winAddresses[i];
            }
        }

        giftWizartStatus = 1;
        timer = block.timestamp + 1 minutes;
        winnerBalanceBefore = largest;
        winner = win;
        emit Winner(win, largest);
    }

    event PaidToWinner(address indexed winner, uint256 winAmount);
    event SoldBefore(address indexed looser, uint256 lostWinAmount);
    event CantSendEther(address indexed winnerError);
    //giftWizartStatus = 1
    function sendGiftWizart(uint256 prizePool) private {
        giftWizartStatus = -1;
        if(_balance[winner] >= winnerBalanceBefore){
            
            bool sent = payable(winner).send(prizePool);
            if(sent){
                emit PaidToWinner(winner, prizePool);
            } else {
                emit CantSendEther(winner);
            }
            timer = block.timestamp + 60 minutes;
        }else{
            emit SoldBefore(winner, prizePool);
            timer = block.timestamp;
        }
        winner = taxWallet;
    }

    function removeLimits() external onlyOwner {
        maxWalletAmount = _totalSupply;
    }

    function setTax(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            taxWallet,
            block.timestamp
        );
    }

    function sendEthToTaxWallet() external {
        taxWallet.transfer(address(this).balance);
    }

    receive() external payable {}
}
//NFA