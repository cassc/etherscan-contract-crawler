// SPDX-License-Identifier: MIT
/*     

      ___          ___                 ___                                            ___         ___          ___                       
     /__/\        /  /\        ___    /  /\                   ___        _____       /  /\       /  /\        /  /\        ___           
    |  |::\      /  /:/_      /  /\  /  /::\                 /  /\      /  /::\     /  /::\     /  /::\      /  /::\      /__/|          
    |  |:|:\    /  /:/ /\    /  /:/ /  /:/\:\  ___     ___  /  /:/     /  /:/\:\   /  /:/\:\   /  /:/\:\    /  /:/\:\    |  |:|          
  __|__|:|\:\  /  /:/ /:/_  /  /:/ /  /:/~/::\/__/\   /  /\/__/::\    /  /:/~/::\ /  /:/~/:/  /  /:/~/::\  /  /:/~/:/    |  |:|          
 /__/::::| \:\/__/:/ /:/ /\/  /::\/__/:/ /:/\:\  \:\ /  /:/\__\/\:\__/__/:/ /:/\:/__/:/ /:/__/__/:/ /:/\:\/__/:/ /:/_____|__|:|          
 \  \:\~~\__\/\  \:\/:/ /:/__/:/\:\  \:\/:/__\/\  \:\  /:/    \  \:\/\  \:\/:/~/:|  \:\/:::::|  \:\/:/__\/\  \:\/:::::/__/::::\          
  \  \:\       \  \::/ /:/\__\/  \:\  \::/      \  \:\/:/      \__\::/\  \::/ /:/ \  \::/~~~~ \  \::/      \  \::/~~~~   ~\~~\:\         
   \  \:\       \  \:\/:/      \  \:\  \:\       \  \::/       /__/:/  \  \:\/:/   \  \:\      \  \:\       \  \:\         \  \:\        
    \  \:\       \  \::/        \__\/\  \:\       \__\/        \__\/    \  \::/     \  \:\      \  \:\       \  \:\         \__\/        
     \__\/        \__\/               \__\/   ___          ___          _\__\/     __\__\/      _\__\/        \__\/                      
                                             /  /\        /  /\        /  /\      /  /::\      /  /\                                     
                                            /  /:/       /  /::\      /  /::\    /  /:/\:\    /  /:/_                                    
                                           /  /:/       /  /:/\:\    /  /:/\:\  /  /:/  \:\  /  /:/ /\                                   
                                          /  /:/  ___  /  /:/~/::\  /  /:/~/:/ /__/:/ \__\:|/  /:/ /::\                                  
                                         /__/:/  /  /\/__/:/ /:/\:\/__/:/ /:/__\  \:\ /  /:/__/:/ /:/\:\                                 
                                         \  \:\ /  /:/\  \:\/:/__\/\  \:\/:::::/\  \:\  /:/\  \:\/:/~/:/                                 
                                          \  \:\  /:/  \  \::/      \  \::/~~~~  \  \:\/:/  \  \::/ /:/                                  
                                           \  \:\/:/    \  \:\       \  \:\       \  \::/    \__\/ /:/                                   
                                            \  \::/      \  \:\       \  \:\       \__\/       /__/:/                                    
                                             \__\/        \__\/        \__\/                   \__\/                                     
*/

