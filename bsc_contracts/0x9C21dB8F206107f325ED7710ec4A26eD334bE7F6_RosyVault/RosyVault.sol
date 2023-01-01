/**
 *Submitted for verification at BscScan.com on 2022-12-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
 
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


interface IPancakeRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


 contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;

            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {

            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}



contract RosyVault is ERC20, Ownable{
    using SafeMath for uint256;

    struct TokenDetail{
        address tokenAddress;
        uint256 decimals;
        string name;
        uint256 totalAmountIn;
        int256 average;
    }

    struct Params{
        string sellToken;
        uint256 amountSell;
        string buyToken;
        uint256 amountBuy;
        uint256 price;
    }

    address public constant ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    TokenDetail BUSD = TokenDetail(
        0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56,
        18, "BUSD", 0, 1);
    
    TokenDetail BTC = TokenDetail(
        0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c,
        18, "BTC", 0, 0);

    TokenDetail ETH = TokenDetail(
        0x250632378E573c6Be1AC2f97Fcdf00515d0Aa91B,
        18, "ETH", 0, 0);
    
    TokenDetail XRP = TokenDetail(
        0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE,
        18, "XRP", 0, 0);
    
    TokenDetail ADA = TokenDetail(
        0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47,
        18, "ADA", 0, 0);
    
    TokenDetail DOT = TokenDetail(
        0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402,
        18, "DOT", 0, 0);
    
    TokenDetail LTC = TokenDetail(
        0x4338665CBB7B2485A8855A139b75D5e34AB0DB94,
        18, "LTC", 0, 0);

    TokenDetail SHIB = TokenDetail(
        0x2859e4544C4bB03966803b044A93563Bd2D0DD4D,
        18, "SHIB", 0, 0);
    
    TokenDetail UNI = TokenDetail(
        0xBf5140A22578168FD562DCcF235E5D43A02ce9B1,
        18, "UNI", 0, 0);
    
    TokenDetail AVAX = TokenDetail(
        0x1CE0c2827e2eF14D5C4f29a091d735A204794041,
        18, "AVAX", 0, 0);
    
    TokenDetail LINK = TokenDetail(
        0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD,
        18, "LINK", 0, 0);
    
    TokenDetail ATOM = TokenDetail(
        0x0Eb3a705fc54725037CC9e008bDede697f62F335,
        18, "ATOM", 0, 0);
    
    TokenDetail ETC = TokenDetail(
        0x3d6545b08693daE087E957cb1180ee38B9e3c25E,
        18, "ETC", 0, 0);
    
    TokenDetail BCH = TokenDetail(
        0x8fF795a6F4D97E7887C79beA79aba5cc76444aDf,
        18, "BCH", 0, 0);

    TokenDetail NEAR = TokenDetail(
        0x1Fa4a73a3F0133f0025378af00236f3aBDEE5D63,
        18, "NEAR", 0, 0);
    
    TokenDetail FIL = TokenDetail(
        0x0D8Ce2A99Bb6e3B7Db580eD848240e4a0F9aE153,
        18, "FIL", 0, 0);
    
    TokenDetail FLOW = TokenDetail(
        0xC943c5320B9c18C153d1e2d12cC3074bebfb31A2,
        18, "FLOW", 0, 0);

    TokenDetail EOS = TokenDetail(
        0x56b6fB708fC5732DEC1Afc8D8556423A2EDcCbD6,
        18, "EOS", 0, 0);


    IPancakeRouter02 public constant router =
        IPancakeRouter02(ROUTER_ADDRESS);

    uint256 MAX_INT = 2**256 - 1;

    mapping(string => TokenDetail) public Tokens;

    event deposited(
        address user,
        uint256 amount
    );

    event withdrawal(
        address user,
        uint256 amount
    );

      event approved(
        address token,
        uint256 amount
    );

       event swapped(
        string sellToken,
        uint256 amountSell,
        string buyToken,
        uint256 amountBuy,
        uint256 price

    );


    constructor() ERC20("RosyVault POS", "RVPOS") {
        
        approveSpending(BUSD.tokenAddress);
        approveSpending(BTC.tokenAddress);
        approveSpending(ETH.tokenAddress);
        approveSpending(XRP.tokenAddress);
        approveSpending(ADA.tokenAddress);
        approveSpending(DOT.tokenAddress);
        approveSpending(LTC.tokenAddress);
        approveSpending(SHIB.tokenAddress);
        approveSpending(UNI.tokenAddress);
        approveSpending(AVAX.tokenAddress);
        approveSpending(LINK.tokenAddress);
        approveSpending(ATOM.tokenAddress);
        approveSpending(ETC.tokenAddress);
        approveSpending(BCH.tokenAddress);
        approveSpending(NEAR.tokenAddress);
        approveSpending(FIL.tokenAddress);
        approveSpending(FLOW.tokenAddress);
        approveSpending(EOS.tokenAddress);


        Tokens["BUSD"] = BUSD;
        Tokens["BTC"] = BTC;
        Tokens["ETH"] = ETH;
        Tokens["XRP"] = XRP;
        Tokens["ADA"] = ADA;
        Tokens["DOT"] = DOT;
        Tokens["LTC"] = LTC;
        Tokens["SHIB"] = SHIB;
        Tokens["UNI"] = UNI;
        Tokens["AVAX"] =  AVAX;
        Tokens["LINK"] = LINK;
        Tokens["ATOM"] = ATOM;
        Tokens["ETC"] = ETC;
        Tokens["BCH"] = BCH;
        Tokens["NEAR"] = NEAR;
        Tokens["FIL"] = FIL;
        Tokens["FLOW"] = FLOW;
        Tokens["EOS"] = EOS;
    }

    function deposit(uint256 deposit_amount) public {
        ERC20(BUSD.tokenAddress).transferFrom(
            msg.sender,
            address(this),
            deposit_amount
        );
        Tokens["BUSD"].totalAmountIn = Tokens["BUSD"].totalAmountIn.add(deposit_amount);
        mintOnDeposit(msg.sender, deposit_amount);
        emit deposited(msg.sender, deposit_amount);
    }

     function withdraw() public {
         uint256 balance = balanceOf(msg.sender);

         require(balance > 0 , "No Balance To withdraw");

         uint256 percentageShare = balance.mul(100).div(totalSupply());

         IERC20 busd_ = IERC20(BUSD.tokenAddress);
         uint256 busdbalance = busd_.balanceOf(address(this));

        uint256 busdToWithdraw = busdbalance.mul(percentageShare).div(100);
        
        busd_.transfer(
            msg.sender,
            busdToWithdraw
        );

        uint256 newBalance = busd_.balanceOf(address(this));

        Tokens["BUSD"].totalAmountIn = newBalance;

        _burn(msg.sender, balance);
        emit withdrawal(msg.sender, busdToWithdraw);
    }


    function mintOnDeposit(address user, uint256 amount) internal {
        _mint(user, amount);
    }

    function checkAllowance(
        address token_address
    ) internal view returns(uint256){
        return IERC20(token_address).allowance(address(this), ROUTER_ADDRESS);
    }

     function approveSpending(
        address token_address
    ) internal {
        IERC20(token_address).approve(ROUTER_ADDRESS, MAX_INT);
        emit approved(token_address , MAX_INT);
    }

    function calculateAverage(int256 newBalance, int256 oldBalance, int256 fillPrice, int256 prevAvg) internal pure returns(int256){
        int256 difference = newBalance - oldBalance;
        if(oldBalance == 0){
            return fillPrice;
        }
        if(difference < 0){
            if(fillPrice < prevAvg){
                return prevAvg;
            }
            difference *= -2;
        }
        return int256 ((oldBalance*prevAvg)+(difference*fillPrice))/(oldBalance+difference);
    }

    function performSwaps(Params[] calldata data) public  {
        for(uint256 i = 0; i < data.length; i++) {

            TokenDetail storage sellToken_ = Tokens[data[i].sellToken];
            TokenDetail storage buyToken_ = Tokens[data[i].buyToken];

            IERC20 sellTokenInstance =  IERC20(sellToken_.tokenAddress);
            IERC20 buyTokenInstance =  IERC20(buyToken_.tokenAddress);

            uint256 sellAmount = data[i].amountSell;
            uint256 buyAmount = data[i].amountBuy;
            uint256 price = data[i].price;

            uint256 oldbalanceSellToken = sellTokenInstance.balanceOf(address(this));
            uint256 oldbalanceBuyToken = buyTokenInstance.balanceOf(address(this));

            require(oldbalanceSellToken >= sellAmount , "insufficient funds");

            address[] memory path = new address[](2);
            path[0] = sellToken_.tokenAddress;
            path[1] = buyToken_.tokenAddress;

            
            if(checkAllowance(sellToken_.tokenAddress) < sellAmount){
                approveSpending(sellToken_.tokenAddress);
            }

            swap(sellAmount, buyAmount, path, address(this), block.timestamp + 360);

            uint256 newbalanceSellToken = sellTokenInstance.balanceOf(address(this));
            uint256 newbalanceBuyToken = buyTokenInstance.balanceOf(address(this));

            int256 avg = sellToken_.average;
            if(sellToken_.tokenAddress != BUSD.tokenAddress ){
                 sellToken_.average= calculateAverage(int256(newbalanceSellToken), int256(oldbalanceSellToken), int256(price), avg);
            }

            int256 avg2 = buyToken_.average;
            if(buyToken_.tokenAddress != BUSD.tokenAddress ){
                buyToken_.average = calculateAverage(int256(newbalanceBuyToken), int256(oldbalanceBuyToken), int256(price), avg2);
            }

            sellToken_.totalAmountIn = newbalanceSellToken;
            buyToken_.totalAmountIn = newbalanceBuyToken;


            emit swapped(sellToken_.name, sellAmount, buyToken_.name, newbalanceBuyToken.sub(oldbalanceBuyToken), price);

        }

    }

    function getAverages() public view returns(TokenDetail[] memory) {
        TokenDetail[] memory data_ = new TokenDetail[](22);

        data_[0] =	Tokens["BUSD"];
        data_[1] =	Tokens["BTC"];
        data_[2] =	Tokens["ETH"];
        data_[3] =	Tokens["XRP"];
        data_[4] =	Tokens["ADA"];
        data_[5] =	Tokens["DOT"];
        data_[6] =	Tokens["LTC"];
        data_[7] =	Tokens["SHIB"];
        data_[8] =	Tokens["UNI"];
        data_[9] =	Tokens["AVAX"];
        data_[10] =	Tokens["LINK"];
        data_[11] =	Tokens["ATOM"];
        data_[12] =	Tokens["ETC"];
        data_[13] =	Tokens["BCH"];
        data_[14] =	Tokens["NEAR"];
        data_[15] =	Tokens["FIL"];
        data_[16] =	Tokens["FLOW"];
        data_[17] =	Tokens["EOS"];

        return data_;
    }

     function swap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _acct,
        uint256 _deadline
    ) internal {
        router.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _acct,
            _deadline
        );
    }


}