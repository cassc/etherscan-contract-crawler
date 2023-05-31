// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../external-interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../utils/OpenSeaContract.sol";
import "../utils/Withdrawable.sol";
import "../utils/NameSymbolUpdate.sol";
import "../utils/OpenSeaFakeOwner.sol";

import "../interfaces/IROJINFTHookTokenURIs.sol";
import "../interfaces/IROJINFTHookRoyalties.sol";
import "../interfaces/INumberMinted.sol";
import "../interfaces/INumberBurned.sol";

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/// @title ERC721A based NFT contract.
/// @author Martin Wawrusch for Roji Inc.
/// @custom:security-contact [email protected]
contract ROJIStandardERC721A is ERC721A , 
                        AccessControl, 
                        NameSymbolUpdateAccessControl,
                        RojiWithdrawableAccessControl, 
                        OpenSeaContractAccessControl,
                        OpenSeaFakeOwnerAccessControl,
                        IERC2981, 
                        Pausable, 
                        INumberBurned, 
                        INumberMinted {
    using Strings for uint256;
    using SafeMath for uint256;

    /// @dev The role required for the {mintDirect} and {mintDirectSafe} functions.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public constant ROYALTY_FEE_DENOMINATOR = 10000;
    uint256 public defaultRoyaltiesBasisPoints = 0;
    address public defaultRoyaltiesReceiver;

    mapping(bytes32 => address) public hooks;
    bytes32 public constant TOKENMETAURI_HOOK = keccak256("TOKENMETAURI_HOOK");
    bytes32 public constant ROYALTIES_HOOK = keccak256("ROYALTIES_HOOK");

    string public baseTokenURI = "";

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

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

    /// @dev Internal proxy registry for {isApprovedForAll}.
    mapping(address => bool) public projectProxy;
    /// @dev The opensea proxy registry address.
    address public              proxyRegistryAddress;

    /// @notice The constructor of this contract.
    /// @param defaultRoyaltiesBasisPoints_ The default royalties basis points (out of 10000).
    /// @param name_ The name of the NFT.
    /// @param symbol_ The symbol of the NFT. Must not exceed 11 characters as that is the Metamask display limit.
    /// @param baseTokenURI_ The base URI of the NFTs. The final URI is composed through baseTokenURI + tokenId + .json. Normally you will want to include the trailing slash.
    constructor(uint256 defaultRoyaltiesBasisPoints_,
                string memory name_,
                string memory symbol_,
                string memory baseTokenURI_) ERC721A(name_, symbol_) OpenSeaFakeOwnerAccessControl() {

        defaultRoyaltiesBasisPoints = defaultRoyaltiesBasisPoints_;
        baseTokenURI = baseTokenURI_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(WITHDRAWER_ROLE, msg.sender);

        defaultRoyaltiesReceiver = msg.sender; 
    }

    /// @dev Sets the proxy registry address for opensea.
    /// Use this with caution - in general we do not want to do this, as this has been known
    /// to be a securities risk and might present some liability, 
    /// as per definition the 'owner' of an NFT does not have full control over it anymore.
    /// 
    /// Requires DEFAULT_ADMIN_ROLE membership
    /// @param proxyRegistryAddress_ The address of the proxy registry. This varies based on platform.
    function setProxyRegistryAddress(address proxyRegistryAddress_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        proxyRegistryAddress = proxyRegistryAddress_;
    }

    /// @dev Activates/deactivates proxying for {isApprovedForAll} for a specific contract address.
    /// This is the local version of the OpenSea proxy registry.
    /// 
    /// Requires DEFAULT_ADMIN_ROLE membership
    /// @param proxyAddress The address that should be toggled.
    function flipProxyState(address proxyAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    /// @dev Sets the hook contract for token metadata. 
    /// This allows for easy implementation of a different metadata strategy other than the one implemented in this contract.
    /// Requires DEFAULT_ADMIN_ROLE membership
    /// @param contract_ The address of the token metadata URI hook contract
    function setHookTokenMetaURIs(address contract_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        hooks[TOKENMETAURI_HOOK] = contract_;
    }

    /// @dev Sets the default baseTokenURI.
    /// The {tokenURI}, by default, is composed of baseTokenURI + tokenId + .json.
    /// Requires DEFAULT_ADMIN_ROLE membership
    /// @param newBaseTokenURI The new baseTokenURI, which normally ends with a forward slash.
    function setBaseTokenURI(string calldata newBaseTokenURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = newBaseTokenURI;
        emit BaseTokenURIChanged(newBaseTokenURI);
    }

    /// @dev Returns the hook contract for token metadata.
    /// When not set the contract specific {tokenURI} implementation is used.
    /// @return The address of the token metadata URI hook contract or address(0) if not set.
    function hookTokenMetaURIs() public view returns (IROJINFTHookTokenURIs) {
        return IROJINFTHookTokenURIs(hooks[TOKENMETAURI_HOOK]);
    }

    /// @dev Sets the hook contract for royalties. 
    /// This allows for easy implementation of a different royalty strategy other than the one implemented in this contract.
    /// Requires DEFAULT_ADMIN_ROLE membership
    /// @param contract_ The address of the royalties hook contract
    function setHookRoyalties(address contract_) public onlyRole(DEFAULT_ADMIN_ROLE) {
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
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return  ERC721A.supportsInterface(interfaceId) || 
                AccessControl.supportsInterface(interfaceId) ||
                interfaceId == _INTERFACE_ID_ERC2981;
    }

    /// @notice Mints quantity amount of tokens to address.
    /// @dev Requires DEFAULT_ADMIN_ROLE membership
    function mintAdmin(address to, uint256 quantity) external onlyRole(DEFAULT_ADMIN_ROLE) {
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
    function mintDirect(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
       // 0 quantity is checked by the underlying ERC721A implementation
      _mint(to, quantity);
    }
    
    /// @dev Safely mints `quantity` tokens and transfers them to `to`.
    /// 
    /// Requirements:
    /// Invoker must have the MINTER_ROLE
    /// - If `to` refers to a smart contract, it must implement
    /// {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
    ///
    /// Emits a {Transfer} event for each mint.
    /// @param to The address of the recipient or smart contract. Cannot be 0 address.
    /// @param quantity The number of tokens to mint. Must be greater than 0.
    function mintDirectSafe(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
       require(to != address(0), "ERC721: mint to the zero address");

       // 0 quantity is checked by the underlying ERC721A implementation
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
        } else {
            receiver = defaultRoyaltiesReceiver;
            royaltyAmount = defaultRoyaltiesReceiver != address(0)
                      ? _salePrice * defaultRoyaltiesBasisPoints / ROYALTY_FEE_DENOMINATOR 
                      : 0;
        }
    }

    /// @notice Returns a string representing the token URI for a given token ID.
    /// @param tokenId uint256 ID of the token to query
    /// @dev This function reevrts if the token does not exist. 
    /// If a hook is set for the token uri then the hook will be invoked, otherwise the
    /// URI will be constructed from the baseTokenURI and the tokenId and a '.json' at the end.
    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        address tokenURIContract =  hooks[TOKENMETAURI_HOOK];
        if(tokenURIContract != address(0)) {
            return IROJINFTHookTokenURIs(tokenURIContract).tokenURI(address(this), tokenId);
        } else {
            return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
        }
    }

    /// @inheritdoc ERC721A
    function isApprovedForAll(address owner_, address operator) public view override(ERC721A) returns (bool) {
        if (projectProxy[operator]) {
            return true;
        }

        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if(proxyRegistryAddress != address(0) && address(proxyRegistry.proxies(owner_)) == operator ) {
            return true;
        }

        return super.isApprovedForAll(owner_, operator);
    }

    /// @notice Updates the basis points for an NFT contract
    /// @dev While not enforced yet the contract address should be a 721 or 1155 NFT contract
    /// Requires DEFAULT_ADMIN_ROLE membership
    /// @param basisPoints the basis points (1/100 per cent) - e.g. 1% 100 basis points, 5% 500 basis points
    function setDefaultRoyaltiesBasisPoints(uint256 basisPoints) public onlyRole(DEFAULT_ADMIN_ROLE)  {

      require(basisPoints < 10000, "Basis points must be < 10000");

      defaultRoyaltiesBasisPoints = basisPoints;
      emit DefaultRoyaltiesBasisPointsUpdated( basisPoints);
    }

    /// @notice Updates the defaultRoyaltiesReceiver for an NFT contract
    /// @dev Requires DEFAULT_ADMIN_ROLE membership
    /// @param receiver The address of the account that should receive royalties
    function setDefaultRoyaltiesReceiver(address receiver) public  onlyRole(DEFAULT_ADMIN_ROLE)  {
      require(receiver != address(0), "receiver is null");
 
      defaultRoyaltiesReceiver = receiver;
      emit DefaultRoyaltiesReceiverUpdated( receiver);
    }

    /// @notice Pauses this contract
    /// @dev Requires DEFAULT_ADMIN_ROLE membership
    /// Pausing generally only effects the public minting functionality.
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses this contract
    /// @dev Requires DEFAULT_ADMIN_ROLE membership
    /// Pausing generally only effects the public minting functionality.
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
    
    /// @notice Returns the number of tokens minted by the owner.
    /// @param adr the address of the owner
    /// @return An uint256 representing the number of tokens minted by the passed address.
    function numberMinted(address adr) public view override returns (uint256) {
        return _numberMinted(adr);
    }

    /// @notice Returns the number of tokens burned by or on behalf of owner.
    /// @param adr the address of the owner
    /// @return An uint256 representing the number of tokens burned by the passed address.
     function numberBurned(address adr) public view override returns (uint256) {
        return _numberBurned(adr);
    }

}