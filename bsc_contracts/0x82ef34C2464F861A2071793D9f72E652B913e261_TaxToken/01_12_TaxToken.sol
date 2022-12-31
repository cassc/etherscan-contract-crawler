// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./InfoToken.sol";
import "./Social.sol";
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";
import "./IPancakeRouter02.sol";
import "./Blacklistable.sol";

contract TaxToken is Context, IERC20, Ownable, Blacklistable {
    using SafeMath for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;
    address payable public teamWalletAddress;
    address public immutable deadAddress = address(0);
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;
    string public site;
    string public telegram;
    string public twitter;

    uint256 public _buyTax = 0;
    uint256 public _sellTax = 0;
    uint256 public _totalTaxIfBuying = 0;
    uint256 public _totalTaxIfSelling = 0;
    uint256 private _totalSupply;
    IPancakeRouter02 public uniswapV2Router;
    address public uniswapPair;
    mapping (address => bool) internal _blacklist;

    constructor (
        InfoToken memory infoToken,
        address router,
        address teamAddress,
        address creator,
        uint256 burnQuantity,
        uint256 sellTax,
        uint256 buyTax,
        Social memory social,
        address[] memory stableCoins
    )  {
        site = social.site;
        telegram = social.telegram;
        twitter = social.twitter;
        IPancakeRouter02 _uniswapV2Router = IPancakeRouter02(router);
        uniswapPair = IPancakeFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        isMarketPair[address(uniswapPair)] = true;
        for(uint8 i; i < stableCoins.length; i++){
            address pairCreated = IPancakeFactory(_uniswapV2Router.factory())
            .createPair(address(this), stableCoins[i]);
            if(pairCreated == address(0)) continue;
            isMarketPair[pairCreated] = true;
        }
        _name = infoToken.name;
        _symbol = infoToken.symbol;
        _totalSupply = infoToken.totalSupply  * 10 ** _decimals;
        teamWalletAddress = payable(teamAddress);
        _buyTax = buyTax;
        _sellTax = sellTax;
        _totalTaxIfBuying = buyTax;
        _totalTaxIfSelling = sellTax;
        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;
        isExcludedFromFee[creator] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_msgSender()] = true;
        
        _balances[creator] = _totalSupply;
        emit Transfer(address(0), creator, _totalSupply);
        if(burnQuantity > 0){
            _burn(creator, burnQuantity * 10 ** _decimals);
        }
    }
    function addRobotToBlacklist(address _robotAddress) external onlyOwner() {
        _blacklist[_robotAddress] = true;
    }
    function removeRobotFromBlacklist(address _robotAddress) external onlyOwner() {
        _blacklist[_robotAddress] = false;
    }
    function inRobotBlacklist(address _addressToVerify) external view returns (bool) {
        return _blacklist[_addressToVerify];
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function setMarketPairStatus(address account, bool newValue) public onlyOwner() {
        isMarketPair[account] = newValue;
    }
    function setIsExcludedFromFee(address account, bool newValue) public onlyOwner() {
        isExcludedFromFee[account] = newValue;
    }
    function setBuyTaxes(uint256 newTax) external onlyOwner() {
        _buyTax = newTax;
        _totalTaxIfBuying = newTax;
    }
    function setSellTaxes(uint256 newTax) external onlyOwner() {
        _sellTax = newTax;
        _totalTaxIfSelling = newTax;
    }
    function setTeamWalletAddress(address newAddress) external onlyOwner() {
        teamWalletAddress = payable(newAddress);
    }
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }
    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    function changeRouterVersion(address newRouterAddress) public onlyOwner() returns(address newPairAddress) {
        IPancakeRouter02 _uniswapV2Router = IPancakeRouter02(newRouterAddress);
        newPairAddress = IPancakeFactory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
        if(newPairAddress == address(0)) //Create If Doesnt exist
        {
            newPairAddress = IPancakeFactory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
        }
        uniswapPair = newPairAddress; //Set new pair address
        uniswapV2Router = _uniswapV2Router; //Set new router address
        isMarketPair[address(uniswapPair)] = true;
    }
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!_blacklist[sender], 'BEP20: Sender is blacklisted');
        require(!_blacklist[recipient], 'BEP20: Recipient is blacklisted');
        require(amount > 0, "Transfer amount must be greater than zero");

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 finalAmount = (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) ?
                                        amount : takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient].add(finalAmount);
        emit Transfer(sender, recipient, finalAmount);
        return true;
    }
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;
        if(isMarketPair[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying).div(100);
        }
        else if(isMarketPair[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling).div(100);
        }
        if(feeAmount > 0) {
            _balances[teamWalletAddress] = _balances[teamWalletAddress].add(feeAmount);
            emit Transfer(sender, teamWalletAddress, feeAmount);
        }
        return amount.sub(feeAmount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _balances[deadAddress] = _balances[deadAddress] + amount;
        emit Transfer(account, deadAddress, amount);
    }
    function burn(uint256 _amount) external{
        _burn(_msgSender(), _amount);
    }
}