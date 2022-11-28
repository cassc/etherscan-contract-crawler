// File: @ensdomains/resolver/contracts/Resolver.sol
pragma solidity >=0.4.24;

interface ETHRegistrarController {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

pragma solidity >= 0.7.0 < 0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SoundBound is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public curTokenId;

    // genre variables
    mapping (uint32 => bool) genreIdIsIn;

    // The ENS registry
    ETHRegistrarController public ens;

    // NFT price
        uint256 private purchasePrice = 0 wei;
        uint256 private whitelistPurchasePrice = 0 wei;

    // TODO: testing
//    uint256 private purchasePrice = 0 wei;
//    uint256 private whitelistPurchasePrice = 0 wei;

    // Whitelist
    // Track the number of whitelisted addresses.
    uint256 public numberOfAddressesWhitelisted;
    // To store our addresses, we need to create a mapping that will receive the users' addresses and return if they are whitelisted or not.
    mapping(address => bool) whitelistedAddresses;

    // Log event for indexing
    event LogNFTCreated(uint256 indexed curTokenId, address indexed ownerWalletAddress, string name, uint32 genre);

    // contract paused
    bool public paused = false;

    // Mapping from name to its purchased status
    mapping(string => bool) private purchaseStatus;

    // Mapping from name to a token id
    mapping(string => uint256) private domainToTokenId;

    // Basic metadata uri
    string public metadataUri = "";
    string public metadataUriSuffix = "/metadata";

    constructor(
        ETHRegistrarController _ens,
        string memory name,
        string memory symbol,
        uint32[] memory _genre
    )
    ERC721(name, symbol)
    {
        ens = _ens;
        for(uint i = 0; i < _genre.length; i++) {
            genreIdIsIn[_genre[i]] = true;
        }
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function domainToNode(string memory name) internal pure returns (uint256) {
        bytes32 label = keccak256(bytes(name));
        uint256 hashKey = uint256(label);
        return hashKey;
    }

    // Group whitelist
    function addGroupUserAddressToWhitelist(address[] memory whitelistAddressMap) public onlyOwner {
        for (uint i=0; i<whitelistAddressMap.length; i++) {
            address whitelistAddress = whitelistAddressMap[i];
            // Validate the caller is not already part of the whitelist.
            if(whitelistedAddresses[whitelistAddress]) {
                continue;
            }
            // Set whitelist boolean to true.
            whitelistedAddresses[whitelistAddress] = true;
            // Increasing the count
            numberOfAddressesWhitelisted += 1;
        }
    }

    // Is the user whitelisted?
    function isWhitelisted(address _whitelistedAddress)
    public
    view
    returns (bool)
    {
        // Verifying if the user has been whitelisted
        return whitelistedAddresses[_whitelistedAddress];
    }

    // Remove users from whitelist
    function removeGroupUserAddressToWhitelist(address[] memory addressToRemoveMap) public onlyOwner {
        for (uint i=0; i<addressToRemoveMap.length; i++) {
            address removeAddress = addressToRemoveMap[i];
            // Validate the caller is not already part of the whitelist.
            if(!whitelistedAddresses[removeAddress]) {
                continue;
            }
            // Set whitelist boolean to false.
            whitelistedAddresses[removeAddress] = false;
            // This will decrease the number of whitelisted addresses.
            numberOfAddressesWhitelisted -= 1;
        }
    }

    // Get the number of whitelisted addresses
    function getNumberOfWhitelistedAddresses() public view returns (uint256) {
        return numberOfAddressesWhitelisted;
    }

    // Purchase music NFT
    function purchaseNFT(string memory name, uint32 genreId) external payable {
        require(!paused, "The contract has been paused");

        // Revert if the genre type is invalid
        require(genreIdIsIn[genreId], "Genre id is invalid.");

        // Revert the transaction if the amount is insufficient
        if(isWhitelisted(msg.sender)) {
            require(msg.value >= whitelistPurchasePrice, "Insufficient amount.");
        } else {
            require(msg.value >= purchasePrice, "Insufficient amount.");
        }

        // uint256 node = domainToNode(name);

        // Revert the transaction if the NFT has been purchased
        require(purchaseStatus[name] == false, "This NFT has been purchased.");

        // Revert if the node doesn't belong to message sender
        //        require(msg.sender == ens.ownerOf(node),  "You are not the owner of this node.");

        purchaseStatus[name] = true;
        curTokenId.increment();
        uint256 newItemId = curTokenId.current();
        _safeMint(msg.sender, newItemId);
        domainToTokenId[name] = newItemId;
        emit LogNFTCreated(newItemId, msg.sender, name, genreId);
    }


    // Get functions
    function getPurchsePrice() external view returns (uint256) {
        return purchasePrice;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), metadataUriSuffix)) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataUri;
    }

    function getMetadataSuffix() external view returns (string memory) {
        return metadataUriSuffix;
    }

    function getTokenIdByNode(string memory name) external view returns (uint256) {
        require(purchaseStatus[name] == true,  "The domain hasn't been purchased yet.");
        return domainToTokenId[name];
    }

    function getMusicGenre(uint32 index) external view returns (bool) {
        return genreIdIsIn[index];
    }

    function getPurchaseStatus(string memory name) external view returns (bool) {
        return purchaseStatus[name];
    }

    // Set functions
    function setBaseURI(string memory newURI) external onlyOwner {
        metadataUri = newURI;
    }

    function setMetadataSuffix(string memory newURI) external onlyOwner {
        metadataUriSuffix = newURI;
    }

    function setPurchasePrice(uint256 newPrice) public onlyOwner {
        purchasePrice = newPrice;
    }

    function addMusicGenre(uint32 index) public onlyOwner {
        require(!genreIdIsIn[index], "This genre id already exists");
        genreIdIsIn[index] = true;
    }

    function disableMusicGenre(uint32 index) public onlyOwner {
        require(genreIdIsIn[index], "This genre id doesn't exist");
        genreIdIsIn[index] = false;
    }

    function pause(bool state) public onlyOwner {
        paused = state;
    }

    function withdraw() public payable onlyOwner {
        // This will payout the owner 100% of the contract balance.
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}