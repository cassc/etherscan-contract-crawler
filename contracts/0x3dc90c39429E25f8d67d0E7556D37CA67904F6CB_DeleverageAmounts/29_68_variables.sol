//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract ConstantVariables is ERC20Upgradeable {
    IInstaIndex internal constant instaIndex =
        IInstaIndex(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    IERC20 internal constant wethContract =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 internal constant stethContract =
        IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    IAaveProtocolDataProvider internal constant aaveProtocolDataProvider =
        IAaveProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    IAaveAddressProvider internal constant aaveAddressProvider =
        IAaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    IERC20 internal constant awethVariableDebtToken =
        IERC20(0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf);
    IERC20 internal constant astethToken =
        IERC20(0x1982b2F5814301d4e9a8b0201555376e62F82428);
    IInstaList internal constant instaList =
        IInstaList(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);
}

contract Variables is ConstantVariables {
    uint256 internal _status = 1;

    // only authorized addresses can rebalance
    mapping(address => bool) internal _isRebalancer;

    IERC20 internal _token;

    uint8 internal _tokenDecimals;

    uint256 internal _tokenMinLimit;

    IERC20 internal _atoken;

    IDSA internal _vaultDsa;

    struct Ratios {
        uint16 maxLimit; // Above this withdrawals are not allowed
        uint16 maxLimitGap;
        uint16 minLimit; // After leverage the ratio should be below minLimit & above minLimitGap
        uint16 minLimitGap;
        uint16 stEthLimit; // if 7500. Meaning stETH collateral covers 75% of the ETH debt. Excess ETH will be covered by token limit.
        // send borrow rate in 4 decimals from UI. In the smart contract it'll convert to 27 decimals which where is 100%
        uint128 maxBorrowRate; // maximum borrow rate above this leveraging should not happen
    }

    Ratios internal _ratios;

    // last revenue exchange price (helps in calculating revenue)
    // Exchange price when revenue got updated last. It'll only increase overtime.
    uint256 internal _lastRevenueExchangePrice;

    uint256 internal _revenueFee; // 1000 = 10% (10% of user's profit)

    uint256 internal _revenue;

    uint256 internal _revenueEth;

    uint256 internal _withdrawalFee; // 10000 = 100%

    uint256 internal _idealExcessAmt; // 10 means 0.1% of total stEth/Eth supply (collateral + ideal balance)

    uint256 internal _swapFee; // 5 means 0.05%. This is the fee on leverage function which allows swap of stETH -> ETH

    uint256 internal _saveSlippage; // 1e16 means 1%

    uint256 internal _deleverageFee; // 1 means 0.01%
}