// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./libraries/UniERC20.sol";
import "./libraries/Sqrt.sol";
import "./libraries/VirtualBalance.sol";
import "./base/BaseHelioswap.sol";

contract Helioswap is BaseHelioswap {
    using Sqrt for uint256;
    using SafeMath for uint256;
    using UniERC20 for IERC20;
    using VirtualBalance for VirtualBalance.Data;

    struct Balances {
        uint256 src;
        uint256 dst;
    }

    struct HelioswapVolumes {
        uint128 confirmed;
        uint128 results;
    }

    struct Fees {
        uint256 fee;
        uint256 slippageFee;
    }

    event HelioswapDeposited(
        address indexed sender,
        address indexed receiver,
        uint256 share,
        uint256 token0Amount,
        uint256 token1Amount
    );
    event HelioswapWithdrawn(
        address indexed sender,
        address indexed receiver,
        uint256 share,
        uint256 token0Amount,
        uint256 token1Amount
    );
    event HelioswapSwapped(
        address indexed sender,
        address indexed receiver,
        address indexed srcToken,
        address dstToken,
        uint256 amount,
        uint256 result,
        uint256 srcAdditionBalance,
        uint256 dstRemovalBalance
    );
    event HelioswapSync(
        uint256 srcBalance,
        uint256 dstBalance,
        uint256 fee,
        uint256 slippageFee
    );

    uint256 private constant _BASE_SUPPLY = 1000; // Total supply on first deposit

    IERC20 public token0;
    IERC20 public token1;
    mapping(IERC20 => HelioswapVolumes) public volumes;
    mapping(IERC20 => VirtualBalance.Data) public virtualBalancesForAddition;
    mapping(IERC20 => VirtualBalance.Data) public virtualBalancesForRemoval;

    modifier whenNotShutdown {
        require(baseHelioswapFactory.isActive(), "Helioswap: factory shutdown");
        _;
    }

    constructor(
        IERC20 _token0,
        IERC20 _token1,
        string memory name,
        string memory symbol,
        IBaseHelioswapFactory _baseHelioswapFactory
    ) public ERC20(name, symbol) BaseHelioswap(_baseHelioswapFactory) {
        require(bytes(name).length > 0, "Helioswap: name is empty");
        require(bytes(symbol).length > 0, "Helioswap: symbol is empty");
        require(_token0 != _token1, "Helioswap: duplicate tokens");
        token0 = _token0;
        token1 = _token1;
    }

    function tokens(uint256 i) external view returns (IERC20) {
        if (i == 0) {
            return token0;
        } else if (i == 1) {
            return token1;
        } else {
            revert("Pool has two tokens");
        }
    }

    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1) {
        _reserve0 = token0.uniBalanceOf(address(this));
        _reserve1 = token1.uniBalanceOf(address(this));
    }

    function estimateBalanceForAddition(IERC20 token) public view returns (uint256) {
        uint256 balance = token.uniBalanceOf(address(this));
        return
            Math.max(
                virtualBalancesForAddition[token].current(
                    decayPeriod(),
                    balance
                ),
                balance
            );
    }

    function estimateBalanceForRemoval(IERC20 token) public view returns (uint256) {
        uint256 balance = token.uniBalanceOf(address(this));
        return
            Math.min(
                virtualBalancesForRemoval[token].current(
                    decayPeriod(),
                    balance
                ),
                balance
            );
    }

    function deposit(uint256[2] calldata maxAmounts, uint256[2] calldata minAmounts)
        external
        payable
        returns (uint256 failSupply, uint256[2] memory receivedAmounts)
    {
        return depositFor(maxAmounts, minAmounts, msg.sender);
    }

    function depositFor(
        uint256[2] memory maxAmounts,
        uint256[2] memory minAmounts,
        address target
    )
        public
        payable
        nonReentrant
        returns (uint256 fairSupply, uint256[2] memory receivedAmounts)
    {
        IERC20[2] memory _tokens = [token0, token1];
        require(
            msg.value ==
                (
                    _tokens[0].isETH()
                        ? maxAmounts[0]
                        : (_tokens[1].isETH() ? maxAmounts[1] : 0)
                ),
            "Helioswap: wrong value usage"
        );

        uint256 totalSupply = totalSupply();

        if (totalSupply == 0) {
            fairSupply = _BASE_SUPPLY.mul(99);
            _mint(address(this), _BASE_SUPPLY); // Donate up to 1%

            for (uint256 i = 0; i < maxAmounts.length; i++) {
                fairSupply = Math.max(fairSupply, maxAmounts[i]);

                require(maxAmounts[i] > 0, "Helioswap: amount is zero");
                require(
                    maxAmounts[i] >= minAmounts[i],
                    "Helioswap: minAmount not reached"
                );

                _tokens[i].uniTransferFrom(
                    msg.sender,
                    address(this),
                    maxAmounts[i]
                );
                receivedAmounts[i] = maxAmounts[i];
            }
        } else {
            uint256[2] memory realBalances;
            for (uint256 i = 0; i < realBalances.length; i++) {
                realBalances[i] = _tokens[i].uniBalanceOf(address(this)).sub(
                    _tokens[i].isETH() ? msg.value : 0
                );
            }

            // Pre-compute fair supply
            fairSupply = uint256(-1);
            for (uint256 i = 0; i < maxAmounts.length; i++) {
                fairSupply = Math.min(
                    fairSupply,
                    totalSupply.mul(maxAmounts[i]).div(realBalances[i])
                );
            }

            uint256 fairSupplyCached = fairSupply;

            for (uint256 i = 0; i < maxAmounts.length; i++) {
                require(maxAmounts[i] > 0, "Helioswap: amount is zero");
                uint256 amount = realBalances[i]
                .mul(fairSupplyCached)
                .add(totalSupply - 1)
                .div(totalSupply);
                require(amount >= minAmounts[i], "Helioswap: minAmount not reached");

                _tokens[i].uniTransferFrom(msg.sender, address(this), amount);
                receivedAmounts[i] = _tokens[i].uniBalanceOf(address(this)).sub(
                    realBalances[i]
                );
                fairSupply = Math.min(
                    fairSupply,
                    totalSupply.mul(receivedAmounts[i]).div(realBalances[i])
                );
            }

            uint256 _decayPeriod = decayPeriod(); // gas savings
            for (uint256 i = 0; i < maxAmounts.length; i++) {
                virtualBalancesForRemoval[_tokens[i]].scale(
                    _decayPeriod,
                    realBalances[i],
                    totalSupply.add(fairSupply),
                    totalSupply
                );
                virtualBalancesForAddition[_tokens[i]].scale(
                    _decayPeriod,
                    realBalances[i],
                    totalSupply.add(fairSupply),
                    totalSupply
                );
            }
        }

        require(fairSupply > 0, "Helioswap: result is not enough");
        _mint(target, fairSupply);

        emit HelioswapDeposited(
            msg.sender,
            target,
            fairSupply,
            receivedAmounts[0],
            receivedAmounts[1]
        );
    }

    function withdraw(uint256 amount, uint256[] calldata minReturns) external returns(uint256[2] memory withdrawnAmounts) {
        return withdrawFor(amount, minReturns, msg.sender);
    }

    function withdrawFor(uint256 amount, uint256[] memory minReturns, address payable target) public nonReentrant returns(uint256[2] memory withdrawnAmounts) {
        IERC20[2] memory _tokens = [token0, token1];

        uint256 totalSupply = totalSupply();
        uint256 _decayPeriod = decayPeriod(); // gas savings
        _burn(msg.sender, amount);

        for (uint i = 0; i < _tokens.length; i++) {
            IERC20 token = _tokens[i];

            uint256 preBalance = token.uniBalanceOf(address(this));
            uint256 value = preBalance.mul(amount).div(totalSupply);
            token.uniTransfer(target, value);
            withdrawnAmounts[i] = value;
            require(i >= minReturns.length || value >= minReturns[i], "Helioswap: result is not enough");

            virtualBalancesForAddition[token].scale(_decayPeriod, preBalance, totalSupply.sub(amount), totalSupply);
            virtualBalancesForRemoval[token].scale(_decayPeriod, preBalance, totalSupply.sub(amount), totalSupply);
        }

        emit HelioswapWithdrawn(msg.sender, target, amount, withdrawnAmounts[0], withdrawnAmounts[1]);
    }

    function swap(IERC20 src, IERC20 dst, uint256 amount, uint256 minReturn) external payable returns(uint256 result) {
        return swapFor(src, dst, amount, minReturn, msg.sender);
    }

    function swapFor(IERC20 src, IERC20 dst, uint256 amount, uint256 minReturn, address payable receiver) public payable nonReentrant whenNotShutdown returns (uint256 result) {
        require(msg.value == (src.isETH() ? amount : 0), "Helioswap: wrong value usage");

        Balances memory balances = Balances({
            src: src.uniBalanceOf(address(this)).sub(src.isETH() ? msg.value : 0),
            dst: dst.uniBalanceOf(address(this))
        });
        uint256 confirmed;
        Balances memory virtualBalances;
        Fees memory fees = Fees({
            fee: fee(),
            slippageFee: slippageFee()
        });
        (confirmed, result, virtualBalances) = _doTransfers(src, dst, amount, minReturn, receiver, balances, fees);
        emit HelioswapSwapped(msg.sender, receiver, address(src), address(dst), confirmed, result, virtualBalances.src, virtualBalances.dst);

        // Overflow of uint128 is desired
        volumes[src].confirmed += uint128(confirmed);
        volumes[src].results += uint128(result);

        emit HelioswapSync(balances.src, balances.dst, fees.fee, fees.slippageFee);
    }

    function _doTransfers(IERC20 src, IERC20 dst, uint256 amount, uint256 minReturn, address payable receiver, Balances memory balances, Fees memory fees)
        private returns(uint256 confirmed, uint256 result, Balances memory virtualBalances)
    {
        uint256 _decayPeriod = decayPeriod();
        virtualBalances.src = virtualBalancesForAddition[src].current(_decayPeriod, balances.src);
        virtualBalances.src = Math.max(virtualBalances.src, balances.src);
        virtualBalances.dst = virtualBalancesForRemoval
        [dst].current(_decayPeriod, balances.dst);
        virtualBalances.dst = Math.min(virtualBalances.dst, balances.dst);
        src.uniTransferFrom(msg.sender, address(this), amount);
        confirmed = src.uniBalanceOf(address(this)).sub(balances.src);
        result = _getReturn(src, dst, confirmed, virtualBalances.src, virtualBalances.dst, fees.fee, fees.slippageFee);
        require(result > 0 && result >= minReturn, "Helioswap: return is not enough");
        dst.uniTransfer(receiver, result);

        // Update virtual balances to the same direction only at imbalanced state
        if (virtualBalances.src != balances.src) {
            virtualBalancesForAddition[src].set(virtualBalances.src.add(confirmed));
        }
        if (virtualBalances.dst != balances.dst) {
            virtualBalancesForRemoval[dst].set(virtualBalances.dst.sub(result));
        }
        // Update virtual balances to the opposite direction
        virtualBalancesForRemoval[src].update(_decayPeriod, balances.src);
        virtualBalancesForAddition[dst].update(_decayPeriod, balances.dst);
    }

    /*
        spot_ret = dx * y / x
        uni_ret = dx * y / (x + dx)
        slippage = (spot_ret - uni_ret) / spot_ret
        slippage = dx * dx * y / (x * (x + dx)) / (dx * y / x)
        slippage = dx / (x + dx)
        ret = uni_ret * (1 - slip_fee * slippage)
        ret = dx * y / (x + dx) * (1 - slip_fee * dx / (x + dx))
        ret = dx * y / (x + dx) * (x + dx - slip_fee * dx) / (x + dx)

        x = amount * denominator
        dx = amount * (denominator - fee)
    */
    function _getReturn(IERC20 src, IERC20 dst, uint256 amount, uint256 srcBalance, uint256 dstBalance, uint256 fee, uint256 slippageFee) internal view returns(uint256) {
        if (src > dst) {
            (src, dst) = (dst, src);
        }
        if (amount > 0 && src == token0 && dst == token1) {
            uint256 taxedAmount = amount.sub(amount.mul(fee).div(HelioswapConstants._FEE_DENOMINATOR));
            uint256 srcBalancePlusTaxedAmount = srcBalance.add(taxedAmount);
            uint256 ret = taxedAmount.mul(dstBalance).div(srcBalancePlusTaxedAmount);
            uint256 feeNumerator = HelioswapConstants._FEE_DENOMINATOR.mul(srcBalancePlusTaxedAmount).sub(slippageFee.mul(taxedAmount));
            uint256 feeDenominator = HelioswapConstants._FEE_DENOMINATOR.mul(srcBalancePlusTaxedAmount);
            return ret.mul(feeNumerator).div(feeDenominator);
        }
    }

    function rescueFunds(IERC20 token, uint256 amount) external nonReentrant onlyOwner {
        uint256 balance0 = token0.uniBalanceOf(address(this));
        uint256 balance1 = token1.uniBalanceOf(address(this));

        token.uniTransfer(msg.sender, amount);

        require(token0.uniBalanceOf(address(this)) >= balance0, "Helioswap: access denied");
        require(token1.uniBalanceOf(address(this)) >= balance1, "Helioswap: access denied");
        require(balanceOf(address(this)) >= _BASE_SUPPLY, "Helioswap: access denied");
    }

    // FE function
    function getReturn(IERC20 src, IERC20 dst, uint256 amount) public view returns(uint256 result) {
        if (src.uniBalanceOf(address(this)) == 0 || dst.uniBalanceOf(address(this)) == 0) {
            return 0;
        }
        Balances memory balances = Balances({
            src: src.uniBalanceOf(address(this)),
            dst: dst.uniBalanceOf(address(this))
        });
        Balances memory virtualBalances;
        Fees memory fees = Fees({
            fee: fee(),
            slippageFee: slippageFee()
        });

        uint256 _decayPeriod = decayPeriod();
        virtualBalances.src = virtualBalancesForAddition[src].current(_decayPeriod, balances.src);
        virtualBalances.src = Math.max(virtualBalances.src, balances.src);
        virtualBalances.dst = virtualBalancesForRemoval
        [dst].current(_decayPeriod, balances.dst);
        virtualBalances.dst = Math.min(virtualBalances.dst, balances.dst);
        return _getReturn(src, dst, amount, virtualBalances.src, virtualBalances.dst, fees.fee, fees.slippageFee);
    }
}