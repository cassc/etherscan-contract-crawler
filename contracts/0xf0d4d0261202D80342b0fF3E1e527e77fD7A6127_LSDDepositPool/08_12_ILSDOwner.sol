// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILSDOwner {
    function getDepositEnabled() external view returns (bool);

    function getIsLock() external view returns (bool);

    function getApy() external view returns (uint256);

    function getMultiplier() external view returns (uint256);

    function getMultiplierUnit() external view returns (uint256);

    function getApyUnit() external view returns (uint256);

    function getLIDOApy() external view returns (uint256);

    function getRPApy() external view returns (uint256);

    function getSWISEApy() external view returns (uint256);

    function getProtocolFee() external view returns (uint256);

    function getMinimumDepositAmount() external view returns (uint256);

    function setDepositEnabled(bool _depositEnabled) external;

    function setIsLock(bool _isLock) external;

    function setApy(uint256 _apy) external;

    function setApyUnit(uint256 _apyUnit) external;

    function setMultiplier(uint256 _multiplier) external;

    function setMultiplierUnit(uint256 _multiplierUnit) external;

    function setRPApy(uint256 _rpApy) external;

    function setLIDOApy(uint256 _lidoApy) external;

    function setSWISEApy(uint256 _swiseApy) external;

    function setProtocolFee(uint256 _protocalFee) external;

    function setMinimumDepositAmount(uint256 _minimumDepositAmount) external;

    function upgrade(string memory _type, string memory _name, string memory _contractAbi, address _contractAddress) external;
}