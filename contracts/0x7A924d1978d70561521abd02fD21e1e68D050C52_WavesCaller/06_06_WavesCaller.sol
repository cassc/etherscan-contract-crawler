// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./AbstractCaller.sol";

contract WavesCaller is AbstractCaller {
    event WavesCallEvent(
        uint16 callerChainId,
        uint16 executionChainId,
        string executionContract,
        string functionName,
        string[] args,
        uint256 nonce
    );

    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function init(address admin_, uint16 chainId_) external whenNotInitialized {
        require(admin_ != address(0), "zero address");
        admin = admin_;
        pauser = admin_;
        chainId = chainId_;
        isInited = true;
    }

    // first argument must be empty (functionArgs_[0] = caller)
    function call(
        uint16 executionChainId_,
        string calldata executionContract_,
        string calldata functionName_,
        string[] memory functionArgs_
    ) external whenInitialized whenAllowed(msg.sender) whenNotPaused {
        string memory caller = toHexString_(msg.sender);
        functionArgs_[0] = caller;
        uint256 nonce_ = nonce;
        emit WavesCallEvent(
            chainId,
            executionChainId_,
            executionContract_,
            functionName_,
            functionArgs_,
            nonce_
        );
        nonce = nonce_ + 1;
    }

    function toHexString_(address addr) internal pure returns (string memory) {
        uint256 value = uint256(uint160(addr));
        bytes memory buffer = new bytes(2 * _ADDRESS_LENGTH + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * _ADDRESS_LENGTH + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "length insufficient");
        return string(buffer);
    }
}