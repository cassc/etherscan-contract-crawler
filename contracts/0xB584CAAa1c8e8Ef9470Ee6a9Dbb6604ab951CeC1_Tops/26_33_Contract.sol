// SPDX-License-Identifier: MIT
/*
 ___   __    ______   _________  ______   ________       __       ________   ___   __    ______      
/__/\ /__/\ /_____/\ /________/\/_____/\ /_______/\     /_/\     /_______/\ /__/\ /__/\ /_____/\     
\  \_\\  \ \\    _\/_\__    __\/\    _\/_\    _  \ \    \ \ \    \    _  \ \\  \_\\  \ \\   _ \ \    
 \   `-\  \ \\ \/___/\  \  \ \   \ \/___/\\  (_)  \ \    \ \ \    \  (_)  \ \\   `-\  \ \\ \ \ \ \   
  \   _    \ \\   ._\/   \  \ \   \  ___\/_\   __  \ \    \ \ \____\   __  \ \\   _    \ \\ \ \ \ \  
   \  \`-\  \ \\ \ \      \  \ \   \ \____/\\  \ \  \ \    \ \/___/\\  \ \  \ \\  \`-\  \ \\ \/  | | 
    \__\/ \__\/ \_\/       \__\/    \_____\/ \__\/\__\/     \_____\/ \__\/\__\/ \__\/ \__\/ \____/_/
 */
pragma solidity ^0.8.15;

import "./lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "./lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "./lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "./lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "./lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";

import { Cans } from "./Cans.sol";
import "./Constants.sol";

contract Tops is ERC1155Burnable, ERC1155Supply, AccessControl, ERC2981, DefaultOperatorFilterer, Ownable {

    address immutable public cansAddress;

    bool public recyclingActive;

    error RecyclingNotActive();
    error NotOwner();
    error NoTokenIds();
    error WithdrawFailed();

    constructor(address cansAddress_, string memory uri) ERC1155(uri) {
        cansAddress = cansAddress_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(Constants.SUPPORT_ROLE, msg.sender);
    }

    function setRecyclingActive(bool recyclingActive_) external onlyRole(Constants.SUPPORT_ROLE) {
        recyclingActive = recyclingActive_;
    }

    function devMint(address to, uint amount, Constants.Tier tier) external onlyRole(Constants.SUPPORT_ROLE) {
        _mint(to, uint(tier), amount, "");
    }

    function recycle(uint canTokenId) external {
        if (!recyclingActive) revert RecyclingNotActive();
        Cans cans = Cans(cansAddress);
        if (cans.ownerOf(canTokenId) != msg.sender) revert NotOwner();
        cans.burn(canTokenId);
        uint8 tier = uint8(cans.canTier(canTokenId));
        _mint(msg.sender, tier, 1, "");
    }

    function recycleBatch(uint[] calldata canTokenIds) external {
        if (!recyclingActive) revert RecyclingNotActive();

        uint i = canTokenIds.length;
        if (i == 0) revert NoTokenIds();

        uint[] memory amounts = new uint[](3);
        Cans cans = Cans(cansAddress);
        uint canId;
        unchecked {
            for (; i != 0; --i) {
                canId = canTokenIds[i - 1];
                if (cans.ownerOf(canId) != msg.sender) revert NotOwner();
                amounts[uint(cans.canTier(canId))]++;
                cans.burn(canId);
            }
        }

        uint[] memory ids = new uint[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        _mintBatch(msg.sender, ids, amounts, "");
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        if (!success) revert WithdrawFailed();
    }

    function setURI(string memory newuri) public onlyRole(Constants.SUPPORT_ROLE) {
        super._setURI(newuri);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /***************************************************************************
     * Operator Filterer
     */

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /***************************************************************************
     * Royalties
     */

    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyRole(Constants.SUPPORT_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyRole(Constants.SUPPORT_ROLE) {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(Constants.SUPPORT_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId)
        external
        onlyRole(Constants.SUPPORT_ROLE)
    {
        _resetTokenRoyalty(tokenId);
    }
}