// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BACardV1 is Initializable, UUPSUpgradeable, ERC721Upgradeable, ERC2981, PausableUpgradeable, OwnableUpgradeable {
    /* ==================== VARIABLES SECTION ==================== */
    /**
    * @notice Maximum NFT supply
    *
    * @dev Maximum NFT that can be minted
    */
    // **NOTE: MAX_SUPPLY value should be change to 10000 before mainnet deployment
    uint256 public MAX_SUPPLY;

    /**
    * @notice Total supply
    *
    * @dev Total minted tokens
    */
    uint256 public totalSupply;

    /**
    * @notice Maximum Mint Per Transaction
    *
    * @dev Maximum NFT that can be minted per transaction. Avoiding Gas Limit error
    */
    uint256 public maxMintPerTransaction;

    /**
    * @notice Minting Price
    *
    * @dev Minting price for the tokens
    */
    uint256 public mintPrice;

    /**
    * @notice Minting Limit
    *
    * @dev value that will represent the mint limit
    */
    uint256 public mintLimit;

    /**
    * @dev this is the temporary metadata for all NFTs.
    */
    string public previewURI;

    /**
    * @notice Base token URI of token
    *
    * @dev This will hold the base uri for token metadata
    */
    string public baseURI;

    /**
    * @notice Contract-level metadata
    * 
    * @dev variable is declared for opensea contract-level metadata 
    *      for on-chain royalty see https://docs.opensea.io/docs/contract-level-metadata
    */
    string public contractURI;

    /**
    * @notice Suffix of baseTokenURI    
    */
    string tokenURISuffix;

    /**
    * @notice Withdrawal recipient address
    *
    * @dev Address that is capable to withdraw contract's balance
    */
    address public withdrawalAddress;

    /**
    * @notice Wallet Address to receive EIP-2981 royalties from secondary sales
    *         see https://eips.ethereum.org/EIPS/eip-2981
    *
    * @dev The wallet address here is a EOA
    */
    address public royaltyReceiverAddress;

    /**
    * @notice Percentage of token sale price to be used for EIP-2981 royalties from secondary sales
    *         see https://eips.ethereum.org/EIPS/eip-2981
    *
    * @dev Has 2 decimal precision. E.g. a value of 100 would result in a 1% royalty fee    
    */
    uint96 public royaltyFeesInBips;

    /**
    * @notice Mode to determine if tokenURI will return tokenIdURI or previewURI
    *
    * @dev Should be set to true after all nft is minted and migrated to ipfs
    */
    bool public revealURIMode;

    /**
    * @notice Merkle root
    *
    * @dev Should be set by owner after whitelising
    */
    bytes32 public merkleRoot;
    /* ==================== VARIABLES SECTION ==================== */

    /* ==================== MAPPING SECTION ==================== */
    /**
    * @notice Maps key => pair value
    *
    * @dev use token id to fetch the token uri
    */
    mapping(uint256 => string) public tokenURIOfIds;
    /* ==================== MAPPING SECTION ==================== */

    /* ==================== EVENTS SECTION ==================== */
    /**
    * @dev Called in `safeMint()` when we minted a token
    * 
    * @param _account owner of the token
    * @param _id token id of minted token
    */
    event MintNFT(address _account, uint256 _id);

    /**
    * @dev Called in `_withdraw()` when widthdrawing from contract balance
    * 
    * @param _withdrawalAddress address of calling the `_withdraw()`
    * @param _amount amount withdrawn
    */
    event Withdraw(address _withdrawalAddress, uint256 _amount);

    /**
    * @dev Called in `setRoyaltyInfo()` when update royalty info
    * 
    * @param _royaltyReceiverAddress address to receive EIP-2981 royalties from secondary sales 
    * @param royaltyFeesInBips has 2 decimal precision. E.g. a value of 100 would result in a 1% royalty fee
    */
    event SetRoyaltyInfo(address _royaltyReceiverAddress, uint96 royaltyFeesInBips);

    /**
    * @dev Fired in `setPreviewURI()` when update the previewURI
    * 
    * @param _previewURI new preview URI for nft
    */
    event SetPreviewURI(string _previewURI);

    /**
    * @dev Fired in `setBaseURI()` when update the baseURI
    * 
    * @param _baseURI new base URI for nft
    */
    event SetBaseURI(string _baseURI);

    /**
    * @dev Fired in `enableURIMode()` and `disableURIMode()` when update the revealURIMode
    * 
    * @param _uriMode mode for revealURIMode (true or false)
    */
    event SetBaseURIMode(bool _uriMode);

    /**
    * @dev Called in `setContractURI()` when update the contractURI
    * 
    * @param _contractURI new contractURI
    */
    event SetContractURI(string _contractURI);

    /**
    * @dev Called in `setTokenURI()` when update the tokenURIOfIds
    * 
    * @param _id of the token
    * @param _uri metadata of the token
    */
    event SetTokenURI(uint256 _id, string _uri);

    /**
    * @dev Called in `setWithdrawalRecipient()` when update withdrawalAddress
    * 
    * @param _withdrawalAddress new withdrawal address
    */
    event SetWithdrawalRecipient(address _withdrawalAddress);

    /**
    * @dev Called in `setMintPrice()` when update mintPrice
    * 
    * @param _price new mintPrice
    */
    event SetMintPrice(uint256 _price);

    /**
    * @dev Called in `setMintLimit()` when update mintLimit
    * 
    * @param _limit new mintLimit
    */
    event SetMintLimit(uint256 _limit);

    /**
    * @dev Fired in `setMerkleRoot()` when update merkleRoot
    * 
    * @param _merkleRoot value of new merkleRoot
    */
    event SetMerkleRoot(bytes32 _merkleRoot);
    /* ==================== EVENTS SECTION ==================== */

    /* ==================== MODIFIERS SECTION ==================== */
    /**
    * @dev Reverts if the caller is not an EOA of not the owner    
    */
    modifier isCallerAllowed() {
        require(tx.origin == msg.sender || owner() == msg.sender, "IC"); // Invalid Caller
        _;
    }

    /**
    * @dev Reverts if the totalSupply plus the id is greater than max supply
    * @dev Reverts if the id is greater than max mint per transaction
    */
    modifier isIdPassed1(uint256 _id) {           
        require((totalSupply + _id) <= MAX_SUPPLY, "MR"); // Max Reached
        require(_id <= maxMintPerTransaction, "MI"); // Max Invalid  
        _;
    }

    /**
    * @dev Reverts if the payment is not equal to the mint price for tier
    */
    modifier isIdPassed2(uint256[] memory _ids) {
        uint256 _correctPayment;
        
        require((totalSupply + _ids.length) <= mintLimit, "MLR"); // Max Limit Reached 
        for (uint256 x = 0; x <= (_ids.length - 1); x++) {      
            _correctPayment += mintPrice;
        }
        require(msg.value == _correctPayment, "IP"); // Incorrect Payment
        _;
    }

    /**
    * @dev Reverts if the token id is not existing
    */
    modifier isTokenExists(uint256 _id) {
        require(_exists(_id), "TNE"); // Token Not Exist
        _;
    }

    /**
    * @dev called in `mint()`
    * @dev Reverts if caller is not whitelisted
    */
    modifier isNotWhitelisted(bytes32[] memory _merkleproof) {
        require(isValidMerkleProof(_merkleproof, keccak256(abi.encodePacked(msg.sender))), "NW"); // Not Whitelisted
        _;
    }  
    /* ==================== MODIFIERS SECTION ==================== */

    /* ==================== CONSTRUCTOR SECTION ==================== */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
    * @param _name name of the nft collection
    * @param _symbol symbol of the nft collection
    * @param _price minting amount of the nft collection
    *
    */
    function initialize
        (
            string memory _name,
            string memory _symbol,
            uint256 _price
        ) 
            initializer 
            public 
    {
        __ERC721_init(_name, _symbol);
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        // Constructor Pre-set function calls        
        MAX_SUPPLY = 10000; // initialized to 10,000.
        totalSupply = 0; // initialized to 0 as per default
        maxMintPerTransaction = 5; // initialized to 5.
        tokenURISuffix = ".json"; // initialized to `.json` string
        withdrawalAddress = 0x5867230FdAcf4c8cD6a291eccd8bDdF849F85932; // NOTE: changed before mainnet deployment
        revealURIMode = false; // initialized to false as per default
        royaltyReceiverAddress = 0xD263877fd19f846B2A2403Fed7abec62b12da529; // NOTE: changed before mainnet deployment
        royaltyFeesInBips = 500; // NOTE: changed before mainnet deployment

        setRoyaltyInfo(royaltyReceiverAddress, royaltyFeesInBips);
        mintPrice = _price;
        pause();
    }
    /* ==================== CONSTRUCTOR SECTION ==================== */

    /* ==================== PAUSABLE SECTION ==================== */
    /**
    * @dev Pause the contract. This will disallowed to execute `mint()`   
    */
    function pause() public onlyOwner {
        _pause();
    }

    /**
    * @dev Unpause the contract. This will allow to execute `mint()`
    */
    function unpause() public onlyOwner {
        _unpause();
    }
    /* ==================== PAUSABLE SECTION ==================== */

    /* ==================== REVEAL SECTION ==================== */
    /**
    * @dev update the revealURIMode value.
    * @dev it will allow to reveal the final metadata    
    */
    function setURIMode(bool _mode) external 
        onlyOwner 
    {
        revealURIMode = _mode;

        emit SetBaseURIMode(_mode);
    }
    /* ==================== REVEAL SECTION ==================== */

    /* ==================== SETTERS SECTION ==================== */
    /**
    * @dev Set new Preview URI for tokens
    *
    * @param _previewURI new preview URI for tokens
    */
    function setPreviewURI(string memory _previewURI)
        external
        onlyOwner
    {
        previewURI = _previewURI;

        emit SetPreviewURI(_previewURI);
    }

    /**
    * @dev Set new Base URI for tokens
    *
    * @param _newBaseURI new base URI for tokens
    */
    function setBaseURI(string memory _newBaseURI) 
        external
        onlyOwner 
    {
        baseURI = _newBaseURI;

        emit SetBaseURI(_newBaseURI);
    }

    /**
    * @dev Set new contract URI
    *
    * @param _uri new contract URI
    */
    function setContractURI(string memory _uri) 
        external 
        onlyOwner
    {
        contractURI = _uri;

        emit SetContractURI(_uri);
    }

    /**
    * @dev Set Token URI
    *
    * @param _id of the token
    * @param _uri metadata of the token
    */
    function setTokenURI(uint256 _id, string memory _uri)
        external
        onlyOwner
        isTokenExists(_id)
    {
        tokenURIOfIds[_id] = _uri;

        emit SetTokenURI(_id, _uri);
    }

    /**
    * @dev Set Mint Price
    *
    * @param _price amount of minting price
    */
    function setMintPrice(uint256 _price)
        external
        onlyOwner
    {
        mintPrice = _price;

        emit SetMintPrice(_price);
    }

    /**
    * @dev Set withdrawal address
    *
    * @param _recipient address that can withdraw the contract balance
    */
    function setWithdrawalRecipient(address _recipient)
        external        
        onlyOwner
    {
        require(_recipient != address(0),"ZA"); // Zero Address
        withdrawalAddress = _recipient;

        emit SetWithdrawalRecipient(_recipient);
    }

    /**
    * @dev Set merkleroot
    *
    * @param _root Merkleroot hash
    */
    function setMerkleRoot(bytes32 _root)
        external        
        onlyOwner
    {
        merkleRoot = _root;

        emit SetMerkleRoot(_root);
    }

    /**
    * @dev Set Mint Limit
    *
    * @param _limit value of minting limit
    */
    function setMintLimit(uint256 _limit)
        external 
        onlyOwner
    {
        mintLimit = _limit;

        emit SetMintLimit(_limit);
    }

    /**
    * @dev Set new royalty info
    *
    * @param _royaltyReceiverAddress address to receive royalty fee
    * @param _royaltyFeesInBips Percentage of token sale price to be used for
    *                                 EIP-2981 royalties from secondary sales
    *                                 Has 2 decimal precision. E.g. a value of 100 would result in a 1% royalty fee
    *                                 value should be replace before mainnet deployment
    */
    function setRoyaltyInfo(address _royaltyReceiverAddress, uint96 _royaltyFeesInBips)
        public 
        onlyOwner 
    {
        require(_royaltyReceiverAddress != address(0),"ZA"); // Zero Address
        royaltyReceiverAddress = _royaltyReceiverAddress;
        royaltyFeesInBips = _royaltyFeesInBips;
        _setDefaultRoyalty(_royaltyReceiverAddress, _royaltyFeesInBips);

        emit SetRoyaltyInfo(_royaltyReceiverAddress, _royaltyFeesInBips);
    }
    /* ==================== SETTERS SECTION ==================== */

    /* ==================== (EXTERNAL) SECTION ==================== */
    /**
    * @dev Call the `safeBatchMint()`
    * @dev Mint multiple tokens if whitelisted
    * @dev reverts if presale mode is false
    * @dev reverts if caller is not part of whitelist
    *
    * @param _to address of the token owner
    * @param _ids id of the tokens
    * @param _uris metadata for each token
    * @param _merkleproof proof that the address is part of merkletree
    */   
    function mint
        (
            address _to, 
            uint256[] calldata _ids,
            string[] calldata _uris, 
            bytes32[] memory _merkleproof
        )
            external 
            payable
            whenNotPaused
            isCallerAllowed
            isIdPassed1(_ids.length) 
            isIdPassed2(_ids)
            isNotWhitelisted(_merkleproof)
    {                
        safeBatchMint(_to, _ids, _uris); 
    }

    /**
    * @dev Call the `safeBatchMint()`
    * @dev Mint multiple tokens if owner
    *
    * @param _to owner of the tokens
    * @param _ids ids of the tokens
    * @param _uris metadata for each token
    */
    function mintByOwner
        (
            address _to, 
            uint256[] calldata _ids,
            string[] calldata _uris
        )
            external
            onlyOwner
            isIdPassed1(_ids.length)
    {       
        safeBatchMint(_to, _ids, _uris);
    }

    /**
    * @dev send the entire contract balance to withdrawal address
    * @dev reverts if withdrawal address is incorrect
    * @dev reverts if contract balance is zero
    */
    function withdrawAll() 
        external
    {
        require(withdrawalAddress == msg.sender, "IR"); // Invalid Recipient
        require((address(this).balance) > 0, "NB"); // No Balance
        uint256 balance = address(this).balance;
        _withdraw(balance);
    }
    /* ==================== (EXTERNAL) SECTION ==================== */ 

    /* ==================== (PRIVATE) SECTION ==================== */
    /**
    * @dev Call the `safeBatchMint()`
    * @dev Mint a token
    *
    * @param _to owner of the token
    * @param _tokenId id of the token
    * @param _uri metadata of token
    */
    function safeMint(address _to, uint256 _tokenId, string memory _uri)
        private
    {
        _safeMint(_to, _tokenId);
        totalSupply++;
        tokenURIOfIds[_tokenId] = _uri;

        emit MintNFT(_to, _tokenId);
    }

    /**
    * @dev Call the `mint()` and `mintByOwner()`
    * @dev Mint multiple tokens by owner
    *
    * @param _to owner of the token
    * @param _ids ids of the tokens
    * @param _uris metadata for each token
    */
    function safeBatchMint
        (
            address _to, 
            uint256[] calldata _ids,
            string[] memory _uris
        )
            private
    {
        for(uint256 x; x < _ids.length; x++) {
            uint256 _id = _ids[x];
            string memory _uri = _uris[x];
            safeMint(_to, _id, _uri);
        }
    }

    /**
    * @dev Private function called in `withdraw()` and `withdrawAll()`
    *
    * @param _amount amount to withdraw
    */
    function _withdraw(uint256 _amount) 
        private
    {
        (bool success, ) = (msg.sender).call{value: _amount}("");
        require(success, ": WF"); // Withdraw Failed

        emit Withdraw(msg.sender, _amount);    
    }

    /**
    * @dev Check if merkle proof is valid
    *
    * @param _merkleProof proof address that address is whitelisted
    * @param _merkleLeaf validate the proof by address (EOA or Contract Address)
    */
    function isValidMerkleProof(bytes32[] memory _merkleProof, bytes32 _merkleLeaf) 
        private 
        view 
        returns (bool)
    {
        return MerkleProof.verify(_merkleProof, merkleRoot, _merkleLeaf);
    }
    /* ==================== (PRIVATE) SECTION ==================== */

    /* ==================== (INTERNAL) SECTION ==================== */
    /**
    * @dev Authorized the upgrade of smart cotnract
    *
    * @param newImplementation the address of the implementation contract
    */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    /* ==================== (INTERNAL) SECTION ==================== */

    /* ==================== (OVERRIDES) SECTION ==================== */
    /**        
    * @dev Check if the nft is allowed to transfer to the receiver address.
    * @dev Hook that is called before any token transfer.
    *      see https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721-_beforeTokenTransfer-address-address-uint256-
    *      for more details.
    *
    * @param from wallet address of sender
    * @param to wallet address of receiver
    * @param tokenId id of the token
    * @param batchSize size of the batch of token being transferred
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal        
        override(ERC721Upgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // NOTE: The following functions are overrides required by Solidity.

    /**
    * @dev ERC721 token with storage based token URI management.
    *      see https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721URIStorage
    *      for more details
    *
    * @param tokenId id that hold the uri (points to the metadata) of the token
    */
    function tokenURI(uint256 tokenId)
        public
        view
        isTokenExists(tokenId)
        override(ERC721Upgradeable)
        returns (string memory)
    {
        string memory _tokenBaseURI = baseURI;

        if (revealURIMode == true) {
            return 
                bytes(_tokenBaseURI).length > 0 ? 
                string(abi.encodePacked(_tokenBaseURI, Strings.toString(tokenId), tokenURISuffix)) 
                : "";
        }

        return 
            bytes(tokenURIOfIds[tokenId]).length > 0
                ? tokenURIOfIds[tokenId]
                : string(abi.encodePacked(previewURI, "hidden", tokenURISuffix));
    }

    /**
    * @inheritdoc ERC2981
    */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    /* ==================== (OVERRIDES) SECTION ==================== */
}