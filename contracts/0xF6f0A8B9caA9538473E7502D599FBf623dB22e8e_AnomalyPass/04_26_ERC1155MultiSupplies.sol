// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./Admins.sol";
import "./ERC1155.sol";

// @author: miinded.com

abstract contract ERC1155Multi is ERC1155, ERC2981, Admins, ReentrancyGuard, DefaultOperatorFilterer {

    struct Supply {
        uint64 max;
        uint64 minted;
        uint64 burned;
        bool paused;
        bool valid;
    }

    Supply[] public supplies;

    mapping(uint256 => bool) burnsPublicDisabled;

    modifier notSoldOut(uint256 _id, uint64 _count) {
        require(isValidSupplyId(_id), "Supply not valid");
        require(supplies[_id].paused == false, "Supply paused");

        require(supplies[_id].minted + _count <= supplies[_id].max, "Sold out!");
        _;
    }

    function isValidSupplyId(uint256 _id) public view returns (bool){
        return supplies.length > _id && supplies[_id].valid;
    }

    function isSoldOut(uint256 _id) public view returns(bool){
        require(isValidSupplyId(_id), "Supply not valid");
        return supplies[_id].minted >= supplies[_id].max;
    }

    function setSupply(uint256 _id, Supply memory _supply) public onlyOwnerOrAdmins {
        require(_supply.valid, "_supply not valid");

        if(supplies.length > _id){
            if (supplies[_id].valid) {
                require(_supply.max <= supplies[_id].max, "Not possible to increase the supply max, only decrease");
                supplies[_id].max = _supply.max;
                return;
            }
        }

        for (uint256 i = supplies.length; i <= _id; i++) {
            supplies.push(Supply(0, 0, 0, false, false));
        }

        supplies[_id] = _supply;
    }

    function pauseSupply(uint256 _id, bool _pause) public onlyOwnerOrAdmins {
        require(isValidSupplyId(_id), "Supply not valid");

        supplies[_id].paused = _pause;
    }

    function setBaseUri(string memory baseURI) public onlyOwnerOrAdmins {
        _setURI(baseURI);
    }

    function walletOfOwner(address _wallet) public view returns (uint256[] memory){
        uint256[] memory ids = new uint256[](supplies.length);
        for (uint256 id = 1; id < supplies.length; id++) {
            ids[id] = balanceOf(_wallet, id);
        }
        return ids;
    }

    function totalSupply(uint256 _id) public view returns (uint64) {
        require(isValidSupplyId(_id), "Supply not valid");
        return supplies[_id].minted - supplies[_id].burned;
    }

    function _mintTokens(address _wallet, uint256 _id, uint64 _count) internal {
        supplies[_id].minted += _count;
        _mint(_wallet, _id, _count, "");
    }

    function reserve(address _to, uint256 _id, uint64 _count) public virtual notSoldOut(_id, _count) onlyOwnerOrAdmins {
        _mintTokens(_to, _id, _count);
    }

    function toggleBurnPublic(uint256 _id, bool _disabled) public onlyOwnerOrAdmins {
        burnsPublicDisabled[_id] = _disabled;
    }

    function burn(uint256 _id, uint64 _count) public virtual {
        require(burnsPublicDisabled[_id] == false, "Burn public is disabled for this _id");

        _burnInternal(_msgSender(), _id, _count);
    }

    function _burnInternal(address _to, uint256 _id, uint64 _count) internal virtual {
        require(isValidSupplyId(_id), "Supply not valid");

        supplies[_id].burned += _count;
        _burn(_to, _id, _count);
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