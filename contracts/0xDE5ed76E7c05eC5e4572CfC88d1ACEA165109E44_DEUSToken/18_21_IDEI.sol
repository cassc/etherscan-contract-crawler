// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later

interface IDEIStablecoin {

    function totalSupply() external view returns (uint256);

    function global_collateral_ratio() external view returns (uint256);
	
    function verify_price(bytes32 sighash, bytes[] calldata sigs) external view returns (bool);

	function dei_info(uint256 eth_usd_price, uint256 eth_collat_price)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);

	function globalCollateralValue(uint256[] memory collat_usd_price) external view returns (uint256);

	function refreshCollateralRatio(uint256 dei_price_cur, uint256 expireBlock, bytes[] calldata sigs) external;

	function pool_burn_from(address b_address, uint256 b_amount) external;

	function pool_mint(address m_address, uint256 m_amount) external;

	function addPool(address pool_address) external;

	function removePool(address pool_address) external;

	function setDEIStep(uint256 _new_step) external;

	function setPriceTarget(uint256 _new_price_target) external;

	function setRefreshCooldown(uint256 _new_cooldown) external;

	function setDEUSAddress(address _deus_address) external;

	function setPriceBand(uint256 _price_band) external;
	
    function toggleCollateralRatio() external;
}

//Dar panah khoda