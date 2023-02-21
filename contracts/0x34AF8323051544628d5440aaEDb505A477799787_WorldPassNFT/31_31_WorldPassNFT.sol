// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IWorldPassNFT.sol";
import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "@thirdweb-dev/contracts/extension/Permissions.sol";
import "@thirdweb-dev/contracts/extension/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WorldPassNFT is IWorldPassNFT, ERC721Base, Permissions, DefaultOperatorFilterer {
    using HouseUtil for House;

    bytes32 public constant MINTER_ROLE =
        keccak256("MINTER_ROLE");

    bytes32 public constant ATTRIBUTE_ADMIN_ROLE =
        keccak256("ATTRIBUTE_ADMIN_ROLE");

    string private imageDirURI = "";
    uint256 private maxSupply = 0;
    uint256 private maxHouseSupply = 0;
    mapping(uint256 => TokenData) private tokenDataMap;

    mapping(uint256 => uint256) private houseSupplies;

    /**
     * The token doesn't exist
     */
    error TokenDoesntExist();

    modifier tokenExists(uint256 _tokenId) {
        if (!_exists(_tokenId)) revert TokenDoesntExist();
        _;
    }

    /**
     *  @notice          Constructor for WorldPass contract.
     *
     *  @param _name             Name of contract.
     *  @param _symbol           Token Symbol.
     *  @param _royaltyRecipient Address
     *  @param _royaltyBps       Royalty Bps.
     *  @param _imageDirURI      URI to root dir for WP images. Full image URI is generated in @see _getHouseImageURI()
     *  @param _maxSupply        Max Supply of token (0 => unlimitted; anything else is the exact supply).
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _imageDirURI,
        string memory _contractURI,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint256 _maxSupply,
        uint256 _maxHouseSupply
    ) ERC721Base(_name, _symbol, _royaltyRecipient, _royaltyBps) {
        _setupContractURI(_contractURI);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(ATTRIBUTE_ADMIN_ROLE, msg.sender);
        imageDirURI = _imageDirURI;
        maxSupply = _maxSupply;
        maxHouseSupply = _maxHouseSupply;
    }

    function setTokenHouse(uint256 _tokenId, House _house) public override tokenExists(_tokenId) onlyRole(ATTRIBUTE_ADMIN_ROLE) {
        TokenData memory dataItem = tokenDataMap[_tokenId];

        // Guarantees it will only allow to be set once
        require(!dataItem.__exists, "Can't change House attribute once it's set!");

        require(houseSupplies[uint256(_house)] < maxHouseSupply, "Can't mint more than maxHouseSupply");        

        tokenDataMap[_tokenId] = _initTokenData(_tokenId, _house);
        ++houseSupplies[uint256(_house)];
    }

    function getTokenHouse(uint256 _tokenId) public view override tokenExists(_tokenId) returns (House){
        TokenData memory dataItem = tokenDataMap[_tokenId];

        // default of non-set dataItem's house is going to be first enum val -> Scarred
        return dataItem.house;
    }

    /**
     * A new mint method to include a house param.
     */
    function mintWithHouseTo(address _to, House _house) public virtual override {
        require(_canMint(), "Not authorized to mint.");

        uint256 tokenId = nextTokenIdToMint();

        _safeMint(_to, 1, "");
        setTokenHouse(tokenId, _house);
    }

    /**
     * A new batch mint method to include a house param.
     */
    function batchMintWithHouseTo(
        address _to,
        uint256 _quantity,
        House _house
    ) public virtual override {
        require(_canMint(), "Not authorized to mint.");

        uint256 tokenId = nextTokenIdToMint();

        _safeMint(_to, _quantity, "");

        for (uint256 i = tokenId; i < tokenId + _quantity; i++) {
            setTokenHouse(i, _house);
        }
    }

    /**
     *  @notice         Returns the metadata of an NFT.
     *
     *  @param _tokenId The tokenId of an NFT.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        tokenExists(_tokenId)
        returns (string memory)
    {
        TokenData memory tokenData = tokenDataMap[_tokenId];

        string memory houseAttribute = "";

        if (tokenData.house == House.Scarred) {
            houseAttribute = _getBoolTraitAttributeJson(
                "Scarred",
                true
            );
        } else {
            houseAttribute = _getStringTraitAttributeJson(
                "House",
                tokenData.house.toString()
            );
        }

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name": "',
                        '#', Strings.toString(_tokenId),
                        '", "image": "',
                        _getHouseMediaURI(_tokenId),
                        '.png", "animation_url": "', 
                        _getHouseMediaURI(_tokenId),
                        '.mp4", "attributes": [',
                        houseAttribute,
                        "]}"
                    )
                )
            )
        );
    }

    /**
     *  @notice         Returns the remaining supply for the given house.
     *
     *  @param _house The house to query remaining supply of.
     */
    function getRemainingHouseSupply(House _house) external view returns (uint256) {
        return maxHouseSupply - houseSupplies[uint256(_house)];
    }

    function setImageDirURI(string calldata _imageDirURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        imageDirURI = _imageDirURI;
    }

    /**
     * Override to limit roles.
     */
    function _canMint() internal view virtual override returns (bool) {
        return hasRole(MINTER_ROLE, msg.sender);
    }

    function _afterTokenTransfers(
        address from,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        // in the case of minting
        if (from == address(0)) {
            require(startTokenId + quantity <= maxSupply, "Can't go over max supply!");
        }
    }

    function _initTokenData(uint256 _tokenId, House _house) internal view returns (TokenData memory) {
        require(!tokenDataMap[_tokenId].__exists, "TokenData already exists!");

        TokenData memory result = TokenData({
            house: _house,
            __exists: true
        });

        return result;
    }

    /**
     *  @notice         Returns the WP image of a specific house.
     *
     *  @param _tokenId The tokenId of an NFT.
     */
    function _getHouseMediaURI(uint256 _tokenId) internal view returns (string memory) {
        TokenData memory tokenData = tokenDataMap[_tokenId];

        return string(abi.encodePacked(imageDirURI, Strings.toString(uint(tokenData.house))));
    }

    function _getStringTraitAttributeJson(string memory _name, string memory _value) pure internal returns (string memory) {
        return string(abi.encodePacked(
            '{"trait_type": "', _name, '", "value": "', _value, '"}'
        ));
    }

    function _getBoolTraitAttributeJson(string memory _name, bool _value) pure internal returns (string memory) {
        return string(abi.encodePacked(
            '{"trait_type": "', _name, '", "value": ', _value ? 'true': 'false', '}'
        ));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}