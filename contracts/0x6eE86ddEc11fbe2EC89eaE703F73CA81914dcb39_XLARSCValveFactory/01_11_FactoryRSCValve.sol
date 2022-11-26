// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "contracts/RSCValve.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract XLARSCValveFactory is Ownable {
    address payable public immutable contractImplementation;
    uint256 constant version = 1;
    uint256 public platformFee;
    address payable public platformWallet;

    struct RSCCreateData {
        string name;
        address controller;
        address distributor;
        bool immutableController;
        bool autoEthDistribution;
        uint256 minAutoDistributeAmount;
        address payable [] initialRecipients;
        uint256[] percentages;
        string[] names;
    }

    event RSCValveCreated(
        address contractAddress,
        address controller,
        address distributor,
        string name,
        uint256 version,
        bool immutableController,
        bool autoEthDistribution,
        uint256 minAutoDistributeAmount
    );

    event PlatformFeeChanged(
        uint256 oldFee,
        uint256 newFee
    );

    event PlatformWalletChanged(
        address payable oldPlatformWallet,
        address payable newPlatformWallet
    );

    constructor() {
        contractImplementation = payable(new XLARSCValve());
    }

    /**
     * @dev Public function for creating clone proxy pointing to RSC Percentage
     * @param _data Initial data for creating new RSC Valve contract
     */
    function createRSCValve(RSCCreateData memory _data) external returns(address) {
        address payable clone = payable(Clones.clone(contractImplementation));

        XLARSCValve(clone).initialize(
            msg.sender,
            _data.controller,
            _data.distributor,
            _data.immutableController,
            _data.autoEthDistribution,
            _data.minAutoDistributeAmount,
            platformFee,
            address(this),
            _data.initialRecipients,
            _data.percentages,
            _data.names
        );

        emit RSCValveCreated(
            clone,
            _data.controller,
            _data.distributor,
            _data.name,
            version,
            _data.immutableController,
            _data.autoEthDistribution,
            _data.minAutoDistributeAmount
        );

        return clone;
    }

    /**
     * @dev Only Owner function for setting platform fee
     * @param _fee Percentage define platform fee 100% == 10000
     */
    function setPlatformFee(uint256 _fee) external onlyOwner {
        emit PlatformFeeChanged(platformFee, _fee);
        platformFee = _fee;
    }

    /**
     * @dev Only Owner function for setting platform fee
     * @param _platformWallet New ETH wallet which will receive ETH
     */
    function setPlatformWallet(address payable _platformWallet) external onlyOwner {
        emit PlatformWalletChanged(platformWallet, _platformWallet);
        platformWallet = _platformWallet;
    }
}