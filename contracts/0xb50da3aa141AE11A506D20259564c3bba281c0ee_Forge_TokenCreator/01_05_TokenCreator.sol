//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.8;

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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

interface DexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface DexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Forge_GeneratedToken is ERC20, Ownable {
    struct Tax {
        uint256 devTax;
        uint256 liquidityTax;
        uint256 burnTax;
    }

    uint256 private constant _totalSupply = 1e7 * 1e18;

    //Router
    DexRouter public uniswapRouter;
    address public pairAddress;

    //Taxes
    Tax public buyTaxes = Tax(3, 3, 3);
    Tax public sellTaxes = Tax(3, 3, 3);
    uint256 public totalBuyFees = 9;
    uint256 public totalSellFees = 9;

    //Whitelisting from taxes/maxwallet/txlimit/etc
    mapping(address => bool) private whitelisted;

    //Swapping
    uint256 public swapTokensAtAmount = _totalSupply / 100000; //after 0.001% of total supply, swap them
    bool public swapAndLiquifyEnabled = true;
    bool public isSwapping = false;
    bool public tradingStatus = false;

    //Wallets
    address public DevWallet;
    address public BurnWallet = 0x000000000000000000000000000000000000dEaD;

    constructor(string memory _name, string memory _symbol, uint256 _supply) ERC20(_name, _symbol) {
        //0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 test
        //0x10ED43C718714eb63d5aA57B78B54704E256024E Pancakeswap on mainnet
        //LFT swap on ETH 0x4f381d5fF61ad1D0eC355fEd2Ac4000eA1e67854
        //UniswapV2 on ETHMain net 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        //bscscan testnet 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        uniswapRouter = DexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // do not whitelist liquidity pool, otherwise there wont be any taxes
        whitelisted[msg.sender] = true;
        whitelisted[address(uniswapRouter)] = true;
        whitelisted[address(this)] = true;
        _mint(msg.sender, _supply);
    }

    function startTrading(address _pairAddress) external onlyOwner{
        pairAddress = _pairAddress;
        tradingStatus = true;
    }

    function setDevWallet(address _newDevWallet) external onlyOwner {
        require(_newDevWallet != address(0), "new dev wallet can not be dead address!");
        DevWallet = _newDevWallet;
    }

    function setBuyFees(
        uint256 _lpTax,
        uint256 _devTax,
        uint256 _burnTax
    ) external onlyOwner {
        require(_lpTax + _devTax + _burnTax <= 30, "Total tax must be less than 30%");
        buyTaxes.devTax = _devTax;
        buyTaxes.liquidityTax = _lpTax;
        buyTaxes.burnTax = _burnTax;
        totalBuyFees = _lpTax + _devTax + _burnTax;
    }

function setSellFees(
        uint256 _lpTax,
        uint256 _devTax,
        uint256 _burnTax
    ) external onlyOwner {
        require(_lpTax + _devTax + _burnTax <= 30, "Total tax must be less than 30%");
        sellTaxes.devTax = _devTax;
        sellTaxes.liquidityTax = _lpTax;
        sellTaxes.burnTax = _burnTax;
        totalSellFees = _lpTax + _devTax + _burnTax;
    }

    function setSwapTokensAtAmount(uint256 _newAmount) external onlyOwner {
        require(_newAmount > 0, "Minimum swap amount must be greater than 0!");
        swapTokensAtAmount = _newAmount;
    }

    function toggleSwapping() external onlyOwner {
        swapAndLiquifyEnabled = (swapAndLiquifyEnabled == true) ? false : true;
    }

    function setWhitelist(address _wallet, bool _status) external onlyOwner {
        whitelisted[_wallet] = _status;
    }

    function checkWhitelist(address _wallet) external view returns (bool) {
        return whitelisted[_wallet];
    }


