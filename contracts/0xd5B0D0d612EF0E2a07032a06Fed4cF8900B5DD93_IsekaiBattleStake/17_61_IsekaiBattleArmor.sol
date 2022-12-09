// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import {AccessControlEnumerable} from '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import './interface/IIsekaiBattleArmor.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract IsekaiBattleArmor is
    ERC1155Burnable,
    AccessControlEnumerable,
    Ownable,
    IIsekaiBattleArmor,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');
    bytes32 public constant INFO_SETTER_ROLE = keccak256('INFO_SETTER_ROLE');
    string public constant name = 'Isekai Battle Armor';
    string public constant symbol = 'AMR';

    IIsekaiBattle public override ISB;

    ArmorInfo[] public override ArmorInfos;

    constructor(string memory _uri, IIsekaiBattle _ISB) ERC1155(_uri) {
        ISB = _ISB;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        _setupRole(INFO_SETTER_ROLE, _msgSender());
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function burnAdmin(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override onlyRole(BURNER_ROLE) {
        _burn(account, id, value);
    }

    function burnBatchAdmin(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override onlyRole(BURNER_ROLE) {
        _burnBatch(account, ids, values);
    }

    function addArmorInfo(ArmorInfo memory info) public virtual override onlyRole(INFO_SETTER_ROLE) {
        ArmorInfos.push(info);
    }

    function setArmorInfo(uint256 index, ArmorInfo memory info) public virtual override onlyRole(INFO_SETTER_ROLE) {
        ArmorInfos[index] = info;
    }

    function getArmorInfosLength() public virtual override returns (uint256) {
        return ArmorInfos.length;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        ArmorInfo memory info = ArmorInfos[tokenId];
        string memory armorType = ISB.staticData().armorTypeText(info.armorType);

        bytes memory dataURI = abi.encodePacked(
            '{"name": "',
            armorType,
            ' Lv',
            info.level.toString(),
            '","description": "Armor used for defending against attacks from other players in the fully on-chain game \\"Isekai Battle\\".  \\n  \\nIsekai Battle (https://isekai-battle.xyz/)","image": "',
            info.image,
            '","attributes": [{"trait_type":"Lv","value":',
            info.level.toString(),
            '},{"trait_type":"Type","value":"',
            armorType,
            '"}]}'
        );

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(dataURI)));
    }

    function balanceOfAll(address account) public view virtual returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < ArmorInfos.length; i++) {
            count += balanceOf(account, i);
        }
        return count;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
}