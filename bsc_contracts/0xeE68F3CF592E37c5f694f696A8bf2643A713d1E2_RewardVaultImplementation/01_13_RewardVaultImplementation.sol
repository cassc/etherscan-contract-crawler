// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../token/IERC20.sol';
import '../token/IDToken.sol';
import './IPool.sol';
import './IVault.sol';
import '../library/SafeMath.sol';
import './RewardVaultStorage.sol';
import '../RewardVault/IRewardVault.sol';

contract RewardVaultImplementation is RewardVaultStorage {

	using SafeMath for uint256;
	using SafeMath for int256;
	uint256 constant UONE = 1e18;

	IERC20 public immutable RewardToken;

	event SetRewardPerSecond(address indexed pool, uint256 newRewardPerSecond);
	event Claim(address indexed pool, address indexed account, uint256 indexed tokenId, uint256 amount);
	event AddPool(address indexed pool);

	constructor(address _rewardToken) {
		RewardToken = IERC20(_rewardToken);
	}

	//  ========== ADMIN ==============
	// Initialize new pool
	function initializeVenus(address _pool) _onlyAdmin_ external {
		require(!authorizedPool[_pool], "pool already init");
		IDToken lToken = IPool(_pool).lToken();

		uint256 total = lToken.totalMinted();
		uint256 _totalLiquidityB0;
		address vTokenB0 = IPool(_pool).vTokenB0();

		for (uint256 tokenId = 1; tokenId <= total; tokenId++) {
			UserInfo storage user = userInfo[_pool][tokenId];
			IPool.LpInfo memory info = IPool(_pool).lpInfos(tokenId);
			if (info.liquidity > 0) {
				(, uint256 underlyingBalance) = IVault(info.vault).getBalances(vTokenB0);
				int256 liquidityB0 = info.amountB0 + underlyingBalance.utoi();
				if (info.liquidity >= liquidityB0) {
					user.liquidityB0 = liquidityB0 > 0 ? liquidityB0.itou() : 0;
				} else {
					user.liquidityB0 = info.liquidity.itou();
				}
				_totalLiquidityB0 += user.liquidityB0;
			}
		}

		VaultInfo storage vault = vaultInfo[_pool];
		vault.totalLiquidityB0 = _totalLiquidityB0;
		vault.lastRewardTimestamp = block.timestamp;

		authorizedPool[_pool] = true;
		pools.push(_pool);

		emit AddPool(_pool);
	}

	function initializeAave(address _pool) _onlyAdmin_ external {
		require(!authorizedPool[_pool], "pool already init");
		IDToken lToken = IPool(_pool).lToken();

		uint256 total = lToken.totalMinted();
		uint256 _totalLiquidityB0;
		address marketB0 = IPool(_pool).marketB0();
		address tokenB0 = IPool(_pool).tokenB0();
		uint256 decimalsB0 = IERC20(tokenB0).decimals();

		for (uint256 tokenId = 1; tokenId <= total; tokenId++) {
			UserInfo storage user = userInfo[_pool][tokenId];
			IPool.LpInfo memory info = IPool(_pool).lpInfos(tokenId);
			if (info.liquidity > 0) {
				uint256 assetBalanceB0 = IVault(info.vault).getAssetBalance(marketB0);
                int256 liquidityB0 = assetBalanceB0.rescale(decimalsB0, 18).utoi() + info.amountB0;
				if (info.liquidity >= liquidityB0) {
					user.liquidityB0 = liquidityB0 > 0 ? liquidityB0.itou() : 0;
				} else {
					user.liquidityB0 = info.liquidity.itou();
				}
				_totalLiquidityB0 += user.liquidityB0;
			}
		}

		VaultInfo storage vault = vaultInfo[_pool];
		vault.totalLiquidityB0 = _totalLiquidityB0;
		vault.lastRewardTimestamp = block.timestamp;

		authorizedPool[_pool] = true;
		pools.push(_pool);

		emit AddPool(_pool);
	}

	// Initialze new pool from old reward vault
	function initializeFromVenus(address _pool, address _fromRewardVault) _onlyAdmin_ external {
		require(!authorizedPool[_pool], "pool already init");
		IDToken lToken = IPool(_pool).lToken();
		uint256 total = lToken.totalMinted();
		uint256 _totalLiquidityB0;
		address vTokenB0 = IPool(_pool).vTokenB0();

		uint256 newAccRewardPerLiquidity;
		{
			uint256 lastRewardTimestamp = IRewardVault(_fromRewardVault).lastRewardTimestamp();
			uint256 accRewardPerLiquidity = IRewardVault(_fromRewardVault).accRewardPerLiquidity();
			uint256 totalLiquidity = IPool(_pool).liquidity().itou();
			uint256 reward = (block.timestamp - lastRewardTimestamp) * IRewardVault(_fromRewardVault).rewardPerSecond();
			newAccRewardPerLiquidity = accRewardPerLiquidity + reward * UONE / totalLiquidity;
		}

		for (uint256 tokenId = 1; tokenId <= total; tokenId++) {
			UserInfo storage user = userInfo[_pool][tokenId];
			IPool.LpInfo memory info = IPool(_pool).lpInfos(tokenId);
			IRewardVault.UserInfo memory fromUser = IRewardVault(_fromRewardVault).userInfo(tokenId);
			if (info.liquidity > 0) {
				(, uint256 underlyingBalance) = IVault(info.vault).getBalances(vTokenB0);
				int256 liquidityB0 = info.amountB0 + underlyingBalance.utoi();
				if (info.liquidity >= liquidityB0) {
					user.liquidityB0 = liquidityB0 > 0 ? liquidityB0.itou() : 0;
				} else {
					user.liquidityB0 = info.liquidity.itou();
				}
				user.unclaimed = fromUser.unclaimed + info.liquidity.itou() * (newAccRewardPerLiquidity - fromUser.accRewardPerLiquidity) / UONE;
				_totalLiquidityB0 += user.liquidityB0;
			} else {
				user.unclaimed = fromUser.unclaimed;
			}
		}
		VaultInfo storage vault = vaultInfo[_pool];
		vault.totalLiquidityB0 = _totalLiquidityB0;
		vault.lastRewardTimestamp = block.timestamp;
		authorizedPool[_pool] = true;
		pools.push(_pool);
		emit AddPool(_pool);
	}


	function initializeFromAaveA(address _pool) _onlyAdmin_ external {
		require(!authorizedPool[_pool], "pool already init");
		VaultInfo storage vault = vaultInfo[_pool];
		vault.lastRewardTimestamp = block.timestamp;

		authorizedPool[_pool] = true;
		pools.push(_pool);
		emit AddPool(_pool);
	}

	function initializeFromAaveB(address _pool, address _fromRewardVault, uint256 start, uint256 end) _onlyAdmin_ external {
		require(authorizedPool[_pool], 'pool not init');
		uint256 markAccRewardPerLiquidity;
		{
			uint256 lastRewardTimestamp = IRewardVault(_fromRewardVault).lastRewardTimestamp();
			uint256 accRewardPerLiquidity = IRewardVault(_fromRewardVault).accRewardPerLiquidity();
			uint256 totalLiquidity = IPool(_pool).liquidity().itou();
			uint256 vaultTimestamp = vaultInfo[_pool].lastRewardTimestamp;
			uint256 reward = (vaultTimestamp - lastRewardTimestamp) * IRewardVault(_fromRewardVault).rewardPerSecond();
			markAccRewardPerLiquidity = accRewardPerLiquidity + reward * UONE / totalLiquidity;
		}

		IDToken lToken = IPool(_pool).lToken();
		uint256 total = lToken.totalMinted();
		uint256 _totalLiquidityB0;
		address marketB0 = IPool(_pool).marketB0();
		uint256 decimalsB0 = IERC20(IPool(_pool).tokenB0()).decimals();
		if (end > total) end = total;

		for (uint256 tokenId = start; tokenId <= end; tokenId++) {
			UserInfo storage user = userInfo[_pool][tokenId];
			IPool.LpInfo memory info = IPool(_pool).lpInfos(tokenId);
			IRewardVault.UserInfo memory fromUser = IRewardVault(_fromRewardVault).userInfo(tokenId);
			if (info.liquidity > 0) {
				uint256 assetBalanceB0 = IVault(info.vault).getAssetBalance(marketB0);
                int256 liquidityB0 = assetBalanceB0.rescale(decimalsB0, 18).utoi() + info.amountB0;
				if (info.liquidity >= liquidityB0) {
					user.liquidityB0 = liquidityB0 > 0 ? liquidityB0.itou() : 0;
				} else {
					user.liquidityB0 = info.liquidity.itou();
				}
				user.unclaimed = fromUser.unclaimed + info.liquidity.itou() * (markAccRewardPerLiquidity - fromUser.accRewardPerLiquidity) / UONE;
				_totalLiquidityB0 += user.liquidityB0;
			} else {
				user.unclaimed = fromUser.unclaimed;
			}
		}

		VaultInfo storage vault = vaultInfo[_pool];
		vault.totalLiquidityB0 += _totalLiquidityB0;
	}


	// Initialize new lite pool
	function initializeLite(address _pool) _onlyAdmin_ external {
		require(!authorizedPool[_pool], "pool already init");
		IDToken lToken = IPool(_pool).lToken();
		uint256 total = lToken.totalMinted();
		uint256 _totalLiquidityB0;

		for (uint256 tokenId = 1; tokenId <= total; tokenId++) {
			UserInfo storage user = userInfo[_pool][tokenId];
			IPool.LpInfo memory info = IPool(_pool).lpInfos(tokenId);
			if (info.liquidity > 0) {
				int256 liquidityB0 = info.amountB0;
				user.liquidityB0 = liquidityB0 > 0 ? liquidityB0.itou() : 0;
				_totalLiquidityB0 += user.liquidityB0;
			}
		}

		VaultInfo storage vault = vaultInfo[_pool];
		vault.totalLiquidityB0 = _totalLiquidityB0;
		vault.lastRewardTimestamp = block.timestamp;

		authorizedPool[_pool] = true;
		pools.push(_pool);

		emit AddPool(_pool);
	}


	function setRewardPerSecond(address _pool, uint256 _rewardPerSecond) _onlyAdmin_ external {
		uint256 totalLiquidity = IPool(_pool).liquidity().itou();
		uint256 ratioB0 = _getRatioB0(_pool, totalLiquidity);
		_updateAccRewardPerLiquidity(_pool, totalLiquidity, ratioB0);

		vaultInfo[_pool].rewardPerSecond = _rewardPerSecond;
		emit SetRewardPerSecond(_pool, _rewardPerSecond);
	}

	function emergencyWithdraw(address to) _onlyAdmin_ external {
		uint256 balance = RewardToken.balanceOf(address(this));
		RewardToken.transfer(to, balance);
	}

	// ============= UPDATE =================

	function updateVault(uint256 totalLiquidity, uint256 tokenId, uint256 liquidity, uint256 balanceB0, int256 newLiquidityB0) external {
		address pool = msg.sender;
		if (!authorizedPool[pool]) {
			return;
		}
		// update accRewardPerLiquidity before adding new liquidity
		uint256 ratioB0 = balanceB0 * UONE / totalLiquidity;
		_updateAccRewardPerLiquidity(pool, totalLiquidity, ratioB0);

		// settle reward to the user before updating new liquidity
		UserInfo storage user = userInfo[pool][tokenId];
		VaultInfo memory vault = vaultInfo[pool];
		user.unclaimed += user.liquidityB0 * (vault.accRewardPerB0Liquidity - user.accRewardPerB0Liquidity) / UONE
			+ (liquidity - user.liquidityB0) * (vault.accRewardPerBXLiquidity - user.accRewardPerBXLiquidity) / UONE;
		user.accRewardPerB0Liquidity = vault.accRewardPerB0Liquidity;
		user.accRewardPerBXLiquidity = vault.accRewardPerBXLiquidity;

		// update liquidityB0
		int256 totalLiquidityB0 = vault.totalLiquidityB0.utoi();
		int256 liquidityB0;
		if (newLiquidityB0 > 0) {
			int256 delta =  newLiquidityB0 - user.liquidityB0.utoi();
			totalLiquidityB0 += delta;
			liquidityB0 = newLiquidityB0;
		} else if (newLiquidityB0 <= 0 && user.liquidityB0 >0) {
			int256 delta = -user.liquidityB0.utoi();
			totalLiquidityB0 += delta;
			liquidityB0 = 0;
		} else { //// newLiquidityB0 <= 0 && user.liquidityB0 == 0
			return;
		}
		vaultInfo[pool].totalLiquidityB0 = totalLiquidityB0.itou();
		user.liquidityB0 = liquidityB0.itou();
	}


	function claim(address pool) external {
		require(authorizedPool[pool], "Only authorized by pools");
		uint256 totalLiquidity = IPool(pool).liquidity().itou();
		uint256 ratioB0 = _getRatioB0(pool, totalLiquidity);
		_updateAccRewardPerLiquidity(pool, totalLiquidity, ratioB0);

		IDToken lToken = IPool(pool).lToken();
		require(lToken.exists(msg.sender), "LToken not exist");
		uint256 tokenId = lToken.getTokenIdOf(msg.sender);

		UserInfo storage user = userInfo[pool][tokenId];
		VaultInfo memory vault = vaultInfo[pool];
		IPool.LpInfo memory info = IPool(pool).lpInfos(tokenId);
		uint256 liquidity = info.liquidity.itou();
		uint256 claimed = user.unclaimed
			+ user.liquidityB0 * (vault.accRewardPerB0Liquidity - user.accRewardPerB0Liquidity) / UONE
			+ (liquidity - user.liquidityB0) * (vault.accRewardPerBXLiquidity - user.accRewardPerBXLiquidity) / UONE;

		user.accRewardPerB0Liquidity = vault.accRewardPerB0Liquidity;
		user.accRewardPerBXLiquidity = vault.accRewardPerBXLiquidity;
		user.unclaimed = 0;

		RewardToken.transfer(msg.sender, claimed);
		emit Claim(pool, msg.sender, tokenId, claimed);
	}


	function _updateAccRewardPerLiquidity(address pool, uint256 totalLiquidity, uint256 ratioB0) internal {
		(uint256 rewardPerB0Liquidity, uint256 rewardPerBXLiquidity) = _getRewardPerLiquidity(pool, totalLiquidity, ratioB0);
		VaultInfo storage vault = vaultInfo[pool];
		vault.accRewardPerB0Liquidity += rewardPerB0Liquidity;
		vault.accRewardPerBXLiquidity += rewardPerBXLiquidity;
		vault.lastRewardTimestamp = block.timestamp;
	}

	function _getRewardPerLiquidityPerSecond(address pool, uint256 totalLiquidity, uint256 ratioB0) internal view returns (
		uint256 rewardPerB0LiquidityPerSecond, uint256 rewardPerBXLiquidityPerSecond
	) {
		(bool success, bytes memory data) = pool.staticcall(abi.encodeWithSignature("minRatioB0()"));
		uint256 minRatioB0;
		if (success) {
			minRatioB0 = abi.decode(data, (int256)).itou();
		}
		uint256 rewardPerSecond = vaultInfo[pool].rewardPerSecond;
		uint256 totalLiquidityB0 = vaultInfo[pool].totalLiquidityB0;

		if (ratioB0 >= 2 * minRatioB0) {
			rewardPerBXLiquidityPerSecond = rewardPerSecond * UONE / totalLiquidity;
			rewardPerB0LiquidityPerSecond = rewardPerBXLiquidityPerSecond;
		} else if (ratioB0 <= minRatioB0) {
			rewardPerB0LiquidityPerSecond = rewardPerSecond * UONE / totalLiquidityB0;
		} else {
			uint256 rewardCoef = (ratioB0 - minRatioB0) * UONE / minRatioB0;
			rewardPerBXLiquidityPerSecond = rewardPerSecond * rewardCoef / totalLiquidity;
			rewardPerB0LiquidityPerSecond = (rewardPerSecond * UONE - rewardPerBXLiquidityPerSecond * (totalLiquidity - totalLiquidityB0))/ totalLiquidityB0;
		}
	}

	function _getRewardPerLiquidity(address pool, uint256 totalLiquidity, uint256 ratioB0) internal view returns (
		uint256 rewardPerB0Liquidity, uint256 rewardPerBXLiquidity
	) {
		(uint256 rewardPerB0LiquidityPerSecond, uint256 rewardPerBXLiquidityPerSecond) = _getRewardPerLiquidityPerSecond(pool, totalLiquidity, ratioB0);
		uint256 timeDelta = block.timestamp - vaultInfo[pool].lastRewardTimestamp;
		rewardPerB0Liquidity = timeDelta * rewardPerB0LiquidityPerSecond;
		rewardPerBXLiquidity = timeDelta * rewardPerBXLiquidityPerSecond;
	}

	function _getRatioB0(address pool, uint256 totalLiquidity) internal view returns (uint256) {
		address tokenB0 = IPool(pool).tokenB0();
		uint256 decimalsB0 = IERC20(tokenB0).decimals();
		uint256 ratioB0 = IERC20(tokenB0).balanceOf(pool).rescale(decimalsB0, 18) * UONE / totalLiquidity;
		return ratioB0;
	}


	// ============= VIEW ===================
	function pending(address pool, address account) external view returns (uint256) {
		IDToken lToken = IPool(pool).lToken();
		uint256 tokenId = lToken.getTokenIdOf(account);
		return pending(pool, tokenId);
	}

	function pending(address pool, uint256 tokenId) public view returns (uint256) {
		UserInfo memory user = userInfo[pool][tokenId];
		VaultInfo memory vault = vaultInfo[pool];

		uint256 totalLiquidity = IPool(pool).liquidity().itou();
		uint256 ratioB0 = _getRatioB0(pool, totalLiquidity);
		(uint256 rewardPerB0Liquidity, uint256 rewardPerBXLiquidity) = _getRewardPerLiquidity(pool, totalLiquidity, ratioB0);
		uint256 newAccRewardPerB0Liquidity = vault.accRewardPerB0Liquidity + rewardPerB0Liquidity;
		uint256 newAccRewardPerBXLiquidity = vault.accRewardPerBXLiquidity + rewardPerBXLiquidity;

		IPool.LpInfo memory info = IPool(pool).lpInfos(tokenId);
		uint256 liquidity = info.liquidity.itou();
		uint256 unclaimed = user.unclaimed + user.liquidityB0 * (newAccRewardPerB0Liquidity - user.accRewardPerB0Liquidity) / UONE
			+ (liquidity - user.liquidityB0) * (newAccRewardPerBXLiquidity - user.accRewardPerBXLiquidity) / UONE;

		return unclaimed;
	}

	function getRewardPerLiquidityPerSecond(address pool) external view returns (uint256, uint256) {
		uint256 totalLiquidity = IPool(pool).liquidity().itou();
		uint256 ratioB0 = _getRatioB0(pool, totalLiquidity);
		return _getRewardPerLiquidityPerSecond(pool, totalLiquidity, ratioB0);
	}

	function getUserInfo(address pool, address account) external view returns (UserInfo memory) {
		IDToken lToken = IPool(pool).lToken();
		uint256 tokenId = lToken.getTokenIdOf(account);
		UserInfo memory user = userInfo[pool][tokenId];
		return user;
	}

	function getTotalLiquidityB0(address pool) external view returns (uint256) {
		return vaultInfo[pool].totalLiquidityB0;
	}

	function getAccRewardPerB0Liquidity(address pool) external view returns (uint256) {
		return vaultInfo[pool].accRewardPerB0Liquidity;
	}

	function getAccRewardPerBXLiquidity(address pool) external view returns (uint256) {
		return vaultInfo[pool].accRewardPerBXLiquidity;
	}

	function getVaultBalance(uint256 endTimestamp) external view returns (uint256, int256) {
		uint256 balance = RewardToken.balanceOf(address(this));
		uint256 delta = endTimestamp - block.timestamp;
		uint256 toclaim;
		for (uint256 i=0; i<pools.length; i++) {
			toclaim += vaultInfo[pools[i]].rewardPerSecond * delta;
			toclaim += getPendingPerPool(pools[i]);
		}
		int256 remain = balance.utoi() - toclaim.utoi();
		return (balance, remain);
	}

	function getPendingPerPool(address pool) public view returns (uint256) {
		IDToken lToken = IPool(pool).lToken();
		uint256 total = lToken.totalMinted();
		uint256 unclaimed;
		for (uint256 tokenId = 1; tokenId <= total; tokenId++) {
			unclaimed += pending(pool, tokenId);
		}
		return unclaimed;
	}

}