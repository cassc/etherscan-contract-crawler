//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./events.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AdminModule is Events {
    using SafeERC20 for IERC20;

    /**
     * @dev Reentrancy gaurd.
     */
    modifier nonReentrant() {
        require(status != 2, "ReentrancyGuard: reentrant call");
        status = 2;
        _;
        status = 1;
    }

    /**
     * @dev Only auth gaurd.
     */
    modifier onlyAuth() {
        require(auth == msg.sender, "only auth");
        _;
    }

    /**
     * @dev Update auth.
     * @param auth_ address of new auth.
     */
    function updateAuth(address auth_) external onlyAuth {
        auth = auth_;
        emit updateAuthLog(auth_);
    }

    /**
     * @dev Update if vault or not.
     * @param vaultAddr_ address of vault.
     * @param isVault_ true for adding the vault, false for removing.
     */
    function updateVault(address vaultAddr_, bool isVault_) external onlyAuth {
        isVault[vaultAddr_] = isVault_;
        emit updateVaultLog(vaultAddr_, isVault_);
    }

    /**
     * @dev Update premium.
     * @param premium_ new premium.
     */
    function updatePremium(uint256 premium_) external onlyAuth {
        premium = premium_;
        emit updatePremiumLog(premium_);
    }

    /**
     * @dev Update premium.
     * @param premiumEth_ new premium.
     */
    function updatePremiumEth(uint256 premiumEth_) external onlyAuth {
        premiumEth = premiumEth_;
        emit updatePremiumEthLog(premiumEth_);
    }

    /**
     * @dev Function to withdraw premium collected.
     * @param tokens_ list of token addresses.
     * @param amounts_ list of corresponding amounts.
     * @param to_ address to transfer the funds to.
     */
    function withdrawPremium(
        address[] memory tokens_,
        uint256[] memory amounts_,
        address to_
    ) external onlyAuth {
        uint256 length_ = tokens_.length;
        require(amounts_.length == length_, "lengths not same");
        for (uint256 i = 0; i < length_; i++) {
            if (amounts_[i] == type(uint256).max)
                amounts_[i] = IERC20(tokens_[i]).balanceOf(address(this));
            IERC20(tokens_[i]).safeTransfer(to_, amounts_[i]);
        }
        emit withdrawPremiumLog(tokens_, amounts_, to_);
    }
}

