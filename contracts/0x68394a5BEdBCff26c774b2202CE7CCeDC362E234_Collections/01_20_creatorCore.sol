// SPDX-License-Identifier: AGPLv3"

pragma solidity ^0.8.0;
	

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import './erc1155_base.sol';

contract Collections is Initializable, UUPSUpgradeable {
    address payable private owner;


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    

    // uint private fees = 157500000;
    /*
    ** NftContract For keeping the nft record
    **Collection Name for the Collection name
    **TimeStamp for the time and date when the contract is created
    **NftType is the type of the collection
    */
    struct CollectionsDetails {
        ERC1155Lockable NftContract;
        string CollectionName;
        address CollectionCreatedBy;
    }


    /*
    ** Unique values in the set.
    */
    struct _collectionsD {
        uint[] ids;
    }


    event CollectionCreateEvent(address indexed _CreatedBy, address indexed _collectionAddress, uint id);


    //Keeps the count of the collection created
    uint CollectionCount;

    function initialize() initializer public {
        __UUPSUpgradeable_init();
        owner = payable(0x2265EcB63c1a949Bf71e754b4d7448389badCA2A);

        CollectionCount = 0;

    }

    /*
    ** Hashmap for the address and collection ID.
    ** Data is Mapped/Indexed according to key 'address'
    ** Returns an array of the collection Id created by particular address
    */
    

    mapping(address => _collectionsD ) collectionOwners;
    mapping(address => address) OwnerRole;



    /*
    ** Hashmap for the Collections
    ** Collections is indexed by the collection count.
    ** Returns the Struct/Json with details of the Collection specified in the "CollectionsDetails"
    */
    mapping(uint => CollectionsDetails) public CollectionsRecord;
    function create_collection(string memory name, uint256 supply, bytes calldata uri_, uint256 royaltyValue, string memory contract_Metadata_Uri, address royaltyRecipient) public {
            // require(msg.value >= 0, "Not enough amount for the Fees");
            ERC1155Lockable ERC1155 =new ERC1155Lockable(name,name,contract_Metadata_Uri);
            CollectionsRecord[CollectionCount] = CollectionsDetails(ERC1155, name, msg.sender);
            collectionOwners[address(msg.sender)].ids.push(CollectionCount);
            ERC1155.mint(msg.sender, supply, uri_, royaltyRecipient, royaltyValue);
            // owner.transfer(msg.value);
            CollectionCount += 1;
            OwnerRole[address(ERC1155)] = address(msg.sender);
            emit CollectionCreateEvent(address(msg.sender), address(ERC1155), CollectionCount);
            
            }


    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event in the collection contract.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(ERC1155Lockable Collection, uint256 supply, bytes calldata uri_, uint256 royaltyValue, address royaltyRecipient) external payable {
        require(OwnerRole[address(Collection)] == address(msg.sender), "Only Collection owner is allowed");
        require(msg.value>=157500000,"Bidding value must be greater than the last bid");
        owner.transfer(msg.value);
        Collection.mint(msg.sender, supply, uri_, royaltyRecipient, royaltyValue);
    }


    /*
    ** Getter Function for fetching the details of the collections created by the address or owned by address
    ** Takes the Owner address as an input or arguement 
    ** Returns the array of the collections id's created by the address.
    */
    function collections(address ownedBy)external view returns (_collectionsD memory){
        _collectionsD storage collection_Details = collectionOwners[ownedBy];
        return collection_Details;
    }
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}