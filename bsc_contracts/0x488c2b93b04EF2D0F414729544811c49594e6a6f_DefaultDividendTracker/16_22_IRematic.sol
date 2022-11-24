// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./PancakeswapInterface/IERC20.sol";

interface IRematic is IERC20 {
    function adminContract() external view returns (address);

    function burnWallet() external view returns (address);
    function stakingWallet() external view returns (address);
    function txFeeRate() external view returns (uint256);
    function burnFeeRate() external view returns (uint256);
    function stakingFeeRate() external view returns (uint256);

    function setBurnWallet(address _address) external;
    function setStakingWallet(address _address) external;
    function setTxFeeRate(uint256 _value) external;
    function setBurnFeeRate(uint256 _value) external;
    function setStakingFeeRate(uint256 _value) external;

    function setIsOnBurnFee(bool flag) external;
    function setIsOnStakingFee(bool flag) external;

    function swapThreshold() external returns (uint256);

}