// SPDX-License-Identifier: ISC
pragma solidity >=0.8.17;

// NOTE: This file generated from FPIController contract at https://etherscan.io/address/0x2397321b301B80A1C0911d6f9ED4b6033d43cF51#code

interface IFPIControllerPool {
    function FEE_PRECISION() external view returns (uint256);

    function FPI_TKN() external view returns (address);

    function FRAX() external view returns (address);

    function PEG_BAND_PRECISION() external view returns (uint256);

    function PRICE_PRECISION() external view returns (uint256);

    function TWAMM() external view returns (address);

    function acceptOwnership() external;

    function addAMO(address amo_address) external;

    function amos(address) external view returns (bool);

    function amos_array(uint256) external view returns (address);

    function burnFPI(bool burn_all, uint256 fpi_amount) external;

    function calcMintFPI(uint256 frax_in, uint256 min_fpi_out) external view returns (uint256 fpi_out);

    function calcRedeemFPI(uint256 fpi_in, uint256 min_frax_out) external view returns (uint256 frax_out);

    function cancelCurrTWAMMOrder(uint256 order_id_override) external;

    function chainlink_fpi_usd_decimals() external view returns (uint256);

    function chainlink_frax_usd_decimals() external view returns (uint256);

    function collectCurrTWAMMProceeds(uint256 order_id_override) external;

    function cpiTracker() external view returns (address);

    function dollarBalances() external view returns (uint256 frax_val_e18, uint256 collat_val_e18);

    function fpi_mint_cap() external view returns (uint256);

    function frax_borrow_cap() external view returns (int256);

    function frax_borrowed_balances(address) external view returns (int256);

    function frax_borrowed_sum() external view returns (int256);

    function frax_is_token0() external view returns (bool);

    function getFPIPriceE18() external view returns (uint256);

    function getFRAXPriceE18() external view returns (uint256);

    function getReservesAndFPISpot()
        external
        returns (
            uint256 reserveFRAX,
            uint256 reserveFPI,
            uint256 fpi_price
        );

    function giveFRAXToAMO(address destination_amo, uint256 frax_amount) external;

    function last_order_id_twamm() external view returns (uint256);

    function max_swap_fpi_amt_in() external view returns (uint256);

    function max_swap_frax_amt_in() external view returns (uint256);

    function mintFPI(uint256 frax_in, uint256 min_fpi_out) external returns (uint256 fpi_out);

    function mint_fee() external view returns (uint256 fee);

    function mint_fee_manual() external view returns (uint256);

    function mint_fee_multiplier() external view returns (uint256);

    function mints_paused() external view returns (bool);

    function nominateNewOwner(address _owner) external;

    function nominatedOwner() external view returns (address);

    function num_twamm_intervals() external view returns (uint256);

    function owner() external view returns (address);

    function pegStatusMntRdm()
        external
        view
        returns (
            uint256 cpi_peg_price,
            uint256 diff_frac_abs,
            bool within_range
        );

    function peg_band_mint_redeem() external view returns (uint256);

    function peg_band_twamm() external view returns (uint256);

    function pending_twamm_order() external view returns (bool);

    function priceFeedFPIUSD() external view returns (address);

    function priceFeedFRAXUSD() external view returns (address);

    function price_info()
        external
        view
        returns (
            int256 collat_imbalance,
            uint256 cpi_peg_price,
            uint256 fpi_price,
            uint256 price_diff_frac_abs
        );

    function receiveFRAXFromAMO(uint256 frax_amount) external;

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function redeemFPI(uint256 fpi_in, uint256 min_frax_out) external returns (uint256 frax_out);

    function redeem_fee() external view returns (uint256 fee);

    function redeem_fee_manual() external view returns (uint256);

    function redeem_fee_multiplier() external view returns (uint256);

    function redeems_paused() external view returns (bool);

    function removeAMO(address amo_address) external;

    function setFraxBorrowCap(int256 _frax_borrow_cap) external;

    function setMintCap(uint256 _fpi_mint_cap) external;

    function setMintRedeemFees(
        bool _use_manual_mint_fee,
        uint256 _mint_fee_manual,
        uint256 _mint_fee_multiplier,
        bool _use_manual_redeem_fee,
        uint256 _redeem_fee_manual,
        uint256 _redeem_fee_multiplier
    ) external;

    function setOracles(
        address _frax_oracle,
        address _fpi_oracle,
        address _cpi_oracle
    ) external;

    function setPegBands(uint256 _peg_band_mint_redeem, uint256 _peg_band_twamm) external;

    function setTWAMMAndSwapPeriod(address _twamm_addr, uint256 _swap_period) external;

    function setTWAMMMaxSwapIn(uint256 _max_swap_frax_amt_in, uint256 _max_swap_fpi_amt_in) external;

    function setTimelock(address _new_timelock_address) external;

    function swap_period() external view returns (uint256);

    function timelock_address() external view returns (address);

    function toggleMints() external;

    function toggleRedeems() external;

    function twammManual(
        uint256 frax_sell_amt,
        uint256 fpi_sell_amt,
        uint256 override_intervals
    ) external returns (uint256 frax_to_use, uint256 fpi_to_use);

    function use_manual_mint_fee() external view returns (bool);

    function use_manual_redeem_fee() external view returns (bool);
}