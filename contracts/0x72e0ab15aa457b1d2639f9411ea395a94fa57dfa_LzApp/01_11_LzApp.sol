// SPDX-License-Identifier: MIT

/**
 * Created on 2022-11-20 06:20
 * @Summary A contract used to bridge tokens to different chains using LayerZero protocol.
 * @title Overlay Bridge.
 * @author: Overlay - c-n-o-t-e
 */
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./types/BaseNonblockingLzApp.sol";
import "./interfaces/IToken.sol";

error LzApp_AmountTooLow();
error LzApp_MessageFeeLow();
error LzApp_AmountAboveUserBalance();

contract LzApp is Pausable, BaseNonblockingLzApp {
    event SendToChain(
        address indexed _sender,
        uint16 _dstChainId,
        address _toAddress,
        uint _amount,
        uint64 _nonce,
        bytes payload
    );
    event Mint(
        address indexed _toAddress,
        bytes _dstChainId,
        uint _amount,
        uint64 _nonce
    );

    IToken public iToken;

    constructor(
        address _lzEndpoint,
        address _token
    ) BaseNonblockingLzApp(_lzEndpoint) {
        iToken = IToken(_token);
    }

    /// @notice sets token address
    /// @param _token token address
    function setTokenAddress(address _token) external onlyOwner {
        iToken = IToken(_token);
    }

    /// @notice mints tokens on destination chain
    /// @param _srcAddress bytes of both address (dst, src)
    /// @param _nonce tx count
    /// @param _payload data from src chain
    function _nonblockingLzReceive(
        uint16,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        (address toAddress, uint256 amount) = abi.decode(
            _payload,
            (address, uint256)
        );

        iToken.mint(toAddress, amount);
        emit Mint(toAddress, _srcAddress, amount, _nonce);
    }

    /// @notice bridge tokens to another chain
    /// @param _dstChainId destination chain ID
    /// @param _amount amount to burn and bridge
    function bridgeToken(
        uint16 _dstChainId,
        uint256 _amount
    ) public payable whenNotPaused {
        if (_amount == 0) revert LzApp_AmountTooLow();
        if (_amount > iToken.balanceOf(msg.sender)) revert LzApp_AmountAboveUserBalance();

        iToken.transferFrom(msg.sender, address(this), _amount);
        iToken.burn(_amount);

        bytes memory payload = abi.encode(msg.sender, _amount);
        bytes memory adapterParams = getAdapterParams(_dstChainId);

        (uint256 messageFee, ) = lzEndpoint.estimateFees(
            _dstChainId,
            address(this),
            payload,
            false,
            adapterParams
        );

        if (msg.value < messageFee) revert LzApp_MessageFeeLow();
        _lzSend(
            _dstChainId,
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );

        uint64 nonce = lzEndpoint.getOutboundNonce(_dstChainId, address(this));
        emit SendToChain(
            msg.sender,
            _dstChainId,
            msg.sender,
            _amount,
            nonce,
            payload
        );
    }

    function getAdapterParams(
        uint16 _dstChainId
    ) public view returns (bytes memory) {
        return
            abi.encodePacked(
                lzEndpoint.getSendVersion(address(this)),
                minDstGasLookup[_dstChainId]
            );
    }

    /// @notice disable bridging token
    /// @param _en flag indicator to pause/unpause contract
    function enable(bool _en) external onlyOwner {
        if (_en) {
            _pause();
        } else {
            _unpause();
        }
    }
}