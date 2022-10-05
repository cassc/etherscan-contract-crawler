// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../external-interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


import "./INFTRedeemable.sol";

import "./IROJINFTHookTokenURIs.sol";
import "./IROJINFTHookRoyalties.sol";

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ROJIERC721A is ERC721A , AccessControl, IERC2981, INFTRedeemable, Pausable {
      using ECDSA for bytes32;

    // The key used to sign allowlist signatures.
    // We will check to ensure that the key that signed the signature
    // is this one that we expect.
    address allowlistSigningAddress = address(0);

    bytes32 public constant REDEMPTION_ROLE = keccak256("REDEMPTION_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ROYALTIES_SETTER_ROLE = keccak256("ROYALTIES_SETTER_ROLE"); // This comes from the hooks

    uint256 public constant ROYALTY_FEE_DENOMINATOR = 10000;

    uint256 public defaultRoyaltiesBasisPoints = 0;
    address public defaultRoyaltiesReceiver;

    // Domain Separator is the EIP-712 defined structure that defines what contract
    // and chain these signatures can be used for.  This ensures people can't take
    // a signature used to mint on one contract and use it for another, or a signature
    // from testnet to replay on mainnet.
    // It has to be created in the constructor so we can dynamically grab the chainId.
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    bytes32 public DOMAIN_SEPARATOR;

    // The typehash for the data type specified in the structured data
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
    // This should match whats in the client side allowlist signing code
    // https://github.com/msfeldstein/EIP712-allowlisting/blob/main/test/signWhitelist.ts#L22
    bytes32 public constant MINTER_TYPEHASH =
        keccak256("Minter(address wallet)");

    mapping(bytes32 => address) public hooks;
    bytes32 public constant TOKENMETAURI_HOOK = keccak256("TOKENMETAURI_HOOK");
    // bytes32 public constant BURN_HOOK = keccak256("BURN_HOOK");
    // bytes32 public constant TRANSFER_HOOK = keccak256("TRANSFER_HOOK");
    bytes32 public constant ROYALTIES_HOOK = keccak256("ROYALTIES_HOOK");

    string public fallbackTokenURI = "";

    using SafeMath for uint256;
    uint256 public price;
    /// Invoked when the sale price is updated.
    event PriceChanged(uint256 _price);

    /// The optional opensea metatdata URI
    string private _contractURI;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    uint256 public paidMintMaxTokensPerAddress;
    event PaidMintMaxTokensPerAddressChanged(uint256 paidMintMaxTokensPerAddress);

    uint256 public availableSupply;


    /// @notice Emitted when basis points have been updated for an NFT contract
    /// @dev The basis points can range from 0 to 99999, representing 0 to 99.99 percent
    /// @param basisPoints the basis points (1/100 per cent) - e.g. 1% 100 basis points, 5% 500 basis points
    event DefaultRoyaltiesBasisPointsUpdated( uint256 basisPoints);

    /// @notice Emitted when the receiver has been updated for an NFT contract
    /// @param receiver The address of the account that should receive royalties
    event DefaultRoyaltiesReceiverUpdated( address receiver);




    mapping(address => bool) public projectProxy;
    address public              proxyRegistryAddress;

    bytes4 private constant _INTERFACE_ID_INFT_REDEEMABLE = type(INFTRedeemable).interfaceId;

    constructor(uint256 price_,
                uint256 paidMintMaxTokensPerAddress_,
                uint256 availableSupply_,
                uint256 defaultRoyaltiesBasisPoints_,
                string memory domainVerifierAppName_,
                string memory domainVerifierAppVersion_,
                address allowlistSigningAddress_,
                string memory name_,
                string memory symbol_,
                string memory fallbackTokenURI_) ERC721A(name_, symbol_) {

        // This should match whats in the client side allowlist signing code
        // https://github.com/msfeldstein/EIP712-allowlisting/blob/main/test/signWhitelist.ts#L12
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                // This should match the domain you set in your client side signing.
                keccak256(bytes(domainVerifierAppName_)), // "WhitelistToken"
                keccak256(bytes(domainVerifierAppVersion_)), // "1"
                block.chainid,
                address(this)
            )
        );

        allowlistSigningAddress = allowlistSigningAddress_;

        price = price_;
        availableSupply = availableSupply_;
        paidMintMaxTokensPerAddress = paidMintMaxTokensPerAddress_;
        defaultRoyaltiesBasisPoints = defaultRoyaltiesBasisPoints_;
        fallbackTokenURI = fallbackTokenURI_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(ROYALTIES_SETTER_ROLE, msg.sender);
        _owner = msg.sender; // This is the opensea owner
        defaultRoyaltiesReceiver = msg.sender; 
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function setHookTokenMetaUris(address contract_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        hooks[TOKENMETAURI_HOOK] = contract_;
    }

    function hookTokenMetaURIs() public view returns (IROJINFTHookTokenURIs) {
        return IROJINFTHookTokenURIs(hooks[TOKENMETAURI_HOOK]);
    }

    function setHookRoyalties(address contract_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        hooks[ROYALTIES_HOOK] = contract_;
    }

    function hookRoyalties() public view returns (IROJINFTHookRoyalties) {
        return IROJINFTHookRoyalties(hooks[ROYALTIES_HOOK]);
    }



    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return  ERC721A.supportsInterface(interfaceId) || 
                AccessControl.supportsInterface(interfaceId) ||
                interfaceId == _INTERFACE_ID_INFT_REDEEMABLE ||
                interfaceId == _INTERFACE_ID_ERC2981;
    }

    /// @notice Mints numberOfTokens amount of tokens to address.
    function mint(uint256 quantity, bytes calldata signature) external payable requiresAllowlist(signature) whenNotPaused() {

      require(balanceOf(msg.sender) + quantity <= paidMintMaxTokensPerAddress, "Token limit/address exceeded");
      require(msg.value >= price.mul(quantity), "Insufficient payment");
      require(availableSupply >= quantity, "Not enough tokens left");

      availableSupply = availableSupply.sub(quantity);
      _mint(msg.sender, quantity);
   }

    /// @notice Mints numberOfTokens amount of tokens to address.
    function mintAdmin(address to, uint256 quantity) public onlyRole(DEFAULT_ADMIN_ROLE) {
      _mint(to, quantity);
    }

    function mintDirect(address to, uint256 quantity) public onlyRole(MINTER_ROLE) {
      _mint(to, quantity);
    }
    
    function mintDirectSafe(address to, uint256 quantity) public onlyRole(MINTER_ROLE) {
       require(to != address(0), "ERC721: mint to the zero address");
      _safeMint(to, quantity);
    }


    /// Sets the optional opensea metadata URI
    function setContractURI(string calldata newContractURI) public onlyRole(DEFAULT_ADMIN_ROLE)  {
        _contractURI = newContractURI;
    }

    /// Returns the opensea contract metadata URI 
    function contractURI() public view returns (string memory) {
        return _contractURI;
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

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        address tokenUriContract =  hooks[TOKENMETAURI_HOOK];
        if(tokenUriContract != address(0)) {
            require(_exists(tokenId), "URI query for nonexistent token");
            return IROJINFTHookTokenURIs(tokenUriContract).tokenURI(address(this), tokenId);
        } else {
            return fallbackTokenURI;
        }
    }

    function redeem(address, uint256 tokendId) public override onlyRole(REDEMPTION_ROLE) {
        _burn(tokendId, false);
    }

    function isApprovedForAll(address owner_, address operator) public view override(ERC721A) returns (bool) {
        if (projectProxy[operator]) return true;

        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if(proxyRegistryAddress != address(0) && address(proxyRegistry.proxies(owner_)) == operator ) return true;

        return super.isApprovedForAll(owner_, operator);
    }

