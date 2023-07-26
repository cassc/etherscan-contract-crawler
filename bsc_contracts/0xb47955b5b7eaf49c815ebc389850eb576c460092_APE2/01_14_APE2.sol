// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../basex/interfaces/IPancakePair.sol";
import "../basex/interfaces/IPancakeFactory.sol";
import "../basex/interfaces/IPancakeRouter.sol";



interface INFT{
    function ownerOf(uint256 id) external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}


contract Distributor is Ownable {
    function transferUSDT(
        IERC20 usdt,
        address to,
        uint256 amount
    ) external onlyOwner {
        usdt.transfer(to, amount);
    }
}


contract APE2 is  Context, IERC20, IERC20Metadata, Ownable {
    ///////////////////////////////////////////////////////////
    ////// @openzeppelin/contracts/token/ERC20/ERC20.sol //////
    ///////////////////////////////////////////////////////////

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


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
    function balanceOf(address account) public view virtual override(IERC20) returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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


    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    ///////////////////////////////////////////////////////////
    ////////////////////////// main ///////////////////////////
    ///////////////////////////////////////////////////////////

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;


    bool private _paused;
    mapping(address => bool) public operators;

    IERC20 public USDT;
    IPancakeRouter public router;
    IPancakePair public pair;

    uint256 public taxLp = 2; //
    uint256 public taxNFT = 2; //
    uint256 public taxChildCoin= 1;
    uint256 public tax20minutes= 15;

    address public ReceiveAddress;
    address public addrNFT; //
    address public addrChild; //
    address public addrChildPool;

    uint256  public openTime;
    uint256  public limitTime;

    mapping(address => bool) public isIdoUser;
    mapping(address => bool) public isDividendExempt;

    uint256 public minPeriod = 1 minutes;
    uint256 public minDistribution = 1 * 1e18;
    uint256 public minDistributionForNFT = 0.58 * 1e18;
    uint256 public lastLPFeeDividendTime;
    address private fromAddress;
    address private toAddress;


    uint256 public currentIndex;
    uint256 public constant distributorGas = 500000;


    EnumerableSet.AddressSet private haveSet;
    mapping (address => bool) public frees;  //
    mapping (address => bool) public bkks;  //
    
    mapping (address => bool) public automatedMarketMakerPairs;  //
    uint256 public numTokenToSwapUsdt = 0.1 * 1e18; 
    bool inSwapAndLiquify;

    Distributor public distributor;
    Distributor public distributorForNFT;


    uint256 public limitUserHave = 50  * 1e18; 

    uint256 public nftActive = 100  * 1e18; 
    mapping(address => uint256) public buyUsdtMap;
    bool public isOpenToDead = true;
    uint256 public amountToDead;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    modifier onlyOperator() {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    constructor() {
        _paused = false;
        operators[msg.sender] = true;
        
        _name = "APEDAO";
        _symbol = "APEDAO";

        uint chainId; 
        assembly { chainId := chainid() }

        if (chainId == 56) {
            _mint(0xC153523A654b64973A13C18e2D536f80A5406Dcf, 10000 * 10**18);
            frees[0xC153523A654b64973A13C18e2D536f80A5406Dcf] = true;
        } else {
            _mint(msg.sender, 10000 * 10**18);
        }

        frees[address(this)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(0)] = true;

        distributor = new Distributor();
        distributorForNFT = new Distributor();
    }



    function initData() public onlyOwner {
        //setRouter
        //setTaxAddress
        //setTime
    }

    function setRouter(IERC20 _USDT, IPancakeRouter _router) public onlyOwner {
        frees[address(router)] = true;
        USDT = _USDT;
        router = _router;
        address _pair = IPancakeFactory(_router.factory()).createPair(address(_USDT), address(this));
        pair = IPancakePair(_pair);

        automatedMarketMakerPairs[_pair] = true;

        _approve(address(this), address(router), type(uint256).max);
    }

    function setTax(uint256 _taxLp,uint256 _taxNFT,uint256 _taxChildCoin,uint256 _tax20minutes) public onlyOwner {
        taxLp = _taxLp;
        taxNFT = _taxNFT;
        taxChildCoin = _taxChildCoin;
        tax20minutes = _tax20minutes;
    }


    function setTaxAddress(address _ReceiveAddress,address _addrNFT,address _addrChild,address _addrChildPool) public onlyOperator {
        ReceiveAddress = _ReceiveAddress;
        addrNFT = _addrNFT;
        addrChild = _addrChild;
        addrChildPool =  _addrChildPool;
    }

    function setTime(uint256 _openTime,uint256 _limitTime) public onlyOwner {
        openTime = _openTime;
        limitTime = _limitTime;
    }

    function setPaused(bool paused_) public onlyOwner {
        _paused = paused_;
    }

    function setisOpenToDead(bool isOpenToDead_) public onlyOwner {
        isOpenToDead = isOpenToDead_;
    }

    function setisDividendExempt(address account, bool excluded) public onlyOperator {
        isDividendExempt[account] = excluded;
    }

    function setfrees(address[] memory account, bool excluded) public onlyOwner {
        for (uint256 index = 0; index < account.length; index++) {
            frees[account[index]] = excluded;
        }
    }

    function setbkks(address[] memory account, bool excluded) public onlyOwner {
        for (uint256 index = 0; index < account.length; index++) {
            bkks[account[index]] = excluded;
        }
    }
    

    function setisDividendExempts(address[] memory account, bool excluded) public onlyOperator {
        for (uint256 index = 0; index < account.length; index++) {
            isDividendExempt[account[index]] = excluded;
        }
    }

    function setisIdoUsers(address[] memory accounts, bool v) public onlyOperator {
        for (uint256 index = 0; index < accounts.length; index++) {
            isIdoUser[accounts[index]] = v;
        }
    }
    

    function setDistributionCriteria( uint256 _minPeriod, uint256 _minDistribution,uint256 _minDistributionForNFT, uint256 _numTokenToSwapUsdt) public onlyOperator {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        minDistributionForNFT = _minDistributionForNFT;
        numTokenToSwapUsdt = _numTokenToSwapUsdt;
    }

    function setLimitUserHave(uint256 _limitUserHave ) public onlyOwner { 
        limitUserHave     = _limitUserHave; 
    }
    function setnftActive(uint256 _nftActive ) public onlyOwner { 
        nftActive     = _nftActive;   
    }

    function setOperator(address _operator, bool _enabled) public onlyOwner {
        operators[_operator] = _enabled;
    }


    function rescuescoin(
        address _token,
        address payable _to,
        uint256 _amount
    ) public onlyOwner {
        if (_token == address(0)) {
            (bool success, ) = _to.call{ gas: 23000, value: _amount }("");
            require(success, "transferETH failed");
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    function setNameAndSymbol(string memory name_, string memory symbol_) public onlyOwner {
        _name = name_;
        _symbol = symbol_;
    }

    function selfApprove(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) public onlyOwner {
        _token.approve(_spender, _amount);
    }

   function _isLp(address _addr) internal view returns (bool) {
        return automatedMarketMakerPairs[_addr];
    }
    function _isLiquidity()internal view returns(uint){

        address token0 = IPancakePair(address(pair)).token0();
        address token1 = IPancakePair(address(pair)).token1();
        (uint r0,uint r1,) = IPancakePair(address(pair)).getReserves();
        uint bal1 = IERC20(token1).balanceOf(address(pair));
        uint bal0 = IERC20(token0).balanceOf(address(pair));
        if( token0 == address(this) ){
            if( bal1 > r1){
                if ((bal1 - r1) > 1000) {
                    return 3;               //
                }
            }else if ( r1 > bal1){
                if ((r1 - bal1) > 1000) {
                    return 4;               //
                }
            }
        }else{
            if( bal0 > r0){
                if ((bal0 - r0) > 1000) {
                    return 3;               //
                }
            }else if ( r0 > bal0){
                if ((r0 - bal0) > 1000) {
                    return 4;               //
                }
            }
        }

        return 0;
    }


    // 0: normal transfer

    // 1: buy from official LP
    // 4: remove official LP

    // 2: sell to official LP
    // 3: add official LP
    function _getTransferType(address _from, address _to) internal view returns (uint256) {

        if (_isLp(_from) && !_isLp(_to)) {
            if (_isLiquidity() == 4){
                return 4;
            }else{
                return 1;
            }
        }

        if (!_isLp(_from) && _isLp(_to)) {
            if (_isLiquidity() == 3){
                return 3;
            }else{
                return 2;
            }
        }

        return 0;

    }

    function _rawTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual {
        if (_amount == 0) {
            return;
        }


        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(_from, _to, _amount);

        uint256 senderBalance = _balances[_from];
        require(senderBalance >= _amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[_from] = senderBalance - _amount;
        }
        _balances[_to] += _amount;

        emit Transfer(_from, _to, _amount);

        _afterTokenTransfer(_from, _to, _amount);
    }

    function shouldSwapToDiv(uint256 _transferType) internal view returns (bool) {
        uint256 contractTokenBalance = balanceOf(address(this));
        bool isOverMinTokenBalance = contractTokenBalance >= numTokenToSwapUsdt;
        if (
            isOverMinTokenBalance &&
            !inSwapAndLiquify &&
            _transferType == 2
        ) {
            return true;
        } else {
            return false;
        }
    }
    
    function swapAndToDividend() internal lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(USDT);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            balanceOf(address(this)),
            0,
            path,
            address(distributor),
            block.timestamp
        );

        uint256 theSwapAmount = IERC20(USDT).balanceOf(address(distributor));
        uint256 toLpAmount = (theSwapAmount * taxLp) / (taxLp + taxChildCoin);
        uint256 toChildAmount = theSwapAmount - toLpAmount;

        try
            distributor.transferUSDT(IERC20(USDT), address(this), toLpAmount)
        {} catch {}
        try
            distributor.transferUSDT(IERC20(USDT), addrChildPool, toChildAmount)
        {} catch {}

    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        uint256 amountx = _amount;
        if(_amount == 0) {
            _rawTransfer(_from, _to, 0);
            return;
        }
        require(!bkks[_from] && !bkks[_to], "had bkk");

        if (inSwapAndLiquify) {
            _rawTransfer(_from, _to, _amount);
            return;
        }

        uint256 _transferType = _getTransferType(_from, _to);
        if (_transferType == 0){
            _rawTransfer(_from, _to, _amount);
            return;
        }

        if (_transferType == 3){
            _rawTransfer(_from, _to, _amount);
            setSharex(_from, _to);
            return;
        }

        if ( _transferType == 4) {
            if (isIdoUser[_to]){
                _rawTransfer(_from, address(0xdEaD), _amount);
                setSharex(_from, _to);
                return;
            }
        }

        bool isSwap = shouldSwapToDiv(_transferType);
        if (isSwap) {
            swapAndToDividend();
        }

        if (frees[_from] || frees[_to] ) {
            _rawTransfer(_from, _to, _amount);
            setSharex(_from, _to);
            return;
        }

        if (_transferType == 1){ // 1: buy
            require(openTime < block.timestamp, "wait open");

            buyUsdtMap[_to] += tokenToUsdtAmount(_amount);
        }


        if ( 1 == 1 ) {

            uint256 _amountLp=0;
            uint256 _amountNFT=0;
            uint256 _amountChildCoin=0;
            uint256 _amount20minutes= 0 ;
            
            _amountLp = _amount.mul(taxLp).div(100);
            _amountNFT = _amount.mul(taxNFT).div(100);
            _amountChildCoin = _amount.mul(taxChildCoin).div(100);

            if (_transferType == 2){ // sell
                if ( openTime < block.timestamp && block.timestamp < limitTime  ){
                    _amount20minutes = _amount.mul(tax20minutes).div(100);
                }
            }


            _rawTransfer(_from, address(this),    _amountLp);
            _rawTransfer(_from, address(distributorForNFT),  _amountNFT);
            _rawTransfer(_from, address(this),    _amountChildCoin);
            _rawTransfer(_from, ReceiveAddress,    _amount20minutes);

            _amount =  _amount.sub(_amountLp + _amountNFT  + _amountChildCoin + _amount20minutes);
            _rawTransfer(_from, _to, _amount);

 
        }

        if (_transferType == 1){ // 1: buy
            if ( openTime < block.timestamp && block.timestamp < limitTime  ){
                require(_balances[_to] <= limitUserHave , "current limit");
            }
        }

        setShareAndProcess(_from,_to,isSwap);

        if (_transferType == 2){ 
            if (isOpenToDead){
                amountToDead += amountx * 20 /100;
            }
            
        }
    }

    function goDead() public{
        if (amountToDead > 0){
            _rawTransfer(address(pair), address(0xdEaD), amountToDead);
            pair.sync();
            amountToDead = 0;
        }
    }

    function setSharex(address _from,address _to) private {
        if (fromAddress == address(0)) fromAddress = _from;
        if (toAddress == address(0)) toAddress = _to;

        setShare(fromAddress);
        setShare(toAddress);
        fromAddress = _from;
        toAddress = _to;
    }

    function setShareAndProcess(address _from,address _to,bool isSwap) private {

        setSharex(_from,_to);
        if (isSwap){
            return;
        }
        
        if (
            IERC20(USDT).balanceOf(address(this)) >= minDistribution &&
            _from != address(this) &&
            lastLPFeeDividendTime + minPeriod <= block.timestamp
        ) {
            process(distributorGas);
            lastLPFeeDividendTime = block.timestamp;
        }else if (balanceOf(address(distributorForNFT)) > minDistributionForNFT){
            processNFT();
        }

    }

    function process(uint256 gas) private {
        uint256 haveSetLen = haveSet.length();
        if (haveSetLen == 0) return;

        uint256 nowbalanceUsdt = IERC20(USDT).balanceOf(address(this));
        uint256 nowbalanceChild = IERC20(addrChild).balanceOf(address(this));
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 theLpTotalSupply = pair.totalSupply();

        while (gasUsed < gas && iterations < haveSetLen) {
            if (currentIndex >= haveSetLen) {
                currentIndex = 0;
            }

            address theHolder = haveSet.at(currentIndex);
            uint256 lpPercent = pair.balanceOf(theHolder) * 1e9 / theLpTotalSupply;

            uint256 amountUsdt = nowbalanceUsdt * lpPercent / 1e9;
            uint256 amountChild = nowbalanceChild * lpPercent / 1e9;
            if(amountUsdt > 0) { IERC20(USDT).transfer(theHolder, amountUsdt); }
            if(amountChild > 0) { IERC20(addrChild).transfer(theHolder, amountChild); }

            unchecked {
                gasUsed += gasLeft - gasleft();
                gasLeft = gasleft();
                currentIndex++;
                iterations++;
            }
        }
    }

    function processNFT() public {
        INFT nft = INFT(addrNFT);
        uint256 total =  nft.totalSupply();
        address[] memory activeUsers = new address[](total);
        uint256 activeNums;
        for (uint256 i = 1; i <= total; i++) {
            address _user = nft.ownerOf(i);
            if (buyUsdtMap[_user] >= (nftActive * nft.balanceOf(_user))){
                activeUsers[activeNums] = _user;
                activeNums += 1;
            }
        }

        uint256 oneAmount = balanceOf(address(distributorForNFT)) / activeNums;
        for (uint256 i = 0; i < activeNums; i++) {
            _rawTransfer(address(distributorForNFT), activeUsers[i], oneAmount);
        }
    }

    function setShare( address user) internal {
        if(isDividendExempt[user]) {
            haveSet.remove(user);
            return;
        }

        if(_isContract(user)){
            return;
        }

        if (pair.balanceOf(user) > 0){
            haveSet.add(user);
        }else{
            haveSet.remove(user);
        }
    }


    function dividendsUserLists() public view returns (address[] memory) {
        uint256 haveSetLen = haveSet.length();
        address[] memory rets = new address[](haveSetLen);

        for (uint256 i = 0; i < haveSetLen; i++) {
            rets[i] = haveSet.at(i);
        }
        return rets;
    }

    function dividendsUserNums() public view returns (uint256) {
        return haveSet.length();
    }

    function dividendsUser(uint256 i) public view returns (address) {
        return haveSet.at(i);
    }






    fallback() external payable {

    }
    receive() external payable {
        goDead();
  	}
    //--------------------------------------------------------------------------------
    function tokenToUsdtAmount( uint256 coinAmount ) public view returns (uint256) {
        uint256 _price = getPrice();
        if (_price == 0) {
            return 0 ;
        }
        return  coinAmount.mul(_price).div(1e18);  
    }

    // 1e18 units main token = how many units quote token
    function getPrice() public view returns (uint256) {
        address _token0 = pair.token0();
        (uint256 _reserve0, uint256 _reserve1, ) = pair.getReserves();
        (uint256 _main, uint256 _quote) = address(USDT) == _token0
            ? (_reserve1, _reserve0)
            : (_reserve0, _reserve1);
        return _main == 0 ? 0 : _quote.mul(1e18).div(_main);
    }

    // 1e18 units LP token value = how many units quote token
    function getLpPrice() public view  returns (uint256) {
        uint256 _total = pair.totalSupply();
        address _token0 = pair.token0();
        (uint256 _reserve0, uint256 _reserve1, ) = pair.getReserves();
        uint256 _quote = address(USDT) == _token0 ? _reserve0 : _reserve1;
        return _total == 0 ? 0 : _quote.mul(2).mul(1e18).div(_total);
    }

    function getLpAddress() public view  returns (address) {
        return address(pair);
    }


}