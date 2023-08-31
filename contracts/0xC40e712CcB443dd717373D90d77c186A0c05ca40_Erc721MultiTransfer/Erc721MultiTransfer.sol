/**
 *Submitted for verification at Etherscan.io on 2023-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

struct Recipient {
    address to;
    uint256 tokenId;
}

struct exRecipient {
    address tokenAddr;
    uint256 tokenId;
    address to;
}

string constant ERR_EMPTY_RECIPIENTS = "empty recipient list";

contract Erc721MultiTransfer {

    function version() external pure returns (string memory) { return "Erc721MultiTransfer v2"; }

    function multiTransfer(exRecipient[] calldata _recipients) external {
        require(_recipients.length > 0, ERR_EMPTY_RECIPIENTS);

        for (uint16 i = 0; i < _recipients.length; ++i) {
            IERC721(_recipients[i].tokenAddr).safeTransferFrom(msg.sender, _recipients[i].to, _recipients[i].tokenId);
        }
    }

    function multiTransfer(address _token, Recipient[] calldata _recipients) external {
        require(_recipients.length > 0, ERR_EMPTY_RECIPIENTS);

        for (uint16 i = 0; i < _recipients.length; ++i) {
            IERC721(_token).safeTransferFrom(msg.sender, _recipients[i].to, _recipients[i].tokenId);
        }
    }
}