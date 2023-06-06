// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "contracts/revenue-share-contracts/RSCValve.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract XLARSCValveFactory is Ownable {
    address payable public immutable contractImplementation;
    bytes32 public constant version = "1.0";
    uint256 public platformFee;
    address payable public platformWallet;

    struct RSCCreateData {
        address controller;
        address[] distributors;
        bool isImmutableRecipients;
        bool isAutoNativeCurrencyDistribution;
        uint256 minAutoDistributeAmount;
        address payable [] initialRecipients;
        uint256[] percentages;
        bytes32 creationId;
    }

    event RSCValveCreated(
        address contractAddress,
        address controller,
        address[] distributors,
        bytes32 version,
        bool isImmutableRecipients,
        bool isAutoNativeCurrencyDistribution,
        uint256 minAutoDistributeAmount,
        bytes32 creationId
    );

    event PlatformFeeChanged(
        uint256 oldFee,
        uint256 newFee
    );

    event PlatformWalletChanged(
        address payable oldPlatformWallet,
        address payable newPlatformWallet
    );

    // Throw when Fee Percentage is more than 100%
    error InvalidFeePercentage();

    constructor() {
        contractImplementation = payable(new XLARSCValve());
    }

    /**
     * @dev internal function for getting semi-random salt for deterministicClone creation
     * @param _data RSC Create data used for hashing and getting random salt
     * @param _deployer Wallet address that want to create new RSC contract
     */
    function _getSalt(RSCCreateData memory _data, address _deployer) internal pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
                _data.controller,
                _data.distributors,
                _data.isImmutableRecipients,
                _data.isAutoNativeCurrencyDistribution,
                _data.minAutoDistributeAmount,
                _data.initialRecipients,
                _data.percentages,
                _data.creationId,
                _deployer
            ));
        return hash;
    }

    /**
     * @dev external function for creating clone proxy pointing to RSC Percentage
     * @param _data RSC Create data used for hashing and getting random salt
     * @param _deployer Wallet address that want to create new RSC contract
     */
    function predictDeterministicAddress(RSCCreateData memory _data, address _deployer) external view returns(address) {
        bytes32 salt = _getSalt(_data, _deployer);
        address predictedAddress = Clones.predictDeterministicAddress(contractImplementation, salt);
        return predictedAddress;
    }

    /**
     * @dev Public function for creating clone proxy pointing to RSC Percentage
     * @param _data Initial data for creating new RSC Valve contract
     */
    function createRSCValve(RSCCreateData memory _data) external returns(address) {

        // check and register creationId
        bytes32 creationId = _data.creationId;
        address payable clone;
        if (creationId != bytes32(0)) {
            bytes32 salt = _getSalt(_data, msg.sender);
            clone = payable(Clones.cloneDeterministic(contractImplementation, salt));
        } else {
            clone = payable(Clones.clone(contractImplementation));
        }

        XLARSCValve(clone).initialize(
            msg.sender,
            _data.controller,
            _data.distributors,
            _data.isImmutableRecipients,
            _data.isAutoNativeCurrencyDistribution,
            _data.minAutoDistributeAmount,
            platformFee,
            address(this),
            _data.initialRecipients,
            _data.percentages
        );

        emit RSCValveCreated(
            clone,
            _data.controller,
            _data.distributors,
            version,
            _data.isImmutableRecipients,
            _data.isAutoNativeCurrencyDistribution,
            _data.minAutoDistributeAmount,
            creationId
        );

        return clone;
    }

    /**
     * @dev Only Owner function for setting platform fee
     * @param _fee Percentage define platform fee 100% == 10000000
     */
    function setPlatformFee(uint256 _fee) external onlyOwner {
        if (_fee > 10000000) {
            revert InvalidFeePercentage();
        }
        emit PlatformFeeChanged(platformFee, _fee);
        platformFee = _fee;
    }

    /**
     * @dev Only Owner function for setting platform fee
     * @param _platformWallet New native currency wallet which will receive fee
     */
    function setPlatformWallet(address payable _platformWallet) external onlyOwner {
        emit PlatformWalletChanged(platformWallet, _platformWallet);
        platformWallet = _platformWallet;
    }
}