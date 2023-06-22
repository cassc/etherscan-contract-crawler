// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC20} from "./libraries/solmate/ERC20.sol";
import {Owned} from "./libraries/solmate/Owned.sol";

import {IsContract} from "./libraries/isContract.sol";

import "./interfaces/univ2.sol";

error NotStartedYet();
error Blocked();

contract MEMELIToken is ERC20("MEMELISA Token", "MEMELI", 18), Owned(msg.sender) {
    using IsContract for address;

    mapping(address => bool) public whitelisted;
    mapping(address => bool) public blocked;

    IUniswapV2Pair public pair;
    IUniswapV2Router02 public router;
    uint256 public startedIn = 0;
    uint256 public startedAt = 0;

    address public treasury;

    uint256 public feeCollected = 0;
    uint256 public feeSwapBps = 100; // 1.00% liquidity increase
    uint256 public feeSwapTrigger = 10e18;

    uint256 maxBps = 10000; // 10000 is 100.00%

    // 0-1 blocks:
    uint256 public zeroBlockBuyBPS = 9000; // 90.00%
    uint256 public zeroBlockSellBPS = 9000; // 90.00%
    // first 30min:
    uint256 public initialBuyBPS = 1000; // 10.00%
    uint256 public initialSellBPS = 3000; // 30.00%
    // 7 days:
    uint256 public weekBuyBPS = 500; // 5.00%
    uint256 public weekSellBPS = 2000; // 20.00%
    // after
    uint256 public buyBPS = 500; // 5.00%
    uint256 public sellBPS = 500; // 5.00%

    constructor() {
        treasury = address(0x3b6869106b4F747fB36bB94f7089165AdD128365);
        uint256 expectedTotalSupply = 811_000_000_000 ether;
        whitelisted[treasury] = true;
        whitelisted[address(this)] = true;
        _mint(treasury, expectedTotalSupply);
    }

    // getters
    function isLiqudityPool(address account) public view returns (bool) {
        if (!account.isContract()) return false;
        (bool success0, bytes memory result0) = account.staticcall(
            abi.encodeWithSignature("token0()")
        );
        if (!success0) return false;
        (bool success1, bytes memory result1) = account.staticcall(
            abi.encodeWithSignature("token1()")
        );
        if (!success1) return false;
        address token0 = abi.decode(result0, (address));
        address token1 = abi.decode(result1, (address));
        if (token0 == address(this) || token1 == address(this)) return true;
        return false;
    }

    // public functions

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // transfer functions
    function _onTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (blocked[to] || blocked[from]) {
            revert Blocked();
        }
        if(whitelisted[from] || whitelisted[to]) {
            return amount;
        }

        if (startedIn == 0) {
            revert NotStartedYet();
        }

        if (isLiqudityPool(to) || isLiqudityPool(from)) {
            return _transferFee(from, to, amount);
        }

        if (feeCollected > feeSwapTrigger) {
            _swapFee();
        }

        return amount;
    }

    function _swapFee() internal {
        uint256 feeAmount = feeCollected;
        feeCollected = 0;
        if(address(pair) == address(0)) return;


        (address token0, address token1) = (pair.token0(), pair.token1());
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        if (token1 == address(this)) {
            (token0, token1) = (token1, token0);
            (reserve0, reserve1) = (reserve1, reserve0);
        }

        uint256 maxFee = reserve0 * feeSwapBps / maxBps;
        if (maxFee < feeAmount) {
            feeCollected = feeAmount - maxFee;
            feeAmount = maxFee;
        }

        if(feeAmount == 0) return;

        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        this.approve(address(router), feeAmount);
        router.swapExactTokensForTokens(
            feeAmount,
            0,
            path,
            treasury,
            block.timestamp + 1000
        );
    }

    function _transferFee(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        uint256 taxBps = 0;

        if (isLiqudityPool(from)) {
            if (block.number <= startedIn + 1) {
                taxBps = zeroBlockBuyBPS;
            } else if (block.timestamp <= startedAt + 30 minutes) {
                taxBps = initialBuyBPS;
            } else if (block.timestamp <= startedAt + 7 days) {
                taxBps = weekBuyBPS;
            } else {
                taxBps = buyBPS;
            }
        } else if (isLiqudityPool(to)) {
            if (block.number <= startedIn + 1) {
                taxBps = zeroBlockSellBPS;
            } else if (block.timestamp <= startedAt + 30 minutes) {
                taxBps = initialSellBPS;
            } else if (block.timestamp <= startedAt + 7 days) {
                taxBps = weekSellBPS;
            } else {
                taxBps = sellBPS;
            }
        }

        uint256 feeAmount = (amount * taxBps) / maxBps;
        if (feeAmount == 0) return amount;

        feeCollected += feeAmount;
        amount -= feeAmount;

        _transfer(from, address(this), feeAmount);

        return amount;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (from != address(this) && to != address(this)) {
            amount = _onTransfer(from, to, amount);
        }

        return super.transferFrom(from, to, amount);
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        if (msg.sender != address(this) && to != address(this)) {
            amount = _onTransfer(msg.sender, to, amount);
        }
        return super.transfer(to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        balanceOf[from] -= amount;
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }

    // Only owner functions
    function start() public onlyOwner {
        require(startedIn == 0, "MEMELI: already started");
        startedIn = block.number;
        startedAt = block.timestamp;
    }

    function setUni(address _router, address _pair) public onlyOwner {
        router = IUniswapV2Router02(_router);
        pair = IUniswapV2Pair(_pair);
        (address token0, address token1) = (pair.token0(), pair.token1());
        require(token0 == address(this) || token1 == address(this), "MEMELI: wrong pair");
        require(pair.factory() == router.factory(), "MEMELI: wrong pair");
    }

    function setFeeSwapConfig(uint256 _feeSwapTrigger, uint256 _feeSwapBps) public onlyOwner {
        feeSwapTrigger = _feeSwapTrigger;
        feeSwapBps = _feeSwapBps;
    }

    function setBps(uint256 _buyBPS, uint256 _sellBPS) public onlyOwner {
        require(_buyBPS <= 500, "MEMELI: wrong buyBPS");
        require(_sellBPS <= 500, "MEMELI: wrong sellBPS");
        buyBPS = _buyBPS;
        sellBPS = _sellBPS;
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function whitelist(address account, bool _whitelisted) public onlyOwner {
        whitelisted[account] = _whitelisted;
    }

    function blocklist(address account, bool _blocked) public onlyOwner {
        require(startedAt > 0, "MEMELI: too early");
        require(startedAt + 7 days > block.timestamp, "MEMELI: too late");
        blocked[account] = _blocked;
    }
}