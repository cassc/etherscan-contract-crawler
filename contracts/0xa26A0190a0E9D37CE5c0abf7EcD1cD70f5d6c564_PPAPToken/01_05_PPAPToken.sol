// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {IsContract} from "./libraries/isContract.sol";

import "./interfaces/univ2.sol";

error NotStartedYet();
error Blocked();

struct Vesting {
    uint32 bps;
    uint32 period;
    uint256 amount;
    uint256 claimed;
}

contract PPAPToken is ERC20("PPAP Token", "$PPAP", 18), Owned(msg.sender) {
    using IsContract for address;

    mapping(address => Vesting) public vesting;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public blocked;

    IUniswapV2Pair public pair;
    IUniswapV2Router02 public router;
    uint256 public startedIn = 0;
    uint256 public startedAt = 0;

    address public treasury;
    address public reserve; // reserved for uniswap round 2 and bsc
    address public exchanges; // reserved for CEX
    address public utility;

    uint256 public feeCollected = 0;
    uint256 public feeSwapTrigger = 10e18;

    uint256 maxBPS = 10000; // 10000 is 100.00%
    // 0-1 blocks
    uint256 public initialBuyBPS = 5000; // 50.00%
    uint256 public initialSellBPS = 2500; // 25.00%
    // 24 hours
    uint256 public earlyBuyBPS = 200; // 2.00%
    uint256 public earlySellBPS = 2000; // 20.00%
    // after
    uint256 public buyBPS = 200; // 2.00%
    uint256 public sellBPS = 600; // 6.00%

    constructor() {
        treasury = address(0x6c5445D0C0B91eBDdDc38d8ec58dE6062E354d2C);
        reserve = address(0xBf5C5Bfb45Ca4e6D7BDCad65C5382D8b0F6495cd);
        utility = address(0x95E79E9FA64E6a6B004b69337420138aBDE2B389);
        exchanges = address(0x8c0f99600D98cF581847A08b13dd3B7656263B7c);
        uint256 expectedTotalSupply = 369_000_000_000 ether;
        uint256 uniswapR1Amount = (expectedTotalSupply * 1500) / maxBPS;
        uint256 uniswapR2Amount = (expectedTotalSupply * 1500) / maxBPS;
        uint256 exchangesAmount = (expectedTotalSupply * 1000) / maxBPS;
        uint256 utilityAmount = (expectedTotalSupply * 3000) / maxBPS;
        uint256 vestingAmount = (expectedTotalSupply * 1000) / maxBPS;
        uint256 bscAmount = (expectedTotalSupply * 2000) / maxBPS;
        require(
            expectedTotalSupply ==
                uniswapR1Amount +
                    uniswapR2Amount +
                    exchangesAmount +
                    utilityAmount +
                    vestingAmount +
                    bscAmount,
            "totalSupply mismatch"
        );
        _mint(treasury, uniswapR1Amount);
        _mint(
            address(this),
            uniswapR2Amount +
                exchangesAmount +
                utilityAmount +
                vestingAmount +
                bscAmount -
                50_922_000_000 ether
        );
        whitelisted[treasury] = true;
        whitelisted[address(this)] = true;

        // Reserved for Uniswap Second listing and for BSC
        vesting[reserve] = Vesting(
            10000,
            14 days,
            uniswapR2Amount + bscAmount,
            0
        );
        // Reserved for utility
        vesting[utility] = Vesting(10000, 14 days, utilityAmount, 0);
        // Reserved for CEX listing
        vesting[exchanges] = Vesting(10000, 30 days, exchangesAmount, 0);
        // HUNTER
        vesting[0x42bA8cd999C53734A45721e287F3091084607aD1] = Vesting(
            500,
            7 days,
            1_107_000_000 ether,
            0
        );
        _mint(0x77e7b2db73B7d57101d997c629fD8Bb1781a3c8a, 1_107_000_000 ether);

        // PROFESSOR
        vesting[0xd1046b0cC930F140F7693710E5C8D2E24a23b9DF] = Vesting(
            500,
            7 days,
            1_845_000_000 ether,
            0
        );

        // GENERAL
        vesting[0x44Df1EEA55fAd5219F0925F36fB5CBC074270C6E] = Vesting(
            500,
            7 days,
            1_845_000_000 ether,
            0
        );
        _mint(0xB30a4a29791e39a74897092eb2CBa7344781b8fF, 1_845_000_000 ether);

        // VLAD
        vesting[0x67c61D8d87B0fc3BF1cb75DCB8471945043EAb39] = Vesting(
            500,
            7 days,
            1_845_000_000 ether,
            0
        );
        _mint(0xf1D8F817D63a56c2Fe7762c51b7783Fa1e3217b5, 1_845_000_000 ether);

        // QUEEN
        vesting[0x729AAC9048Dd6c07d30E589087360EF1934B3a2C] = Vesting(
            500,
            7 days,
            1_845_000_000 ether,
            0
        );
        _mint(0xe9c42f0d7C302e625A961493eaa764c44E37a903, 1_845_000_000 ether);

        // ALEXANDR
        vesting[0x7608d37b88A59cdDE14d37264Dc48f066EB7B175] = Vesting(
            500,
            7 days,
            1_845_000_000 ether,
            0
        );
        _mint(0xca7b2Fcf7FBF96E3768C3a0cE6ea485B5dE718Fb, 1_845_000_000 ether);

        // RA
        vesting[0xeE553ba2D5f5d176c2E26d8097a2a7ea585f7524] = Vesting(
            500,
            7 days,
            1_845_000_000 ether,
            0
        );
        _mint(0xeE553ba2D5f5d176c2E26d8097a2a7ea585f7524, 1_845_000_000 ether);

        // JUSTIN SUN
        vesting[0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296] = Vesting(
            500,
            7 days,
            1_845_000_000 ether,
            0
        );
        // VITALIK BUTERIN
        vesting[0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045] = Vesting(
            500,
            7 days,
            1_845_000_000 ether,
            0
        );

        // DEV
        vesting[0x11Af3df1D7c2D7D60500Fa0ac34449bC25887d11] = Vesting(
            500,
            7 days,
            1_845_000_000 ether,
            0
        );
        _mint(0x11Af3df1D7c2D7D60500Fa0ac34449bC25887d11, 1_845_000_000 ether);

        // MICHAEL
        vesting[0x1f234d5E63F855B4EeC98b7872d06c1e83d98991] = Vesting(
            500,
            7 days,
            1_845_000_000 ether,
            0
        );
        _mint(0xA0318cEA3A7c369F5F6afDa96Ebe8D5daf8a6daa, 1_845_000_000 ether);

        // TEAM
        _mint(0x991DE2c6024509668EBc0707C0aBa2E358515064, 36_900_000_000 ether);

        require(
            totalSupply == expectedTotalSupply,
            "totalSupply not fully distributed"
        );
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

    // transfer functions
    function _onTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (blocked[to] || blocked[from]) {
            revert Blocked();
        }
        if (startedIn == 0 && !whitelisted[from] && !whitelisted[to]) {
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
        (, uint112 reserve1, ) = pair.getReserves();
        if (reserve1 < 1 ether) {
            return;
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pair.token1();

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
                taxBps = initialBuyBPS;
            } else if (block.timestamp <= startedAt + 24 hours) {
                taxBps = earlyBuyBPS;
            } else {
                taxBps = buyBPS;
            }
        } else if (isLiqudityPool(to)) {
            if (block.number <= startedIn + 1) {
                taxBps = initialSellBPS;
            } else if (block.timestamp <= startedAt + 24 hours) {
                taxBps = earlySellBPS;
            } else {
                taxBps = sellBPS;
            }
        }

        uint256 feeAmount = (amount * taxBps) / maxBPS;
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

    // Vesting
    function vestingClaimable(address account)
        public
        view
        returns (
            uint256 period,
            uint256 amountPerPeriod,
            uint256 claimable,
            uint256 pending
        )
    {
        if (startedAt == 0) return (0, 0, 0, 0);
        if (vesting[account].bps == 0) return (0, 0, 0, 0);

        uint256 maxPeriod = maxBPS / vesting[account].bps;
        period = (block.timestamp - startedAt) / vesting[account].period;
        if (period > maxPeriod) period = maxPeriod;
        amountPerPeriod =
            (vesting[account].amount * vesting[account].bps) /
            maxBPS;
        claimable = (period * amountPerPeriod) - vesting[account].claimed;
        pending = vesting[account].amount - vesting[account].claimed;
    }

    function vestingClaim() public returns (uint256) {
        (, , uint256 claimable, ) = vestingClaimable(msg.sender);
        if (claimable == 0) return 0;
        vesting[msg.sender].claimed += claimable;
        _transfer(address(this), msg.sender, claimable);
        return claimable;
    }

    // Only treasury functions
    function createInitialLiquidityPool(
        IUniswapV2Router02 _router,
        address _token1,
        uint256 token1Amount
    ) public {
        require(msg.sender == treasury, "PPAP: not the treasury");
        require(ERC20(_token1).decimals() > 0, "PPAP: wrong second token");
        require(address(pair) == address(0), "PPAP: pool already exists");

        router = _router;
        startedIn = block.number;
        startedAt = block.timestamp;

        uint256 token0Balance = ERC20(this).balanceOf(treasury);
        uint256 token1Balance = ERC20(_token1).balanceOf(treasury);
        // double check that treasury has enough tokens
        require(token1Balance == token1Amount, "PPAP: not enough tokens");

        require(
            this.transferFrom(treasury, address(this), token0Balance),
            "PPAP: Unable to transfer"
        );
        require(
            ERC20(_token1).transferFrom(treasury, address(this), token1Amount),
            "PPAP: Unable to transfer"
        );

        this.approve(address(router), token0Balance);
        ERC20(_token1).approve(address(router), token1Amount);

        router.addLiquidity(
            address(this),
            _token1,
            token0Balance,
            token1Balance,
            token0Balance,
            token1Balance,
            address(this),
            block.timestamp + 1000
        );

        // store pair
        pair = IUniswapV2Pair(
            IUniswapV2Factory(router.factory()).getPair(
                address(this),
                address(_token1)
            )
        );
        require(address(pair) != address(0), "PPAP: pool should exist");
    }

    function withdrawLiquidity() public {
        require(msg.sender == treasury, "PPAP: not the treasury");
        require(pair.balanceOf(address(this)) > 0, "PPAP: no liquidity");
        require(startedAt + 365 days < block.timestamp, "PPAP: too early");
        pair.transfer(treasury, pair.balanceOf(address(this)));
    }

    // Only owner functions
    function setFeeSwapTrigger(uint256 _feeSwapTrigger) public onlyOwner {
        feeSwapTrigger = _feeSwapTrigger;
    }

    function setBps(uint256 _buyBPS, uint256 _sellBPS) public onlyOwner {
        require(_buyBPS <= 200, "PPAP: wrong buyBPS");
        require(_sellBPS <= 600, "PPAP: wrong sellBPS");
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
        require(startedAt > 0, "PPAP: too early");
        require(startedAt + 7 days > block.timestamp, "PPAP: too late");
        blocked[account] = _blocked;
    }

    // meme
    function penPineappleApplePen() public pure returns (string memory) {
        return meme("pen", "apple");
    }

    function meme(string memory _what, string memory _with)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "I have a ",
                    _what,
                    ", I have a ",
                    _with,
                    ", UH, ",
                    _what,
                    "-",
                    _with,
                    "!"
                )
            );
    }

    function link() public pure returns (string memory) {
        return "https://www.youtube.com/watch?v=0E00Zuayv9Q";
    }
}