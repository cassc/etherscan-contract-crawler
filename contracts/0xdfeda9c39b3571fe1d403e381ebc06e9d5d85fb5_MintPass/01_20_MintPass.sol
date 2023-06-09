// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

// Afterparty MintPass allows buying of a pass to access the IRL mint of your Afterparty Utopian.


// Truffle imports
//import "../openzeppelin-contracts/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
//import "../openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
//import "../openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";

// Remix imports
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Audits
// Last passed audits
// Mythrill: 5, 11/22/2021
// MythX:
// Optilistic :

contract MintPass is ERC1155PresetMinterPauser {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeMath for uint;

    /***********************************|
    |        Structs                    |
    |__________________________________*/
    struct WhitelistAddresses {
        mapping(address => uint256) whitelist;
    }

    struct Collection {
        bytes32 name;   // short name (up to 32 bytes)
        uint16 collectionType;
        string uri;
        uint cost;
        bool mintPassOpenToPublic;
        bool mintNftOpenToPublic;
        uint256 totalMintCount;
        uint256 remaingMintCount;
        uint16 artistPayablePercent;
        address artistPayableAddress;
        address nftContractAddress;
        // NOTE: in whitelist mappings, uint = remaining_mint_count
        mapping(address => uint) whitelistPass;
        mapping(address => uint) whitelistNft;
    }

    struct Pass {
        uint256 collectionId;
        uint sale_price;
    }


    /***********************************|
    |        Variables and Constants    |
    |__________________________________*/
    bytes32 public constant EVENT_MANAGER_ROLE = keccak256("EVENT_MANAGER_ROLE");

    string public name;
    string public symbol;
    address public nftContractAddress;
    uint256 public numCollections;
    mapping (uint256 => Collection) public collections;

    uint16 public build = 14;
    uint256 public tokenCount = 0;

    // For Minting and Burning, locks the functions
    bool private _enabled = true;
    // For metadata (scripts), when locked, cannot be changed
    bool private _locked = false;

    bytes4 constant public ERC1155_ACCEPTED = 0xf23a6e61;

    address payable public contract_owner;

    mapping(uint256 => address) public tokenToAddress;

    Pass[] public passes;


    /***********************************|
    |        Events                     |
    |__________________________________*/
    /**
     * @dev Emitted when an original NFT with a new seed is minted
     */
    event evtPassMinted(address _seller, address _buyer, uint256 _price);
    event evtMintFromPass(bool success, bytes data, uint _id);
    event evtPassMintedBatch(address _seller, address _buyer, bytes data, uint count);

    /***********************************|
    |        Errors                     |
    |__________________________________*/
    error errNftMintFailed(bytes data);

    /***********************************|
    |        Modifiers                  |
    |__________________________________*/
    modifier onlyWhenEnabled() {
        require(_enabled, "Contract is disabled");
        _;
    }
    modifier onlyWhenDisabled() {
        require(!_enabled, "Contract is enabled");
        _;
    }
    modifier onlyUnlocked() {
        require(!_locked, "Contract is locked");
        _;
    }

    modifier ownerorWhitelistOnly() {
        require(contract_owner == msg.sender);
        _;
    }



    /***********************************|
    |        MAIN CONSTRUCTOR           |
    |__________________________________*/
    constructor() ERC1155PresetMinterPauser("https://nft.afterparty.ai/nft_metadata/0/{id}.json") {
        contract_owner = payable(msg.sender);
        name = "Afterparty MintPass";
        symbol = "APMP";
        // TODO: For testing -- Afterparty Pass collection
        //createCollection(0x4166746572706172747920506173730000000000000000000000000000000000, 1, 100, "https://nft.afterparty.ai/nft_collection_metadata/0.json", 1500, 90, contract_owner);
    }

    /***********************************|
    |        User Interactions          |
    |__________________________________*/
    /**
     * @dev Function to mint pass. Msg.value must have sufficient eth for collection item
     */
    function mintPass(address _to, uint256 collectionId, bytes memory _data) public payable onlyWhenEnabled {
        require(collections[collectionId].remaingMintCount > 0, "AP: No remaining passes to mint");

        require(msg.value >= collections[collectionId].cost, "AP: Not enough value to mint");
        require(
            hasRole(MINTER_ROLE, _msgSender()) || collections[collectionId].whitelistPass[msg.sender] > 0 || collections[collectionId].mintPassOpenToPublic,
            "Only contract owner or whitelist can mint."
        );
        // Decrement remaining available mintables
        collections[collectionId].remaingMintCount--;

        _mint(_to, tokenCount, 1, _data);

        // Subtract from the number that can be minted from that address
        if(!collections[collectionId].mintPassOpenToPublic) {
            if(!hasRole(MINTER_ROLE, _msgSender())) {
                collections[collectionId].whitelistPass[msg.sender]--;
            }
        }
        // Set the ownership of this token to sender
        tokenToAddress[tokenCount] = _to;
        // Push associated data for mint to NFT array
        passes.push(Pass({
            collectionId:  collectionId,
            sale_price: msg.value
        }));

        // Split minting value
        uint artistFraction = 90;
        uint artistTotal = (collections[collectionId].cost * artistFraction) / 100;
        uint apTotal = msg.value - artistTotal;
        address artistAddress = collections[collectionId].artistPayableAddress;
        payable(contract_owner).transfer(apTotal); // send the ETH to the Afterparty wallet
        payable(artistAddress).transfer(artistTotal); // send the ETH to the Artist wallet

        // Increment token count
        tokenCount++;

        // Emit minted event
        emit evtPassMinted(contract_owner, msg.sender, msg.value);
    }

    function mintPassBatch(address _to, uint256 collectionId, bytes memory _data, uint count) public onlyWhenEnabled {
        // TODO: Get remaining mint count function
        require(collections[collectionId].remaingMintCount > count, "AP: Not enough remaining passes to mint");

        require( hasRole(MINTER_ROLE, _msgSender()), "Only minter can batch mint." );
        // Decrement remaining available mintables
        collections[collectionId].remaingMintCount -= count;

        uint[] memory ids = new uint[](count);
        uint[] memory amounts = new uint[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenCount+i;
            amounts[i] = 1;
            tokenToAddress[tokenCount+i] = _to;
            // Push associated data for mint to NFT array
            passes.push(Pass({
                collectionId:  collectionId,
                sale_price: 0
            }));
        }
        _mintBatch(_to, ids, amounts, _data);
        // Increment token count
        tokenCount += count;

        // Emit minted event
        emit evtPassMintedBatch(_to, msg.sender, _data, count);
    }

    function nftUri() public pure returns (string memory) {
        string memory baseMetadataURI = "https://afterparty.ai/nft_metadata/0/{id}.json";
        return baseMetadataURI;
    }

    // Check code _burn to make sure it reverts -- otherwise check for burn success
    // Reentrancy Guard code to prevent -- https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol


    function mintToNftContract(uint256 _passId) public onlyWhenEnabled {
        // Check if the pass is valid
        require(_passId < passes.length, "AP: Pass not found");
        // Check if you own that mint pass by balance
        require(balanceOf(msg.sender, _passId) > 0, "AP: Pass balance 0");
        // Make sure a valid NFT contract is associated with collection
        uint256 collectionId = passes[_passId].collectionId;
        address callableNftContractAddress = collections[collectionId].nftContractAddress;
        require(callableNftContractAddress != 0x0000000000000000000000000000000000000000, "AP: Invalid NFT contract address");
        // Make sure the minter is an admin, on the whitelist, or minting is open
        require(
            hasRole(MINTER_ROLE, _msgSender()) || collections[collectionId].whitelistNft[msg.sender] > 0 || collections[collectionId].mintNftOpenToPublic,
            "Only contract owner or whitelist can mint."
        );

        // Burn pass
        _burn(msg.sender, _passId, 1);
        // If pass is valid, mint NFT on NFT contract
        (bool success, bytes memory data) = callableNftContractAddress.call(abi.encodeWithSignature("mintFromPass(address)", msg.sender));
        // Verify success
        if(!success) {
            revert errNftMintFailed({
                    data: data
                });
        }
        // Emit successful minting event
        emit evtMintFromPass(success, data, _passId);
    }
    /***********************************|
    |        Admin                      |
    |__________________________________*/

    // Examples names:
    // Fernickle           = 0x4665726e69636b6c650000000000000000000000000000000000000000000000
    // Afterparty Utopians = 0x416674657270617274792055746f7069616e7300000000000000000000000000
    // Afterparty Pass     = 0x4166746572706172747920506173730000000000000000000000000000000000

    /**
     * @dev Create a collection of mint passes
     * @param _name Name of the collection
     * @param _collectionType Type of collection
     * @param _cost Cost per pass
     * @param _uri URI of collection
     * @param _remaingMintCount Number of passes remaining available to mint
     * @param _artistPayablePercent Percent of collection funds that go to artist
     * @param _artistPayableAddress Artist wallet that receives percentage of funds
     */
    function createCollection (bytes32 _name, uint16 _collectionType, uint256 _cost, string memory _uri, uint256 _remaingMintCount, uint16 _artistPayablePercent, address _artistPayableAddress) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "AP: must have minter role to create collection");
        Collection storage newCol = collections[numCollections++];
        newCol.name = _name;
        newCol.collectionType = _collectionType;
        newCol.uri = _uri;
        newCol.cost = _cost;
        newCol.totalMintCount = _remaingMintCount;
        newCol.remaingMintCount = _remaingMintCount;
        newCol.mintPassOpenToPublic = false;
        newCol.mintNftOpenToPublic = false;
        newCol.artistPayablePercent = _artistPayablePercent;
        newCol.artistPayableAddress = _artistPayableAddress;
        newCol.nftContractAddress = 0x0000000000000000000000000000000000000000;
    }

    function addToPassWhitelist ( address to, uint256 collectionId, uint16 amount ) public  {
        require(hasRole(MINTER_ROLE, _msgSender()) || hasRole(EVENT_MANAGER_ROLE, _msgSender()), "AP: must have minter role to whitelist mint pass");
        collections[collectionId].whitelistPass[to] = amount;
    }
    function addToNftWhitelist ( address to, uint256 collectionId, uint16 amount ) public  {
        require(hasRole(MINTER_ROLE, _msgSender()) || hasRole(EVENT_MANAGER_ROLE, _msgSender()), "AP: must have minter role to whitelist mint NFT");
        collections[collectionId].whitelistNft[to] = amount;
    }
    /**
     * @dev Function to enable/disable token minting
     * @param enabled The flag to turn minting on or off
     */
    function setEnabled(bool enabled) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "AP: must have minter role to change enable");
        _enabled = enabled;
    }

    function setContractOwner(address newOwner) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "AP: must have minter role to change contract owner");
        contract_owner = payable(newOwner);
    }

    /**
     * @dev Function to lock/unlock the on-chain metadata
     * @param locked The flag turn locked on
     */
    function setLocked(bool locked) public onlyUnlocked {
        require(
            msg.sender == contract_owner,
            "Only contract owner add to whitelist."
        );
        _locked = locked;
    }

    /**
     * @dev Function to update the base _uri for all tokens
     * @param newuri The base uri string
     */
    function setURI(string memory newuri) public  {
        require(
            msg.sender == contract_owner,
            "Only contract owner add to whitelist."
        );
        _setURI(newuri);
    }

    /***********************************|
    |    Utility Functions              |
    |__________________________________*/

    function mintedPassesCount() public view returns (uint256){
        return passes.length;
    }

    function ownerOf(uint256 idx) public view returns (address) {
        return tokenToAddress[idx];
    }

    function setNftContractAddress(address _nftAddress, uint256 collectionId) public {
        require(collectionId < numCollections, "AP: Collection not found");
        collections[collectionId].nftContractAddress = _nftAddress;
    }

    function setMintPassOpenToPublic(bool _open, uint256 collectionId) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "AP: Must have minter role to set MintPassOpenToPublic");
        require(collectionId < numCollections, "AP: Collection not found");
        collections[collectionId].mintPassOpenToPublic = _open;
    }

    function setMintNftOpenToPublic(bool _open, uint256 collectionId) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "AP: Must have minter role to set MintNftOpenToPublic");
        require(collectionId < numCollections, "AP: Collection not found");
        collections[collectionId].mintNftOpenToPublic = _open;
    }

    /***********************************|
    |    Nullify Functions              |
    |__________________________________*/

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        // Use mintNFT() instead
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        // Use mintBatchNFT() instead
    }

}