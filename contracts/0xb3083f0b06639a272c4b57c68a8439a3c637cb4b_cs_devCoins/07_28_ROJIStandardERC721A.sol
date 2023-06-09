// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "solady/src/auth/OwnableRoles.sol";

import "../external-interfaces/IERC2981.sol";

import "../utils/OpenSeaContractOwnableRoles.sol";
import "../utils/WithdrawableOwnableRoles.sol";
import "../utils/NameSymbolUpdateOwnableRoles.sol";

import "../interfaces/IROJINFTHookTokenURIs.sol";
import "../interfaces/IROJINFTHookRoyalties.sol";
import "../interfaces/INumberMinted.sol";
import "../interfaces/INumberBurned.sol";
import "../utils/errors.sol";
import "../utils/roji-roles.sol";
import "../external-interfaces/IERC4906.sol";


/// @title ERC721A based NFT contract.
/// @author Martin Wawrusch for Roji Inc.
/// @dev
/// General
///
/// This contract starts with tokenID 1. It does not contain any minters, but minters
/// can be added either by inheriting from this contract or attaching external minting
/// contracts. External minting contracts will typically consume an additional 4000 gas.
///
/// Max Supply
///
/// This contract supports a max supply that is validated over all minted NFTs,
/// to ensure that PFP style applications support rarity. When inheriting from this 
/// contract and using the protected minting functions you need to ensure that this 
/// invariant is maintained.
/// By default, maxSupply is set to MAX_UINT. It can only be shrinked.
/// 
/// Security Model
/// 
/// There is one owner of the NFT contract. This is exposed in an Ownable confirming way
/// so it will be picked up by OpenSea and the other platforms.
/// This owner can assign roles to other accounts and contracts. 
/// 
/// Inheriting Instructions
/// 
/// Make sure that this contract and it's decendents are the first one in the inheritance chain.
/// 
/// @custom:security-contact [email protected]
contract ROJIStandardERC721A is ERC721A, // IMPORTANT MUST ALWAYS BE FIRST - NEVER CHANGE THAT
                            OwnableRoles,
                            NameSymbolUpdateOwnableRoles,
                            RojiWithdrawableOwnableRoles,
                            OpenSeaContractOwnableRoles,
                            Pausable, 
                            IERC2981,
                            INumberBurned, 
                            INumberMinted,
                            IERC4906
                        {
    using Strings for uint256;

    uint256 private _maxSupply = 2**256 - 1;

    uint256 private constant FEE_DENOMINATOR = 10000;


    uint256 public constant ROYALTY_FEE_DENOMINATOR = 10000;
    uint256 public defaultRoyaltiesBasisPoints;
    address public defaultRoyaltiesReceiver;

    mapping(bytes32 => address) public hooks;
    bytes32 public constant TOKENMETAURI_HOOK = keccak256("TOKENMETAURI_HOOK");
    bytes32 public constant ROYALTIES_HOOK = keccak256("ROYALTIES_HOOK");

    string public baseTokenURI = "";

    string public overrideTokenURI;

//    bytes4 private constant _INTERFACE_ID_EIP165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// @dev Emitted when the overrideTokenURI is updated.
    /// @param overrideTokenURI The new overrideTokenURI.
    event OverrideTokenURIChanged(string overrideTokenURI);

    /// @dev Emitted when the baseTokenURI is updated.
    /// @param baseTokenURI The new baseTokenURI.
    event BaseTokenURIChanged(string baseTokenURI);

    /// @notice Emitted when basis points have been updated for an NFT contract
    /// @dev The basis points can range from 0 to 99999, representing 0 to 99.99 percent
    /// @param basisPoints the basis points (1/100 per cent) - e.g. 1% 100 basis points, 5% 500 basis points
    event DefaultRoyaltiesBasisPointsUpdated( uint256 basisPoints);

    /// @notice Emitted when the receiver has been updated for an NFT contract
    /// @param receiver The address of the account that should receive royalties
    event DefaultRoyaltiesReceiverUpdated( address receiver);

    /// @notice The event emitted when the max supply has been manully updated.
    /// @param maxSupply The new max supply.
    event MaxSupplyChanged(uint256 maxSupply);

    /// @dev The role required for the {mintDirect} function.
    uint256 public constant ROLE_MINTER = ROJI_ROLE_MINTER;

    /// @notice A token with the specified id does not exist
    error TokenDoesNotExist();

    /// @notice Requires a non zero receiver address.
    error ReceiverIsZeroAddress();

    /// @notice The max supply would be less than the current supply.
    error MaxSupplyLessThanCurrentSupply();

    /// @notice The max supply would be less than the total number of minted tokens.
    error MaxSupplyLessThanTotalMinted();

    /// @notice When setting a new max supply it must be less than the current max supply.
    error NewMaxSupplyMustBeLessThanCurrentMaxSupply();

    /// @notice The overall allowed supply of tokens cannot be exceeded.
    error MaxSupplyExceeded();

    /// @notice The constructor of this contract.
    /// @param defaultRoyaltiesBasisPoints_ The default royalties basis points (out of 10000).
    /// @param name_ The name of the NFT.
    /// @param symbol_ The symbol of the NFT. Must not exceed 11 characters as that is the Metamask display limit.
    /// @param baseTokenURI_ The base URI of the NFTs. The final URI is composed through baseTokenURI + tokenId + .json. Normally you will want to include the trailing slash.
    constructor(uint256 defaultRoyaltiesBasisPoints_,
                string memory name_,
                string memory symbol_,
                string memory baseTokenURI_) ERC721A(name_, symbol_) {

        _initializeOwner(msg.sender);
        _grantRoles(msg.sender, ROLE_MINTER | ROLE_WITHDRAWER);

         defaultRoyaltiesBasisPoints = defaultRoyaltiesBasisPoints_;
        baseTokenURI = baseTokenURI_;
        defaultRoyaltiesReceiver = msg.sender; 
    }

    /// @dev Sets the hook contract for token metadata. 
    /// This allows for easy implementation of a different metadata strategy other than the one implemented in this contract.
    ///
    /// *Access Control*
    /// Access restricted to the owner and members of the [ROJI_ROLE_ADMIN_METADATA] role.
    ///
    /// @param contract_ The address of the token metadata URI hook contract
    function setHookTokenMetaURIs(address contract_) public onlyOwnerOrRoles(ROJI_ROLE_ADMIN_METADATA) {
        hooks[TOKENMETAURI_HOOK] = contract_;
    }

    /// @dev Sets the default baseTokenURI.
    /// The {tokenURI}, by default, is composed of baseTokenURI + tokenId + .json.
    ///
    /// *Access Control*
    /// Access restricted to the owner and members of the [ROJI_ROLE_ADMIN_METADATA] role.
    ///
    /// @param newBaseTokenURI The new baseTokenURI, which normally ends with a forward slash.
    function setBaseTokenURI(string calldata newBaseTokenURI) public onlyOwnerOrRoles(ROJI_ROLE_ADMIN_METADATA) {
        baseTokenURI = newBaseTokenURI;
        emit BaseTokenURIChanged(newBaseTokenURI);
        if(_nextTokenId() > _startTokenId()) {
            emit BatchMetadataUpdate(_startTokenId(), _nextTokenId() - 1);
        }

    }

    /// @dev Sets the default overrideTokenURI.
    /// The {tokenURI}, by default, is composed of overrideTokenURI + tokenId + .json.
    ///
    /// *Access Control*
    /// Access restricted to the owner and members of the [ROJI_ROLE_ADMIN_METADATA] role.
    ///
    /// @param newOverrideTokenURI The new overrideTokenURI, which normally ends with a forward slash.
    function setOverrideTokenURI(string calldata newOverrideTokenURI) public onlyOwnerOrRoles(ROJI_ROLE_ADMIN_METADATA) {
        overrideTokenURI = newOverrideTokenURI;
        emit OverrideTokenURIChanged(newOverrideTokenURI);
    }


    /// @dev Returns the hook contract for token metadata.
    /// When not set the contract specific {tokenURI} implementation is used.
    /// @return The address of the token metadata URI hook contract or address(0) if not set.
    function hookTokenMetaURIs() public view returns (IROJINFTHookTokenURIs) {
        return IROJINFTHookTokenURIs(hooks[TOKENMETAURI_HOOK]);
    }

    /// @dev Sets the hook contract for royalties. 
    /// This allows for easy implementation of a different royalty strategy other than the one implemented in this contract.
    ///
    /// *Access Control*
    /// Access restricted to the owner and members of the [ROJI_ROLE_ADMIN_ROYALTIES] role.
    ///
    /// @param contract_ The address of the royalties hook contract
    function setHookRoyalties(address contract_) public onlyOwnerOrRoles(ROJI_ROLE_ADMIN_ROYALTIES) {
        hooks[ROYALTIES_HOOK] = contract_;
    }

    /// @dev Getter method for the royalties hook
    /// @return The address of the royalties hook, if present, or address(0)
    function hookRoyalties() public view returns (IROJINFTHookRoyalties) {
        return IROJINFTHookRoyalties(hooks[ROYALTIES_HOOK]);
    }

    /// @dev Determines if an interface is supported by this contract.
    /// @param interfaceId The interface identifier, as specified in ERC-165.
    /// @return `true` if the interface is supported.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return 
                ERC721A.supportsInterface(interfaceId) || 
                interfaceId == type(INumberMinted).interfaceId ||
                interfaceId == bytes4(0x49064906) || // I4906
                interfaceId == type(INumberBurned).interfaceId ||
                // interfaceId == _INTERFACE_ID_EIP165 ||  Already included in base
                interfaceId == _INTERFACE_ID_ERC2981;
    }

    /// @dev Mints quantity amount of tokens to address.
    ///
    /// *Access Control*
    /// Access restricted to the owner and members of the [ROJI_ROLE_ADMIN_MINTER] role.
    ///
    /// @param to The address to mint the tokens to.
    /// @param quantity The quantity of tokens to mint. Must be at least 1.
    function mintAdmin(address to, uint256 quantity) external requiresMaxSupply(quantity) onlyOwnerOrRoles(ROJI_ROLE_ADMIN_MINTER) {
       // 0 quantity and 0 address are reverted by 
       // the underlying ERC721A implementation.
      _mint(to, quantity);
    }

    /// @dev Mints `quantity` tokens and transfers them to `to`.
    ///
    /// Requirements:
    /// Invoker must have the MINTER_ROLE
    ///
    /// Emits a {Transfer} event for each mint.
    /// @param to The address of the recipient or smart contract. Cannot be 0 address.
    /// @param quantity The number of tokens to mint. Must be greater than 0.     
    function mintDirect(address to, uint256 quantity) external requiresMaxSupply(quantity) onlyRoles(ROLE_MINTER) {
       // 0 quantity and 0 address are reverted by 
       // the underlying ERC721A implementation.
      _mint(to, quantity);
    }
 
    /// @dev Mints `quantity` tokens and transfers them to `to`.
    /// This method differs from {mintDirect} in that it also checks if the reveiver, in
    /// case it is a smart contract, implements the {IERC721Receiver-onERC721Received} interface.
    ///
    /// Requirements:
    /// Invoker must have the MINTER_ROLE
    ///
    /// Emits a {Transfer} event for each mint.
    /// @param to The address of the recipient or smart contract. Cannot be 0 address.
    /// @param quantity The number of tokens to mint. Must be greater than 0.     
    function safeMintDirect(address to, uint256 quantity) external requiresMaxSupply(quantity) onlyRoles(ROLE_MINTER) {
       // 0 quantity and 0 address are reverted by 
       // the underlying ERC721A implementation.
      _safeMint(to, quantity);
    }
 
    /// @inheritdoc	IERC2981
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) public override view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        address royaltiesHook =  hooks[ROYALTIES_HOOK];
        if(royaltiesHook != address(0)) {
            (receiver, royaltyAmount) = IROJINFTHookRoyalties(royaltiesHook).royaltyInfo(address(this), _tokenId, _salePrice);
        }
         else {
            receiver = defaultRoyaltiesReceiver;
            royaltyAmount =  _salePrice * defaultRoyaltiesBasisPoints / ROYALTY_FEE_DENOMINATOR;
        }
    }

    /// @notice Returns a string representing the token URI for a given token ID.
    /// @param tokenId uint256 ID of the token to query
    /// @dev This function reverts if the token does not exist. 
    /// If a hook is set for the token uri then the hook will be invoked, otherwise the
    /// URI will be constructed from the baseTokenURI and the tokenId and a '.json' at the end.
    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        if(!_exists(tokenId)) {revert TokenDoesNotExist(); }

        if( bytes(overrideTokenURI).length != 0) {
            return overrideTokenURI;
        }

        address tokenURIContract =  hooks[TOKENMETAURI_HOOK];
        if(tokenURIContract != address(0)) {
            return IROJINFTHookTokenURIs(tokenURIContract).tokenURI(address(this), tokenId);
        } 
        else {
            return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
        }
    }

    /// @dev Updates the basis points for an NFT contract
    /// While not enforced yet the contract address should be a 721 or 1155 NFT contract
    ///
    /// *Access Control*
    /// Access restricted to the owner and members of the [ROJI_ROLE_ADMIN_ROYALTIES] role.
    ///
    /// @param basisPoints_ the basis points (1/100 per cent) - e.g. 1% 100 basis points, 5% 500 basis points
    function setDefaultRoyaltiesBasisPoints(uint256 basisPoints_) public onlyOwnerOrRoles(ROJI_ROLE_ADMIN_ROYALTIES)  {

      if(basisPoints_ >= FEE_DENOMINATOR) { revert BasisPointsMustBeLessThan10000(); }

      defaultRoyaltiesBasisPoints = basisPoints_;
      emit DefaultRoyaltiesBasisPointsUpdated(defaultRoyaltiesBasisPoints);
    }

    /// @dev Updates the defaultRoyaltiesReceiver for an NFT contract
    ///
    /// *Access Control*
    /// Access restricted to the owner and members of the [ROJI_ROLE_ADMIN_ROYALTIES] role.
    ///
    /// @param receiver The address of the account that should receive royalties
    function setDefaultRoyaltiesReceiver(address receiver) public  onlyOwnerOrRoles(ROJI_ROLE_ADMIN_ROYALTIES)  {
        if(receiver == address(0)) { revert ReceiverIsZeroAddress(); }
 
        defaultRoyaltiesReceiver = receiver;
        emit DefaultRoyaltiesReceiverUpdated(defaultRoyaltiesReceiver);
    }

    /// @notice Pauses this contract
    /// @dev  Pausing generally only effects the public minting functionality.
    ///
    /// *Access Control*
    /// Access restricted to the owner and members of the [ROJI_ROLE_ADMIN_OPERATIONS] role.
    ///
    function pause() public onlyOwnerOrRoles(ROJI_ROLE_ADMIN_OPERATIONS) {
        _pause();
    }

    /// @notice Unpauses this contract
    /// @dev Pausing generally only effects the public minting functionality.
    ///
    /// *Access Control*
    /// Access restricted to the owner and members of the [ROJI_ROLE_ADMIN_OPERATIONS] role.
    /// 
    function unpause() public onlyOwnerOrRoles(ROJI_ROLE_ADMIN_OPERATIONS) {
        _unpause();
    }
    
    /// @notice Returns the number of tokens minted by the owner.
    /// @param adr the address of the owner
    /// @return An uint256 representing the number of tokens minted by the passed address.
    function numberMinted(address adr) external view override returns (uint256) {
        return _numberMinted(adr);
    }

    /// @notice Returns the number of tokens burned by or on behalf of owner.
    /// @param adr the address of the owner
    /// @return An uint256 representing the number of tokens burned by the passed address.
     function numberBurned(address adr) external view override  returns (uint256) {
        return _numberBurned(adr);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /***************************************************************************
    ** Max Supply Section
    ***************************************************************************/
    

    /// @dev Sets the new max supply.
    /// This is an internal role only.
    /// @param maxSupply_ The new max supply.
    function _setMaxSupply(uint256 maxSupply_) internal {
        if(maxSupply_ < totalSupply()) { revert MaxSupplyLessThanCurrentSupply(); }
        if(maxSupply_ < _totalMinted()) { revert MaxSupplyLessThanTotalMinted(); }
        _maxSupply = maxSupply_;
        emit MaxSupplyChanged(_maxSupply);
    }

    /// @dev Shrinks the current max supply
    /// Do not call from constructor, use {_setMaxSupply} instead.
    ///
    /// *Access Control*
    /// Access restricted to the owner and members of the [ROJI_ROLE_ADMIN_SETUP] role.
    ///
    /// @param maxSupply_ The new max supply.
    function shrinkMaxSupply(uint256 maxSupply_) external onlyOwnerOrRoles(ROJI_ROLE_ADMIN_SETUP) {
        if(maxSupply_ >= _maxSupply) { revert NewMaxSupplyMustBeLessThanCurrentMaxSupply(); }
        _setMaxSupply(maxSupply_);
    }

    /// @dev The maxium number of NFTs that can be minted with this contract.
    /// If tokens are burned those do not affect the max supply.
    function maxSupply() external view returns(uint256) {
        return _maxSupply;
    }

    /// @dev use this modifier in any minting function to ensure that
    /// the max supply is never exceeded.
    /// The max supply is based on the minted tokens, not the tokens in existance.
    /// 
    /// Example:
    /// We mint 10 tokens, burn 2.
    /// maxSupply is set to 10.
    /// we cannot mint any more tokens.
    modifier requiresMaxSupply(uint256 quantity) {
        if(_totalMinted() + quantity > _maxSupply) { revert MaxSupplyExceeded(); }
        _;
    }


    function metadataUpdated(uint256 __tokenId) public onlyOwnerOrRoles(ROJI_ROLE_ADMIN_OPERATIONS) {
        emit MetadataUpdate(__tokenId);
    }

    function batchMetadataUpdated(uint256 _fromTokenId, uint256 _toTokenId) public onlyOwnerOrRoles(ROJI_ROLE_ADMIN_OPERATIONS) {
        emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
    }
}