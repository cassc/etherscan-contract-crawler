//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IAxelarGateway} from "@axelar-network/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/interfaces/IAxelarGasService.sol";
import {IAxelarExecutable} from "@axelar-network/interfaces/IAxelarExecutable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../LiquidityPool/IFetcchPool.sol";
import "../CommLayerAggregator/ICommLayer.sol";

contract AxelarImpl is IAxelarExecutable, Ownable, ICommLayer {
    /// @notice Axelar gas service address
    IAxelarGasService public gasReceiver;

    /// @notice Communication layer aggregator addresses
    ICommLayer public commLayerAggregator;

    /// @notice Mapping to get pool address from token address
    mapping(address => address) public pools;

    /// @notice mapping to check if source address is valid address
    mapping(string => bool) public source;

    event msgSent(string _dstChain, address _destination, bytes _payload);

    event Executed(string sourceChain, string sourceAddress, bytes _payload);

    /// @dev Initializes the contract by setting gateway, gasReceiver and commLayerAggregator address
    constructor(
        address _gateway,
        address _gasReceiver,
        address _commLayerAggregator
    ) IAxelarExecutable(_gateway) {
        gasReceiver = IAxelarGasService(_gasReceiver);
        commLayerAggregator = ICommLayer(_commLayerAggregator);
    }

    modifier onlyCommLayerAggregator() {
        require(msg.sender == address(commLayerAggregator));
        _;
    }

    /// @notice This function is responsible for setting source LayerZeroImpl addresses
    /// @dev onlyOwner is allowed to call this function
    /// @param _source Source chain LayerZeroImpl address
    function setSource(string memory _source) external onlyOwner {
        source[_source] = true;
    }

    /// @notice This function is responsible for changing commLayerAggregator address
    /// @dev onlyOwner can call this function
    /// @param _aggregator New communication layer aggregator address
    function changeCommLayerAggregator(address _aggregator) external onlyOwner {
        commLayerAggregator = ICommLayer(_aggregator);
    }

    /// @notice This function is responsible for changing gasReceiver address
    /// @dev onlyOwner can call this function
    /// @param _gasReceiver New gas receiver address
    function changeGasReceiver(address _gasReceiver) external onlyOwner {
        gasReceiver = IAxelarGasService(_gasReceiver);
    }

    /// @notice This function is responsible for mapping token to its corresponding pool
    /// @dev onlyOwner can access this function
    /// @param _token address of pool asset
    /// @param _pool address of corresponding pool
    function setPools(address _token, address _pool) external onlyOwner {
        pools[_token] = _pool;
    }

    /// @notice This function is responsible for sending messages to another chain using LayerZero
    /// @dev It makes call to LayerZero endpoint contract
    /// @dev This function can only be called from CommLayerAggregator
    /// @param destinationAddress Address of destination contract to send message on
    /// @param payload Encoded data to send on destination chain
    /// @param extraParams Encoded extra parameters
    function sendMsg(
        address destinationAddress,
        bytes memory payload,
        bytes memory extraParams
    ) external payable onlyCommLayerAggregator {
        string memory destinationChain = abi.decode(extraParams, (string));
        if (msg.value > 0) {
            gasReceiver.payNativeGasForContractCall{value: msg.value}(
                address(this),
                destinationChain,
                toAsciiString(destinationAddress),
                payload,
                msg.sender
            );
        }
        gateway.callContract(
            destinationChain,
            toAsciiString(destinationAddress),
            payload
        );
        emit msgSent(destinationChain, destinationAddress, payload);
    }

    /// @notice This function is responsible for receiving messages
    /// @dev This function is directly called by Axelar gateway
    function _execute(
        string memory sourceChain_,
        string memory sourceAddress_,
        bytes calldata _payload
    ) internal override {
        // require(msg.sender == address(gateway));
        require(source[sourceAddress_], "Invalid source address");
        (
            address _fromToken,
            address _toToken,
            uint256 _amount,
            address _receiver,
            DexData memory _dex
        ) = abi.decode(_payload, (address, address, uint256, address, DexData));
        address pool = pools[_fromToken];
        IFetcchPool(pool).release(
            _fromToken,
            _toToken,
            _amount,
            _receiver,
            _dex
        );

        emit Executed(sourceChain_, sourceAddress_, _payload);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}