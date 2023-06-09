// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721BridgableParent.sol";
import "./interfaces/IBeforeTokenTransferHandler.sol";

/** @title Pirate NFTs on L1 */
contract PirateNFTParent is ERC721BridgableParent, Ownable {
    /// @notice Current metadata URI for the contract
    string private _contractURI;

    /// @notice Reference to the handler contract for transfer hooks
    address public beforeTokenTransferHandler;

    /** Events */

    /// @notice Emitted when contractURI has changed
    event ContractURIUpdated(string uri);

    /** Constructor */
    constructor(uint256 maxSupply)
        ERC721BridgableParent("Pirate", "PIRATE", maxSupply)
    {
        // Do nothing
    }

    /**
     * Sets the current contractURI for the contract
     *
     * @param _uri New contract URI
     */
    function setContractURI(string calldata _uri) public onlyOwner {
        _contractURI = _uri;
        emit ContractURIUpdated(_uri);
    }

    /**
     * @return Contract metadata URI for the NFT contract, used by NFT marketplaces to display collection inf
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * Sets the before token transfer handler
     *
     * @param handlerAddress  Address to the transfer hook handler contract
     */
    function setBeforeTokenTransferHandler(address handlerAddress)
        external
        onlyOwner
    {
        beforeTokenTransferHandler = handlerAddress;
    }

    /**
     * @notice Handles any pre-transfer actions
     * @inheritdoc ERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (beforeTokenTransferHandler != address(0)) {
            IBeforeTokenTransferHandler handlerRef = IBeforeTokenTransferHandler(
                    beforeTokenTransferHandler
                );
            handlerRef.beforeTokenTransfer(
                address(this),
                _msgSender(),
                from,
                to,
                tokenId
            );
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }
}