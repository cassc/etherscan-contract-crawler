// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract YelloCollectibles is
    Ownable,
    ERC1155,
    ERC1155Burnable,
    ERC1155Supply,
    ReentrancyGuard,
    DefaultOperatorFilterer,
    ERC2981
{
    string public name;
    string public symbol;

    /**
     * @dev Related to models
     */
    uint256 public modelCounter;
    mapping(uint256 => Model) public models;
    struct Model {
        uint256 partType;
        uint256 requirePartAmount;
        uint256 mintPrice;
        bool craftable;
    }

    /**
     * @dev Parts Contract
     */
    YelloPartsContract public yelloParts;

    /**
     * @dev Craft open or close
     */
    bool public craftOpen;

    /**
     * @dev Mint open or close
     */
    bool public mintOpen;

    constructor(address yelloPartsAddr) ERC1155('') {
        name = "YELLO Collectibles";
        symbol = "YELLO";
        yelloParts = YelloPartsContract(yelloPartsAddr);

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
    }

    /**
     * @dev validates caller is not from contract
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'Caller is contract');
        _;
    }

    /**
     * @dev add models to collection
     */
    function addModel(
        uint256 _partType,
        uint256 _requirePartAmount,
        uint256 _mintPrice,
        bool _craftable
    ) external onlyOwner {
        Model storage ast = models[modelCounter];
        ast.partType = _partType;
        ast.requirePartAmount = _requirePartAmount;
        ast.mintPrice = _mintPrice;
        ast.craftable = _craftable;
        modelCounter++;
    }

    function editModelPartType(uint256 _id, uint256 _partType) external onlyOwner {
        models[_id].partType = _partType;
    }

    function editModelRequirePartAmount(uint256 _id, uint256 _requirePartAmount) external onlyOwner {
        models[_id].requirePartAmount = _requirePartAmount;
    }

    function editModelMintPrice(uint256 _id, uint256 _mintPrice) external onlyOwner {
        models[_id].mintPrice = _mintPrice;
    }

    function editModelCraftable(uint256 _id, bool _craftable) external onlyOwner {
        models[_id].craftable = _craftable;
    }

    /**
     * @dev set parts contract address
     */
    function setYelloPartsAddress(address yelloPartsAddr) external onlyOwner {
        yelloParts = YelloPartsContract(yelloPartsAddr);
    }

    /**
     * @dev set craft open or close
     */
    function setCraftOpen(bool _craftOpen) external onlyOwner {
        craftOpen = _craftOpen;
    }

    /**
     * @dev set mint open or close
     */
    function setMintOpen(bool _mintOpen) external onlyOwner {
        mintOpen = _mintOpen;
    }

    /**
     * @dev Team dev mint
     */
    function devMint(uint256[] calldata ids, uint256[] calldata amounts) external onlyOwner {
        for (uint256 i = 0; i < ids.length; ) {
            require(ids[i] < modelCounter, 'Model not added');

            unchecked {
                ++i;
            }
        }

        _mintBatch(msg.sender, ids, amounts, '');
    }

    /**
     * @dev Public Mint
     */
    function mint(uint256 modelId, uint256 amount) external payable callerIsUser nonReentrant {
        require(mintOpen, 'Mint not open');
        require(models[modelId].mintPrice > 0, 'Mint price 0');
        require(msg.value >= models[modelId].mintPrice * amount, 'Need more ETH');
        require(modelId < modelCounter, 'No such model');

        _mint(msg.sender, modelId, amount, '');
    }

    /**
     * @dev burns parts and craft model
     */
    function craft(uint256[] calldata partIds, uint256 modelId) external callerIsUser nonReentrant {
        require(isValidCraft(partIds, modelId));
        yelloParts.burnBatch(partIds);
        _mint(msg.sender, modelId, 1, '');
    }

    function isValidCraft(uint256[] calldata partIds, uint256 modelId) private view returns (bool) {
        require(craftOpen, 'Craft not open');
        require(modelId < modelCounter, 'No such model');

        Model memory md = models[modelId];
        require(md.craftable, 'Model is not craftable');
        require(partIds.length == md.requirePartAmount, 'Wrong part amount to craft');

        for (uint256 i = 0; i < partIds.length; ) {
            require(yelloParts.getTokenType(partIds[i]) == md.partType, 'Wrong part to craft');
            require(yelloParts.ownerOf(partIds[i]) == msg.sender, 'Do not own token');

            unchecked {
                ++i;
            }
        }

        return true;
    }

    function setBaseURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(_id < modelCounter && totalSupply(_id) > 0, 'URI: nonexistent token');

        return string.concat(super.uri(_id), Strings.toString(_id));
    }

    /**
     * @dev withdraw money to owner
     */
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Transfer failed');
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev For Opensea OperatorFilterer
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
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

    /**
     * @dev For ERC2981
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}

interface YelloPartsContract {
    function burnBatch(uint256[] calldata tokenIds) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function getTokenType(uint256 tokenId) external view returns (uint256);
}