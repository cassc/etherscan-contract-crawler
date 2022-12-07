/**
 *
 *
 *            .':looooc;.    .,cccc,.    'cccc:. 'ccccc:. .:ccccccccccccc:. .:ccc:.    .;cccc,
 *          .lOXNWWWNWNNKx;. .kWNNWk.    lNWNWK, dWWWNWX; :XWNWNNNNNWNWWWX: :XWNWX:    .OWNNWd.
 *         ;0NNNNNXKXNNNNNXd..kWNNWk.    lNNNWK, oNNNNWK; :KWNNNNNNNNNNNN0, :XWNWX:    .OWNNNd.
 *        ;0WNNN0c,.';x0Oxoc..kWNNW0c;:::xNNNWK, oNNNNWK; .;;;;:dKNNNNNXd'  :XWNWX:    .OWNNNd.
 *       .oNNNWK;     ...    .kWNNNNNNNNNNNNNWK, :0NWNXx'     .l0NNNNNk;.   :XWNWX:    .OWNNNd.
 *       .oNNNWK;     ...    .kWNNNNNWWWWNNNNWK,  .,c:'.    .;ONNNNN0c.     :XWNWXc    'OWNNNd.
 *        ;0NNNN0l,.':xKOkdc..kWNNW0occcckNNNWK, .:oddo,.  'xXNNNNNKo::::;. '0WNNN0c,,:xXNNWXc
 *         ;0NNNNNXKXNNNNNXo..kWNNWk.    lNNNWK,.oNNNNWK; :KNNNNNNNNNNNNNXc  :KNNNNNNXNNNNNNd.
 *          .lkXNWNNWWNNKx;. .kWNNWk.    lNWNWK, :KNWNNk' oNWNNWNNNNNWNNWNc   ,dKNWWNNWWNXk:.
 *            .':looolc;.    .,c::c,.    ':::c;.  .:c:,.  ':c::c:::c::::c:.     .;coodol:'.
 *
 *
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libs/interfaces/IDistinctiveCollection.sol";
import "./libs/interfaces/ICollectionFactory.sol";
import "./libs/interfaces/IGetRoyalties.sol";
import "./libs/interfaces/IRoyaltyInfo.sol";
import "./libs/interfaces/INodeRole.sol";
import "./libs/interfaces/ILazyMintable.sol";
import "./libs/interfaces/IMigrateable.sol";
import "./libs/interfaces/ICHIZUCore.sol";
import "./libs/interfaces/IMetaData.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./libs/OZ/OZERC165Checker.sol";
import "./libs/markets/CopyrightRegistry.sol";
import "./libs/users/AddressManagerNode.sol";
import "./libs/nfts/ERC721Distinctive.sol";
import "./libs/utils/CopyrightInfo.sol";
import "./libs/utils/AddressLibrary.sol";

error DistinctiveCollection_Not_Owner();
error DistinctiveCollection_Not_Match_Msg_Sender();
error DistinctiveCollection_Can_Not_Migrate_To_ADDRESS_0();
error DistinctiveCollection_Can_Not_Move_To_Same_Collection();
error DistinctiveCollection_Not_Support_Interface();
error DistinctiveCollection_Holder_Is_Not_Creator();
error DistinctiveCollection_Over_Than_Limit_Numer();
error DistinctiveCollection_Policy_Is_Not_0();
error DistinctiveCollection_Creator_Is_Not_Owner();
error DistinctiveCollection_Time_Expired();

/***
 * @title A collection of NFTs made by a creator.
 */
