pragma solidity ^0.8.13;

// libs
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';



import "hardhat/console.sol";

contract ArtsyApes is 
    ERC721AUpgradeable, 
    AccessControlUpgradeable, 
    PausableUpgradeable{
    /**
     * Physical item does not exists
     */
    error NonExistentPhysical();

    /**
     * Can't mint provided quantity
     */
    error MaxTokenSupply();
    
    /**
     * Emits when the new physical is created
     */
    event PhysicalCreation(address owner, uint256 pId);

    struct PhysicalInfo {
        // Erc271 ID this physical belongs to
        uint256 tokenId;
        // The owner address of the physical item
        address owner;
        // The name of a product --> Masterpiece or giclee
        string productName;
        // The first generated address of 'SECORA Blockchain' chip
        address nfc;
    }
    
    // =============================================================
    //                        Constants
    // =============================================================

    bytes32 public constant ADMIN = keccak256("ADMIN");

    bytes32 public constant PHYSICAL_ISSUER = keccak256("PHYSICAL_ISSUER");

    // =============================================================
    //                         Storage
    // =============================================================

    // Token limit
    uint256 public MAX_APES;

    // IPFS CID
    string private baseUri;

    // PhysicalInfo by pId
    mapping( uint256 => PhysicalInfo) public physicals;

    // Physical Ids belonging to the specific address
    mapping( address => uint256[]) public pIDsByAddress;

    // Physical Ids belonging to the specific token Id
    mapping( uint256 => uint256[]) public pIDsByTokenId;

    // Physical ID counter
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public physicalItemCount;

    // =============================================================
    //                        Constructor
    // =============================================================

    function initialize(string memory name, string memory symbol, uint256 maxApes) initializerERC721A initializer public {
        MAX_APES = maxApes;
        __ERC721A_init(name, symbol);
        __AccessControl_init();
        AccessControlUpgradeable._setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AUpgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // =============================================================
    //                         Pausable
    // =============================================================

    function pause() whenNotPaused onlyRole(ADMIN) public{
        PausableUpgradeable._pause();
    }

    function unpause() whenPaused onlyRole(ADMIN) public{
        PausableUpgradeable._unpause();
    }

    // =============================================================
    //                         Metadata
    // =============================================================
    function setBaseURI(string memory newBaseUri) onlyRole(ADMIN) public{
        baseUri = newBaseUri;
    }
    
    function _baseURI() override internal view virtual returns (string memory) {
        return baseUri;
    }
    
    // =============================================================
    //                        Token Count
    // =============================================================
    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    // =============================================================
    //                           Mint
    // =============================================================
    function mint(uint256 quantity) onlyRole(ADMIN) whenNotPaused public returns (bool){
        if(ERC721AUpgradeable.totalSupply() + quantity > MAX_APES) revert MaxTokenSupply();
        ERC721AUpgradeable._mint(msg.sender, quantity);
        return true;
    }
    
    // =============================================================
    //                Physical Operations & Queries
    // =============================================================
    function createPhysicalItem(
        uint256 tokenId,
        address owner,
        string memory productName
    ) public onlyRole(PHYSICAL_ISSUER) whenNotPaused{
        physicalItemCount.increment();
        uint256 id = physicalItemCount.current();

        physicals[id] = PhysicalInfo(tokenId, owner, productName, address(0));
        pIDsByAddress[owner].push(id);
        pIDsByTokenId[tokenId].push(id);

        emit PhysicalCreation(owner, id);
    }

    function isPhysicalItemAvailable(
        uint256 tokenId,
        string memory productName,
        uint8 max_items_limit
    ) public view returns (bool){
        if(max_items_limit == 0) return false;
        uint256[] memory pIds = physicalsByTokenId(tokenId);
        uint8 counter;
        for(uint8 it; it < pIds.length; it++){
            PhysicalInfo memory physical = physicalById(pIds[it]);
            if (compareStrings(physical.productName, productName)) {
                counter++;
            }
            if(counter == max_items_limit){
                return false;
            }
        }
        return true;
    }

    function addNFCTag(uint256 pId, address nfcADdress) onlyRole(ADMIN) public{
        if(!_physicalExists(pId)) revert NonExistentPhysical();
        physicals[pId].nfc = nfcADdress;
    }

    function verify (uint256 pId, bytes32 message, uint8 v, bytes32 r, bytes32 s) public view returns (bool){
        bytes memory header = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(header, message));
        address signer = ecrecover(prefixedHashMessage, v, r, s);
        return signer == physicalById(pId).nfc;
    }

    function _physicalExists(uint256 pId) internal view virtual returns (bool) {
        return physicals[pId].owner != address(0);
    }

    function physicalById(uint256 pID) public view returns(PhysicalInfo memory) {
        return physicals[pID];
    }

    function physicalsByAddress(address owner) public view returns (uint256[] memory) {
        return pIDsByAddress[owner];
    }

    function physicalsByTokenId(uint256 tokenId) public view returns (uint256[] memory) {
        return pIDsByTokenId[tokenId];
    }

    // =============================================================
    //                              HELPERS
    // =============================================================
    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));  
    }
}