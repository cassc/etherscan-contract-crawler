// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import ".././Library/Ownable.sol";
import ".././Library/EnumerableSet.sol";

contract PresaleSettings is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Settings {
        uint256 BASE_FEE; // base fee divided by 1000
        uint256 TOKEN_FEE; // token fee divided by 1000
        address payable ETH_FEE_ADDRESS;
        address payable TOKEN_FEE_ADDRESS;
        uint256 ETH_CREATION_FEE; // fee to generate a presale contract on the platform
    }

    Settings public SETTINGS;

    constructor() public {
        SETTINGS.BASE_FEE = 0; // 5%
        SETTINGS.TOKEN_FEE = 0; // 0%
        SETTINGS.ETH_CREATION_FEE = 0; // 0.005 ETH
        SETTINGS.ETH_FEE_ADDRESS = payable(_msgSender());
        SETTINGS.TOKEN_FEE_ADDRESS = payable(_msgSender());
    }

    function getBaseFee() external view returns (uint256) {
        return SETTINGS.BASE_FEE;
    }

    function getTokenFee() external view returns (uint256) {
        return SETTINGS.TOKEN_FEE;
    }

    function getEthCreationFee() external view returns (uint256) {
        return SETTINGS.ETH_CREATION_FEE;
    }

    function getEthAddress() external view returns (address payable) {
        return SETTINGS.ETH_FEE_ADDRESS;
    }

    function getTokenAddress() external view returns (address payable) {
        return SETTINGS.TOKEN_FEE_ADDRESS;
    }

    function setFeeAddresses(
        address payable _ethAddress,
        address payable _tokenFeeAddress
    ) external onlyOwner {
        SETTINGS.ETH_FEE_ADDRESS = _ethAddress;
        SETTINGS.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
    }

    function setFees(
        uint256 _baseFee,
        uint256 _tokenFee,
        uint256 _ethCreationFee
    ) external onlyOwner {
        SETTINGS.BASE_FEE = _baseFee;
        SETTINGS.TOKEN_FEE = _tokenFee;
        SETTINGS.ETH_CREATION_FEE = _ethCreationFee;
    }
}