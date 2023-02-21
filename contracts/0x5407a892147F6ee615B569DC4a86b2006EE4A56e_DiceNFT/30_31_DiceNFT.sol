// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDiceNFT.sol";
import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "@thirdweb-dev/contracts/extension/Permissions.sol";
import "@thirdweb-dev/contracts/extension/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DiceNFT is IDiceNFT, ERC721Base, Permissions, DefaultOperatorFilterer {
    using MaterialUtil for Material;
    using DiceTypeUtil for DieType;
    using ElementalTypeUtil for ElementalType;
    using Strings for uint256;
    using Strings for uint8;

    bytes32 public constant BOOST_ADMIN_ROLE = keccak256("BOOST_ADMIN_ROLE");
    bytes32 public constant BOOST_USER_ROLE = keccak256("BOOST_USER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public maxTotalSupply;
    uint256 public defaultBoostCount;

    string public imageDirURI;

    mapping(uint256 => uint256) private _boosts;

    mapping(uint256 => DiceMetadata) private _oldTokenIdToMetadata;

    mapping(uint256 => uint256) private _newTokenIdToOldTokenId;

    mapping(uint256 => bool) private _oldTokenIdBurned;

    modifier tokenExists(uint256 _tokenId) {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _imageDirURI,
        string memory _contractURI,
        uint256 _defaultBoostCount,
        uint256 _maxSupply,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC721Base(_name, _symbol, _royaltyRecipient, _royaltyBps) {
        _setupContractURI(_contractURI);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BOOST_USER_ROLE, msg.sender);
        _setupRole(BOOST_ADMIN_ROLE, msg.sender);
        maxTotalSupply = _maxSupply;
        imageDirURI = _imageDirURI;
        defaultBoostCount = _defaultBoostCount;
    }

    function setOriginalMetadata(
        DiceMetadata[] calldata originalMetadata,
        uint128 _startIndex,
        uint128 _endIndex
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _startIndex <= _endIndex,
            "Start index should be less than or equal to end index"
        );
        uint128 numberOfItems = _endIndex - _startIndex;
        require(
            originalMetadata.length == numberOfItems,
            "Metadata length does not match index range"
        );

        for (uint256 i = 0; i < numberOfItems; ) {
            _oldTokenIdToMetadata[_startIndex + i] = originalMetadata[i];

            unchecked {
                ++i;
            }
        }
    }

    function resetBoosts(uint256 _newDefaultBoostCount)
        public
        onlyRole(BOOST_ADMIN_ROLE)
    {
        defaultBoostCount = _newDefaultBoostCount;
        for (uint256 i = 0; i < _totalMinted(); i++) {
            _boosts[i] = defaultBoostCount;
        }
    }

    function useBoost(uint256 tokenId, uint256 count)
        public
        tokenExists(tokenId)
        onlyRole(BOOST_USER_ROLE)
    {
        uint256 totalBoosts = _boosts[tokenId];
        require(
            totalBoosts >= count,
            "Requested boost count exceeds the total"
        );

        _boosts[tokenId] = totalBoosts - count;

        emit BoostUpdated(tokenId, _boosts[tokenId]);
    }

    function setBoostCount(uint256 tokenId, uint16 amount)
        public
        tokenExists(tokenId)
        onlyRole(BOOST_ADMIN_ROLE)
    {
        _boosts[tokenId] = amount;

        emit BoostUpdated(tokenId, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            Minting logic
    //////////////////////////////////////////////////////////////*/

    function mintTo(address _to, string memory _tokenURI)
        public
        virtual
        override
    {
        revert("Not allowed");
    }

    function batchMintTo(
        address _to,
        uint256 _quantity,
        string memory _baseURI,
        bytes memory _data
    ) public virtual override {
        revert("Not allowed");
    }

    /**
     *  @notice          Lets an authorized address mint an NFT to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to          The recipient of the NFT to mint.
     *  @param _oldTokenId  Old dice token Id
     */
    function mint(address _to, uint256 _oldTokenId) public virtual {
        require(_canMint(), "Not authorized to mint.");
        require(
            !_oldTokenIdBurned[_oldTokenId],
            "Already claimed old token id"
        );

        uint256 newTokenId = nextTokenIdToMint();
        _safeMint(_to, 1, "");

        _newTokenIdToOldTokenId[newTokenId] = _oldTokenId;
        _boosts[newTokenId] = defaultBoostCount;
        _oldTokenIdBurned[_oldTokenId] = true;
    }

    /**
     *  @notice          Lets an authorized address mint multiple NFTs at once to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to          The recipient of the NFT to mint.
     *  @param _oldTokenIds  Old dice token Ids
     */
    function batchMint(address _to, uint256[] calldata _oldTokenIds)
        public
        virtual
    {
        require(_canMint(), "Not authorized to mint.");

        uint256 quantity = _oldTokenIds.length;
        uint256 newTokenId = nextTokenIdToMint();
        _safeMint(_to, quantity, "");

        uint256 oldTokenIndex = 0;
        for (uint256 i = newTokenId; i < newTokenId + quantity; ++i) {
            require(
                !_oldTokenIdBurned[_oldTokenIds[oldTokenIndex]],
                "Already claimed old token id"
            );

            _newTokenIdToOldTokenId[i] = _oldTokenIds[oldTokenIndex];
            _boosts[i] = defaultBoostCount;
            _oldTokenIdBurned[_oldTokenIds[oldTokenIndex]] = true;
            oldTokenIndex++;
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
        DiceMetadata memory _diceMetadata = _oldTokenIdToMetadata[
            _newTokenIdToOldTokenId[_tokenId]
        ];

        string memory attributes;

        // All dice
        // Dice 1
        if (_diceMetadata.amount >= 1) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    '{"trait_type":"dice ',
                    "1",
                    ' type","value":"',
                    DiceBitmapUtil.getDiceType(_diceMetadata.bitmap, 0).toString(),
                    '"},{"trait_type":"dice ',
                    "1",
                    ' material","value":"',
                    DiceBitmapUtil.getDiceMaterial(_diceMetadata.bitmap, 0).toString(),
                    '"},'
                )
            );
        }
        // Dice 2
        if (_diceMetadata.amount >= 2) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    '{"trait_type":"dice ',
                    "2",
                    ' type","value":"',
                    DiceBitmapUtil.getDiceType(_diceMetadata.bitmap, 1).toString(),
                    '"},{"trait_type":"dice ',
                    "2",
                    ' material","value":"',
                    DiceBitmapUtil.getDiceMaterial(_diceMetadata.bitmap, 1).toString(),
                    '"},'
                )
            );
        }
        // Dice 3
        if (_diceMetadata.amount >= 3) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    '{"trait_type":"dice ',
                    "3",
                    ' type","value":"',
                    DiceBitmapUtil.getDiceType(_diceMetadata.bitmap, 2).toString(),
                    '"},{"trait_type":"dice ',
                    "3",
                    ' material","value":"',
                    DiceBitmapUtil.getDiceMaterial(_diceMetadata.bitmap, 2).toString(),
                    '"},'
                )
            );
        }
        // Dice 4
        if (_diceMetadata.amount >= 4) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    '{"trait_type":"dice ',
                    "4",
                    ' type","value":"',
                    DiceBitmapUtil.getDiceType(_diceMetadata.bitmap, 3).toString(),
                    '"},{"trait_type":"dice ',
                    "4",
                    ' material","value":"',
                    DiceBitmapUtil.getDiceMaterial(_diceMetadata.bitmap, 3).toString(),
                    '"},'
                )
            );
        }
        // Dice 5
        if (_diceMetadata.amount >= 5) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    '{"trait_type":"dice ',
                    "5",
                    ' type","value":"',
                    DiceBitmapUtil.getDiceType(_diceMetadata.bitmap, 4).toString(),
                    '"},{"trait_type":"dice ',
                    "5",
                    ' material","value":"',
                    DiceBitmapUtil.getDiceMaterial(_diceMetadata.bitmap, 4).toString(),
                    '"},'
                )
            );
        }
        // Dice 6
        if (_diceMetadata.amount >= 6) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    '{"trait_type":"dice ',
                    "6",
                    ' type","value":"',
                    DiceBitmapUtil.getDiceType(_diceMetadata.bitmap, 5).toString(),
                    '"},{"trait_type":"dice ',
                    "6",
                    ' material","value":"',
                    DiceBitmapUtil.getDiceMaterial(_diceMetadata.bitmap, 5).toString(),
                    '"},'
                )
            );
        }
        // Dice 7
        if (_diceMetadata.amount >= 7) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    '{"trait_type":"dice ',
                    "7",
                    ' type","value":"',
                    DiceBitmapUtil.getDiceType(_diceMetadata.bitmap, 6).toString(),
                    '"},{"trait_type":"dice ',
                    "7",
                    ' material","value":"',
                    DiceBitmapUtil.getDiceMaterial(_diceMetadata.bitmap, 6).toString(),
                    '"},'
                )
            );
        }

        //Add power and Boosts attributes
        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type":"Power","value":',
                _diceMetadata.power.toString(),
                '},',
                '{"trait_type":"Boosts","value":',
                _boosts[_tokenId].toString(),
                '},',
                '{"trait_type":"Element Type","value":"',
                DiceBitmapUtil.getElementType(_diceMetadata.bitmap).toString(),
                '"}'
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
                            '","image":"',
                            imageDirURI,
                            "/",
                            _newTokenIdToOldTokenId[_tokenId].toString(),
                            '.jpg","animation_url":"',
                            imageDirURI,
                            "/",
                            _newTokenIdToOldTokenId[_tokenId].toString(),
                            '.mp4","attributes":[',
                            attributes,
                            "]}"
                        )
                    )
                )
            );
    }

    function getDiceBoosts(uint256 _tokenId)
        public
        view
        tokenExists(_tokenId)
        returns (uint256)
    {
        return _boosts[_tokenId];
    }

    function getDiceMaterials(uint256 _tokenId)
        public
        view
        tokenExists(_tokenId)
        returns (string[] memory)
    {
        DiceMetadata memory _diceMetadata = _oldTokenIdToMetadata[
            _newTokenIdToOldTokenId[_tokenId]
        ];

        string[] memory materials = new string[](_diceMetadata.amount);

        if (_diceMetadata.amount >= 1) {
            materials[0] = DiceBitmapUtil.getDiceMaterial(_diceMetadata.bitmap, 0).toString();
        }
        if (_diceMetadata.amount >= 2) {
            materials[1] = DiceBitmapUtil.getDiceMaterial(_diceMetadata.bitmap, 1).toString();
        }
        if (_diceMetadata.amount >= 3) {
            materials[2] = DiceBitmapUtil.getDiceMaterial(_diceMetadata.bitmap, 2).toString();
        }
        if (_diceMetadata.amount >= 4) {
            materials[3] = DiceBitmapUtil.getDiceMaterial(_diceMetadata.bitmap, 3).toString();
        }
        if (_diceMetadata.amount >= 5) {
            materials[4] = DiceBitmapUtil.getDiceMaterial(_diceMetadata.bitmap, 4).toString();
        }
        if (_diceMetadata.amount >= 6) {
            materials[5] = DiceBitmapUtil.getDiceMaterial(_diceMetadata.bitmap, 5).toString();
        }
        if (_diceMetadata.amount >= 7) {
            materials[6] = DiceBitmapUtil.getDiceMaterial(_diceMetadata.bitmap, 6).toString();
        }

        return materials;
    }

    function getDiceMetadata(uint256 _tokenId)
        public
        view
        tokenExists(_tokenId)
        returns (DiceMetadata memory)
    {
        return _oldTokenIdToMetadata[_newTokenIdToOldTokenId[_tokenId]];
    }

    function setImageDirURI(string calldata _imageDirURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        imageDirURI = _imageDirURI;
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

    function _canMint() internal view virtual override returns (bool) {
        return hasRole(MINTER_ROLE, msg.sender);
    }
}