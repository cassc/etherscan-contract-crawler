// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { ICollectionFactory } from "../interfaces/ICollectionFactory.sol";
import { ICollection } from "../interfaces/ICollection.sol";
import { ICollectionCloneable } from "../interfaces/ICollectionCloneable.sol";
import { ICollectionNFTCloneableV1 } from "../interfaces/ICollectionNFTCloneableV1.sol";
import { ICollectionNFTEligibilityPredicate } from "../interfaces/ICollectionNFTEligibilityPredicate.sol";
import { ICollectionNFTMintFeePredicate } from "../interfaces/ICollectionNFTMintFeePredicate.sol";
import { IERC2981Royalties } from "../interfaces/IERC2981Royalties.sol";
import { IHashes } from "../interfaces/IHashes.sol";
import { IOwnable } from "../interfaces/IOwnable.sol";
import { OwnableCloneable } from "./OwnableCloneable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title CollectionNFTCloneableV1
 * @author DEX Labs
 * @notice This contract is the cloneable template for Hashes Collections.
 *         It is an ERC-721 contract which is preconfigured to work within
 *         the Hashes ecosystem. Creation logic has been moved to an initialization
 *         function so it works with the cloneable factory pattern.
 */
contract CollectionNFTCloneableV1 is
    ICollection,
    ICollectionCloneable,
    ICollectionNFTCloneableV1,
    OwnableCloneable,
    ERC721Enumerable,
    IERC2981Royalties,
    ReentrancyGuard
{
    using SafeMath for uint16;
    using SafeMath for uint64;
    using SafeMath for uint128;
    using SafeMath for uint256;

    bool _initialized;

    /// @notice A structure for storing a token ID in a map.
    struct TokenIdEntry {
        bool exists;
        uint128 tokenId;
    }

    /// @notice A structure for decoding and storing data from the factory initializer
    struct InitializerSettings {
        string tokenName;
        string tokenSymbol;
        string baseTokenURI;
        uint256 cap;
        ICollectionNFTEligibilityPredicate mintEligibilityPredicateContract;
        ICollectionNFTMintFeePredicate mintFeePredicateContract;
        uint16 royaltyBps;
        address signatureBlockAddress;
    }

    /// @notice nonce Monotonically-increasing number (token ID).
    uint256 public nonce;

    /// @notice cap The supply cap for this token. Set to 0 for unlimited.
    uint256 public cap;

    /// @notice baseTokenURI The base token URI for this token.
    string public baseTokenURI;

    /// @notice tokenName The name of the ERC-721 token.
    string private tokenName;

    /// @notice tokenSymbol The symbol of the ERC-721 token.
    string private tokenSymbol;

    /// @notice creatorAddress The address of the collection creator.
    address public creatorAddress;

    /// @notice signatureBlockAddress An optional address which (when set) will cause all tokens to be
    ///         minted from this address and then immediately transfered to the mint message sender.
    address public signatureBlockAddress;

    // Interface for contract which contains a function isTokenEligibleToMint(tokenId, hashesTokenId)
    // used for determining mint eligibility for a Hashes token.
    ICollectionNFTEligibilityPredicate public mintEligibilityPredicateContract;

    // Interface for contract which contains a function getTokenMintFee(tokenId, hashesTokenId)
    // used for determining the mint fee for a Hashes token.
    ICollectionNFTMintFeePredicate public mintFeePredicateContract;

    /// @notice hashesIdToCollectionTokenIdMapping Mapping of Hashes ID to collection token ID.
    mapping(uint256 => TokenIdEntry) public hashesIdToCollectionTokenIdMapping;

    /// @notice royaltyBps The sales royalty amount (in hundredths of a percent).
    uint16 public royaltyBps;

    uint16 private _hashesDAOMintFeePercent;

    uint16 private _hashesDAORoyaltyFeePercent;

    uint16 private _maximumCollectionRoyaltyPercent;

    /// @notice isSignatureBlockCompleted Whether the signature block address has interacted with this
    ///         contract to verify their support of this contract and establish provenance.
    bool public isSignatureBlockCompleted;

    IHashes hashesToken;

    /// @notice CollectionInitialized Emitted when a Collection is initialized.
    event CollectionInitialized(
        string tokenName,
        string tokenSymbol,
        string baseTokenURI,
        uint256 cap,
        address mintEligibilityPredicateAddress,
        address mintFeePredicateAddress,
        uint16 royaltyBps,
        address signatureBlockAddress,
        uint64 indexed initializationBlock
    );

    /// @notice Minted Emitted when a Hashes Collection is minted.
    event Minted(address indexed minter, uint256 indexed tokenId, uint256 indexed hashesTokenId);

    /// @notice BaseTokenURISet Emitted when the base token URI is updated.
    event BaseTokenURISet(string baseTokenURI);

    /// @notice Withdraw Emitted when a withdraw event is triggered.
    event Withdraw(uint256 indexed creatorAmount, uint256 indexed hashesDAOAmount);

    /// @notice CreatorTransferred Emitted when the creator address is transferred.
    event CreatorTransferred(address indexed previousCreator, address indexed newCreator);

    /// @notice RoyaltyBpsSet Emitted when the royalty bps is set.
    event RoyaltyBpsSet(uint16 royaltyBps);

    /// @notice Burned Emitted when a token is burned.
    event Burned(address indexed burner, uint256 indexed tokenId);

    /// @notice SignatureBlockCompleted Emitted when the signature block is completed.
    event SignatureBlockCompleted(address indexed signatureBlockAddress);

    /// @notice SignatureBlockAddressSet Emitted when the signature block address is set.
    event SignatureBlockAddressSet(address indexed signatureBlockAddress);

    modifier initialized() {
        require(_initialized, "CollectionNFTCloneableV1: hasn't been initialized yet.");
        _;
    }

    modifier onlyOwnerOrHashesDAO() {
        require(
            _msgSender() == owner() || _msgSender() == IOwnable(address(hashesToken)).owner(),
            "CollectionNFTCloneableV1: must be contract owner or HashesDAO"
        );
        _;
    }

    modifier onlyCreator() {
        require(_msgSender() == creatorAddress, "CollectionNFTCloneableV1: must be contract creator");
        _;
    }

    /**
     * @notice Constructor for the cloneable Hashes Collection contract. The ERC-721 token
     *         name and symbol aren't used since they are provided in the initialize function.
     */
    constructor() ERC721("TOKEN_NAME_PLACEHOLDER", "TOKEN_SYMBOL_PLACEHOLDER") {}

    receive() external payable {}

    /**
     * @notice This function is used by the Factory to verify the format of ecosystem settings
     * @param _settings ABI encoded ecosystem settings data. This expected encoding for
     *        ecosystem name 'NFT_v1' is the following:
     *
     *        'uint16' hashesDAOMintFeePercent - The percentage of mint fees owable to HashesDAO.
     *        'uint16' hashesDAORoyaltyFeePercent - The percentage of royalties owable to HashesDAO. This will
     *                 be the percentage of the royalties percent set by the creator.
     *        'uint16' maximumCollectionRoyaltyPercent - The highest allowable royalty percentage
     *                 settable by creators for cloned instances of this contract.
     * @return The boolean result of the validation.
     */
    function verifyEcosystemSettings(bytes memory _settings) external pure override returns (bool) {
        (
            uint16 _settingsHashesDAOMintFeePercent,
            uint16 _settingsHashesDAORoyaltyFeePercent,
            uint16 _settingsMaximumCollectionRoyaltyPercent
        ) = abi.decode(_settings, (uint16, uint16, uint16));

        return
            _settingsHashesDAOMintFeePercent <= 10000 &&
            _settingsHashesDAORoyaltyFeePercent <= 10000 &&
            _settingsMaximumCollectionRoyaltyPercent <= 10000;
    }

    /**
     * @notice This function initializes a cloneable implementation contract.
     * @param _hashesToken The Hashes NFT contract address.
     * @param _factoryMaintainerAddress The address of the current factory maintainer
     *        which will be the Owner role of this collection.
     * @param _createCollectionCaller The address which has called createCollection on the factory.
     *        This will be the Creator role of this collection.
     * @param _initializationData ABI encoded initialization data. This expected encoding is a struct
     *        with the following properties:
     *
     *        'string' tokenName - The name of the resulting ERC-721 token.
     *        'string' tokenSymbol - The symbol of the resulting ERC-721 token.
     *        'string' baseTokenURI - The initial base token URI of the resulting ERC-721 token.
     *        'uint256' cap - The maximum token supply of the resulting ERC-721 token. Set 0 for no limit.
     *        'address' mintEligibilityPredicateContract - The address of a contract which contains a
     *                  function isTokenEligibleToMint(uint256 tokenId, uint256 hashesTokenId) used to
     *                  determine whether the chosen Hashes token ID is eligible for minting. Contracts
     *                  which define this logic should implement the interface ICollectionNFTEligibilityPredicate.
     *        'address' mintFeePredicateContract - The address of a contract which contains a function
     *                  getTokenMintFee(tokenId, hashesTokenId) used to determine the mint fee for the
     *                  chosen Hashes token ID. Contracts which define this logic should implement the
     *                  interface ICollectionNFTMintFeePredicate.
     *        'uint16' royaltyBps - The sales royalty that should be collected. A percentage of this
     *                 will be allocated for the HashesDAO to withdraw.
     *        'address' signatureBlockAddress - An optional address which can be used to establish
     *                  creator provenance. When set, the specified address (could be the artist for example)
     *                  can call completeSignatureBlock to establish provenance and sign off on the contract
     *                  values. To skip using this mechanism, set the value of this field to the 0x0 address.
     */
    function initialize(
        IHashes _hashesToken,
        address _factoryMaintainerAddress,
        address _createCollectionCaller,
        bytes memory _initializationData
    ) external override {
        require(!_initialized, "CollectionNFTCloneableV1: already inititialized.");

        initializeOwnership(_factoryMaintainerAddress);
        creatorAddress = _createCollectionCaller;

        // Use this struct workaround to get around Stack Too Deep issues
        InitializerSettings memory _initializerSettings;
        (_initializerSettings) = abi.decode(_initializationData, (InitializerSettings));
        tokenName = _initializerSettings.tokenName;
        tokenSymbol = _initializerSettings.tokenSymbol;
        baseTokenURI = _initializerSettings.baseTokenURI;
        cap = _initializerSettings.cap;
        mintEligibilityPredicateContract = _initializerSettings.mintEligibilityPredicateContract;
        mintFeePredicateContract = _initializerSettings.mintFeePredicateContract;
        royaltyBps = _initializerSettings.royaltyBps;
        signatureBlockAddress = _initializerSettings.signatureBlockAddress;

        uint64 _initializationBlock = safe64(block.number, "CollectionNFTCloneableV1: exceeds 64 bits.");
        bytes memory settingsBytes = ICollectionFactory(_msgSender()).getEcosystemSettings(
            keccak256(abi.encodePacked("NFT_v1")),
            _initializationBlock
        );

        (_hashesDAOMintFeePercent, _hashesDAORoyaltyFeePercent, _maximumCollectionRoyaltyPercent) = abi.decode(
            settingsBytes,
            (uint16, uint16, uint16)
        );

        require(
            royaltyBps <= _maximumCollectionRoyaltyPercent,
            "CollectionNFTCloneableV1: royalty percentage must be less than or equal to maximum allowed setting"
        );

        _initialized = true;

        hashesToken = _hashesToken;

        emit CollectionInitialized(
            tokenName,
            tokenSymbol,
            baseTokenURI,
            cap,
            address(mintEligibilityPredicateContract),
            address(mintFeePredicateContract),
            royaltyBps,
            signatureBlockAddress,
            _initializationBlock
        );
    }

    /**
     * @notice The function used to mint instances of this Hashes Collection ERC-721 token.
     *         Minting requires passing in a specific Hashes token id which is owned by the minter.
     *         Each Hashes token id may only be used to mint once towards a specific collection.
     *         The minting eligibility and fee structure are determined per Hashes token id
     *         by the Hashes Collection owner through predicate functions. The Hashes DAO will receive
     *         a minting fee percentage of each mint, unless a DAO hash was used to mint.
     * @param _hashesTokenId The Hashes token Id being used to mint.
     */
    function mint(uint256 _hashesTokenId) external payable override initialized nonReentrant {
        require(cap == 0 || nonce < cap, "CollectionNFTCloneableV1: supply cap has been reached");
        require(
            _msgSender() == hashesToken.ownerOf(_hashesTokenId),
            "CollectionNFTCloneableV1: must be owner of supplied hashes token ID to mint"
        );
        require(
            !hashesIdToCollectionTokenIdMapping[_hashesTokenId].exists,
            "CollectionNFTCloneableV1: supplied token ID has already been used to mint with this collection"
        );

        // get mint eligibility through static call
        bool isHashesTokenIdEligibleToMint = mintEligibilityPredicateContract.isTokenEligibleToMint(
            nonce,
            _hashesTokenId
        );
        require(isHashesTokenIdEligibleToMint, "CollectionNFTCloneableV1: supplied token ID is ineligible to mint");

        // get mint fee through static call
        uint256 currentMintFee = mintFeePredicateContract.getTokenMintFee(nonce, _hashesTokenId);
        require(msg.value >= currentMintFee, "CollectionNFTCloneableV1: must pass sufficient mint fee.");

        hashesIdToCollectionTokenIdMapping[_hashesTokenId] = TokenIdEntry({
            exists: true,
            tokenId: safe128(nonce, "CollectionNFTCloneableV1: exceeds 128 bits.")
        });

        uint256 feeForHashesDAO = (currentMintFee.mul(_hashesDAOMintFeePercent)) / 10000;
        uint256 authorFee = currentMintFee.sub(feeForHashesDAO);

        uint256 mintFeePaid;
        if (authorFee > 0) {
            // If the minting fee is non-zero
            mintFeePaid = mintFeePaid.add(authorFee);

            (bool sent, ) = creatorAddress.call{ value: authorFee }("");
            require(sent, "CollectionNFTCloneableV1: failed to send ETH to creator address");
        }

        // Only apply the minting tax for non-DAO hashes (tokenID >= 1000 or deactivated DAO tokens)
        if (feeForHashesDAO > 0 && (_hashesTokenId >= 1000 || hashesToken.deactivated(_hashesTokenId))) {
            // If the hashes DAO minting fee is non-zero

            // Send minting tax to HashesDAO
            (bool sent, ) = IOwnable(address(hashesToken)).owner().call{ value: feeForHashesDAO }("");
            require(sent, "CollectionNFTCloneableV1: failed to send ETH to HashesDAO");

            mintFeePaid = mintFeePaid.add(feeForHashesDAO);
        }

        if (msg.value > mintFeePaid) {
            // If minter passed ETH value greater than the minting
            // fee paid/computed above

            // Refund the remaining ether balance to the sender. Since there are no
            // other payable functions, this remainder will always be the senders.
            (bool sent, ) = _msgSender().call{ value: msg.value.sub(mintFeePaid) }("");
            require(sent, "CollectionNFTCloneableV1: failed to refund ETH.");
        }

        _safeMint(_msgSender(), nonce++);

        emit Minted(_msgSender(), nonce - 1, _hashesTokenId);
    }

    /**
     * @notice The function allows the token owner or approved address to burn the token.
     * @param _tokenId The token Id to be burned.
     */
    function burn(uint256 _tokenId) external override initialized {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "CollectionNFTCloneableV1: caller is not owner nor approved."
        );
        _burn(_tokenId);

        emit Burned(_msgSender(), _tokenId);
    }

    /**
     * @notice The signatureBlockAddress can call this function to establish provenance and effectively
     *         sign off on the contract. Can be useful in cases where the creator address is different
     *         from the artist address.
     */
    function completeSignatureBlock() external override initialized {
        require(!isSignatureBlockCompleted, "CollectionNFTCloneableV1: signature block has already been completed");
        require(
            signatureBlockAddress != address(0),
            "CollectionNFTCloneableV1: signature block address has not been set."
        );
        require(
            _msgSender() == signatureBlockAddress,
            "CollectionNFTCloneableV1: only signature block address can complete signature block"
        );
        isSignatureBlockCompleted = true;

        emit SignatureBlockCompleted(signatureBlockAddress);
    }

    /// @inheritdoc IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        // Send royalties to this contract address. Note: this will only work for
        // marketplaces which implement the ERC2981 royalty standard. Off-chain
        // configuration may be required for certain marketplaces.
        return (address(this), (value.mul(royaltyBps)).div(10000));
    }

    /**
     * @notice The function used to renounce contract ownership. This can be performed
     *         by either the Owner or HashesDAO. This departs slightly from the traditional
     *         implementation where only the Owner has this permission. HashesDAO may
     *         need to perform this actions in the case of the factory maintainer changing,
     *         getting lost, or being taken over by a bad actor.
     */
    function renounceOwnership() public override ownershipInitialized onlyOwnerOrHashesDAO {
        _setOwner(address(0));
    }

    /**
     * @notice The function used to transfer contract ownership. This can be performed by
     *         either the owner or HashesDAO. This departs slightly from the traditional
     *         implementation where only the Owner has this permission. HashesDAO may
     *         need to perform this actions in the case of the factory maintainer changing,
     *         getting lost, or being taken over by a bad actor.
     * @param newOwner The new owner address.
     */
    function transferOwnership(address newOwner) public override ownershipInitialized onlyOwnerOrHashesDAO {
        require(newOwner != address(0), "CollectionNFTCloneableV1: new owner is the zero address");
        _setOwner(newOwner);
    }

    /**
     * @notice The function used to set the base token URI. Only collection creator may call.
     * @param _baseTokenURI The base token URI.
     */
    function setBaseTokenURI(string memory _baseTokenURI) external override initialized onlyCreator {
        baseTokenURI = _baseTokenURI;
        emit BaseTokenURISet(_baseTokenURI);
    }

    /**
     * @notice The function used to set the sales royalty bps. Only collection creator may call.
     * @param _royaltyBps The sales royalty percent in hundredths of a percent.
     */
    function setRoyaltyBps(uint16 _royaltyBps) external override initialized onlyCreator {
        require(
            _royaltyBps <= _maximumCollectionRoyaltyPercent,
            "CollectionNFTCloneableV1: royalty percentage must be less than or equal to maximum allowed setting"
        );
        royaltyBps = _royaltyBps;
        emit RoyaltyBpsSet(_royaltyBps);
    }

    /**
     * @notice The function used to transfer the creator address. Only collection creator may call.
     *         This is especially important since this concerns withdrawl permissions.
     * @param _creatorAddress The new creator address.
     */
    function transferCreator(address _creatorAddress) external override initialized onlyCreator {
        address oldCreator = creatorAddress;
        creatorAddress = _creatorAddress;
        emit CreatorTransferred(oldCreator, _creatorAddress);
    }

    function setSignatureBlockAddress(address _signatureBlockAddress) external override initialized onlyCreator {
        require(!isSignatureBlockCompleted, "CollectionNFTCloneableV1: signature block has already been completed");
        signatureBlockAddress = _signatureBlockAddress;
        emit SignatureBlockAddressSet(_signatureBlockAddress);
    }

    /**
     * @notice The function used to withdraw funds to the Collection creator and HashesDAO addresses.
     *         The balance of the contract is equal to the royalties and gifts owed to the creator and HashesDAO.
     */
    function withdraw() external override initialized {
        // The contract balance is equal to the royalties or gifts which need to be allocated
        // to both the creator and HashesDAO.
        uint256 _contractBalance = address(this).balance;

        // The amount owed to the DAO will be the total royalties times the royalty
        // fee percent value (in bps).
        uint256 _daoRoyaltiesOwed = (_contractBalance.mul(_hashesDAORoyaltyFeePercent)).div(10000);

        // The amount owed to the creator will then be the total balance of the contract minus the DAO
        // royalties owed.
        uint256 _creatorRoyaltiesOwed = _contractBalance.sub(_daoRoyaltiesOwed);

        if (_creatorRoyaltiesOwed > 0) {
            (bool sent, ) = creatorAddress.call{ value: _creatorRoyaltiesOwed }("");
            require(sent, "CollectionNFTCloneableV1: failed to send ETH to creator address");
        }

        if (_daoRoyaltiesOwed > 0) {
            (bool sent, ) = IOwnable(address(hashesToken)).owner().call{ value: _daoRoyaltiesOwed }("");
            require(sent, "CollectionNFTCloneableV1: failed to send ETH to HashesDAO");
        }

        emit Withdraw(_creatorRoyaltiesOwed, _daoRoyaltiesOwed);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC2981Royalties).interfaceId || ERC721Enumerable.supportsInterface(interfaceId);
    }

    /**
     * @notice The function used to get the Hashes Collection token URI.
     * @param _tokenId The Hashes Collection token Id.
     */
    function tokenURI(uint256 _tokenId) public view override initialized returns (string memory) {
        // Ensure that the token ID is valid and that the hash isn't empty.
        require(_tokenId < nonce, "CollectionNFTCloneableV1: Can't provide a token URI for a non-existent collection.");

        // Return the base token URI concatenated with the token ID.
        return string(abi.encodePacked(baseTokenURI, _toDecimalString(_tokenId)));
    }

    /**
     * @notice The function used to get the name of the Hashes Collection token
     */
    function name() public view override initialized returns (string memory) {
        return tokenName;
    }

    /**
     * @notice The function used to get the symbol of the Hashes Collection token
     */
    function symbol() public view override initialized returns (string memory) {
        return tokenSymbol;
    }

    function _toDecimalString(uint256 _value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }

    function safe64(uint256 n, string memory errorMessage) internal pure returns (uint64) {
        require(n < 2**64, errorMessage);
        return uint64(n);
    }

    function safe128(uint256 n, string memory errorMessage) internal pure returns (uint128) {
        require(n < 2**128, errorMessage);
        return uint128(n);
    }
}