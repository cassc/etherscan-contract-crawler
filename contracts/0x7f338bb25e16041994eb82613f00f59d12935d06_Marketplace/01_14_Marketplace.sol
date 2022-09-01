// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './NFTToken.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable {
	/** @dev Struct that stores Art data 
	* @param id Art id 
	* @param name Art name 
	* @param description Art Description 
	* @param uri URI for the NFT
    * @param uri The initial price of the NFT
    * @param totalSupply Total amount of nft that can be minted using this art 
	* @param mintedCount Count for the nft minted using this art
	*/    
    struct Art {
        bytes32 id;
        bytes32 providerID;
        string name;
        string description;
        string uri;
        string metadataUri;
        uint16 totalSupply;
        uint16 mintedCount;
        uint256 price;
        uint256 dateCreated;
    }

	/** @dev Struct that stores Provider data 
	* @param id Provider id 
	* @param name Provider name 
	* @param description Provider Description 
	* @param logo The provider's logo
    * @param addr The address for the provider
    * @param commission The commission for each sale
	*/    
    struct Provider {
        bytes32 id;
        string name;
        string description;
        string logo;
        string banner;
        address payable addr;
        uint8 commission;
        uint256 dateCreated;
        bool isEnabled;
    }

    //Events emited by the contract
    event ProviderCreated(bytes32 id, string name, string description, string logo, string banner, address addr, uint8 commission, uint256 dateCreated, bool isEnabled);
    event ProviderEdited(bytes32 id, string name, string description, string logo, string banner, address addr, uint8 commission, uint256 dateCreated, bool isEnabled);
    event ArtCreated(bytes32 id, bytes32 providerID, string name, string description, string uri, string metadataUri, uint16 totalSupply, uint256 price, uint256 dateCreated);
    event ArtMinted(bytes32 artID, uint256 tokenId, address owner);

    //List of all providers
    bytes32[] providers;   

    NFTToken nft;

    //Mapping between the address and the provider
    mapping (address => bytes32) providerByOwner;

    //Mapping between the id and the provider
    mapping (bytes32 => Provider) providerByID;

    //Mapping between the address of the owner and his arts
    mapping (bytes32 => bytes32[]) artsByProvider;

    //Mapping between the art id and the art
    mapping (bytes32 => Art) artByID;

    bool stopped;

    modifier notStopped {
        require(stopped == false, "The contract is stopped");
        _;
    }

    constructor(address nftTknAddr) Ownable() { 
        nft = NFTToken(nftTknAddr);
        stopped = false;
    }

    //////////////////////////  
    //  CONTRACT FUNCTIONS  //
    //////////////////////////  

    /** @dev Adds a new provider
    * @param name Provider name 
	* @param description Provider Description 
	* @param logo The provider's logo
    * @param banner A banner image for the provider
    * @param addr The address for the provider
    * @param commission The marketplace commission for each sale
	*/

    function addProvider(string memory name, string memory description, string memory logo, string memory banner, address addr, uint8 commission) public notStopped onlyOwner {
        require(bytes(name).length > 0, "The name can't be empty");
        require(bytes(description).length > 0, "The description can't be empty");
        require(bytes(logo).length > 0, "The logo can't be empty");
        require(addr != owner(), "The owner can't be a provider");
        require(providerByOwner[addr] == 0, "The address is already a provider");
        require(commission >= 0 && commission <= 100, "The commission should be between 0 and 100");

        bytes32 id = keccak256(abi.encodePacked(msg.sender, name, block.timestamp));
        Provider memory p = Provider(id, name, description, logo, banner, payable(addr), commission, block.timestamp, true);

        providers.push(id);
        providerByOwner[addr] = id;
        providerByID[id] = p;

        emit ProviderCreated(p.id, p.name, p.description, p.logo, p.banner, p.addr, p.commission, p.dateCreated, p.isEnabled);
    }

    /** @dev Enables / Disables a provider
    * @param id The provider to edit
    * @param value true -> enabled, false -> disabled
	*/
    function setIsProviderEnabled(bytes32 id, bool value) public notStopped onlyOwner {
        require(providerByID[id].id != 0, "The provider doesn't exist");
        providerByID[id].isEnabled = value;
        Provider memory p = providerByID[id];
        
        emit ProviderEdited(p.id, p.name, p.description, p.logo, p.banner, p.addr, p.commission, p.dateCreated, p.isEnabled);
    }

    /** @dev Edits a provider
    * @param id The provider to edit
    * @param name Provider name 
	* @param description Provider Description 
	* @param logo The provider's logo
    * @param banner A banner image for the provider
    * @param addr The address for the provider
    * @param commission The marketplace commission for each sale
	*/
    function editProvider(bytes32 id, string memory name, string memory description, string memory logo, string memory banner, address addr, uint8 commission) public notStopped { 
        Provider memory p = providerByID[id];

        require(p.id != 0, "The provider doesn't exist");

        if(msg.sender != owner()) {
            require(p.addr == msg.sender, "Only the owner or the provider itself can edit this profile");
        }

        require(bytes(name).length > 0, "The name can't be empty");
        require(bytes(description).length > 0, "The description can't be empty");
        require(bytes(logo).length > 0, "The logo can't be empty");
        require(addr != owner(), "The owner can't be a provider");
        require(providerByOwner[addr] == 0, "The address is already a provider");
        require(commission >= 0 && commission <= 100, "The commission should be between 0 and 100");

        p.name = name;
        p.description = description;
        p.logo = logo;
        p.addr = payable(addr);
        p.banner = banner;

        if(msg.sender == owner()) {
            p.commission = commission;
        }

        providerByID[id] = p;

        emit ProviderEdited(p.id, p.name, p.description, p.logo, p.banner, p.addr, p.commission, p.dateCreated, p.isEnabled);
    }

    /** @dev Returns all the providers ids */
    function getProviders() view public returns(bytes32[] memory) {
        return providers;
    }

    /** @dev Returns the provider for the given id
    @param id The provider id
    */
    function getProviderByID(bytes32 id) view public returns(Provider memory) {
        return providerByID[id];
    }

    /** @dev Returns the provider for the given address
    @param addr The provider address
    */
    function getProviderByAddress(address addr) view public returns(bytes32) {
        bytes32 id = providerByOwner[addr];
        return id;
    }

    /** @dev Add a new artwork to the provider. The provider must me the caller of this function
    @param name The artwork name
    @param description The artwork description
    @param metadataUri The artwork image URI
    @param price The artwork price
    @param totalSupply The artwork total supply that can be minted
    */

    function addArtwork(string memory name, string memory description, string memory uri, string memory metadataUri, uint256 price, uint16 totalSupply) notStopped public {
        require(bytes(name).length > 0, "The name can't be empty");
        require(bytes(description).length > 0, "The description can't be empty");
        require(bytes(uri).length > 0, "The uri can't be empty");
        require(price > 0, "The price should be greater than 0");
        require(totalSupply > 0, "The total supply should be greater than 0");

        bytes32 providerID = getProviderByAddress(msg.sender);
        require(providerID != 0, "The provider doesn't exist");

        bytes32 id = keccak256(abi.encodePacked(msg.sender, name, block.timestamp));
        Art memory art = Art(id, providerID, name, description, uri, metadataUri, totalSupply, 0, price, block.timestamp);

        artsByProvider[providerID].push(id);
        artByID[id] = art;

        emit ArtCreated(art.id, art.providerID, art.name, art.description, art.uri, art.metadataUri, art.totalSupply, art.price, art.dateCreated);
    }

    /** @dev Returns the artwork by the given artwork id
    @param id The artwork id
    */
    function getArtworkForID(bytes32 id) view public returns(Art memory) {
        return artByID[id];
    }

    /** @dev Returns the artworks id that are owned by the given provider id
    @param pID The provider id
    */
    function getArtworksForProvider(bytes32 pID) view public returns(bytes32[] memory) {
        return artsByProvider[pID];
    }

    /** @dev Buys a new artwork. This method needs to be called with the value matching the artwork price. 
     * The value is splitted, the commission is kept in the contract and the rest is transferred to the provider
    @param aID The artwork id
    */
    function buyArtwork(bytes32 aID) public payable notStopped {
        Art memory a = getArtworkForID(aID);
        require(a.id != 0, "The artwork doesn't exist");

        uint256 paidValue = msg.value;
        require(a.mintedCount < a.totalSupply, "The Art has reached the total minting supply");
        require(paidValue == a.price, "The price doesn't match");

        artByID[aID].mintedCount += 1;

        Provider memory p = providerByID[a.providerID];
        address payable providerAddress = p.addr;
        uint256 marketCommission = msg.value * p.commission / 100;
        providerAddress.transfer(msg.value - marketCommission);

        //Mint the art
        uint256 tokenId = nft.mint(msg.sender, a.metadataUri);

        emit ArtMinted(a.id, tokenId, msg.sender);
    }

    function extractBalance() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setStopped(bool value) public onlyOwner {
        stopped = value;
    }
}