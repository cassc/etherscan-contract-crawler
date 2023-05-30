//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////************@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////*******************@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///***********************@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///**************************@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///**********/**************/*@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////****/****************//@@@@@
// @@@*********@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(///////////*****************//@@@@@@
// @@@**************//////@@@@@@@@@@@@@@@@@@@((////////////***************//@@@@@@@
// @@@*********************////@@@@@@@@@@@@@((///////////////************//@@@@@@@@
// @@@@//**************//***//////@@@@@@@@@@(///////////////////*******//@@@@@@@@@@
// @@@@@/*****************////////((@@@@@@@((///((////////////////***//@@@@@@@@@@@@
// @@@@@@//*************////////////((@@@@@((//((////////////////////@@@@@@@@@@@@@@
// @@@@@@@//**********///////////////((@@@@((((//////////////////@@@@@@@@@@@@@@@@@@
// @@@@@@@@///******//////////////((//((@@@(((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@//*///////////////////(//((@(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@////////////////////(((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@/((((/////////////((((/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@((((((((@@@(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@###(((((((((((((((((((((((((###@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@####################################@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@#############################################@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import './IVariety.sol';
import '../NFT/ERC721Helpers/ERC721Full.sol';

/// @title Variety Contract
/// @author Simon Fremaux (@dievardump)
contract Variety is IVariety, ERC721Full {
    event SeedChangeRequest(uint256 indexed tokenId, address indexed operator);

    // seedlings Sower
    address public sower;

    // last tokenId
    uint256 public lastTokenId;

    // each token seed
    mapping(uint256 => bytes32) internal tokenSeed;

    // names
    mapping(uint256 => string) public names;

    // useNames
    mapping(bytes32 => bool) public usedNames;

    // tokenIds with a request for seeds change
    mapping(uint256 => bool) internal seedChangeRequests;

    modifier onlySower() {
        require(msg.sender == sower, 'Not Sower.');
        _;
    }

    /// @notice constructor
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param sower_ Sower contract
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address sower_
    ) ERC721Ownable(name_, symbol_, contractURI_, openseaProxyRegistry_) {
        sower = sower_;
    }

    /// @notice mint `seeds.length` token(s) to `to` using `seeds`
    /// @param to token recipient
    /// @param seeds each token seed
    function plant(address to, bytes32[] memory seeds)
        external
        virtual
        override
        onlySower
        returns (uint256)
    {
        uint256 tokenId = lastTokenId;
        for (uint256 i; i < seeds.length; i++) {
            tokenId++;
            _safeMint(to, tokenId);
            tokenSeed[tokenId] = seeds[i];
        }
        lastTokenId = tokenId;

        return tokenId;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Full, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice tokenURI override that returns a data:json application
    /// @inheritdoc	ERC721
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        return _render(tokenId, tokenSeed[tokenId]);
    }

    /// @notice ERC2981 support - 4% royalties sent to Sower
    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = sower;
        royaltyAmount = (value * 400) / 10000;
    }

    /// @inheritdoc IVariety
    function getTokenSeed(uint256 tokenId)
        external
        view
        override
        returns (bytes32)
    {
        require(_exists(tokenId), 'TokenSeed query for nonexistent token');
        return tokenSeed[tokenId];
    }

    /// @inheritdoc IVariety
    function requestSeedChange(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, 'Not token owner.');
        seedChangeRequests[tokenId] = true;
        emit SeedChangeRequest(tokenId, msg.sender);
    }

    /// @inheritdoc IVariety
    function changeSeedAfterRequest(uint256 tokenId)
        external
        override
        onlySower
    {
        require(seedChangeRequests[tokenId] == true, 'No request for token.');
        seedChangeRequests[tokenId] = false;
        tokenSeed[tokenId] = keccak256(
            abi.encode(
                tokenSeed[tokenId],
                block.timestamp,
                block.difficulty,
                blockhash(block.number - 1)
            )
        );
    }

    /// @notice Function allowing an owner to set the seedling name
    ///         User needs to be extra careful. Some characters might completly break the token.
    ///         Since the metadata are generated in the contract.
    ///         if this ever happens, you can simply reset the name to nothing or for something else
    /// @dev sender must be tokenId owner
    /// @param tokenId the token to name
    /// @param seedlingName the name
    function setName(uint256 tokenId, string memory seedlingName)
        external
        virtual
    {
        require(ownerOf(tokenId) == msg.sender, 'Not token owner.');

        bytes32 byteName = keccak256(abi.encodePacked(seedlingName));

        // if the name is not empty, verify it is not used
        if (bytes(seedlingName).length > 0) {
            require(usedNames[byteName] == false, 'Name already used');
            usedNames[byteName] = true;
        }

        // if it already has a name, mark all name as unused
        string memory oldName = names[tokenId];
        if (bytes(oldName).length > 0) {
            byteName = keccak256(abi.encodePacked(oldName));
            usedNames[byteName] = false;
        }

        names[tokenId] = seedlingName;
    }

    /// @notice function to get a token name
    /// @dev token must exist
    /// @param tokenId the token to get the name of
    /// @return the token name
    function getName(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), 'Unknown token');
        return _getName(tokenId);
    }

    /// @dev internal function to get the name. Should be overrode by actual Variety contract
    /// @param tokenId the token to get the name of
    /// @return the token name
    function _getName(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        return bytes(names[tokenId]).length > 0 ? names[tokenId] : 'Variety';
    }

    /// @notice Function allowing to check the rendering for a given seed
    ///         This allows to know what a seed would render without minting
    /// @param seed the seed to render
    /// @return the json
    function renderSeed(bytes32 seed) public view returns (string memory) {
        return _render(0, seed);
    }

    /// @dev Rendering function; should be overrode by the actual seedling contract
    /// @param tokenId the tokenId
    /// @param seed the seed
    /// @return the json
    function _render(uint256 tokenId, bytes32 seed)
        internal
        view
        virtual
        returns (string memory)
    {
        seed;
        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,{"name":"',
                    _getName(tokenId),
                    '"}'
                )
            );
    }
}