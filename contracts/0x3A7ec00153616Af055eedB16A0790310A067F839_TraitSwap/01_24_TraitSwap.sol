// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IFancyTraitsV2.sol";
import "./interfaces/IFancyBearTraits.sol";
import "./interfaces/IFancy721.sol";
import "./interfaces/IFancyTraitCategories.sol";
import "./interfaces/IFancyBearStaking.sol";
import "./Tag.sol";

contract TraitSwap is ERC1155Holder, AccessControlEnumerable {
    
    struct Trait {
        address traitContract;
        uint256 traitId;
    }

    enum State {
        Off,
        On
    }

    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    EnumerableSet.AddressSet private approvedCollections;
    EnumerableSet.AddressSet private approvedTraitContracts;

    IFancyBearTraits public fancyTraitContract;
    IFancyTraitCategories public fancyTraitCategories;
    IFancyBearStaking public fancyBearStakingContract;
    address fancyBearContract;

    mapping(address => mapping(uint256 => mapping(string => Trait)))
        public traitsByCategoryByTokenByCollection;

    State public state;

    event TraitStaked(
        address indexed _collection,
        uint256 indexed _tokenId,
        address _traitContract,
        uint256 indexed _traitId,
        string _category,
        address _sender
    );
    event TraitUnstaked(
        address indexed _collection,
        uint256 indexed _tokenId,
        uint256 indexed _traitId,
        string _category,
        address _sender
    );
    event TraitSwapped(
        address indexed _collection,
        uint256 indexed _tokenId,
        string _category,
        uint256 _oldTraitId,
        address _oldTraitContract,
        uint256 _newTraitId,
        address _newTraitContract,
        address _sender
    );

    event CollectionAdded(address indexed _collection);
    event TraitContractAdded(address indexed _traitContract);
    event StateChanged(State _state);

    constructor(
        IFancyBearTraits _fancyTraitContract,
        IFancyTraitCategories _fancyTraitCategories,
        IFancyBearStaking _fancyBearStakingContract,
        address _fancyBearContract
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        fancyTraitContract = _fancyTraitContract;
        fancyTraitCategories = _fancyTraitCategories;
        fancyBearStakingContract = _fancyBearStakingContract;
        fancyBearContract = _fancyBearContract;
        state = State.On;
    }

    function stakeTraits(
        address[] calldata _collections,
        uint256[] calldata _tokenIds,
        address[] calldata _traitContracts,
        uint256[][] calldata _traitIds
    ) public {

        require(state == State.On, "stakeTraits: state must be on in order to stake traits");

        uint256 expectedLength = _collections.length;

        require(
            _tokenIds.length == expectedLength,
            "stakeTraits: tokenIds array size mismatch"
        );

        require(
            _traitContracts.length == expectedLength,
            "stakeTraits: traitCollection array size mismatch"
        );

        require(
            _traitIds.length == expectedLength,
            "stakeTraits: traitIds array size mismatch"
        );

        for (uint256 i = 0; i < expectedLength; i++) {

            require(
                isCollectionApproved(_collections[i]),
                "stakeTraits: collection not approved"
            );

            if(_collections[i] == fancyBearContract){
                require(
                    IERC721Enumerable(_collections[i]).ownerOf(_tokenIds[i]) == msg.sender ||
                    fancyBearStakingContract.getOwnerOf(_tokenIds[i]) == msg.sender,
                    "stakeTraits: caller does not own token on collection"
                );
            } 
            else {
                require(
                    IERC721Enumerable(_collections[i]).ownerOf(_tokenIds[i]) == msg.sender,
                    "stakeTraits: caller does not own token on collection"
                );
            }

            require(
                _traitContracts[i] == address(fancyTraitContract) ||
                isTraitContractApproved(_traitContracts[i]),
                "stakeTraits: trait contract not approved"
            );
            

            string memory category;

            for (uint256 j = 0; j < _traitIds[i].length; j++) {
                require(
                    IERC1155(_traitContracts[i]).balanceOf(msg.sender, _traitIds[i][j]) >
                        0,
                    "stakeTraits: caller does not own trait"
                );

                if (_traitContracts[i] == address(fancyTraitContract)) {
                    (, category, ) = fancyTraitContract.getTrait(
                        _traitIds[i][j]
                    );
                } else {
                    (, category) = IFancyTraitsV2(_traitContracts[i]).getTrait(
                        _traitIds[i][j]
                    );
                }

                require(
                    fancyTraitCategories.categoryApprovedByCollection(_collections[i], category),
                    "stakeTraits: category not approved for collection"
                );

                Trait memory currentTrait = traitsByCategoryByTokenByCollection[
                    _collections[i]
                ][_tokenIds[i]][category];

                if (currentTrait.traitContract != address(0)) {
                    IERC1155(currentTrait.traitContract).safeTransferFrom(
                        address(this),
                        msg.sender,
                        currentTrait.traitId,
                        1,
                        ""
                    );

                    delete (
                        traitsByCategoryByTokenByCollection[_collections[i]][
                            _tokenIds[i]
                        ][category]
                    );
                }

                IERC1155(_traitContracts[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _traitIds[i][j],
                    1,
                    ""
                );

                traitsByCategoryByTokenByCollection[_collections[i]][
                    _tokenIds[i]
                ][category] = Trait({
                    traitContract: _traitContracts[i],
                    traitId: _traitIds[i][j]
                });

                if (currentTrait.traitContract == address(0)) {
                    emit TraitStaked(
                        _collections[i],
                        _tokenIds[i],
                        _traitContracts[i],
                        _traitIds[i][j],
                        category,
                        msg.sender
                    );
                } else {
                    emit TraitSwapped(
                        _collections[i],
                        _tokenIds[i],
                        category,
                        currentTrait.traitId,
                        currentTrait.traitContract,
                        _traitIds[i][j],
                        _traitContracts[i],
                        msg.sender
                    );
                }
            }
        }
    }

    function unstakeTraits(
        address _collection,
        uint256 _tokenId,
        string[] calldata _categoriesToUnstake
    ) public {

        if(_collection == fancyBearContract){
            require(
                IERC721Enumerable(_collection).ownerOf(_tokenId) == msg.sender ||
                fancyBearStakingContract.getOwnerOf(_tokenId) == msg.sender,
                "unstakeTraits: caller does not own token on collection"
            );
        } 
        else {
            require(
            IERC721Enumerable(_collection).ownerOf(_tokenId) == msg.sender,
            "unstakeTraits: caller does not own token on collection"
        );
        }

        Trait memory currentTrait;

        for (uint256 i = 0; i < _categoriesToUnstake.length; i++) {
            currentTrait = traitsByCategoryByTokenByCollection[_collection][
                _tokenId
            ][_categoriesToUnstake[i]];

            require(
                currentTrait.traitContract != address(0),
                "unstakeTraits: no trait staked in category"
            );

            IERC1155(currentTrait.traitContract).safeTransferFrom(
                address(this),
                msg.sender,
                currentTrait.traitId,
                1,
                ""
            );
            delete (
                traitsByCategoryByTokenByCollection[_collection][_tokenId][
                    _categoriesToUnstake[i]
                ]
            );

            emit TraitUnstaked(
                _collection,
                _tokenId,
                currentTrait.traitId,
                _categoriesToUnstake[i],
                msg.sender
            );
        }
    }

    function getStakedTraits(address _collection, uint256 _tokenId)
        public
        view
        returns (string[] memory, Trait[] memory)
    {

        string[] memory categories = fancyTraitCategories.getCategoriesByCollection(_collection);

        Trait[] memory traitArray = new Trait[](categories.length);

        for (uint256 i = 0; i < traitArray.length; i++) {
            traitArray[i] = traitsByCategoryByTokenByCollection[
                    _collection
                ][_tokenId][categories[i]];
        }
        return (categories, traitArray);
    }

    function addCollection(address _collection) public onlyRole(MANAGER_ROLE) {
        approvedCollections.add(_collection);
        emit CollectionAdded(_collection);
    }

    function changeState(State _state) public onlyRole(MANAGER_ROLE) {
        require(state != _state, "changeState: no state change requested");
        state = _state;
        emit StateChanged(_state);
    }

    function getApprovedCollection() public view returns (address[] memory) {
        return approvedCollections.values();
    }

    function isCollectionApproved(address _address) public view returns (bool) {
        return approvedCollections.contains(_address);
    }

    function addTraitContract(address _traitContract)
        public
        onlyRole(MANAGER_ROLE)
    {
        approvedTraitContracts.add(_traitContract);
        emit TraitContractAdded(_traitContract);
    }

    function getApprovedTraitContracts()
        public
        view
        returns (address[] memory)
    {
        return approvedTraitContracts.values();
    }

    function isTraitContractApproved(address _address)
        public
        view
        returns (bool)
    {
        return approvedTraitContracts.contains(_address);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Receiver, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}