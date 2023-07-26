// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/IONFT721.sol";
import "./ONFT721Core.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// NOTE: this ONFT contract has no public minting logic.
// must implement your own minting logic in child classes
contract ONFT721 is ONFT721Core, ERC721, IERC721Receiver, IONFT721 {
    constructor(string memory _name, string memory _symbol, address _lzEndpoint)
        ERC721(_name, _symbol)
        ONFT721Core(_lzEndpoint)
    { }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ONFT721Core, ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == type(IONFT721).interfaceId || super.supportsInterface(interfaceId);
    }

    function _debitFrom(address _from, uint16, bytes memory, uint256 _tokenId) internal virtual override {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ONFT721: not owner nor approved");
        require(ERC721.ownerOf(_tokenId) == _from, "ONFT721: incorrect owner");
        _burn(_tokenId);
    }

    function _creditTo(uint16, address _toAddress, uint256 _tokenId) internal virtual override {
        _safeMint(_toAddress, _tokenId);
    }

    function onERC721Received(address _operator, address, uint256, bytes memory)
        public
        virtual
        override
        returns (bytes4)
    {
        // only allow `this` to tranfser token from others
        if (_operator != address(this)) return bytes4(0);
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice Checks if there is a payload waiting to be delivered.
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        return lzEndpoint.hasStoredPayload(_srcChainId, _srcAddress);
    }

    /// @notice Retries to send a payload in case an error occurs on receiving chain.
    /// @dev In case an error occurs on receiving chain, the message is stuck in the pipeline until this function is called.
    /// Reason for message failing once contracts are stet up correctly is usually running out of gas.
    /// retry this message with a higher amount of gas.
    /// Info on retriving stored payload: https://layerzero.gitbook.io/docs/guides/error-messages/storedpayload-detection
    /// @param _srcChainId The source chain ID
    /// @param _srcAddress The source address
    /// @param _payload Message payload. THis can be retrieved from etherscan:
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external payable {
        lzEndpoint.retryPayload(_srcChainId, _srcAddress, _payload);
    }
}