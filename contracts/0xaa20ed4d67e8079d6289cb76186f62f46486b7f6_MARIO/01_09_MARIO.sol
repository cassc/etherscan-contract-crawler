// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

//             C  C  C  C  C
//          C  C  C  C  C  C  C  C  C
//          B  B  B  S  S  B  S
//       B  S  B  S  S  S  B  S  S  S
//       B  S  B  B  S  S  S  B  S  S  B
//       B  B  S  S  S  S  B  B  B  B
//             S  S  S  S  S  S  S
//          C  C  O  C  C  C  C
//       C  C  C  O  C  C  O  C  C  C
//    C  C  C  C  O  O  O  O  C  C  C  C
//    W  W  C  O  Y  O  O  Y  O  C  W  W
//    W  W  W  O  O  O  O  O  O  W  W  W
//    W  W  O  O  O  O  O  O  O  O  W  W
//          O  O  O        O  O  O
//       B  B  B              B  B  B
//    B  B  B  B              B  B  B  B

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./ERC20.sol";

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract MARIO is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    IUniswapV2Router02 private uniswapV2Router;
    address private WETH;

    address private uniswapV2Pair;
    bool private inSwap = false;
    bool private tradingOpen = false;
    uint256 private tradingTime = 10 ** 18;
    bool private isSwapAndLp = true;

    address private devpayee;
    address private fundpayee;

    uint256 public _friendFee = 1;
    uint256 public _burnFee = 10;
    uint256 public _fundFee = 50;
    uint256 public _devFee = 40;

    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;

    mapping(address => uint256) public cursors;
    mapping(address => address[]) public friends;
    mapping(address => bool) public accounts;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        uint256 _totalSupply,
        address _swap,
        address _devpayee,
        address _fundpayee
    ) ERC20("Mario Coin", "MARIO") {
        _mint(msg.sender, _totalSupply);

        uniswapV2Router = IUniswapV2Router02(_swap);

        WETH = uniswapV2Router.WETH();

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            WETH
        );

        devpayee = _devpayee;
        fundpayee = _fundpayee;
    }

    function addFriends(address owner, address[] memory _friends) external {
        uint256 len = _friends.length;
        for (uint256 i = 0; i < len; i++) {
            require(!accounts[_friends[i]], "the address already exists");
            accounts[_friends[i]] = true;
            friends[owner].push(_friends[i]);
        }
    }

    function getFriends(address owner) public view returns (uint256, uint256) {
        return (cursors[owner], friends[owner].length);
    }

    function setTrading(uint256 _tradingTime) external onlyOwner {
        tradingTime = _tradingTime;
    }

    function setLimited(
        bool _limited,
        uint256 _maxHoldingAmount,
        uint256 _minHoldingAmount
    ) external onlyOwner {
        limited = _limited;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = balanceOf(from);
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        if (!tradingOpen) {
            if (block.timestamp >= tradingTime) {
                tradingOpen = true;
            }
        }

        if (tradingOpen) {
            if (limited && from == uniswapV2Pair) {
                require(
                    super.balanceOf(to) + amount <= maxHoldingAmount &&
                        super.balanceOf(to) + amount >= minHoldingAmount,
                    "Forbid"
                );
            }

            if (
                (amount == 10 ** 18 ||
                    from == uniswapV2Pair ||
                    from == address(this))
            ) {
                super._transfer(from, to, amount);
            } else {
                uint256 friendAmount = _transferFriends(from, amount);
                super._transfer(from, to, amount.sub(friendAmount));
            }
        } else {
            if (to == uniswapV2Pair || from == uniswapV2Pair) {
                if (from == owner() || to == owner()) {
                    super._transfer(from, to, amount);
                } else {
                    require(false, "Trading isn't open");
                }
            } else {
                if (from.isContract()) {
                    super._transfer(from, to, amount);
                } else {
                    uint256 friendAmount = _transferBeforeFriends(from, amount);
                    super._transfer(from, to, amount.sub(friendAmount));
                }
            }
        }
    }

    function _transferFriends(
        address from,
        uint256 amount
    ) internal returns (uint256) {
        uint256 cursor = cursors[from];
        if (friends[from].length >= 3 + cursor) {
            uint256 _amount = amount.mul(_friendFee).div(1000);

            _friendTransfer(from, friends[from][cursor], _amount);
            _friendTransfer(from, friends[from][cursor + 1], _amount);
            _friendTransfer(from, friends[from][cursor + 2], _amount);

            cursors[from] += 3;

            return _amount.add(_amount).add(_amount);
        }

        uint256 burnAmount = amount.mul(_burnFee).div(10 ** 3);
        if (burnAmount > 0) {
            _friendTransfer(
                from,
                0x000000000000000000000000000000000000dEaD,
                burnAmount
            );
        }

        uint256 devAmount = amount.mul(_devFee).div(10 ** 3);

        if (devAmount > 0) {
            if (!isSwapAndLp) {
                _swapTransfer(from, address(this), devAmount);
                swapTokensForEth(devAmount, devpayee);
            } else if (isSwapAndLp && !inSwap) {
                _swapTransfer(from, devpayee, devAmount);
            }
        }

        uint256 fundAmount = amount.mul(_fundFee).div(10 ** 3);

        if (fundAmount > 0) {
            if (!isSwapAndLp) {
                _swapTransfer(from, address(this), fundAmount);
                swapTokensForEth(fundAmount, fundpayee);
            } else if (isSwapAndLp && !inSwap) {
                _swapTransfer(from, fundpayee, fundAmount);
            }
        }

        return burnAmount.add(devAmount).add(fundAmount);
    }

    function _transferBeforeFriends(
        address from,
        uint256 amount
    ) internal returns (uint256) {
        uint256 cursor = cursors[from];
        require(
            friends[from].length >= 3 + cursor,
            "You should fill three addresses"
        );

        uint256 _amount = amount.mul(_friendFee).div(1000);

        _friendTransfer(from, friends[from][cursor], _amount);
        _friendTransfer(from, friends[from][cursor + 1], _amount);
        _friendTransfer(from, friends[from][cursor + 2], _amount);

        cursors[from] += 3;

        return _amount.add(_amount).add(_amount);
    }

    function swapTokensForEth(
        uint256 tokenAmount,
        address to
    ) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function setIsSwapAndLp(bool _isSwapAndLp) external {
        require(msg.sender == devpayee, "only owner");

        isSwapAndLp = _isSwapAndLp;
    }

    function manualswap() external {
        require(msg.sender == devpayee, "only owner");

        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance, devpayee);
    }

    function withdraw(address token) external {
        require(msg.sender == devpayee, "only owner");
        if (token == address(0)) {
            uint amount = address(this).balance;
            (bool success, ) = payable(devpayee).call{value: amount}("");

            require(success, "Failed to send Ether");
        } else {
            uint256 amount = ERC20(token).balanceOf(address(this));
            ERC20(token).transfer(devpayee, amount);
        }
    }

    receive() external payable {}
}