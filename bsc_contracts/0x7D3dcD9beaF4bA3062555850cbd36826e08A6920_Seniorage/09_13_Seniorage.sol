// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/ISnacksBase.sol";
import "./interfaces/ILunchBox.sol";
import "./interfaces/IZoinks.sol";

contract Seniorage is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private constant BASE_PERCENT = 10000;
    uint256 private constant BDM_WALLET_PERCENT = 500;
    uint256 private constant CRM_WALLET_PERCENT = 500;
    uint256 private constant DEV_MANAGER_WALLET_PERCENT = 500;
    uint256 private constant MARKETING_MANAGER_WALLET_PERCENT = 500;
    uint256 private constant DEV_WALLET_PERCENT = 1000;
    uint256 private constant SITUATIONAL_FUND_WALLET_PERCENT = 1500;
    uint256 private constant MARKETING_FUND_WALLET_PERCENT = 2000;
    uint256 private constant SWAP_ON_BTC_PERCENT = 400;
    uint256 private constant SWAP_ON_ETH_PERCENT = 400;
    uint256 private constant BTC_SNACKS_PULSE_PERCENT = 5000;
    uint256 private constant ETH_SNACKS_PULSE_PERCENT = 5000;
    uint256 private constant ADD_LIQUIDITY_PERCENT = 2500;
    uint256 private constant SWAP_ON_ZOINKS_PERCENT = 200;
    uint256 private constant LUNCH_BOX_PERCENT = 4500;
    uint256 private constant MULTISIG_WALLET_PERCENT = 2000;
    
    address public immutable busd;
    address public immutable router;
    address public cakeLP;
    address public zoinks;
    address public btc;
    address public eth;
    address public snacks;
    address public btcSnacks;
    address public ethSnacks;
    address public authority;
    address public pulse;
    address public lunchBox;
    address public bdmWallet;
    address public crmWallet;
    address public devManagerWallet;
    address public marketingManagerWallet;
    address public devWallet;
    address public marketingFundWallet;
    address public situationalFundWallet;
    address public multisigWallet;
    uint256 public busdAmountStored;
    uint256 public zoinksAmountStored;
    uint256 public btcAmountStored;
    uint256 public ethAmountStored;

    EnumerableSet.AddressSet private _nonBusdCurrencies;

    event PulseUpdated(address indexed pulse);
    event LunchBoxUpdated(address indexed lunchBox);
    event AuthorityUpdated(address indexed authority);

    modifier onlyAuthority {
        require(
            msg.sender == authority,
            "Seniorage: caller is not authorised"
        );
        _;
    }
    
    /**
    * @param busd_ Binance-Peg BUSD token address.
    * @param router_ Router contract address (from PancakeSwap DEX).
    */
    constructor(
        address busd_,
        address router_
    ) {
        busd = busd_;
        router = router_;
        IERC20(busd_).approve(router_, type(uint256).max);
    }
    
    /**
    * @notice Configures currency addresses.
    * @dev Could be called by the owner in case of resetting addresses.
    * @param cakeLP_ Pancake LPs token address.
    * @param zoinks_ Zoinks token address.
    * @param btc_ Binance-Peg BTCB token address.
    * @param eth_ Binance-Peg Ethereum token address.
    * @param snacks_ Snacks token address.
    * @param btcSnacks_ BtcSnacks token address.
    * @param ethSnacks_ EthSnacks token address.
    */
    function configureCurrencies(
        address cakeLP_,
        address zoinks_,
        address btc_,
        address eth_,
        address snacks_,
        address btcSnacks_,
        address ethSnacks_
    )
        external
        onlyOwner
    {
        cakeLP = cakeLP_;
        zoinks = zoinks_;
        btc = btc_;
        eth = eth_;
        snacks = snacks_;
        btcSnacks = btcSnacks_;
        ethSnacks = ethSnacks_;
        for (uint256 i = 0; i < _nonBusdCurrencies.length(); i++) {
            address currency = _nonBusdCurrencies.at(i);
            _nonBusdCurrencies.remove(currency);
        }
        _nonBusdCurrencies.add(zoinks_);
        _nonBusdCurrencies.add(btc_);
        _nonBusdCurrencies.add(eth_);
        _nonBusdCurrencies.add(snacks_);
        _nonBusdCurrencies.add(btcSnacks_);
        _nonBusdCurrencies.add(ethSnacks_);
        if (IERC20(zoinks_).allowance(address(this), router) == 0) {
            IERC20(zoinks_).approve(router, type(uint256).max);
        }
        if (IERC20(zoinks_).allowance(address(this), snacks_) == 0) {
            IERC20(zoinks_).approve(snacks_, type(uint256).max);
        }
        if (IERC20(busd).allowance(address(this), zoinks_) == 0) {
            IERC20(busd).approve(zoinks_, type(uint256).max);
        }
        if (IERC20(btc_).allowance(address(this), btcSnacks_) == 0) {
            IERC20(btc_).approve(btcSnacks_, type(uint256).max);
        }
        if (IERC20(eth_).allowance(address(this), ethSnacks_) == 0) {
            IERC20(eth_).approve(ethSnacks_, type(uint256).max);
        }
    }
    
    /**
    * @notice Configures wallet addresses.
    * @dev Could be called by the owner in case of resetting addresses.
    * @param bdmWallet_ Business development manager wallet.
    * @param crmWallet_ Customer relationship manager wallet.
    * @param devManagerWallet_ Development manager wallet.
    * @param marketingManagerWallet_ Marketing manager wallet.
    * @param devWallet_ Developers wallet.
    * @param marketingFundWallet_ Marketing fund wallet.
    * @param situationalFundWallet_ Situational fund wallet.
    * @param multisigWallet_ Multisignature wallet.
    */
    function configureWallets(
        address bdmWallet_,
        address crmWallet_,
        address devManagerWallet_,
        address marketingManagerWallet_,
        address devWallet_,
        address marketingFundWallet_,
        address situationalFundWallet_,
        address multisigWallet_
    )
        external
        onlyOwner
    {
        bdmWallet = bdmWallet_;
        crmWallet = crmWallet_;
        devManagerWallet = devManagerWallet_;
        marketingManagerWallet = marketingManagerWallet_;
        devWallet = devWallet_;
        marketingFundWallet = marketingFundWallet_;
        situationalFundWallet = situationalFundWallet_;
        multisigWallet = multisigWallet_;
    }

    /**
    * @notice Triggers stopped state.
    * @dev Could be called by the owner in case of resetting addresses.
    */
    function pause() external onlyOwner {
        _pause();
    }

    /**
    * @notice Triggers stopped state.
    * @dev Could be called by the owner in case of resetting addresses.
    */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
    * @notice Sets the Pulse contract address.
    * @dev Could be called by the owner in case of address reset.
    * @param pulse_ Pulse contract address.
    */
    function setPulse(address pulse_) external onlyOwner {
        pulse = pulse_;
        emit PulseUpdated(pulse_);
    }
    
    /**
    * @notice Sets the LunchBox contract address.
    * @dev Could be called by the owner in case of address reset.
    * @param lunchBox_ LunchBox contract address.
    */
    function setLunchBox(address lunchBox_) external onlyOwner {
        lunchBox = lunchBox_;
        IERC20(busd).approve(lunchBox_, type(uint256).max);
        IERC20(zoinks).approve(lunchBox_, type(uint256).max);
        IERC20(btc).approve(lunchBox_, type(uint256).max);
        IERC20(eth).approve(lunchBox_, type(uint256).max);
        IERC20(snacks).approve(lunchBox_, type(uint256).max);
        IERC20(btcSnacks).approve(lunchBox_, type(uint256).max);
        IERC20(ethSnacks).approve(lunchBox_, type(uint256).max);
        emit LunchBoxUpdated(lunchBox_);
    }
    
    /**
    * @notice Sets the authorised address.
    * @dev Could be called by the owner in case of address reset.
    * @param authority_ Authorised address.
    */
    function setAuthority(address authority_) external onlyOwner {
        authority = authority_;
        emit AuthorityUpdated(authority_);
    }

    /**
    * @notice Distributes all currencies except the Binance-Peg BUSD token.
    * @dev Called by the authorised address once every 12 hours.
    * @param zoinksBusdAmountOutMin_ The minimal amount of tokens (slippage tolerance) for 
    * Zoinks token to Binance-Peg BUSD token swap.
    * @param btcBusdAmountOutMin_ The minimal amount of tokens (slippage tolerance) for 
    * Binance-Peg BTCB token to Binance-Peg BUSD token swap.
    * @param ethBusdAmountOutMin_ The minimal amount of tokens (slippage tolerance) for 
    * Binance-Peg Ethereum token to Binance-Peg BUSD token swap.
    */
    function distributeNonBusdCurrencies(
        uint256 zoinksBusdAmountOutMin_,
        uint256 btcBusdAmountOutMin_,
        uint256 ethBusdAmountOutMin_
    ) 
        external 
        whenNotPaused 
        onlyAuthority 
    {
        for (uint256 i = 0; i < _nonBusdCurrencies.length(); i++) {
            address currency = _nonBusdCurrencies.at(i);
            uint256 balance;
            if (currency == zoinks) {
                balance = IERC20(currency).balanceOf(address(this)) - zoinksAmountStored;
            } else if (currency == btc) {
                balance = IERC20(currency).balanceOf(address(this)) - btcAmountStored;
            } else if (currency == eth) {
                balance = IERC20(currency).balanceOf(address(this)) - ethAmountStored;
            } else {
                balance = IERC20(currency).balanceOf(address(this));
            }
            if (balance != 0) {
                IERC20(currency).safeTransfer(
                    bdmWallet,
                    balance * BDM_WALLET_PERCENT / BASE_PERCENT
                );
                IERC20(currency).safeTransfer(
                    crmWallet,
                    balance * CRM_WALLET_PERCENT / BASE_PERCENT
                );
                IERC20(currency).safeTransfer(
                    devManagerWallet,
                    balance * DEV_MANAGER_WALLET_PERCENT / BASE_PERCENT
                );
                IERC20(currency).safeTransfer(
                    marketingManagerWallet,
                    balance * MARKETING_MANAGER_WALLET_PERCENT / BASE_PERCENT
                );
                IERC20(currency).safeTransfer(
                    devWallet,
                    balance * DEV_WALLET_PERCENT / BASE_PERCENT
                );
                IERC20(currency).safeTransfer(
                    marketingFundWallet,
                    balance * MARKETING_FUND_WALLET_PERCENT / BASE_PERCENT
                );
                IERC20(currency).safeTransfer(
                    situationalFundWallet,
                    balance * SITUATIONAL_FUND_WALLET_PERCENT / BASE_PERCENT
                );
            }
        }
        _distributeNonBusdCurrenciesToLunchBox(
            zoinksBusdAmountOutMin_,
            btcBusdAmountOutMin_,
            ethBusdAmountOutMin_
        );
    }

    /**
    * @notice Distributes the Binance-Peg BUSD token.
    * @dev Called by the authorised address once every 12 hours.
    * @param btcAmountOutMin_ Minimum expected amount of Binance-Peg BTCB token 
    * to be received after the exchange 5.5% of the total balance of Binance-Peg BUSD token.
    * @param ethAmountOutMin_ Minimum expected amount of Binance-Peg Ethereum token 
    * to be received after the exchange 5.5% of the total balance of Binance-Peg BUSD token.
    * @param zoinksAmountOutMin_ Minimum expected amount of Zoinks token 
    * to be received after the exchange 3% of the total balance of Binance-Peg BUSD token.
    */
    function distributeBusd(
        uint256 btcAmountOutMin_,
        uint256 ethAmountOutMin_,
        uint256 zoinksAmountOutMin_
    )
        external
        whenNotPaused
        onlyAuthority
    {
        uint256 balance = IERC20(busd).balanceOf(address(this)) - busdAmountStored;
        if (balance != 0) {
            address[] memory path = new address[](2);
            path[0] = busd;
            path[1] = btc;
            uint256 busdAmountToSwapOnBtc = balance * SWAP_ON_BTC_PERCENT / BASE_PERCENT;
            uint256[] memory amounts = IRouter(router).swapExactTokensForTokens(
                busdAmountToSwapOnBtc,
                btcAmountOutMin_,
                path,
                address(this),
                block.timestamp
            );
            address btcSnacksAddress = btcSnacks;
            if (ISnacksBase(btcSnacksAddress).sufficientPayTokenAmountOnMint(amounts[1] + btcAmountStored)) {
                uint256 btcSnacksAmount = ISnacksBase(btcSnacksAddress).mintWithPayTokenAmount(amounts[1] + btcAmountStored);
                IERC20(btcSnacksAddress).safeTransfer(
                    pulse,
                    btcSnacksAmount * BTC_SNACKS_PULSE_PERCENT / BASE_PERCENT
                );
                if (btcAmountStored != 0) {
                    btcAmountStored = 0;
                }
            } else {
                btcAmountStored += amounts[1];
            }
            path[1] = eth;
            uint256 busdAmountToSwapOnEth = balance * SWAP_ON_ETH_PERCENT / BASE_PERCENT;
            amounts = IRouter(router).swapExactTokensForTokens(
                busdAmountToSwapOnEth,
                ethAmountOutMin_,
                path,
                address(this),
                block.timestamp
            );
            address ethSnacksAddress = ethSnacks;
            if (ISnacksBase(ethSnacksAddress).sufficientPayTokenAmountOnMint(amounts[1] + ethAmountStored)) {
                uint256 ethSnacksAmount = ISnacksBase(ethSnacksAddress).mintWithPayTokenAmount(amounts[1] + ethAmountStored);
                IERC20(ethSnacksAddress).safeTransfer(
                    pulse,
                    ethSnacksAmount * ETH_SNACKS_PULSE_PERCENT / BASE_PERCENT
                );
                if (ethAmountStored != 0) {
                    ethAmountStored = 0;
                }
            } else {
                ethAmountStored += amounts[1];
            }
            path[1] = zoinks;
            uint256 busdAmountToSwapOnZoinks = balance * SWAP_ON_ZOINKS_PERCENT / BASE_PERCENT;
            amounts = IRouter(router).swapExactTokensForTokens(
                busdAmountToSwapOnZoinks,
                zoinksAmountOutMin_,
                path,
                address(this),
                block.timestamp
            );
            address snacksAddress = snacks;
            if (ISnacksBase(snacksAddress).sufficientPayTokenAmountOnMint(amounts[1] + zoinksAmountStored)) {
                uint256 snacksAmount = ISnacksBase(snacksAddress).mintWithPayTokenAmount(amounts[1] + zoinksAmountStored);
                IERC20(snacksAddress).safeTransfer(pulse, snacksAmount);
                if (zoinksAmountStored != 0) {
                    zoinksAmountStored = 0;
                }
            } else {
                zoinksAmountStored += amounts[1];
            }
            busdAmountStored += balance * ADD_LIQUIDITY_PERCENT / BASE_PERCENT;
            ILunchBox(lunchBox).stakeForSeniorage(balance * LUNCH_BOX_PERCENT / BASE_PERCENT);
            IERC20(busd).safeTransfer(multisigWallet, balance * MULTISIG_WALLET_PERCENT / BASE_PERCENT);
        }
    }

    /**
    * @notice Provides liquidity with the proper reserve ratio.
    * @dev Called by the authorised address once every 12 hours.
    * @param addLiquidityBusdAmountMin_ Minimum expected amount of Binance-Peg BUSD token 
    * to add liquidity after the addition 50% of the stored amount of Binance-Peg BUSD token.
    * @param addLiquidityZoinksAmountMin_ Minimum expected amount of Zoinks token 
    * to add liquidity in the amount received after the mint of 50% of the stored amount 
    * of Binance-Peg BUSD token.
    */
    function provideLiquidity(
        uint256 addLiquidityBusdAmountMin_,
        uint256 addLiquidityZoinksAmountMin_
    )
        external
        whenNotPaused
        onlyAuthority
    {
        if (busdAmountStored != 0) {
            uint256 addLiquidityAmount = busdAmountStored / 2;
            IZoinks(zoinks).mint(addLiquidityAmount);
            (, , uint256 liquidity) = IRouter(router).addLiquidity(
                busd,
                zoinks,
                addLiquidityAmount,
                addLiquidityAmount,
                addLiquidityBusdAmountMin_,
                addLiquidityZoinksAmountMin_,
                address(this),
                block.timestamp
            );
            IERC20(cakeLP).safeTransfer(pulse, liquidity);
            busdAmountStored = 0;
        }
    }

    /**
    * @notice Deposits remaining balance of all currencies 
    * except the Binance-Peg BUSD token in the LunchBox contract.
    * @dev Called inside `distributeNonBusdCurrencies()` function.
    */
    function _distributeNonBusdCurrenciesToLunchBox(
        uint256 zoinksBusdAmountOutMin_,
        uint256 btcBusdAmountOutMin_,
        uint256 ethBusdAmountOutMin_
    ) 
        private 
    {
        uint256 zoinksBalance = IERC20(zoinks).balanceOf(address(this)) - zoinksAmountStored;
        uint256 btcBalance = IERC20(btc).balanceOf(address(this)) - btcAmountStored;
        uint256 ethBalance = IERC20(eth).balanceOf(address(this)) - ethAmountStored;
        if (
            zoinksBalance != 0 ||
            btcBalance != 0 ||
            ethBalance != 0 ||
            IERC20(snacks).balanceOf(address(this)) != 0 ||
            IERC20(btcSnacks).balanceOf(address(this)) != 0 ||
            IERC20(ethSnacks).balanceOf(address(this)) != 0
        ) {
            ILunchBox(lunchBox).stakeForSeniorage(
                zoinksBalance,
                btcBalance,
                ethBalance,
                IERC20(snacks).balanceOf(address(this)),
                IERC20(btcSnacks).balanceOf(address(this)),
                IERC20(ethSnacks).balanceOf(address(this)),
                zoinksBusdAmountOutMin_,
                btcBusdAmountOutMin_,
                ethBusdAmountOutMin_
            );
        }
    }
}