// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "../interfaces/IServiceFee.sol";
import "../roles/AdminRole.sol";

/**
 * @notice Service Fee Proxy to communicate service fee contract
 */
contract ServiceFeeProxy is AdminRole {
    /// @notice service fee contract
    IServiceFee public serviceFeeContract;

    event ServiceFeeContractUpdated(address serviceFeeContract);

    /**
     * @notice Lets admin set the service fee contract
     * @param _serviceFeeContract address of serviceFeeContract
     */
    function setServiceFeeContract(address _serviceFeeContract) onlyAdmin external {
        require(
            _serviceFeeContract != address(0),
            "ServiceFeeProxy.setServiceFeeContract: Zero address"
        );
        serviceFeeContract = IServiceFee(_serviceFeeContract);
        emit ServiceFeeContractUpdated(_serviceFeeContract);
    }

    /**
     * @notice Fetch sell service fee bps from service fee contract
     * @param _seller address of seller
     */
    function getSellServiceFeeBps(address _seller, bool isSecondarySale) external view returns (uint256) {
        require(
            _seller != address(0),
            "ServiceFeeProxy.getSellServiceFeeBps: Zero address"
        );
        return serviceFeeContract.getSellServiceFeeBps(_seller, isSecondarySale);
    }

    /**
     * @notice Fetch buy service fee bps from service fee contract
     * @param _buyer address of seller
     */
    function getBuyServiceFeeBps(address _buyer) external view returns (uint256) {
        require(
            _buyer != address(0),
            "ServiceFeeProxy.getBuyServiceFeeBps: Zero address"
        );
        return serviceFeeContract.getBuyServiceFeeBps(_buyer);
    }

    /**
     * @notice Get service fee recipient address
     */
    function getServiceFeeRecipient() external view returns (address payable) {
        return serviceFeeContract.getServiceFeeRecipient();
    }

    /**
     * @notice Set service fee recipient address
     * @param _serviceFeeRecipient address of recipient
     */
    function setServiceFeeRecipient(address payable _serviceFeeRecipient) external onlyAdmin {
        require(
            _serviceFeeRecipient != address(0),
            "ServiceFeeProxy.setServiceFeeRecipient: Zero address"
        );

        serviceFeeContract.setServiceFeeRecipient(_serviceFeeRecipient);
    }
}