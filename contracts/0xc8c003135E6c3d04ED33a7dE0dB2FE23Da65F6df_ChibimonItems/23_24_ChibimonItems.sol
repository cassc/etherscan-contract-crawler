// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {ERC1155} from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import {ERC1155Receiver} from '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol';
import {ERC1155Holder} from '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import {IERC721} from '@openzeppelin/contracts/interfaces/IERC721.sol';
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {OperatorFilterer} from './imports/OperatorFilterer.sol';

    error IncorrectSignature();
    error MaxMintTokensExceeded();
    error MaxEquipsExceeded();
    error NotTheOwnerOfToken();
    error AddressCantBeBurner();
    error CantWithdrawFunds();

contract ChibimonItems is ERC1155, ERC1155Holder, OperatorFilterer, Ownable, ReentrancyGuard, ERC2981 {

    using ECDSA for bytes32;

    struct Item {
        uint256 id;
        uint256 amount;
    }

    address private signer;

    bool public operatorFilteringEnabled;

    mapping(uint256 => uint256) public totalSupply;
    mapping(address => mapping(uint256 => uint256)) public numberMinted;

    mapping(uint256 => mapping(uint256 => uint256)) public trainerEquipment;
    mapping(uint256 => mapping(uint256 => uint256)) public chibimonEquipment;
    uint256[] trainerEquipmentIds;
    uint256[] chibimonEquipmentIds;
    mapping(uint256 => uint256[]) trainerEquipmentTokenIds;
    mapping(uint256 => uint256[]) chibimonEquipmentTokenIds;

    IERC721 public immutable chibimon;
    IERC721 public immutable trainer;
    IERC20 public immutable apeCoin;

    constructor(address chibimonAddress, address trainerAddress, address apeCoinAddress, address signerAddress) ERC1155("https://api.chibimon.xyz/metadata/item/{id}") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);

        signer = signerAddress;
        chibimon = IERC721(chibimonAddress);
        trainer = IERC721(trainerAddress);
        apeCoin = IERC20(apeCoinAddress);
    }

    // events

    event TrainerEquip(
        address indexed owner,
        uint256 trainerId,
        uint256 tokenId,
        uint256 quantity
    );

    event TrainerUnequip(
        address indexed owner,
        uint256 trainerId,
        uint256 tokenId,
        uint256 quantity
    );

    event ChibimonEquip(
        address indexed owner,
        uint256 chibimonId,
        uint256 tokenId,
        uint256 quantity
    );

    event ChibimonUnequip(
        address indexed owner,
        uint256 chibimonId,
        uint256 tokenId,
        uint256 quantity
    );

    event TrainerConsume(
        address indexed owner,
        uint256 trainerId,
        uint256 tokenId,
        uint256 quantity
    );

    event ChibimonConsume(
        address indexed owner,
        uint256 chibimonId,
        uint256 tokenId,
        uint256 quantity
    );

    // public/external functions

    function mint(bytes calldata signature, uint256 priceTotal, uint256[] calldata tokenIds, uint256[] calldata quantities, uint256[] calldata maxMintables) external {
        if( !_verifyMint(msg.sender, priceTotal, tokenIds, maxMintables, signature) ) revert IncorrectSignature();

        for(uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 quantity = quantities[i];
            uint256 maxMintable = maxMintables[i];

            if( numberMinted[msg.sender][tokenId] + quantity > maxMintable ) revert MaxMintTokensExceeded();

            totalSupply[tokenId] += quantity;
            numberMinted[msg.sender][tokenId] += quantity;
        }

        apeCoin.transferFrom(msg.sender, address(this), priceTotal);
        _mintBatch(msg.sender, tokenIds, quantities, "");
    }

    function equipTrainer(bytes calldata signature, uint256 trainerId, uint256[] calldata tokenIds, uint256[] calldata quantities, uint256[] calldata maxEquipables) external nonReentrant {
        if( !_verifyEquip(msg.sender, trainerId, tokenIds, maxEquipables, signature) ) revert IncorrectSignature();
        if( trainer.ownerOf(trainerId) != msg.sender ) revert NotTheOwnerOfToken();

        for(uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 quantity = quantities[i];
            uint256 maxEquipable = maxEquipables[i];

            if( trainerEquipment[trainerId][tokenId] + quantity > maxEquipable ) revert MaxEquipsExceeded();

            _equipTrainer(msg.sender, trainerId, tokenId, quantity);
        }
    }

    function unequipTrainer(uint256 trainerId, uint256[] calldata tokenIds, uint256[] calldata quantities) external nonReentrant {
        if( trainer.ownerOf(trainerId) != msg.sender ) revert NotTheOwnerOfToken();

        for(uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 quantity = quantities[i];

            _unequipTrainer(msg.sender, trainerId, tokenId, quantity);
        }
    }

    function equipChibimon(bytes calldata signature, uint256 chibimonId, uint256[] calldata tokenIds, uint256[] calldata quantities, uint256[] calldata maxEquipables) external nonReentrant {
        if( !_verifyEquip(msg.sender, chibimonId, tokenIds, maxEquipables, signature) ) revert IncorrectSignature();
        if( chibimon.ownerOf(chibimonId) != msg.sender ) revert NotTheOwnerOfToken();

        for(uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 quantity = quantities[i];
            uint256 maxEquipable = maxEquipables[i];

            if( chibimonEquipment[chibimonId][tokenId] + quantity > maxEquipable ) revert MaxEquipsExceeded();

            _equipChibimon(msg.sender, chibimonId, tokenId, quantity);
        }

    }

    function unequipChibimon(uint256 chibimonId, uint256[] calldata tokenIds, uint256[] calldata quantities) external nonReentrant {
        if( chibimon.ownerOf(chibimonId) != msg.sender ) revert NotTheOwnerOfToken();

        for(uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 quantity = quantities[i];

            _unequipChibimon(msg.sender, chibimonId, tokenId, quantity);
        }

    }

    function consumeTrainer(bytes calldata signature, uint256 trainerId, uint256[] calldata tokenIds, uint256[] calldata quantities) external nonReentrant {
        if( !_verifyConsume(msg.sender, trainerId, tokenIds, signature) ) revert IncorrectSignature();
        if( trainer.ownerOf(trainerId) != msg.sender ) revert NotTheOwnerOfToken();

        for(uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 quantity = quantities[i];

            _consumeTrainer(msg.sender, trainerId, tokenId, quantity);
        }
    }

    function consumeChibimon(bytes calldata signature, uint256 chibimonId, uint256[] calldata tokenIds, uint256[] calldata quantities) external nonReentrant {
        if( !_verifyConsume(msg.sender, chibimonId, tokenIds, signature) ) revert IncorrectSignature();
        if( chibimon.ownerOf(chibimonId) != msg.sender ) revert NotTheOwnerOfToken();

        for(uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 quantity = quantities[i];

            _consumeChibimon(msg.sender, chibimonId, tokenId, quantity);
        }
    }

    // public views

    function getTrainerEquipment(uint256 trainerId) public view returns(Item[] memory) {
        return _getTrainerEquipment(trainerId);
    }

    function getChibimonEquipment(uint256 chibimonId) public view returns(Item[] memory) {
        return _getChibimonEquipment(chibimonId);
    }

    // internal functions

    function _verifyMint(address sender, uint256 valueSent, uint256[] calldata tokenIds, uint256[] calldata maxMintables, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(sender, valueSent, tokenIds, maxMintables));
        return signer == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function _verifyEquip(address sender, uint256 nftId, uint256[] calldata tokenIds, uint256[] calldata maxEquipables, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(sender, nftId, tokenIds, maxEquipables));
        return signer == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function _verifyConsume(address sender, uint256 nftId, uint256[] calldata tokenIds, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(sender, nftId, tokenIds));
        return signer == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function _equipTrainer(address sender, uint256 trainerId, uint256 tokenId, uint256 quantity) internal {

        safeTransferFrom(sender, address(this), tokenId, quantity, "");

        trainerEquipment[trainerId][tokenId] += quantity;
        trainerEquipmentIds.push(trainerId);
        trainerEquipmentTokenIds[trainerId].push(tokenId);

        emit TrainerEquip(sender, trainerId, tokenId, quantity);

    }

    function _unequipTrainer(address sender, uint256 trainerId, uint256 tokenId, uint256 quantity) internal {

        uint256 _quantity = quantity;

        if( trainerEquipment[trainerId][tokenId] < _quantity ) {
            _quantity = trainerEquipment[trainerId][tokenId];
        }

        _safeTransferFrom(address(this), sender, tokenId, _quantity, "");
        trainerEquipment[trainerId][tokenId] -= _quantity;

        emit TrainerUnequip(sender, trainerId, tokenId, _quantity);

    }

    function _equipChibimon(address sender, uint256 chibimonId, uint256 tokenId, uint256 quantity) internal {

        safeTransferFrom(sender, address(this), tokenId, quantity, "");

        chibimonEquipment[chibimonId][tokenId] += quantity;
        chibimonEquipmentIds.push(chibimonId);
        chibimonEquipmentTokenIds[chibimonId].push(tokenId);

        emit ChibimonEquip(msg.sender, chibimonId, tokenId, quantity);

    }

    function _unequipChibimon(address sender, uint256 chibimonId, uint256 tokenId, uint256 quantity) internal {

        uint256 _quantity = quantity;

        if( chibimonEquipment[chibimonId][tokenId] < _quantity ) {
            _quantity = chibimonEquipment[chibimonId][tokenId];
        }

        _safeTransferFrom(address(this), sender, tokenId, _quantity, "");
        chibimonEquipment[chibimonId][tokenId] -= _quantity;

        emit ChibimonUnequip(sender, chibimonId, tokenId, _quantity);

    }

    function _consumeTrainer(address sender, uint256 trainerId, uint256 tokenId, uint256 quantity) internal {

        super._burn(sender, tokenId, quantity);
        emit TrainerConsume(sender, trainerId, tokenId, quantity);

    }

    function _consumeChibimon(address sender, uint256 chibimonId, uint256 tokenId, uint256 quantity) internal {

        super._burn(sender, tokenId, quantity);
        emit ChibimonConsume(sender, chibimonId, tokenId, quantity);

    }

    function _getTrainerEquipment(uint256 trainerId) internal view returns(Item[] memory) {
        Item[] memory _trainerEquipment = new Item[](trainerEquipmentTokenIds[trainerId].length);
        uint32 equipmentIndex;

        for( uint256 i; i < trainerEquipmentTokenIds[trainerId].length; i++) {
            _trainerEquipment[equipmentIndex++] = Item(
                trainerEquipmentTokenIds[trainerId][i],
                trainerEquipment[trainerId][trainerEquipmentTokenIds[trainerId][i]]
            );
        }

        return _trainerEquipment;
    }

    function _getChibimonEquipment(uint256 chibimonId) internal view returns(Item[] memory) {
        Item[] memory _chibimonEquipment = new Item[](chibimonEquipmentTokenIds[chibimonId].length);
        uint32 equipmentIndex;

        for( uint256 i; i < chibimonEquipmentTokenIds[chibimonId].length; i++) {
            _chibimonEquipment[equipmentIndex++] = Item(
                chibimonEquipmentTokenIds[chibimonId][i],
                chibimonEquipment[chibimonId][chibimonEquipmentTokenIds[chibimonId][i]]
            );
        }

        return _chibimonEquipment;
    }

    // owner functions

    function airdrop(address[] calldata receivers, uint256 tokenId, uint256 quantity ) external onlyOwner {

        for( uint256 i = 0; i < receivers.length; i++ ) {
            totalSupply[tokenId] += quantity;
            numberMinted[receivers[i]][tokenId] += quantity;

            _mint(receivers[i], tokenId, quantity, "");
        }

    }

    function forceUnequipTrainer(address sender, uint256 trainerId, uint256[] calldata tokenIds, uint256[] calldata quantities) external onlyOwner {

        if( trainer.ownerOf(trainerId) != sender ) revert NotTheOwnerOfToken();

        for(uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 quantity = quantities[i];

            _unequipTrainer(sender, trainerId, tokenId, quantity);
        }

    }

    function forceUnequipChibimon(address sender, uint256 chibimonId, uint256[] calldata tokenIds, uint256[] calldata quantities) external onlyOwner {

        if( chibimon.ownerOf(chibimonId) != sender ) revert NotTheOwnerOfToken();

        for(uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 quantity = quantities[i];

            _unequipChibimon(sender, chibimonId, tokenId, quantity);
        }

    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        super._setURI(newBaseURI);
    }

    function setSigner(address signerAddress) external onlyOwner {
        if( signerAddress == address(0) ) revert AddressCantBeBurner();
        signer = signerAddress;
    }

    function withdrawApe(uint256 amount) external onlyOwner {
        apeCoin.transfer(msg.sender, amount);
    }

    function withdrawEth() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if( !success ) revert CantWithdrawFunds();
    }

    // overrides / royalities

    function setApprovalForAll(address operator, bool approved)
    public
    override
    onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override (ERC1155, ERC2981, ERC1155Receiver)
    returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC1155: 0xd9b67a26
        // - IERC1155MetadataURI: 0x0e89341c
        // - IERC2981: 0x2a55205a
        return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

}