// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../interfaces/ICallProxy.sol";
import "../interfaces/IDeBridgeGate.sol";
import "./interfaces/IDeNFT.sol";
import "./interfaces/IDeNftBridge.sol";
import "./DeNftDeployer.sol";
import "../libraries/Flags.sol";
import "./libraries/DeNftConstants.sol";

contract DeNftBridge is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721ReceiverUpgradeable,
    IDeNftBridge
{
    using AddressUpgradeable for address payable;
    using AddressUpgradeable for address;

    /* ========== STATE VARIABLES ========== */

    /// @dev Stores the wrapper collections' details on the current chain.
    ///      These collections are identifiable by debridgeId
    /// @notice See getDebridgeId() for details
    mapping(bytes32 => BridgeNFTInfo) public getBridgeNFTInfo;

    /// @dev Stores the original collections' metadata
    mapping(address => NativeNFTInfo) public getNativeInfo;

    /// @dev Stores the addresses NFTBridge has been deployed at on the supported target chains (relative to the current chain).
    mapping(uint256 => ChainInfo) public getChainInfo;

    /// @dev DeBridgeGate's address on the current chain
    IDeBridgeGate public deBridgeGate;

    /// @dev DeBridgeNFTDeployer's address on the current chain
    DeNftDeployer public deNftDeployer;

    /// @dev Outgoing submissions count
    uint256 public nonce;

    /// @dev Created collections created by calling createNFT() on the current chain for the burn/mint approach (value is type of NFT)
    mapping(address => uint256) public factoryCreatedTokens;

    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AdminBadRole();
        _;
    }

    /// @dev This modifier restricts calls so they can be made only by deBridge CallProxy
    ///         and ensures the origin transaction submitter is known NFTBridge contract on the origin chain
    modifier onlyCrossBridgeAddress() {
        ICallProxy callProxy = ICallProxy(deBridgeGate.callProxy());
        if (address(callProxy) != msg.sender) {
            revert CallProxyBadRole();
        }

        bytes memory nativeSender = callProxy.submissionNativeSender();
        uint256 chainIdFrom = callProxy.submissionChainIdFrom();

        if (keccak256(getChainInfo[chainIdFrom].nftBridgeAddress) != keccak256(nativeSender)) {
            revert NativeSenderBadRole(nativeSender, chainIdFrom);
        }

        _;
    }

    /* ========== CONSTRUCTOR  ========== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IDeBridgeGate _deBridgeGate) public initializer {
        deBridgeGate = _deBridgeGate;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== EXTERNAL METHODS ========== */

    /// @dev Constructs and initiates a cross chain transfer of an object.
    ///         It obtains an object from the sender and constructs a message to operate the object on the target chain
    /// @param _nftCollectionAddress NFT collection's address in the current chain
    /// @param _tokenId ID of an object from the given NFT collection to transfer
    /// @param _permitDeadline ERC-4494-compliant permit deadline
    /// @param _permitSignature ERC-4494-compliant permit signature to obtain the given object
    /// @param _chainIdTo Target chain id to transfer the given object to
    /// @param _receiverAddress Address on the target chain to transfer the bridged object to
    /// @param _executionFee  Fee to be paid to the claim transaction executor on target chain.
    /// @param _referralCode Referral code to be assigned to this cross chain transaction on the deBridge protocol
    function send(
        address _nftCollectionAddress,
        uint256 _tokenId,
        uint256 _permitDeadline,
        bytes calldata _permitSignature,
        uint256 _chainIdTo,
        address _receiverAddress,
        uint256 _executionFee,
        uint32 _referralCode
    ) external payable nonReentrant whenNotPaused {
        // NFTBridge is not yet deployed on the target chain or its address is not yet registered here
        // -- no receiver on the target chain
        if (!getChainInfo[_chainIdTo].isSupported) {
            revert ChainToIsNotSupported();
        }

        // run permit first
        if (_permitSignature.length > 0) {
            IERC4494(_nftCollectionAddress).permit(
                address(this),
                _tokenId,
                _permitDeadline,
                _permitSignature
            );
        }

        bool isNativeToken;
        bytes memory targetData;
        {
            //
            // find the residence chain for the given nft collection
            //

            NativeNFTInfo storage nativeTokenInfo = getNativeInfo[_nftCollectionAddress];

            // is the current chain a native chain for the given collection?
            isNativeToken = nativeTokenInfo.chainId == 0
                ? true // token not in mapping
                : nativeTokenInfo.chainId == getChainId(); // or token native chain id the same

            // take tokenURI before the object being burned!
            string memory tokenURI = IERC721MetadataUpgradeable(_nftCollectionAddress).tokenURI(
                _tokenId
            );

            // are we on the native chain?
            if (isNativeToken) {
                // if NFT was created by our factory contract
                if (
                    _isInHouse(_nftCollectionAddress) &&
                    // if nftBridge has mint access right
                    IDeNFT(_nftCollectionAddress).hasMinterAccess(address(this))
                ) {
                    // already was added in createNFT
                    // _checkAddAsset(_nftCollectionAddress);
                    IDeNFT(_nftCollectionAddress).burn(_tokenId);
                }
                // hold the object on this contract address
                else {
                    _receiveNativeNFT(_nftCollectionAddress, _tokenId);
                }
            }
            // we are on the secondary chain
            else {
                IDeNFT(_nftCollectionAddress).burn(_tokenId);
            }

            // Encode the function call to be executed on the target chain
            targetData = _encodeClaimOrMint(nativeTokenInfo, _tokenId, _receiverAddress, tokenURI);
        }

        //
        // send message to deBridge gate
        //
        {
            deBridgeGate.send{value: msg.value}(
                address(0), // we transfer native coin as a means of payment
                msg.value, // _amount of native coin (includes transport fees + optional execution fee amount)
                _chainIdTo, // _chainIdTo
                abi.encodePacked(getChainInfo[_chainIdTo].nftBridgeAddress), // _receiverAddress
                "", // _permit
                false, // _useAssetFee
                _referralCode, // _referralCode
                _encodeAutoParamsTo(targetData, _executionFee) // _autoParams
            );
        }

        emit NFTSent(
            _nftCollectionAddress,
            _tokenId,
            abi.encodePacked(_receiverAddress),
            _chainIdTo,
            nonce
        );
        nonce++;
    }

    /// @dev Mints the original object (if called on the native chain for burn/mint-compatible DeNFT collection)
    ///         or a wrapped version of an object (if called on the secondary chain).
    ///         This method is restricted by onlyCrossBridgeAddress modifier: it can be called only by deBridge CallProxy
    ///         and the origin transaction submitter must be an NFTBridge contract on the origin chain
    /// @param _tokenId ID of an object from the given NFT collection to receive and mint
    /// @param _receiver Address on target chain who will receive the object.
    /// @param _tokenUri Payload: the canonical URI of an object from the given NFT collection to mint
    /// @param _tokenInfo Original information about NFT
    function claimOrMint(
        uint256 _tokenId,
        address _receiver,
        string calldata _tokenUri,
        NativeNFTInfo calldata _tokenInfo
    ) external onlyCrossBridgeAddress whenNotPaused {
        bytes32 debridgeId = getDebridgeId(_tokenInfo.chainId, _tokenInfo.tokenAddress);
        BridgeNFTInfo storage bridgeInfo = getBridgeNFTInfo[debridgeId];

        // if NFT on the bridge contract
        if (
            bridgeInfo.nativeChainId == getChainId() &&
            _safeOwnerOf(bridgeInfo.tokenAddress, _tokenId) == address(this)
        ) {
            // withdraw nft to receiver
            _safeTransferFrom(bridgeInfo.tokenAddress, address(this), _receiver, _tokenId);
            emit NFTClaimed(bridgeInfo.tokenAddress, _tokenId, _receiver);
        } else {
            // sanity check: ensure that this conditional branch handles in-house DeNFTs
            if (bridgeInfo.nativeChainId == getChainId() && !_isInHouse(bridgeInfo.tokenAddress)) {
                revert Unreachable();
            }
            // if it's new NFT on this chain (never bridged to this chain)
            if (bridgeInfo.nativeChainId == 0) {
                //!bridgeInfo.exist
                // create new NFT contract
                uint256 mintTokenType = _tokenInfo.tokenType == DeNftConstants.DENFT_TYPE_THIRDPARTY
                    ? DeNftConstants.DENFT_TYPE_BASIC
                    : _tokenInfo.tokenType;
                address currentNFTAddress = deNftDeployer.deployAsset(
                    mintTokenType,
                    debridgeId,
                    _tokenInfo.name,
                    _tokenInfo.symbol
                );
                // register address in bridge contract
                // mind that we don't store tokenType inside the secondary DeNFT
                _addAsset(
                    debridgeId,
                    currentNFTAddress,
                    _tokenInfo.tokenAddress,
                    _tokenInfo.chainId,
                    _tokenInfo.name,
                    _tokenInfo.symbol,
                    _tokenInfo.tokenType
                );
            }
            address tokenAddress = getBridgeNFTInfo[debridgeId].tokenAddress;
            IDeNFT(tokenAddress).mint(_receiver, _tokenId, _tokenUri);

            emit NFTMinted(tokenAddress, _tokenId, _receiver, _tokenUri);
        }
    }

    /// @dev Deploys a new DeNFT collection with the minter role granted to the given address
    ///         and marks it internally as burn/mint-compatible collection
    /// @param _tokenType type of NFT (ERC721/ERC721Votes/etc.)
    /// @param _owner the owner address for the new DeNFT collection
    /// @param _minters the addresses that can mint NFTs in the new DeNFT collection
    /// @param _name The name for the new DeNFT collection
    /// @param _symbol The symbol for the new DeNFT collection
    /// @param _baseUri The base URI for the new DeNFT collection
    function createNFT(
        uint256 _tokenType,
        address _owner,
        address[] memory _minters,
        string calldata _name,
        string calldata _symbol,
        string calldata _baseUri
    ) external whenNotPaused {
        if (_tokenType == 0 || _tokenType == DeNftConstants.DENFT_TYPE_THIRDPARTY)
            revert WrongArgument();
        address currentNFTAddress = deNftDeployer.createNFT(
            _tokenType,
            _owner,
            _minters,
            _name,
            _symbol,
            _baseUri
        );
        factoryCreatedTokens[currentNFTAddress] = _tokenType;
        _addNativeAssetIfNew(currentNFTAddress);
    }

    /// @inheritdoc IERC721ReceiverUpgradeable
    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*tokenId*/
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    // ============ ADMIN METHODS ============

    /// @dev Sets NFT deployer
    /// @param _newDeployer new nft deployer contract address
    function setNftDeployer(DeNftDeployer _newDeployer) external onlyAdmin {
        address oldDeployer = address(deNftDeployer);
        deNftDeployer = _newDeployer;
        emit updatedNftDeployer(oldDeployer, address(_newDeployer));
    }

    function setDeBridgeGate(IDeBridgeGate _deBridgeGate) external onlyAdmin {
        deBridgeGate = _deBridgeGate;
    }

    /// @dev Sets the address of the NFTBridge contract on the secondary chain, effectively enabling object transfers to it
    /// @param _nftBridgeAddress The address of the NFTBridge contract deployed on the secondary chain
    /// @param _chainId The id of the secondary chain
    function addChainSupport(bytes calldata _nftBridgeAddress, uint256 _chainId)
        external
        onlyAdmin
    {
        if (_chainId == 0 || _chainId == getChainId()) {
            revert WrongArgument();
        }
        getChainInfo[_chainId].nftBridgeAddress = _nftBridgeAddress;
        getChainInfo[_chainId].isSupported = true;

        emit AddedChainSupport(_nftBridgeAddress, _chainId);
    }

    function removeChainSupport(uint256 _chainId) external onlyAdmin {
        delete getChainInfo[_chainId];
        emit RemovedChainSupport(_chainId);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    // ============ Private methods ============

    /// @dev Save information about token to BridgeNFTInfo and NativeNFTInfo
    function _addAsset(
        bytes32 _debridgeId,
        address _nftCollectionAddress,
        bytes memory _nativeAddress,
        uint256 _nativeChainId,
        string memory _nativeName,
        string memory _nativeSymbol,
        uint256 _nftCollectionType
    ) internal {
        BridgeNFTInfo storage bridgeInfo = getBridgeNFTInfo[_debridgeId];

        if (_nativeChainId == 0) revert ZeroChainId();
        // bridgeInfo.exist
        if (bridgeInfo.nativeChainId != 0) revert AssetAlreadyExist();
        if (_nftCollectionAddress == address(0)) revert ZeroAddress();

        // bridgeInfo.exist = true;
        bridgeInfo.tokenAddress = _nftCollectionAddress;
        bridgeInfo.nativeChainId = _nativeChainId;

        NativeNFTInfo storage nativeTokenInfo = getNativeInfo[_nftCollectionAddress];
        nativeTokenInfo.chainId = _nativeChainId;
        nativeTokenInfo.tokenAddress = _nativeAddress;
        nativeTokenInfo.name = _nativeName;
        nativeTokenInfo.symbol = _nativeSymbol;
        nativeTokenInfo.tokenType = _nftCollectionType;

        emit NFTContractAdded(
            _debridgeId,
            _nftCollectionAddress,
            abi.encodePacked(_nativeAddress),
            _nativeChainId,
            _nativeName,
            _nativeSymbol,
            _nftCollectionType
        );
    }

    function _decodeAddressFromBytes(bytes memory _bytes) internal pure returns (address addr) {
        // See https://ethereum.stackexchange.com/a/50528
        assembly {
            addr := mload(add(_bytes, 20))
        }
    }

    function _receiveNativeNFT(address _tokenAddress, uint256 _tokenId) internal {
        _addNativeAssetIfNew(_tokenAddress);
        _safeTransferFrom(_tokenAddress, msg.sender, address(this), _tokenId);
    }

    /// @dev Save information about token to BridgeNFTInfo and NativeNFTInfo if this token transfer first time
    function _addNativeAssetIfNew(address _tokenAddress) internal returns (bytes32 debridgeId) {
        debridgeId = getDebridgeId(getChainId(), _tokenAddress);
        // if this NFT never bridged
        if (getBridgeNFTInfo[debridgeId].nativeChainId == 0) {
            _addAsset(
                debridgeId,
                _tokenAddress,
                abi.encodePacked(_tokenAddress),
                getChainId(),
                IERC721MetadataUpgradeable(_tokenAddress).name(),
                IERC721MetadataUpgradeable(_tokenAddress).symbol(),
                _getTokenType(_tokenAddress)
            );
        }
    }

    /// @dev Safely transfers the given object and performs additional ownership check
    function _safeTransferFrom(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        IERC721Upgradeable(_tokenAddress).safeTransferFrom(_from, _to, _tokenId);

        // check that this contract address actually received the object
        if (_safeOwnerOf(_tokenAddress, _tokenId) != _to) revert NotReceivedERC721();
    }

    /// @dev encodes a call to `NFTBridge.claimOrMint()`
    function _encodeClaimOrMint(
        NativeNFTInfo storage nativeTokenInfo,
        uint256 _tokenId,
        address _receiverAddress,
        string memory _tokenURI
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                this.claimOrMint.selector,
                _tokenId,
                _receiverAddress,
                _tokenURI,
                nativeTokenInfo
            );
    }

    /// @dev encodes a `IDeBridgeGate.SubmissionAutoParamsTo` struct required for deBridge gate
    function _encodeAutoParamsTo(bytes memory _data, uint256 _executionFee)
        internal
        view
        returns (bytes memory)
    {
        IDeBridgeGate.SubmissionAutoParamsTo memory autoParams;
        autoParams.flags = Flags.setFlag(autoParams.flags, Flags.REVERT_IF_EXTERNAL_FAIL, true);
        autoParams.flags = Flags.setFlag(autoParams.flags, Flags.PROXY_WITH_SENDER, true);

        // fallbackAddress can be used to transfer NFT with deAssets
        autoParams.fallbackAddress = abi.encodePacked(msg.sender);
        autoParams.data = _data;
        autoParams.executionFee = _executionFee;
        return abi.encode(autoParams);
    }

    /// @dev Gets the token type of nft
    function _getTokenType(address _tokenAddress) internal view virtual returns (uint256) {
        uint256 tokenType = factoryCreatedTokens[_tokenAddress];
        // it this NFT was created not our factory set type to EXTERNAL_NFT_TYPE
        // if (tokenType == 0) return EXTERNAL_NFT_TYPE;
        return tokenType > 0 ? tokenType : DeNftConstants.DENFT_TYPE_THIRDPARTY;
    }

    // ============ VIEWS ============

    /// @dev Cross-chain identifier of a native NFT collection
    /// @param _nativeChainId Native chain ID for the NFT collection
    /// @param _nftCollectionAddress Original NFT collection's address on the native chain
    function getDebridgeId(uint256 _nativeChainId, address _nftCollectionAddress)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_nativeChainId, _nftCollectionAddress));
    }

    /// @dev Cross-chain identifier of a native NFT collection
    /// @param _nativeChainId Native chain ID for the NFT collection
    /// @param _nftCollectionAddress Original NFT collection's address on the native chain
    function getDebridgeId(uint256 _nativeChainId, bytes memory _nftCollectionAddress)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_nativeChainId, _nftCollectionAddress));
    }

    /// @dev Gets the current chain id
    function getChainId() public view virtual returns (uint256 cid) {
        assembly {
            cid := chainid()
        }
    }

    /// @dev Returns the owner of the `tokenId` token.
    /// @notice Return address(0) if NFT not exist and it's in-house DeNFTs
    function _safeOwnerOf(address _nft, uint256 _tokenId) internal view returns (address owner) {
        if (_isInHouse(_nft) && !DeNFT(_nft).exists(_tokenId)) {
            return address(0);
        }

        (bool success, bytes memory data) = _nft.staticcall(
            abi.encodeWithSelector(IERC721Upgradeable.ownerOf.selector, _tokenId)
        );
        if (success) {
            owner = abi.decode(data, (address));
        }
    }

    /// @dev This NFT was created by this smart contract
    function _isInHouse(address _nft) internal view returns (bool) {
        uint256 tokenType = factoryCreatedTokens[_nft];
        return (tokenType != 0 && tokenType != DeNftConstants.DENFT_TYPE_THIRDPARTY);
    }

    // ============ Version Control ============
    function version() external pure returns (uint256) {
        return 100; // 1.0.0
    }
}