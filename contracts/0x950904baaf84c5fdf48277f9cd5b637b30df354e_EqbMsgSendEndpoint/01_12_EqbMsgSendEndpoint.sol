// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../Interfaces/IEqbMsgSendEndpoint.sol";
import "../Interfaces/LayerZero/ILayerZeroEndpoint.sol";
import "../Dependencies/Errors.sol";
import "./LayerZeroHelper.sol";

/**
 * @dev Initially, currently we will use layer zero's default send and receive version (which is most updated)
 * So we can leave the configuration unset.
 */

contract EqbMsgSendEndpoint is IEqbMsgSendEndpoint, OwnableUpgradeable {
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    address payable public refundAddress;
    ILayerZeroEndpoint public lzEndpoint;

    EnumerableMap.UintToAddressMap internal receiveEndpoints;
    mapping(address => bool) public isWhitelisted;

    modifier onlyWhitelisted() {
        if (!isWhitelisted[msg.sender]) {
            revert Errors.OnlyWhitelisted();
        }

        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _refundAddress,
        ILayerZeroEndpoint _lzEndpoint
    ) external initializer {
        __Ownable_init();

        refundAddress = payable(_refundAddress);
        lzEndpoint = _lzEndpoint;

        setLzSendVersion(2);
    }

    function calcFee(
        uint256 _dstChainId,
        address _dstAddress,
        bytes memory _payload,
        uint256 _estimatedGasAmount
    ) external view returns (uint256 fee) {
        (fee, ) = lzEndpoint.estimateFees(
            LayerZeroHelper.getLayerZeroChainId(_dstChainId),
            receiveEndpoints.get(_dstChainId),
            abi.encode(_dstAddress, msg.sender, _payload),
            false,
            _getAdapterParams(_estimatedGasAmount)
        );
    }

    function sendMessage(
        uint256 _dstChainId,
        address _dstAddress,
        bytes calldata _payload,
        uint256 _estimatedGasAmount
    ) external payable onlyWhitelisted {
        bytes memory path = abi.encodePacked(
            receiveEndpoints.get(_dstChainId),
            address(this)
        );
        lzEndpoint.send{value: msg.value}(
            LayerZeroHelper.getLayerZeroChainId(_dstChainId),
            path,
            abi.encode(_dstAddress, msg.sender, _payload),
            refundAddress,
            address(0),
            _getAdapterParams(_estimatedGasAmount)
        );

        emit MsgSent(_dstChainId, _dstAddress, _payload, _estimatedGasAmount);
    }

    function addReceiveEndpoints(
        uint256 _endpointChainId,
        address _endpointAddr
    ) external payable onlyOwner {
        receiveEndpoints.set(_endpointChainId, _endpointAddr);
    }

    function setWhitelisted(address _addr, bool _status) external onlyOwner {
        isWhitelisted[_addr] = _status;
    }

    function setLzSendVersion(uint16 _newVersion) public onlyOwner {
        ILayerZeroEndpoint(lzEndpoint).setSendVersion(_newVersion);
    }

    function getAllReceiveEndpoints()
        external
        view
        returns (uint256[] memory chainIds, address[] memory addrs)
    {
        uint256 length = receiveEndpoints.length();
        chainIds = new uint256[](length);
        addrs = new address[](length);

        for (uint256 i = 0; i < length; ++i) {
            (chainIds[i], addrs[i]) = receiveEndpoints.at(i);
        }
    }

    function _getAdapterParams(
        uint256 _estimatedGasAmount
    ) internal pure returns (bytes memory adapterParams) {
        // this is more like "type" rather than version
        // It is the type of adapter params you want to pass to relayer
        adapterParams = abi.encodePacked(uint16(1), _estimatedGasAmount);
    }
}