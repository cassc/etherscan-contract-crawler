// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./utils/Ownable.sol";
import "./utils/SafeERC20.sol";
import "./utils/IERC20.sol";
import "./utils/ERC20.sol";
import "./utils/SafeMath.sol";
import "./utils/Address.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";


contract Token is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    receive() external payable {}

    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    address public marketingAddress;
    address public usdtAddress;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isMarketPair;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isBlackList;

    uint256 public startTradeBlock;
    uint256 public startBlock;
    bool public swapEnabled;

    address public immutable deadAddress =
    0x000000000000000000000000000000000000dEaD;

    uint256 private _totalSupply = 102400000000 * 10 ** _decimals;
    address public router;
    address public pairAddress;
    bool inSwap;

    constructor(
        address _marketing,
        address _router
    ) {
        _name = "FrogGaga"; 
        _symbol = "GAGA";

        router = _router;
        marketingAddress = _marketing;

        pairAddress = IUniswapV2Factory(IUniswapV2Router01(router).factory())
        .createPair(address(this), IUniswapV2Router01(router).WETH());

        isExcludedFromFee[_marketing] = true;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isMarketPair[address(pairAddress)] = true;

        swapEnabled = false;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }


    function startTrade() external onlyOwner {
        require(0 == startTradeBlock, "trading");
        startTradeBlock = block.number;
    }

    function setAddresses(
        address _marketing
    ) public onlyOwner {
        marketingAddress = _marketing;
    }

    function setSwapEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
    }

    function setExcludedFromFee(address _address, bool _excluded) public onlyOwner {
        isExcludedFromFee[_address] = _excluded;
    }

    function setExcludedFromFees(address[] memory _address, bool _excluded) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            isExcludedFromFee[_address[i]] = _excluded;
        }
    }

    function setBlackList(address _address, bool _excluded) public onlyOwner {
        isBlackList[_address] = _excluded;
    }

    function setBlackLists(address[] memory _address, bool _excluded) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            isBlackList[_address[i]] = _excluded;
        }
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
        inSwap = true;
        _;
        inSwap = false;
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
        require(!isBlackList[sender] && !isBlackList[recipient], "BlackList");

        if (inSwap) {
            _basicTransfer(sender, recipient, amount);
        } else {
            if (amount == 0) {
                _balances[recipient] = _balances[recipient].add(amount);
                return;
            }

            _balances[sender] = _balances[sender].sub(
                amount,
                "Insufficient Balance"
            );

            if (startBlock == 0 && isMarketPair[recipient]) {
                startBlock = block.number;
            }

            if (
                swapEnabled &&
                isMarketPair[recipient] &&
                balanceOf(address(this)) > amount.div(2)
            ) {
                swapTokensForETH(amount.div(2), marketingAddress);
            }

            uint256 finalAmount = (isExcludedFromFee[sender] ||
                isExcludedFromFee[recipient])
                ? amount
                : takeFee(sender, recipient, amount);

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

    function swapTokensForETH(uint256 tokenAmount, address to)
    private
    lockTheSwap
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router01(router).WETH();

        _approve(address(this), address(router), tokenAmount);

        IUniswapV2Router02(router)
        .swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = 0;
        address _sender = sender;
        uint256 _amount = amount;
        require(startTradeBlock > 0, "Not start trade");
        if (isMarketPair[sender] && startTradeBlock + 50 >= block.number) {
            feeAmount = _amount.mul(99).div(100);
            _balances[marketingAddress] = _balances[marketingAddress].add(feeAmount);
            emit Transfer(sender, marketingAddress, feeAmount);
            return _amount.sub(feeAmount);
        }
        return _amount.sub(feeAmount);
    }
}