    function _takeTax(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (whitelisted[_from] || whitelisted[_to]) {
            return _amount;
        }
        require(tradingStatus, "Trading is not enabled yet!");
        uint256 totalTax = 0;
        if (_to == pairAddress) {
            totalTax = totalSellFees;
        } else if (_from == pairAddress) {
            totalTax = totalBuyFees;
        }
        uint256 tax = (_amount * totalTax) / 100;
        super._transfer(_from, address(this), tax);
        return (_amount - tax);
    }


    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        uint256 toTransfer = _takeTax(_from, _to, _amount);

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if (
            swapAndLiquifyEnabled &&
            pairAddress == _to &&
            canSwap &&
            !whitelisted[_from] &&
            !whitelisted[_to] &&
            !isSwapping
        ) {
            isSwapping = true;
            manageTaxes();
            isSwapping = false;
        }
        super._transfer(_from, _to, toTransfer);
    }


    function manageTaxes() internal {
        uint256 taxAmount = balanceOf(address(this));

        //Getting total Fee Percentages And Caclculating Portinos for each tax type
        Tax memory bt = buyTaxes;
        Tax memory st = sellTaxes;
        uint256 totalTaxes = totalBuyFees + totalSellFees;

        if(totalTaxes == 0){
            return;
        }
        
        uint256 totalDevTax = bt.devTax + st.devTax;
        uint256 totalLPTax = bt.liquidityTax + st.liquidityTax;
        uint256 totalBurnTax = bt.burnTax + st.burnTax;
        
        //Calculating portions for each type of tax (dev, burn, liquidity)
        uint256 lpPortion = (taxAmount * totalLPTax) / totalTaxes;
        uint256 devPortion = (taxAmount * totalDevTax) / totalTaxes;
        uint256 burningPortion = (taxAmount * totalBurnTax) / totalTaxes;

        //Add Liquidty taxes to liqudity pool
        if(lpPortion > 0){
            swapAndLiquify(lpPortion);
        }

        //Burning
        if(burningPortion > 0){
            super._transfer(address(this), BurnWallet, burningPortion);
        }

         //sending to dev wallet
        if(devPortion > 0){
            swapToETH(balanceOf(address(this)));
            (bool success, ) = DevWallet.call{value : address(this).balance}("");
        }
    }


    function swapAndLiquify(uint256 _amount) internal {
        uint256 firstHalf = _amount / 2;
        uint256 otherHalf = _amount - firstHalf;
        uint256 initialETHBalance = address(this).balance;

        //Swapping first half to ETH
        swapToETH(firstHalf);
        uint256 received = address(this).balance - initialETHBalance;
        addLiquidity(otherHalf, received);
    }

    function swapToETH(uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), _amount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function updateDexRouter(address _newDex) external onlyOwner {
        uniswapRouter = DexRouter(_newDex);
        pairAddress = DexFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );
    }

    function withdrawStuckETH() external onlyOwner {
        (bool success, ) = address(msg.sender).call{value: address(this).balance}("");
        require(success, "transfering ETH failed");
    }

    function withdrawStuckTokens(address erc20_token) external onlyOwner {
        bool success = IERC20(erc20_token).transfer(
            msg.sender,
            IERC20(erc20_token).balanceOf(address(this))
        );
        require(success, "trasfering tokens failed!");
    }

    function transferOwner(address _newOwner) public onlyOwner{
        transferOwnership(_newOwner);
    }

    receive() external payable {}
}

contract Forge_TokenCreator is Ownable {

    address public FeeReceiver = 0x56F7B7C624Fd51449b370F373D9d750D620DF963;
    uint256 public creationFee = 0.15 ether;
    mapping(address=>address[]) public tokensOf;

    function createNewToken(string memory _name, string memory _symbol, uint256 _totalSupply,
    address devWallet,
     uint256 buyDevFee, uint256 buyLiquidityFee, uint256 buyBurnFee
     , uint256 sellDevFee, uint256 sellLiquidityFee, uint256 sellBurnFee) public payable{

        require(msg.value >= creationFee, "Please provide creation fee!");
        payable(FeeReceiver).transfer(msg.value);

        Forge_GeneratedToken newToken = new Forge_GeneratedToken(_name, _symbol, _totalSupply);
        tokensOf[msg.sender].push(address(newToken));
        newToken.setBuyFees(buyLiquidityFee, buyDevFee, buyBurnFee);
        newToken.setSellFees(sellLiquidityFee, sellDevFee, sellBurnFee);
        newToken.setDevWallet(devWallet);
        newToken.transferOwner(msg.sender);
        IERC20(address(newToken)).transfer(msg.sender, IERC20(address(newToken)).balanceOf(address(this)));
    }

    function setFeeReceiver(address _newFeeReceiver) public onlyOwner{
        FeeReceiver = _newFeeReceiver;
    }

    function setCreationFee(uint256 _fees) public onlyOwner{
        creationFee = _fees;
    }

}