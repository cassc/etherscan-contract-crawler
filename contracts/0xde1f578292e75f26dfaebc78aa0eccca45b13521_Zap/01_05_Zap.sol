pragma solidity 0.6.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20, SafeMath} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract Zap {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using SafeERC20 for IbDUSD;

    uint constant N_COINS = 4;
    string constant ERR_SLIPPAGE = "ERR_SLIPPAGE";

    ICurveDeposit immutable yDeposit;
    ICurve immutable ySwap;
    IERC20 immutable yCrv;
    IERC20 immutable dusd;
    IbDUSD immutable ibdusd;
    IYVaultPeak immutable yVaultPeak;

    address[N_COINS] coins;
    address[N_COINS] underlyingCoins;
    uint[N_COINS] ZEROES = [uint(0),uint(0),uint(0),uint(0)];

    constructor(
        ICurveDeposit _yDeposit,
        ICurve _ySwap,
        IERC20 _yCrv,
        IERC20 _dusd,
        IbDUSD _ibdusd,
        IYVaultPeak _yVaultPeak,
        address[N_COINS] memory _underlyingCoins,
        address[N_COINS] memory _coins
    ) public {
        yDeposit = _yDeposit;
        ySwap = _ySwap;
        yCrv = _yCrv;
        dusd = _dusd;
        ibdusd = _ibdusd;
        yVaultPeak = _yVaultPeak;
        underlyingCoins = _underlyingCoins;
        coins = _coins;
    }

    /**
    * @notice Mint DUSD
    * @param inAmounts Exact inAmounts in the same order as required by the curve pool
    * @param minDusdAmount Minimum DUSD to mint, used for capping slippage
    */
    function mint(uint[N_COINS] memory inAmounts, uint minDusdAmount)
        public
        returns (uint dusdAmount)
    {
        dusdAmount = _mint(inAmounts, minDusdAmount);
        dusd.safeTransfer(msg.sender, dusdAmount);
    }

    function _mint(uint[N_COINS] memory inAmounts, uint minDusdAmount)
        internal
        returns (uint dusdAmount)
    {
        address[N_COINS] memory _coins = underlyingCoins;
        for (uint i = 0; i < N_COINS; i++) {
            if (inAmounts[i] > 0) {
                IERC20(_coins[i]).safeTransferFrom(msg.sender, address(this), inAmounts[i]);
                IERC20(_coins[i]).safeApprove(address(yDeposit), inAmounts[i]);
            }
        }
        yDeposit.add_liquidity(inAmounts, 0);
        uint inAmount = yCrv.balanceOf(address(this));
        yCrv.safeApprove(address(yVaultPeak), 0);
        yCrv.safeApprove(address(yVaultPeak), inAmount);
        dusdAmount = yVaultPeak.mintWithYcrv(inAmount);
        require(dusdAmount >= minDusdAmount, ERR_SLIPPAGE);
    }

    function calcMint(uint[N_COINS] memory inAmounts)
        public
        view
        returns (uint dusdAmount)
    {
        for(uint i = 0; i < N_COINS; i++) {
            inAmounts[i] = inAmounts[i].mul(1e18).div(yERC20(coins[i]).getPricePerFullShare());
        }
        uint _yCrv = ySwap.calc_token_amount(inAmounts, true /* deposit */);
        return yVaultPeak.calcMintWithYcrv(_yCrv);
    }

    /**
    * @dev Redeem DUSD
    * @param dusdAmount Exact dusdAmount to burn
    * @param minAmounts Min expected amounts to cap slippage
    */
    function redeem(uint dusdAmount, uint[N_COINS] memory minAmounts)
        public
    {
        redeemTo(dusdAmount, minAmounts, msg.sender);
    }

    function redeemTo(uint dusdAmount, uint[N_COINS] memory minAmounts, address destination)
        public
    {
        dusd.safeTransferFrom(msg.sender, address(this), dusdAmount);
        _redeemTo(dusdAmount, minAmounts, destination);
    }

    function _redeemTo(uint dusdAmount, uint[N_COINS] memory minAmounts, address destination)
        internal
    {
        uint r = yVaultPeak.redeemInYcrv(dusdAmount, 0);
        yCrv.safeApprove(address(yDeposit), r);
        yDeposit.remove_liquidity(r, ZEROES);
        address[N_COINS] memory _coins = underlyingCoins;
        uint toTransfer;
        for (uint i = 0; i < N_COINS; i++) {
            toTransfer = IERC20(_coins[i]).balanceOf(address(this));
            if (toTransfer > 0) {
                require(toTransfer >= minAmounts[i], ERR_SLIPPAGE);
                IERC20(_coins[i]).safeTransfer(destination, toTransfer);
            }
        }
    }

    function calcRedeem(uint dusdAmount)
        public view
        returns (uint[N_COINS] memory amounts)
    {
        uint _yCrv = yVaultPeak.calcRedeemInYcrv(dusdAmount);
        uint totalSupply = yCrv.totalSupply();
        for(uint i = 0; i < N_COINS; i++) {
            amounts[i] = ySwap.balances(int128(i))
                .mul(_yCrv)
                .div(totalSupply)
                .mul(yERC20(coins[i]).getPricePerFullShare())
                .div(1e18);
        }
    }

    function redeemInSingleCoin(uint dusdAmount, uint i, uint minOut)
        public
        returns (uint amount)
    {
        return redeemInSingleCoinTo(dusdAmount, i, minOut, msg.sender);
    }

    function redeemInSingleCoinTo(uint dusdAmount, uint i, uint minOut, address destination)
        public
        returns (uint)
    {
        dusd.safeTransferFrom(msg.sender, address(this), dusdAmount);
        return _redeemInSingleCoinTo(dusdAmount, i, minOut, destination);
    }

    function _redeemInSingleCoinTo(uint dusdAmount, uint i, uint minOut, address destination)
        internal
        returns (uint amount)
    {
        uint r = yVaultPeak.redeemInYcrv(dusdAmount, 0);
        yCrv.safeApprove(address(yDeposit), r);
        yDeposit.remove_liquidity_one_coin(r, int128(i), minOut); // checks for slippage
        IERC20 coin = IERC20(underlyingCoins[i]);
        amount = coin.balanceOf(address(this));
        coin.safeTransfer(destination, amount);
    }

    function calcRedeemInSingleCoin(uint dusdAmount, uint i)
        public view
        returns(uint)
    {
        uint _yCrv = yVaultPeak.calcRedeemInYcrv(dusdAmount);
        return yDeposit.calc_withdraw_one_coin(_yCrv, int128(i));
    }

    function deposit(uint[N_COINS] calldata inAmounts, uint minDusdAmount)
        external
        returns (uint dusdAmount)
    {
        dusdAmount = _mint(inAmounts, minDusdAmount);
        dusd.safeApprove(address(ibdusd), dusdAmount);
        ibdusd.deposit(dusdAmount);
        ibdusd.safeTransfer(msg.sender, ibdusd.balanceOf(address(this)));
    }

    function withdraw(uint shares, uint i, uint minOut)
        external
        returns (uint)
    {
        ibdusd.safeTransferFrom(msg.sender, address(this), shares);
        ibdusd.withdraw(shares);
        return _redeemInSingleCoinTo(
            dusd.balanceOf(address(this)),
            i,
            minOut,
            msg.sender
        );
    }

    function withdrawInAll(uint shares, uint[N_COINS] calldata minAmounts)
        external
    {
        ibdusd.safeTransferFrom(msg.sender, address(this), shares);
        ibdusd.withdraw(shares);
        _redeemTo(
            dusd.balanceOf(address(this)),
            minAmounts,
            msg.sender
        );
    }
}

