// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "../interfaces/IServiceFee.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Service Fee Proxy to communicate service fee contract
 */
contract ServiceFeeProxy is Ownable {
    
    IServiceFee private serviceFeeContract;

    event ServiceFeeContractUpdated(address serviceFeeContract);

    /**
     * @notice Let admin set the service fee contract
     * @param _serviceFeeContract address of serviceFeeContract
     */
    function setServiceFeeContract(address _serviceFeeContract) onlyOwner external {
        require(
            _serviceFeeContract != address(0),
            "ServiceFeeProxy.setServiceFeeContract: Zero address"
        );
        serviceFeeContract = IServiceFee(_serviceFeeContract);
        emit ServiceFeeContractUpdated(_serviceFeeContract);
    }

    /**
     * @notice Set seller service fee
     * @param _sellerFee seller service fee
     */
    function setSellServiceFee(uint256 _sellerFee) external onlyOwner {
        require(
            _sellerFee != 0,
            "ServiceFee.setSellServiceFee: Zero value"
        );
        
        serviceFeeContract.setSellServiceFee(_sellerFee);
    }

    /**
     * @notice Set buyer service fee
     * @param _buyerFee buyer service fee
     */
    function setBuyServiceFee(uint256 _buyerFee) external onlyOwner {
        require(
            _buyerFee != 0,
            "ServiceFee.setBuyServiceFee: Zero value"
        );
        
        serviceFeeContract.setBuyServiceFee(_buyerFee);
    }

    /**
     * @notice Fetch sell service fee bps from service fee contract
     */
    function getSellServiceFeeBps() external view returns (uint256) {
        return serviceFeeContract.getSellServiceFeeBps();
    }

    /**
     * @notice Fetch buy service fee bps from service fee contract
     */
    function getBuyServiceFeeBps() external view returns (uint256) {
        return serviceFeeContract.getBuyServiceFeeBps();
    }

    /**
     * @notice Get service fee recipient address
     */
    function getServiceFeeRecipient() external view returns (address) {
        return serviceFeeContract.getServiceFeeRecipient();
    }

    /**
     * @notice Set service fee recipient address
     * @param _serviceFeeRecipient address of recipient
     */
    function setServiceFeeRecipient(address _serviceFeeRecipient) external onlyOwner {
        require(
            _serviceFeeRecipient != address(0),
            "ServiceFeeProxy.setServiceFeeRecipient: Zero address"
        );

        serviceFeeContract.setServiceFeeRecipient(_serviceFeeRecipient);
    }
}