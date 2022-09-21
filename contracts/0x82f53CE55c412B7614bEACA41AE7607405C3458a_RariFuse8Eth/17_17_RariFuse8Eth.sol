// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../Strategy.sol";
import "../../interfaces/compound/ICompound.sol";
import "vesper-pools/contracts/interfaces/token/IToken.sol";
import "hardhat/console.sol";

/// @title This strategy is specially design to deal after rari hack.
/// There is discussion going in TRIBE/FEI/RARI community that reimbursement of all affected user may be done
/// by atomic swap hence EOA need to get access of cTokens . This strategy allow governor to take cToken out from strategy and get reimbursement done.
contract RariFuse8Eth is Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.0.0";

    CToken internal cToken;

    // solhint-disable-next-line var-name-mixedcase
    Comptroller public immutable COMPTROLLER;
    address public rewardToken;

    uint256 internal constant fuseId = 8;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(
        address _pool,
        address _swapper,
        address _comptroller,
        address _rewardToken,
        address _receiptToken,
        string memory _name
    ) Strategy(_pool, _swapper, _receiptToken) {
        require(_receiptToken != address(0), "cToken-address-is-zero");
        cToken = CToken(_receiptToken);
        NAME = _name;

        // Either can be address(0), for example in Rari Strategy
        COMPTROLLER = Comptroller(_comptroller);
        rewardToken = _rewardToken;
    }

    /// @dev Only receive ETH from either cToken or WETH
    receive() external payable {
        require(msg.sender == address(cToken) || msg.sender == WETH, "not-allowed-to-send-ether");
    }

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _token == address(cToken);
    }

    function tvl() external view override returns (uint256) {
        return
            ((cToken.balanceOf(address(this)) * cToken.exchangeRateStored()) / 1e18) +
            collateralToken.balanceOf(address(this));
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(cToken), _amount);
    }

    //solhint-disable-next-line no-empty-blocks
    function _beforeMigration(address _newStrategy) internal virtual override {}

    /**
     * @dev Generate report for pools accounting and also send profit and any payback to pool.
     * To deal with rariFuse#8 hack and reimbursement, rebalance do not deposit collateral to rari, only try to withdraw if available.
     *  payback excessDebt to pool if collateral available.
     */
    function _rebalance()
        internal
        virtual
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _collateralHere + cToken.balanceOfUnderlying(address(this));
        if (_totalCollateral > _totalDebt) {
            _profit = _totalCollateral - _totalDebt;
        }

        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_profitAndExcessDebt > _collateralHere) {
            _withdrawHere(_profitAndExcessDebt - _collateralHere);
            _collateralHere = collateralToken.balanceOf(address(this));
        }

        // Make sure _collateralHere >= _payback + profit. set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;
        IVesperPool(pool).reportEarning(_profit, 0, _payback);
    }

    /**
     * @notice To deal with rariFuse#8 reimbursement.
     * @param _token token address to sweep
     */
    function sweepAnyToken(address _token, address _receiver) external onlyGovernor {
        require(_receiver != address(0), "_receiver-is-zero");
        if (_token == ETH) {
            Address.sendValue(payable(_receiver), address(this).balance);
        } else {
            uint256 _amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    /// @dev Withdraw collateral here. Do not transfer to pool
    function _withdrawHere(uint256 _amount) internal override {
        // If _amount is very small and equivalent to 0 cToken then skip withdraw.
        uint256 _expectedCToken = (_amount * 1e18) / cToken.exchangeRateStored();
        if (_expectedCToken > 0) {
            // Get minimum of _amount and _available collateral and _availableLiquidity
            uint256 _withdrawAmount = Math.min(
                _amount,
                Math.min(cToken.balanceOfUnderlying(address(this)), cToken.getCash())
            );
            require(cToken.redeemUnderlying(_withdrawAmount) == 0, "withdraw-from-compound-failed");
            TokenLike(WETH).deposit{value: address(this).balance}();
        }
    }
}