// SPDX-License-Identifier: MIT
// 2022 Infinity Keys Team
pragma solidity ^0.8.4;

/*************************************************************
* @title: ABSTRACT IK Traverse Chains                        *
* @notice: Manage leaving this chain for another, and        *
* receiving from another chain, as well as gas               *
*************************************************************/

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./NonblockingReceiver.sol";

abstract contract AbstractIKTraverseChains is NonblockingReceiver, ERC1155Supply {
    uint public gasForDestinationLzReceive = 350000;

    event ReceiveNFT( uint16 _srcChainId, bytes _from, uint256 _tokenId, address _to );
    event MessageFee(uint fee);

    /**
    @dev Traverse specified tokenID to specified chainID
    */
    function traverseChain(uint16 _chainID, uint _tokenID) external payable {
        require(
            balanceOf(msg.sender, _tokenID) > 0,
            "TraverseChain: You must own this token to traverse"
        );
        require(
            trustedRemoteLookup[_chainID].length != 0,
            "TraverseChain: This chain is currently unavailable for travel"
        );
        require(
            _chainID != block.chainid,
            "TraverseChain: Destination blockchain can't be the same as source"
        );

        _burn(msg.sender, _tokenID, 1); // Eliminate NFT from source chain

        bytes memory payload = abi.encode(msg.sender, _tokenID); // Encode the payload

        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(
            version,
            gasForDestinationLzReceive
        );

        // Get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // Extra Gas will be refunded
        (uint256 messageFee, ) = endpoint.estimateFees(
            _chainID,
            address(this),
            payload,
            false,
            // bytes("")
            adapterParams
        );

        emit MessageFee(messageFee);

        require(
            msg.value >= messageFee,
            "TraverseChain: value sent is not enough to cover messageFee. Increase gas for message fees"
        );

        endpoint.send{value: msg.value}(
            _chainID, 
            trustedRemoteLookup[_chainID], 
            payload, 
            payable(msg.sender), 
            address(0x0), 
            adapterParams 
        );
    }

    /**
    @dev Set the gas for receive function on destination chain
    */
    function setGasForDestinationLzReceive(uint256 newVal) external onlyOwner {
        gasForDestinationLzReceive = newVal;
    }

    /**
    @dev Handle receiving NFTs sent from other chains
    */
    function _LzReceive( uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload ) internal override {
        (address toAddr, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );

        emit ReceiveNFT( _srcChainId, _srcAddress, tokenId, toAddr );

        _mint(toAddr, tokenId, 1, ""); 
    }
}