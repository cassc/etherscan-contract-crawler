/* SPDX-License-Identifier: MIT

   ██████     ░░░░░░     ▒▒▒▒▒▒
 ██████████ ░░░░░░░░░░ ▒▒▒▒▒▒▒▒▒▒
 ███    ███ ░░░░       ▒▒▒▒  ▒▒▒▒
 ██████████ ░░░░░░░░░░ ▒▒▒▒  ▒▒▒▒
   ██████     ░░░░░░    ▒▒▒  ▒▒▒

 ********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░██████████████████████░░░ *
 * ░░░██░░░░░░██░░░░░░████░░░░░ *
 * ░░░██░░░░░░██░░░░░░██░░░░░░░ *
 * ░░░██████████████████░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 ************************♥tt****/

// onChainAlpha.sol is a fork of 
// IndelibleERC721A.sol by 0xHirch.eth
// With modifications by ogkenobi.eth

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./helpers/SSTORE2.sol";
import "./helpers/DynamicBuffer.sol";
import "./helpers/HelperLib.sol";
import "./helpers/ERC721A.sol";


contract OnChainAlpha is ERC721A, IERC721Receiver, Multicall, ReentrancyGuard, Ownable {
    using HelperLib for uint256;
    using DynamicBuffer for bytes;

    event AttributesUpdated(
        uint256 tokenId,
        string userName,
        string social,
        string website,
        string profileName
    );
    event LabelsValuesUpdated(
        uint256 tokenId,
        uint256 labelId,
        string customLabels,
        string customValues
    );
    event LayersUpdated(uint256 tokenId, bool[] layerIsHidden);
    event LayersRevealed(uint256 tokenId, uint layerRevealed);
    event ImagePhlipped(uint256 tokenId, bool isPhlipped);
    event bgChanged(uint256 tokenId, string color);

    struct TraitDTO {
        string name;
        string mimetype;
        bytes data;
    }

    struct Trait {
        string name;
        string mimetype;
    }

    struct AlphaToken {
        Profile AlphaProfile;
        mapping(uint => string) labels;
        mapping(uint => string) values;
        uint256 labelcount;
    }

    struct Profile {
        string userName;
        string social;
        string website;
        string profileName;
    }

    struct ContractData {
        string name;
        string description;
        string image;
        string banner;
        string website;
        uint256 royalties;
        string royaltiesRecipient;
    }

    mapping(uint256 => address[]) internal _traitDataPointers;
    mapping(uint256 => mapping(uint256 => Trait)) internal _traitDetails;
    mapping(uint256 => bool) internal _renderTokenOffChain;
    mapping(uint256 => mapping(uint256 => bool)) internal _hideLayer;
    mapping(uint256 => mapping(uint256 => bool)) internal _revealLayer;
    mapping(uint256 => bool) internal _phlipImage;
    mapping(uint256 => AlphaToken) idValues;
    mapping(uint256 => string) bgColor;
    mapping(address => uint256) rebates;
    mapping(uint256 => bool) ogMints;
    mapping(address => uint256) mints;

    uint256 private constant NUM_LAYERS = 15;
    uint256 private constant MAX_BATCH_MINT = 10;
    uint256[][NUM_LAYERS] private TIERS;
    string[] private LAYER_NAMES = [
        unicode"Special",
        unicode"-",
        unicode"Mouth Special",
        unicode"-",
        unicode"Headwear",
        unicode"-",
        unicode"Eyewear",
        unicode"-",
        unicode"Eyes",
        unicode"-",
        unicode"Mouth",
        unicode"-",
        unicode"Ears",
        unicode"-",
        unicode"Body"
    ];

    function setLayerNames(uint _layerNum, string memory _value) public onlyOwner {
        LAYER_NAMES[_layerNum] = _value;
    }

    address public reRollDuplicateRole = 0x957356F9412830c992D465FF8CDb9b0AA023020b;
    address public faContract = 0x89d92A754FD1A672c21b5fc2a347198D1A9456b3;
    uint256 public constant maxSupply = 7777;
    uint256 public mintPrice = 0.05 ether;
    uint256 public rebateAmt = 0.02 ether;
    string public baseURI = "https://static.flooredApe.io/oca/";
    bool public isPublicMintActive = false;

    ContractData public contractData =
        ContractData(
            unicode"On-Chain Alpha",
            unicode"On-Chain Alpha is a collection of 7777 customizable digital identity tokens stored entirely on the Ethereum blockchain. Token holders can visit https://oca.gg to enable/disable existing traits, change background color, flip the image, enable Twitter hex, and more as well as reveal new trait drops to be released in the future.",
            "https://ipfs.io/ipfs/Qmdbq7N5izrazoYcbwSuxcms2dBemxuxbrLaFtw2dufdV6/collection.gif",
            "https://ipfs.io/ipfs/Qmdbq7N5izrazoYcbwSuxcms2dBemxuxbrLaFtw2dufdV6/banner.png",
            "https://oca.gg",
            500,
            "0x957356F9412830c992D465FF8CDb9b0AA023020b"
        );

    constructor() ERC721A("On-Chain Alpha", "OCA") {
        TIERS[0] = [10,15,25,50,75,100,7502]; //special 0
        TIERS[1] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027];
        TIERS[2] = [50,100,150,200,250,300,350,400,450,500,550,600,650,700,750,1777]; //mouth special 1
        TIERS[3] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027];
        TIERS[4] = [10,20,40,60,80,100,120,140,160,180,200,220,240,260,280,300,320,340,360,380,400,420,440,460,480,500,520,747]; //headwear 2
        TIERS[5] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027];
        TIERS[6] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027]; //eyewear 3
        TIERS[7] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027];
        TIERS[8] = [25,40,80,110,140,170,200,230,260,290,320,350,380,410,440,470,500,530,570,610,650,1002]; //eyes 4
        TIERS[9] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027];
        TIERS[10] = [100,200,250,300,350,400,450,500,550,600,650,700,750,850,1000,1727]; //mouth 5
        TIERS[11] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027];
        TIERS[12] = [200,300,400,500,600,700,800,900,1000,1100,1200,1300,1477]; //ears 6
        TIERS[13] = [35,65,100,130,160,190,220,250,280,310,340,370,400,450,500,650,700,750,850,1027];
        TIERS[14] = [75,100,150,200,250,300,350,400,450,500,550,600,700,800,900,1452,0]; //body 7
    }

    function rarityGen(uint256 _randinput, uint256 _rarityTier)
        internal
        view
        returns (uint256)
    {
        uint256 currentLowerBound = 0;
        for (uint256 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint256 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        return TIERS[_rarityTier].length - 1;
    }

    modifier whenMintActive() {
        require(isMintActive());
        _;
    }

    function entropyForExtraData() internal view returns (uint24) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    msg.sender
                )
            )
        );
        return uint24(randomNumber);
    }

    function reRollDuplicate(uint256 tokenIdA, uint256 tokenIdB)
        public
    {
        require(msg.sender == reRollDuplicateRole);

        uint256 largerTokenId = tokenIdA > tokenIdB ? tokenIdA : tokenIdB;

        _initializeOwnershipAt(largerTokenId);
        if (_exists(largerTokenId + 1)) {
            _initializeOwnershipAt(largerTokenId + 1);
        }

        _setExtraDataAt(largerTokenId, entropyForExtraData());
    }

    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual override returns (uint24) {
        return from == address(0) ? entropyForExtraData() : previousExtraData;
    }

    function tokenIdToHash(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        require(_exists(_tokenId));
        // This will generate a NUM_LAYERS * 3 character string.
        bytes memory hashBytes = DynamicBuffer.allocate(NUM_LAYERS * 4);

        uint256[] memory hash = new uint256[](NUM_LAYERS);

        for (uint256 i = 0; i < NUM_LAYERS; i++) {
            uint256 traitIndex = hash[i];
            if(i % 2 > 0 && _revealLayer[_tokenId][i] == false){
                hash[i] = TIERS[i].length - 1;
            } else {
                uint256 tokenExtraData = uint24(_ownershipOf(_tokenId).extraData);
                uint256 _randinput = uint256(
                    keccak256(
                        abi.encodePacked(
                            tokenExtraData,
                            _tokenId,
                            _tokenId + i
                        )
                    )
                ) % maxSupply;

                traitIndex = rarityGen(_randinput, i);
                hash[i] = traitIndex;
                uint blank = TIERS[i].length - 1;

                if (_hideLayer[_tokenId][i] == true){
                    if (i == 10 && hash[i] == 10){ //astonished -> blank
                        hash[i] = blank;
                        if(_hideLayer[_tokenId][2] == false){hash[2] = 15;}

                    } else if (i == 14 && hash[i] == 0) {
                        //ghost
                        hash[i] = blank;
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 5;}
                        
                    } else if (i == 14 && hash[i] == 2) {
                        //robot
                        hash[i] = blank;
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 1;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 0;}
                        if(_hideLayer[_tokenId][4] == false){hash[4] = 1;}
                        
                    } else if (i == 14 && hash[i] == 4) {
                        //skull
                        hash[i] = blank;
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 8;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 9;}

                    } else if (i == 14 && hash[i] == 5) {
                        //vampire
                        hash[i] = blank;
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 6;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 7;}

                    } else if (i == 14 && hash[i] == 6) {
                        //monster
                        hash[i] = blank;
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 7;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 8;}
                        if (hash[6] == 8 && _hideLayer[_tokenId][6] == false) {hash[6] = 19;}
                    } else if (i == 14 && hash[i] == 7) {
                        //clown
                        hash[i] = blank;
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 2;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 4;}

                    } else if (i == 14 && hash[i] == 9) {
                        //pepe
                        hash[i] = blank;
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 5;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 1;}

                    } else if (i == 14 && hash[i] == 10) {
                        //doge
                        hash[i] = blank;
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 4;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 2;}

                    } else if (i == 14 && hash[i] == 11) {
                        //cat
                        hash[i] = blank;
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 3;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 3;}

                    } else {
                        hash[i] = blank;
                    }
                    
                } else {

                    if (hash[10] == 10){ //astonished -> blank
                        if(_hideLayer[_tokenId][2] == false){hash[2] = 15;}
                    }

                    if (hash[14] == 0) {
                        //ghost
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 5;}
                    } else if (hash[14] == 2) {
                        //robot
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 1;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 0;}
                        if(_hideLayer[_tokenId][4] == false){hash[4] = 1;}

                    } else if (hash[14] == 4) {
                        //skull
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 8;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 9;}

                    } else if (hash[14] == 5) {
                        //vampire
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 6;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 7;}

                    } else if (hash[14] == 6) {
                        //monster
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 7;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 8;}
                        if (hash[6] == 8 && _hideLayer[_tokenId][6] == false) {hash[6] = 19;}

                    } else if (hash[14] == 7) {
                        //clown
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 2;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 4;}

                    } else if (hash[14] == 9) {
                        //pepe
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 5;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 1;}

                    } else if (hash[14] == 10) {
                        //doge
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 4;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 2;}

                    } else if (hash[14] == 11) {
                        //cat
                        if(_hideLayer[_tokenId][10] == false){hash[10] = 3;}
                        if(_hideLayer[_tokenId][8] == false){hash[8] = 3;}

                    }

                }
            }
        }

        for (uint256 i = 0; i < hash.length; i++) {
            if (hash[i] < 10) {
                hashBytes.appendSafe("00");
            } else if (hash[i] < 100) {
                hashBytes.appendSafe("0");
            }
            if (hash[i] > 999) {
                hashBytes.appendSafe("999");
            } else {
                hashBytes.appendSafe(bytes(_toString(hash[i])));
            }
        }

        return string(hashBytes);
    }

    function publicMint(uint256 _count) external payable nonReentrant whenMintActive returns (uint256) {
        uint256 totalMinted = _totalMinted();
        require(mints[msg.sender] + _count <= 100);
        require(_count <= MAX_BATCH_MINT && _count > 0);
        require(totalMinted + _count <= maxSupply);
        require(msg.sender == tx.origin);

        uint256 discount;
        uint256 numDisc = rebates[msg.sender];
        if (numDisc > 0) {
            if (numDisc <= _count) {
                discount = rebateAmt * numDisc;
                require(msg.value >= (_count * mintPrice) - discount);
                rebates[msg.sender] = 0;
            } else {
                discount = rebateAmt * _count;
                require(msg.value >= (_count * mintPrice) - discount);
                rebates[msg.sender] -= _count;
            }
        } else {
            require(msg.value >= _count * mintPrice);
        }

        mints[msg.sender] += _count;
        _mint(msg.sender, _count);

        return totalMinted;
    }

    function ogMint(uint256 _ogTokenId) external nonReentrant whenMintActive returns (uint256) {
        uint256 totalMinted = _totalMinted();
        require(_ogTokenId <= 1000);
        require(ogMints[_ogTokenId] == false);
        require(msg.sender == ERC721(faContract).ownerOf(_ogTokenId));
        require(totalMinted + 1 <= maxSupply);

        ogMints[_ogTokenId] = true;
        _mint(msg.sender, 1);
        return totalMinted;
    }

    function ogClaimed(uint256 _ogTokenId) public view returns (bool){
        return ogMints[_ogTokenId];
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        require(
            msg.sender == faContract ||
                ERC721(faContract).ownerOf(
                    tokenId
                ) ==
                from
        );

        rebates[from]++;
        return this.onERC721Received.selector;
    }

    function getRebates(address _address) public view returns (uint256) {
        return rebates[_address];
    }

    function hashToSVG(string memory _hash, uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        uint256 thisTraitIndex;
        string memory _bgColor = "1C1531";

        if (bytes(bgColor[_tokenId]).length > 0) {
            _bgColor = bgColor[_tokenId];
        }

        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        svgBytes.appendSafe(
            '<svg width="1600" height="1600" viewBox="0 0 1600 1600" version="1.2" xmlns="http://www.w3.org/2000/svg" style="background-color: #'
        );
        svgBytes.appendSafe(
            abi.encodePacked(_bgColor, ";background-image:url(")
        );
        for (uint256 i = 0; i < NUM_LAYERS - 1; i++) {
            if(!(i % 2 > 0 && _revealLayer[_tokenId][i] == false)){
            // if(_traitDataPointers[i].length > 0){
                thisTraitIndex = HelperLib.parseInt(
                    HelperLib._substring(_hash, (i * 3), (i * 3) + 3)
                );
                svgBytes.appendSafe(
                    abi.encodePacked(
                        "data:",
                        _traitDetails[i][thisTraitIndex].mimetype,
                        ";base64,",
                        Base64.encode(
                            SSTORE2.read(_traitDataPointers[i][thisTraitIndex])
                        ),
                        "),url("
                    )
                );
            }
        }

        thisTraitIndex = HelperLib.parseInt(
            HelperLib._substring(_hash, (NUM_LAYERS * 3) - 3, NUM_LAYERS * 3)
        );

        svgBytes.appendSafe(
            abi.encodePacked(
                "data:",
                _traitDetails[NUM_LAYERS - 1][thisTraitIndex].mimetype,
                ";base64,",
                Base64.encode(
                    SSTORE2.read(
                        _traitDataPointers[NUM_LAYERS - 1][thisTraitIndex]
                    )
                ),
                ');background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;"></svg>'
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svgBytes)
                )
            );
    }

    function hashToMetadata(string memory _hash, uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        bytes memory metadataBytes = DynamicBuffer.allocate(1024 * 128);
        metadataBytes.appendSafe("[");

        for (uint256 i = 0; i < NUM_LAYERS; i++) {
            uint256 thisTraitIndex = HelperLib.parseInt(
                HelperLib._substring(_hash, (i * 3), (i * 3) + 3)
            );
            if (bytes(_traitDetails[i][thisTraitIndex].name).length > 2 ) {
                metadataBytes.appendSafe(
                    abi.encodePacked(
                        '{"trait_type":"',
                        LAYER_NAMES[i],
                        '","value":"',
                        _traitDetails[i][thisTraitIndex].name,
                        '"}'
                    )
                );

                if (i == 10 && ((_hideLayer[_tokenId][11] || _revealLayer[_tokenId][11] == false) && _hideLayer[_tokenId][12] && (_hideLayer[_tokenId][13] || _revealLayer[_tokenId][13] == false) && _hideLayer[_tokenId][14])){
                    metadataBytes.appendSafe("]");
                } else if (i == 11 && (_hideLayer[_tokenId][12] && (_hideLayer[_tokenId][13] || _revealLayer[_tokenId][13] == false) && _hideLayer[_tokenId][14])){
                    metadataBytes.appendSafe("]");
                } else if (i == 12 && ((_hideLayer[_tokenId][13] || _revealLayer[_tokenId][13] == false) && _hideLayer[_tokenId][14])){
                    metadataBytes.appendSafe("]");
                } else if (i == 13 && _hideLayer[_tokenId][14]){
                    metadataBytes.appendSafe("]");
                } else if (i == 14) {
                    metadataBytes.appendSafe("]");
                } else {
                    metadataBytes.appendSafe(",");
                }

            } 
        }

        return string(metadataBytes);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));
        require(_traitDataPointers[0].length > 0);

        string memory tokenHash = tokenIdToHash(_tokenId);

        bytes memory jsonBytes = DynamicBuffer.allocate(1024 * 128);
        if (bytes(idValues[_tokenId].AlphaProfile.userName).length > 0) {
            jsonBytes.appendSafe(
                abi.encodePacked(
                    unicode'{"name":"',
                    idValues[_tokenId].AlphaProfile.userName
                )
            );
        } else {
            jsonBytes.appendSafe(unicode'{"name":"OnChainAlpha');
        }

        jsonBytes.appendSafe(
            abi.encodePacked(
                "#",
                _toString(_tokenId),
                '","description":"',
                contractData.description,
                '",'
            )
        );

        if (bytes(baseURI).length > 0 && _renderTokenOffChain[_tokenId]) {
            jsonBytes.appendSafe(
                abi.encodePacked('"image":"', baseURI, _toString(_tokenId))
            );
        } else {
            string memory svgCode = "";
            if (_phlipImage[_tokenId]) {
                string memory svgString = hashToSVG(tokenHash, _tokenId);
                svgCode = string(
                    abi.encodePacked(
                        "data:image/svg+xml;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '<svg width="100%" height="100%" viewBox="0 0 1200 1200" style="display: block; transform: scale(-1,1)" version="1.2" xmlns="http://www.w3.org/2000/svg"><image width="1200" height="1200" href="',
                                svgString,
                                '"></image></svg>'
                            )
                        )
                    )
                );
                jsonBytes.appendSafe(
                    abi.encodePacked('"svg_image_data":"', svgString, '",')
                );
            } else {
                string memory svgString = hashToSVG(tokenHash, _tokenId);
                svgCode = string(
                    abi.encodePacked(
                        "data:image/svg+xml;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '<svg width="100%" height="100%" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg"><image width="1200" height="1200" href="',
                                svgString,
                                '"></image></svg>'
                            )
                        )
                    )
                );
                jsonBytes.appendSafe(
                    abi.encodePacked('"svg_image_data":"', svgString, '",')
                );
            }

            jsonBytes.appendSafe(
                abi.encodePacked('"image_data":"', svgCode, '",')
            );
        }

        jsonBytes.appendSafe(
            abi.encodePacked('"attributes":', hashToMetadata(tokenHash, _tokenId), "}")
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(jsonBytes)
                )
            );
    }

    function contractURI() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            contractData.name,
                            '","description":"',
                            contractData.description,
                            '","image":"',
                            contractData.image,
                            '","banner":"',
                            contractData.banner,
                            '","external_link":"',
                            contractData.website,
                            '","seller_fee_basis_points":',
                            _toString(contractData.royalties),
                            ',"fee_recipient":"',
                            contractData.royaltiesRecipient,
                            '"}'
                        )
                    )
                )
            );
    }

    function addLayer(uint256 _layerIndex, TraitDTO[] memory traits)
        public
        onlyOwner
    {
        require(TIERS[_layerIndex].length == traits.length);
        address[] memory dataPointers = new address[](traits.length);
        for (uint256 i = 0; i < traits.length; i++) {
            dataPointers[i] = SSTORE2.write(traits[i].data);
            _traitDetails[_layerIndex][i] = Trait(
                traits[i].name,
                traits[i].mimetype
            );
        }
        _traitDataPointers[_layerIndex] = dataPointers;
        return;
    }

    function setRenderOfTokenId(uint256 _tokenId, bool _renderOffChain)
        external
    {
        require(msg.sender == ownerOf(_tokenId));
        _renderTokenOffChain[_tokenId] = _renderOffChain;
    }

    function isMintActive() public view returns (bool) {
        return _totalMinted() < maxSupply && isPublicMintActive;
    }

    function togglePublicMint() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    //metadata URI
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setContractData(ContractData memory _contractData)
        external
        onlyOwner
    {
        contractData = _contractData;
    }

    //address info
    address private helper = 0x95c0a28443F4897Bf718243A539fd018B6C16F63;

    //withdraw to helper address
    function withdraw() external {
        uint256 balance = address(this).balance;
        require(balance > 0);
        Address.sendValue(payable(helper), balance);
    }

    function setBgColor(uint256 _tokenId, string memory _bgColor) public {
        require(ownerOf(_tokenId) == msg.sender);
        bgColor[_tokenId] = _bgColor;

        emit bgChanged(_tokenId, _bgColor);
    }

    function setProfile(
        uint256 _tokenId,
        string memory _username,
        string memory _social,
        string memory _website
    ) public {
        require(ownerOf(_tokenId) == msg.sender);

        idValues[_tokenId].AlphaProfile.userName = _username;
        idValues[_tokenId].AlphaProfile.social = _social;
        idValues[_tokenId].AlphaProfile.website = _website;

        string memory str = string(abi.encodePacked(_username,"#",_toString(_tokenId)));
        idValues[_tokenId].AlphaProfile.profileName = str;

        emit AttributesUpdated(
            _tokenId,
            _username,
            _social,
            _website,
            str
        );
    }

    function setLabelsValues(uint256 _tokenId, uint _labelNum, string memory _label, string memory _value) external {
        require(msg.sender == ownerOf(_tokenId));
        uint count = idValues[_tokenId].labelcount;
        if(_labelNum >= count){
            _labelNum = count;
            idValues[_tokenId].labelcount++;
        }

        idValues[_tokenId].labels[_labelNum] = _label;
        idValues[_tokenId].values[_labelNum] = _value;

        emit LabelsValuesUpdated(_tokenId, _labelNum, _label, _value);
    }

    function toggleLayers(uint256 _tokenId, bool[] memory states) public {
        require(msg.sender == ownerOf(_tokenId));
        for (uint256 i = 0; i < NUM_LAYERS; i++) {
            _hideLayer[_tokenId][i] = states[i];
        }

        emit LayersUpdated(_tokenId, states);
    }

    function revealLayers(uint256 _tokenId, uint _layer) public {
        require(_layer < 15);
        require(msg.sender == ownerOf(_tokenId));

        _revealLayer[_tokenId][_layer] = true;

        emit LayersRevealed(_tokenId, _layer);
    }

    function togglePhlipPFP(uint256 _tokenId, bool _flipped) public {
        require(msg.sender == ownerOf(_tokenId));
        _phlipImage[_tokenId] = _flipped;

        emit ImagePhlipped(_tokenId, _flipped);
    }

}