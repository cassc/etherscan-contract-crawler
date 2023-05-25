// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ForjTreasuryLogic} from "contracts/utils/ForjTreasuryLogic.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract ForjERC1155 is ERC1155, Ownable, DefaultOperatorFilterer, ForjTreasuryLogic {

    using Strings for uint256;

    string public name;
    string public symbol;
    string public baseURI;
    bool public erc1155Initialized;

    event TokenBurn(uint256[] indexed _tokenIds, uint256[] indexed _amounts, address indexed _user);
    event BatchMint(address indexed user, uint256[] indexed _ids, uint256[] indexed _amounts);

    mapping(uint256 => Supply) public supplyPerId;

    struct Supply {
        uint256 max;
        uint256 total;
    }

    constructor() ERC1155(""){}

    function _erc1155Initializer(
        string memory _baseURI,
        string memory _name,
        string memory _symbol
    ) internal {
        if(erc1155Initialized) revert AlreadyInitialized();

        baseURI = _baseURI;
        name = _name;
        symbol = _symbol;

        erc1155Initialized = true;
    }

    function setName(string memory _name) public onlyAdminOrOwner(msg.sender){
        name = _name;
    }

    function setSymbol(string memory _symbol) public onlyAdminOrOwner(msg.sender){
        symbol = _symbol;
    }

    function setTokenIdMaxSupply(uint256 _tokenId, uint256 _maxSupply) public onlyAdminOrOwner(msg.sender) {
        if (supplyPerId[_tokenId].total > _maxSupply) revert TotalSupplyGreaterThanMaxSupply();
        supplyPerId[_tokenId].max = _maxSupply;
    }

    function setBaseURI(string memory _baseURI) public onlyAdminOrOwner(msg.sender) {
        baseURI = _baseURI;
    }

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public {
        if(ids.length != amounts.length) revert ArrayLengthsDiffer();
        if(from != msg.sender) revert MsgSenderIsNotOwner();

        uint256 length = ids.length;

        for(uint256 i=0; i < length; i++){
            _burn(from, ids[i], amounts[i]);
            supplyPerId[ids[i]].total -= amounts[i];
        }

        emit TokenBurn(ids, amounts, from);
    }

    function burn(address from, uint256 id, uint256 amount) public {
        if(from != msg.sender) revert MsgSenderIsNotOwner();

        _burn(from, id, amount);
    }

    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyAdminOrOwner(msg.sender) {

        uint256 length = ids.length;

        for(uint256 i; i < length; i++){
            if(supplyPerId[ids[i]].total + amounts[i] > supplyPerId[ids[i]].max) revert TotalSupplyGreaterThanMaxSupply();
            supplyPerId[ids[i]].total += amounts[i];
        }
        super._mintBatch(to, ids, amounts, data);

        emit BatchMint(to, ids, amounts);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        if(supplyPerId[id].total + amount > supplyPerId[id].max) revert TotalSupplyGreaterThanMaxSupply();
        supplyPerId[id].total += amount;
        super._mint(to, id, amount, data);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override virtual onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) public override virtual onlyAllowedOperatorApproval(from) {
        super.safeBatchTransferFrom(from, to, tokenIds, amounts, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override virtual onlyAllowedOperatorApproval(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns(bool){
        return super.supportsInterface(interfaceId);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
}