/// @title BookCoin's Metalibrary Card NFT Collection
/// @author audie.eth
/// @notice Become a Founder of the MetaLibrary — Giving You an Early Mint Pass to Future Drops, The Founder's Club, $BKCN Token*, & More.
/// @dev Mint windows coded into contract, merkle trees are additive and don't need to repeat

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract BookCoin721 is ERC2981, ERC721, Ownable {
    using Counters for Counters.Counter;

    // mutable properties
    bytes32 private _rootPreSale;
    bytes32 private _rootGroup1;
    bytes32 private _rootGroup2;
    string private _baseTokenURI = "https://bookcoin.mypinata.cloud/ipfs/QmeeCAhgji7J4vqWxmXFvbSjvKc7etscXsF8maJTBmdvJc/";
    string private _contractUri = "https://bookcoin.mypinata.cloud/ipfs/QmSCmtnvf2AQDLbwWEgRYmeYPagLbsxRR8cv6xyXEW9EvS";
    uint256 private _preSaleStartTime = 1650315600; // Mon Apr 18 2022 21:00:00 GMT+0000
    uint256 private _groupOneStartTime = 1650376800; // Tue Apr 19 2022 14:00:00 GMT+0000
    uint256 private _groupTwoStartTime = 1650387600; // Tue Apr 19 2022 17:00:00 GMT+0000
    uint256 private _publicMintStartTime = 1650355200; // Tue Apr 19 2022 08:00:00 GMT+0000

    // counter for incrementing tokenID
    Counters.Counter private _nextTokenId;

    // map of addresses to count of NFTs minted
    mapping(address => uint16) public mintNum;

    // fixed properties
    uint256 public supplyLimit = 777;
    uint256 public mintPrice = 0.15 ether;
    uint256 public mintLimitSwitchTime = _groupTwoStartTime; // also set with group two below
    uint16 public firstMintLimit = 1;
    uint16 public secondMintLimit = 5;

    // EIP2981 properties
    address royaltyAddr = 0x83958d93Aa1Dd637f265F8FF324FC358e94c40dB;
    uint96 royaltyPercent = 1000; // denominator is 10000, so this is 10%

    /**
     *  @notice Contructor for the NFT
     *  @param name The long name of the NFT collection
     *  @param symbol The short, all caps symbol for the collection
     *  @param merklerootPreSale The merkle root for the presale allowed minters
     *  @param merklerootGroup1 The merkle root for the group one allowed minters
     *  @param merklerootGroup2 The merkle root for the group two allowed minters
     */
    constructor(
        string memory name,
        string memory symbol,
        bytes32 merklerootPreSale,
        bytes32 merklerootGroup1,
        bytes32 merklerootGroup2
    ) ERC2981() ERC721(name, symbol) Ownable() {
        _setDefaultRoyalty(royaltyAddr, royaltyPercent);
        _rootPreSale = merklerootPreSale;
        _rootGroup1 = merklerootGroup1;
        _rootGroup2 = merklerootGroup2;
        _nextTokenId.increment();
    }

    /**
     *  @notice Sets the ERC2981 default royalty info
     *  @param receiver The address to receive default royalty payouts
     *  @param feeNumerator The royalty fee in basis points, set over a denominatory of 10000
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     *  @notice Given a caller with a matching proof, and at least mint price ETH sent, mints the next NFT
     *  @param proof A merkle proof that confirms the sender's address is in the list of approved minters
     */
    function mint(bytes32[] calldata proof) external payable {
        // only the address on the merkle tree can mint, no others - means tree can be public
        address account = _msgSender();
        require(
            msg.value >= mintPrice,
            "Ether value sent lower than mint price"
        );
        require(_verify(_leaf(account), proof), "Invalid merkle proof");
        require(_withinMintLimit(account, 1), "Already Minted");
        _mintOne(account);
    }

    /**
     *  @notice Allow minting more than one NFT in one call, up to the mint limit
     *  @param proof A merkle proof that confirms the sender's address is in the list of approved minters
     *  @param numberToMint The number of NFTs to mint
     *  @dev The number of NFTs that can me minted is limited by the mint limit, which changes 
     */
    function mintBatch(bytes32[] calldata proof, uint16 numberToMint) external payable {
        address account = _msgSender();
        require(
            msg.value >= mintPrice * numberToMint,
            "Ether value sent lower than mint price"
        );
        require(_verify(_leaf(account), proof), "Invalid merkle proof");
        require(_withinMintLimit(account, numberToMint), "Already Minted");
        for (uint256 i = 0; i < numberToMint; i++) {
            _mintOne(account);
        }
    }

    /**
     *  @notice Owner only mint function to mint reserves or giveaways
     *  @param account The address to receive all the minted NFTs
     *  @param numberToMint The number of NFTs to mint
     */
    function ownerMint(address account, uint96 numberToMint)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < numberToMint; i++) {
            _mintOne(account);
        }
    }

    /**
     *  @notice View to see current mint limit
     *  @return limit Current mint limit 
     */
    function mintLimit() public view returns(uint16){
        if (block.timestamp <= mintLimitSwitchTime){
            return firstMintLimit;
        }
        return secondMintLimit;
    }

    /**
     *  @notice Allows the owner to withdraw the Ether collected from minting
     */
    function withdrawEther() public onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    /**
     *   @notice Overrides EIP721 and EIP2981 supportsInterface function
     *   @param interfaceId Is supplied from anyone/contract calling this function, as defined in ERC 165
     *   @return supports A boolean saying if this contract supports the interface or not
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     *   @notice Shows maximum supply
     *   @return uint256 Returns the maximum number of mintable NFTs
     */
    function maxSupply() public view returns (uint256) {
        // total supply is the total minted
        return supplyLimit;
    }

    /**
     *   @notice Shows total supply
     *   @return uint256 Returns total existing supply
     */
    function totalSupply() public view returns (uint256) {
        // total supply is the total minted
        return _nextTokenId.current() - 1;
    }

    /**
     *  @notice Provides the root being used for presale approved minter list
     */
    function preSaleRoot() public view returns (bytes32) {
        return _rootPreSale;
    }

    /**
     *  @notice Allows the owner to set a new presale merkle root
     *  @param newPreSaleRoot A merkle root created from a list of approved presale minters
     */
    function setPreSaleRoot(bytes32 newPreSaleRoot) public onlyOwner {
        _rootPreSale = newPreSaleRoot;
    }

    /**
     *  @notice Provides the root being used for group one approved minter list
     */
    function preGroupOneRoot() public view returns (bytes32) {
        return _rootPreSale;
    }

    /**
     *  @notice Provides the root being used for group one approved minter list
     *  @param newGroupOneRoot A merkle root created from a list of approved group one minters
     */
    function setGroupOneRoot(bytes32 newGroupOneRoot) public onlyOwner {
        _rootGroup1 = newGroupOneRoot;
    }

    /**
     *  @notice Provides the root being used for group two approved minter list
     */
    function preGroupTwoRoot() public view returns (bytes32) {
        return _rootPreSale;
    }

    /**
     *  @notice Provides the root being used for group two approved minter list
     *  @param newGroupTwoRoot A merkle root created from a list of approved group two minters
     */
    function setGroupTwoRoot(bytes32 newGroupTwoRoot) public onlyOwner {
        _rootGroup2 = newGroupTwoRoot;
    }

    /**
     *  @notice Retrieves the presale mint start time
     *  @return date The unix time stamp for when presale mint starts
     */
    function preSaleStartTime() public view returns (uint256) {
        return _preSaleStartTime;
    }

    /**
     *  @notice Set the timestamp after which presale mint opens
     *  @param newPreSaleStart The unix time stamp presale mint will start
     *  @dev This time is when minting begins, should be set first
     */
    function setPreSaleStartTime(uint256 newPreSaleStart) public onlyOwner {
        _preSaleStartTime = newPreSaleStart;
    }

    /**
     *  @notice Retrieves the group one mint start time
     *  @return date The unix time stamp for when group one mint starts
     */
    function groupOneStartTime() public view returns (uint256) {
        return _groupOneStartTime;
    }

    /**
     *  @notice Set the timestamp after which group one mint opens
     *  @param newGroupOneStart The unix time stamp group one mint will start
     */
    function setGroupOneStartTime(uint256 newGroupOneStart) public onlyOwner {
        require(
            newGroupOneStart > _preSaleStartTime,
            "Set time greater than presale time"
        );
        _groupOneStartTime = newGroupOneStart;
    }

    /**
     *  @notice Retrieves the group two mint start time
     *  @return date The unix time stamp for when group two mint starts
     */
    function groupTwoStartTime() public view returns (uint256) {
        return _groupTwoStartTime;
    }

    /**
     *  @notice Set the timestamp after which group two mint opens
     *  @param newGroupTwoStart The unix time stamp group two mint will start
     *  @dev The mint limit switch is coded in here, needs to change with this time
     */
    function setGroupTwoStartTime(uint256 newGroupTwoStart) public onlyOwner {
        require(
            newGroupTwoStart > _groupOneStartTime,
            "Set time greater than group one time"
        );
        _groupTwoStartTime = newGroupTwoStart;
        mintLimitSwitchTime = newGroupTwoStart;
    }

    /**
     *  @notice Retrieves the public mint start time
     *  @return date The unix time stamp for when public mint starts
     */
    function publicMintStartTime() public view returns (uint256) {
        return _publicMintStartTime;
    }

    /**
     *  @notice Set the timestamp after which public mint opens
     *  @param newPublicMintStart The unix time stamp public mint will start
     */
    function setPublicMintStartTime(uint256 newPublicMintStart)
        public
        onlyOwner
    {
        require(
            newPublicMintStart > _groupTwoStartTime,
            "Set time greater than group two time"
        );
        _publicMintStartTime = newPublicMintStart;
    }

    /**
     *   @notice Gets next mint token id
     *   @return uint256 The number of next token id to mint
     */
    function getNextTokenId() public view returns (uint256) {
        return _nextTokenId.current();
    }

    /**
     *   @notice Provides collection metadata URI
     *   @return string The contract metadata URI
     */
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    /**
     *   @notice Sets the collection metadata URI
     *   @param newContractUri The URI set for the collection metadata
     */
    function setContractURI(string memory newContractUri) public onlyOwner {
        _contractUri = newContractUri;
    }

    /**
     *   @notice Sets the token metadata base URI
     *   @param uri The baseURI for the token metadata
     */
    function setBaseURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    /**
     *  @notice Provides the URI for the specific token's metadata
     *  @param tokenId The token ID for which you want the metadat URL
     *  @dev This will only return for existing token IDs, and expects the file to end in .json
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /**
     *  @notice Confirms and address and proof will allow minting
     *  @param account The address to use as a merkle leaf
     *  @param proof The merkle proof you want to check is valid with the address
     *  @dev This needs the address, proof, and time to be correct. Time check is in internal _verify function
     */
    function canMint(address account, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        return _verify(_leaf(account), proof);
    }   

    function _withinMintLimit(address account, uint16 mintCount)
        internal
        view
        returns (bool)
    {
        uint16 num = mintNum[account];
        if (block.timestamp <= mintLimitSwitchTime) {
            require(
                num + mintCount <= firstMintLimit,
                "Attempting to mint past limit"
            );
        } else {
            require(
                num + mintCount <= secondMintLimit,
                "Attempting to mint past limit"
            );
        }
        return true;
    }


    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _mintOne(address account) internal {
        require(
            _nextTokenId.current() <= supplyLimit,
            "Cannot mint beyond supply limit"
        );
        _safeMint(account, _nextTokenId.current());
        _nextTokenId.increment();
        mintNum[account]++;
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        bool presale = false;
        bool groupone = false;
        bool grouptwo = false;
        uint256 currentBlockTime = block.timestamp;
        if (currentBlockTime > _publicMintStartTime) {
            return true;
        }

        if (currentBlockTime > _groupTwoStartTime) {
            grouptwo = MerkleProof.verify(proof, _rootGroup2, leaf);
        }

        if (currentBlockTime > _groupOneStartTime) {
            groupone = MerkleProof.verify(proof, _rootGroup1, leaf);
        }

        if (currentBlockTime > _preSaleStartTime) {
            presale = MerkleProof.verify(proof, _rootPreSale, leaf);
        }

        return (presale || groupone || grouptwo);
    }
}