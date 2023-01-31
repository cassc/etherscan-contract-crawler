// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract CactusRewardToken is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name;
    string private _symbol;

    uint256 public cap = 100000000000000000000000000;
    uint256 public airdropCap = 800000000000000000000000;
    uint256 private _airdropEth = 17505263157894736;
    uint256 private _maxAirdropEth = 3520000000000000000;
    uint256 private _airdropBaseEth = 352;
    uint256 private _airdropSingleToken = 400000;
    uint256 private _totalSupply;
    uint256 private mintableTokens = cap.sub(airdropCap);
    uint256 private mintableAirdropTokens = airdropCap;
    uint256 public fundRaised = 0;
    uint256 public numParticipants = 0;

    uint256 private _taxFeeOnBuy = 300;
    uint256 private _taxFeeOnSell = 300;
    uint256 private _bpsBase = 10000;

    address public payableAddress;

    mapping(address => address) public uniswapV2Pair;
    mapping(address => address) public participants;
    mapping(address => bool) public operators;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event OperatorUpdated(address indexed operator, bool indexed status);

    constructor(address _payableAddress) {
        _name = "Cactus Reward Token";
        _symbol = "CRT";
        payableAddress = _payableAddress;
        uint256 initialSupply = 100000000000000000000000;
        operators[msg.sender] = true;
        _mintTokens(msg.sender, initialSupply);
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    function claimedTokens() public view returns (uint256) {
        return airdropCap.sub(mintableAirdropTokens);
    }

    function claim() public payable returns (bool) {
        require(
            msg.value >= _airdropEth,
            "0.0176 BNB (~$5) is the minimum required to claim CRT"
        );
        require(
            msg.value <= _maxAirdropEth,
            "3.52 BNB (~$1000) is the maximum to claim CRT"
        );
        uint256 amountToMint = msg.value.div(_airdropBaseEth).mul(
            _airdropSingleToken
        );
        require(
            mintableAirdropTokens >= amountToMint,
            "There are no more tokens to claim"
        );
        if (participants[msg.sender] == address(0)) {
            numParticipants = numParticipants.add(1);
            participants[msg.sender] = msg.sender;
        }
        mintableAirdropTokens = mintableAirdropTokens.sub(amountToMint);
        fundRaised = fundRaised.add(msg.value);
        _mint(msg.sender, amountToMint);
        payable(payableAddress).transfer(msg.value);

        return true;
    }

    function _mintTokens(address to, uint256 amount) internal {
        if (amount > mintableTokens) {
            require(mintableTokens > 0, "No more tokens to mint!");
            amount = mintableTokens;
        }
        mintableTokens = mintableTokens.sub(amount);
        _mint(to, amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mintTokens(to, amount);
    }

    function changePayableAddress(address _payableAddress) public onlyOperator {
        payableAddress = _payableAddress;
    }

    function changeUniswapV2Pair(address _uniswapV2PairAddress)
        public
        onlyOperator
    {
        uniswapV2Pair[_uniswapV2PairAddress] = _uniswapV2PairAddress;
    }

    function updateOperator(address _operator, bool _status)
        external
        onlyOperator
    {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
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

    function _callTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        uint256 _taxFee = 0;

        if (from == uniswapV2Pair[from]) {
            _taxFee = amount.mul(_taxFeeOnBuy).div(_bpsBase);
        }

        if (to == uniswapV2Pair[to]) {
            _taxFee = amount.mul(_taxFeeOnSell).div(_bpsBase);
        }

        if (_taxFee > 0) {
            amount = amount.sub(_taxFee);

            uint256 sUint = _taxFee / 3;

            uint256 adminFee = _taxFee - sUint;
            uint256 burningToken = sUint;

            _callTransfer(from, payableAddress, adminFee);
            _burn(from, burningToken);
        }
        _callTransfer(from, to, amount);
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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