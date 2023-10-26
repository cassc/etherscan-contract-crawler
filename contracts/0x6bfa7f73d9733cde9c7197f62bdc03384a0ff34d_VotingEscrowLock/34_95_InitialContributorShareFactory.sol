// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "../../../core/emission/libraries/MiningPoolFactory.sol";
import "../../../core/emission/pools/InitialContributorShare.sol";

contract InitialContributorShareFactory is MiningPoolFactory {
    using ERC165Checker for address;
    /*
     *     // copied from openzeppelin ERC1155 spec impl
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    bytes4 public override poolType =
        InitialContributorShare(0).initialContributorShare.selector;

    constructor() MiningPoolFactory() {
        address _controller = address(new InitialContributorShare());
        _setController(_controller);
    }

    function newPool(address _emitter, address _contributionBoard)
        public
        override
        returns (address _pool)
    {
        require(
            _contributionBoard.supportsInterface(_INTERFACE_ID_ERC1155),
            "Not an ERC1155"
        );
        return super.newPool(_emitter, _contributionBoard);
    }
}