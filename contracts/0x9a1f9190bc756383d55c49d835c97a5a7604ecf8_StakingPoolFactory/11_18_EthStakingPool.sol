// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/CurrencyTransferLib.sol";
import "./interfaces/IWETH.sol";
import "./StakingPool.sol";

/*
 * Website: alacritylsd.com
 * X/Twitter: x.com/alacritylsd
 * Telegram: t.me/alacritylsd
 */

/*
 * Same as StakingPool, but with WETH as the staking token.
 */
contract EthStakingPool is StakingPool {
    using SafeMath for uint256;

    IWETH private weth;

    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _nativeTokenWrapper,
        uint256 _durationInDays,
        address _feeManager
    )
        StakingPool(
            _rewardsDistribution,
            _rewardsToken,
            _nativeTokenWrapper,
            _durationInDays,
            _feeManager
        )
    {
        weth = IWETH(_nativeTokenWrapper);
    }

    function _transferStakingToken(uint256 amount) internal virtual override {
        weth.deposit{value: amount}();

        uint256 diff = msg.value.sub(amount);
        if (diff > 0) {
            CurrencyTransferLib.transferCurrency(
                CurrencyTransferLib.NATIVE_TOKEN,
                address(this),
                msg.sender,
                diff
            );
        }
    }

    function _withdrawStakingToken(uint256 amount) internal virtual override {
        weth.withdraw(amount);
        CurrencyTransferLib.transferCurrency(
            CurrencyTransferLib.NATIVE_TOKEN,
            address(this),
            msg.sender,
            amount
        );
    }

    function withdrawExcess(
        address to
    ) external virtual override nonReentrant onlyRewardsDistribution {
        require(block.timestamp >= periodFinish, "Not ready");

        uint256 amount = address(this).balance;
        require(amount > 0, "No rewards");

        CurrencyTransferLib.transferCurrency(
            CurrencyTransferLib.NATIVE_TOKEN,
            address(this),
            to,
            amount
        );
    }
}