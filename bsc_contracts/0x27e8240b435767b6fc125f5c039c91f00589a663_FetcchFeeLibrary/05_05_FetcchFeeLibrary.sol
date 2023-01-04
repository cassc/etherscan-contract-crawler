//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FetcchFeeLibrary is Ownable {
    using SafeMath for uint256;

    event MaxFeesChanged(uint256 _newFees);

    uint256 constant FLOAT_HANDLER = 10000;
    uint256 constant feesAtEq = 10;
    uint256 public maxFees = 1000;
    uint256 public LPFee = 7;
    uint256 public platformFee = 3;

    mapping(uint8 => mapping(uint8 => uint8)) internal deepFactorRange;

    /// @notice This function is responsible for changing max fees
    /// @dev onlyOwner is allowed to call this function
    /// @param _fees : new max fees
    function changeMaxFees(uint256 _fees) external onlyOwner {
        maxFees = _fees.mul(100);
        emit MaxFeesChanged(maxFees);
    }

    /// @notice This function is responsible for calculating Equilibrium Fees
    /// @dev Returns fees to be deducted from transfer amount
    /// @param _pool : address of pool
    /// @param _token : address of token deposited by user in the pool
    /// @param _amount : Amount deposited by the user in the pool
    /// @param _suppliedLiq : Total liquidity supplied by the LPs
    function getEqFees(
        address _pool,
        address _token,
        uint256 _amount,
        uint256 _suppliedLiq,
        uint256 _availableLiq
    ) external view returns (uint256 fees) {
        return _getEqFees(_pool, _token, _amount, _suppliedLiq, _availableLiq);
    }

    function _getEqFees(
        address _pool,
        address _token,
        uint256 _amount,
        uint256 _suppliedLiq,
        uint256 _availableLiq
    ) internal view returns (uint256 fees) {
        return 0;
    }

    /// @notice This function is responsible for calculating Equilibrium Rewards
    /// @dev Returns rewards to be transferred for providing excess liquidity
    /// @param _pool : address of pool
    /// @param _token : address of token deposited by user in the pool
    /// @param _amount : Amount deposited by the user in the pool
    /// @param _suppliedLiq : Total liquidity supplied by the LPs
    /// @param _IP :  Incentive Pool Amount for given asset
    function getEqRewards(
        address _pool,
        address _token,
        uint256 _amount,
        uint256 _suppliedLiq,
        uint256 _availableLiq,
        uint256 _IP
    ) external view returns (uint256 reward) {
        return
            _getEqRewards(
                _pool,
                _token,
                _amount,
                _suppliedLiq,
                _availableLiq,
                _IP
            );
    }

    function _getEqRewards(
        address _pool,
        address _token,
        uint256 _amount,
        uint256 _suppliedLiq,
        uint256 _availableLiq,
        uint256 _IP
    ) internal view returns (uint256 reward) {
        return 0;
    }

    /// @notice This function is responsible for returning LP fees for a particular amount
    /// @param _amount amount of tokens
    /// @return LP fees for a particular amount
    function getLPFee(uint256 _amount) external view returns (uint256) {
        return (_amount.mul(LPFee)).div(FLOAT_HANDLER);
    }

    /// @notice This function is responsible for returning platform fees for a particular amount
    /// @param _amount amount of tokens
    /// @return platform fees for a particular amount
    function getPlatformFee(uint256 _amount) external view returns (uint256) {
        return (_amount.mul(platformFee)).div(FLOAT_HANDLER);
    }

    /// @notice This function is responsible for changing LP fees
    /// @dev onlyOwner is allowed to call this function
    /// @param _LPFee new LP fee
    function changeLPFee(uint256 _LPFee) external onlyOwner {
        LPFee = _LPFee;
    }

    /// @notice Returns current version of fee library
    function getVersion() external pure returns (string memory) {
        return "1.0.0";
    }
}