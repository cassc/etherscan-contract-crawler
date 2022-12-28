// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./Admins.sol";
import "./ERC1155.sol";
import "./MultiSigProxy.sol";

// @author: miinded.com

abstract contract ERC1155Multi is ERC1155, ERC2981, MultiSigProxy, ReentrancyGuard, DefaultOperatorFilterer {

    struct Supply{
        uint64 max;
        uint64 minted;
        uint64 burned;
    }

    mapping(uint256 => Supply) public supplies;

    /**
    @dev Verify if the contract is soldout
    */
    modifier notSoldOut(uint256 _id, uint64 _count) {
        require(supplies[_id].minted + _count <= supplies[_id].max, "Sold out!");
        _;
    }

    /**
    @notice Set the max supply of the contract
    @dev only internal, can't be change after contract deployment
    */
    function setSupply(uint256 _id, Supply memory _supply) public onlyOwnerOrAdmins {
        MultiSigProxy.validate("setSupply");

        _setSupply(_id, _supply);
    }

    function _setSupply(uint256 _id, Supply memory _supply) internal {
        supplies[_id] = _supply;
    }

    /**
    @notice Set the base URI for metadata of all tokens
    */
    function setBaseUri(string memory baseURI) public onlyOwnerOrAdmins {
        _setURI(baseURI);
    }

    /**
    @notice Get all ids for a wallet
    @dev This method can revert if the _maxId is > 30000.
        it is not recommended to call this method from another contract.
    */
    function walletOfOwner(address _wallet, uint256 _maxId) public view returns(uint256[] memory){
        uint256[] memory ids = new uint256[](_maxId + 1);
        for(uint256 id = 0; id <= _maxId; id++){
            ids[id] = balanceOf(_wallet, id);
        }
        return ids;
    }

    /**
    @notice Replace ERC1155Enumerable.totalSupply()
    @return The total token available.
    */
    function totalSupply(uint256 _id) public view returns (uint64) {
        return supplies[_id].minted - supplies[_id].burned;
    }

    /**
    @notice Mint the next tokens
    */
    function _mintTokens(address _wallet, uint256 _id, uint64 _count) internal{
        supplies[_id].minted += _count;
        _mint(_wallet, _id, _count, "");
    }

    /**
    @notice Mint the tokens reserved for the team project
    @dev the tokens are minted to the owner of the contract
    */
    function reserve(uint256 _id, uint64 _count) public virtual notSoldOut(_id, _count) onlyOwnerOrAdmins {
        _mintTokens(_msgSender(), _id, _count);
    }

    /**
    @notice Burn the token if is approve or owner
    */
    function burn(uint256 _id, uint64 _count) public virtual {
        supplies[_id].burned += _count;
        _burn(_msgSender(), _id, _count);
    }

    /**
     * @notice Allows the owner to set default royalties following EIP-2981 royalty standard.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwnerOrAdmins {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /**
    @notice Add the Operator filter functions
    */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
    public
    override
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
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}