// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../layerZero/NonblockingLzApp.sol";
import "../utils/AdminProxyManager.sol";
import "../interfaces/IGovFactory.sol";
import "../interfaces/IGovSaleRemote.sol";

contract SaleGatewayRemote is
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    NonblockingLzApp,
    PausableUpgradeable,
    AdminProxyManager {

    uint16 public dstChainId; // polygon
    address public dstSaleGateway; // dst sale gateway

    event BuyToken(
        address sale,
        uint16 dstId,
        address dstContract,
        bytes dstPayload
    );

    function init(address _endpoint) external initializer proxied {
		__UUPSUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __NonblockingLzApp_init(_endpoint);
        __AdminProxyManager_init(_msgSender());

        dstChainId = 109;
	}

    function _authorizeUpgrade(address newImplementation) internal virtual override proxied {}

    /**
     * @dev Buy token project using token raise
     */
    function buyToken(
        address _factory,
        bytes calldata _payload,
        bytes calldata _adapterParams,
        uint256 _tax
    ) external payable whenNotPaused nonReentrant {
        require(IGovFactory(_factory).isKnown(_msgSender()), "unknown");

        uint256 feeIn = msg.value;
        if(_tax > 0) feeIn -= _tax;

        // send LayerZero message
        _lzSend(
            dstChainId,
            _payload,
            payable(address(this)),
            address(0x0),
            _adapterParams,
            feeIn
        );

        emit BuyToken(_msgSender(), dstChainId, dstSaleGateway, _payload);
    }

    function _nonblockingLzReceive(
        uint16, // _srcChainId
        bytes memory, // _srcAddress
        uint64, // _nonce
        bytes memory _payload
    ) internal override {
        (address targetSale,,,,,,,) = abi.decode(_payload, (
            address,
            uint128,
            uint128,
            uint256,
            address[],
            uint128[],
            uint128[],
            uint128[]
        ));

        IGovSaleRemote(targetSale).finalize(_payload);
    }

    function setDstSaleGateway(address _dstSaleGateway) external onlyOwner {
        dstSaleGateway = _dstSaleGateway;
    }

    /**
     * @dev Toggle buyToken pause
     */
    function togglePause() external onlyOwner {
        if(paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /**
     * @dev Set dst chain id
     * @param _dstChainId Dst chain id
     */
    function setDstChainId(uint16 _dstChainId) external onlyOwner {
        dstChainId = _dstChainId;
    }

    /**
     * @dev Withdraw eth
     */
    function wdEth(
        uint256 _amount,
        address payable _target
    ) external onlyOwner nonReentrant {
        if(address(this).balance < _amount) _amount = address(this).balance;

        (bool success,) = _target.call{value: _amount}("");
        require(success, "bad");
    }

    receive() external payable {}
}