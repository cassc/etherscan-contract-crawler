// SPDX-License-Identifier: MIT

// Forked and refactored by:
//////////////////////////////////////////////solarprotocol.io//////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\__0xFluffyBeard__/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {LibSimpleBlacklist} from "../blacklist/LibSimpleBlacklist.sol";
import {LibContext} from "../libraries/LibContext.sol";
import {LibUtils} from "./LibUtils.sol";
import {LibPausable} from "../pausable/LibPausable.sol";

import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LibProtocolX {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    struct Storage {
        string name;
        string symbol;
        uint256 rebaseRate;
        uint256 index;
        uint256 lastRebasedTime;
        uint256 lastAddLiquidityTime;
        uint256 totalSupply;
        uint256 gonsPerFragment;
        uint256 autoLiquidityAmount;
        uint256 collectedFeeTreasury;
        uint256 collectedFeeXshare;
        uint256 collectedFeeAfterburner;
        IUniswapV2Router02 router;
        address autoLiquidityReceiver;
        address treasuryReceiver;
        address xshareFundReceiver;
        address afterburner;
        address pair;
        bool inSwap;
        bool swapEnabled;
        bool autoRebase;
        bool autoAddLiquidity;
        EnumerableSet.AddressSet exemptFromRebase;
        mapping(address => bool) exemptFromFees;
        mapping(address => uint256) gonBalances;
        mapping(address => mapping(address => uint256)) allowedFragments;
        mapping(address => bool) defaultOperators;
        uint256 lastSwapBackTime;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.ptx.LibProtocolX");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    uint256 internal constant DECIMALS = 5;
    uint8 internal constant RATE_DECIMALS = 7;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal constant ZERO = 0x0000000000000000000000000000000000000000;

    uint256 internal constant MAXREBASERATE = 10000;
    uint256 internal constant MINREBASERATE = 20;

    uint256 internal constant MAX_UINT256 = type(uint256).max;
    uint256 internal constant MAX_SUPPLY = MAX_UINT256;

    uint256 internal constant INITIAL_FRAGMENTS_SUPPLY = 5e7 * 10**DECIMALS;
    uint256 internal constant TOTAL_GONS =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 internal constant FEE_DENOMINATOR = 1000;
    uint256 internal constant LIQUIDITY_FEE = 0;
    uint256 internal constant LIQUIDITY_FEE_SELL = 50;
    uint256 internal constant TREASURY_FEE = 40;
    uint256 internal constant TREASURY_FEE_SELL = 80;
    uint256 internal constant XSHARE_FUND_FEE = 0;
    uint256 internal constant XSHARE_FUND_FEE_SELL = 20;
    uint256 internal constant AFTERBURNER_FEE = 0;
    uint256 internal constant AFTERBURNER_FEE_SELL = 30;

    //events
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event SwapBack(
        uint256 contractTokenBalance,
        uint256 amountETHToTreasuryAndTIF
    );
    event SetRebaseRate(uint256 indexed rebaseRate);
    event UpdateAutoRebaseStatus(bool status);
    event UpdateAutoAddLiquidityStatus(bool status);
    event UpdateAutoSwapStatus(bool status);
    event UpdateFeeReceivers(
        address liquidityReceiver,
        address treasuryReceiver,
        address xshareFundReceiver,
        address afterburner
    );

    event UpdateExemptFromFees(address account, bool flag);
    event UpdateExemptFromRebase(address account, bool flag);
    event UpdateDefaultOperator(address account, bool flag);

    /**
     * @dev ERC20 transfer event. Emitted when issued after investment.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function enforceValidRecipient(address account) internal pure {
        require(account != address(0x0), "invalid address");
    }

    function init(
        string memory name_,
        string memory symbol_,
        uint256 startTime,
        address autoLiquidityReceiver,
        address treasuryReceiver,
        address xshareFundReceiver,
        address afterburner,
        IUniswapV2Router02 router,
        address[] memory exemptFromRebase
    ) internal {
        Storage storage s = _storage();

        s.name = name_;
        s.symbol = symbol_;

        updateRouterAndCreatePair(router);

        s.totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        s.gonBalances[treasuryReceiver] = TOTAL_GONS;
        s.gonsPerFragment = TOTAL_GONS.div(s.totalSupply);

        // solhint-disable-next-line not-rely-on-time
        s.lastRebasedTime = startTime > block.timestamp
            ? startTime // solhint-disable-next-line not-rely-on-time
            : block.timestamp;

        setFeeReceivers(
            autoLiquidityReceiver,
            treasuryReceiver,
            xshareFundReceiver,
            afterburner
        );

        setExemptFromFees(treasuryReceiver, true);
        setExemptFromFees(xshareFundReceiver, true);
        setExemptFromFees(afterburner, true);

        setExemptFromRebase(exemptFromRebase, true);

        s.index = gonsForBalance(10**DECIMALS);

        emit Transfer(address(0x0), treasuryReceiver, s.totalSupply);

        s.rebaseRate = 3656;

        s.swapEnabled = false;
        s.autoRebase = false;
        s.autoAddLiquidity = false;

        LibPausable.pause();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() internal view returns (string memory) {
        return _storage().name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() internal view returns (string memory) {
        return _storage().symbol;
    }

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() internal pure returns (uint8) {
        return uint8(DECIMALS);
    }

    function totalSupply() internal view returns (uint256) {
        return _storage().totalSupply;
    }

    function balanceOf(address account) internal view returns (uint256) {
        return _storage().gonBalances[account].div(_storage().gonsPerFragment);
    }

    function shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        Storage storage s = _storage();

        return
            (s.pair == from || s.pair == to) &&
            !isExemptFromFees(from) &&
            !isExemptFromFees(to);
    }

    function shouldAddLiquidity() internal view returns (bool) {
        Storage storage s = _storage();

        return
            s.autoAddLiquidity &&
            !s.inSwap &&
            LibContext.msgSender() != s.pair &&
            // solhint-disable-next-line not-rely-on-time
            block.timestamp >= (s.lastAddLiquidityTime + 12 hours);
    }

    function shouldSwapBack() internal view returns (bool) {
        Storage storage s = _storage();

        return
            s.swapEnabled &&
            !s.inSwap &&
            LibContext.msgSender() != s.pair &&
            // solhint-disable-next-line not-rely-on-time
            block.timestamp >= (s.lastSwapBackTime + 1 hours);
    }

    function allowance(address owner_, address spender)
        internal
        view
        returns (uint256)
    {
        Storage storage s = _storage();

        if (s.defaultOperators[spender]) {
            return MAX_UINT256;
        }

        return s.allowedFragments[owner_][spender];
    }

    function approve(
        address owner,
        address spender,
        uint256 value
    ) internal returns (bool) {
        // solhint-disable-next-line reason-string
        require(owner != address(0), "ERC20: approve from the zero address");
        // solhint-disable-next-line reason-string
        require(spender != address(0), "ERC20: approve to the zero address");

        _storage().allowedFragments[owner][spender] = value;

        emit Approval(owner, spender, value);

        return true;
    }

    function spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        if (owner == spender) {
            return;
        }

        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != MAX_UINT256) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        LibSimpleBlacklist.enforceNotBlacklisted();
        LibSimpleBlacklist.enforceNotBlacklisted(sender);
        LibSimpleBlacklist.enforceNotBlacklisted(recipient);

        Storage storage s = _storage();

        if (s.inSwap) {
            return basicTransfer(sender, recipient, amount);
        }

        if (shouldRebase()) {
            rebase();
        }

        if (shouldAddLiquidity()) {
            s.inSwap = true;
            addLiquidity();
            s.inSwap = false;
        } else if (shouldSwapBack()) {
            s.inSwap = true;
            swapBack();
            s.inSwap = false;
        }

        uint256 gonAmount = amount.mul(s.gonsPerFragment);

        s.gonBalances[sender] = s.gonBalances[sender].sub(gonAmount);

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, gonAmount)
            : gonAmount;

        s.gonBalances[recipient] = s.gonBalances[recipient].add(
            gonAmountReceived
        );

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(s.gonsPerFragment)
        );

        return true;
    }

    function basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        Storage storage s = _storage();

        uint256 gonAmount = amount.mul(s.gonsPerFragment);
        s.gonBalances[from] = s.gonBalances[from].sub(gonAmount);
        s.gonBalances[to] = s.gonBalances[to].add(gonAmount);

        emit Transfer(from, to, amount);

        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 gonAmount
    ) internal returns (uint256) {
        Storage storage s = _storage();

        // Declare the variables for the fee amounts
        uint256 feeAmountLiquidity = gonAmount.mul(LIQUIDITY_FEE).div(
            FEE_DENOMINATOR
        );
        uint256 feeAmountTreasury = gonAmount.mul(TREASURY_FEE).div(
            FEE_DENOMINATOR
        );
        uint256 feeAmountXshare = gonAmount.mul(XSHARE_FUND_FEE).div(
            FEE_DENOMINATOR
        );
        uint256 feeAmountAfterburner = gonAmount.mul(AFTERBURNER_FEE).div(
            FEE_DENOMINATOR
        );

        // Calculate each fee amount when selling
        if (recipient == s.pair) {
            feeAmountLiquidity = gonAmount.mul(LIQUIDITY_FEE_SELL).div(
                FEE_DENOMINATOR
            );
            feeAmountTreasury = gonAmount.mul(TREASURY_FEE_SELL).div(
                FEE_DENOMINATOR
            );
            feeAmountXshare = gonAmount.mul(XSHARE_FUND_FEE_SELL).div(
                FEE_DENOMINATOR
            );
            feeAmountAfterburner = gonAmount.mul(AFTERBURNER_FEE_SELL).div(
                FEE_DENOMINATOR
            );
        }

        uint256 totalFeeAmount = feeAmountLiquidity +
            feeAmountTreasury +
            feeAmountXshare +
            feeAmountAfterburner;

        s.gonBalances[address(this)] += totalFeeAmount;

        s.autoLiquidityAmount += feeAmountLiquidity;
        s.collectedFeeTreasury += feeAmountTreasury;
        s.collectedFeeXshare += feeAmountXshare;
        s.collectedFeeAfterburner += feeAmountAfterburner;

        emit Transfer(
            sender,
            address(this),
            totalFeeAmount.div(s.gonsPerFragment)
        );

        return gonAmount.sub(totalFeeAmount);
    }

    function rebase() internal {
        Storage storage s = _storage();

        if (s.inSwap) return;

        // solhint-disable-next-line not-rely-on-time
        uint256 deltaTime = block.timestamp - s.lastRebasedTime;
        uint256 times = deltaTime.div(30 minutes);
        uint256 epoch = times.mul(30);

        for (uint256 i = 0; i < times; i++) {
            s.totalSupply = s
                .totalSupply
                .mul((10**RATE_DECIMALS).add(s.rebaseRate))
                .div(10**RATE_DECIMALS);
        }

        if (s.totalSupply > MAX_SUPPLY) {
            s.totalSupply = MAX_SUPPLY;
        }

        uint256 oldGonsPerFragment = s.gonsPerFragment;

        s.gonsPerFragment = TOTAL_GONS.div(s.totalSupply);
        s.lastRebasedTime = s.lastRebasedTime.add(times.mul(30 minutes));

        updateAllExemptFromRebaseBalances(oldGonsPerFragment);

        IUniswapV2Pair(s.pair).sync();

        emit LogRebase(epoch, s.totalSupply);
    }

    function shouldRebase() internal view returns (bool) {
        Storage storage s = _storage();

        return
            s.autoRebase &&
            (s.totalSupply < MAX_SUPPLY) &&
            LibContext.msgSender() != s.pair &&
            !s.inSwap &&
            // solhint-disable-next-line not-rely-on-time
            block.timestamp >= (s.lastRebasedTime + 30 minutes);
    }

    function addLiquidity() internal {
        Storage storage s = _storage();

        if (s.autoLiquidityAmount > s.gonBalances[address(this)]) {
            s.autoLiquidityAmount = s.gonBalances[address(this)];
        }

        uint256 autoLiquidityAmount = s.autoLiquidityAmount.div(
            s.gonsPerFragment
        );

        s.autoLiquidityAmount = 0;
        uint256 amountToLiquify = autoLiquidityAmount.div(2);
        uint256 amountToSwap = autoLiquidityAmount.sub(amountToLiquify);

        if (amountToSwap == 0) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = s.router.WETH();

        uint256 balanceBefore = address(this).balance;

        s.router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        uint256 amountETHLiquidity = address(this).balance.sub(balanceBefore);

        if (amountToLiquify > 0 && amountETHLiquidity > 0) {
            s.router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                s.autoLiquidityReceiver,
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            );
        }

        // solhint-disable-next-line not-rely-on-time
        s.lastAddLiquidityTime = block.timestamp;
    }

    function swapBack() internal {
        Storage storage s = _storage();

        if (s.autoLiquidityAmount > s.gonBalances[address(this)]) {
            s.autoLiquidityAmount = s.gonBalances[address(this)];
        }

        uint256 amountToSwapTreasury = s.collectedFeeTreasury /
            s.gonsPerFragment;
        uint256 amountToSwapXshare = s.collectedFeeXshare / s.gonsPerFragment;
        uint256 amountToSwapAfterburner = s.collectedFeeAfterburner /
            s.gonsPerFragment;

        uint256 totalAmountToSwap = amountToSwapTreasury +
            amountToSwapXshare +
            amountToSwapAfterburner;

        if (totalAmountToSwap == 0) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = s.router.WETH();

        uint256 ethSent;

        ethSent += swapToETHAndSend(
            amountToSwapTreasury,
            path,
            s.treasuryReceiver
        );
        s.collectedFeeTreasury = 0;

        ethSent += swapToETHAndSend(
            amountToSwapXshare,
            path,
            s.xshareFundReceiver
        );
        s.collectedFeeXshare = 0;

        ethSent += swapToETHAndSend(
            amountToSwapAfterburner,
            path,
            s.afterburner
        );
        s.collectedFeeAfterburner = 0;

        // solhint-disable-next-line not-rely-on-time
        s.lastSwapBackTime = block.timestamp;

        emit SwapBack(totalAmountToSwap, ethSent);
    }

    function swapToETHAndSend(
        uint256 amountToSwap,
        address[] memory path,
        address receiver
    ) internal returns (uint256 ethSent) {
        Storage storage s = _storage();

        if (0 >= amountToSwap) {
            return 0;
        }

        uint256 balanceBefore = address(this).balance;

        s.router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        ethSent = address(this).balance.sub(balanceBefore);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(receiver).call{value: ethSent, gas: 30000}(
            ""
        );

        require(success, "Failed to send ETH");
    }

    function index() internal view returns (uint256) {
        return balanceForGons(_storage().index);
    }

    function gonsForBalance(uint256 amount) internal view returns (uint256) {
        return amount.mul(_storage().gonsPerFragment);
    }

    function balanceForGons(uint256 gons) internal view returns (uint256) {
        return gons.div(_storage().gonsPerFragment);
    }

    function getCirculatingSupply() internal view returns (uint256) {
        Storage storage s = _storage();

        return
            (TOTAL_GONS.sub(s.gonBalances[DEAD]).sub(s.gonBalances[ZERO])).div(
                s.gonsPerFragment
            );
    }

    function getLiquidityBacking(uint256 accuracy)
        internal
        view
        returns (uint256)
    {
        Storage storage s = _storage();

        uint256 liquidityBalance = s.gonBalances[s.pair].div(s.gonsPerFragment);
        return
            accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }

    function setAutoRebase(bool flag) internal {
        Storage storage s = _storage();

        require(s.autoRebase != flag, "Not changed");

        if (flag) {
            // solhint-disable-next-line not-rely-on-time
            s.lastRebasedTime = block.timestamp;
        }
        s.autoRebase = flag;

        emit UpdateAutoRebaseStatus(flag);
    }

    function setSwapEnabled(bool flag) internal {
        Storage storage s = _storage();

        require(s.swapEnabled != flag, "swapEnabled did not change");

        s.swapEnabled = flag;

        emit UpdateAutoSwapStatus(flag);
    }

    function setAutoAddLiquidity(bool flag) internal {
        Storage storage s = _storage();

        require(s.autoAddLiquidity != flag, "autoAddLiquidity did not change");
        if (flag) {
            // solhint-disable-next-line not-rely-on-time
            s.lastAddLiquidityTime = block.timestamp;
        }
        s.autoAddLiquidity = flag;

        emit UpdateAutoAddLiquidityStatus(flag);
    }

    function setRebaseRate(uint256 rebaseRate) internal {
        Storage storage s = _storage();

        require(s.rebaseRate != rebaseRate, "rebaseRate not changed");
        require(
            rebaseRate < MAXREBASERATE && rebaseRate > MINREBASERATE,
            "rebaseRate out of range"
        );
        s.rebaseRate = rebaseRate;

        emit SetRebaseRate(rebaseRate);
    }

    function setFeeReceivers(
        address autoLiquidityReceiver,
        address treasuryReceiver,
        address xshareFundReceiver,
        address afterburner
    ) internal {
        Storage storage s = _storage();

        require(
            autoLiquidityReceiver != address(0x0),
            "Invalid autoLiquidityReceiver"
        );
        require(treasuryReceiver != address(0x0), "Invalid treasuryReceiver");
        require(
            xshareFundReceiver != address(0x0),
            "Invalid xshareFundReceiver"
        );
        require(afterburner != address(0x0), "Invalid afterburner");

        s.autoLiquidityReceiver = autoLiquidityReceiver;
        s.treasuryReceiver = treasuryReceiver;
        s.xshareFundReceiver = xshareFundReceiver;
        s.afterburner = afterburner;

        emit UpdateFeeReceivers(
            autoLiquidityReceiver,
            treasuryReceiver,
            xshareFundReceiver,
            afterburner
        );
    }

    function setExemptFromFees(address account, bool flag) internal {
        _storage().exemptFromFees[account] = flag;

        emit UpdateExemptFromFees(account, flag);
    }

    function isExemptFromFees(address account) internal view returns (bool) {
        return account == address(this) || _storage().exemptFromFees[account];
    }

    function setExemptFromRebase(address[] memory accounts, bool flag)
        internal
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            setExemptFromRebase(accounts[i], flag);
        }
    }

    function setExemptFromRebase(address account, bool flag) internal {
        Storage storage s = _storage();

        if (flag) {
            if (!s.exemptFromRebase.contains(account)) {
                s.exemptFromRebase.add(account);
            }
        } else {
            s.exemptFromRebase.remove(account);
        }

        emit UpdateExemptFromRebase(account, flag);
    }

    function isExemptFromRebase(address account) internal view returns (bool) {
        return _storage().exemptFromRebase.contains(account);
    }

    function updateAllExemptFromRebaseBalances(uint256 oldGonsPerFragment)
        internal
    {
        Storage storage s = _storage();

        uint256 newGonsPerFragment = s.gonsPerFragment;

        uint256 i = 0;
        uint256 length = s.exemptFromRebase.length();
        while (i < length) {
            address account = s.exemptFromRebase.at(i);
            s.gonBalances[account] = s
                .gonBalances[account]
                .div(oldGonsPerFragment)
                .mul(newGonsPerFragment);

            unchecked {
                ++i;
            }
        }
    }

    function getRebaseRate() internal view returns (uint256) {
        return _storage().rebaseRate;
    }

    function getLastRebasedTime() internal view returns (uint256) {
        return _storage().lastRebasedTime;
    }

    function getReceivers()
        internal
        view
        returns (
            address,
            address,
            address,
            address
        )
    {
        Storage storage s = _storage();

        return (
            s.autoLiquidityReceiver,
            s.treasuryReceiver,
            s.xshareFundReceiver,
            s.afterburner
        );
    }

    function updateRouterAndCreatePair(IUniswapV2Router02 router) internal {
        Storage storage s = _storage();

        require(s.router != router, "router did not change");

        s.router = router;
        s.pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        s.allowedFragments[address(this)][address(router)] = MAX_UINT256;
        s.allowedFragments[address(this)][s.pair] = MAX_UINT256;

        setExemptFromRebase(s.pair, true);
    }

    function setDefaultOperator(address account, bool flag) internal {
        _storage().defaultOperators[account] = flag;

        emit UpdateDefaultOperator(account, flag);
    }
}