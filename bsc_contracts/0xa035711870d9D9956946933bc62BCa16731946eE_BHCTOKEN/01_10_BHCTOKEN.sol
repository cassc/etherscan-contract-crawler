// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IBHCDAO.sol";
import "./IBHCShareDiv.sol";
import "./IBHCLpDiv.sol";
import "./ISwapRouter.sol";
import "./ISwapFactory.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract BHCTOKEN is Ownable {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    bool private _isBlackOpen = true;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _blacklist;

    address public daoAddress;

    address public swapPair;
    address public shareAddress;
    uint256 public shareBuyFee = 100;
    uint256 public shareSellFee = 200;
    address public lpDivAddress;
    uint256 public lpDivBuyFee = 100;
    uint256 public lpDivSellFee = 100;
    address public marketAddress;
    uint256 public marketFee = 100;
    uint256 public buyBurnFee = 0;
    address public upShareAddress;
    uint256[] public upShareFees = [50, 20, 20, 20, 10, 10, 10, 10];

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event ProcessedLpDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        address indexed processor
    );

    constructor(
        address _router,
        address _usdt,
        address _dao,
        address _share,
        address _lpDiv,
        address _market,
        address _upShare
    ) {
        _name = "BHC";
        _symbol = "BHC";

        address swapFactory = ISwapRouter(_router).factory();
        swapPair = ISwapFactory(swapFactory).createPair(address(this), _usdt);

        daoAddress = _dao;
        shareAddress = _share;
        lpDivAddress = _lpDiv;
        marketAddress = _market;
        upShareAddress = _upShare;

        address sender = _msgSender();
        _totalSupply = 10000000 * 10**9;
        _balances[sender] = _totalSupply;
        emit Transfer(address(0), sender, _totalSupply);

        _isExcludedFromFee[sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0xdead)] = true;
        _isExcludedFromFee[shareAddress] = true;
        _isExcludedFromFee[lpDivAddress] = true;
        _isExcludedFromFee[marketAddress] = true;
        _isExcludedFromFee[upShareAddress] = true;
    }

    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 9;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function isBlack(address account) public view returns (bool) {
        return _blacklist[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function setShare(
        address share,
        uint256 buyFee,
        uint256 sellFee
    ) public onlyOwner {
        shareAddress = share;
        shareBuyFee = buyFee;
        shareSellFee = sellFee;
    }

    function setLpDiv(
        address lpdiv,
        uint256 buyFee,
        uint256 sellFee
    ) public onlyOwner {
        lpDivAddress = lpdiv;
        lpDivBuyFee = buyFee;
        lpDivSellFee = sellFee;
    }

    function setMarket(address market, uint256 fee) public onlyOwner {
        marketAddress = market;
        marketFee = fee;
    }

    function setBuyBurnFee(uint256 fee) public onlyOwner {
        buyBurnFee = fee;
    }

    function setUpShare(address upShare, uint256[] memory fees)
        public
        onlyOwner
    {
        upShareAddress = upShare;
        upShareFees = fees;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setBlacklist(address _address, bool _flag) external onlyOwner {
        _blacklist[_address] = _flag;
    }

    function setIsBlackOpen(bool _open) external onlyOwner {
        _isBlackOpen = _open;
    }

    function setClaim(
        address payable to,
        address token,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = to.call{value: amount}("");
            require(
                success,
                "Error: unable to send value, to may have reverted"
            );
        } else IERC20(token).transfer(to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            unchecked {
                _balances[from] = fromBalance - amount;
            }
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        } else {
            require(
                !_blacklist[from] && !_blacklist[to],
                "ERC20: the current user is in the blacklist and cannot be transferred"
            );
            if (from == swapPair) {
                if (_isBlackOpen) _blacklist[to] = true;
                _tokenBuyWithFee(from, to, amount);
            } else {
                _tokenSellWithFee(from, to, amount);
            }
            try IBHCLpDiv(lpDivAddress).process() returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedLpDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    tx.origin
                );
            } catch {}
        }
    }

    function _tokenBuyWithFee(
        address from,
        address to,
        uint256 amount
    ) private {
        // Share fee
        uint256 shareAmount = amount.mul(shareBuyFee).div(10000);
        if (shareAmount > 0) {
            _balances[shareAddress] = _balances[shareAddress].add(shareAmount);
            IBHCShareDiv(shareAddress).distributeDividends(shareAmount);
            emit Transfer(from, shareAddress, shareAmount);
        }
        // Lp Div fee
        uint256 lpDivAmount = amount.mul(lpDivBuyFee).div(10000);
        if (lpDivAmount > 0) {
            _balances[lpDivAddress] = _balances[lpDivAddress].add(lpDivAmount);
            IBHCLpDiv(lpDivAddress).distributeDividends(lpDivAmount);
            emit Transfer(from, lpDivAddress, lpDivAmount);
        }
        // Marketing fee
        uint256 marketAmount = amount.mul(marketFee).div(10000);
        if (marketAmount > 0) {
            _balances[marketAddress] = _balances[marketAddress].add(
                marketAmount
            );
            emit Transfer(from, marketAddress, marketAmount);
        }
        // Burn fee
        uint256 burnAmount = amount.mul(buyBurnFee).div(10000);
        if (burnAmount > 0) {
            address burnAddress = address(0xdead);
            _balances[burnAddress] = _balances[burnAddress].add(burnAmount);
            emit Transfer(from, burnAddress, burnAmount);
        }
        // Ramain amount
        _balances[from] = _balances[from].sub(amount);
        uint256 toAmount = amount
            .sub(shareAmount)
            .sub(lpDivAmount)
            .sub(marketAmount)
            .sub(burnAmount);
        _balances[to] = _balances[to].add(toAmount);
        emit Transfer(from, to, toAmount);
        // Up Levels share
        IBHCDAO BHCDAO = IBHCDAO(daoAddress);
        address parent = BHCDAO.getParent(to);
        for (uint8 i = 0; i < upShareFees.length; i++) {
            if (parent == address(0)) break;
            uint256 upShareAmount = amount.mul(upShareFees[i]).div(10000);
            if (
                upShareAmount > 0 && _balances[upShareAddress] > upShareAmount
            ) {
                _balances[upShareAddress] = _balances[upShareAddress].sub(
                    upShareAmount
                );
                _balances[parent] = _balances[parent].add(upShareAmount);
                emit Transfer(upShareAddress, parent, upShareAmount);
                parent = BHCDAO.getParent(parent);
            }
        }
    }

    function _tokenSellWithFee(
        address from,
        address to,
        uint256 amount
    ) private {
        // Share fee
        uint256 shareAmount = amount.mul(shareSellFee).div(10000);
        if (shareAmount > 0) {
            _balances[shareAddress] = _balances[shareAddress].add(shareAmount);
            IBHCShareDiv(shareAddress).distributeDividends(shareAmount);
            emit Transfer(from, shareAddress, shareAmount);
        }
        // Lp Div fee
        uint256 lpDivAmount = amount.mul(lpDivSellFee).div(10000);
        if (lpDivAmount > 0) {
            _balances[lpDivAddress] = _balances[lpDivAddress].add(lpDivAmount);
            IBHCLpDiv(lpDivAddress).distributeDividends(lpDivAmount);
            emit Transfer(from, lpDivAddress, lpDivAmount);
        }
        // Ramain amount
        _balances[from] = _balances[from].sub(amount);
        // Set cannot be sold out
        if (_balances[from] == 0) {
            _balances[from] = amount.div(10000);
            amount = amount.sub(_balances[from]);
        }
        uint256 toAmount = amount.sub(shareAmount).sub(lpDivAmount);
        _balances[to] = _balances[to].add(toAmount);
        emit Transfer(from, to, toAmount);
    }
}
