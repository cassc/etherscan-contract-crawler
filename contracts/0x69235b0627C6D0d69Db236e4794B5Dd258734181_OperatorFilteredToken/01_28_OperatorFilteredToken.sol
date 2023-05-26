// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./LockableRevealERC721EnumerableToken.sol";
import "operator-filter-registry/src/IOperatorFilterRegistry.sol";

contract OperatorFilteredToken is LockableRevealERC721EnumerableToken {

    error OperatorNotAllowed(address operator);

    bool                    public OSFiltering = true;
    address                 public DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    IOperatorFilterRegistry public OPERATOR_FILTER_REGISTRY = IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
    uint32         constant public version = 2022120701;

    function setup(TokenConstructorConfig memory config) public virtual override onlyOwner {

        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), DEFAULT_SUBSCRIPTION);
        }
        super.setup(config);
    }

    // Toggle to disable OS filtering
    function toggleOSFilterOperatorState() public onlyOwner() {
        OSFiltering = !OSFiltering;
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) {
        if(OSFiltering) {
            _checkFilterOperator(operator);
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) {
        if(OSFiltering) {
            _checkFilterOperator(operator);
        }
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        if (OSFiltering && from != msg.sender) { _checkFilterOperator(msg.sender); }
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        if (OSFiltering && from != msg.sender) { _checkFilterOperator(msg.sender); }
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) {
        if (OSFiltering && from != msg.sender) { _checkFilterOperator(msg.sender); }
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}