//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/**

`7MM"""YMM   .M"""bgd `7MN.   `7MF'`YMM'   `MP'
  MM    `7  ,MI    "Y   MMN.    M    VMb.  ,P
  MM   d    `MMb.       M YMb   M     `MM.M'
  MMmmMM      `YMMNq.   M  `MN. M       MMb
  MM   Y  , .     `MM   M   `MM.M     ,M'`Mb.
  MM     ,M Mb     dM   M     YMM    ,P   `MM.
.JMMmmmmMMM P"Ybmmd"  .JML.    YM  .MM:.  .:MMa.

powered by ctor.xyz

 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "closedsea/src/OperatorFilterer.sol";

contract Codec is Ownable, ERC1155, ERC1155Burnable, ERC2981, OperatorFilterer {
    address public immutable recoder;

    error NotRecoder();

    modifier onlyRecoder() {
        if (msg.sender != recoder) {
            revert NotRecoder();
        }
        _;
    }

    constructor(address recoder_)
        ERC1155("ipfs://QmNyuN5HZxUQjMQViT61PeTMkbRxetJvE2mQyZisS48UZA")
    {
        recoder = recoder_;

        _setDefaultRoyalty(
            address(0xd188Db484A78C147dCb14EC8F12b5ca1fcBC17f5),
            750
        );

        _registerForOperatorFiltering();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function mint(address to, uint256 quantity) external onlyRecoder {
        _mint(to, 0, quantity, "");
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}