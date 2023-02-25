// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.17;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./OperatorFilter/OperatorFiltererUpgradeable.sol";
import "./OperatorFilter/Constants.sol";

contract Relic is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    OperatorFiltererUpgradeable
{
    string public baseURI;

    /**
     * instantiates contract
     * @param _b baseURI of metadata
   */
    function initialize(string memory _b) external initializer {
        __Ownable_init();
        __ERC721_init("Wolf Game Relic", "WRELIC");

        baseURI = _b;
    }

    function mint(uint256 tokenId, address recipient) external onlyOwner {
        _mint(recipient, tokenId);
    }

    /**
     * overrides base ERC721 implementation to return back our baseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * sets the root IPFS folder of the metadata
     * @param _b the root folder
   */
    function setBaseURI(string calldata _b) external onlyOwner {
        baseURI = _b;
    }

    //operator-filter-registry
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilterer() external onlyOwner {
        OperatorFiltererUpgradeable.__OperatorFilterer_init(CANONICAL_CORI_SUBSCRIPTION, true);
    }
}