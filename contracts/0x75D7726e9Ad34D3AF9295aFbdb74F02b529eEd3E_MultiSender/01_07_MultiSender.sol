// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract MultiSender {
    using SafeERC20 for IERC20;

    bytes private emptyData = bytes("");

    /**
     * @dev Send ETH to multiple accounts.
     *
     * - `_recipients`: list of receiver's address.
     * - `_values`: list of values in wei will be sent.
     */
    function sendETH(address payable[] calldata _recipients, uint256[] calldata _values) external payable {
        require(_recipients.length == _values.length, "MultiSender: _recipients and _values not equal");
        for (uint256 i = 0; i < _recipients.length; i++) {
            (bool sent,) = _recipients[i].call{value : _values[i]}("");
            require(sent, "MultiSender: Failed to send Ether");
        }
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool sent,) = msg.sender.call{value : balance}("");
            require(sent, "MultiSender: Failed to send Ether back");
        }
    }

    /**
     * @dev Send token ERC20 to multiple accounts.
     *
     * - `_tokenAddress`: address of token erc20
     * - `_recipients`: list of receiver's address.
     * - `_values`: list of values in wei will be sent.
     */
    function sendERC20(address _tokenAddress, address[] calldata _recipients, uint256[] calldata _values) external {
        require(_recipients.length == _values.length, "MultiSender: _recipients and _values not equal");
        IERC20 token = IERC20(_tokenAddress);
        for (uint256 i = 0; i < _recipients.length; i++) {
            token.safeTransferFrom(msg.sender, _recipients[i], _values[i]);
        }
    }

    /**
     * @dev Send token ERC20 to multiple accounts.
     *
     * - `_tokenAddress`: address of token erc721
     * - `_recipients`: list of receiver's address.
     * - `_ids`: list of NFT's ID will be sent.
     */
    function sendERC721(address _tokenAddress, address[] calldata _recipients, uint256[] calldata _ids) external {
        require(_recipients.length == _ids.length, "MultiSender: _recipients and _ids not equal");
        IERC721 token = IERC721(_tokenAddress);
        for (uint256 i = 0; i < _recipients.length; i++) {
            token.safeTransferFrom(msg.sender, _recipients[i], _ids[i]);
        }
    }

    /**
     * @dev Send token ERC20 to multiple accounts.
     *
     * - `_tokenAddress`: address of token erc721
     * - `_recipients`: list of receiver's address.
     * - `_ids`: list of NFT's ID will be sent.
     * - `_values`: list of values corresponding to each id
     */
    function sendERC1155(address _tokenAddress, address[] calldata _recipients, uint256[] calldata _ids, uint256[] calldata _values) external {
        require(_recipients.length == _values.length, "MultiSender: _recipients and _values not equal");
        require(_recipients.length == _ids.length, "MultiSender: _recipients and _ids not equal");
        IERC1155 token = IERC1155(_tokenAddress);
        for (uint256 i = 0; i < _recipients.length; i++) {
            token.safeTransferFrom(msg.sender, _recipients[i], _ids[i], _values[i], emptyData);
        }
    }
}