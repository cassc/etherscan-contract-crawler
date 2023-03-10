// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IMultiWalletCallerOperator.sol";
import "./interface/IMinterChild.sol";
import "./interface/IChildStorage.sol";
import "./interface/ITransferHelper.sol";

contract MultiWalletCallerWithdrawERC721 is Ownable {
    IChildStorage private immutable _ChildStorage;

    constructor(address childStorage_) {
        _ChildStorage = IChildStorage(childStorage_);
    }

    modifier checkId(uint256 _startId, uint256 _endId) {
        IMultiWalletCallerOperator(_ChildStorage.operator()).checkId(_startId, _endId, msg.sender);
        _;
    }

    /**
     * @dev Withdraws multiple ERC721 tokens from a contract by transferring ownership of the tokens to the caller.
     *
     * Requirements:
     * - `_startId` must be less than or equal to `_endId`.
     * - The caller must be approved to transfer each token.
     *
     * @param _startId The starting wallet ID to withdraw.
     * @param _endId The ending wallet ID to withdraw.
     * @param _contract The address of the ERC721 contract to withdraw tokens from.
     * @param _tokenIds The array of token IDs to withdraw, one array for each token owner.
     *                  Each element of `_tokenIds` array contains an array of token IDs owned by a single address.
     */
    function batchWithdrawERC721(
        uint256 _startId,
        uint256 _endId,
        address _contract,
        uint256[][] calldata _tokenIds
    ) external checkId(_startId, _endId) {
        TransferHelperItemsWithRecipient[] memory item = new TransferHelperItemsWithRecipient[](1);
        bytes32 conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;
        address transferHelper = 0x0000000000c2d145a2526bD8C716263bFeBe1A72;
        address conduit = 0x1E0049783F008A0085193E00003D00cd54003c71;

        for (uint256 i = _startId; i <= _endId; ) {
            TransferHelperItem[] memory items = new TransferHelperItem[](_tokenIds[i].length);
            for (uint256 j = 0; j < _tokenIds[i].length;) {
                items[j].itemType = ConduitItemType.ERC721;
                items[j].token = _contract;
                items[j].identifier = _tokenIds[i][j];
                items[j].amount = 1;
                unchecked {
                    j++;
                }
            }
            item[0].items = items;
            item[0].recipient = msg.sender;
            item[0].validateERC721Receiver = true;
            IMinterChild(
                payable(_ChildStorage.child(msg.sender, i))
            ).run_Ozzfvp4CEc(_contract, abi.encodeWithSignature("setApprovalForAll(address,bool)", conduit, true), 0);
            IMinterChild(
                payable(_ChildStorage.child(msg.sender, i))
            ).run_Ozzfvp4CEc(transferHelper, abi.encodeWithSignature("bulkTransfer(((uint8,address,uint256,uint256)[],address,bool)[],bytes32)", item, conduitKey), 0);
            unchecked {
                i++;
            }
        }
    }
}