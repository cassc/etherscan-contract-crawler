// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./tokens/interfaces/IChill.sol";

pragma solidity ^0.8.2;

interface NFTContract is IERC721, IERC721Enumerable {}


/**
 * @author Astrid Fox
 * @title Loopy Cups contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 * @custom:security-contact [email protected]
 */
contract LoopyCups is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public immutable MAX_TOKENS;
    uint256 public immutable MAX_FOR_SALE;
    uint256 public immutable MAX_FOR_CHILL_SALE;
    uint256 public immutable OFFSET_START;

    string public PROVENANCE;
    uint256 public SALE_END;

    uint256 public cupPrice = 0.025 ether;
    uint256 public cupChillPrice = 750 ether;

    uint public constant maxCupsPurchase = 20;

    bool public saleIsActive = false;

    // Base URI
    string public baseMetadataURI;

    // Backup URIs
    mapping (uint256 => string) public backupURIs;

    // Contract lock - when set, prevents altering the base URLs saved in the smart contract
    bool public locked = false;

    // Tracks how many Loopy Cups have been purchased with ETH
    uint256 public cupsPurchasedWithEth = 0;

    // Tracks how many Loopy Cups have been purchased with CHILL
    uint256 public cupsPurchasedWithChill = 0;

    // Tracks burnt tokens
    mapping (uint256 => bool) public burntCups;

    // Loopy Donuts smart contract
    NFTContract public immutable loopyDonuts;

    // Chill Token contract
    IChill public immutable chillToken;


    /**
    @param _name - Name of the ERC721 token.
    @param _symbol - Symbol of the ERC721 token.
    @param _maxSupply - Maximum number of tokens to allow minting.
    @param _maxForSale - Maximum number of tokens to allow selling.
    @param _maxForChillSale - Maximum number of tokens to allow selling with Chills.
    @param _saleEndTs - Timestamp in seconds of sale end.
    @param _provenance - The sha256 string of concatenated sha256 of all images in their natural order - AKA Provenance.
    @param _metadataURI - Base URI for token metadata
    @param _ldAddress - Address of the Loopy Donuts smart contract.
    @param _chillToken - Address of the Chill token
     */
    constructor(string memory _name,
                string memory _symbol,
                uint256 _maxSupply,
                uint256 _maxForSale,
                uint256 _maxForChillSale,
                uint256 _saleEndTs,
                string memory _provenance,
                string memory _metadataURI,
                address _ldAddress,
                address _chillToken
    )
        ERC721(_name, _symbol)
    {
        MAX_TOKENS = _maxSupply;
        MAX_FOR_SALE = _maxForSale;
        MAX_FOR_CHILL_SALE = _maxForChillSale;
        SALE_END = _saleEndTs;
        PROVENANCE = _provenance;
        baseMetadataURI = _metadataURI;
        loopyDonuts = NFTContract(_ldAddress);
        chillToken = IChill(_chillToken);
        OFFSET_START = MAX_TOKENS - MAX_FOR_SALE;
    }


    /**
    * @dev Throws if the contract is already locked
    */
    modifier notLocked() {
        require(!locked, "Contract already locked.");
        _;
    }


    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function payTo(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Not allowed to send to 0 address");
        uint balance = address(this).balance;
        require(amount <= balance, "Not enough balance");

        payable(to).transfer(amount);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    /**
     * Reserve Loopy Cups.
     */
    function reserveCups(address to, uint256 amount) public onlyOwner {
        uint offset = OFFSET_START + cupsPurchasedWithEth + cupsPurchasedWithChill;
        require(offset + amount <= MAX_TOKENS, "Reserving would exceed supply.");

        for (uint i = 0; i < amount; i++) {
            _safeMint(to, offset + i);
        }
    }


    /**
     * Sets the sale ending timestamp
     */
    function setSaleEndTimestamp(uint256 newDate) public onlyOwner notLocked {
        SALE_END = newDate;
    }


    /*     
    * Set provenance hash - in case there is an error.
    * Provenance hash is set in the contract construction time,
    * ideally there is no reason to ever call it.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner notLocked {
        PROVENANCE = provenanceHash;
    }


    /**
     * @dev Pause sale if active, activate if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }


    /**
     * @dev Locks the contract - prevents changing it's properties. 
     */
    function lock() public onlyOwner notLocked {
        require(bytes(baseMetadataURI).length > 0,
                "Thou shall not lock prematurely!");
        locked = true;
    }


    /**
     * @dev Sets the price for minting
     */
     function setPrice(uint256 newPrice) external onlyOwner notLocked {
         require(newPrice > 0, "Invalid price.");
         cupPrice = newPrice;
     }

    /**
     * @dev Sets the price for minting
     */
     function setChillPrice(uint256 newPrice) external onlyOwner notLocked {
         require(newPrice > 0, "Invalid price.");
         cupChillPrice = newPrice;
     }


     /**
     * @dev Sets the Metadata Base URI for computing the {tokenURI}.
     */
    function setMetadataBaseURI(string memory newURI) public onlyOwner notLocked {
        baseMetadataURI = newURI;
    }


     /**
     * @dev Modifies the backup Base URI of `backupNumber`.
     */
    function modifyBackupBaseURI(uint256 backupNumber, string memory newURI) external onlyOwner notLocked {
        backupURIs[backupNumber] = newURI;
    }


    /**
     * @dev Adds a new backup Base URI corresponding to `backupNumber`.
     * Allows adding new backups even after contract is locked.
     */
    function addBackupBaseURI(uint256 backupNumber, string memory newURI) external onlyOwner {
        require(bytes(backupURIs[backupNumber]).length == 0, "LoopyCups: URI already exists for backupNumber");
        backupURIs[backupNumber] = newURI;
    }


    /**
     * @dev Returns the tokenURI if exists.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Deployer should make sure that the selected base has a trailing '/'
        return bytes(baseMetadataURI).length > 0 ? 
                string( abi.encodePacked(baseMetadataURI, tokenId.toString(), ".json") ) :
                "";
    }


    /**
    * @dev Returns the backup URI to the token's metadata -
    * as specified by the `backupNumber`
    */
    function getBackupTokenURI(uint256 tokenId, uint256 backupNumber) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory backupURI = backupURIs[backupNumber];
        require(bytes(backupURI).length > 0, "LoopyCups: Invalid backupNumber");

        return string( abi.encodePacked(backupURI, tokenId.toString(), ".json") );
    }


    /**
    * @dev Returns the base URI. Internal override method.
    */
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseMetadataURI;
    }


    /**
    * @dev Returns the base URI. Public facing method.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }


    /**
     * @dev Returns an array of all the tokenIds owned by `ownerToCheck`.
     */
    function tokensOfOwner(address ownerToCheck) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(ownerToCheck);
        uint256[] memory tokenIds = new uint256[](balance);

        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(ownerToCheck, i);
        }

        return tokenIds;
    }


    /**
     * @dev Claims all Loopy Cups for the Loopy Donuts holder `msg.sender`
     * which were not already claimed.
     */
    function claimAll() public nonReentrant {
        require(saleIsActive, "Sale is not active."); 
        uint balance = loopyDonuts.balanceOf(msg.sender);

        for (uint i = 0; i < balance; i++) {
            uint donutId = loopyDonuts.tokenOfOwnerByIndex(msg.sender, i);

            if (!(_exists(donutId) || burntCups[donutId])) {
                _safeMint(msg.sender, donutId);
            }
        }
    }


    /**
     * @dev Claims Loopy Cups for the holder `msg.sender` - 
     * of unclaimed Loopy Donuts specified by `donutIds`.
     */
    function claimSpecific(uint256[] calldata donutIds) external nonReentrant {
        require(saleIsActive, "Sale is not active."); 
        for (uint i = 0; i < donutIds.length; i++) {
            uint donutId = donutIds[i];

            require(msg.sender == loopyDonuts.ownerOf(donutId), "Not owner of Donut");
            
            if (!(_exists(donutId) || burntCups[donutId])) {
                _safeMint(msg.sender, donutId);
            }
        }
    }


    /**
    * @dev Mints Loopy Cups.
    * Ether value sent must exactly match.
    */
    function mintCups(uint toMint) public payable nonReentrant {
        require(saleIsActive && block.timestamp < SALE_END, "Sale is not active.");
        require(toMint <= maxCupsPurchase, "Can only mint 20 Cups at a time.");
        require(cupsPurchasedWithEth + cupsPurchasedWithChill + toMint <= MAX_FOR_SALE, "Not enough Cups for sale.");
        require(cupPrice * toMint == msg.value, "Ether value sent is not correct.");

        uint offset = OFFSET_START + cupsPurchasedWithEth + cupsPurchasedWithChill;

        cupsPurchasedWithEth += toMint;

        for(uint i = 0; i < toMint; i++) {
            _safeMint(msg.sender, offset + i);
        }
    }

    /**
    * @dev Mints Loopy Cups with Chill.
    * Ether value sent must exactly match.
    */
    function mintCupsWithChill(uint toMint, uint fromWallet, uint[] calldata donutIds, uint[] calldata amounts) public nonReentrant {
        require(saleIsActive, "Sale is not active.");
        require(toMint <= maxCupsPurchase, "Can only mint 20 Cups at a time.");
        require(cupsPurchasedWithEth + cupsPurchasedWithChill + toMint <= MAX_FOR_SALE, "Not enough Cups for sale.");
        require(cupsPurchasedWithChill + toMint <= MAX_FOR_CHILL_SALE, "Not enough Cups for sale with CHILL.");
        
        uint totalChill = fromWallet;
        for(uint i = 0; i < amounts.length; i++) {
            totalChill += amounts[i];
        }
        
        require(cupChillPrice * toMint == totalChill, "CHILL value sent is not correct.");
        
        if (fromWallet > 0) {
            chillToken.externalBurnFrom(msg.sender, fromWallet, 0, "");
        }
        if (amounts.length > 0) {
            chillToken.externalSpendMultiple(msg.sender, donutIds, amounts, 0, "");
        }
        
        uint offset = OFFSET_START + cupsPurchasedWithEth + cupsPurchasedWithChill;

        cupsPurchasedWithChill += toMint;

        for(uint i = 0; i < toMint; i++) {
            _safeMint(msg.sender, offset + i);
        }
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
        burntCups[tokenId] = true;
    }

}