/***********************
****** Withdrawal code
***********************/

    /// @notice Fund withdrawal for owner.
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
      payable(msg.sender).transfer(address(this).balance); 
    }

/***********************
****** Allowlist code
***********************/

    function setAllowlistSigningAddress(address newSigningAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        allowlistSigningAddress = newSigningAddress;
    }

    modifier requiresAllowlist(bytes calldata signature) {
        require(allowlistSigningAddress != address(0), "allowlist not enabled");
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender))
            )
        );
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = digest.recover(signature);
        require(recoveredAddress == allowlistSigningAddress, "Invalid Signature");
        _;
    }

    /***********************
    ****** Opensea doesn't support role based ownership for setting royalties there.
    ***********************/
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual  onlyRole(DEFAULT_ADMIN_ROLE)  {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual  onlyRole(DEFAULT_ADMIN_ROLE)  {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


    /// @notice sets the price in gwai for a single nft sale. 
    function setPrice(uint256 price_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        price = price_;
        emit PriceChanged( price_);
    }

    function setPaidMintMaxTokensPerAddress(uint256 paidMintMaxTokensPerAddress_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        paidMintMaxTokensPerAddress = paidMintMaxTokensPerAddress_;
        emit PaidMintMaxTokensPerAddressChanged( paidMintMaxTokensPerAddress);
    }
    

    function _setStringAtStorageSlot(string memory value, uint256 storageSlot) private {
        assembly {
            let stringLength := mload(value)

            switch gt(stringLength, 0x1F)
            case 0 {
                sstore(storageSlot, or(mload(add(value, 0x20)), mul(stringLength, 2)))
            }
            default {
                sstore(storageSlot, add(mul(stringLength, 2), 1))
                mstore(0x00, storageSlot)
                let dataSlot := keccak256(0x00, 0x20)
                for { let i := 0 } lt(mul(i, 0x20), stringLength) { i := add(i, 0x01) } {
                    sstore(add(dataSlot, i), mload(add(value, mul(add(i, 1), 0x20))))
                }
            }
        }
    }

    function setName(string memory value) public onlyRole(DEFAULT_ADMIN_ROLE)  {
        _setStringAtStorageSlot(value, 2);
    }

    function setSymbol(string memory value) public onlyRole(DEFAULT_ADMIN_ROLE)  {
        _setStringAtStorageSlot(value, 3);
    }


    /// @notice Updates the basis points for an NFT contract
    /// @dev While not enforced yet the contract address should be a 721 or 1155 NFT contract
    /// @param basisPoints the basis points (1/100 per cent) - e.g. 1% 100 basis points, 5% 500 basis points
    function setDefaultRoyaltiesBasisPoints(uint256 basisPoints) public  onlyRole(DEFAULT_ADMIN_ROLE)  {

      require(basisPoints < 10000, "Basis points must be < 10000");

      defaultRoyaltiesBasisPoints = basisPoints;
      emit DefaultRoyaltiesBasisPointsUpdated( basisPoints);
    }

    /// @notice Updates the receiver for an NFT contract
    /// @dev While not enforced yet the contract address should be a 721 or 1155 NFT contract
    /// @param receiver The address of the account that should receive royalties
    function setDefaultRoyaltiesReceiver(address receiver) public  onlyRole(DEFAULT_ADMIN_ROLE)  {
      require(receiver != address(0), "receiver is null");
 
      defaultRoyaltiesReceiver = receiver;
      emit DefaultRoyaltiesReceiverUpdated( receiver);
    }

    /// @notice Pauses this contract
    /// Requires owner privileges
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses this contract
    /// Requires owner privileges
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }


}