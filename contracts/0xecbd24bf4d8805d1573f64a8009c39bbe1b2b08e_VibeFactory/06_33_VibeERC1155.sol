// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@rari-capital/solmate/src/tokens/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract VibeERC1155 is ERC1155, Ownable, IMasterContract, DefaultOperatorFilterer {

    string public _uri;

    function uri(uint256 /*id*/) public view override returns (string memory) {
        return _uri;
    }

    function init(bytes calldata data) public payable override {
        (string memory uri_) = abi.decode(data, (string));
        require(bytes(_uri).length == 0 && bytes(uri_).length != 0);
        _uri = uri_;
        _transferOwnership(msg.sender);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external onlyOwner {
        _mint(account, id, amount, data);
    }

    function batchMint(address to, uint256 fromId, uint256 toId, uint256 amount, bytes memory data) external onlyOwner {
        for (uint256 id = fromId; id <= toId; id++) {
            _mint(to, id, amount, data);
        }
    }

     /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes calldata data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

}