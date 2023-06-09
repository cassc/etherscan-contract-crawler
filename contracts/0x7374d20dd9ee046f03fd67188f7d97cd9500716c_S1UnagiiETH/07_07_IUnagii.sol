// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IUnagii {
    function safeDepositETH(address _receiver, uint256 _minShares) external payable returns (uint256 shares);

    function safeRedeemETH(
		uint256 _shares,
		address _receiver,
		address _owner,
		uint256 _maxShares
	) external returns (uint256 assets);

    function convertToShares(uint256 _assets) external view returns (uint256 shares); // for deposit

    function convertToAssets(uint256 _shares) external view returns (uint256 assets); // for withdraw
}