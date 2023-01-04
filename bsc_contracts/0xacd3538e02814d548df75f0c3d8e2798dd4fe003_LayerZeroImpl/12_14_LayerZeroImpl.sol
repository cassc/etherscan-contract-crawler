//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../LiquidityPool/IFetcchPool.sol";
import "../CommLayerAggregator/ICommLayer.sol";

contract LayerZeroImpl is ILayerZeroReceiver, ICommLayer, Ownable {
    /// @notice LayerZero endoint address
    ILayerZeroEndpoint public endpoint;

    /// @notice Communication Layers Aggregator address
    ICommLayer public commLayerAggregator;

    /// @notice mapping to keep track of failed messages
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32)))
        public failedMessages;

    /// @notice mapping to check if source address is valid address
    mapping(address => bool) public source;

    /// @notice Mapping to get pool address from token address
    mapping(address => address) public pools;

    /// @notice Extra LayerZero fees customization parameters
    struct lzAdapterParams {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    event ReceiveMsg(
        uint16 _srcChainId,
        address _from,
        bytes _payload,
        uint256 nonce
    );
    event msgSent(
        uint16 _dstChainId,
        bytes _destination,
        bytes _payload,
        uint256 nonce
    );
    event RetriedPayload(uint16 _srcChainId, bytes _srcAddress, bytes _payload);
    event ForceResumed(uint16 _srcChainId, bytes _srcAddress, bytes _payload);

    /// @dev Initializes the contract by setting LayerZeroEndpoint and CommLayerAggregator address
    constructor(address _endpoint, address _commLayerAggregator) {
        endpoint = ILayerZeroEndpoint(_endpoint);
        commLayerAggregator = ICommLayer(_commLayerAggregator);
    }

    /// @notice modifier to check msg.sender is commLayerAggregator
    modifier onlyCommLayerAggregator() {
        require(msg.sender == address(commLayerAggregator));
        _;
    }

    /// @notice This function is responsible to estimate fees required for sending message
    /// @param _dstChainId Destination Chain Id
    /// @param _userApplication Destination contract address
    /// @param _payload Encoded data to send on destination chain
    /// @param _adapterParameters Extra fees customization parameters
    /// @return nativeFee Fees required in native token
    /// @return zroFee Fees required in zro token
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bytes calldata _adapterParameters
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        return
            endpoint.estimateFees(
                _dstChainId,
                _userApplication,
                _payload,
                false,
                _adapterParameters
            );
    }

    /// @notice This function is responsible for mapping token to its corresponding pool
    /// @dev onlyOwner can access this function
    /// @param _token address of pool asset
    /// @param _pool address of corresponding pool
    function setPools(address _token, address _pool) external onlyOwner {
        pools[_token] = _pool;
    }

    /// @notice This function is responsible for setting source LayerZeroImpl addresses
    /// @dev onlyOwner is allowed to call this function
    /// @param _source Source chain LayerZeroImpl address
    function setSource(address _source) external onlyOwner {
        source[_source] = true;
    }

    /// @notice This function is responsible for setting source LayerZeroImpl addresses
    /// @dev onlyOwner is allowed to call this function
    /// @param _endpoint Source chain LayerZeroImpl address
    function changeEndpoint(address _endpoint) external onlyOwner {
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    /// @notice This function is responsible for chaning communication layer aggregator address
    /// @dev onlyOwner is allowed to call this function
    /// @param _aggregator Communication layer aggregator address
    function changeCommLayerAggregator(address _aggregator) external onlyOwner {
        commLayerAggregator = ICommLayer(_aggregator);
    }

    /// @notice This function is responsible for sending messages to another chain using LayerZero
    /// @dev It makes call to LayerZero endpoint contract
    /// @dev This function can only be called from CommLayerAggregator
    /// @param _destination Address of destination contract to send message on
    /// @param _payload Encoded data to send on destination chain
    /// @param extraParams Encoded extra parameters
    function sendMsg(
        address _destination,
        bytes calldata _payload,
        bytes memory extraParams
    ) public payable onlyCommLayerAggregator {
        (uint16 _dstChainId, address refundAd, bytes memory adapterParams) = abi
            .decode(extraParams, (uint16, address, bytes));

        uint64 nextNonce = endpoint.getOutboundNonce(
            _dstChainId,
            address(this)
        ) + 1;

        endpoint.send{value: msg.value}(
            _dstChainId,
            abi.encodePacked(_destination, address(this)),
            _payload,
            payable(refundAd),
            address(0x0),
            adapterParams
        );
        emit msgSent(
            _dstChainId,
            abi.encodePacked(_destination),
            _payload,
            nextNonce
        );
    }

    /// @notice This function is responsible for receiving message
    /// @dev LayerZero endpoint calls this function upon receiving message
    /// @param _srcChainId Source chain Id
    /// @param _from Source chain contract address
    /// @param _nonce nonce
    /// @param _payload Encoded data received from source chain
    function lzReceive(
        uint16 _srcChainId,
        bytes memory _from,
        uint64 _nonce,
        bytes memory _payload
    ) external override {
        //require(msg.sender == address(endpoint));
        address from;
        assembly {
            from := mload(add(_from, 20))
        }
        //require(source[from], "Invalid source address");
        if (
            keccak256(abi.encodePacked((_payload))) ==
            keccak256(abi.encodePacked((bytes10("ff"))))
        ) {
            endpoint.receivePayload(
                1,
                bytes(""),
                address(0x0),
                1,
                1,
                bytes("")
            );
        }
        (
            address _fromToken,
            address _toToken,
            uint256 _amount,
            address _receiver,
            DexData memory _dex
        ) = abi.decode(_payload, (address, address, uint256, address, DexData));
        address pool = pools[_fromToken];
        try
            IFetcchPool(pool).release(
                _fromToken,
                _toToken,
                _amount,
                _receiver,
                _dex
            )
        {
            emit ReceiveMsg(_srcChainId, from, _payload, _nonce);
        } catch {
            try endpoint.retryPayload(_srcChainId, _from, _payload) {
                emit RetriedPayload(_srcChainId, _from, _payload);
            } catch {
                endpoint.forceResumeReceive(_srcChainId, _from);
                emit ForceResumed(_srcChainId, _from, _payload);
            }
        }
    }

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external onlyOwner {
        endpoint.setSendVersion(_version);
    }

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external onlyOwner {
        endpoint.setReceiveVersion(_version);
    }
}