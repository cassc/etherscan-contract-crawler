// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IIkonictoken.sol";

/**
 * @notice Service Fee contract for Ikonic NFT Marketplace
 */
contract ServiceFee is AccessControl, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 sellerServiceFeeBps;

    uint256 buyerServiceFeeBps;

    bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE");

    address internal serviceFeeRecipient;

    event ServiceFeeRecipientChanged(address serviceFeeRecipient);

    modifier onlyProxy() {
        require(
            hasRole(PROXY_ROLE, _msgSender()),
            "ServiceFee: caller is not the proxy"
        );
        _;
    }

    /**
     * @dev Constructor Function
    */
    constructor() {
        require(
            _msgSender() != address(0),
            "ServiceFee: Zero address"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        sellerServiceFeeBps = 300;

        buyerServiceFeeBps = 200;

    }

    /**
     * @notice Admin can add proxy address
     * @param _proxyAddr address of proxy
     */
    function addProxy(address _proxyAddr) onlyOwner external {
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
    function removeProxy(address _proxyAddr) onlyOwner external {
        require(
            _proxyAddr.isContract(),
            "ServiceFee.removeProxy: address is not a contract address"
        );
        revokeRole(PROXY_ROLE, _proxyAddr);
    }

    /**
     * @notice Set seller service fee
     * @param _sellerFee seller service fee
     */
    function setSellServiceFee(uint256 _sellerFee) external onlyProxy {
        require(
            _sellerFee != 0,
            "ServiceFee.setSellServiceFee: Zero value"
        );
        
        sellerServiceFeeBps = _sellerFee.mul(100);
    }

    /**
     * @notice Set buyer service fee
     * @param _buyerFee buyer service fee
     */
    function setBuyServiceFee(uint256 _buyerFee) external onlyProxy {
        require(
            _buyerFee != 0,
            "ServiceFee.setBuyServiceFee: Zero value"
        );
        
        buyerServiceFeeBps = _buyerFee.mul(100);
    }

    /**
     * @notice Get the seller service fee
     */
    function getSellServiceFeeBps() external view returns (uint256) {
        return sellerServiceFeeBps;
    }

    /**
     * @notice Get the buyer service fee 
     */
    function getBuyServiceFeeBps() external view returns (uint256) {
        return buyerServiceFeeBps;
    }

    /**
     * @notice Get service fee recipient address
     */
    function getServiceFeeRecipient() external view returns (address) {
        return serviceFeeRecipient;
    }

    /**
     * @notice Set service fee recipient address
     * @param _serviceFeeRecipient address of recipient
     */
    function setServiceFeeRecipient(address _serviceFeeRecipient) onlyProxy external {
        require(
            _serviceFeeRecipient != address(0),
            "ServiceFee.setServiceFeeRecipient: Zero address"
        );

        serviceFeeRecipient = _serviceFeeRecipient;
        emit ServiceFeeRecipientChanged(_serviceFeeRecipient);
    }
}