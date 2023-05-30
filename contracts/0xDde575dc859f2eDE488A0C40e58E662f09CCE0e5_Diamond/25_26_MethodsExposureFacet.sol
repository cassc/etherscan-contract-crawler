// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LibDiamond.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

contract MethodsExposureFacet is IDiamondCut, IDiamondLoupe, IERC20Upgradeable {
    // ==================== IDiamondLoupe & IDiamondCut ==================== //

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external {
      LibDiamond.enforceIsContractOwner();
      LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }

    /// These functions are expected to be called frequently by tools.

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        facets_ = new Facet[](0);
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        facetFunctionSelectors_ = new bytes4[](0);
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        override
        returns (address[] memory facetAddresses_)
    {
        facetAddresses_ = new address[](0);
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        override
        returns (address facetAddress_)
    {
        return address(0);
    }

    // ==================== ERC20 ==================== //

    function name() public view virtual returns (string memory) {
        return "";
    }

    function symbol() public view virtual returns (string memory) {
        return "";
    }

    function totalSupply() external view returns (uint256) {
        return 0;
    }

    function balanceOf(address account) external view returns (uint256) {
        return 0;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return false;
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return 0;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return false;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        return false;
    }

    function setLiquidityWallet(address _liquidityWallet) external {}

    function setLiquidityFee(uint256 _liquidityBuyFee) external {}

    function setRewardFee(uint256 _rewardBuyFee) external {}

    function setIsLpPool(address _pairAddress, bool _isLp) external {}

    function setNumTokensToSwap(uint256 _amount) external {}

    function setDefaultRouter(address _router) external {}

    function setSwapRouter(address _router, bool _isRouter) external {}

    function setManualClaim(bool _manualClaim) external {}

    function setMaxTokenPerWallet(uint256 _maxTokenPerWallet) external {}

    // ==================== Views ==================== //

    function implementation() public view returns (address) {
        return address(0);
    }

    function liquidityWallet() external view returns (address) {
        return address(0);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return false;
    }

    function isExcludedMaxWallet(address account) external view returns (bool) {
        return false;
    }

    function isExcludedFromRewards(address account) public view returns (bool) {
        return false;
    }

    function isSwapRouter(address routerAddress) external view returns (bool) {
        return false;
    }

    function isLpPool(address pairAddress) external view returns (bool) {
        return false;
    }

    function maxTokenPerWallet() external view returns (uint256) {
        return 0;
    }

    // ==================== DividendPayingToken ==================== //

    function dividendOf(address _owner)
        public
        view
        returns (uint256 dividends)
    {
        return 0;
    }

    function withdrawnDividendOf(address _owner)
        public
        view
        returns (uint256 dividends)
    {
        return 0;
    }

    function accumulativeDividendOf(address _owner)
        public
        view
        returns (uint256 accumulated)
    {
        return 0;
    }

    function withdrawableDividendOf(address _owner)
        public
        view
        returns (uint256 withdrawable)
    {
        return 0;
    }

    function dividendBalanceOf(address account) public view returns (uint256) {
        return 0;
    }

    // ==================== WithReward ==================== //

    function claimRewards() external {}

    function getRewardToken()
        public
        view
        returns (
            address token,
            address router,
            address[] memory path
        )
    {
        return (address(0), address(0), new address[](0));
    }

    function totalRewardSupply() public view returns (uint256) {
        return 0;
    }

    function getLastProcessedIndex() external view returns (uint256 index) {
        return 0;
    }

    /// @return numHolders The number of reward tracking token holders
    function getRewardHolders() external view returns (uint256 numHolders) {
        return 0;
    }

    /// Gets reward account information by address
    function getRewardAccount(address _account)
        public
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableRewards,
            uint256 totalRewards,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        return (address(0), 0, 0, 0, 0, 0, 0, 0);
    }

    function getRewardAccountAtIndex(uint256 _index)
        public
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableRewards,
            uint256 totalRewards,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        return (address(0), 0, 0, 0, 0, 0, 0, 0);
    }

    // ==================== Hamachi ==================== //

    function buyFees()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (0, 0, 0);
    }

    function sellFees()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (0, 0, 0);
    }

    function totalBuyFees() public view returns (uint256) {
        return 0;
    }

    function totalSellFees() public view returns (uint256) {
        return 0;
    }

    function numTokensToSwap() external view returns (uint256) {
        return 0;
    }

    // ==================== Vesting ==================== //
    function getTotalAmountInVesting() public view returns (uint256) {
        return 0;
    }

    function computeReleasableAmount(address _beneficiary)
        external
        view
        returns (uint256)
    {
        return 0;
    }

    function getVestingSchedule(address _beneficiary)
        external
        view
        returns (
            bool initialized,
            address beneficiary,
            uint256 cliff,
            uint256 start,
            uint256 duration,
            uint256 slicePeriodSeconds,
            uint256 amountTotal,
            uint256 released
        )
    {
        return (false, address(0), 0, 0, 0, 0, 0, 0);
    }

    function release(address _beneficiary, uint256 _amount) external {}

    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        uint256 _amount
    ) external {}

}