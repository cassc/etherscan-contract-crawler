// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tag.sol";

contract FancyTraitsV2 is Ownable, ERC1155Supply, AccessControlEnumerable {

    using SafeMath for uint256;

    struct Trait {
        string name;
        string category;
        bool set;
    }

    mapping(uint256 => Trait) public traits;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRAIT_EDITOR_ROLE = keccak256("TRAIT_EDITOR");

    event TraitAdded(uint256 indexed _traitId, string _name, string _category);
    event TraitRemoved(uint256 indexed _traitId);

    constructor(string memory _URI) ERC1155(_URI) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function getTrait(uint256 _tokenId) public view returns (string memory, string memory) {
        require(traits[_tokenId].set, "getTrait: trait not set");
        return (
            traits[_tokenId].name, 
            traits[_tokenId].category
        );         
    }

    function addTraits(
        uint256[] calldata _traitIds, 
        string[] calldata _names,
        string[] calldata _categories
    )
        public 
        onlyRole(TRAIT_EDITOR_ROLE) 
    {
        require(
            _traitIds.length == _names.length, 
            "addTraits: traitId and name array must match in length"
        );
        require(
            _traitIds.length == _categories.length, 
            "addTraits: traitId and category array must match in length"
        );
        
        for(uint256 i = 0; i < _traitIds.length; i++){

            require(!traits[_traitIds[i]].set, "addTrait: Trait ID already set");
            require(bytes(_names[i]).length != 0, "addTrait: Name cannot be blank");

            traits[_traitIds[i]] = Trait({
                name: _names[i],
                category: _categories[i],
                set: true
            });

            emit TraitAdded(
                _traitIds[i], 
                 _names[i], 
                 _categories[i]
            );

        }
    }

    function removeTrait(uint256 _traitId) public  onlyRole(TRAIT_EDITOR_ROLE) {
        require(traits[_traitId].set, "removeTrait: Trait ID not set");
        require(totalSupply(_traitId)==0, "removeTrait: Trait ID already minted");
        delete(traits[_traitId]);
        emit TraitRemoved(_traitId);
    }

    function setURI(string memory newuri) public onlyRole(TRAIT_EDITOR_ROLE) {
        _setURI(newuri);
    }

    function mint(address _account, uint256 _id, uint256 _amount, bytes memory _data)
        public
        onlyRole(MINTER_ROLE)
    {
        require(traits[_id].set, "mint: Traits not set for Token ID");
        _mint(_account, _id, _amount, _data);
    }

    function mintBatch(address _account, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
        public
        onlyRole(MINTER_ROLE)
    {
        for(uint256 i = 0; i < _ids.length; i++) {
            require(traits[_ids[i]].set, "mintBatch: Traits not set for Token ID");
            _mint(_account, _ids[i], _amounts[i], _data);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}