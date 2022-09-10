// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../lib/LibPool.sol";
import "../lib/Math.sol";


contract IgnitionCore is OwnableUpgradeable, PausableUpgradeable {

    /// Pool Token Model
    /// IDO (Token Address) -> Pool (unit) -> PoolTokenModel
    mapping(address => mapping(uint8 => LibPool.PoolTokenModel)) public poolTokens;
    mapping(address => mapping(uint8 => LibPool.FallBackModel)) public fallBacks;
    mapping(address => LibPool.ERC20Decimals) public erc20Decimals;

    uint constant internal STATUS_BOOLEAN = 5;

    function version() external virtual pure returns (string memory) {
        return "1.0.11";
    }

    function initialize() external initializer {
        __Ownable_init();
        __Pausable_init();
    }

    /**
    * @notice pause/Unpause Smart Contract
    * @dev Only Owner
    */
    function pause(bool status) external onlyOwner {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
    * Get the Address from PackageDate variable.
    * @param _packageData Address package the data via Bytes Shift
    * @return result is a address from convert uint256 to bytes20 with address() method
    */
    function getAddress(uint256 _packageData) external virtual pure returns (address)
    {
        return address(uint160(_packageData));
    }

        /**
    * @notice Calculate Amount of Token
    * @dev This method hava a adjust that permit eliminate the 10 less significant digits
    * @dev This is achieved by dividing not by 1e18 to convert from wei to eth, but by
    * @dev additionally changing the exponent to the value of 1e28, to discard the last
    * @dev 10 least significant digits of the multiplication result, avoiding the
    * @dev well-known solidity precision errors when multiply bignumbers
    * @dev Error IGN34 - Buy value below threshold
    * @param _pool number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    * @param _amount Amount in Coin (ETH/USDT/USDC/DAI, etc) for Buy Tokens of the IDO
    * @return Amount of token rewarded based in th Tiers assign in the Lottery
    */
    function calculateAmount(uint8 _pool, address _poolAddr, uint256 _amount)
    internal virtual view returns (uint256) {

        uint256 decimalAdjust = LibPool.getDecimals(erc20Decimals[_poolAddr].decimals);
        uint256 rewardedAmount = Math.mulDivRoundingUp(
            _amount,
            poolTokens[_poolAddr][_pool].rate,
            1e28
        ) * 1e11;

        require(rewardedAmount > 0, "IGN34");
        return rewardedAmount / decimalAdjust;
    }

    /// @notice Revert receive ether without buyTokens
    // solhint-disable-next-line
    fallback() external {
        revert("Fallback not supported");
    }
}