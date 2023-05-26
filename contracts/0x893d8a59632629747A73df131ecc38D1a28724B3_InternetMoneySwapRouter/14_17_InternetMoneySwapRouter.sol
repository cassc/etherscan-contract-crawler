// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./OracleReader.sol";
import "./interfaces/IWETH.sol";
import "./Migratable.sol";
import "./Utils.sol";

/**
 * @title contract for swapping tokens
 * @notice use this contract for only the most basic simulation
 * @dev function calls are currently implemented without side effects
 * @notice multicall was not included here because sender
 * is less relevant outside of a swap
 * which already allows for multiple swaps
 */
contract InternetMoneySwapRouter is Ownable, Migratable, Utils, OracleReader {
    using Address for address payable;
    using SafeERC20 for IERC20;
    /** a single dex entry */
    struct Dex {
        uint64 id;
        address router;
        bool disabled;
        string name;
    }
    Dex[] public dexInfo;

    error DexConflict(uint256 dexIndex);
    error DexDisabled();
    error NativeMissing(uint256 pathIndex);
    error FeeMissing(uint256 expected, uint256 provided, string message);
    error DestinationMissing();

    /**
     * returns all relevant dex info needed to render clients
     * @return _dexInfo the array of dexes as a DexInfo array
     * @return _wNative the wrapped native address
     * @return _destination destination of fees
     * @return _fee fee numerator as an int constant
     * @return _feeDenominator constant at 100_000
     */
    function allDexInfo() public view returns(
        Dex[] memory _dexInfo,
        address _wNative,
        address _destination,
        uint256 _fee,
        uint256 _feeDenominator
    ) {
        _dexInfo = dexInfo;
        _wNative = wNative;
        _destination = destination;
        _fee = fee;
        _feeDenominator = feeDenominator;
    }

    /**
     * where the fees will end up
     * @notice this address cannot be updated after it is set during constructor
     * @notice the destination must be payable + have a receive function
     * that has gas consumption less than limit
     */
    address payable public immutable destination;
    /**
     * @notice map a router to a dex to check
     * if the router was already added, the addition should fail
     */
    mapping(address => uint256) public routerToDex;

    event AddDex(address indexed executor, uint256 indexed dexId);
    event UpdateDex(address indexed executor, uint256 indexed dexId);

    /**
     * sets up the wallet swap contract
     * @param _destination where native currency will be sent
     * @param _wNative the address that is used to wrap and unwrap tokens
     * @notice wNative does not have to have the name wNative
     * it is just a placeholder for wrapped native currency
     * @notice the destination address must have a receive / fallback method
     * to receive native currency
     */
    constructor(
        address payable _destination,
        address payable _wNative,
        uint96 _fee
    ) OracleReader(_wNative, _destination == address(0) ? 0 : _fee) {
        destination = _destination;
    }

    receive() external payable {
        // the protocol thanks you for your donation
        if (destination == address(0)) {
            revert DestinationMissing();
        }
    }

    /**
     * @notice Add new Dex
     * @dev This also generate id of the Dex
     * @param _dexName Name of the Dex
     * @param _router address of the dex router
     */
    function addDex(
        string calldata _dexName,
        address _router
    ) external payable onlyOwner {
        uint256 id = dexInfo.length;
        dexInfo.push(Dex({
            name: _dexName,
            router: _router,
            id: uint64(id),
            disabled: false
        }));
        if (routerToDex[_router] != 0) {
            revert DexConflict(routerToDex[_router]);
        }
        routerToDex[_router] = dexInfo.length;
        emit AddDex(msg.sender, id);
    }

    /**
     * Updates dex info
     * @param id the id to update in dexInfo array
     * @param _name pass anything other than an empty string to update the name
     * @notice _factory is not used in these contracts
     * it is held for external services to utilize
     */
    function updateDex(
        uint256 id,
        string memory _name
    ) external payable onlyOwner {
        if (bytes(_name).length == 0) {
            return;
        }
        dexInfo[id].name = _name;
        emit UpdateDex(msg.sender, id);
    }

    /**
     * sets disabled flag on a dex
     * @param id the dex id to disable
     * @param disabled the boolean denoting whether to disable or enable
     */
    function disableDex(uint256 id, bool disabled) external payable onlyOwner {
        if (dexInfo[id].disabled == disabled) {
            return;
        }
        dexInfo[id].disabled = disabled;
        emit UpdateDex(msg.sender, id);
    }

    /**
     * distributes all fees, after withdrawing wrapped native balance
     * @notice if the amount is 0, all funds will be drained
     * @notice if an amount is provided, the method will only unwrap
     * the wNative token if it does not have enough native balance to cover the amount
     * @notice the balance will change in the middle of the function
     * if the appropriate conditions are met. however, we do not use that updated balance
     * because the whole amount may not have been asked for
     */
    function distributeAll(uint256 amount) external payable {
        (uint256 nativeBalance, uint256 wNativeBalance) = pendingDistributionSegmented();
        if ((amount == 0 || nativeBalance < amount) && wNativeBalance > 0) {
            IWETH(wNative).withdraw(wNativeBalance);
        }
        amount = clamp(amount, nativeBalance + wNativeBalance);
        if (amount == 0) {
            return;
        }
        destination.sendValue(amount);
    }
    /**
     * A public method to distribute fees
     * @param amount the amount of ether to distribute
     * @notice failure in receipt will cause this tx to fail as well
     */
    function distribute(uint256 amount) external payable {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            return;
        }
        destination.sendValue(clamp(amount, balance));
    }

    /**
     * returns the balance in wNative token and native token as two separate numbers
     */
    function pendingDistributionSegmented() public view returns(uint256, uint256) {
        return (address(this).balance, IWETH(wNative).balanceOf(address(this)));
    }

    /**
     * returns the balance of wNative token and native token,
     * treating them as an aggregate balance for ease
     */
    function pendingDistribution() public view returns(uint256) {
        (uint256 nativeBalance, uint256 wNativeBalance) = pendingDistributionSegmented();
        return nativeBalance + wNativeBalance;
    }

    /**
     * this method transfers funds from the sending address
     * and returns the delta of the balance of this contracat
     * @param sourceTokenId is the token id to transfer from the sender
     * @param amountIn is the amount that you desire to transfer from the sender
     * @return delta the amount that was actually transferred, using a `balanceOf` check
     */
    function collectFunds(address sourceTokenId, uint256 amountIn) internal returns(uint256) {
        address self = address(this);
        uint256 balanceBefore = IERC20(sourceTokenId).balanceOf(self);
        IERC20(sourceTokenId).safeTransferFrom(_msgSender(), self, amountIn);
        return IERC20(sourceTokenId).balanceOf(self) - balanceBefore;
    }

    /**
     * @notice Swap erc20 token, end with erc20 token
     * @param _dexId ID of the Dex
     * @param recipient address to receive funds
     * @param _path Token address array
     * @param _amountIn Input amount
     * @param _minAmountOut Output token amount
     * @param _deadline the time at which this transaction can no longer be run
     * @notice anything extra in msg.value is treated as a donation
     * @notice anyone using this method will be costing themselves more
     * than simply going through the router they wish to swap through
     * so anything that comes through really acts like a high yeilding voluntary donation box
     * @notice if wNative is passed in as the first or last step of the path
     * then fees will be calculated from that number available at that time
     * @notice fee is only paid via msg.value if and only if the
     * first and last of the path are not a wrapped token
     * @notice if first or last of the path is wNative
     * then msg.value is required to be zero
     */
    function swapTokenV2(
        uint256 _dexId,
        address recipient,
        address[] calldata _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _deadline
    ) external payable {
        address first = _path[0];
        address last = _path[_path.length - 1];
        address _wNative = wNative;
        uint256 nativeFee = 0;
        if (first == _wNative) {
            nativeFee = (_amountIn * fee) / feeDenominator;
            if (msg.value != 0) {
                revert FeeMissing(0, msg.value, "fees paid from input");
            }
        } else if (last != _wNative && fee > 0) {
            (, uint256 minimum) = getFeeMinimum(
                IUniswapV2Router02(dexInfo[_dexId].router).factory(),
                _amountIn,
                _path
            );
            // introduce fee tolerance here
            minimum = (minimum * 9) / 10;
            if (minimum == 0) {
                revert FeeMissing(0, msg.value, "unable to compute fees");
            }
            if (msg.value < minimum) {
                revert FeeMissing(minimum, msg.value, "not enough fee value");
            }
        }
        // run transfer as normal
        uint256 actualAmountIn = collectFunds(first, _amountIn) - nativeFee;
        uint256 actualAmountOut = swapExactTokenForTokenV2(
            _dexId,
            _path,
            actualAmountIn,
            _minAmountOut,
            _deadline
        );
        uint256 actualAmountOutAfterFees = actualAmountOut;
        if (last == _wNative) {
            actualAmountOutAfterFees -= (actualAmountOut * fee) / feeDenominator;
            if (fee != 0 && msg.value != 0) {
                revert FeeMissing(0, msg.value, "fees paid from output");
            }
        }
        IERC20(last).safeTransfer(recipient, actualAmountOutAfterFees);
    }

    /**
     * @notice Swap native currency, end with erc20 token
     * @param _dexId ID of the Dex
     * @param recipient address to receive funds
     * @param _path Token address array
     * @param _amountIn Input amount
     * @param _minAmountOut Output token amount
     * @param _deadline the time at which this transaction can no longer be run
     * @notice anything extra in msg.value is treated as a donation
     * @notice this method does not require an approval step from the user
     */
    function swapNativeToV2(
        uint256 _dexId,
        address recipient,
        address[] calldata _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _deadline
    ) external payable {
        uint256 minimal = (msg.value * fee) / feeDenominator;
        address payable _wNative = wNative;
        if (msg.value != _amountIn + minimal) {
            revert FeeMissing(_amountIn + minimal, msg.value, "amount + fees must = total");
        }
        if (_path[0] != _wNative) {
            revert NativeMissing(0);
        }
        // convert native to wNative
        IWETH(_wNative).deposit{value: _amountIn}();
        uint256 actualAmountOut = swapExactTokenForTokenV2(_dexId, _path, _amountIn, _minAmountOut, _deadline);
        IERC20(_path[_path.length - 1]).safeTransfer(recipient, actualAmountOut);
    }

    /**
     * @notice Swap ERC-20 Token, end with native currency
     * @param _dexId ID of the Dex
     * @param recipient address to receive funds
     * @param _path Token address array
     * @param _amountIn Input amount
     * @param _minAmountOut Output token amount
     * @param _deadline the time at which this transaction can no longer be run
     * @notice anything extra in msg.value is treated as a donation
     */
    function swapToNativeV2(
        uint256 _dexId,
        address payable recipient,
        address[] calldata _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _deadline
    ) external payable {
        address payable _wNative = wNative;
        if (_path[_path.length - 1] != _wNative) {
            revert NativeMissing(_path.length - 1);
        }
        uint256 actualAmountIn = collectFunds(_path[0], _amountIn);
        uint256 actualAmountOut = swapExactTokenForTokenV2(_dexId, _path, actualAmountIn, _minAmountOut, _deadline);
        uint256 minimal = (actualAmountOut * fee) / feeDenominator;
        uint256 actualAmountOutAfterFee = actualAmountOut - minimal;
        if (actualAmountOut > 0) {
            IWETH(_wNative).withdraw(actualAmountOut);
        }
        recipient.sendValue(actualAmountOutAfterFee);
    }

    function swapExactTokenForTokenV2(
        uint256 dexId,
        address[] calldata _path,
        uint256 _amountIn, // this value has been checked
        uint256 _minAmountOut, // this value will be met
        uint256 _deadline
    ) internal returns (uint256) {
        Dex memory dex = dexInfo[dexId];
        if (dex.disabled) {
            revert DexDisabled();
        }
        address last = _path[_path.length - 1];
        // approve router to swap tokens
        IERC20(_path[0]).approve(dex.router, _amountIn);
        // call to swap exact tokens
        uint256 balanceBefore = IERC20(last).balanceOf(address(this));
        IUniswapV2Router02(dex.router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            _minAmountOut,
            _path,
            address(this),
            _deadline
        );
        return IERC20(last).balanceOf(address(this)) - balanceBefore;
    }
}