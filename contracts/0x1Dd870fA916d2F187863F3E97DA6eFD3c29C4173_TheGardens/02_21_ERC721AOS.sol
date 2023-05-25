// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC721A.sol";
import "./OperatorFilterer.sol";
import "./lib/Constants.sol";

import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS, CANONICAL_CORI_SUBSCRIPTION} from "./lib/Constants.sol";



abstract contract ERC721AOS is ERC721A, OperatorFilterer, Ownable  {

    error RegistryHasBeenRevoked();
    error OnlyOwner();

    bool isOperatorFilterRegistryRevoked = false;

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true)  {

    }

    /***************************************************************************
     * Operator Filterer
     */

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function enableOperatorFunction(address subscriber) public onlyOwner {
       
        _registerForOperatorFiltering(subscriber, true);

    }

    function disableOperatorFunction(address subscriber) public onlyOwner {
 
        _registerForOperatorFiltering(subscriber, false);

    }

    function disableOperatorFilterer(bool _isDisabled) external onlyOwner {
    isDisabled = _isDisabled;
    }


    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


}