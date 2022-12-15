// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

error ContractIsLocked();
error ContractIsNotLocked();
error MintingNotStarted();
error MintingFinished();
error InvalidSignature();
error OnlyHumans();
error isZero();
error ExcededMaxPerTx();
error ExcededMaxPerUser();
error InsufficientETH();
error NotYourToken();
error CollectionIsRevealed();
error CollectionIsNotRevealed();
error MissingBaseURI();
error MissingContractURI();
error MissingPreviewTokenURI();
error ReserveArlreadyClaimed();
error BeneficiaryReserveExceded();

/// @title ERC721JM
/// @author Joyce and TheSergeant
/// @notice You can use this contract to mint an ERC721JM NFT
contract ERC721JM is ERC721A, IERC2981, AccessControlEnumerable, ReentrancyGuard {
    using Strings for uint256;

    string internal __baseURI;
    string internal _contractURI;
    uint256 internal DEV_RESERVE;
    uint256 public immutable MAX_SUPPLY;
    uint256 internal immutable MAX_MINT_PER_BENEFICIARY;

    // IMPORTANT: the signer obj and the _signer solidity variable must have the same address
    address private _signer;
    uint256 public price = 0.2 ether;
    uint8 public maxPerUser = 2;
    uint8 public maxPerTx = 2;
    address[] public beneficiary;
    mapping(address => uint256) internal beneficiaryReserve;

    // ROYALTIES
    uint256 private royalties;
    address private royaltiesAddr;

    // CONTRACT STATE
    bool public isActive = false;
    bool public contractLocked = false;
    bool public isWhitelisteActive = true;
    bool private devMinted = false;
    bool public isRevealed = false;
    string public previewTokenURI;
    mapping(uint256 => string) public customTokenURI;

    // ROLE
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY_ROLE");

    // EVENTS
    event Mint(address _from, uint256 quantity, uint256 price);
    event Withdraw(address _from, uint256 quantity);
    event NewBaseURI(string _baseURI);
    event ActiveStatus(bool _ActiveStatus);
    event ContractLocked(bool _isLocked);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(
        string memory tokenName,
        string memory symbol,
        uint256 _collectionSize,
        uint256 _devReserved,
        uint256 _royalties,
        address[] memory _beneficiary
    ) ERC721A(tokenName, symbol) {
        __baseURI = "ipfs://";

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BENEFICIARY_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        // Minter Role
        for (uint256 i = 0; i < _beneficiary.length; i++) {
            _setupRole(BENEFICIARY_ROLE, _beneficiary[i]);
        }

        MAX_SUPPLY = _collectionSize;
        DEV_RESERVE = _devReserved;
        MAX_MINT_PER_BENEFICIARY = DEV_RESERVE / _beneficiary.length;

        royalties = _royalties;
        royaltiesAddr = address(this);

        setBeneficiary(_beneficiary);
        _signer = beneficiary[0]; //FIXME - msg.sender
    }

    /// @dev See {ERC721A-_startTokenId}.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @dev See {ERC721A-tokenURI}.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        // custom token URI
        if (bytes(customTokenURI[tokenId]).length > 0) {
            return customTokenURI[tokenId];
        }
        // is revealed
        if (!isRevealed && bytes(previewTokenURI).length != 0) {
            if (bytes(previewTokenURI).length == 0) revert MissingPreviewTokenURI();
            return previewTokenURI;
        } else {
            string memory baseURI = _baseURI();
            if (bytes(baseURI).length == 0) revert MissingBaseURI();
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
        }
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC165, AccessControlEnumerable)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev See {IERC2981-royaltyInfo}.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return (royaltiesAddr, (salePrice * royalties) / 100);
    }

    /// @notice Get contractURI
    /// @return (string memory) The JSON metadata of the collection
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Get baseURI
    /// @return (string memory) Base url of the collection
    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }

    modifier _requireMint(uint256 quantity) {
        if(!isActive) revert MintingNotStarted();
        if(quantity == 0) revert isZero();
        if(tx.origin != _msgSender()) revert OnlyHumans();
        if(totalSupply() + quantity > MAX_SUPPLY) revert MintingFinished();
        if(quantity > maxPerTx) revert ExcededMaxPerTx();
        if(_numberMinted(_msgSender()) + quantity > maxPerUser) revert ExcededMaxPerUser();
        _;
    }

    /// @notice  Mint the NFT to the caller addres
    /// @param quantity (uint256) Number of NFTs to mint
    /// @param signature (bytes) Whitelist signature
    /// @param nonce (bytes32) Nonce
    function mintToken(
        uint256 quantity,
        bytes calldata signature,
        bytes32 nonce
    ) external payable nonReentrant _requireMint(quantity){
        if (isWhitelisteActive) {
            if(!_verifySignature(signature, quantity, msg.value, nonce)) revert InvalidSignature();
        } else {
			if(msg.value < currentPrice() * quantity) revert InsufficientETH();
        }

        _safeMint(_msgSender(), quantity);
        //_mint(_msgSender(), quantity, '', false);
        emit Mint(_msgSender(), quantity, msg.value);
        // Refund excedeed ETH
        if (msg.value > (quantity * currentPrice()) && !isWhitelisteActive) {
            payable(_msgSender()).transfer(msg.value - (quantity * currentPrice()));
        }
    }

    /// @notice Check if an user is allowed to mint a token
    /// @notice It checks if the signature given by the user is valid
    /// @param signature (bytes) Signature to check
    /// @param quantity (uint256) Number of NFT requested to mint
    /// @param nonce (bytes32) Nonce
    /// @return (bool) Returns true if the signature is valid
    function _verifySignature(
        bytes calldata signature,
        uint256 quantity,
        uint256 _price,
        bytes32 nonce
    ) internal view returns (bool) {
        bytes32 hashMsg = keccak256(abi.encodePacked(address(this), _msgSender(), quantity, _price, nonce));
        address ecdsa_rec = ECDSA.recover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashMsg)),
            signature
        );
        return (ecdsa_rec == _signer) ? true : false;
    }

    /// @notice Returns the mint current price
    /// @return (uint256) Current price
    function currentPrice() public view returns (uint256) {
        return price;
    }

    /// @notice It emits a PermanentURI event required by OpenSea to freeze metadata for a particular url
    /// @param nftID (uint256) The ID of the NFT, you should be the owner
    function freezeMetadata(uint256 nftID) external {
        if(!contractLocked) revert ContractIsNotLocked();
        if(ownerOf(nftID) != _msgSender()) revert NotYourToken();
        if(!isRevealed) revert CollectionIsNotRevealed();
        emit PermanentURI(tokenURI(nftID), nftID);
    }


    //  ===================================
    //  ========= ADMIN FUNCTIONS =========
    //  ===================================

    /// @notice Set the Beneficiary
    function setBeneficiary(address[] memory _beneficiary) public onlyRole(DEFAULT_ADMIN_ROLE) {
        beneficiary = _beneficiary;
    }

    /// @notice Set the mint price
    /// @param newPrice (uint256) New price
    function setPrice(uint256 newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        price = newPrice;
    }

    /// @notice Reveal the collection
    function reveal() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isRevealed = true;
    }

    /// @notice Set a new signer for the whitelist
    /// @param signer (address) New signer
    function setSigner(address signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _signer = signer;
    }

    /// @notice Pause the contract
    /// @param _isActive (bool) ID of the NFT to retrive its metadata url
    function setActive(bool _isActive) external onlyRole(PAUSER_ROLE) {
        isActive = _isActive;
        emit ActiveStatus(isActive);
    }

    /// @notice Set the whitelist status
    /// @param _isWhitelisteActive (bool) ID of the NFT to retrive its metadata url
    function setWhitelistActive(bool _isWhitelisteActive) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isWhitelisteActive = _isWhitelisteActive;
    }

    /// @notice Set a new baseURI
    /// @param _baseTokenURI (string memory) New baseURI
    function setBaseTokenURI(string memory _baseTokenURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if(contractLocked) revert ContractIsLocked();
        __baseURI = _baseTokenURI;
        emit NewBaseURI(__baseURI);
    }

    /// @notice Set a new previewTokenURI
    /// @param _previewTokenURI (string memory) New previewTokenURI
    function setPreviewTokenURI(string memory _previewTokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(contractLocked) revert ContractIsLocked();
        if(isRevealed) revert CollectionIsRevealed();
        previewTokenURI = _previewTokenURI;
    }

    /// @notice Set a custom TokenURI for unique NFTs
    function setCustomTokenURI(string memory _customTokenURI, uint256 tokenID) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(contractLocked) revert ContractIsLocked();
        if(isRevealed) revert CollectionIsRevealed();
        customTokenURI[tokenID] = _customTokenURI;
    }

    /// @notice Lock contract
    function lockContract() external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractLocked = true;
        emit ContractLocked(true);
    }

    /// @notice Set the royalties on the contract
    /// @dev This function can be called only by ADMIN
    /// @param royaltyReceiver The royalties recipient
    /// @param royaltyPercentage Royalties value (between 0 and 10000)
    function setRoyalties(address royaltyReceiver, uint256 royaltyPercentage) public onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltiesAddr = royaltyReceiver;
        royalties = royaltyPercentage;
    }

    /// @notice Set a new contractURI
    /// @param _contractURI_ (string memory) The new contractURI
    function setContractURI(string memory _contractURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(contractLocked) revert ContractIsLocked();
        _contractURI = _contractURI_;
    }

    /// @notice Set the maximum amount of NFTs that can be minted per user
    function setMaxPerUser(uint8 _maxPerUser) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxPerUser = _maxPerUser;
    }

    /// @notice Set the maximum amount of NFTs that can be minted per Transaction
    function setMaxTransaction(uint8 _maxPerTransaction) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxPerTx = _maxPerTransaction;
    }

    /// @notice Claim an amount of NFTs reserved for the dev
    /// @param _number (uint256) Number of NFTs to claim
    function claimReserve(uint256 _number) external onlyRole(BENEFICIARY_ROLE) nonReentrant {
        if(devMinted) revert ReserveArlreadyClaimed();
        if(beneficiaryReserve[_msgSender()] + _number > MAX_MINT_PER_BENEFICIARY)  revert BeneficiaryReserveExceded();
        DEV_RESERVE -=  _number;
        beneficiaryReserve[_msgSender()] += _number;
        if (DEV_RESERVE == 0) devMinted = true;

        _safeMint(_msgSender(), _number);
    }

    /// @notice Allows to withdraw found from contract
    /// @dev This function can be called only from ADMIN
    function withdraw() external onlyRole(BENEFICIARY_ROLE) nonReentrant {
        uint256 balance = address(this).balance;
        if(balance == 0) revert InsufficientETH();
        uint256 beneficiaryNumber = beneficiary.length;
        uint256 amount = balance / beneficiaryNumber;
        for (uint256 i = 0; i < beneficiaryNumber; ) {
            payable(beneficiary[i]).transfer(amount);
            unchecked {
                i++;
            }
        }
        emit Withdraw(_msgSender(), balance);
    }
}