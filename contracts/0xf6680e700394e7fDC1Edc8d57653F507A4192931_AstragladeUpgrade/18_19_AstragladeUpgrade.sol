//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import '../ERC721Ownable.sol';
import '../ERC2981/IERC2981Royalties.sol';
import './IOldMetaHolder.sol';

/// @title AstragladeUpgrade
/// @author Simon Fremaux (@dievardump)
contract AstragladeUpgrade is
    IERC2981Royalties,
    ERC721Ownable,
    IERC721Receiver
{
    using ECDSA for bytes32;
    using Strings for uint256;

    // emitted when an Astraglade has been upgrade
    event AstragladeUpgraded(address indexed operator, uint256 indexed tokenId);

    // emitted when a token owner asks for a metadata update (image or signature)
    // because of rendering error
    event RequestUpdate(address indexed operator, uint256 indexed tokenId);

    struct MintingOrder {
        address to;
        uint256 expiration;
        uint256 seed;
        string signature;
        string imageHash;
    }

    struct AstragladeMeta {
        uint256 seed;
        string signature;
        string imageHash;
    }

    // start at the old contract last token Id minted
    uint256 public lastTokenId = 84;

    // signer that signs minting orders
    address public mintSigner;

    // how long before an order expires
    uint256 public expiration;

    // old astraglade contract to allow upgrade to new token
    address public oldAstragladeContract;

    // contract that holds metadata of previous contract Astraglades
    address public oldMetaHolder;

    // contract operator next to the owner
    address public contractOperator =
        address(0xD1edDfcc4596CC8bD0bd7495beaB9B979fc50336);

    // max supply
    uint256 constant MAX_SUPPLY = 5555;

    // price
    uint256 constant PRICE = 0.0888 ether;

    // project base render URI
    string private _baseRenderURI;

    // project description
    string internal _description;

    // list of Astraglades
    mapping(uint256 => AstragladeMeta) internal _astraglades;

    // saves if a minting order was already used or not
    mapping(bytes32 => uint256) public messageToTokenId;

    // request updates
    mapping(uint256 => bool) public requestUpdates;

    // remaining giveaways
    uint256 public remainingGiveaways = 100;

    // user giveaways
    mapping(address => uint8) public giveaways;

    // Petri already redeemed
    mapping(uint256 => bool) public petriRedeemed;

    address public artBlocks;

    address[3] public feeRecipients = [
        0xe4657aF058E3f844919c3ee713DF09c3F2949447,
        0xb275E5aa8011eA32506a91449B190213224aEc1e,
        0xdAC81C3642b520584eD0E743729F238D1c350E62
    ];

    modifier onlyOperator() {
        require(isOperator(msg.sender), 'Not operator.');
        _;
    }

    function isOperator(address operator) public view returns (bool) {
        return owner() == operator || contractOperator == operator;
    }

    /// @notice constructor
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param mintSigner_ Address of the wallet used to sign minting orders
    /// @param owner_ Address to whom transfer ownership (can be address(0), then owner is deployer)
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address mintSigner_,
        address owner_,
        address oldAstragladeContract_,
        address oldMetaHolder_,
        address artBlocks_
    )
        ERC721Ownable(
            name_,
            symbol_,
            contractURI_,
            openseaProxyRegistry_,
            owner_
        )
    {
        mintSigner = mintSigner_;
        oldAstragladeContract = oldAstragladeContract_;
        oldMetaHolder = oldMetaHolder_;
        artBlocks = artBlocks_;
    }

    /// @notice Mint one token using a minting order
    /// @dev mintingSignature must be a signature that matches `mintSigner` for `mintingOrder`
    /// @param mintingOrder the minting order
    /// @param mintingSignature signature for the mintingOrder
    /// @param petriId petri id to redeem if owner and not already redeemed the free AG
    function mint(
        MintingOrder memory mintingOrder,
        bytes memory mintingSignature,
        uint256 petriId
    ) external payable {
        bytes32 message = hashMintingOrder(mintingOrder)
            .toEthSignedMessageHash();

        address sender = msg.sender;

        require(
            message.recover(mintingSignature) == mintSigner,
            'Wrong minting order signature.'
        );

        require(
            mintingOrder.expiration >= block.timestamp,
            'Minting order expired.'
        );

        require(
            mintingOrder.to == sender,
            'Minting order for another address.'
        );

        require(mintingOrder.seed != 0, 'Seed can not be 0');

        require(messageToTokenId[message] == 0, 'Token already minted.');

        uint256 tokenId = lastTokenId + 1;

        require(tokenId <= MAX_SUPPLY, 'Max supply already reached.');

        uint256 mintingCost = PRICE;

        // For Each Petri (https://artblocks.io/project/67/) created by Fabin on artblocks.io
        // the owner can claim a free Astraglade
        // After a Petri was used, it CAN NOT be used again to claim another Astraglade
        if (petriId >= 67000000 && petriId < 67000200) {
            require(
                // petri was not redeemed already
                petriRedeemed[petriId] == false &&
                    // msg.sender is Petri owner
                    ERC721(artBlocks).ownerOf(petriId) == sender,
                'Petri already redeemed or not owner'
            );

            petriRedeemed[petriId] = true;
            mintingCost = 0;
        } else if (giveaways[sender] > 0) {
            // if the user has some free mints
            giveaways[sender]--;
            mintingCost = 0;
        }

        require(
            msg.value == mintingCost || isOperator(sender),
            'Incorrect value.'
        );

        lastTokenId = tokenId;

        messageToTokenId[message] = tokenId;

        _astraglades[tokenId] = AstragladeMeta({
            seed: mintingOrder.seed,
            signature: mintingOrder.signature,
            imageHash: mintingOrder.imageHash
        });

        _safeMint(mintingOrder.to, tokenId, '');
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            ERC721Enumerable.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981Royalties).interfaceId;
    }

    /// @notice Helper to get the price
    /// @return the price to mint
    function getPrice() external pure returns (uint256) {
        return PRICE;
    }

    /// @notice tokenURI override that returns a data:json application
    /// @inheritdoc	ERC721
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        AstragladeMeta memory astraglade = getAstraglade(tokenId);

        string memory astraType;
        if (tokenId <= 10) {
            astraType = 'Universa';
        } else if (tokenId <= 100) {
            astraType = 'Galactica';
        } else if (tokenId <= 1000) {
            astraType = 'Nebula';
        } else if (tokenId <= 2500) {
            astraType = 'Meteora';
        } else if (tokenId <= 5554) {
            astraType = 'Solaris';
        } else {
            astraType = 'Quanta';
        }

        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,{"name":"Astraglade - ',
                    tokenId.toString(),
                    ' - ',
                    astraType,
                    '","license":"CC BY-SA 4.0","description":"',
                    getDescription(),
                    '","created_by":"Fabin Rasheed","twitter":"@astraglade","image":"ipfs://ipfs/',
                    astraglade.imageHash,
                    '","seed":"',
                    astraglade.seed.toString(),
                    '","signature":"',
                    astraglade.signature,
                    '","animation_url":"',
                    renderTokenURI(tokenId),
                    '"}'
                )
            );
    }

    /// @notice function that returns a string that can be used to render the current token
    /// @param tokenId tokenId
    /// @return the URI to render token
    function renderTokenURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        AstragladeMeta memory astraglade = getAstraglade(tokenId);
        return
            string(
                abi.encodePacked(
                    getBaseRenderURI(),
                    '?seed=',
                    astraglade.seed.toString(),
                    '&signature=',
                    astraglade.signature
                )
            );
    }

    /// @notice Returns Metadata for Astraglade id
    /// @param tokenId the tokenId we want metadata for
    function getAstraglade(uint256 tokenId)
        public
        view
        returns (AstragladeMeta memory astraglade)
    {
        require(_exists(tokenId), 'Astraglade: nonexistent token');

        // if the metadata are in this contract
        if (_astraglades[tokenId].seed != 0) {
            astraglade = _astraglades[tokenId];
        } else {
            // or in the old one
            (
                uint256 seed,
                string memory signature,
                string memory imageHash
            ) = IOldMetaHolder(oldMetaHolder).get(tokenId);
            astraglade.seed = seed;
            astraglade.signature = signature;
            astraglade.imageHash = imageHash;
        }
    }

    /// @notice helper to get the description
    function getDescription() public view returns (string memory) {
        if (bytes(_description).length == 0) {
            return
                'Astraglade is an interactive, generative, 3D collectible project. Astraglades are collected through a unique social collection mechanism. Each version of Astraglade can be signed with a signature which will remain in the artwork forever.';
        }

        return _description;
    }

    /// @notice helper to set the description
    /// @param newDescription the new description
    function setDescription(string memory newDescription)
        external
        onlyOperator
    {
        _description = newDescription;
    }

    /// @notice helper to get the base expiration time
    function getExpiration() public view returns (uint256) {
        if (expiration == 0) {
            return 15 * 60;
        }

        return expiration;
    }

    /// @notice helper to set the expiration
    /// @param newExpiration the new expiration
    function setExpiration(uint256 newExpiration) external onlyOperator {
        expiration = newExpiration;
    }

    /// @notice helper to get the baseRenderURI
    function getBaseRenderURI() public view returns (string memory) {
        if (bytes(_baseRenderURI).length == 0) {
            return 'ipfs://ipfs/QmP85DSrtLAxSBnct9iUr7qNca43F3E4vuG6Jv5aoTh9w7';
        }

        return _baseRenderURI;
    }

    /// @notice helper to set the baseRenderURI
    /// @param newRenderURI the new renderURI
    function setBaseRenderURI(string memory newRenderURI)
        external
        onlyOperator
    {
        _baseRenderURI = newRenderURI;
    }

    /// @notice Helper to do giveaways - there can only be `remainingGiveaways` giveaways given all together
    /// @param winner the giveaway winner
    /// @param count how many we giveaway to recipient
    function giveaway(address winner, uint8 count) external onlyOperator {
        require(remainingGiveaways >= count, 'Giveaway limit reached');
        remainingGiveaways -= count;
        giveaways[winner] += count;
    }

    /// @dev Receive, for royalties
    receive() external payable {}

    /// @dev Owner withdraw balance function
    function withdraw() external onlyOperator {
        address[3] memory feeRecipients_ = feeRecipients;

        uint256 balance_ = address(this).balance;
        payable(address(feeRecipients_[0])).transfer((balance_ * 30) / 100);
        payable(address(feeRecipients_[1])).transfer((balance_ * 35) / 100);
        payable(address(feeRecipients_[2])).transfer(address(this).balance);
    }

    /// @notice helper to set the fee recipient at `index`
    /// @param newFeeRecipient the new address
    /// @param index the index to edit
    function setFeeRecipient(address newFeeRecipient, uint8 index)
        external
        onlyOperator
    {
        require(index < feeRecipients.length, 'Index too high.');
        require(newFeeRecipient != address(0), 'Invalid address.');

        feeRecipients[index] = newFeeRecipient;
    }

    /// @notice 10% royalties going to this contract
    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(this);
        royaltyAmount = (value * 1000) / 10000;
    }

    /// @notice Hash the Minting Order so it can be signed by the signer
    /// @param mintingOrder the minting order
    /// @return the hash to sign
    function hashMintingOrder(MintingOrder memory mintingOrder)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(mintingOrder));
    }

    /// @notice Helper for the owner to change current minting signer
    /// @dev needs to be owner
    /// @param mintSigner_ new signer
    function setMintingSigner(address mintSigner_) external onlyOperator {
        require(mintSigner_ != address(0), 'Invalid Signer address.');
        mintSigner = mintSigner_;
    }

    /// @notice Helper for an operator to change the current operator address
    /// @param newOperator the new operator
    function setContractOperator(address newOperator) external onlyOperator {
        contractOperator = newOperator;
    }

    /// @notice Helper for the owner to change the oldMetaHolder
    /// @dev needs to be owner
    /// @param oldMetaHolder_ new oldMetaHolder address
    function setOldMetaHolder(address oldMetaHolder_) external onlyOperator {
        require(oldMetaHolder_ != address(0), 'Invalid Contract address.');
        oldMetaHolder = oldMetaHolder_;
    }

    /// @notice Helpers that returns the MintingOrder plus the message to sign
    /// @param to the address of the creator
    /// @param seed the seed
    /// @param signature the signature
    /// @param imageHash image hash
    /// @return mintingOrder and message to hash
    function createMintingOrder(
        address to,
        uint256 seed,
        string memory signature,
        string memory imageHash
    )
        external
        view
        returns (MintingOrder memory mintingOrder, bytes32 message)
    {
        mintingOrder = MintingOrder({
            to: to,
            expiration: block.timestamp + getExpiration(),
            seed: seed,
            signature: signature,
            imageHash: imageHash
        });

        message = hashMintingOrder(mintingOrder);
    }

    /// @notice returns a tokenId from an mintingOrder, used to know if already minted
    /// @param mintingOrder the minting order to check
    /// @return an integer. 0 if not minted, else the tokenId
    function tokenIdFromOrder(MintingOrder memory mintingOrder)
        external
        view
        returns (uint256)
    {
        bytes32 message = hashMintingOrder(mintingOrder)
            .toEthSignedMessageHash();
        return messageToTokenId[message];
    }

    /// @notice Allows an owner to request a metadata update.
    ///         Because Astraglade are generated from a backend it can happen that a bug
    ///         blocks the generation of the image OR that a signature with special characters stops the
    ///         token from working.
    ///         This method allows a user to ask for regeneration of the image / signature update
    ///         A contract operator can then update imageHash and / or signature
    /// @param tokenId the tokenId to update
    function requestMetaUpdate(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, 'Not token owner.');
        requestUpdates[tokenId] = true;
        emit RequestUpdate(msg.sender, tokenId);
    }

    /// @notice Allows an operator of this contract to update a tokenId metadata (signature or image hash)
    ///         after it was requested by its owner.
    ///         This is only used in the case the generation of the Preview image did fail
    ///         in some way or if the signature has special characters that stops the token from working
    /// @param tokenId the tokenId to update
    /// @param newImageHash the new imageHash (can be empty)
    /// @param newSignature the new signature (can be empty)
    function updateMeta(
        uint256 tokenId,
        string memory newImageHash,
        string memory newSignature
    ) external onlyOperator {
        require(
            requestUpdates[tokenId] == true,
            'No update request for token.'
        );
        requestUpdates[tokenId] = false;

        // get the current Astraglade data
        // for ids 1-82 it can come from oldMetaHolder
        AstragladeMeta memory astraglade = getAstraglade(tokenId);
        if (bytes(newImageHash).length > 0) {
            astraglade.imageHash = newImageHash;
        }

        if (bytes(newSignature).length > 0) {
            astraglade.signature = newSignature;
        }

        // save the new state
        _astraglades[tokenId] = astraglade;
    }

    /// @notice function used to allow upgrade of old contract Astraglade to this one.
    /// @inheritdoc	IERC721Receiver
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        require(msg.sender == oldAstragladeContract, 'Only old Astraglades.');
        // mint tokenId to from
        _mint(from, tokenId);

        // burn old tokenId
        ERC721Burnable(msg.sender).burn(tokenId);

        emit AstragladeUpgraded(from, tokenId);

        return 0x150b7a02;
    }
}