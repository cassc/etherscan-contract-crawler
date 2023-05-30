// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "hardhat/console.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
//access control
import "@openzeppelin/contracts/access/AccessControl.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/utils/Base64.sol";
import "./AddingData.sol";

struct PropertyAttributes {
    uint256 id;
    uint256 propertyIndex;
    string name;
    string description;
    string image;
    Properties properties;
    uint16 extensionCount;
    uint256[] extensionIds;
}

struct Properties {
    string tower;
    string district;
    string neighborhood;
    string primary_type;
    string sub_type_1;
    string sub_type_2;
    string structure;
    string feature_1;
    string feature_2;
    string feature_3;
    string feature_4;
    string tier;
}

interface DataInterface {
    function price(uint16 nftId) external view returns (uint256);
    function nftProperties(uint16 nftId) external view returns (PropertyAttributes memory);
    function getMintStatus(uint16 nftId) external view returns (bool);
    function changeMintStatus(uint16 nftId) external;
    function addExtensionToMetadata(uint16 nftId, uint extId)external;
    function removeExtensionFromMetadata(uint16 nftId, uint extId)external;
    function checkOwnershipOfExtension(uint16 propId, uint extTokenId)external view returns(bool);
}
interface WLContractInter{
    function checkPassportHasWLSpot(uint passportId, string calldata city, uint32 buildingId)external view returns(bool);
    function removeCityWlSpot(uint passportId, string calldata city, uint32 buildingId)external;
}
interface PassportInterface{
    // function confirmCityWl(uint passId, string calldata city, uint buildingId)external returns(bool);
    function ownerOf(uint256 tokenId)external view returns(address);
    function detachCityWLSpot(uint passportId, uint index)external;
}

interface TokenUriInterface{
    function getTokenUri(uint16 nftId)external view returns(string memory);
}


