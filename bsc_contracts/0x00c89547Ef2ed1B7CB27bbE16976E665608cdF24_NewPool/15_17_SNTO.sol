// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "./utils/Ownable.sol";
import "./utils/SafeERC20.sol";
import "./utils/IERC20.sol";
import "./utils/ERC20.sol";
import "./utils/IPancakeRouter02.sol";
import "./utils/IPancakeFactory.sol";
import "./utils/IPancakePair.sol";
import "./utils/SafeMath.sol";
import "./utils/Address.sol";

contract SNTO is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    receive() external payable {}

    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    address public marketingAddress;
    address public usdtAddress;

    uint256 public sellFeeRate;
    uint256 public buyFeeRate;
    uint256 public transFeeRate;

    uint256 public removeRate;
    uint256 public removeLPBurnRate;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isMarketPair;
    mapping(address => bool) public isBlackList;
    mapping(address => bool) public isExcludedFromFee;

    uint256 public startTime;
    uint256 public removeLPFeeDuration;

    bool public takeFeeDisabled;
    bool public allowSell;
    bool public allowBuy;
    bool public addLiquidityEnabled;
    bool public feeConvertEnabled;

    address public immutable deadAddress =
    0x000000000000000000000000000000000000dEaD;
    uint256 private _totalSupply = 10000000000 * 10 ** _decimals;
    address public router;
    address public pairAddress;
    bool inSwapAndLiquify;

    constructor(
        address _marketing,
        address _routerAddress,
        address _usdtAddress
    ) {
        _name = "Santosa Bank";
        _symbol = "SNTO";

        router = _routerAddress;
        marketingAddress = _marketing;


        sellFeeRate = 600;
        buyFeeRate = 600;
        transFeeRate = 600;

        removeLPBurnRate = 5000;
        removeRate = 600;
        removeLPFeeDuration = 30 days;

        startTime = block.timestamp;
        usdtAddress = _usdtAddress;

        pairAddress = IPancakeFactory(IPancakeRouter01(router).factory())
        .createPair(address(this), _usdtAddress);

        isExcludedFromFee[_marketing] = true;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isMarketPair[address(pairAddress)] = true;

        addLiquidityEnabled = false;
        allowSell = false;
        allowBuy = false;
        takeFeeDisabled = false;
        feeConvertEnabled = false;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function setExcludedFromFee(address _address, bool _excluded) public onlyOwner {
        isExcludedFromFee[_address] = _excluded;
    }

    function setRates(uint256 _sell, uint256 _buy, uint256 _trans, uint256 _removeBurn, uint256 _remove) public onlyOwner {
        sellFeeRate = _sell;
        buyFeeRate = _buy;
        transFeeRate = _trans;
        removeLPBurnRate = _removeBurn;
        removeRate = _remove;
    }

    function setRemoveLPFeeDuration(uint256 _duration) public onlyOwner {
        removeLPFeeDuration = _duration;
    }

    function rescueToken(address tokenAddress, uint256 tokens)
    public
    onlyOwner
    returns (bool success)
    {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function rescueBNB(address payable _recipient) public onlyOwner {
        _recipient.transfer(address(this).balance);
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
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

    function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMarketPairStatus(address account, bool newValue)
    public
    onlyOwner
    {
        isMarketPair[account] = newValue;
    }

    function setFeeConvertEnabled(bool _value) public onlyOwner {
        feeConvertEnabled = _value;
    }

    function setTakeFeeDisabled(bool _value) public onlyOwner {
        takeFeeDisabled = _value;
    }

    function setTradeEnabled(bool _buy, bool _sell) public onlyOwner {
        allowBuy = _buy;
        allowSell = _sell;
    }

    function setAddLiquidityEnabled(bool _value) public onlyOwner {
        addLiquidityEnabled = _value;
    }

    function setIsBlackList(address account, bool newValue) public onlyOwner {
        isBlackList[account] = newValue;
    }

    function setAddress(address _marketing) external onlyOwner {
        marketingAddress = _marketing;
        isExcludedFromFee[marketingAddress] = true;
    }

    function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (inSwapAndLiquify) {
            _basicTransfer(sender, recipient, amount);
        } else {
            require(
                !isBlackList[sender] && !isBlackList[recipient],
                "address is black"
            );
            if (amount == 0) {
                _balances[recipient] = _balances[recipient].add(amount);
                return;
            }

            _balances[sender] = _balances[sender].sub(
                amount,
                "Insufficient Balance"
            );

            bool needTakeFee;
            bool isRemoveLP;
            bool isAdd;

            if (!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]) {
                needTakeFee = true;
                if (isMarketPair[recipient]) {
                    isAdd = _isAddLiquidity();
                    if (isAdd) {
                        require(addLiquidityEnabled, "add liquidity is disabled");
                        needTakeFee = false;
                    }
                } else {
                    isRemoveLP = _isRemoveLiquidity();
                }
            }


            if (
                feeConvertEnabled &&
                isMarketPair[recipient] &&
                balanceOf(address(this)) > 0
            ) {
                swapTokensForUSDT(balanceOf(address(this)), marketingAddress);
            }

            uint256 finalAmount = (isExcludedFromFee[sender] ||
            isExcludedFromFee[recipient]) ||
            takeFeeDisabled ||
            !needTakeFee
            ? amount
            : takeFee(sender, recipient, amount, isRemoveLP);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
        }
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapTokensForUSDT(uint256 tokenAmount, address to)
    private
    lockTheSwap
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0x55d398326f99059fF775485246999027B3197955;

        _approve(address(this), address(router), tokenAmount);

        IPancakeRouter02(router)
        .swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     */
    function rescueTokens(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(this), "cannot be this token");
        IERC20(_tokenAddress).safeTransfer(
            address(msg.sender),
            IERC20(_tokenAddress).balanceOf(address(this))
        );
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount,
        bool isRemoveLP
    ) internal returns (uint256) {
        uint256 feeAmount = 0;
        address _sender = sender;
        uint256 _amount = amount;


        if (isMarketPair[sender] || isMarketPair[recipient]) {
            uint256 removeAmount = 0;
            uint256 removeBurnAmount = 0;
            uint256 sellAmount = 0;
            uint256 buyAmount = 0;
            if (isRemoveLP) {
                if (block.timestamp < startTime + removeLPFeeDuration) {
                    removeBurnAmount = _amount.mul(removeLPBurnRate).div(10000);
                }
                removeAmount = _amount.mul(removeRate).div(10000);
            } else {
                if (isMarketPair[sender]) {
                    //buy
                    require(allowBuy, "buy closed");
                    buyAmount = _amount.mul(buyFeeRate).div(10000);
                }
                if (isMarketPair[recipient]) {
                    //sell
                    require(allowSell, "sell closed");
                    sellAmount = _amount.mul(sellFeeRate).div(10000);
                }
            }

            if (removeBurnAmount > 0) {
                _balances[marketingAddress] = _balances[marketingAddress].add(
                    removeBurnAmount
                );
                emit Transfer(_sender, marketingAddress, removeBurnAmount);
            }

            if (removeAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(
                    removeAmount
                );
                emit Transfer(_sender, address(this), removeAmount);
            }
            if (sellAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(
                    sellAmount
                );
                emit Transfer(_sender, address(this), sellAmount);
            }
            if (buyAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(
                    buyAmount
                );
                emit Transfer(_sender, address(this), buyAmount);
            }
            feeAmount = removeBurnAmount.add(removeAmount).add(sellAmount).add(buyAmount);
        } else {
            //transfer
            uint256 transAmount = _amount.mul(transFeeRate).div(10000);
            if (transAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(
                    transAmount
                );
                emit Transfer(_sender, address(this), transAmount);
            }
            feeAmount = transAmount;
        }
        return _amount.sub(feeAmount);
    }

    function _isAddLiquidity() internal view returns (bool isAdd) {
        IPancakePair mainPair = IPancakePair(pairAddress);
        (uint256 r0, uint256 r1,) = mainPair.getReserves();
        address tokenOther = usdtAddress;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint256 bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isAdd = bal > r;
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove) {
        IPancakePair mainPair = IPancakePair(pairAddress);
        (uint256 r0, uint256 r1,) = mainPair.getReserves();
        address tokenOther = usdtAddress;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }
        uint256 bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }
}