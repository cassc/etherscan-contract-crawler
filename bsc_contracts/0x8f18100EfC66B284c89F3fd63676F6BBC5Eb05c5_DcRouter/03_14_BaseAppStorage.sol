// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../stargate/ISgBridge.sol";

abstract contract BaseAppStorage {
    /// address of native stargateRouter for swap
    /// https://stargateprotocol.gitbook.io/stargate/interfaces/evm-solidity-interfaces/istargaterouter.sol
    /// https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
    address internal _sgBridge;

    address internal _currentUSDCToken;

    address internal _actionPool;

    uint16 internal _nativeChainId;

    event Bridged(
        uint16 indexed receiverLZId,
        address indexed receiverAddress,
        uint256 stableAmount
    );
    event RouterChanged(address sender, address oldRelayer, address newRelayer);

    modifier onlySelf() {
        require(
            msg.sender == address(this) || msg.sender == _actionPool,
            "SmartLZBase:Only self call"
        );
        _;
    }

    /* solhint-disable */
    receive() external payable {}

    fallback() external payable {}

    /* solhint-enable */

    function setBridge(
        address _newSgBridge /*onlySelf() */
    ) public {
        _sgBridge = _newSgBridge;
    }

    /**
     * @notice Set address of native stable token for this router
     * @param _newStableToken - newStableToken address of native stableToken
     * @dev only deCommas ActionPool Address
     */
    function setStable(
        address _newStableToken /*onlySelf()*/
    ) public returns (bool) {
        _currentUSDCToken = _newStableToken;
        return true;
    }

    function bridge(
        address _nativeStableToken,
        uint256 _stableAmount,
        uint16 _receiverLZId,
        address _receiverAddress,
        address _destinationStableToken
    ) public onlySelf {
        _bridge(
            _nativeStableToken,
            _stableAmount,
            _receiverLZId,
            _receiverAddress,
            _destinationStableToken,
            address(this).balance,
            ""
        );
    }

    function getNativeSgBridge() public view returns (address) {
        return _sgBridge;
    }

    function _bridge(
        address _nativeStableToken,
        uint256 _stableAmount,
        uint16 _receiverLZId,
        address _receiverAddress,
        address _destinationStableToken,
        uint256 _nativeValue,
        bytes memory _payload
    ) internal {
        IERC20(_nativeStableToken).approve(_sgBridge, _stableAmount);
        ISgBridge(_sgBridge).bridge{value: _nativeValue}(
            _nativeStableToken,
            _stableAmount,
            _receiverLZId,
            _receiverAddress,
            _destinationStableToken,
            _payload
        );
        emit Bridged(_receiverLZId, _receiverAddress, _stableAmount);
    }
}