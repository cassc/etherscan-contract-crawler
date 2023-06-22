// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FancyBearTraits is Ownable, ERC1155, AccessControlEnumerable, ERC1155Supply {

    using SafeMath for uint256;

    struct Trait {
        string name;
        string category;
        uint256 honeyConsumptionRequirement;
        bool set;
    }

    mapping(uint256 => Trait) public traits;
    mapping(string => bool) public categoryValidation;
    string[] public categories;
    uint256 public categoryPointer;

    uint256[] private traitTokenIds; 
    uint256 traitTokenIdPointer;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRAIT_EDITOR_ROLE = keccak256("TRAIT_EDITOR");

    event TraitAdded(uint256 indexed _traitId, string _name, string _category, uint256 _honeyConsumptionRequirement);
    event TraitRemoved(uint256 indexed _traitId);
    event CategoryAdded(string _category);

    constructor() ERC1155("https://api-traits.fancybearsmetaverse.com/{id}.json") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function getTrait(uint256 _tokenId) public view returns (string memory, string memory, uint256) {
        require(traits[_tokenId].set, "getTrait: trait not set");
        return (
            traits[_tokenId].name, 
            traits[_tokenId].category, 
            traits[_tokenId].honeyConsumptionRequirement
        );         
    }

    function getCategories() public view returns (string[] memory) {
        return categories;
    }

    function addTrait(
        uint256 _traitId, 
        string calldata _name,
        string calldata _category,
        uint256 _honeyConsumptionRequirement
    ) 
        public 
        onlyRole(TRAIT_EDITOR_ROLE) 
    {
        require(!traits[_traitId].set, "addTrait: Trait ID already set");
        require(categoryValidation[_category], "addTrait: Category not valid");
        require(bytes(_name).length != 0, "addTrait: Name cannot be blank");

        traits[_traitId] = Trait({
            name: _name,
            category: _category,
            honeyConsumptionRequirement: _honeyConsumptionRequirement,
            set: true
        });

        emit TraitAdded(_traitId,  _name, _category, _honeyConsumptionRequirement);
    }

    function addTraits(
        uint256[] calldata _traitIds, 
        string[] calldata _names,
        string[] calldata _categories,
        uint256[] calldata _honeyConsumptionRequirements
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
        require(
            _traitIds.length == _honeyConsumptionRequirements.length,
            "addTraits: traitId and name array must match in length"
        );

        for(uint256 i = 0; i < _traitIds.length; i++){

            require(!traits[_traitIds[i]].set, "addTrait: Trait ID already set");
            require(categoryValidation[_categories[i]], "addTrait: Category not valid");
            require(bytes(_names[i]).length != 0, "addTrait: Name cannot be blank");

            traits[_traitIds[i]] = Trait({
                name: _names[i],
                category: _categories[i],
                honeyConsumptionRequirement: _honeyConsumptionRequirements[i],
                set: true
            });

            emit TraitAdded(
                _traitIds[i], 
                 _names[i], 
                 _categories[i], 
                 _honeyConsumptionRequirements[i]
            );

        }
    }

    function removeTrait(uint256 _traitId) public  onlyRole(TRAIT_EDITOR_ROLE) {
        require(traits[_traitId].set, "removeTrait: Trait ID not set");
        require(totalSupply(_traitId)==0, "removeTrait: Trait ID already minted");
        delete(traits[_traitId]);
        emit TraitRemoved(_traitId);
    }

    function addCategory(string memory _category) public onlyRole(TRAIT_EDITOR_ROLE) {
        require(!categoryValidation[_category], "addCategory: Category already added");
        categoryValidation[_category] = true;
        categories.push(_category);
        categoryPointer++;
        emit CategoryAdded(_category);
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

    function _beforeTokenTransfer(
        address operator, 
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    )
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
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