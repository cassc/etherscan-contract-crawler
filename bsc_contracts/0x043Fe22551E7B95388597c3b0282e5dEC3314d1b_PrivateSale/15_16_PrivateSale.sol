// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./implements/SaleBase.sol";

import "./implements/VestingWalletOMN.sol";

contract PrivateSale is SaleBase {
    uint256 private _startTimeVesting;
    uint256 private _durationVesting;

    constructor(
        ITreasury treasury,
        address addressBusd,
        address addressUsdt,
        address addressVes,
        address addressPancakeRouter,
        uint256 startTimeSale,
        uint256 endTimeSale,
        uint256 startTimeVesting,
        uint256 durationVesting
    ) {
        require(
            endTimeSale > startTimeSale && startTimeSale >= now(),
            "Time sale invalid"
        );
        require(startTimeVesting > endTimeSale, "Time vesting invalid");
        _price = 170;
        _busdAddress = addressBusd;
        _usdtAddress = addressUsdt;
        _vesAddress = addressVes;
        _pancakeRouterAddress = addressPancakeRouter;

        _startTimestamp = startTimeSale;
        _endTimestamp = endTimeSale;

        _startTimeVesting = startTimeVesting;
        _durationVesting = durationVesting;

        _maxSaleToken = 77_600_000 ether;
        _treasury = treasury;

    }

    function _getVestingWalletAddress(
        address beneficiary,
        uint256 amountVes
    ) internal override returns (address) {
        address existingWallet = _vestingWallets[beneficiary];

        if (existingWallet == address(0x0)) {
            VestingWalletOMN wallet = new VestingWalletOMN(
                beneficiary,
                _startTimeVesting,
                _durationVesting,
                amountVes,
                _vesAddress
            );

            address walletAddress = address(wallet);
            _vestingWallets[beneficiary] = walletAddress;

            return walletAddress;
        } else {
            return existingWallet;
        }
    }

    function getStartVesting() public view returns (uint256) {
        return _startTimeVesting;
    }

    function getDurationVesting() public view returns (uint256) {
        return _durationVesting;
    }
}