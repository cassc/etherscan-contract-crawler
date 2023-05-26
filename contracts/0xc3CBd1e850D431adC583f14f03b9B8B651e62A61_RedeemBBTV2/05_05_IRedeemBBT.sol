// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


interface IRedeemBBT {

    /// @notice mapping of how many CNV tokens a bbtCNV holder has redeemed
    /// @param      _who    address
    /// @return     amount  amount redeemed so far
    function redeemed(address _who)
        external
        view
        returns(uint256 amount);

    /// @notice             redeem bbtCNV for CNV following vesting schedule
    /// @param  _amount     amount of CNV to redeem, irrelevant if _max = true
    /// @param  _who        address of bbtCNV holder to redeem
    /// @param  _to         address to which to mint CNV
    /// @param  _max        whether to redeem maximum amount possible
    /// @return amountOut   amount of CNV tokens to be minted to _to
    function redeem(uint256 _amount, address _who, address _to, bool _max)
        external
        returns(uint256 amountOut);

    /// @notice         to view how much a holder has redeemable
    /// @param  _who    bbtHolder address
    /// @return         amount redeemable
    function redeemable(address _who)
        external
        view
        returns(uint256);

    /// @notice         returns the percent of holdings vested for a given point
    ///                 in time.
    /// @param  _time   point in time
    /// @return vpct    percent of holdings vested
    function vestedPercent(uint256 _time)
        external
        pure
        returns(uint256 vpct);
}