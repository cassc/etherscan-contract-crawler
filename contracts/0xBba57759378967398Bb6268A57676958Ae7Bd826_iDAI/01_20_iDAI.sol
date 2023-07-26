// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./iToken.sol";
import "./interface/IMaker.sol";

// Upgrade iDAI to support DSR.
contract iDAI is iToken {
    // DAI adapter contract
    DaiJoinLike public immutable daiJoin;

    // DAI Savings Rate (DSR) pot contract
    PotLike public immutable pot;

    // DAI vat contract
    VatLike public immutable vat;

    constructor(address _daiJoin, address _pot) public {
        daiJoin = DaiJoinLike(_daiJoin);
        pot = PotLike(_pot);
        vat = DaiJoinLike(_daiJoin).vat();
    }

    // Upgrade iDAI contract to support depositing underlying DAI to DSR
    function _enableDSR() external onlyOwner {
        GemLike dai = daiJoin.dai();
        require(address(dai) == address(underlying), "_enableDSR: DAI must be the same as underlying");

        // Approve moving DAI into the vat through daiJoin
        underlying.approve(address(daiJoin), uint256(-1));

        // Approve the pot to transfer our funds within the vat
        vat.hope(address(pot));
        vat.hope(address(daiJoin));

        // Accumulate DSR interest -- must do this in order to _doTransferIn
        pot.drip();

        // Transfer all cash in (_doTransferIn does this regardless of amount)
        _doTransferIn(address(this), 0);
    }

    // Disable to exit DSR
    function _disableDSR() external settleInterest onlyOwner {
        // Accumulate interest
        pot.drip();

        // Calculate the total amount in the pot, and move it out
        uint256 _pie = pot.pie(address(this));
        pot.exit(_pie);

        // Checks the actual balance of DAI in the vat after the pot exit
        uint256 _bal = vat.dai(address(this));

        // Remove our whole balance
        daiJoin.exit(address(this), _bal.div(RAY));

        // Disapprove moving DAI into the vat through daiJoin
        underlying.approve(address(daiJoin), 0);
    }

    /**
      * @notice Accrues DSR then applies accrued interest to total borrows and reserves
      * @dev This calculates interest accrued from the last checkpointed block
      *      up to the current block and writes new checkpoint to storage.
      */
    function _updateInterest() internal virtual override  {
        // Accumulate DSR interest
        pot.drip();

        // Accumulate iToken interest
        super._updateInterest();
    }

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function _getCurrentCash() internal view override returns (uint256) {
        uint256 _pie = pot.pie(address(this));

        return pot.chi().mul(_pie).div(RAY);
    }

    // Transfer the underlying to this contract and sweep into DSR pot
    function _doTransferIn(address _sender, uint256 _amount)
        internal
        override
        returns (uint256)
    {
        // Perform the EIP-20 transfer in
        underlying.safeTransferFrom(_sender, address(this), _amount);

        // Convert all DAI to internal DAI in the vat
        daiJoin.join(address(this), underlying.balanceOf(address(this)));

        // Checks the actual balance of DAI in the vat after the join
        uint256 _bal = vat.dai(address(this));

        // Calculate the percentage increase to th pot for the entire vat, and move it in
        // Note: We may leave a tiny bit of DAI in the vat...but we do the whole thing every time
        uint256 _pie = _bal.div(pot.chi());
        pot.join(_pie);

        return _amount;
    }

    // Transfer the underlying from this contract, after sweeping out of DSR pot
    function _doTransferOut(address payable _to, uint256 _amount) internal virtual override {
        // Calculate the percentage decrease from the pot, and move that much out
        // Note: Use a slightly larger pie size to ensure that we get at least amount in the vat
        uint256 _pie = _amount.mul(RAY).div(pot.chi()).add(1);
        pot.exit(_pie);

        daiJoin.exit(_to, _amount);
    }

    // Calculates the Dai savings rate per block
    function dsrPerBlock() internal view returns (uint256) {
        return pot
            .dsr().sub(RAY)  // scaled 1e27 aka RAY, and includes an extra "ONE" before subtraction
            .div(1e9) // descale to 1e18
            .mul(13); // 13 seconds per block
    }

    function supplyRatePerBlock() external override view returns (uint256) {
        // `_underlyingScaled` is scaled by 1e36.
        uint256 _underlyingScaled = totalSupply.mul(_exchangeRateInternal());
        if (_underlyingScaled == 0) return 0;
        uint256 _totalBorrowsScaled = totalBorrows.mul(BASE);
        uint256 _totalCashScaled = _getCurrentCash().mul(BASE);
        uint256 _dsrPerBlock = dsrPerBlock();

        return
            borrowRatePerBlock().tmul(
                BASE.sub(reserveRatio),
                _totalBorrowsScaled
            ).add(_totalCashScaled.rmul(_dsrPerBlock)).rdiv(_underlyingScaled);
    }

    /*** Maker Internals ***/

    uint256 constant RAY = 10 ** 27;
}