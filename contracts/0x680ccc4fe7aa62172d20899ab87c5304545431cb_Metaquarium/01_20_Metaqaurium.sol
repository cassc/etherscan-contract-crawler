// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''."""""""","'''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''"▐╣╣╣╣╣╣╣╣▒'''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''"▐╣╣╣╣╣╣╣╣▒''''''''''''''''"""""""""""''''''''
// ''''''''''''''''''''''''''''''''''"▐╣╣╣╣╣╣╣╣▒'''''''''''''''''║████████▌''''''''
// ''''''''."""""""",'''''''"┌'''''''"▐╣╣╣╣╣╣╣╣▒"""""""'"''''''''║████████▌''''''''
// '''''''"▐╣╣╣╣╣╣╣╣▌'''''''"▐╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬█████████▌''''''''║████████▌''''''''
// ''''''''▐╣╣╣╣╣╣╣╣▌''''''''▐╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬█████████▌''''''''║████████▌''''''''
// ''''''''▐╣╣╣╣╣╣╣╣▌''''''''▐╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬█████████▌'''''''"'........'''''''''
// ''''''''▐╣╣╣╣╣╣╣╣▌"""""""'▐╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬█████████▌'''''"""""""''''''''''''''
// '''''''":¡¡¡¡¡¡¡;▐╣╣╣╣╣╣╣╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬δ         '''"█████████"''''''''''''
// '''''''''''''''''▐╣╣╣╣╣╣╣╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬Ü         '''"█████████"''''''''''''
// '''''''''''''''''▐╣╣╣╣╣╣╣╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬Ü         '''"█████████"''''''''''''
// '''''''"'""""""""▐╣╣╣╣╣╣╣╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬Ü         '''"█████████"''''''''''''
// '''''''"▐▒▒▒▒▒▒▒▒▒└└└└└└└└▐╬╬╬╬╬╬╬╬╣╣╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒'''"└└└└└└└└└"''''''''''''
// ''''''''▐╣╣╣╣╣╣╣╣▌''''''''▐╬╬╬╬╬╬╬╬╣╣╣╣╣╣╣╣╣╬╬╬╬╬╬╬╬╬▒''''''''''''''''''''''''''
// ''''''''▐╣╣╣╣╣╣╣╣▌''''''''▐╬╬╬╬╬╬╬╬╣╣╣╣╣╣╣╣╣╬╬╬╬╬╬╬╬╬▒''''''''''''''''''''''''''
// '''''''"▐╣╣╣╣╣╣╣╣▌'''''''"▐╬╬╬╬╬╬╬╬╣╣╣╣╣╣╣╣╣╬╬╬╬╬╬╬╬╬▒''''''''''''''''''''''''''
// '''''''"└││││││││└'''''''"▐╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣▒││││││││└''''''''''''''''''''''''''
// ''''''''''''''''''''''''''▐╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣▒'''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''▐╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣▒'''''''''''''''''''''''''''''''''''
// '''''''''''''''''''''''''"▐╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣▒'''''''''''''''''''''''''''''''''''
// '''''''''''''''''''''''''"└╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙░'''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

// ><((((+> A Deviant of House Zeppelin
import {ERC721A} from "erc721a/contracts/ERC721A.sol";

