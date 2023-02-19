//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./events.sol";
import "../../../../infiniteProxy/IProxy.sol";

contract RebalancerModule is Events {
    using SafeERC20 for IERC20;

    /**
     * @dev Only rebalancer gaurd.
     */
    modifier onlyRebalancer() {
        require(
            _isRebalancer[msg.sender] ||
                IProxy(address(this)).getAdmin() == msg.sender,
            "only rebalancer"
        );
        _;
    }

    /**
     * @dev low gas function just to collect profit.
     * @notice Collected the profit & leave it in the DSA itself to optimize further on gas.
     */
    function collectProfit(
        bool isWeth, // either weth or steth
        uint256 withdrawAmt_,
        uint256 amt_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external nonReentrant onlyRebalancer {
        uint256 profits_ = getNewProfits();
        require(amt_ <= profits_, "amount-exceeds-profit");
        uint256 length_ = 1;
        if (withdrawAmt_ > 0) length_++;
        string[] memory targets_ = new string[](length_);
        bytes[] memory calldata_ = new bytes[](length_);
        address sellToken_ = isWeth
            ? address(wethContract)
            : address(stethContract);
        uint256 maxAmt_ = (getStethCollateralAmount() * _idealExcessAmt) /
            10000;
        if (withdrawAmt_ > 0) {
            if (isWeth) {
                targets_[0] = "AAVE-V2-A";
                calldata_[0] = abi.encodeWithSignature(
                    "borrow(address,uint256,uint256,uint256,uint256)",
                    address(wethContract),
                    withdrawAmt_,
                    2,
                    0,
                    0
                );
            } else {
                targets_[0] = "AAVE-V2-A";
                calldata_[0] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    address(stethContract),
                    withdrawAmt_,
                    0,
                    0
                );
            }
        }
        targets_[length_ - 1] = "1INCH-A";
        calldata_[length_ - 1] = abi.encodeWithSignature(
            "sell(address,address,uint256,uint256,bytes,uint256)",
            _token,
            sellToken_,
            amt_,
            unitAmt_,
            oneInchData_,
            0
        );
        _vaultDsa.cast(targets_, calldata_, address(this));
        if (withdrawAmt_ > 0)
            require(
                IERC20(sellToken_).balanceOf(address(_vaultDsa)) <= maxAmt_,
                "withdrawal-exceeds-max-limit"
            );

        emit collectProfitLog(isWeth, withdrawAmt_, amt_, unitAmt_);
    }

    struct RebalanceOneVariables {
        bool isOk;
        uint256 i;
        uint256 j;
        uint256 length;
        string[] targets;
        bytes[] calldatas;
        bool criticalIsOk;
        bool minIsOk;
    }

    /**
     * @dev Rebalancer function to leverage and rebalance the position.
     */
    function rebalanceOne(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] memory vaults_, // leverage using other vaults
        uint256[] memory amts_,
        uint256 leverageAmt_,
        uint256 swapAmt_, // 1inch's swap amount
        uint256 tokenSupplyAmt_,
        uint256 tokenWithdrawAmt_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external nonReentrant onlyRebalancer {
        if (leverageAmt_ < 1e14) leverageAmt_ = 0;
        if (tokenWithdrawAmt_ < _tokenMinLimit) tokenWithdrawAmt_ = 0;
        if (tokenSupplyAmt_ >= _tokenMinLimit)
            _token.safeTransfer(address(_vaultDsa), tokenSupplyAmt_);

        RebalanceOneVariables memory v_;
        v_.isOk = validateLeverageAmt(vaults_, amts_, leverageAmt_, swapAmt_);
        require(v_.isOk, "swap-amounts-are-not-proper");

        v_.length = amts_.length;
        uint256 tokenDsaBal_ = _token.balanceOf(address(_vaultDsa));
        if (tokenDsaBal_ >= _tokenMinLimit) v_.j += 1;
        if (leverageAmt_ > 0) v_.j += 1;
        if (flashAmt_ > 0) v_.j += 3;
        if (swapAmt_ > 0) v_.j += 2; // only deposit stEth in Aave if swap amt > 0.
        if (v_.length > 0) v_.j += v_.length;
        if (tokenWithdrawAmt_ > 0) v_.j += 2;

        v_.targets = new string[](v_.j);
        v_.calldatas = new bytes[](v_.j);
        if (tokenDsaBal_ >= _tokenMinLimit) {
            v_.targets[v_.i] = "AAVE-V2-A";
            v_.calldatas[v_.i] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                address(_token),
                type(uint256).max,
                0,
                0
            );
            v_.i++;
        }

        if (leverageAmt_ > 0) {
            if (flashAmt_ > 0) {
                v_.targets[v_.i] = "AAVE-V2-A";
                v_.calldatas[v_.i] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    flashTkn_,
                    flashAmt_,
                    0,
                    0
                );
                v_.i++;
            }
            v_.targets[v_.i] = "AAVE-V2-A";
            v_.calldatas[v_.i] = abi.encodeWithSignature(
                "borrow(address,uint256,uint256,uint256,uint256)",
                address(wethContract),
                leverageAmt_,
                2,
                0,
                0
            );
            v_.i++;
            // Doing swaps from different vaults using deleverage to reduce other vaults riskiness if needed.
            // It takes WETH from vault and gives astETH at 1:1
            for (uint256 k = 0; k < v_.length; k++) {
                v_.targets[v_.i] = "LITE-A"; // Instadapp Lite vaults connector
                v_.calldatas[v_.i] = abi.encodeWithSignature(
                    "deleverage(address,uint256,uint256,uint256)",
                    vaults_[k],
                    amts_[k],
                    0,
                    0
                );
                v_.i++;
            }
            if (swapAmt_ > 0) {
                require(unitAmt_ > (1e18 - 10), "invalid-unit-amt");
                v_.targets[v_.i] = "1INCH-A";
                v_.calldatas[v_.i] = abi.encodeWithSignature(
                    "sell(address,address,uint256,uint256,bytes,uint256)",
                    address(stethContract),
                    address(wethContract),
                    swapAmt_,
                    unitAmt_,
                    oneInchData_,
                    0
                );
                v_.targets[v_.i + 1] = "AAVE-V2-A";
                v_.calldatas[v_.i + 1] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    address(stethContract),
                    type(uint256).max,
                    0,
                    0
                );
                v_.i += 2;
            }
            if (flashAmt_ > 0) {
                v_.targets[v_.i] = "AAVE-V2-A";
                v_.calldatas[v_.i] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    flashTkn_,
                    flashAmt_,
                    0,
                    0
                );
                v_.targets[v_.i + 1] = "INSTAPOOL-C";
                v_.calldatas[v_.i + 1] = abi.encodeWithSignature(
                    "flashPayback(address,uint256,uint256,uint256)",
                    flashTkn_,
                    flashAmt_,
                    0,
                    0
                );
                v_.i += 2;
            }
        }
        if (tokenWithdrawAmt_ > 0) {
            v_.targets[v_.i] = "AAVE-V2-A";
            v_.calldatas[v_.i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                _token,
                tokenWithdrawAmt_,
                0,
                0
            );
            v_.targets[v_.i + 1] = "BASIC-A";
            v_.calldatas[v_.i + 1] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                _token,
                tokenWithdrawAmt_,
                address(this),
                0,
                0
            );
            v_.i += 2;
        }

        if (flashAmt_ > 0) {
            bytes memory encodedFlashData_ = abi.encode(
                v_.targets,
                v_.calldatas
            );

            string[] memory flashTarget_ = new string[](1);
            bytes[] memory flashCalldata_ = new bytes[](1);
            flashTarget_[0] = "INSTAPOOL-C";
            flashCalldata_[0] = abi.encodeWithSignature(
                "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                flashTkn_,
                flashAmt_,
                route_,
                encodedFlashData_,
                "0x"
            );
            _vaultDsa.cast(flashTarget_, flashCalldata_, address(this));
        } else {
            if (v_.j > 0)
                _vaultDsa.cast(v_.targets, v_.calldatas, address(this));
        }
        if (leverageAmt_ > 0)
            require(
                getWethBorrowRate() < _ratios.maxBorrowRate,
                "high-borrow-rate"
            );

        (v_.criticalIsOk, , v_.minIsOk, , ) = validateFinalPosition();
        // this will allow auth to take position to max safe limit. Only have to execute when there's a need to make other vaults safer.
        if (IProxy(address(this)).getAdmin() == msg.sender) {
            if (leverageAmt_ > 0)
                require(v_.criticalIsOk, "aave position risky");
        } else {
            if (leverageAmt_ > 0)
                require(v_.minIsOk, "position risky after leverage");
            if (tokenWithdrawAmt_ > 0)
                require(v_.criticalIsOk, "aave position risky");
        }

        emit rebalanceOneLog(
            flashTkn_,
            flashAmt_,
            route_,
            vaults_,
            amts_,
            leverageAmt_,
            swapAmt_,
            tokenSupplyAmt_,
            tokenWithdrawAmt_,
            unitAmt_
        );
    }

    /**
     * @dev Rebalancer function for saving. To be run in times of making position less risky or to fill up the withdraw amount for users to exit
     */
    function rebalanceTwo(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 saveAmt_,
        uint256 tokenSupplyAmt_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external nonReentrant onlyRebalancer {
        require(unitAmt_ > (1e18 - _saveSlippage), "excess-slippage"); // TODO: set variable to update slippage? Here's it's 0.1% slippage.
        uint256 i;
        uint256 j;

        if (tokenSupplyAmt_ >= _tokenMinLimit)
            _token.safeTransfer(address(_vaultDsa), tokenSupplyAmt_);
        uint256 tokenDsaBal_ = _token.balanceOf(address(_vaultDsa));
        if (tokenDsaBal_ >= _tokenMinLimit) j += 1;
        if (saveAmt_ > 0) j += 3;
        if (flashAmt_ > 0) j += 3;
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);

        if (tokenDsaBal_ >= _tokenMinLimit) {
            targets_[i] = "AAVE-V2-A";
            calldata_[i] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                address(_token),
                type(uint256).max,
                0,
                0
            );
            i++;
        }

        if (saveAmt_ > 0) {
            if (flashAmt_ > 0) {
                targets_[i] = "AAVE-V2-A";
                calldata_[i] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    flashTkn_,
                    flashAmt_,
                    0,
                    0
                );
                i++;
            }
            targets_[i] = "AAVE-V2-A";
            calldata_[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                address(stethContract),
                saveAmt_,
                0,
                0
            );
            targets_[i + 1] = "1INCH-A";
            calldata_[i + 1] = abi.encodeWithSignature(
                "sell(address,address,uint256,uint256,bytes,uint256)",
                address(wethContract),
                address(stethContract),
                saveAmt_,
                unitAmt_,
                oneInchData_,
                1 // setId 1
            );
            targets_[i + 2] = "AAVE-V2-A";
            calldata_[i + 2] = abi.encodeWithSignature(
                "payback(address,uint256,uint256,uint256,uint256)",
                address(wethContract),
                0,
                2,
                1, // getId 1 to get the payback amount
                0
            );
            if (flashAmt_ > 0) {
                targets_[i + 3] = "AAVE-V2-A";
                calldata_[i + 3] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    flashTkn_,
                    flashAmt_,
                    0,
                    0
                );
                targets_[i + 4] = "INSTAPOOL-C";
                calldata_[i + 4] = abi.encodeWithSignature(
                    "flashPayback(address,uint256,uint256,uint256)",
                    flashTkn_,
                    flashAmt_,
                    0,
                    0
                );
            }
        }

        if (flashAmt_ > 0) {
            bytes memory encodedFlashData_ = abi.encode(targets_, calldata_);

            string[] memory flashTarget_ = new string[](1);
            bytes[] memory flashCalldata_ = new bytes[](1);
            flashTarget_[0] = "INSTAPOOL-C";
            flashCalldata_[0] = abi.encodeWithSignature(
                "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                flashTkn_,
                flashAmt_,
                route_,
                encodedFlashData_,
                "0x"
            );
            _vaultDsa.cast(flashTarget_, flashCalldata_, address(this));
        } else {
            if (j > 0) _vaultDsa.cast(targets_, calldata_, address(this));
        }

        (, bool isOk_, , , ) = validateFinalPosition();
        require(isOk_, "position-risky");

        emit rebalanceTwoLog(flashTkn_, flashAmt_, route_, saveAmt_, unitAmt_);
    }
}