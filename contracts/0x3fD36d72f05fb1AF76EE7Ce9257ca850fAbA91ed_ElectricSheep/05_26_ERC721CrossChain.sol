// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { INFTBridge } from "../../NFTBridge/interfaces/INFTBridge.sol";

contract ERC721CrossChain is Ownable, ERC721 {
    error CallerNotNFTBridge();
    error CrossChainBridgeNotEnabled();
    error CrossChainCallerNotOwner();
    error CrossChainToZeroAddress();

    event NFTBridgeUpdated(address);

    address public nftBridge;

    /**
     * @notice Constructor
     * @param name token name
     * @param symbol token symbol
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /**
     * @notice Only accept transcations sent by NFTBridge
     */
    modifier onlyNftBridge() {
        if (nftBridge == address(0)) {
            revert CrossChainBridgeNotEnabled();
        }
        if (_msgSender() != nftBridge) {
            revert CallerNotNFTBridge();
        }
        _;
    }

    /**
     * @notice Cross-chain ability is enabled
     */
    modifier crossChainEnabled() {
        if (nftBridge == address(0)) {
            revert CrossChainBridgeNotEnabled();
        }
        _;
    }

    /**
     * @notice Set NFTBridge contract address
     * @param bridge NFTBridge contract address
     */
    function setNFTBridge(address bridge) external onlyOwner {
        nftBridge = bridge;
        emit NFTBridgeUpdated(bridge);
    }

    /**
     * @notice Cross-chain transfer to specific receiver
     * @param chainId destination chain that token will be transferred to
     * @param tokenId token will be transferred
     * @param receiver wallet address in destination chain who will receive token
     */
    function crossChain(uint64 chainId, uint256 tokenId, address receiver) public payable crossChainEnabled {
        if (_msgSender() != ownerOf(tokenId)) {
            revert CrossChainCallerNotOwner();
        }
        if (receiver == address(0)) {
            revert CrossChainToZeroAddress();
        }

        string memory uri = tokenURI(tokenId);
        // burn token
        _burn(tokenId);
        // send transfer message to destination chain
        INFTBridge(nftBridge).sendMsg{value: msg.value}(
            chainId,
            _msgSender(),
            receiver,
            tokenId,
            uri
        );
    }

    /**
     * @notice Cross-chain transfer to specific receiver presented by bytes type, used for non-evm chains
     * @param chainId destination chain that token will be transferred to
     * @param tokenId token will be transferred
     * @param receiver wallet address in destination chain who will receive token
     */
    function crossChain(uint64 chainId, uint256 tokenId, bytes calldata receiver) public payable crossChainEnabled {
        if (_msgSender() != ownerOf(tokenId)) {
            revert CrossChainCallerNotOwner();
        }

        string memory uri = tokenURI(tokenId);
        // burn token
        _burn(tokenId);
        // send transfer message to destination chain
        INFTBridge(nftBridge).sendMsg{value: msg.value}(
            chainId,
            _msgSender(),
            receiver,
            tokenId,
            uri
        );
    }

    /**
     * @notice Estimate fees paid for cross-chain transfer
     * @dev The cBridge website depends on this function
     * @param chainId destination chain id
     * @param tokenId token id
     */
    function totalFee(uint64 chainId, uint256 tokenId) external view crossChainEnabled returns (uint256) {
        return INFTBridge(nftBridge).totalFee(chainId, address(this), tokenId);
    }

    /**
     * @notice Called by nftBridge contract to mint the transferred token from other chain
     * @param to token receiver
     * @param tokenId token id
     */
    function bridgeMint(address to, uint256 tokenId, string memory /* uri */) external onlyNftBridge {
        _safeMint(to, tokenId);
    }
}