contract DistinctiveCollection is
    IDistinctiveCollection,
    IRoyaltyInfo,
    IGetRoyalties,
    ILazyMintable,
    IMigrateable,
    Initializable,
    AddressManagerNode,
    ERC721Distinctive
{
    using ECDSA for bytes32;
    using AddressLibrary for address;
    using AddressUpgradeable for address;
    using OZERC165Checker for address;
    using Strings for uint256;

    /// @notice Maximum amount that can be moved
    uint256 constant MAX_MIGRATE_NUMBER = 20;

    /// @notice Copyright that do not provide royalty
    uint256 constant EXCLUSIVE = 20;

    /// @dev Check if it's a used hash
    mapping(bytes32 => bool) public mintHashHistory;

    /**
     * @notice Emitted when a new NFT is minted.
     * @param creator The address of the collection owner at this time this NFT was minted.
     * @param tokenId The tokenId of the newly minted NFT.
     * @param indexedTokenIPFSHash The IPFSHash of the newly minted NFT, indexed to enable watching for mint events by the tokenIPFSHash.
     * @param tokenIPFSHash The actual IPFSHash of the newly minted NFT.
     * @param mintHash The mintHash of the newly minted NFT.
     */
    event Minted(
        address indexed creator,
        uint256 indexed tokenId,
        uint256 policy,
        string indexed indexedTokenIPFSHash,
        string tokenIPFSHash,
        bytes32 mintHash
    );

    /**
     * @notice Emitted when a NFT is burned.
     * @param tokenId The tokenId to burn.
     */
    event Burned(uint256 tokenId, bytes32 indexed burnHash);

    /**
     * @notice Emitted when a NFT is migrated.
     * @param tokenId The tokenId to migrate
     * @param ipfsHash The ipfsHash of the migrated NFT
     * @param from Account sending nft
     * @param to Account receiving nft
     * @param salt Random number value used in the transaction
     */
    event Migrated(
        uint256 tokenId,
        uint256 policy,
        string ipfsHash,
        address from,
        address to,
        uint256 salt
    );

    /**
     * @notice Initialize the template's immutable variables.
     * @param _contractFactory The factory which will be used to create collection contracts.
     */
    constructor(address _contractFactory)
        ContractFactory(_contractFactory) // solhint-disable-next-line no-empty-blocks
    {}

    /**
     * @notice Called by the contract factory on creation.
     * @param _creator The creator of this collection.
     * @param _name The collection's `name`.
     * @param _symbol The collection's `symbol`.
     */
    function initialize(
        address payable _creator,
        string calldata _name,
        string calldata _symbol,
        address _core
    ) external override initializer onlyContractFactory {
        _initializeERC721Distinctive(_creator, _name, _symbol, _core);
    }

    /**
     * @notice Allows the creator to burn a specific token if they currently own the NFT.
     * @param tokenId The ID of the NFT to burn.
     * @dev The function here asserts `onlyOwner` while the super confirms ownership.
     */
    function burn(
        uint256 tokenId,
        uint256 expiredAt,
        address nodeAddress,
        bytes32 burnHash,
        bytes memory burnSignature
    ) public onlyCreator {
        if (expiredAt < block.timestamp) {
            revert DistinctiveCollection_Time_Expired();
        }
        _validateBurnSignature(
            address(this),
            msg.sender,
            tokenId,
            expiredAt,
            nodeAddress,
            burnHash,
            burnSignature
        );
        if (creator() != owner()) {
            revert DistinctiveCollection_Creator_Is_Not_Owner();
        }
        require(
            collectionInfo.licensor == msg.sender,
            "DistinctiveCollection: caller is not token owner nor approved"
        );
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "DistinctiveCollection: caller is not token owner nor approved"
        );
        _burn(tokenId);
        emit Burned(tokenId, burnHash);
    }

    /**
     * @notice It allows you to mint with hash and signature
     * @notice Used when you want to mint with policy
     * @param signerAddress This is the address of the person who signed about mint
     * @param mintSignature Mint signature signed with minthash
     * @param mintHash It's a hash of the transaction information about mint
     * @param creatorAddress This is the address of the creator
     * @param receiverAddress This is the address of the recipient
     * @param ipfsHash ipfshash used for mint
     * @param policy To register policy id.
     * @return tokenId newly minted tokenId of nft
     * @dev Used hash value is not available
     */
    function mint(
        address signerAddress,
        bytes memory mintSignature,
        bytes32 mintHash,
        address creatorAddress,
        address receiverAddress,
        uint256 policy,
        string memory ipfsHash,
        uint256 expiredAt
    ) public returns (uint256 tokenId) {
        require(
            !mintHashHistory[mintHash],
            "DistinctiveCollection_Hash_Is_Duplicated"
        );

        if (expiredAt < block.timestamp) {
            revert DistinctiveCollection_Time_Expired();
        }

        if (policy == 0) {
            revert DistinctiveCollection_Policy_Is_Not_0();
        }

        bool success = _validateMintSignature(
            signerAddress,
            mintSignature,
            mintHash,
            creatorAddress,
            ipfsHash,
            expiredAt
        );
        require(success, "DistinctiveCollection : Signature is wrong");

        unchecked {
            // Number of tokens cannot overflow 256 bits.
            tokenId = ++collectionInfo.lastTokenId;
        }
        _mint(receiverAddress, tokenId);
        _setTokenIPFSHash(tokenId, ipfsHash);
        _setTokenPolicy(tokenId, policy);

        mintHashHistory[mintHash] = true;

        emit Minted(
            receiverAddress,
            tokenId,
            policy,
            ipfsHash,
            ipfsHash,
            mintHash
        );
    }

    /**
     * @notice Function used in the fulfillorder
     * @dev Creator address is an unused param
     * @dev Only chizu module is available
     * @param creatorAddress This is the address of the creator
     * @param receiverAddress This is the address of the recipient
     * @param ipfsHash ipfshash used for mint
     * @param mintHash It's a hash of the transaction information
     * @return tokenId newly minted tokenId of nft
     */
    function chizuMintFor(
        address creatorAddress,
        address receiverAddress,
        uint256 policy,
        string memory ipfsHash,
        bytes32 mintHash,
        uint256 expiredAt
    ) public override onlyCHIZUModule returns (uint256 tokenId) {
        require(
            !mintHashHistory[mintHash],
            "DistinctiveCollection_Hash_Is_Duplicated"
        );

        if (expiredAt < block.timestamp) {
            revert DistinctiveCollection_Time_Expired();
        }

        if (policy == 0) {
            revert DistinctiveCollection_Policy_Is_Not_0();
        }
        unchecked {
            // Number of tokens cannot overflow 32 bits.
            tokenId = ++collectionInfo.lastTokenId;
        }
        _mint(receiverAddress, tokenId);
        _setTokenIPFSHash(tokenId, ipfsHash);
        _setTokenPolicy(tokenId, policy);

        mintHashHistory[mintHash] = true;

        emit Minted(
            receiverAddress,
            tokenId,
            policy,
            ipfsHash,
            ipfsHash,
            mintHash
        );
    }

    /**
     * @notice Function used by the sender of token in migrate
     * @dev The Contract to send is address(this)
     * @param validateInfo Structure to verify the signature for migrate
     * @param signerInfo Information about signature
     * @param tokenIdArrayFrom Array of sending tokens
     * @param to The account of the receiving user
     * @param salt Valid Random Value for Transaction
     * @return original Information on the tokens to send
     */
    function migrateFrom(
        IMigrateable.ValidateInfo[] memory validateInfo,
        IMigrateable.SignerInfo memory signerInfo,
        uint256[] memory tokenIdArrayFrom,
        address to,
        uint256 salt,
        uint256 expiredAt
    ) public override returns (IMigrateable.TokenData[] memory) {
        if (creator() != owner()) {
            revert DistinctiveCollection_Creator_Is_Not_Owner();
        }
        if (tokenIdArrayFrom.length > MAX_MIGRATE_NUMBER) {
            revert DistinctiveCollection_Over_Than_Limit_Numer();
        }
        if (to == address(0)) {
            revert DistinctiveCollection_Can_Not_Migrate_To_ADDRESS_0();
        }
        if (to == address(this)) {
            revert DistinctiveCollection_Can_Not_Move_To_Same_Collection();
        }
        uint256[] memory slice = _exportMigrateSlice(tokenIdArrayFrom);

        for (uint256 i = 0; i < slice.length; i++) {
            bool success = _validateMigrateSignature(
                validateInfo[i],
                slice[i],
                signerInfo,
                address(this),
                to,
                salt,
                expiredAt
            );
            require(success, "DistinctiveCollection : Signature is wron");
        }

        IMigrateable.TokenData[] memory original = new IMigrateable.TokenData[](
            tokenIdArrayFrom.length
        );

        for (uint256 j = 0; j < tokenIdArrayFrom.length; j++) {
            if (ownerOf(tokenIdArrayFrom[j]) != creator()) {
                revert DistinctiveCollection_Holder_Is_Not_Creator();
            }
            original[j].IPFSHash = getTokenIPFSHash(tokenIdArrayFrom[j]);
            original[j].policy = getPolicyOfToken(tokenIdArrayFrom[j]);
            _burn(tokenIdArrayFrom[j]);
        }
        return original;
    }

    /**
     * @notice Function used by the receiver of token in migrate
     * @dev The Contract to receive is address(this)
     * @param validateInfo Structure to verify the signature for migrate
     * @param signerInfo Information about signature
     * @param tokenIdArrayFrom Array of sending tokens
     * @param from The account of the sender
     * @param salt Valid Random Value for Transaction
     * @return tokenIdArrayTo tokenIds minted in the contract receiving the token
     */
    function migrate(
        IMigrateable.ValidateInfo[] memory validateInfo,
        IMigrateable.SignerInfo memory signerInfo,
        uint256[] memory tokenIdArrayFrom,
        address from,
        uint256 salt,
        uint256 expiredAt
    ) public onlyCreator returns (uint256[] memory) {
        if (expiredAt < block.timestamp) {
            revert DistinctiveCollection_Time_Expired();
        }
        if (!from.supportsInterface(type(IMigrateable).interfaceId)) {
            revert DistinctiveCollection_Not_Support_Interface();
        }

        IMigrateable.TokenData[] memory original = IMigrateable(from)
            .migrateFrom(
                validateInfo,
                signerInfo,
                tokenIdArrayFrom,
                address(this),
                salt,
                expiredAt
            );

        uint256[] memory tokenIdArrayTo = new uint256[](
            tokenIdArrayFrom.length
        );

        for (uint256 i = 0; i < tokenIdArrayFrom.length; i++) {
            unchecked {
                // Number of tokens cannot overflow 32 bits.
                tokenIdArrayTo[i] = collectionInfo.lastTokenId++;
            }
            _mint(msg.sender, tokenIdArrayTo[i]);
            _setTokenIPFSHash(tokenIdArrayTo[i], original[i].IPFSHash);
            _setTokenPolicy(tokenIdArrayTo[i], original[i].policy);
            emit Migrated(
                tokenIdArrayFrom[i],
                original[i].policy,
                original[i].IPFSHash,
                from,
                address(this),
                salt
            );
        }
        return tokenIdArrayTo;
    }

    function getPolicyOfToken(uint256 _tokenId) public view returns (uint256) {
        return tokenPolicy[_tokenId];
    }

    /**
     * @notice Get fee recipients and fees in a single call.
     * @dev The data is the same as when calling getFeeRecipients and getFeeBps separately.
     * @param _tokenId The tokenId of the NFT to get the royalties for.
     * @param _salePrice the salesPrice of the NFT
     * @return recipients An array of addresses to which royalties should be sent.
     * @return fees The array of fees to be sent to each recipient address.
     */
    function getRoyalties(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address payable[] memory recipients, uint256[] memory fees)
    {
        require(
            _exists(_tokenId),
            "DistinctiveCollection: Query for nonexistent token"
        );
        recipients = new address payable[](1);
        recipients[0] = collectionInfo.licensor;

        fees = new uint256[](1);
        if (tokenPolicy[_tokenId] == 20) {
            fees[0] = 0;
        } else {
            fees[0] = (_salePrice * 5) / 100;
        }
    }

    /**
     * @notice Returns the licensor and the amount to be sent for a secondary sale.
     * @param _tokenId The tokenId of the NFT to get the royalty recipient and amount for.
     * @param _salePrice The total price of the sale.
     * @return licensor The royalty recipient address for this sale.
     * @return licensorAmount The total amount that should be sent to the `licensor`.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address licensor, uint256 licensorAmount)
    {
        require(
            _exists(_tokenId),
            "DistinctiveCollection: Query for nonexistent token"
        );
        licensor = address(collectionInfo.licensor);

        if (tokenPolicy[_tokenId] == EXCLUSIVE) {
            licensorAmount = 0;
        } else {
            licensorAmount = (_salePrice * 5) / 100;
        }
    }

    /**
     * @notice Function to check if ipfshash corresponding to tokenId is correct
     * @param tokenId TokenId to check
     * @param IPFSHash corresponding ipfshash
     * @return Boolean value for correctness
     */
    function checkIPFSHashById(uint256 tokenId, string memory IPFSHash)
        external
        view
        returns (bool)
    {
        return
            keccak256(bytes(IPFSHash)) ==
            keccak256(bytes(getTokenIPFSHash(tokenId)));
    }

    /**
     * @param tokenId TokenId to check
     * @return IPFSHash ipfs hash value corresponding to tokenId
     */
    function getTokenIPFSHash(uint256 tokenId)
        public
        view
        returns (string memory IPFSHash)
    {
        require(
            _exists(tokenId),
            "DistinctiveCollection: URI query for nonexistent token"
        );
        IPFSHash = tokenIPFSHash[tokenId];
    }

    /**
     * @notice URI with baseuri and ipfs can be obtained.
     * @param tokenId TokenId to check
     * @return uri URI for tokenId
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory uri)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenIPFS = tokenIPFSHash[tokenId];
        string memory _baseURI = IMetaData(contractFactory).baseURI();

        return string(abi.encodePacked(_baseURI, _tokenIPFS));
    }

    /**
     * @notice The base URI used for all NFTs in this collection.
     * @dev The `tokenIPFSHash` is appended to this to obtain an NFT's `tokenURI`.
     *      e.g. The URI for a token with the `tokenIPFSHash`: "foo" and `baseURI`: "ipfs://" is "ipfs://foo".
     * @return uri The base URI used by this collection.
     */
    function baseURI() public view returns (string memory uri) {
        uri = IMetaData(contractFactory).baseURI();
    }

    /**
     * ==========================
     * Internal Function
     * ==========================
     */

    /**
     * @dev Functions that validate mintsignature
     */
    function _validateMintSignature(
        address signerAddress,
        bytes memory mintSignature,
        bytes32 mintHash,
        address creatorAddress,
        string memory ipfsHash,
        uint256 expiredAt
    ) internal view returns (bool success) {
        if (!INodeRole(core).isNode(signerAddress)) {
            return false;
        }

        bytes32 calculatedHash = keccak256(
            abi.encodePacked(
                uint256(uint160(address(this))),
                uint256(uint160(creatorAddress)),
                ipfsHash,
                uint256(expiredAt)
            )
        );
        bytes32 calculatedSignature = keccak256(
            abi.encodePacked(
                //ethereum signature prefix
                "\x19Ethereum Signed Message:\n32",
                //Orderer
                uint256(calculatedHash)
            )
        );
        address recoveredSigner = calculatedSignature.recover(mintSignature);

        if (calculatedHash != mintHash) {
            return false;
        }

        if (recoveredSigner != signerAddress) {
            return false;
        }
        success = true;
    }

    /**
     * @dev Functions that validate migrateSignature
     * @dev userSignature is signature of receiver
     */
    function _validateMigrateSignature(
        IMigrateable.ValidateInfo memory validateInfo,
        uint256 slice,
        IMigrateable.SignerInfo memory signerInfo,
        address from,
        address to,
        uint256 salt,
        uint256 expiredAt
    ) internal pure returns (bool success) {
        bytes32 calculatedHash = keccak256(
            abi.encodePacked(
                uint256(salt),
                uint256(slice),
                uint256(uint160(from)),
                uint256(uint160(to)),
                uint256(expiredAt)
            )
        );
        bytes32 calculatedOrigin = keccak256(
            abi.encodePacked(
                //ethereum signature prefix
                "\x19Ethereum Signed Message:\n32",
                //Orderer
                uint256(calculatedHash)
            )
        );
        address recoveredNodeSigner = calculatedOrigin.recover(
            validateInfo.nodeSignature
        );

        address recoveredUserSigner = calculatedOrigin.recover(
            validateInfo.userSignature
        );

        if (calculatedHash != validateInfo.finalHash) {
            return false;
        }
        if (recoveredNodeSigner != signerInfo.nodeAddress) {
            return false;
        }

        if (recoveredUserSigner != signerInfo.userAddress) {
            return false;
        }
        success = true;
    }

    function _validateBurnSignature(
        address contractAddress,
        address creator,
        uint256 tokenId,
        uint256 expiredAt,
        address nodeAddress,
        bytes32 burnHash,
        bytes memory burnSignature
    ) internal view returns (bool success, string memory message) {
        if (!INodeRole(core).isNode(nodeAddress)) {
            return (false, "DistinctiveCollection : is not node");
        }
        bytes32 calculatedHash = keccak256(
            abi.encodePacked(
                uint256(uint160(contractAddress)),
                uint256(uint160(creator)),
                uint256(tokenId),
                uint256(expiredAt)
            )
        );
        bytes32 calculatedOrigin = calculatedHash.toEthSignedMessageHash();

        address recoveredSigner = calculatedOrigin.recover(burnSignature);

        if (calculatedHash != burnHash) {
            return (false, "DistinctiveCollection : hash does not match");
        }
        if (recoveredSigner != nodeAddress) {
            return (false, "DistinctiveCollection : signer does not match");
        }
        success = true;
    }

    /**
     * @dev Function that creates slice by pasting tokenId for tokenId verification
     */
    function _exportMigrateSlice(uint256[] memory tokenIdArray)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 tokenIdSlice;
        uint256 count;
        uint256 index;
        uint256[] memory sliceArray = new uint256[](3);
        for (uint256 i = 0; i < tokenIdArray.length; i++) {
            tokenIdSlice = (tokenIdSlice << 32) | tokenIdArray[i];
            if (i == tokenIdArray.length - 1) {
                sliceArray[index] = tokenIdSlice;
                break;
            }
            ++count;
            if (count == 8) {
                count = 0;
                sliceArray[index] = tokenIdSlice;
                tokenIdSlice = 0;
                index++;
            }
        }
        return sliceArray;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        if (
            interfaceId == type(IRoyaltyInfo).interfaceId ||
            interfaceId == type(IGetRoyalties).interfaceId ||
            interfaceId == type(ILazyMintable).interfaceId ||
            interfaceId == type(IMigrateable).interfaceId ||
            interfaceId == type(IDistinctiveCollection).interfaceId
        ) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}