contract InstaVaultWrapperImplementation is AdminModule {
    using SafeERC20 for IERC20;

    function deleverageAndWithdraw(
        address vaultAddr_,
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_,
        uint256 unitAmt_,
        bytes memory swapData_,
        uint256 route_,
        bytes memory instaData_
    ) external nonReentrant {
        require(unitAmt_ != 0, "unitAmt_ cannot be zero");
        require(isVault[vaultAddr_], "invalid vault");
        (uint256 exchangePrice_, ) = IVault(vaultAddr_)
            .getCurrentExchangePrice();
        uint256 itokenAmt_;
        if (withdrawAmount_ == type(uint256).max) {
            itokenAmt_ = IERC20(vaultAddr_).balanceOf(msg.sender);
            withdrawAmount_ = (itokenAmt_ * exchangePrice_) / 1e18;
        } else {
            itokenAmt_ = (withdrawAmount_ * 1e18) / exchangePrice_;
        }
        IERC20(vaultAddr_).safeTransferFrom(
            msg.sender,
            address(this),
            itokenAmt_
        );
        address[] memory wethList_ = new address[](1);
        wethList_[0] = address(wethContract);
        uint256[] memory wethAmtList_ = new uint256[](1);
        wethAmtList_[0] = deleverageAmt_;
        bytes memory data_ = abi.encode(
            vaultAddr_,
            withdrawAmount_,
            to_,
            unitAmt_,
            swapData_
        );
        fla.flashLoan(wethList_, wethAmtList_, route_, data_, instaData_);
    }

    struct InstaVars {
        address vaultAddr;
        uint256 withdrawAmt;
        uint256 withdrawAmtAfterFee;
        address to;
        uint256 unitAmt;
        bytes swapData;
        uint256 withdrawalFee;
        uint256 iniWethBal;
        uint256 iniStethBal;
        uint256 finWethBal;
        uint256 finStethBal;
        uint256 iniEthBal;
        uint256 finEthBal;
        uint256 ethReceived;
        uint256 stethReceived;
        uint256 iniTokenBal;
        uint256 finTokenBal;
        bool success;
        uint256 wethCut;
        uint256 wethAmtReceivedAfterSwap;
        address tokenAddr;
        uint256 tokenDecimals;
        uint256 tokenPriceInBaseCurrency;
        uint256 ethPriceInBaseCurrency;
        uint256 tokenPriceInEth;
        uint256 tokenCut;
    }

    function executeOperation(
        address[] memory tokens_,
        uint256[] memory amounts_,
        uint256[] memory premiums_,
        address initiator_,
        bytes memory params_
    ) external returns (bool) {
        require(msg.sender == address(fla), "illegal-caller");
        require(initiator_ == address(this), "illegal-initiator");
        require(
            tokens_.length == 1 && tokens_[0] == address(wethContract),
            "invalid-params"
        );

        InstaVars memory v_;
        (v_.vaultAddr, v_.withdrawAmt, v_.to, v_.unitAmt, v_.swapData) = abi
            .decode(params_, (address, uint256, address, uint256, bytes));
        IVault vault_ = IVault(v_.vaultAddr);
        v_.withdrawalFee = vault_.withdrawalFee();
        v_.withdrawAmtAfterFee =
            v_.withdrawAmt -
            ((v_.withdrawAmt * v_.withdrawalFee) / 1e4);
        wethContract.safeApprove(v_.vaultAddr, amounts_[0]);
        if (v_.vaultAddr == ethVaultAddr) {
            v_.iniEthBal = address(this).balance;
            v_.iniStethBal = stethContract.balanceOf(address(this));
            vault_.deleverageAndWithdraw(
                amounts_[0],
                v_.withdrawAmt,
                address(this)
            );
            v_.finEthBal = address(this).balance;
            v_.finStethBal = stethContract.balanceOf(address(this));
            v_.ethReceived = v_.finEthBal - v_.iniEthBal;
            v_.stethReceived = v_.finStethBal - amounts_[0] - v_.iniStethBal;
            require(
                v_.ethReceived + v_.stethReceived + 1e9 >=
                    v_.withdrawAmtAfterFee, // Adding small margin for any potential decimal error
                "something-went-wrong"
            );

            v_.iniWethBal = wethContract.balanceOf(address(this));
            stethContract.safeApprove(oneInchAddr, amounts_[0]);
            Address.functionCall(oneInchAddr, v_.swapData, "1Inch-swap-failed");
            v_.finWethBal = wethContract.balanceOf(address(this));
            v_.wethAmtReceivedAfterSwap = v_.finWethBal - v_.iniWethBal;
            require(
                v_.wethAmtReceivedAfterSwap != 0,
                "wethAmtReceivedAfterSwap cannot be zero"
            );
            require(
                v_.wethAmtReceivedAfterSwap >=
                    (amounts_[0] * v_.unitAmt) / 1e18,
                "Too-much-slippage"
            );

            v_.wethCut =
                amounts_[0] +
                premiums_[0] -
                v_.wethAmtReceivedAfterSwap;
            v_.wethCut = v_.wethCut + ((v_.wethCut * premiumEth) / 10000);
            if (v_.wethCut < v_.ethReceived) {
                Address.sendValue(payable(v_.to), v_.ethReceived - v_.wethCut);
                stethContract.safeTransfer(v_.to, v_.stethReceived);
            } else {
                v_.wethCut -= v_.ethReceived;
                stethContract.safeTransfer(
                    v_.to,
                    v_.stethReceived - v_.wethCut
                );
            }
        } else {
            v_.tokenAddr = vault_.token();
            v_.tokenDecimals = vault_.decimals();
            v_.tokenPriceInBaseCurrency = aaveOracle.getAssetPrice(
                v_.tokenAddr
            );
            v_.ethPriceInBaseCurrency = aaveOracle.getAssetPrice(
                address(wethContract)
            );
            v_.tokenPriceInEth =
                (v_.tokenPriceInBaseCurrency * 1e18) /
                v_.ethPriceInBaseCurrency;

            v_.iniTokenBal = IERC20(v_.tokenAddr).balanceOf(address(this));
            v_.iniStethBal = stethContract.balanceOf(address(this));
            vault_.deleverageAndWithdraw(
                amounts_[0],
                v_.withdrawAmt,
                address(this)
            );
            v_.finTokenBal = IERC20(v_.tokenAddr).balanceOf(address(this));
            v_.finStethBal = stethContract.balanceOf(address(this));
            require(
                v_.finTokenBal - v_.iniTokenBal >=
                    ((v_.withdrawAmtAfterFee * 99999999) / 100000000), // Adding small margin for any potential decimal error
                "something-went-wrong"
            );
            require(
                v_.finStethBal - v_.iniStethBal + 1e9 >= amounts_[0], // Adding small margin for any potential decimal error
                "something-went-wrong"
            );

            v_.iniWethBal = wethContract.balanceOf(address(this));
            stethContract.safeApprove(oneInchAddr, amounts_[0]);
            Address.functionCall(oneInchAddr, v_.swapData, "1Inch-swap-failed");
            v_.finWethBal = wethContract.balanceOf(address(this));
            v_.wethAmtReceivedAfterSwap = v_.finWethBal - v_.iniWethBal;
            require(
                v_.wethAmtReceivedAfterSwap != 0,
                "wethAmtReceivedAfterSwap cannot be zero"
            );
            require(
                v_.wethAmtReceivedAfterSwap >=
                    (amounts_[0] * v_.unitAmt) / 1e18,
                "Too-much-slippage"
            );
            v_.wethCut =
                amounts_[0] +
                premiums_[0] -
                v_.wethAmtReceivedAfterSwap;
            v_.wethCut = v_.wethCut + ((v_.wethCut * premium) / 10000);
            v_.tokenCut =
                (v_.wethCut * (10**v_.tokenDecimals)) /
                (v_.tokenPriceInEth);
            IERC20(v_.tokenAddr).safeTransfer(
                v_.to,
                v_.withdrawAmtAfterFee - v_.tokenCut
            );
        }
        wethContract.safeTransfer(address(fla), amounts_[0] + premiums_[0]);
        return true;
    }

    // function initialize(address auth_, uint256 premium_) external {
    //     require(status == 0, "only once");
    //     auth = auth_;
    //     premium = premium_;
    //     status = 1;
    // }

    receive() external payable {}
}