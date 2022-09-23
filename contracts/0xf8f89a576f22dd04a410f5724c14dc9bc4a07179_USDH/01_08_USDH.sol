// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "v3-periphery/interfaces/IQuoter.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IERC20Decimals.sol";
import "./interfaces/IERC20Old.sol";

contract USDH is IERC20, ReentrancyGuard {
    uint256 internal constant max256 = type(uint256).max;

    string private constant _name = "Hoard Dollar";
    string private constant _symbol = "USDH";
    uint8 private constant _decimals = 18;

    uint256 public _totalSupply;

    mapping (address => bool) public wasCollateral;
    mapping (address => bool) public collateralWhitelist;
    mapping (address => address) public collateralPairings;
    mapping (address => uint256) public collateralPairingsDecimals;
    mapping (address => uint24) public collateralFeeTiers;

    uint256 public constant minimumCollateralPriceMin = 990;
    uint256 public constant minimumCollateralPriceMax = 1005;
    uint256 public minimumCollateralPrice = 990;

    address[] public collateralTypes;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    IQuoter private constant quoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    ISwapRouter private constant router = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

    address public governance;

    event Mint(address indexed _from, address indexed _collateral, uint256 _amount);
    event Redeem(address indexed _from, address[] indexed _collateral, uint256 _amount);

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }

    constructor() {
        governance = msg.sender;
        _balances[address(this)] = 0;
        emit Transfer(address(0), address(this), 0);
    }

    function mint(address _collateral, uint256 _amount, bool _exactOutput) external nonReentrant {
        require(collateralWhitelist[_collateral]);
        require(_amount > 0);

        uint256 _quote = quoter.quoteExactInputSingle(_collateral, collateralPairings[_collateral], collateralFeeTiers[_collateral], 10 ** 18, 0);
        require(_quote >= minimumCollateralPrice * (10 ** collateralPairingsDecimals[_collateral]), "Peg Unstable");
        uint256 _peg = (1000 * (10 ** collateralPairingsDecimals[_collateral]));
        if (_peg > _quote) _amount = _exactOutput ? (_amount * ((_peg * (10 ** 18)) / _quote)) / (10 ** 18) : (_amount * (10 ** 18)) / ((_peg * (10 ** 18)) / _quote);

        IERC20 _Collateral = IERC20(_collateral);
        require(_Collateral.balanceOf(msg.sender) >= _amount);
        require(_Collateral.allowance(msg.sender, address(this)) >= _amount);
        uint256 _balance = _Collateral.balanceOf(address(this));
        require(_Collateral.transferFrom(msg.sender, address(this), _amount), "TF");
        require(_Collateral.balanceOf(address(this)) >= _balance + _amount, "TF");

        uint256 _newSupply = _totalSupply + _amount;
        require(_newSupply > _totalSupply);
        _totalSupply = _newSupply;
        _balances[msg.sender] = _balances[msg.sender] + _amount;
        emit Transfer(address(0), msg.sender, _amount);
        emit Mint(msg.sender, _collateral, _amount);
    }

    function redeem(uint256 _amount) external nonReentrant returns (address[] memory) {
        require(_amount > 0);
        require(_balances[msg.sender] >= _amount && _totalSupply >= _amount);
        _balances[msg.sender] = _balances[msg.sender] - _amount;
        emit Transfer(msg.sender, address(0), _amount);
        _totalSupply = _totalSupply - _amount;

        address[] memory _collateralTypes = new address[](9);

        uint256 _amountStablecoin = _amount;
        uint256 _amountStablecoinPaid;
        uint256 _i;
        while (_amountStablecoin > _amountStablecoinPaid) {
            (address _largestCollateral, uint256 _largestBalance) = getLargestBalance();
            uint256 _amountStablecoinRemaining = _amountStablecoin - _amountStablecoinPaid;
            uint256 _amountCollateral = _amountStablecoinRemaining > _largestBalance ? _largestBalance : _amountStablecoinRemaining;
            try IERC20(_largestCollateral).transfer(msg.sender, _amountCollateral) {} catch {}
            _amountStablecoinPaid = _amountStablecoinPaid + _amountCollateral;
            if (_i < 9) {
                _collateralTypes[_i] = _largestCollateral;
                _i = _i + 1;
            }
        }

        emit Redeem(msg.sender, _collateralTypes, _amount);
        return _collateralTypes;
    }

    function getLargestBalance() public view returns (address, uint256) {
        address _largestCollateral;
        uint256 _largestBalance;

        uint256 collateralTypesNum = collateralTypes.length;

        for (uint256 _i = 0; _i < collateralTypesNum; _i++) {
            address _collateral = collateralTypes[_i];
            uint256 _balance = IERC20(_collateral).balanceOf(address(this));
            if (_balance > _largestBalance) {
                _largestCollateral = _collateral;
                _largestBalance = _balance;
            }
        }

        return (_largestCollateral, _largestBalance);
    }

    function getCollateral(address _collateral) external view returns (bool, uint256, address, uint256, uint24) {
        return (collateralWhitelist[_collateral], IERC20(_collateral).balanceOf(address(this)), collateralPairings[_collateral], collateralPairingsDecimals[_collateral], collateralFeeTiers[_collateral]);
    }

    function getCollateralPrice(address _collateral) external returns (uint256) {
        return collateralPairings[_collateral] != address(0) ? quoter.quoteExactInputSingle(_collateral, collateralPairings[_collateral], collateralFeeTiers[_collateral], 10 ** 18, 0) : 0;
    }

    function getMintCost(address _collateral, uint256 _amount, bool _exactOutput) public returns (uint256, bool) {
        uint256 _quote = quoter.quoteExactInputSingle(_collateral, collateralPairings[_collateral], collateralFeeTiers[_collateral], 10 ** 18, 0);
        uint256 _peg = (1000 * (10 ** collateralPairingsDecimals[_collateral]));
        if (_peg > _quote) _amount = _exactOutput ? (_amount * ((_peg * (10 ** 18)) / _quote)) / (10 ** 18) : (_amount * (10 ** 18)) / ((_peg * (10 ** 18)) / _quote);
        return (_amount, _quote >= minimumCollateralPrice * (10 ** collateralPairingsDecimals[_collateral]));
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function owner() external view returns (address) {
        return governance;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, max256);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != max256) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function rescue(address token) external onlyGovernance {
        if (token == 0x0000000000000000000000000000000000000000) {
            payable(msg.sender).call{value: address(this).balance}("");
        } else {
            require(!wasCollateral[token], "Can't withdraw collateral");
            IERC20 Token = IERC20(token);
            Token.transfer(msg.sender, Token.balanceOf(address(this)));
        }
    }

    function whitelistCollateral(address _newCollateral, address _quotePairing, uint24 _quoteFeeTier) external nonReentrant onlyGovernance {
        require(_quoteFeeTier == 100 || _quoteFeeTier == 500 || _quoteFeeTier == 3000 || _quoteFeeTier == 10000);
        require(IERC20Decimals(_newCollateral).decimals() == 18);
        uint256 _pairingDecimals = IERC20Decimals(_quotePairing).decimals();
        require(_pairingDecimals > 3);
        collateralWhitelist[_newCollateral] = true;
        collateralPairings[_newCollateral] = _quotePairing;
        collateralPairingsDecimals[_newCollateral] = _pairingDecimals - 3;
        collateralFeeTiers[_newCollateral] = _quoteFeeTier;
        if (!wasCollateral[_newCollateral]) {
            collateralTypes.push(_newCollateral);
            wasCollateral[_newCollateral] = true;
        }
    }

    function blacklistCollateral(address _oldCollateral, address _newCollateral, bool _liquidateOldCollateral, uint24 _feeTier, address _tokenSwapThrough, uint24 _feeTierSwapThrough) external nonReentrant onlyGovernance {
        collateralWhitelist[_oldCollateral] = false;
        if (_liquidateOldCollateral) {
            if (collateralWhitelist[_oldCollateral]) {
                if (IERC20(_oldCollateral).balanceOf(address(this)) > 0) {
                    require((_feeTier == 100 || _feeTier == 500 || _feeTier == 3000 || _feeTier == 10000));
                    if (_tokenSwapThrough != address(0)) {
                        require(_feeTierSwapThrough == 100 || _feeTierSwapThrough == 500 || _feeTierSwapThrough == 3000 || _feeTierSwapThrough == 10000);
                        IERC20Old(_oldCollateral).approve(address(router), max256);
                        router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _oldCollateral, tokenOut: _tokenSwapThrough, fee: _feeTierSwapThrough, recipient: address(this), amountIn: IERC20(_oldCollateral).balanceOf(address(this)), amountOutMinimum: 0, sqrtPriceLimitX96: 0}));
                        _oldCollateral = _tokenSwapThrough;
                    }
                    IERC20Old(_oldCollateral).approve(address(router), max256);
                    router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _oldCollateral, tokenOut: _newCollateral, fee: _feeTier, recipient: address(this), amountIn: IERC20(_oldCollateral).balanceOf(address(this)), amountOutMinimum: 0, sqrtPriceLimitX96: 0}));
                }
            }
        }
    }

    function setMinimumCollateralPrice(uint256 _newMinimumCollateralPrice) external nonReentrant onlyGovernance {
        require(_newMinimumCollateralPrice >= minimumCollateralPriceMin && _newMinimumCollateralPrice <= minimumCollateralPriceMax);
        minimumCollateralPrice = _newMinimumCollateralPrice;
    }

    function setGovernance(address _newGovernanceContract) external nonReentrant onlyGovernance {
        governance = _newGovernanceContract;
    }

    receive() external payable {}
}