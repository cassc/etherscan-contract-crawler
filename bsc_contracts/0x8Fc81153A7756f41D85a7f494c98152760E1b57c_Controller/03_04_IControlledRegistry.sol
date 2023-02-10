//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IControlledRegistry {
    function isAmmPair(address addr) external view returns (bool);

    function isTransferLimited(address addr) external view returns (bool);

    function isSaleLimited() external view returns (bool);

    function getAmmPairs() external view returns (address[] memory);

    function getTransferLimited() external view returns (address[] memory);

    function setAmmPair(address account, bool isPair) external;

    function setTransferLimited(address account, bool isLimited) external;

    function setSaleLimited(bool isLimited) external;
}