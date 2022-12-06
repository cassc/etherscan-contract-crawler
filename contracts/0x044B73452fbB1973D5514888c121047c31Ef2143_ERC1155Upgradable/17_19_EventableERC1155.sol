// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

interface IEventableERC1155 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    // function makeEvents(address[] calldata operators, uint256[] calldata tokenIds, address[] calldata _from, address[] calldata _to, uint256[] calldata amounts) external;
}

abstract contract EventableERC1155 is IEventableERC1155 {
    // function makeEvents(address[] calldata operators, uint256[] calldata tokenIds, address[] calldata _from, address[] calldata _to, uint256[] calldata amounts) public virtual override {
    //     _handleEventOperatorLoops(operators, tokenIds, _from, _to, amounts);
    // }    
    // function _handleEventOperatorLoops(address[] calldata operators, uint256[] calldata tokenIds, address[] calldata _from, address[] calldata _to, uint256[] calldata  amounts) internal {
    //     for (uint i=0; i < operators.length; i++) {
    //         if (amounts.length == operators.length && amounts.length == _from.length && amounts.length == _to.length && amounts.length == tokenIds.length) {
    //             _handleEventEmits(operators[i], tokenIds[i], _from[i], _to[i], makeSingleArray(amounts, i));
    //         } else {
    //             _handleEventTokenIdLoops(operators[i], tokenIds, _from, _to, amounts);
    //         }
    //     }
    // }
    // function _handleEventTokenIdLoops(address operator, uint256[] calldata tokenIds, address[] calldata _from, address[] calldata _to, uint256[] calldata  amounts) internal {
    //     for (uint i=0; i < tokenIds.length; i++) {
    //         if (amounts.length == tokenIds.length && tokenIds.length == amounts.length && _from.length == amounts.length && _to.length == amounts.length) {
    //             _handleEventEmits(operator, tokenIds[i], _from[i], _to[i], makeSingleArray(amounts, i));
    //         } else {
    //             _handleEventFromLoops(operator, tokenIds[i], _from, _to, amounts);
    //         }
    //     }
    // }
    // function _handleEventFromLoops(address operator, uint256 tokenId, address[] calldata _from, address[] calldata _to, uint256[] calldata amounts) internal {
    //     for (uint i=0; i < _from.length; i++) {
    //         if (amounts.length == _from.length && amounts.length == _to.length) {
    //             _handleEventEmits(operator, tokenId, _from[i], _to[i], makeSingleArray(amounts, i));
    //         } else if (amounts.length == _from.length && amounts.length != _to.length) {
    //             _handleEventToLoops(operator, tokenId, _from[i], _to, makeSingleArray(amounts, i));
    //         } else {
    //             _handleEventToLoops(operator, tokenId, _from[i], _to, amounts);
    //         }
    //     }
    // }
    // function _handleEventToLoops(address operator, uint256 tokenId, address _from, address[] calldata _to, uint256[] memory amounts) internal {
    //     for (uint i=0; i < _to.length; i++) {
    //         if (amounts.length == _to.length) {
    //             _handleEventEmits(operator, tokenId, _from, _to[i], makeSingleArray(amounts, i));
    //         } else {
    //             _handleEventEmits(operator, tokenId,_from, _to[i], amounts);
    //         }
    //     }
    // }
    // function _handleEventEmits(address operator, uint256 tokenId, address _from, address _to, uint256[] memory amounts) internal {
    //     for (uint i=0; i < amounts.length; i++) {
    //         emit TransferSingle(operator, _from, _to, tokenId, amounts[i]);
    //     }
    // }
    // function makeSingleArray(uint256[] memory amount, uint index) internal pure returns (uint256[] memory) {
    //     uint256[] memory arr = new uint256[](1);
    //     arr[0] = amount[index];
    //     return arr;
    // }
}