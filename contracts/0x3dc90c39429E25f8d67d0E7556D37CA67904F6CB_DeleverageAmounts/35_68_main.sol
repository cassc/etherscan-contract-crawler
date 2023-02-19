//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./events.sol";
import "../../../../infiniteProxy/IProxy.sol";

contract AdminModule is Events {
    using SafeERC20 for IERC20;

    /**
     * @dev Only auth gaurd.
     */
    modifier onlyAuth() {
        require(IProxy(address(this)).getAdmin() == msg.sender, "only auth");
        _;
    }

    /**
     * @dev Update rebalancer.
     * @param rebalancer_ address of rebalancer.
     * @param isRebalancer_ true for setting the rebalancer, false for removing.
     */
    function updateRebalancer(address rebalancer_, bool isRebalancer_)
        external
        onlyAuth
    {
        _isRebalancer[rebalancer_] = isRebalancer_;
        emit updateRebalancerLog(rebalancer_, isRebalancer_);
    }

    /**
     * @dev Update all fees.
     * @param revenueFee_ new revenue fee.
     * @param withdrawalFee_ new withdrawal fee.
     * @param swapFee_ new swap fee or leverage fee.
     * @param deleverageFee_ new deleverage fee.
     */
    function updateFees(
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 swapFee_,
        uint256 deleverageFee_
    ) external onlyAuth {
        require(revenueFee_ / 10000 == 0, "fees-not-valid");
        require(withdrawalFee_ / 10000 == 0, "fees-not-valid");
        require(swapFee_ / 10000 == 0, "fees-not-valid");
        require(deleverageFee_ / 10000 == 0, "fees-not-valid");
        _revenueFee = revenueFee_;
        _withdrawalFee = withdrawalFee_;
        _swapFee = swapFee_;
        _deleverageFee = deleverageFee_;
        emit updateFeesLog(
            revenueFee_,
            withdrawalFee_,
            swapFee_,
            deleverageFee_
        );
    }

    /**
     * @dev Update ratios.
     * @param ratios_ new ratios.
     */
    function updateRatios(uint16[] memory ratios_) external onlyAuth {
        _ratios = Ratios(
            ratios_[0],
            ratios_[1],
            ratios_[2],
            ratios_[3],
            ratios_[4],
            uint128(ratios_[5]) * 1e23
        );
        emit updateRatiosLog(
            ratios_[0],
            ratios_[1],
            ratios_[2],
            ratios_[3],
            ratios_[4],
            uint128(ratios_[5]) * 1e23
        );
    }

    /**
     * @dev Change status.
     * @param status_ new status, function to pause all functionality of the contract, status = 2 -> pause, status = 1 -> resume.
     */
    function changeStatus(uint256 status_) external onlyAuth {
        _status = status_;
        emit changeStatusLog(status_);
    }

    /**
     * @dev Function to collect token revenue.
     * @param amount_ amount to claim
     * @param to_ address to send the claimed revenue to
     */
    function collectRevenue(uint256 amount_, address to_) external onlyAuth {
        require(amount_ != 0, "amount-cannot-be-zero");
        if (amount_ == type(uint256).max) amount_ = _revenue;
        require(amount_ <= _revenue, "not-enough-revenue");
        _revenue -= amount_;
        uint256 tokenVaultBal_ = _token.balanceOf(address(this));
        require(tokenVaultBal_ >= amount_, "not-enough-amount-inside-vault");
        _token.safeTransfer(to_, amount_);
        emit collectRevenueLog(amount_, to_);
    }

    /**
     * @dev Function to collect eth revenue.
     * @param amount_ amount to claim
     * @param to_ address to send the claimed revenue to
     */
    function collectRevenueEth(uint256 amount_, address to_) external onlyAuth {
        require(amount_ != 0, "amount-cannot-be-zero");
        if (amount_ == type(uint256).max) amount_ = _revenueEth;
        require(amount_ <= _revenueEth, "not-enough-revenue");
        _revenueEth -= amount_;
        string[] memory targets_ = new string[](2);
        bytes[] memory calldata_ = new bytes[](2);
        targets_[0] = "AAVE-V2-A";
        calldata_[0] = abi.encodeWithSignature(
            "withdraw(address,uint256,uint256,uint256)",
            address(stethContract),
            amount_,
            0,
            0
        );
        targets_[1] = "BASIC-A";
        calldata_[1] = abi.encodeWithSignature(
            "withdraw(address,uint256,address,uint256,uint256)",
            address(stethContract),
            amount_,
            to_,
            0,
            0
        );
        _vaultDsa.cast(targets_, calldata_, address(this));
        (bool isOk_, , , , ) = validateFinalPosition();
        require(isOk_, "position-risky");
        emit collectRevenueEthLog(amount_, amount_, 0, to_);
    }

    /**
     * @dev function to initialize variables
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address rebalancer_,
        address token_,
        address atoken_,
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 idealExcessAmt_,
        uint16[] memory ratios_,
        uint256 swapFee_,
        uint256 saveSlippage_,
        uint256 deleverageFee_
    ) external initializer onlyAuth {
        address vaultDsaAddr_ = instaIndex.build(
            address(this),
            2,
            address(this)
        );
        _vaultDsa = IDSA(vaultDsaAddr_);
        __ERC20_init(name_, symbol_);
        _isRebalancer[rebalancer_] = true;
        _token = IERC20(token_);
        _tokenDecimals = uint8(TokenInterface(token_).decimals());
        _atoken = IERC20(atoken_);
        _revenueFee = revenueFee_;
        _lastRevenueExchangePrice = 1e18;
        _withdrawalFee = withdrawalFee_;
        _idealExcessAmt = idealExcessAmt_;
        // sending borrow rate in 4 decimals eg:- 300 meaning 3% and converting into 27 decimals eg:- 3 * 1e25
        _ratios = Ratios(
            ratios_[0],
            ratios_[1],
            ratios_[2],
            ratios_[3],
            ratios_[4],
            uint128(ratios_[5]) * 1e23
        );
        _tokenMinLimit = _tokenDecimals > 17 ? 1e14 : _tokenDecimals > 11
            ? 1e11
            : _tokenDecimals > 5
            ? 1e4
            : 1;
        _swapFee = swapFee_;
        _saveSlippage = saveSlippage_;
        _deleverageFee = deleverageFee_;
    }
}