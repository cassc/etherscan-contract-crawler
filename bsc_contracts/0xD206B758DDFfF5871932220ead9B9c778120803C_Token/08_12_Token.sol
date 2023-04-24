// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./Claimable.sol";
import "./Swapable.sol";

contract Token is ERC20, Claimable, Swapable {
    bool private _txOpen = false;
    mapping(address => bool) public _txState;
    mapping(address => bool) public _txOpenState;

    address public immutable team;
    IERC20 public immutable base;
    Wrap public immutable wrap;
    bool internal swapping;
    modifier swap() {
        swapping = true;
        _;
        swapping = false;
    }

    constructor(
        address _router,
        address[] memory _tokens,
        address _team,
        address _base
    ) ERC20("AIT", "AIT") Swapable(_router, _tokens) {
        team = _team;
        base = IERC20(_base);
        wrap = new Wrap(_base);
        _mint(0x6f109c8a1938bF7750f2e8b0bA532DeD30AfCdA7, 99999 * 10 ** decimals());
    }

    function setTxOpen(bool _value) public onlyOwner {
        _txOpen = _value;
    }

    function setTxState(address owner, bool _value) public onlyOwner {
        _txState[owner] = _value;
    }

    function setTxStateList(address[] memory owner, bool _value) public onlyOwner {
        for (uint i = 0; i < owner.length; i++) {
            _txState[owner[i]] = _value;
        }
    }

    function setTxOpenState(address owner, bool _value) public onlyOwner {
        _txOpenState[owner] = _value;
    }

    function setTxOpenStateList(address[] memory owner, bool _value) public onlyOwner {
        for (uint i = 0; i < owner.length; i++) {
            _txOpenState[owner[i]] = _value;
        }
    }

    function beforeTransfer(address from, address to) internal view returns (bool) {
        if (_txOpen) {
            if (_txOpenState[from] || _txOpenState[to]) {
                return false;
            }
            return true;
        }
        if (from == owner() || to == owner()) {
            return true;
        }
        if (_txState[from] || _txState[to]) {
            if (_txOpenState[from] || _txOpenState[to]) {
                return false;
            }
            return true;
        }
        return false;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (swapping == true) {
            super._transfer(from, to, amount);
            return;
        }

        if (isPair(from)) {
            require(beforeTransfer(from, to), "ERC20: address exception!");
        }

        if (amount <= 1e15) revert("amount too low");
        if (balanceOf(from) - amount < 1e15) {
            amount = balanceOf(from) - 1e15;
        }

        if (isPair(to)) {
            _addLiquidity();

            uint256 fee1 = (amount * 4) / 100;
            uint256 fee2 = (amount * 5) / 100;
            super._transfer(from, 0xeb505091D31Af3f9d3728391204E13548C8b240B, fee1);
            super._transfer(from, address(this), fee2);
            super._transfer(from, to, amount - fee1 - fee2);
            return;
        }

        super._transfer(from, to, amount);
    }

    function _addLiquidity() internal swap {
        uint256 amount = balanceOf(address(this));
        if (amount == 0) return;

        if (allowance(address(this), address(router)) < amount / 2) {
            _approve(address(this), address(router), type(uint256).max);
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(base);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount / 2,
            0,
            path,
            address(wrap),
            block.timestamp
        );

        wrap.claim();

        uint256 amount0 = balanceOf(address(this));
        if (allowance(address(this), address(router)) < amount0) {
            _approve(address(this), address(router), type(uint256).max);
        }
        uint256 amount1 = base.balanceOf(address(this));
        if (base.allowance(address(this), address(router)) < amount1) {
            base.approve(address(router), type(uint256).max);
        }

        router.addLiquidity(address(this), address(base), amount0, amount1, 0, 0, team, block.timestamp);
    }
}