contract MetropolisWorldGenesis is ERC721Enumerable, AccessControl {
    address public DATA_CONTRACT;
    DataInterface DataContract;
    address public PASSPORT_CONTRACT;
    PassportInterface PassContract;
    address public TOKENURI_CONTRACT;
    TokenUriInterface TokContract;
    address private WL_CONTRCAT;
    WLContractInter WlContract;
    //defining the access roles
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
    bytes32 public constant BALANCE_ROLE = keccak256("BALANCE_ROLE");

    // The tokenId is the NFTs unique identifier, it's just a number that goes
    // 0, 1, 2, 3, etc.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _contractURI;
    // string private _passportContract;
    address payable private _paymentSplit;

    //map the nft tokenid to the atributes via property id
    //Property ID is used to get data from data contract
    mapping(uint256 => uint16) public nftHolderAttributes;
    mapping(uint16 => uint) propIdToTokenId;

    uint16[] public mintedIds;
    
   
    constructor() ERC721("Metropolis World - City of Celeste", "METC") {
        // I increment _tokenIds here so that my first NFT has an ID of 1.
        _tokenIds.increment();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPDATER_ROLE, msg.sender);
        _setupRole(CONTRACT_ROLE, msg.sender);
        _setupRole(BALANCE_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
    *@dev sets up the interface so this contract can call the passport contract  
    *@param passportContract the contract address of the passport contract. 
     */
    function setInterfaceContracts(address passportContract, address wlContract, address tokContract, address dataContract)external onlyRole(UPDATER_ROLE){
        require(passportContract != address(0), "Please enter valid contract address");
        require(wlContract != address(0), "Please enter valid contract address");
        require(tokContract != address(0), "Please enter valid contract address");
        require(dataContract != address(0), "Please enter valid contract address");
        PASSPORT_CONTRACT = passportContract;
        PassContract = PassportInterface(PASSPORT_CONTRACT);
        WL_CONTRCAT = wlContract;
        WlContract = WLContractInter(WL_CONTRCAT);
        TOKENURI_CONTRACT = tokContract;
        TokContract = TokenUriInterface(TOKENURI_CONTRACT);
        DATA_CONTRACT = dataContract;
        DataContract = DataInterface(DATA_CONTRACT);
    }

    function addPaymentSplitContract(address payable paymentSplit)external onlyRole(UPDATER_ROLE){
        require(paymentSplit != address(0), "Please enter valid contract address");
        _paymentSplit = paymentSplit;
    }

    function getMintedIds()external view returns(uint16[] memory){
        return mintedIds;
    }

    /**
    *@dev sets the CONTRACT_ROLE so that the extensions contract can call functions 
    *@param extAddress the contract address of the extensions contract. 
     */
    function setContractRole(address extAddress)external onlyRole(UPDATER_ROLE){
        require(extAddress != address(0), "Please enter valid contract address");
        _grantRole(CONTRACT_ROLE, extAddress);
    }

    /**
    *@dev returns the price of a specific NFT 
    *@param nftId the property Id of the nft you want to get the price for. 
     */
    function priceOfNft(uint16 nftId) external view returns (uint256) {
        uint256 price = DataContract.price(nftId);
        return price;
    }

    /**
    *@dev returns all the metadata for a specific NFT before or after minting
    *@param nftId the property ID of the speific NFT you want the metadata for. 
     */
    function metaData(uint16 nftId)public view returns (PropertyAttributes memory){
        PropertyAttributes memory x = DataContract.nftProperties(nftId);
        return x;
    }
    
    /**
    *@dev used to view the metadata of a property nft 
    *@param tokenId the token id of the nft you want to get the metadata for. 
     */
    function getNftData(uint tokenId)public view returns (PropertyAttributes memory){
        uint16 nftId = nftHolderAttributes[tokenId];
        return metaData(nftId);
    }

    /**
    @dev used by the front end to verify the wallet holda property and there for allow certain access 
    @param owner the wallet address to be checked against
     */
    function checkOwnsProperty(address owner)external view returns(PropertyAttributes[] memory){
        uint256 bal = balanceOf(owner);
        PropertyAttributes[] memory x = new PropertyAttributes[](bal);
        for (uint256 i = 0; i < bal; i++) {
            uint tokenId = tokenOfOwnerByIndex(owner,i);
            x[i] = getNftData(tokenId);
        }
        return x;
    }


    /**
    *@dev returns the mint status of a specificed property, ie is it minted yet
    *@param nftId the id of the property in question. 
    */
    function mintStatus(uint16 nftId)public view returns(bool){
        return DataContract.getMintStatus(nftId);
    }


    /**
    *@dev a function to chnage a properties mint status to true, effectivleyl making it unmintable 
    *@notice This may well be removed as is risky and perhaps better not having this option. 
     */
    function setMintStatus(uint16 nftId)public onlyRole(UPDATER_ROLE){
        DataContract.changeMintStatus(nftId);
    }

    /**
    *@dev the internal function used to process mints 
     */
    function _internalMint(uint passId, uint16 nftId, address to)internal {
        uint256 newItemId = _tokenIds.current();
        if (passId != 0){
            //check wl spot
            require(WlContract.checkPassportHasWLSpot(passId, 'city1', nftId), "no wl spot");
        }
        //check if minted yet
        require(DataContract.getMintStatus(nftId)==false, "This has already been minted");
        _safeMint(to, newItemId);
        nftHolderAttributes[newItemId] = nftId;
        propIdToTokenId[nftId] = newItemId;
        //set minted to true 
        DataContract.changeMintStatus(nftId);
        mintedIds.push(nftId);
        //Increment the tokenId for the next person that uses it.
        _tokenIds.increment();
        if (passId != 0){
            WlContract.removeCityWlSpot(passId, "city1", nftId);
            //PassContract.detachCityWLSpot(passId, 0);
        }
        //send money to payments contract. 
        if (address(this).balance > 0){
            withdraw();
        }
    }

    /**
    * @dev the standard mint procees to get a property 
    * @notice will check against your passport to make sure you are on the WL for this property
    * @param passId the tokenID of the passport the user holds
    * @param nftId  the id of the property the user is trying to mint 
    @param to wallet where the NFT is going to be minted to
    */
    function paidMint(uint passId, uint16 nftId, address to)external payable{
        //check you owwn this passport. 
        require(passId > 0, "Not a valid passport ID");
        require(PassContract.ownerOf(passId) == to, 'You must be the owner of this passport');
        require(msg.value >= DataContract.price(nftId), "Not paid enough, sorry");
        _internalMint(passId, nftId, to);
        if (msg.value > DataContract.price(nftId)){
            Address.sendValue(payable(msg.sender), (msg.value - DataContract.price(nftId))); 
        }
    }

    /**
    * @dev the free mint functiion used for winners and partners requires role  
    * @notice if you pass in 0 for the passport id it will not check the WL
    * @notice requires the wallet to have the UPDATER_ROLE
    * @param passId the tokenID of the passport the user holds
    * @param nftId  the id of the property the user is trying to mint 
    */
    function freeMint(uint16 passId, uint16 nftId, address to)public onlyRole(UPDATER_ROLE){
        //passing 0 into passID value will not check against WL 
        //used for founding citizens and other giveaways 
        _internalMint(passId, nftId, to);
    }
    
    /**
        *@dev function called by the extension contract to attach the extension to a building  
        *@notice this can only be called by the CONTRACT_ROLE
        *@param propTokenId the token id of the property the extension is attached to 
        *@param extTokenId the id of the extention being added 
        *@param owner the wallet address of the property owner, we verify the owner to ensure added to correct property
    */
    function attachExtension(uint propTokenId, uint extTokenId, address owner)external onlyRole(CONTRACT_ROLE){
        require(ownerOf(propTokenId) == owner, "not the owner");
        uint16 nftId = nftHolderAttributes[propTokenId];
        console.log("NFT ID is: ", nftId);
        DataContract.addExtensionToMetadata(nftId, extTokenId);
    }

    /**
        *@dev the function used to detach the extension from the property 
        *@notice can only be called by the contract role
        *@param propId the token Id of the property the extentsion is being detached from 
        *@param extTokenId the token id of the extension to be removed 
        *@param owner the address of the property owner. 
    */
    function detachExtension(uint propId, uint extTokenId, address owner)external onlyRole(CONTRACT_ROLE){
        require(ownerOf(propId) == owner, "not the owner");
        console.log("prop contract detahc extentions");
        uint16 nftId = nftHolderAttributes[propId];
        DataContract.removeExtensionFromMetadata(nftId, extTokenId);
        console.log("detach semt to data contract");
    }

    /**
    *@dev used to check who owns and extension. Primarily to verify that the user can attach or detach it 
    *@param propTokenId the token id of the property 
    *@param extTokenId the id of the extension id to be checked 
     */
    function checkExtensionOwnership(uint propTokenId, uint extTokenId)external view onlyRole(CONTRACT_ROLE) returns(bool){
        uint16 propId = nftHolderAttributes[propTokenId];
        return DataContract.checkOwnershipOfExtension(propId, extTokenId);
    }

    /**
    @dev function to allow us to use the internal property id to find the owner
    @param propId the internal id of the property  
     */
    function whoOwnsIt(uint16 propId)external view returns(address){
        return ownerOf(propIdToTokenId[propId]);
    }

    /**
    *@dev used to return the tokenURI which is dynamically generated, mostly for opensea etc. 
    *@notice the leg work is done on the tokenURI contract 
    *@param _tokenId token id of the property NFT 
    */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint16 nftId = nftHolderAttributes[_tokenId];
        return TokContract.getTokenUri(nftId);
    }


    /**
    *@dev set the contrct URI data for the contract to meet requirements of markets which follow the standard. 
    *@param name name of the contract 
    *@param desc descirption of the contract 
    *@param image image to represent the contract 
    *@param link link to be associated with the contract 
    *@param royalty about to collected as royalty 100 = 1% 
    */
    function setContractURI(
        string memory name,
        string memory desc,
        string memory image,
        string memory link,
        uint256 royalty
    ) public onlyRole(UPDATER_ROLE) {
        string memory x = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                name,
                '", "description": "',
                desc,
                '", "image": "',
                image,
                '", "external_link": "',
                link,
                '","seller_fee_basis_points":"',
                royalty, // 100 Indicates a 1% seller fee
                '", "fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" }' // Where seller fees will be paid to.}
            )
        );
        _contractURI = string(
            abi.encodePacked("data:application/json;base64,", x)
        );
    }

    /**
    *@dev withdraws eth from the contract to the payment split contract
    */
    function withdraw() public {
        uint256 balance = address(this).balance;
        Address.sendValue(_paymentSplit, balance);
    }
}