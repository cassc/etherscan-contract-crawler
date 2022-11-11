// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./pancake/IPancakeFactory.sol";
import "./pancake/IPancakeRouter.sol";
import "./pancake/IPancakePair.sol";
import "@openzeppelin/contracts/access/Ownable.sol";




contract TokenDistributor {
    constructor (address token) {
        IERC20(token).approve(msg.sender, type(uint256).max);
    }
}

interface IFeeDistributor{
    function distribute() external;
}



contract BTDog is Context, IERC20, IERC20Metadata,Ownable {
    using SafeERC20 for IERC20;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    TokenDistributor public _tokenDistributor;

    mapping(address => bool) public _swapPairList;

    mapping(address => bool) public _blackList;
    mapping(address => bool) public _swapWhiteList;
    mapping(address => bool) public _feeWhiteList;

    address private _usdt;
    IPancakeRouter public _router;
    IPancakePair public _pair;


    bool private _swapEnable;


    bool public isProtection;
    uint256 public INTERVAL = 2 * 60 * 60;
    uint256 public _protectionT;
    uint256 public _protectionP;

    address public lpRecieveAddress;
    address public marketAddress;
    address public fundAddress;
    address public tecAddress;
    address public plegAddress;
    address public nftFeeDistributerAddress;

    uint public minDividend ;

    IFeeDistributor public iFeeDistributor;


    function swapEnable() public onlyOwner{
        _swapEnable = true;
    }
    function swapDisable() public onlyOwner{
        _swapEnable = false;
    }
    function setMinDividend(uint minDividend_) public onlyOwner{
        minDividend = minDividend_;
    }
    function setSwapPairList(address pair_,bool isPair) public onlyOwner{
        _swapPairList[pair_] = isPair;
    }
    function setBlackList(address addr_,bool isBlackAddr)  public onlyOwner{
        _blackList[addr_] = isBlackAddr;
    }
    function setSwapWhiteList(address addr_,bool flag)  public onlyOwner{
        _swapWhiteList[addr_] = flag;
    }
    function setFeeWhiteList(address addr_,bool flag) public onlyOwner{
        _feeWhiteList[addr_] = flag;
    }

    function setFeeAndSwapWiteList(address addr_,bool flag) external onlyOwner{
        setFeeWhiteList(addr_,flag);
        setSwapWhiteList(addr_,flag);
    }
    function setFeeAddress(address lpRecieveAddress_,address marketAddress_,address fundAddress_,address tecAddress_,address plegAddress_,address nftFeeDistributerAddress_) public onlyOwner{
        lpRecieveAddress = lpRecieveAddress_;
        marketAddress = marketAddress_;
        fundAddress = fundAddress_;
        tecAddress = tecAddress_;
        plegAddress = plegAddress_;
        nftFeeDistributerAddress = nftFeeDistributerAddress_;
    }



    constructor(address usdtAddress,address router,address lpRecieveAddress_,address marketAddress_,address fundAddress_,address tecAddress_,address plegAddress_,address nftFeeDistributerAddress_) {
        _name = 'BTDog BEP20 Token';
        _symbol = 'BTDog';
        _mint(msg.sender,12 * 1e25);
        isProtection = true;


        _usdt = usdtAddress;
        _router = IPancakeRouter(router);
        lpRecieveAddress = lpRecieveAddress_;
        marketAddress = marketAddress_;
        fundAddress = fundAddress_;
        tecAddress = tecAddress_;
        plegAddress = plegAddress_;
        nftFeeDistributerAddress = nftFeeDistributerAddress_;
        iFeeDistributor = IFeeDistributor(nftFeeDistributerAddress);



        _pair = IPancakePair(IPancakeFactory(_router.factory()).createPair(address(this), _usdt));
        _swapPairList[address(_pair)] = true;
        _feeWhiteList[address(this)] = true;
        _swapWhiteList[address(this)] = true;
        _swapWhiteList[msg.sender] = true;

        IERC20(_usdt).approve(router, type(uint256).max);
        _allowances[address(this)][router] = type(uint256).max;

        _tokenDistributor = new TokenDistributor(_usdt);

    }






    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual _resetProtection{
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_blackList[from],'_blackList');

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
    }



        uint fee = _caculateFee(from,to,amount);

        //from 買入或撤池子  to  賣出或加池子
        if (_swapPairList[from] || _swapPairList[to]) {
            if(!_swapEnable){
                if(!_swapWhiteList[from] && !_swapWhiteList[to]){
                    revert("can not swap");
                }
            }
        }


        _takeTransfer(from,to,amount - fee);
        _takeTransfer(from,address(this),fee);

        if(_swapPairList[to]){
            _dividendFee();
        }

        _afterTokenTransfer(from, to, amount);
    }



    function _dividendFee() private{

        uint balanceFee = balanceOf(address(this));
        uint price = getBtDogPrice();
        uint usdtTotal = price * balanceFee/decimals();

        if(usdtTotal <= minDividend){
            return;
        }
        uint toSell = balanceFee * 80/100;
        uint toAddLp = balanceFee - toSell;

        (uint112 reserve0, uint112 reserve1, ) = _pair.getReserves();
        if(reserve0 >0 && reserve1 >0){
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _usdt;
            _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(toSell,0,path,address(_tokenDistributor),block.timestamp);

            IERC20(_usdt).safeTransferFrom(address(_tokenDistributor),address(this),IERC20(_usdt).balanceOf(address(_tokenDistributor)));

            _router.addLiquidity(address(this),_usdt,toAddLp,IERC20(_usdt).balanceOf(address(this)),0,0,lpRecieveAddress,block.timestamp);

            uint usdtBalance = IERC20(_usdt).balanceOf(address(this));

            uint temp = usdtBalance/6;

            IERC20(_usdt).safeTransfer(plegAddress,temp);
            IERC20(_usdt).safeTransfer(marketAddress,temp);
            IERC20(_usdt).safeTransfer(tecAddress,temp);
            IERC20(_usdt).safeTransfer(fundAddress,temp);

            IERC20(_usdt).safeTransfer(nftFeeDistributerAddress,usdtBalance - 4 * temp);
            iFeeDistributor.distribute();
        }

    }








    function _caculateFee(address sender,address to,uint256 tAmount) private view returns(uint ){
        uint fee = tAmount * 10/100;
        if(_feeWhiteList[sender] || _feeWhiteList[to]){
            fee = 0;
        }else{

            if(_swapPairList[to]){
                uint priceNow = getBtDogPrice();
                if(priceNow < _protectionP * 75/100){ //跌了25%
                    fee = tAmount * 30 /100;
                }else if(priceNow < _protectionP * 80/100){//跌了20%
                    fee = tAmount * 25 /100;
                }else if(priceNow < _protectionP * 85/100){//跌了15%
                    fee = tAmount * 20 /100;
                }else if(priceNow < _protectionP * 90/100){//跌了10%
                    fee = tAmount * 15 /100;
                }
            }

        }
        return fee;
    }



    modifier _resetProtection() {
        if (isProtection && block.timestamp - _protectionT >= INTERVAL) {
            _protectionT = block.timestamp;
            _protectionP = getBtDogPrice();
        }
        _;
    }

    function resetProtection() external onlyOwner{
        _protectionT = block.timestamp;
        _protectionP = getBtDogPrice();
    }



    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        if(tAmount == 0){
            return;
        }
        _balances[to] += tAmount;
        emit Transfer(sender, to, tAmount);
    }




    function getBtDogPrice() public view returns (uint){
        (uint112 reserve0, uint112 reserve1,) = _pair.getReserves();
        if(reserve0 == 0 || reserve1 == 0){
            return 0;
        }
        (uint112 reserveUsdt, uint112 reserveBtDog) = (reserve0, reserve1);
        if(_pair.token0() != _usdt){
            reserveUsdt = reserve1;
            reserveBtDog = reserve0;
        }
        return _router.getAmountOut(1e18,reserveBtDog,reserveUsdt);
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

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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







    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}