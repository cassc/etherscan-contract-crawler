// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./lzApp/NonblockingLzApp.sol";

contract TokenDistribution is Ownable, NonblockingLzApp {
    IERC20 public tokenAddress;

    constructor(
        address _tokenAddress,
        address _lzEndpoint
    ) NonblockingLzApp(_lzEndpoint) {
        tokenAddress = IERC20(_tokenAddress);
    }

    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        (uint256 amount, address addr) = decode(_payload);
        tokenAddress.transfer(addr, amount);
    }

    function decode(
        bytes memory data
    ) public pure returns (uint256 amount, address addr) {
        assembly {
            amount := mload(add(data, 32))
            addr := mload(add(data, 52))
        }

        return (amount, addr);
    }

    function withdrawTokens(
        address _tokenAddress,
        uint256 _amount
    ) public onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _amount);
    }
}