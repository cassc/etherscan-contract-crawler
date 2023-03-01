// SPDX-License-Identifier: MIT
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
import "./Invite.sol";

contract NFDAO is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    receive() external payable {}

    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    address public nodeAddress;
    address public marketingAddress;
    address public usdtAddress;
    address public swapAddress;

    address public invite;


    uint256 public transBurnRate;

    uint256 public tradeBurnRate;
    uint256 public tradeLiquidityRate;
    uint256 public tradeNodeRate;
    uint256 public tradeInviteRate;
    uint256[3] public inviteRates;


    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isMarketPair;
    mapping(address => bool) public isExcludedFromFee;

    uint256 public startTradeBlock;
    uint256 public startBlock;
    bool public swapEnabled;

    address public immutable deadAddress =
    0x000000000000000000000000000000000000dEaD;

    uint256 private _totalSupply = 300000 * 10 ** _decimals;
    address public router;
    address public pairAddress;
    bool inSwap;

    constructor(
        address _marketing,
        address _node,
        address _swap,
        address _router,
        address _usdt,
        address _invite
    ) {
        _name = "NFDAO";
        _symbol = "NFD";

        invite = _invite;
        router = _router;
        marketingAddress = _marketing;
        nodeAddress = _node;
        usdtAddress = _usdt;
        swapAddress = _swap;

        pairAddress = IPancakeFactory(IPancakeRouter01(router).factory())
        .createPair(address(this), _usdt);

        inviteRates = [5000, 3000, 2000];
        transBurnRate = 300;
        tradeLiquidityRate = 100;
        tradeBurnRate = 100;
        tradeNodeRate = 200;
        tradeInviteRate = 400;

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
        address _marketing,
        address _node,
        address _swap
    ) public onlyOwner {
        marketingAddress = _marketing;
        nodeAddress = _node;
        swapAddress = _swap;
    }

    function setSwapEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
    }

    function setInviteAddress(address _invite) public onlyOwner {
        invite = _invite;
    }

    function setExcludedFromFee(address _address, bool _excluded) public onlyOwner {
        isExcludedFromFee[_address] = _excluded;
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

            bool isRemoveLP;
            bool isAdd;

            if (startBlock == 0 && isMarketPair[recipient]) {
                startBlock = block.number;
            }
            if (!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]) {
                if (isMarketPair[recipient]) {
                    isAdd = _isAddLiquidity();
                }
                if (isMarketPair[sender]) {
                    isRemoveLP = _isRemoveLiquidity();
                }
            }

            if (
                swapEnabled &&
                isMarketPair[recipient] &&
                balanceOf(address(this)) > amount.div(2)
            ) {
                swapTokensForUSDT(amount.div(2), swapAddress);
            }


            uint256 finalAmount = (isExcludedFromFee[sender] ||
            isExcludedFromFee[recipient]) || isRemoveLP
            ? amount
            : takeFee(sender, recipient, amount, isAdd);

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
        bool isAdd
    ) internal returns (uint256) {
        uint256 feeAmount = 0;
        address _sender = sender;
        uint256 _amount = amount;

        if (isMarketPair[sender] && startTradeBlock + 100 >= block.number) {
            feeAmount = _amount.mul(99).div(100);
            _balances[marketingAddress] = _balances[marketingAddress].add(feeAmount);
            emit Transfer(sender, marketingAddress, feeAmount);
            return _amount.sub(feeAmount);
        }

        if (isMarketPair[sender] || isMarketPair[recipient]) {

            if (startTradeBlock == 0) {
                require(startBlock > 0 && isAdd, "!Trade");
            }

            uint256 burnAmount = _amount.mul(tradeBurnRate).div(10000);
            uint256 liquidityAmount = _amount.mul(tradeLiquidityRate).div(10000);
            uint256 nodeAmount = _amount.mul(tradeNodeRate).div(10000);

            uint256[3] memory amounts = Invite(invite).getTradeInviteAmounts(_amount, tradeInviteRate, inviteRates);
            address[] memory invites = Invite(invite).getParentsByLevel(isMarketPair[_sender] ? recipient : _sender, 3);

            if (burnAmount > 0) {
                _balances[deadAddress] = _balances[deadAddress].add(
                    burnAmount
                );
                emit Transfer(sender, deadAddress, burnAmount);
            }

            if (liquidityAmount > 0) {
                _balances[marketingAddress] = _balances[marketingAddress].add(
                    liquidityAmount
                );
                emit Transfer(sender, marketingAddress, liquidityAmount);
            }

            if (nodeAmount > 0) {
                _balances[nodeAddress] = _balances[nodeAddress].add(
                    nodeAmount
                );
                emit Transfer(sender, nodeAddress, nodeAmount);
            }


            address root = Invite(invite).rootAddress();

            for (uint256 i = 0; i < invites.length; i++) {
                if (invites[i] != address(0)) {
                    _balances[invites[i]] = _balances[invites[i]].add(
                        amounts[i]
                    );
                    emit Transfer(sender, invites[i], amounts[i]);
                } else {
                    _balances[root] = _balances[root].add(
                        amounts[i]
                    );
                    emit Transfer(sender, root, amounts[i]);
                }
                feeAmount = feeAmount.add(amounts[i]);
            }
            feeAmount = feeAmount.add(burnAmount).add(liquidityAmount).add(nodeAmount);

        } else {
            //transfer
            uint256 transBurnAmount = _amount.mul(transBurnRate).div(10000);
            if (transBurnAmount > 0) {
                _balances[deadAddress] = _balances[deadAddress].add(
                    transBurnAmount
                );
                emit Transfer(_sender, deadAddress, transBurnAmount);
            }
            feeAmount = transBurnAmount;
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