// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../base/1155/DigitalNFT1155Base.sol";
import "../extensions/DigitalNFTStorage.sol";
import "../extensions/DigitalNFTMintable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/// @notice Developed by DigitalNFT.it (https://digitalnft.it/)
abstract contract DigitalNFT1155Advanced is DigitalNFT1155Base, ERC1155Burnable, ERC1155Supply, DigitalNFTStorage, DigitalNFTMintable {
    
    // ============================== Fields ============================= //

    mapping(uint256 => uint256) private _maxSupplies;


    // ============================= Errors ============================== //

    error supplyError(uint256);


    // ============================ Functions ============================ //

    // ======================== //
    // === Public Functions === //
    // ======================== //

    function publicMint(uint256 tokenID, uint256 amount) external payable {
        _supplyCheck(tokenID, amount);
        _priceCheck(msg.value, tokenID, amount);
        _mint(msg.sender, tokenID, amount, "");
    }

    function publicMintBatch(uint256[] calldata tokenIDs, uint256[] calldata amounts) external payable {
        DigitalNFTUtilities._duplicateCheck(tokenIDs);
        DigitalNFTUtilities._lengthCheck(tokenIDs, amounts);

        _supplyCheckBatch(tokenIDs, amounts);
        _priceCheckBatch(msg.value, tokenIDs, amounts);
        _mintBatch(msg.sender, tokenIDs, amounts, "");
    }

    function getMaxSupply(uint256 tokenID) public view returns(uint256) {
        return _maxSupplies[tokenID];
    }

    // ======================= //
    // === Check Functions === //
    // ======================= //

    function _priceCheck(uint256 value, uint256 tokenID, uint256 amount) private view {
        uint256 price = getPrice(tokenID);
        if(value < price * amount) revert priceError();
    }

    function _priceCheckBatch(uint256 value, uint256[] calldata tokenIDs, uint256[] calldata amounts) private view {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            uint256 tokenID = tokenIDs[i];
            uint256 amount = amounts[i];
            uint256 price = getPrice(tokenID);
            totalPrice += price * amount;
        }
        if(value < totalPrice) revert priceError();
    }

    function _supplyCheck(uint256 tokenID, uint256 amount) private view {
        uint256 maxSupply = getMaxSupply(tokenID);
        uint256 currentSupply = totalSupply(tokenID);
        if(currentSupply + amount > maxSupply) revert supplyError(tokenID);
    }

    function _supplyCheckBatch(uint256[] calldata tokenIDs, uint256[] calldata amounts) private view {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            uint256 tokenID = tokenIDs[i];
            uint256 amount = amounts[i];
            uint256 maxSupply = getMaxSupply(tokenID);
            uint256 currentSupply = totalSupply(tokenID);
            if(currentSupply + amount > maxSupply) revert supplyError(tokenID);
        }
    }


    // ======================= //
    // === Admin Functions === //
    // ======================= //

    function setFields(
        uint256[] calldata tokenIDs,
        uint256[] calldata prices,
        uint256[] calldata maxSupplies, 
        string[] calldata uris
    ) public onlyOwner {
        DigitalNFTUtilities._duplicateCheck(tokenIDs);
        DigitalNFTUtilities._lengthCheck(tokenIDs, prices);
        DigitalNFTUtilities._lengthCheck(tokenIDs, maxSupplies);
        DigitalNFTUtilities._lengthCheck(tokenIDs, uris);

        setPriceBatch(tokenIDs, prices);
        setMaxSupplyBatch(tokenIDs, maxSupplies);
        setUriBatch(tokenIDs, uris);
    }

    function setFieldsAndMintBatch(
        uint256[] calldata tokenIDs, 
        uint256[] calldata prices,
        uint256[] calldata maxSupplies, 
        string[] calldata uris,
        address to,
        uint256[] calldata amounts
    ) external onlyOwner {        
        setFields(tokenIDs, prices, maxSupplies, uris);
        DigitalNFTUtilities._lengthCheck(tokenIDs, amounts);
        adminMintBatch(to, tokenIDs, amounts);
    }

    function adminMint(address account, uint256 id, uint256 amount) public onlyOwner {
        _supplyCheck(id, amount);
        _mint(account, id, amount, "");
    }

    function adminMintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts) public onlyOwner {
        _supplyCheckBatch(ids, amounts);
        _mintBatch(to, ids, amounts, "");
    }

    function setMaxSupply(uint256 tokenID, uint256 supply) external onlyOwner {
        if(_maxSupplies[tokenID] >= supply) revert supplyError(tokenID);
        _maxSupplies[tokenID] = supply;
    }

    function setMaxSupplyBatch(uint256[] calldata tokenIDs, uint256[] calldata supplies) public onlyOwner {
        DigitalNFTUtilities._lengthCheck(tokenIDs, supplies);
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            uint256 tokenID = tokenIDs[i];
            uint256 supply = supplies[i];
            if(_maxSupplies[tokenID] >= supply) revert supplyError(tokenID);
            _maxSupplies[tokenID] = supply;
        }
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenID, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenID, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenID) external onlyOwner {
        _resetTokenRoyalty(tokenID);
    }


    // ========================= //
    // === Ovrride Functions === //
    // ========================= //

    function uri(uint256 tokenID) public view override(ERC1155, DigitalNFT1155Base) returns (string memory) {
        return _uris[tokenID];
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply){
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, DigitalNFT1155Base) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC1155, DigitalNFT1155Base) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId, 
        uint256 amount, 
        bytes memory data
    ) public override(ERC1155, DigitalNFT1155Base) onlyAllowedOperator(from) {
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
    ) public virtual override(ERC1155, DigitalNFT1155Base) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}