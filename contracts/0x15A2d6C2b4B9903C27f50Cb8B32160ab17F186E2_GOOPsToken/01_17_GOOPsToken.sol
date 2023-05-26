//  SPDX-License-Identifier: GPL-3.0

/*

 ██████╗  ██████╗  ██████╗ ██████╗         
██╔════╝ ██╔═══██╗██╔═══██╗██╔══██╗        
██║  ███╗██║   ██║██║   ██║██████╔╝        
██║   ██║██║   ██║██║   ██║██╔═══╝         
╚██████╔╝╚██████╔╝╚██████╔╝██║             
 ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝             
                                           
████████╗██████╗  ██████╗  ██████╗ ██████╗ 
╚══██╔══╝██╔══██╗██╔═══██╗██╔═══██╗██╔══██╗
   ██║   ██████╔╝██║   ██║██║   ██║██████╔╝
   ██║   ██╔══██╗██║   ██║██║   ██║██╔═══╝ 
   ██║   ██║  ██║╚██████╔╝╚██████╔╝██║     
   ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝     
                                           
GOOP Troop: Goofy Oversized Optics People


GOOP Troop project source code is derivative of the Nouns project token (0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03) by Nouns DAO, which is licensed under GPL-3.0.
*/
pragma solidity ^0.8.6;
    
import { Ownable } from './Ownable.sol';
import { IGOOPsDescriptor } from './IGOOPsDescriptor.sol';
import { IGOOPsSeeder } from './IGOOPsSeeder.sol';
import { IGOOPsToken } from './IGOOPsToken.sol';
import { ERC721 } from './ERC721.sol';
import { IERC721 } from './IERC721.sol';
import { IProxyRegistry } from './IProxyRegistry.sol';
import { Strings } from './Strings.sol';
import { ERC721Enumerable } from './ERC721Enumerable.sol';


contract GOOPsToken is IGOOPsToken, Ownable, ERC721Enumerable {
    using Strings for uint256;

    // Price and maximum number of GOOPs
    uint256 public price = 36942000000000000;
    uint256 public max_tokens = 10000;
    uint256 public mint_limit= 20;

    // Store custom descriptions for GOOPs
    mapping (uint => string) public customDescription; 

    // The GOOPs token URI descriptor
    IGOOPsDescriptor public descriptor;

    // The GOOPs token seeder
    IGOOPsSeeder public seeder;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // The GOOP seeds
    mapping(uint256 => IGOOPsSeeder.Seed) public seeds;

    // The internal GOOP ID tracker
    uint256 private _currentGOOPId;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    // Withdraw Addresses
    address t1;
    address t2;

    // Sale Status

    bool public sale_active =false;

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, 'Descriptor is locked');
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, 'Seeder is locked');
        _;
    }

    /**
     * @notice Set a custom description for a GOOP token on-chain that will display on OpenSea and other sites.
     * Takes the format of "GOOP [tokenId] is a [....]"
     * May be modified at any time
     * Send empty string to revert to default.
     * @dev Only callable by the holder of the token.
     */
    function setCustomDescription (uint256 tokenId, string calldata _description) external returns (string memory){
        require (msg.sender==ownerOf(tokenId),"not your GOOP");
        customDescription[tokenId]=_description;
        string memory GOOPId = tokenId.toString();
        string memory returnMessage=string(abi.encodePacked("Description set to: " , viewDescription(tokenId)));
        return returnMessage;
    }

    function viewDescription (uint256 tokenId) public view returns (string memory){
        string memory description="";
        string memory GOOPId = tokenId.toString();

        if (bytes(customDescription[tokenId]).length!=0)
        {
            description = string(abi.encodePacked(description,'GOOP ', GOOPId, ' is a ', customDescription[tokenId]));
        }
        else
        {
            description = string(abi.encodePacked(description,'GOOP ', GOOPId, ' is a member of the Goofy Oversized Optics People, otherwise known as the GOOP Troop'));
        }
        return description;
    }
    
    constructor() ERC721('Goofy Oversized Optics People', 'GOOP') {
        descriptor = IGOOPsDescriptor(0x0Cfdb3Ba1694c2bb2CFACB0339ad7b1Ae5932B63);
        seeder = IGOOPsSeeder(0xCC8a0FB5ab3C7132c1b2A0109142Fb112c4Ce515);
        proxyRegistry = IProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1);
        _contractURIHash="";
        
        t1 = 0x5A1ED1bEB3A8f5979c7f9920834Ee5e54415ffa0;
        t2 = 0xb753f3DD55dAC6ebCD5d204828642A1482D99B2c;

    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    function toggleSale() external onlyOwner {
        sale_active=!sale_active;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Mint GOOPs to sender
     */
    function mint(uint256 num_tokens) public override payable {

        require (sale_active,"sale not active");

        require (num_tokens<=mint_limit,"minted too many");

        require(num_tokens+totalSupply()<=max_tokens,"exceeds maximum tokens");

        require(msg.value>=num_tokens*price,"not enough ethers sent");

        for (uint256 x=0;x<num_tokens;x++)
        {
            _mintTo(msg.sender, _currentGOOPId++);
        }
    }


    /**
     * @notice Burn a GOOP.
     */
    function burn(uint256 GOOPId) public override onlyOwner {
        _burn(GOOPId);
        emit GOOPBurned(GOOPId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'GOOPsToken: URI query for nonexistent token');
        string memory GOOPId = tokenId.toString();
        string memory name = string(abi.encodePacked('GOOP ', GOOPId)); 
        string memory description=viewDescription(tokenId);
        return descriptor.genericDataURI(name, description, seeds[tokenId]);
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(IGOOPsDescriptor _descriptor) external override onlyOwner whenDescriptorNotLocked {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external override onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(IGOOPsSeeder _seeder) external override onlyOwner whenSeederNotLocked {
        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;

        emit SeederLocked();
    }

    /**
     * @notice Mint a GOOP with `GOOPId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 GOOPId) internal returns (uint256) {
        IGOOPsSeeder.Seed memory seed = seeds[GOOPId] = seeder.generateSeed(GOOPId, descriptor);

        _mint(to, GOOPId);
        emit GOOPCreated(GOOPId, seed);

        return GOOPId;
    }

    /**
     * @notice Contract balance is sent to the team.
     */
    function withdrawAll() public {
        uint256 _each = address(this).balance / 2;
        require(payable(t1).send(_each));
        require(payable(t2).send(_each));
    }
    
}