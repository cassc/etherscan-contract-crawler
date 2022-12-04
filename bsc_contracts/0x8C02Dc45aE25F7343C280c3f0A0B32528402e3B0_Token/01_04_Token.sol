pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBEP20.sol";

contract Token is Ownable, IBEP20
{

    uint internal constant PRECISION = 1000000;
    uint internal constant REFLECTION_FEE_PROP = 50 * PRECISION;
    uint internal constant BURN_FEE_PROP = 50 * PRECISION;
    uint internal constant FEE_DIV_BASE = 100 * PRECISION;
    uint internal constant MAX = ~uint(0);
    string internal constant NAME = "Usuku 24h Token Round #1";
    string internal constant SYMBOL = "Usuku #1";
    
    uint internal constant POW_FACTOR = 10;

    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    uint private _tTotal;
    uint private _rTotal;
    uint public genesisBlock;
    uint public finalBlock;
    bool public started;

    event Started();
    event Finished();
    
    constructor()
        Ownable()
    {
        uint total = 20 * 1e6 * 10 ** 9;
        _tTotal = total;
        uint rTotal = MAX - (MAX % total);
        _rTotal = rTotal;
        _balances[_msgSender()] = rTotal;
        emit Transfer(address(0), address(this), total);
    }

    receive()
        external payable
    {

    }

    function start()
        external 
        onlyOwner
    {
        started = true;
        genesisBlock = block.number;
        finalBlock = block.number + 60 * 60 * 24 / 3; // BSC: 1 block every 3 seconds
        renounceOwnership();

        emit Started();
    }

    function finish()
        external
    {
        uint maxBlock = finalBlock;
        require(maxBlock > 0 && _getBlocksToEnd(maxBlock) == 0, "Available after 24H from start");
        started = false;
      
        
        emit Finished();
    }

    function getBlocksToEnd()
        external view 
        returns(uint)
    {
        return _getBlocksToEnd(finalBlock);
    }

    function _getBlocksToEnd(uint pFinalBlock)
        internal view 
        returns(uint)
    {
        if(block.number >= pFinalBlock) { return 0; }

        return pFinalBlock - block.number;
    }

    function getOwner() external override pure returns (address) { return address(0); }

    function name() public override pure returns (string memory) { return NAME; }

    function symbol() public override pure returns (string memory) { return SYMBOL; }

    function decimals() public override pure returns (uint8) { return 9; }

    function totalSupply() public override view returns (uint) { return _tTotal; }

    function balanceOf(address account) public override view returns (uint) { return _tokenFromReflection(_balances[account]); }

    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    function allowance(address owner, address spender) external override view returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);

        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);

        return true;
    }

    function _tokenFromReflection(uint rAmount) private view returns(uint) { return rAmount / _getRate(); }

    function calculateFee()
        public view 
        returns (uint)
    {
        if(!started)
        {
            return 0;
        }
        uint minFee = 1 * PRECISION;
        uint maxFee = 100 * PRECISION;
        uint maxBlock = finalBlock;
        if(_getBlocksToEnd(maxBlock) == 0)
        {
            return maxFee;
        }
        uint minBlock = genesisBlock;
        if(minBlock == 0 || maxBlock == 0)
        {
            return minFee;
        }
        minBlock = minBlock ** POW_FACTOR;
        return minFee + (block.number ** POW_FACTOR - minBlock) * (maxFee - minFee) / (maxBlock ** POW_FACTOR - minBlock);
    }

    function getFeeBase() 
        external pure 
        returns (uint)
    {
        return FEE_DIV_BASE;
    }

    function _transfer(address sender, address recipient, uint amount) private {
        require(sender != address(0), "ERC20: transfer route the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        (
            uint rAmount, 
            uint rTransferAmount, 
            uint rReflectionFee, 
            uint rBurnFee,
            uint tTransferAmount, 
            /*uint tReflectionFee*/,
            uint tBurnFee
        ) = _getValues(amount);        
        _balances[sender] -= rAmount;
        _balances[recipient] += rTransferAmount;
        _rTotal -= rReflectionFee + rBurnFee;
        _tTotal -= tBurnFee;
        emit Transfer(sender, recipient, tTransferAmount);
    }


    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "ERC20: approve route the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _getValues(uint tAmount) 
        private view 
        returns (uint rAmount, uint rTransferAmount, uint rReflectionFee, uint rBurnFee, uint tTransferAmount, uint tReflectionFee, uint tBurnFee) 
    {
        (tTransferAmount, tReflectionFee, tBurnFee) = _getTValues(tAmount);
        (rAmount, rTransferAmount, rReflectionFee, rBurnFee) = _getRValues(tAmount, tReflectionFee, tBurnFee, _getRate());

        return (rAmount, rTransferAmount, rReflectionFee, rBurnFee, tTransferAmount, tReflectionFee, tBurnFee);
    }

    function _getTValues(uint tAmount) private view 
        returns (uint tTransferAmount, uint tReflectionFee, uint tBurnFee) 
    {
		uint fee = tAmount * calculateFee() / FEE_DIV_BASE;
		tReflectionFee = fee * REFLECTION_FEE_PROP / FEE_DIV_BASE;
        tBurnFee = fee * BURN_FEE_PROP / FEE_DIV_BASE;
        tTransferAmount = tAmount - tReflectionFee - tBurnFee;
    }

    function _getRate() private view returns(uint) {
        return _rTotal / _tTotal;
    }

    function _getRValues(uint tAmount, uint tReflectionFee, uint tBurnFee, uint currentRate) private pure returns (
        uint rAmount,
        uint rTransferAmount,
        uint rReflectionFee,
        uint rBurnFee
    ) {
        rAmount = tAmount * currentRate;
        rReflectionFee = tReflectionFee * currentRate;
        rBurnFee = tBurnFee * currentRate;
        rTransferAmount = rAmount - rReflectionFee - rBurnFee;
    }
}