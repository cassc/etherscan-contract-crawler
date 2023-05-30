// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1967/ERC1967ProxyImplementation.sol";
import "./OpenSea/ERC721TradableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


struct RelicProperties
{
    uint256 relicTypeId;
    uint256 materialId;
    uint256 materialOffset; // this relic's number relative to material, e.g. Gold Skull #42
    uint256 poleId;
    uint256 astralId;
    uint256 elementId;
    uint256 alignmentId;
    uint256 greatness;
}

interface IRelicMinter
{
    // The relic minter can inject attributes into the metadata attributes array,
    // they will be added after the standard ones so should begin with a comma.
    // e.g. ,{"trait_type": "Extra Field", "value": "The Value"}
    function getAdditionalAttributes(uint256 tokenId, bytes12 data)
        external view returns(string memory);

    function getTokenOrderIndex(uint256 tokenId, bytes12 data)
        external view returns(uint);

    function getTokenProvenance(uint256 tokenId, bytes12 data)
        external view returns(string memory);

    function getImageBaseURL()
        external view returns(string memory);
}


contract Relic is ProxyImplementation, ERC721TradableUpgradeable
{
    mapping(address => bool) private _whitelistedMinters;
    mapping(uint256 => uint256) public _tokenMintInfo;
    string public _placeholderImageURL;
    string public _animationBaseURL;
    string public _collectionName;
    string public _collectionDesc;
    string public _collectionImgURL;
    string public _collectionExtURL;
    uint256 public _feeBasisPoints;
    address public _feeRecipient;

    function init(
        string memory name,
        string memory symbol,
        address proxyRegistryAddress,
        string memory placeholderImageURL,
        string memory animationBaseURL,
        string memory collectionName,
        string memory collectionDesc,
        string memory collectionImgURL,
        string memory collectionExtURL,
        uint256 feeBasisPoints,
        address feeRecipient)
        public onlyOwner initializer
    {
        _initializeEIP712(name);
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __ERC721TradableUpgradeable_init_unchained(proxyRegistryAddress);

        _placeholderImageURL = placeholderImageURL;
        _animationBaseURL = animationBaseURL;
        _collectionName = collectionName;
        _collectionDesc = collectionDesc;
        _collectionImgURL = collectionImgURL;
        _collectionExtURL = collectionExtURL;
        _feeBasisPoints = feeBasisPoints;
        _feeRecipient = feeRecipient;
    }

    function exists(uint256 tokenId) public view returns(bool)
    {
        return _exists(tokenId);
    }

    function mint(address to, uint256 tokenId, bytes12 data) public
    {
        require(isMinterWhitelisted(_msgSender()), "minter not whitelisted");

        // only need 20 bytes for the minter address, so might as well use the
        // other 12 bytes of the slot for something. The minter can pass
        // whatever they want, I'm thinking some kind of useful context, e.g. a
        // minter which manages multiple dungeons could use this field for
        // dungeon Id
        _tokenMintInfo[tokenId] = packTokenMintInfo(IRelicMinter(_msgSender()), data);

        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory)
    {
        require(_exists(tokenId), "token doesn't exist");

        RelicProperties memory relicProps = getRelicProperties(tokenId);

        (IRelicMinter relicMinter, bytes12 data) = unpackTokenMintInfo(_tokenMintInfo[tokenId]);
        uint orderIndex = relicMinter.getTokenOrderIndex(tokenId, data);
        string memory provenance = relicMinter.getTokenProvenance(tokenId, data);
        string memory baseImageURL = relicMinter.getImageBaseURL();
        if (bytes(baseImageURL).length == 0)
        {
            baseImageURL = _placeholderImageURL;
        }
        string memory imageURL = getImageURLForToken(tokenId, baseImageURL, orderIndex, provenance);

        string memory attrs = string(abi.encodePacked(
           _getAttributes(relicProps),
            ",{\"trait_type\": \"Order\", \"value\": \"", getOrderSuffix(orderIndex), "\"}",
            ",{\"trait_type\": \"Provenance\", \"value\": \"", provenance, "\"}",
            relicMinter.getAdditionalAttributes(tokenId, data)
        ));

        return string(abi.encodePacked(
            "data:application/json;utf8,{"
            "\"name\": \"", getName(relicProps.relicTypeId, relicProps.materialId, relicProps.materialOffset), "\","
            "\"description\": \"Loot dungeon relic\","
            "\"image\": \"", imageURL, "\",",
            "\"external_url\": \"", imageURL,"\",", // TODO: this should be link to asset on TheCrupt
            "\"attributes\": [", attrs, "]}"
        ));
    }

    function contractURI() public view returns(string memory)
    {
        return string(abi.encodePacked(
            "data:application/json;utf8,{"
            "\"name\": \"", _collectionName, "\","
            "\"description\": \"", _collectionDesc, "\","
            "\"image\": \"", _collectionImgURL, "\",",
            "\"external_link\": \"", _collectionExtURL,"\",",
            "\"seller_fee_basis_points\": \"", StringsUpgradeable.toString(_feeBasisPoints),"\",",
            "\"fee_recipient\": \"", StringsUpgradeable.toHexString(uint256(uint160(_feeRecipient)), 20),"\"",
            "}"
        ));
    }

    function getRelicProperties(uint256 tokenId)
        public pure returns(RelicProperties memory)
    {
        RelicProperties memory props;

        uint256 relicsPerMaterialForCurrentType = 84;
        uint256 totalRelicsOfCurrentType;
        uint256 tokenIdStartForCurrentType;
        uint256 tokenIdEndForCurrentType; // exclusive

        while (true)
        {
            totalRelicsOfCurrentType = relicsPerMaterialForCurrentType << 2;
            tokenIdEndForCurrentType = tokenIdStartForCurrentType + totalRelicsOfCurrentType;

            if (tokenId < tokenIdEndForCurrentType)
            {
                break;
            }

            ++props.relicTypeId;
            tokenIdStartForCurrentType = tokenIdEndForCurrentType;
            relicsPerMaterialForCurrentType <<= 1;
        }

        // find out the offset of this token Id into its relic type, that is to
        // say if it's the Nth Skull, what is the value of N
        uint256 relicOffset = tokenId - tokenIdStartForCurrentType;

        // we want materials to be allocated in order from smallest to largest
        // token Id, so derive material from relic offset
        props.materialId = relicOffset / relicsPerMaterialForCurrentType;

        // we want to know that this is the Nth relic of type x material y, for
        // the token name e.g. Golden Skull #42
        props.materialOffset = relicOffset % relicsPerMaterialForCurrentType;

         // First relic of each material set is greatness 20 then it is decremented per token until it loops at the minimum for its type
        uint256 minGreatness = getMiniumGreatness(props.relicTypeId); 
        uint256 greatnessRange = 21 - minGreatness;
        props.greatness = 20 - (props.materialOffset % greatnessRange); 

       
        // offset the attributes Id with a "random" number per relic + material
        // combination, so that all relics of a certain material don't start on
        // N Sun Earth Good Greatness 0 etc
        uint256 attributesId = relicOffset + uint256(keccak256(abi.encodePacked(props.relicTypeId, props.materialId)));

        props.alignmentId = (attributesId / greatnessRange) & 3;
        props.elementId = (attributesId / (greatnessRange * 4)) & 3;
        props.astralId = (attributesId / (greatnessRange * 16)) & 3;
        props.poleId = (attributesId / (greatnessRange * 64)) & 3;

        return props;
    }

    function packTokenMintInfo(IRelicMinter relicMinter, bytes12 data)
        public pure returns(uint256)
    {
        return (uint256(uint160(address(relicMinter))) << 96) | uint96(data);
    }

    function unpackTokenMintInfo(uint256 mintInfo)
        public pure returns(IRelicMinter relicMinter, bytes12 data)
    {
        relicMinter = IRelicMinter(address(uint160(mintInfo >> 96)));
        data = bytes12(uint96(mintInfo & 0xffffffffffffffffffffffff));
    }

    function getRelicType(uint256 relicId) public pure returns(string memory)
    {
        string[7] memory relics = ["Skull", "Crown", "Medal", "Key", "Dagger", "Gem", "Coin"];
        return relics[relicId];
    }

    function getMaterial(uint256 materialId) public pure returns(string memory)
    {
        string[4] memory materials = ["Gold", "Ice", "Fire", "Jade"];
        return materials[materialId];
    }

    function getName(uint256 relicId, uint256 materialId, uint256 materialOffset)
        public pure returns(string memory)
    {
        return string(abi.encodePacked(
            getMaterial(materialId), " ",
            getRelicType(relicId),
            " #", StringsUpgradeable.toString(materialOffset + 1)));
    }

    function getAlignment(uint256 alignmentId) public pure returns(string memory)
    {
        string[4] memory alignment = ["Good", "Evil", "Lawful", "Chaos"];
        return alignment[alignmentId];
    }

    function getElement(uint256 elementId) public pure returns(string memory)
    {
        string[4] memory element = ["Earth", "Wind", "Fire", "Water"];
        return element[elementId];
    }

    function getAstral(uint256 astralId) public pure returns(string memory)
    {
        string[4] memory astral = ["Earth", "Sun", "Moon", "Stars"];
        return astral[astralId];
    }

    function getPole(uint256 poleId) public pure returns(string memory)
    {
        string[4] memory pole = ["North", "South", "East", "West"];
        return pole[poleId];
    }

    function getMiniumGreatness(uint256 relicId) public pure returns(uint256)
    {
        uint256[7] memory greatnesses = [(uint256)(20), 19, 18,17,15,10,0];
        return greatnesses[relicId];
    }

    function getOrderSuffix(uint orderId) public pure returns(string memory)
    {
        string[16] memory suffixes = [
            "of Power",
            "of Giants",
            "of Titans",
            "of Skill",
            "of Perfection",
            "of Brilliance",
            "of Enlightenment",
            "of Protection",
            "of Anger",
            "of Rage",
            "of Fury",
            "of Vitriol",
            "of the Fox",
            "of Detection",
            "of Reflection",
            "of the Twins"
        ];
        return suffixes[orderId];
    }

    // encodes properties in relicProps for use in a URL, such as for animation_url
    function _getURLParams(RelicProperties memory relicProps) public pure returns(string memory)
    {
        return string(abi.encodePacked(
            "relicType=", getRelicType(relicProps.relicTypeId),
            "&material=", getMaterial(relicProps.materialId),
            "&pole=", getPole(relicProps.poleId),
            "&astral=", getAstral(relicProps.astralId),
            "&element=", getElement(relicProps.elementId),
            "&alignment=", getAlignment(relicProps.alignmentId),
            "&greatness=", StringsUpgradeable.toString(relicProps.greatness)
        ));
    }

    // encodes properties in relicProps for use in the attributes array of token
    // metadata
    function _getAttributes(RelicProperties memory relicProps) public pure returns(string memory)
    {
        bytes memory str = abi.encodePacked(
            "{\"trait_type\": \"Relic Type\", \"value\": \"", getRelicType(relicProps.relicTypeId),"\"},"
            "{\"trait_type\": \"Material\", \"value\": \"", getMaterial(relicProps.materialId),"\"},"
            "{\"trait_type\": \"Pole\", \"value\": \"", getPole(relicProps.poleId),"\"},"
            "{\"trait_type\": \"Astral\", \"value\": \"", getAstral(relicProps.astralId),"\"},"
            "{\"trait_type\": \"Element\", \"value\": \"", getElement(relicProps.elementId),"\"},"
            "{\"trait_type\": \"Alignment\", \"value\": \"", getAlignment(relicProps.alignmentId),"\"},"
        );

        // had to break this into two calls to encodePacked as it runs out of stack otherwise
        str = abi.encodePacked(str, "{\"trait_type\": \"Greatness\", \"value\": \"", StringsUpgradeable.toString(relicProps.greatness),"\"}");

        return string(str);
    }

    function getImageURLPart1(RelicProperties memory props)
        internal pure returns(string memory)
    {
        return string(abi.encodePacked(
            Strings.toString(props.materialId),
            "-",
            Strings.toString(props.relicTypeId),
            "-"
        ));
    }

    function getImageURLPart2(RelicProperties memory props)
        internal pure returns(string memory)
    {
        return string(abi.encodePacked(
            Strings.toString(props.astralId),
            "-",
            Strings.toString(props.elementId),
            "-",
            Strings.toString(props.poleId),
            "-"
        ));
    }

    function getImageURLPart3(RelicProperties memory props)
        internal pure returns(string memory)
    {
        return string(abi.encodePacked(
            Strings.toString(props.alignmentId),
            "-",
            Strings.toString(props.greatness),
            "-"
        ));
    }

    function getImageURLForToken(uint256 tokenId, string memory baseURL, uint orderIndex, string memory provenance)
        internal pure returns(string memory)
    {
        RelicProperties memory props = getRelicProperties(tokenId);
        return string(abi.encodePacked(
            baseURL,
            getImageURLPart1(props),
            Strings.toString(orderIndex),
            "-",
            getImageURLPart2(props),
            getImageURLPart3(props),
            provenance,
            ".png"
        ));
    }

    function isMinterWhitelisted(address minter) public view returns(bool)
    {
        return _whitelistedMinters[minter];
    }

    function addWhitelistedMinter(address minter) public onlyOwner
    {
        require(AddressUpgradeable.isContract(minter), "minter is not a contract");
        require(!isMinterWhitelisted(minter), "already whitelisted");
        _whitelistedMinters[minter] = true;
    }

    function removeWhitelistedMinter(address minter) public onlyOwner
    {
        require(isMinterWhitelisted(minter), "not whitelisted");
        _whitelistedMinters[minter] = false;
    }

    function setPlaceholderImageURL(string memory placeholderImageURL) public onlyOwner
    {
        _placeholderImageURL = placeholderImageURL;
    }

    function setAnimationBaseURL(string memory animationBaseURL) public onlyOwner
    {
        _animationBaseURL = animationBaseURL;
    }

    function setCollectionName(string memory collectionName) public onlyOwner
    {
        _collectionName = collectionName;
    }

    function setCollectionDesc(string memory collectionDesc) public onlyOwner
    {
        _collectionDesc = collectionDesc;
    }

    function setCollectionImgURL(string memory collectionImgURL) public onlyOwner
    {
        _collectionImgURL = collectionImgURL;
    }

    function setCollectionExtURL(string memory collectionExtURL) public onlyOwner
    {
        _collectionExtURL = collectionExtURL;
    }

    function setFeeBasisPoints(uint256 feeBasisPoints) public onlyOwner
    {
        _feeBasisPoints = feeBasisPoints;
    }

    function setFeeRecipient(address feeRecipient) public onlyOwner
    {
        _feeRecipient = feeRecipient;
    }
}