interface IYVaultPeak {
    function mintWithYcrv(uint inAmount) external returns(uint dusdAmount);
    function calcMintWithYcrv(uint inAmount) external view returns (uint dusdAmount);
    function redeemInYcrv(uint dusdAmount, uint minOut) external returns(uint _yCrv);
    function calcRedeemInYcrv(uint dusdAmount) external view returns (uint _yCrv);
}

interface yERC20 {
    function getPricePerFullShare() external view returns(uint);
}

interface ICurveDeposit {
    function add_liquidity(uint[4] calldata uamounts, uint min_mint_amount) external;
    function remove_liquidity(uint amount, uint[4] calldata min_uamounts) external;
    function remove_liquidity_imbalance(uint[4] calldata uamounts, uint max_burn_amount) external;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_uamount) external;
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns(uint);
}

interface ICurve {
    function add_liquidity(uint[4] calldata uamounts, uint min_mint_amount) external;
    function remove_liquidity_imbalance(uint[4] calldata uamounts, uint max_burn_amount) external;
    function remove_liquidity(uint amount, uint[4] calldata min_amounts) external;
    function calc_token_amount(uint[4] calldata inAmounts, bool deposit) external view returns(uint);
    function balances(int128 i) external view returns(uint);
    function get_virtual_price() external view returns(uint);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}

interface IbDUSD is IERC20 {
    function deposit(uint) external;
    function withdraw(uint) external;
    function getPricePerFullShare() external view returns (uint);
    function balance() external view returns (uint);
}