// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ERC1155.sol";
import "./ExternalContracts.sol";
import "./interfaces/IERC1155Proxy.sol";

abstract contract ERC1155Proxy is ERC1155, IERC1155Proxy, ERC2981, ExternalContracts, DefaultOperatorFilterer {

    constructor(string memory baseURI) ERC1155(baseURI){}

    function mint(address _wallet, uint256 _id, uint256 _count) public override externalContract {
        ERC1155._mint(_wallet, _id, _count, "");
    }

    function mintBatch(address _wallet, uint256[] memory _ids, uint256[] memory _counts) public override externalContract {
        ERC1155._mintBatch(_wallet, _ids, _counts, "");
    }

    function burn(address _wallet, uint256 _id, uint256 _count) public override externalContract {
        ERC1155._burn(_wallet, _id, _count);
    }

    function burnBatch(address _wallet, uint256[] memory _ids, uint256[] memory _counts) public override externalContract {
        ERC1155._burnBatch(_wallet, _ids, _counts);
    }

    /**
    @notice Set the base URI for metadata of all tokens
    */
    function setBaseUri(string memory baseURI) public onlyOwnerOrAdmins {
        _setURI(baseURI);
    }

    /**
     * @notice Allows the owner to set default royalties following EIP-2981 royalty standard.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwnerOrAdmins {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    function supportsInterface(bytes4 _interfaceId) public view virtual override(IERC165, ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /**
    @notice Add the Operator filter functions
    */
    function setApprovalForAll(address operator, bool approved) public override(IERC1155, ERC1155) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
    public
    override(IERC1155, ERC1155)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(IERC1155, ERC1155) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}