// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;
pragma abicoder v2;

interface ERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

struct Execution {
    ERC721Partial nftContract;
    address recipient;
    uint256[] tokenIds;
}

contract BatchTransfer {
    /// @notice Tokens on the given ERC-721 contract are transferred from you to a recipient.
    ///         Don't forget to execute setApprovalForAll first to authorize this contract.
    /// @param  nftContract An ERC-721 contract
    /// @param  recipient     Who gets the tokens?
    /// @param  tokenIds      Which token IDs are transferred?
    function batchTransfer(
        ERC721Partial nftContract,
        address recipient,
        uint256[] calldata tokenIds
    ) external {
        for (uint256 index; index < tokenIds.length; index++) {
            nftContract.transferFrom(msg.sender, recipient, tokenIds[index]);
        }
    }

    function multiBatchTransfer(Execution[] calldata executions) external {
        uint256 executionsLength = executions.length;

        if (executionsLength == 0) revert("No orders to execute");

        for (uint8 i = 0; i < executionsLength; i++) {
            ERC721Partial nftContract = executions[i].nftContract;
            address recipient = executions[i].recipient;
            uint256[] calldata tokenIds = executions[i].tokenIds;

            bytes memory data = abi.encodeWithSelector(
                this.batchTransfer.selector,
                nftContract,
                recipient,
                tokenIds
            );

            (bool success, bytes memory returndata) = address(this).delegatecall(data);
            
            if (success) {
                // return returndata;
            } else {
                if (returndata.length > 0) {
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } 
            }
        }
    }
}