//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import './interfaces/ILayerZeroEndpoint.sol';
import './interfaces/ILayerZeroReceiver.sol';
import './NonblockingLzApp.sol';

error NotTokenOwner();
error InsufficientGas();
error SupplyExceeded();

contract CrossChainNFT is Ownable, ERC721, NonblockingLzApp {
    uint256 public counter;
    uint256 public currentTokenId;
    uint256 public immutable MAX_ID;

    event ReceivedNFT(
        uint16 _srcChainId,
        address _from,
        uint256 _tokenId,
        uint256 counter
    );

    constructor(
        address _endpoint,
        uint256 _startTokenId
    ) ERC721('CrossChainNFT', 'CCNFT') NonblockingLzApp(_endpoint) {
        currentTokenId = _startTokenId;
        MAX_ID = currentTokenId + 99999;
    }

    function mint() external {
        if (currentTokenId == MAX_ID) revert SupplyExceeded();
        _mint(msg.sender, currentTokenId);
        unchecked {
            ++currentTokenId;
            ++counter;
        }
    }

    function crossChain(uint16 dstChainId, uint256 tokenId) public payable {
        if (msg.sender != ownerOf(tokenId)) revert NotTokenOwner();

        // Remove NFT on current chain
        unchecked {
            --counter;
        }
        _burn(tokenId);

        bytes memory payload = abi.encode(msg.sender, tokenId);
        uint16 version = 1;
        uint256 gasForLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForLzReceive);

        (uint256 messageFee, ) = lzEndpoint.estimateFees(
            dstChainId,
            address(this),
            payload,
            false,
            adapterParams
        );
        if (msg.value <= messageFee) revert InsufficientGas();

        _lzSend(
            dstChainId,
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams,
            msg.value
        );
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /*_nonce*/,
        bytes memory _payload
    ) internal override {
        address from;
        assembly {
            from := mload(add(_srcAddress, 20))
        }
        (address toAddress, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );

        _mint(toAddress, tokenId);
        unchecked {
            ++counter;
        }
        emit ReceivedNFT(_srcChainId, from, tokenId, counter);
    }

    // Endpoint.sol estimateFees() returns the fees for the message
    function estimateFees(
        uint16 dstChainId,
        uint256 tokenId
    ) external view returns (uint256) {
        bytes memory payload = abi.encode(msg.sender, tokenId);
        uint16 version = 1;
        uint256 gasForLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForLzReceive);

        (uint256 messageFee, ) = lzEndpoint.estimateFees(
            dstChainId,
            address(this),
            payload,
            false,
            adapterParams
        );
        return messageFee;
    }
}