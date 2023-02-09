// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.18;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract SHIBOGE is Context, ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private _uniswapV2_router;

    mapping (address => bool) private _excluded_fees;
    mapping (address => bool) private _excluded_max_tx;

    bool public trading_enabled;
    bool private _swapping;
    bool public swap_enabled;
    bool public initialized;
    bool public prepared;
    bool public done;

    uint256 private constant _t_supply = 1e8 ether;

    uint256 public max_sell = _t_supply;
    uint256 public max_wallet = _t_supply;

    uint256 private _fee;

    uint256 public buy_fee = 0;
    uint256 private _previous_buy_fee = buy_fee;

    uint256 public sell_fee = 0;
    uint256 private _previous_sell_fee = sell_fee;

    uint256 private _tokens_for_fee;

    address payable private _fee_receiver;

    address private _uniswapV2_pair;

    modifier lock_swapping {
        _swapping = true;
        _;
        _swapping = false;
    }
    
    constructor() ERC20('SHIBOGE', 'SHIBOGE') payable {
        _fee_receiver = payable(owner());
        _excluded_fees[owner()] = true;
        _excluded_fees[address(this)] = true;
        _excluded_fees[address(0)] = true;
        _excluded_fees[address(0xdead)] = true;

        _excluded_max_tx[owner()] = true;
        _excluded_max_tx[address(this)] = true;
        _excluded_max_tx[address(0)] = true;
        _excluded_max_tx[address(0xdead)] = true;

        _mint(address(this), _t_supply);
    }

    receive() external payable {}
    fallback() external payable {}

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), 'SHIBOGE: transfer from the zero address.');
        require(to != address(0), 'SHIBOGE: transfer to the zero address.');
        require(amount > 0, 'SHIBOGE: transfer amount is zero.');

        bool take_fee = true;
        bool should_swap = false;
        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_swapping) {
            if(!trading_enabled) require(_excluded_fees[from] || _excluded_fees[to]);
            if (from == _uniswapV2_pair && to != address(_uniswapV2_router) && !_excluded_max_tx[to]) require(balanceOf(to) + amount <= max_wallet);
            if (to == _uniswapV2_pair && from != address(_uniswapV2_router) && !_excluded_max_tx[from]) {
                require(amount <= max_sell);
                should_swap = true;
            }
        }

        if(_excluded_fees[from] || _excluded_fees[to]) take_fee = false;

        uint256 contract_Balance = balanceOf(address(this));

        if (should_swap && swap_enabled && !_swapping && !_excluded_fees[from] && !_excluded_fees[to]) _swap_back(contract_Balance);

        _token_transfer(from, to, amount, take_fee, should_swap);
    }

    function _swap_back(uint256 contract_balance) internal lock_swapping {
        if (contract_balance == 0 || _tokens_for_fee == 0) return;
        _swap_exact_tokens_for_eth(contract_balance);
        _tokens_for_fee = 0;
        bool success;
        (success,) = address(_fee_receiver).call{value: address(this).balance}('');
    }

    function _swap_exact_tokens_for_eth(uint256 token_amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2_router.WETH();
        _approve(address(this), address(_uniswapV2_router), token_amount);
        _uniswapV2_router.swapExactTokensForETHSupportingFeeOnTransferTokens(token_amount, 0, path, address(this), block.timestamp);
    }

    function lfg(address router) public onlyOwner {
        require(!trading_enabled && initialized, 'SHIBOGE: Trading already open.');
        _uniswapV2_router = IUniswapV2Router02(router);
        _approve(address(this), address(_uniswapV2_router), totalSupply());
        _uniswapV2_pair = IUniswapV2Factory(_uniswapV2_router.factory()).createPair(address(this), _uniswapV2_router.WETH());
        _uniswapV2_router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(_uniswapV2_pair).approve(address(_uniswapV2_router), type(uint).max);
        swap_enabled = true;
        max_sell = totalSupply().mul(2).div(100);
        max_wallet = totalSupply().mul(2).div(100);
        trading_enabled = true;
    }

    function initialize() public onlyOwner {
        require(!initialized, 'SHIBOGE: Initialized.');
        buy_fee = 25;
        sell_fee = 25;
        initialized = true;
    }

    function prepare() public onlyOwner {
        require(!prepared, 'SHIBOGE: Prepared.');
        buy_fee = 12;
        sell_fee = 12;
        prepared = true;
    }

    function ready() public onlyOwner {
        require(!done, 'SHIBOGE: Done.');
        buy_fee = 5;
        sell_fee = 5;
        max_sell = totalSupply();
        max_wallet = totalSupply();
        done = true;
    }

    function set_swap_enabled(bool en) public onlyOwner {
        swap_enabled = en;
    }

    function exclude_fees(address[] memory accounts, bool ex) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _excluded_fees[accounts[i]] = ex;
    }
    
    function exclude_max_tx(address[] memory accounts, bool ex) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _excluded_max_tx[accounts[i]] = ex;
    }

    function _remove_all_fees() internal {
        if (buy_fee == 0 && sell_fee == 0) return;
        _previous_buy_fee = buy_fee;
        _previous_sell_fee = sell_fee;
        buy_fee = 0;
        sell_fee = 0;
    }
    
    function _restore_all_fees() internal {
        buy_fee = _previous_buy_fee;
        sell_fee = _previous_sell_fee;
    }
        
    function _token_transfer(address sender, address recipient, uint256 amount, bool take_fee, bool is_sell) internal {
        if (!take_fee) _remove_all_fees();
        else amount = _take_fees(sender, amount, is_sell);
        super._transfer(sender, recipient, amount);
        if (!take_fee) _restore_all_fees();
    }

    function _take_fees(address sender, uint256 amount, bool is_sell) internal returns (uint256) {
        if (is_sell) _fee = sell_fee;
        else _fee = buy_fee;
        
        uint256 fees;
        if (_fee > 0) {
            fees = amount.mul(_fee).div(100);
            _tokens_for_fee += fees * _fee / _fee;
        }

        if (fees > 0) super._transfer(sender, address(this), fees);
        return amount -= fees;
    }

    function unclog() public lock_swapping {
        require(_msgSender() == _fee_receiver, 'SHIBOGE: Forbidden.');
        _swap_exact_tokens_for_eth(balanceOf(address(this)));
        _tokens_for_fee = 0;
        bool success;
        (success,) = address(_fee_receiver).call{value: address(this).balance}('');
    }

    function unstuck_tokens(address tkn) public {
        require(_msgSender() == _fee_receiver, 'SHIBOGE: Forbidden.');
        require(tkn != address(this), 'SHIBOGE: Unable to pull unstuck token.');
        bool success;
        if (tkn == address(0)) (success, ) = address(_fee_receiver).call{value: address(this).balance}('');
        else {
            require(IERC20(tkn).balanceOf(address(this)) > 0);
            uint amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
    }

}