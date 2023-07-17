//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Alphi Genesis Mint 
/// @notice Main contract governing the minting and experience boosting of 
/// Alphi Genesis NFTs
contract AlphiGenesis is
ERC721,
ERC721Enumerable,
ERC721URIStorage,
Ownable,
ERC2981
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    // ------------------------------------------------------------------------
    // State Variables: Immutable Token Parameters
    // ------------------------------------------------------------------------
    
    /// @dev Max supply of NFTs that can be minted in this contract
    uint256 public immutable MAX_SUPPLY;
    /// @dev Max supply of NFTs that can be minted during the initial sale
    uint256 public immutable MAX_SALE;
    /// @dev Initial sale price of minting the NFTs
    uint256 public immutable PRICE;
    /// @dev Max amount of NFTs a wallet can mint
    uint256 public immutable MAX_MINT_PER_WALLET;
    /// @dev Default amount of NFTs a wallet can mint during the promotional mint
    uint256 public immutable DEFAULT_PROMO_MINT;
    
    // ------------------------------------------------------------------------
    // State Variables: Mutable Token Parameters
    // ------------------------------------------------------------------------
    
    /// @dev Base token URI for all NFTs in this contract
    string public baseTokenURI;
    
    // ------------------------------------------------------------------------
    // State Variables: Minting Parameters
    // ------------------------------------------------------------------------
    
    /// @dev A counter to keep track of the token IDs
    Counters.Counter private _tokenIdCounter;
    
    /// @dev Mapping from account address to the number of NFTs that account
    /// has minted
    mapping(address => uint256) public numberAddressMinted;
    
    /// @dev Mapping from account address to the number of NFTs that account 
    /// has minted through the promotional period. If the promotional mint is set
    /// to zero, the minting function will default to the DEFAULT_PROMO_MINT
    mapping(address => uint256) public promotionalMinted;
    
    /// @dev Mapping from account address to the number of NFTs that account is 
    /// allowed to mint during the promotional period
    mapping(address => uint256) public promotion;
    
    /// @dev Flag indicating if wave 1 is currently active
    bool public wave1 = false;
    /// @dev Flag indicating if wave 2 is currently active
    bool public wave2 = false;
    /// @dev Flag indicating if wave 3 is currently active
    bool public wave3 = false;
    
    /// @dev Mapping from account address to a boolean indicating if that 
    /// account is on wave 1 allow list
    mapping(address => bool) public allowListWave1;
    
    /// @dev Mapping from account address to a boolean indicating if that
    /// account is on wave 2 allow list
    mapping(address => bool) public allowListWave2;
    
    // ------------------------------------------------------------------------
    // State Variables: Experience Boost
    // ------------------------------------------------------------------------
    
    /// @dev Mapping from account address to a boolean indicating if the token 
    /// is currently soft-locked
    mapping(uint256 => bool) public tokenLocked;
    
    /// @dev Mapping from token ID to the most recent block timestamp (seconds)
    /// the token was either locked or unlocked
    mapping(uint256 => uint256) public timeModified;
    
    /// @dev Mapping from token ID to the total amount of time (seconds) the 
    /// token has been locked over its lifetime
    mapping(uint256 => uint256) public lifetimeLocked;
    
    // ------------------------------------------------------------------------
    // Events: Experience Boost
    // ------------------------------------------------------------------------
    
    /// @notice Emitted when an account locks their NFT for experience boost
    /// @param sender The account that locked their NFT  
    /// @param id The token ID that has been locked 
    /// @param time The block timestamp (seconds) when the token was locked
    event ExperienceLocked(
        address indexed sender,
        uint256 indexed id,
        uint256 indexed time
    );
    
    /// @notice Emitted when an account unlocks their NFT to disable exp boost
    /// @param sender The account that unlocked their NFT
    /// @param id The token ID that has been unlocked 
    /// @param time The block timestamp (seconds) when the token was unlocked
    event ExperienceUnlocked(
        address indexed sender,
        uint256 indexed id,
        uint256 indexed time
    );
    
    // ------------------------------------------------------------------------
    // Events: Mint Management
    // ------------------------------------------------------------------------
    
    /// @notice Emitted when wave 1 of the mint is activated or deactivated
    /// @param active The current state of wave 1 
    /// (true = active, false = inactive)
    event Wave1Active(bool indexed active);
    
    /// @notice Emitted when wave 2 of the mint is activated or deactivated
    /// @param active The current state of wave 2 
    /// (true = active, false = inactive)
    event Wave2Active(bool indexed active);
    
    /// @notice Emitted when wave 3 of the mint is activated or deactivated
    /// @param active The current state of wave 3 
    /// (true = active, false = inactive)
    event Wave3Active(bool indexed active);
    
    // ------------------------------------------------------------------------
    // Contract Initialization
    // ------------------------------------------------------------------------
    
    /// @dev Creates a new AlphiGenesis contract with the provided parameters.
    /// @param _uName The name of the NFT.
    /// @param _uSymbol The symbol of the NFT.
    /// @param _maxSupply The maximum supply of tokens.
    /// @param _price The price per token in wei.
    /// @param _maxPerWallet The maximum number of tokens allowed to be minted 
    /// per wallet.
    /// @param _initialBaseURI The initial base URI for the token metadata.
    /// @param _royaltyRecipient The recipient of the royalty fees.
    /// @param _royaltyBasisPoints The royalty fee as a percentage in basis 
    /// points.
    constructor(
        string memory _uName,
        string memory _uSymbol,
        uint256 _maxSupply,
        uint256 _maxSale,
        uint256 _price,
        uint256 _maxPerWallet,
        uint256 _promoMint,
        string memory _initialBaseURI,
        address _royaltyRecipient,
        uint96 _royaltyBasisPoints
    ) ERC721(_uName, _uSymbol) {
        MAX_SUPPLY = _maxSupply;
        MAX_SALE = _maxSale;
        PRICE = _price;
        MAX_MINT_PER_WALLET = _maxPerWallet;
        DEFAULT_PROMO_MINT = _promoMint;
        baseTokenURI = _initialBaseURI;
        _setDefaultRoyalty(_royaltyRecipient, _royaltyBasisPoints);
    }
    
    // ------------------------------------------------------------------------
    // Functions: Modify Token Parameters
    // ------------------------------------------------------------------------
    
    /// @notice The contract owner can change the base token URI in order to 
    /// change the token metadata
    /// @dev Only the contract owner can call this function
    /// @param _baseTokenURI New token base URI as a string 
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
    
    /// @notice The contract owner can change the token URI of a single NFT 
    /// @dev Only the contract owner can call this function. The submitted 
    /// new URI will be concatenated with the base token URI 
    /// @param _tokenId The token ID of the NFT whose URI will be changed
    /// @param _newURI New URI that will be concatenated with the base URI 
    function changeTokenURI(uint256 _tokenId, string memory _newURI)
    public
    onlyOwner
    {
        _setTokenURI(_tokenId, _newURI);
    }
    
    // ------------------------------------------------------------------------
    // Functions: Mint Utilities
    // ------------------------------------------------------------------------
    
    /// @notice The contract owner can activate or deactivate wave 1 
    /// (free mint to accounts on Allow List 1) of the mint 
    /// @dev Only the contract owner can call this function
    /// @param _active A boolean value that indicates whether wave 1 is active 
    /// (true) or inactive (false)
    function activateWave1(bool _active) public onlyOwner {
        wave1 = _active;
        emit Wave1Active(wave1);
    }
    
    /// @notice The contract owner can activate or deactivate wave 2 
    /// (paid mint to accounts on Allow List 2) of the mint 
    /// @dev Only the contract owner can call this function 
    /// @param _active A boolean value that indicates whether wave 2 is active 
    /// (true) or inactive (false)
    function activateWave2(bool _active) public onlyOwner {
        wave2 = _active;
        emit Wave2Active(wave2);
    }
    
    /// @notice The contract owner can activate or deactivate wave 3 
    /// (paid mint to all accounts of the general public) of the mint 
    /// @dev Only the contract owner can call this function
    /// @param _active A boolean value that indicates whether wave 3 is active 
    /// (true) or inactive (false)
    function activateWave3(bool _active) public onlyOwner {
        wave3 = _active;
        emit Wave3Active(wave3);
    }
    /// @notice Gets the amount of NFTs that an account has minted
    /// @param _mintedAddress Address of the account to check
    /// @return Number of NFTs the account has already minted
    function amountMinted(address _mintedAddress)
    public
    view
    returns (uint256)
    {
        return (numberAddressMinted[_mintedAddress]);
    }
    
    /// @notice Gets the amount of NFTs that an account has minted in wave 1 
    /// @param _mintedAddress Address of the account to Check
    /// @return Number of NFTs the account has already minted in wave 1
    function numPromotionMinted(address _mintedAddress)
    public
    view
    returns (uint256)
    {
        return (promotionalMinted[_mintedAddress]);
    }
    
    /// @notice Sets a custom amount of NFTs an address can mint in wave 1 
    /// @dev Only the contract owner can call this function
    /// @param _address Address of the account to set the limit for
    /// @param _amount Number of NFTs the account can mint in wave 1 
    function setPromotion(address _address, uint256 _amount) public onlyOwner {
        promotion[_address] = _amount;
    }

    /// @notice Gets the amount of NFTs that an account can mint in wave 1 
    /// @param _address Address of the account to Check
    /// @return Number of NFTs the account can mint in wave 1 
    function promoLimit(address _address) public view returns (uint256){
        return (promotion[_address]);
    }
    
    /// @notice Contract owner can add an array of addresses to the allow list
    /// for wave 1
    /// @dev Only the contract owner can call this function.
    /// For each address in the array, it sets the corresponding mapped value
    /// to true.
    /// @param _wAddresses Array of addresses to add to the wave 1 allow list
    function addWave1Address(address[] calldata _wAddresses) public onlyOwner {
        for (uint256 i = 0; i < _wAddresses.length; i++) {
            allowListWave1[_wAddresses[i]] = true;
        }
    }
    
    /// @notice Contract owner can add an array of addresses to the allow list
    /// for wave 2
    /// @dev Only the contract owner can call this function.
    /// For each address in the array, it sets the corresponding mapped value
    /// to true.
    /// @param _wAddresses Array of addresses to add to the wave 2 allow list
    function addWave2Address(address[] calldata _wAddresses) public onlyOwner {
        for (uint256 i = 0; i < _wAddresses.length; i++) {
            allowListWave2[_wAddresses[i]] = true;
        }
    }
    
    /// @notice Contract owner can remove an array of addresses to the allow 
    /// list for wave 1
    /// @dev Only the contract owner can call this function.
    /// For each address in the array, it sets the corresponding mapped value
    /// to false.
    /// @param _wAddresses Array of addresses to remove from the wave 1 allow 
    /// list
    function removeWave1Address(address[] calldata _wAddresses) 
    public 
    onlyOwner 
    {
        for (uint256 i = 0; i < _wAddresses.length; i++) {
            allowListWave1[_wAddresses[i]] = false;
        }
    }
    
    /// @notice Contract owner can remove an array of addresses to the allow 
    /// list for wave 2
    /// @dev Only the contract owner can call this function.
    /// For each address in the array, it sets the corresponding mapped value
    /// to false.
    /// @param _wAddresses Array of addresses to remove from the wave 2 allow 
    /// list
    function removeWave2Address(address[] calldata _wAddresses) 
    public 
    onlyOwner 
    {
        for (uint256 i = 0; i < _wAddresses.length; i++) {
            allowListWave2[_wAddresses[i]] = false;
        }
    }
    
    /// @notice View all wave status 
    /// @return Status of each wave in an array 
    /// (index 0: Wave 1, index 1: Wave 2, index 2: Wave 3)
    function waveActive()
    public
    view
    returns (
        bool,
        bool,
        bool
    )
    {
        return (wave1, wave2, wave3);
    }
    
    /// @notice Checks which allow list an account has been added to 
    /// @param _address Account to query
    /// @return Array booleans indicating which list(s) the account has been 
    /// added to (index 0: Wave 1, index 1: Wave 2)
    function isOnList(address _address) public view returns (bool, bool) {
        return (allowListWave1[_address], allowListWave2[_address]);
    }
    
    // ------------------------------------------------------------------------
    // Functions: Minting
    // ------------------------------------------------------------------------
    
    /// @notice Mints a new NFT based on the current wave that is active and 
    /// the account's allow list status, number of tokens already minted, and 
    /// whether the max supply of the NFT has been reached. 
    /// @dev Users need to be in the correct allow list mapping and they need 
    /// to provide sufficient ETH based on the wave of the sale. 
    /// This function assumes that the same address has not been added 
    /// to multiple allow lists (if they are, the first list will be used).  
    /// Must not have already minted the maximum allowed tokens per wallet 
    /// (amountMinted(msg.sender) < MAX_MINT_PER_WALLET).
    /// Must not have reached the maximum supply of tokens 
    /// (_tokenIdCounter.current() < MAX_SUPPLY).
    /// Emits a transfer event on the successful minting of a token  
    function genesisMint() public payable {
        require(
            amountMinted(msg.sender) < MAX_MINT_PER_WALLET,
            "Already minted maximum"
        );
        require(
            _tokenIdCounter.current() < MAX_SALE, 
            "Max supply reached"
        );

        if (allowListWave2[msg.sender]) {
            require(
                wave2, 
                "Wave 2 is not currently active"
            );
            require(
                msg.value >= PRICE, 
                "Not enough ETH sent; check price!"
            );
            numberAddressMinted[msg.sender] = amountMinted(msg.sender) + 1;
            _saleMint(msg.sender);
        } else {
            require(
                wave3, 
                "Public minting currently not active"
            );
            require(
                msg.value >= PRICE, 
                "Not enough ETH sent; check price!"
            );
            numberAddressMinted[msg.sender] = amountMinted(msg.sender) + 1;
            _saleMint(msg.sender);
        }
    }

    function promoMint() public payable {
        require(
            wave1,
            "Wave 1 is not currently active"
        );
        require(
            allowListWave1[msg.sender],
            "You are not on the allow list"
        );
        require(
            _tokenIdCounter.current() < MAX_SALE,
            "Max supply reached"
        );

        uint256 _maxMint = promotion[msg.sender];
        uint256 _numMinted = promotionalMinted[msg.sender];

        if (_maxMint == 0) {
            require(
                _numMinted < DEFAULT_PROMO_MINT,
                "Already minted maximum promotional tokens"
            );
            promotionalMinted[msg.sender] = _numMinted + 1;
            _saleMint(msg.sender);
        } else {
            require(
                _numMinted < _maxMint,
                "Already minted maximum promotional tokens"
            );
            promotionalMinted[msg.sender] = _numMinted + 1;
            _saleMint(msg.sender);
        }
    }

    /// @notice Allows the contract owner to mint a reward NFT to the address
    /// of their choosing
    /// @dev Only the contract owner can call this function. 
    /// The account that is being minted to must not hawe already minted the 
    /// maximum amount of NFTs (amountMinted(to) < MAX_MINT_PER_WALLET).
    /// The maximum token supply of the contract must not have been reached
    /// (_tokenIdCounter.current() < MAX_SUPPLY).
    /// Emits a transfer event on the successful minting of a token 
    /// @param to The address that should receive the minted token
    function ownerGenesisMint(address to) public onlyOwner {
        require(
            _tokenIdCounter.current() < MAX_SUPPLY, 
            "Max supply reached"
        );
        _saleMint(to);
    }

    /// @dev Writes all possible data before calling mint function. Then writes
    /// the token URI for the newly minted NFT
    /// @param to The address that will be receiving the minted NFT
    function _saleMint(address to) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenId.toString());
    }
    

    // ------------------------------------------------------------------------
    // Functions: Experience Boost
    // ------------------------------------------------------------------------

    /// @notice User can lock an NFT they own to activate experience boost 
    /// @dev For the function call to be successful, the token needs to have 
    /// been minted (_exists(_tokenId), the caller needs to own the NFT 
    /// (ownerOf(_tokenId) == msg.sender), and the token must be currently 
    /// unlocked (!tokenLocked(_tokenId))
    /// Emits an event on successful token lock 
    /// @param _tokenId Token ID of the NFT the user wishes to lock 
    function experienceLock(uint256 _tokenId) public {
        require(
            _exists(_tokenId), 
            "Token not minted"
        );
        require(
            ownerOf(_tokenId) == msg.sender,
            "Token not owned by the caller"
        );
        require(
            !tokenLocked[_tokenId], 
            "Token already locked"
        );
        tokenLocked[_tokenId] = true;
        timeModified[_tokenId] = block.timestamp;
        emit ExperienceLocked(msg.sender, _tokenId, timeModified[_tokenId]);
    }

    /// @notice User can unlock an NFT they own to deactivate experience boost 
    /// @dev For the function call to succeed, the token needs to have been 
    /// minted (_exists(_tokenId), the caller needs to own the 
    /// NFT (ownerOf(_tokenId) == msg.sender), and the token must be currently 
    /// locked (tokenLocked(_tokenId))
    /// Emits an event on successful token unlock 
    /// @param _tokenId Token ID of the NFT the user wishes to unlock 
    function experienceUnlock(uint256 _tokenId) public {
        require(
            _exists(_tokenId), 
            "Token not minted"
        );
        require(
            ownerOf(_tokenId) == msg.sender,
            "Token not owned by the caller"
        );
        require(
            tokenLocked[_tokenId], 
            "Token already unlocked"
        );
        tokenLocked[_tokenId] = false;
        lifetimeLocked[_tokenId] += lastExperienceInteraction(_tokenId);
        timeModified[_tokenId] = block.timestamp;
        emit ExperienceUnlocked(msg.sender, _tokenId, timeModified[_tokenId]);
    }

    /// @notice Checks locked status of an NFT in this collection
    /// @dev Checks if the token has been minted
    /// @param _tokenId Token ID of the NFT 
    /// @return Boolean locked status of the NFT (true = locked, false = unlocked)
    function isLocked(uint256 _tokenId) public view returns (bool) {
        require(
            _exists(_tokenId), 
            "Token not minted"
        );
        return tokenLocked[_tokenId];
    }

    /// @notice Gets the total time since the NFT was last locked (for total 
    /// lifetime locked call getLifetimeLocked(_tokenId) instead)
    /// @dev Checks if the token has been minted.
    /// @param _tokenId Token ID of the NFT to check status
    /// @return Total time locked in the most recent locking period (seconds)
    function getTimeLocked(uint256 _tokenId) public view returns (uint256) {
        require(
            _exists(_tokenId), 
            "Token not minted"
        );
        if (tokenLocked[_tokenId]) {
            return lastExperienceInteraction(_tokenId);
        } else {
            return 0;
        }
    }

    /// @notice Gets the total historical locking time of an NFT (for total 
    /// time locked in the current locking interaction, call 
    /// getTimeLocked(_tokenId) instead)
    /// @dev Checks if the token has been minted
    /// @param _tokenId Token ID of the NFT to check status
    /// @return Total historical time locked (seconds)
    function getLifetimeLocked(uint256 _tokenId) public view returns (uint256) {
        require(
            _exists(_tokenId), 
            "Token not minted"
        );
        if (isLocked(_tokenId)) {
            return
                lifetimeLocked[_tokenId] + lastExperienceInteraction(_tokenId);
        } else {
            return lifetimeLocked[_tokenId];
        }
    }

    /// @notice Check how long ago a user interacted with an NFT for experience
    /// boost locking and unlocking
    /// @dev Checks to ensure the token has been minted. If the token has 
    /// never been locked, the transaction will revert 
    /// (timeModified[_tokenId] != 0)
    /// @param _tokenId Token ID of the NFT to check 
    /// @return Time (seconds) since the last user interaction locking or 
    /// unlocking the NFT 
    function lastExperienceInteraction(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        require(_exists(_tokenId), "Token not minted");
        require(timeModified[_tokenId] != 0, "Token has no interaction history");
        return block.timestamp - timeModified[_tokenId];
    }

    /// @notice Gets the block timestamp (seconds) of the last user interaction
    /// with experience boost locking and unlocking 
    /// @dev Checks to ensure the token has been minted. If the token has 
    /// never been locked, the transaction will revert 
    /// (timeModified[_tokenId] != 0)
    /// @param _tokenId Token ID of the NFT to check 
    /// @return Timestamp (seconds) of the last user interaction locking or 
    /// unlocking the NFT 
    function getTimeModified(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token not minted");
        require(timeModified[_tokenId] != 0, "Token has no interaction history");
        return timeModified[_tokenId];
    }

    // ------------------------------------------------------------------------
    // Functions: Withdraw Funds
    // ------------------------------------------------------------------------

    /// @notice The contract owner can withdraw all ETH held by this contract 
    /// @dev Only the contract owner can call this function. It will withdraw 
    /// all ETH to the contract owner's account 
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // ------------------------------------------------------------------------
    // Functions: ERC2981 Royalty Standard
    // ------------------------------------------------------------------------

    /// @notice The contract owner can set the receiving account and the 
    /// sale percentage of any royalty payments that are compatible with the 
    /// ERC 2981 Standard
    /// @dev Only the contract owner can call this function
    /// @param _receiver Address of the account to receive royalty payments
    /// @param _feeNumerator Fee percentage in basis points (e.g. 1% = 100 BP)
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    // ------------------------------------------------------------------------
    // Functions: Overrides for parent contracts
    // ------------------------------------------------------------------------

    /// @dev Fetches the current value of the base URI 
    /// @return The base token URI as a string
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Checks to see if the token has been locked for experience boost. 
    /// If it is locked, the transfer will fail and the transaction will
    /// revert. If the transfer is originating from the zero address, then 
    /// the transfer will be allowed since that is a minting event and the 
    /// token has no locked status. 
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        if (from != address(0)) {
            require(!isLocked(tokenId), "Token is locked, unlock to transfer");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    
    /// @dev _burn function is not used, but still needs to be overridden    
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}