// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IRefinableToken.sol";
import "../interfaces/IServiceFee.sol";

/**
 * @notice Service Fee contract for Refinable NFT Marketplace
 */
contract ServiceFee is AccessControl, IServiceFee {
    using Address for address;

    /// @notice service fee contract
    IRefinableToken public refinableTokenContract;

    bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE");

    /// @notice Service fee recipient address
    address payable public serviceFeeRecipient;

    event ServiceFeeRecipientChanged(address payable serviceFeeRecipient);

    event RefinableTokenContractUpdated(address refinableTokenContract);

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Ownable: caller is not the admin"
        );
        _;
    }

    modifier onlyProxy() {
        require(
            hasRole(PROXY_ROLE, _msgSender()),
            "Ownable: caller is not the proxy"
        );
        _;
    }

    /**
     * @dev Constructor Function
    */
    constructor() public {
        require(
            _msgSender() != address(0),
            "Auction: Invalid Platform Fee Recipient"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Lets admin set the refinable token contract
     * @param _refinableTokenContract address of refinable token contract
     */
    function setRefinableTokenContract(address _refinableTokenContract) onlyAdmin external override {
        require(
            _refinableTokenContract != address(0),
            "ServiceFee.setRefinableTokenContract: Zero address"
        );
        refinableTokenContract = IRefinableToken(_refinableTokenContract);
        emit RefinableTokenContractUpdated(_refinableTokenContract);
    }

    /**
     * @notice Admin can add proxy address
     * @param _proxyAddr address of proxy
     */
    function addProxy(address _proxyAddr) onlyAdmin external override {
        require(
            _proxyAddr.isContract(),
            "ServiceFee.addProxy: address is not a contract address"
        );
        grantRole(PROXY_ROLE, _proxyAddr);
    }

    /**
     * @notice Admin can remove proxy address
     * @param _proxyAddr address of proxy
     */
    function removeProxy(address _proxyAddr) onlyAdmin external override{
        require(
            _proxyAddr.isContract(),
            "ServiceFee.removeProxy: address is not a contract address"
        );
        revokeRole(PROXY_ROLE, _proxyAddr);
    }

    /**
     * @notice Calculate the seller service fee in according to the business logic and returns it
     * @param _seller address of seller
     * @param _isSecondarySale sale is primary or secondary
     */
    function getSellServiceFeeBps(address _seller, bool _isSecondarySale) external view onlyProxy override returns (uint256) {
        require(
            _seller != address(0),
            "ServiceFee.getSellServiceFeeBps: Zero address"
        );

        uint256 balance = refinableTokenContract.balanceOf(_seller);

        if(_isSecondarySale) {
            if(balance >= 10000 * 10 ** 18)
                return 150;
            else if(balance >= 2500 * 10 ** 18)
                return 175;
            else if(balance >= 250 * 10 ** 18)
                return 200;
            else if(balance >= 20 * 10 ** 18)
                return 225;
        } else {
            if(balance >= 250 * 10 ** 18)
                return 200;
            else if(balance >= 20 * 10 ** 18)
                return 225;
        }
        return 250;
    }

    /**
     * @notice Calculate the buyer service fee in according to the business logic and returns it
     * @param _buyer address of buyer
     */
    function getBuyServiceFeeBps(address _buyer) onlyProxy external view override returns (uint256) {
        require(
            _buyer != address(0),
            "ServiceFee.getBuyServiceFeeBps: Zero address"
        );
        uint256 balance = refinableTokenContract.balanceOf(_buyer);

        if(balance >= 10000 * 10 ** 18)
            return 150;
        else if(balance >= 2500 * 10 ** 18)
            return 175;
        else if(balance >= 250 * 10 ** 18)
            return 200;
        else if(balance >= 20 * 10 ** 18)
            return 225;
        return 250;
    }

    /**
     * @notice Get service fee recipient address
     */
    function getServiceFeeRecipient() onlyProxy external view override returns (address payable) {
        return serviceFeeRecipient;
    }

    /**
     * @notice Set service fee recipient address
     * @param _serviceFeeRecipient address of recipient
     */
    function setServiceFeeRecipient(address payable _serviceFeeRecipient) onlyProxy external override {
        require(
            _serviceFeeRecipient != address(0),
            "ServiceFee.setServiceFeeRecipient: Zero address"
        );

        serviceFeeRecipient = _serviceFeeRecipient;
        emit ServiceFeeRecipientChanged(_serviceFeeRecipient);
    }
}