// ><((((+> The Opens of House Zeppelin
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {AccessControl, IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ><((((+> The Registry of Operators
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/// @dev ><((((º> Bones
struct TokenURI {
    uint256 tokenId;
    string uri;
}

/**
 *  @title METAQUARIUM - ETHEREUM EXHIBIT
 *  @author <^)))><>
 *  @notice Immerse yourself in the tranquil serenity of the Metaquarium.xyz,
 *  an innovative digital aquarium experience. As you navigate the spatial seas
 *  of the Ethereum Exhibit, you will encounter 8192 unique 3D fish NFTs.
 *  Their mesmerizing ballet and vivid colors breathe new life into the classic
 *  art of screensavers, reinventing them as transcendent aquarium experiences
 *  for the spatial age. Simply sit back, enjoy the vibes, and let the underwater
 *  pixels wash over you.
 *  @dev ><(((@> Welcome, and THANKS FROM ALL THE FISH <#)))><
 */
contract Metaquarium is
    ERC721A,
    Pausable,
    AccessControl,
    ERC2981,
    DefaultOperatorFilterer,
    ReentrancyGuard
{
    using Strings for uint256;

    // ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º>
    // EVENTS EVENTS EVENTS EVENTS EVENTS EVENTS EVENTS EVENTS EVENTS EVENTS
    // <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))><
    /// @notice Event for treasury account updates
    event TreasuryAccountUpdated(address newTreasuryAccount);
    /// @notice Event for withdraws
    event FundsWithdrawn();
    /// @notice Event for pause events
    event PauseEvent();
    /// @notice Received Function Called
    event Received(address, uint);
    ///@notice Metadata Updated
    event MetadataUpdate(uint256 tokenId);
    /// @notice BaseURI Updated
    event SetBaseUri(string newBaseUri);
    /// @notice Frozen Metadata
    event PermanentURI();

    // ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º>
    // CONSTANTS CONSTANTS CONSTANTS CONSTANTS CONSTANTS CONSTANTS CONSTANTS
    // <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))><
    /// @notice Maxiumum Supply
    uint256 public constant MAX_SUPPLY = 8192;
    /// @notice Maxiumum Supply Minus One
    uint256 public constant MAX_SUPPLY_MINUS_ONE = 8191;
    /// @notice Mint Cap
    uint256 public constant MINT_CAP = 2;

    // ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º>
    // PRIVATE VARIABLES PRIVATE VARIABLES PRIVATE VARIABLES PRIVATE VARIABLES
    // <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))><
    /// @notice Mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    /// @notice Treasury Account
    address payable private _treasuryAccount;
    /// @notice Pause Mint After Selling This Token ID
    uint256 private _pauseMintAtTokenId = 256;
    /// @notice Mint Price  (in wei)
    uint256 private _price = 0.1 ether;
    /// @notice Current Base URI
    string private _currentBaseURI = "ipfs://";
    /// @notice Flag to permanently freeze metadata
    bool private _metadataFrozen = false;
    /// @notice Public Mint Enabled
    bool private _publicMintEnabled = false;

    // ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º>
    // ROLES ROLES ROLES ROLES ROLES ROLES ROLES ROLES ROLES ROLES ROLES ROLES
    // <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))><
    /// @notice Access Control role for administrative functions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    /// @notice Access Control role for mint functions
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º>
    // ERRORS ERRORS ERRORS ERRORS ERRORS ERRORS ERRORS ERRORS ERRORS ERRORS
    // <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))><
    /// @notice ><((((!> Raised when insufficient funds are sent to mint
    error InsufficientFunds();
    /// @notice ><((((!> Raised when Max Supply is reached
    error MaxSupplyReached();
    /// @notice ><((((!> Raised when Mint Cap is exceeded
    error MintCapExceeded();
    /// @notice ><((((!> Raised when Metadata is frozen
    error MetadataFrozen();
    /// @notice ><((((!> Raised when Invalid
    error NoNoNo();

    // ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º>
    // MODIFIERS MODIFIERS MODIFIERS MODIFIERS MODIFIERS MODIFIERS MODIFIERS
    // <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))><
    /// @notice ><((((?> Modifier for minting
    modifier whenMintingEnabled() {
        require(_publicMintEnabled, "Minting is currently disabled");
        _;
    }

    // ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º>
    // INITIALIZER INITIALIZER INITIALIZER INITIALIZER INITIALIZER INITIALIZER
    // <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))><
    /// @notice ><((((()> 0o0o00o0o00o0o00o0o00o0o00o0o00o0o00o0o00o0o00o0o0
    constructor(
        address[] memory admins,
        address payable treasury,
        address minter
    ) ERC721A("Metaquarium", "MTQRM") {
        _treasuryAccount = treasury;
        _setDefaultRoyalty(treasury, 750);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, minter);
        for (uint256 i = 0; i < admins.length; i++) {
            _setupRole(ADMIN_ROLE, admins[i]);
        }
    }

    /// @notice ><(((*> Receive Function
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @notice ><(((*> Fallback Function
    fallback() external payable {
        emit Received(msg.sender, 0);
    }

    // ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º>
    // ADMIN ADMIN ADMIN ADMIN ADMIN ADMIN ADMIN ADMIN ADMIN ADMIN ADMIN ADMIN
    // <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))><

    /// @notice ><(((*> Pause contract
    function pause() external nonReentrant onlyRole(ADMIN_ROLE) {
        _pause();
        emit PauseEvent();
    }

    /// @notice ><(((*> Unpause contract
    function unpause() external nonReentrant onlyRole(ADMIN_ROLE) {
        _unpause();
        emit PauseEvent();
    }

    /// @notice ><(((*> Freeze Metadata Permanently
    function freezeMetadata() external nonReentrant onlyRole(ADMIN_ROLE) {
        _metadataFrozen = true;
        emit PermanentURI();
    }

    /// @notice ><(((*> Set the baseURI
    /// @param newBaseURI string new base URI
    function setBaseURI(
        string memory newBaseURI
    ) external nonReentrant onlyRole(ADMIN_ROLE) {
        _currentBaseURI = newBaseURI;
        emit SetBaseUri(newBaseURI);
    }

    /// @notice ><(((%> Set the royalty
    /// @param points uint96 royalty points
    function setRoyalty(
        uint96 points
    ) external nonReentrant onlyRole(ADMIN_ROLE) {
        _setDefaultRoyalty(_treasuryAccount, points);
    }

    /// @notice ><(((*> Set the treasury account
    /// @param newTreasuryAccount address payable new treasury account
    function setTreasuryAccount(
        address payable newTreasuryAccount
    ) external nonReentrant onlyRole(ADMIN_ROLE) {
        _treasuryAccount = newTreasuryAccount;
        emit TreasuryAccountUpdated(newTreasuryAccount);
    }

    /// @notice ><(((*> Set the mint price
    /// @dev Revert if the price is 0
    /// @param newDefaultMintPrice uint256 new mint price
    function setPrice(
        uint256 newDefaultMintPrice
    ) external nonReentrant onlyRole(ADMIN_ROLE) {
        if (newDefaultMintPrice == 0) revert NoNoNo();
        _price = newDefaultMintPrice;
    }

    /// @notice ><(((!> Set the _pauseMintAtTokenId
    /// @dev Revert if the tokenId invalid
    function setPauseMintAtTokenId(
        uint256 newPauseMintAtTokenId
    ) external nonReentrant onlyRole(ADMIN_ROLE) {
        if (
            newPauseMintAtTokenId == 0 ||
            newPauseMintAtTokenId > MAX_SUPPLY_MINUS_ONE
        ) revert NoNoNo();
        _pauseMintAtTokenId = newPauseMintAtTokenId;
    }

    /// @notice ><(((*> Set the token URI for a token
    /// @dev Revert if the tokenId invalid
    /// @dev Revert if the metadata is frozen
    /// @param tokenURIs array of TokenURI structs
    function setTokenMetadata(
        TokenURI[] calldata tokenURIs
    ) external nonReentrant onlyRole(ADMIN_ROLE) {
        if (_metadataFrozen) revert MetadataFrozen();
        for (uint256 i = 0; i < tokenURIs.length; i++) {
            if (tokenURIs[i].tokenId == 0 || tokenURIs[i].tokenId > MAX_SUPPLY)
                revert URIQueryForNonexistentToken();
            _tokenURIs[tokenURIs[i].tokenId] = tokenURIs[i].uri;
            emit MetadataUpdate(tokenURIs[i].tokenId);
        }
    }

    /// @notice ><((($> Withdraw funds to treasury
    /// @dev Revert if the contract balance is 0
    function withdraw() external nonReentrant onlyRole(ADMIN_ROLE) {
        if (address(this).balance == 0) revert InsufficientFunds();
        Address.sendValue(_treasuryAccount, address(this).balance);
        emit FundsWithdrawn();
    }

    /// @notice ><(((#>  Admin to burn token
    /// @dev Revert if the token does not exist
    /// @param tokenId uint256 token ID to burn
    function burn(uint256 tokenId) external nonReentrant onlyRole(ADMIN_ROLE) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        _burn(tokenId);
    }

    /// @notice ><(((#> Admin to batch burn tokens
    /// @dev Revert if the token does not exist
    /// @param tokenIds uint256[] token IDs to burn
    function batchBurn(
        uint256[] calldata tokenIds
    ) external nonReentrant onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (!_exists(tokenIds[i])) revert URIQueryForNonexistentToken();
            _burn(tokenIds[i]);
        }
    }

    /// @notice ><(((#> Enable public minting
    function enableMinting() external nonReentrant onlyRole(ADMIN_ROLE) {
        _publicMintEnabled = true;
    }

    /// @notice ><(((#> Disable public minting
    function disableMinting() external nonReentrant onlyRole(ADMIN_ROLE) {
        _publicMintEnabled = false;
    }

    /// @notice ><(((#> Admin mint
    /// @dev Revert if the max supply is reached
    /// @param to address to mint to
    /// @param amount uint256 quantity to mint
    function adminMint(
        address to,
        uint256 amount
    ) external nonReentrant onlyRole(ADMIN_ROLE) {
        if (totalSupply() + amount > MAX_SUPPLY) revert MaxSupplyReached();
        _mint(to, amount);
    }

    /// @notice ><(((#> Member Mint
    /// @dev Revert if the max supply is reached
    /// @dev Revert if the mint cap is exceeded
    /// @dev Revert if the mint price is not met
    /// @param to address to mint to
    /// @param amount uint256 quantity to mint
    function memberMint(
        address to,
        uint256 amount
    ) external payable nonReentrant onlyRole(MINTER_ROLE) {
        if (amount > MINT_CAP) revert MintCapExceeded();
        if (totalSupply() > _pauseMintAtTokenId) revert MaxSupplyReached();
        if (totalSupply() + amount > MAX_SUPPLY_MINUS_ONE)
            revert MaxSupplyReached();
        if (msg.value < _price * amount) revert InsufficientFunds();

        _mint(to, amount);
    }

    /// @notice ><(((`> Get the baseURI
    /// @dev Read only function
    /// @return string
    function baseURI()
        external
        view
        onlyRole(ADMIN_ROLE)
        returns (string memory)
    {
        return _currentBaseURI;
    }

    /// @notice Get the mint price
    /// @dev Read only function
    /// @return uint256
    function price() external view onlyRole(ADMIN_ROLE) returns (uint256) {
        return _price;
    }

    /// @notice Get the treasury account
    /// @dev Read only function
    /// @return address
    function treasuryAccount()
        public
        view
        onlyRole(ADMIN_ROLE)
        returns (address)
    {
        return _treasuryAccount;
    }

    /// @notice Get the max shell supply
    /// @dev Read only function
    /// @return uint256
    function shellMax() public view onlyRole(ADMIN_ROLE) returns (uint256) {
        return _pauseMintAtTokenId;
    }

    // ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º>
    // PUBLIC MINITNG PUBLIC MINITNG PUBLIC MINITNG PUBLIC MINITNG PUBLIC MINITNG
    // <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))><

    /// @notice ><((((º> Mint a Fish
    /// @dev Payable, and will mint tokens if the correct amount of ETH is sent
    /// @dev No more than MINT_CAP tokens can be minted at a time
    /// @dev Pause minting when the shell max supply is reached
    /// @dev Error if the max supply is reached, or if the mint cap is exceeded
    /// @dev Error if the mint price is not met
    /// @dev Error if minting is not enabled
    /// @param to address to mint to
    /// @param amount uint256 quantity to mint
    function mint(
        address to,
        uint256 amount
    ) external payable whenMintingEnabled nonReentrant {
        if (amount > MINT_CAP) revert MintCapExceeded();
        if (totalSupply() > _pauseMintAtTokenId) revert MaxSupplyReached();
        if (totalSupply() + amount > MAX_SUPPLY_MINUS_ONE)
            revert MaxSupplyReached();
        if (msg.value < _price * amount) revert InsufficientFunds();

        if (totalSupply() >= _pauseMintAtTokenId) {
            _publicMintEnabled = false;
        }
        _mint(to, amount);
    }

    // ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º>
    // MARKETPLACE SHENANIGANS MARKETPLACE SHENANIGANS MARKETPLACE SHENANIGANS
    // <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))><

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º>
    // METADATA METADATA METADATA METADATA METADATA METADATA METADATA METADATA
    // <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))><

    /// @notice ><(((*> Get Metadata for a token
    /// @dev 721A Private function override
    /// @dev Revert if the token does not exist
    /// @param tokenId uint256 token ID to query
    /// @return string Token Metadata URI
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0)
            return string(abi.encodePacked(_currentBaseURI, _tokenURI));

        return string(abi.encodePacked(_currentBaseURI, tokenId.toString()));
    }

    /// @notice ><(((*> Start the Token Count at 1
    /// @dev ><(((*> 721A Private function override
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @notice ><(((*> Burn token at delete token URI
    /// @dev ><(((*> 721A Private function override
    /// @param tokenId uint256 token ID to burn
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    // ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º> ><((((º>
    // INTERFACE INTERFACE INTERFACE INTERFACE INTERFACE INTERFACE INTERFACE
    // <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))>< <º))))><
    /// @dev ><(((=> IERC165 supportsInterface
    /// @param interfaceId interface ID to query
    /// @return bool
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == 0x2a55205a || // ERC2981
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x5b5e139f; // ERC721Metadata
    }
}