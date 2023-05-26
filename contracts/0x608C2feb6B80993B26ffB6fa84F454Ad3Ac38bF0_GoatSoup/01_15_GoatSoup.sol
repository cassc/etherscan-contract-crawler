// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "GoatLibrary.sol";

contract GoatSoup is ERC721, Ownable {
    using ECDSA for bytes32;

    uint256 private constant GS_PRICE = 0.08 ether;
    uint256 private constant GS_PRIVATE_MAX = 3500;
    uint256 private constant GS_SALE_MAX = 3744;
    uint256 private constant GS_AIRDROP = 100;
    address private constant GS_TEAM = 0xfa5d05Df712B059B74cCeFe4084785BE7f2ea1B8;

    mapping(string => bool) private _nonces;
    address private _signer = 0x818cDA2bA9CbC2dE202105E08dF37a26793f96A1;
    uint256 private _reserveCounter;
    uint256 private _presaleCounter;
    uint256 private _publicCounter;

    mapping(address => bool) public purchasedPresales;
    uint256 public currentSupply;
    bool public saleLive = false;
    bool public presaleLive = false;

    struct Attribute {
        string name;
        string attr_type;
        string svgPath;
        uint256 pixelCount;
    }

    mapping(uint256 => Attribute[]) _attributes;
    mapping(uint256 => uint256) _tokens;
    uint256 _nonce;

    constructor() ERC721("Goat Soup", "GSOUP") { }

    function verifyPublicMint(address sender, uint256 amount, string memory nonce, bytes memory signature) private view returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, amount, nonce));
        return _signer == hash.recover(signature);
    }

    function verify(address sender, bytes memory signature) private view returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender));
        return _signer == hash.recover(signature);
    }
    
    function mint(uint256 amount, string memory nonce, bytes memory signature) external payable {
        require(saleLive, "NOT_RELEASED");
        require(totalSupply() < GS_SALE_MAX, "SOLD_OUT");
        require(amount <= 2, "MAX_PER_TX_SALE");
        require(!_nonces[nonce], "NONCE_USED");
        require(verifyPublicMint(msg.sender, amount, nonce, signature), "INVALID_TRANSACTION");
        require(_publicCounter + amount <= GS_SALE_MAX - _presaleCounter - GS_AIRDROP, "MAX_PUBLIC_SALE");
        require(msg.value * amount >= GS_PRICE, "INSUFFICIENT_ETH_SENT");
        
        _nonces[nonce] = true;
        _publicCounter += amount;
        for(uint256 i = 0; i < amount; i++) {
            internalMint(msg.sender);
        }
    }

    function presale(bytes memory signature) external payable {
        require(presaleLive, "NOT_RELEASED");
        require(totalSupply() < GS_SALE_MAX, "SOLD_OUT");
        require(_presaleCounter < GS_PRIVATE_MAX, "MAX_PRIVATE_SALE");
        require(!purchasedPresales[msg.sender], "MAX_PER_PRESALE");
        require(verify(msg.sender, signature), "INVALID_TRANSACTION");
        require(msg.value >= GS_PRICE, "INSUFFICIENT_ETH_SENT");

        purchasedPresales[msg.sender] = true;
        _presaleCounter++;
        internalMint(msg.sender);
    }

    function reserveGoatSoup(address[] calldata _receivers) external onlyOwner {   
        require(totalSupply() + _receivers.length <= GS_SALE_MAX);
        _reserveCounter += _receivers.length;
        require(_reserveCounter <= GS_AIRDROP);  

        for (uint256 i = 0; i < _receivers.length; i++) {
            internalMint(_receivers[i]);
        }
    }

    function internalMint(address destination) internal {
        _tokens[currentSupply] = _generateAttributeSet(currentSupply, destination);
        _mint(destination, currentSupply);
        currentSupply++;
    }

    function flipSaleState() external onlyOwner {
        saleLive = !saleLive;
    }

    function flipPresaleState() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function setSignerAddress(address newSigner) external onlyOwner {
        _signer = newSigner;
    }

    function withdraw() external onlyOwner {
        payable(GS_TEAM).transfer(address(this).balance);
    }
    
    function totalSupply() public view returns (uint) {
        return currentSupply;
    }

    function tokensOfOwner(address _owner, uint startId, uint endId) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }

            return result;
        }
    }
    
    function _generateAttributeSet(uint256 _tokenId, address _sender) internal returns(uint256) {
        _nonce++;
        uint256 rndNumber = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _tokenId, _sender, _nonce)));

        uint256 hash = GoatLibrary.selectTraitSoup(rndNumber % 100);
        rndNumber >>= 12;
        hash |= GoatLibrary.selectTraitBowl(rndNumber % 100) << 8;
        rndNumber >>= 12;
        hash |= GoatLibrary.selectTraitFur(rndNumber % 100) << 16;
        rndNumber >>= 12;
        hash |= GoatLibrary.selectTraitTeeth(rndNumber % 100) << 24;
        rndNumber >>= 12;
        hash |= GoatLibrary.selectTraitHorns(rndNumber % 100) << 32;
        rndNumber >>= 12;
        hash |= GoatLibrary.selectTraitHats(rndNumber % 100) << 40;
        rndNumber >>= 12;
        hash |= GoatLibrary.selectTraitEyes(rndNumber % 100) << 48;

        return hash;
    }
    
    // credits to Anoynmice Mouse Dev for the inspiration of the SVG generation and compression algorithm
    // which is an MIT licensed contract
    function _generateSvg(uint256 _traitSet) internal view returns(string memory) {
        string memory svg;

        for(uint256 i = 0; i < 7; i++) {
            uint256 idx = _traitSet & 0xff;
            
            for(uint256 p = 0; p < _attributes[i][idx].pixelCount; p++) {
                string memory data = GoatLibrary.substring(_attributes[i][idx].svgPath, p * 5, p * 5 + 5);
                uint8 x = uint8(bytes(data)[0]) - 97;
                uint8 y = uint8(bytes(data)[1]) - 97;
                                
                svg = string(abi.encodePacked(
                        svg,"<rect class='g",GoatLibrary.substring(data, 2, 5),"' x='", GoatLibrary.toString(x),"' y='",GoatLibrary.toString(y),"'/>"
                    )
                );
            }

            _traitSet >>= 8;
        }
        
        svg = string(abi.encodePacked(
                "<svg id='gs' xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 24 24'>",
                svg,
                "<style>#gs{shape-rendering: crispedges;}rect{width:1px;height:1px;}.g100{fill:#000000}.g101{fill:#313131}.g102{fill:#252525}.g103{fill:#414040}.g104{fill:#4D4D4D}.g105{fill:#363636}.g106{fill:#003471}.g107{fill:#004A80}.g108{fill:#005E20}.g109{fill:#74A33E}.g110{fill:#6A9736}.g111{fill:#0054A6}.g112{fill:#598527}.g113{fill:#ABA000}.g114{fill:#CFBA5D}.g115{fill:#E8D782}.g116{fill:#E5D685}.g117{fill:#E0CE78}.g118{fill:#D7C264}.g119{fill:#C1AC50}.g120{fill:#DBC86D}.g121{fill:#D4BE5D}.g122{fill:#CCCCCC}.g123{fill:#FFFFFF}.g124{fill:#EBEBEB}.g125{fill:#C4393C}.g126{fill:#D14448}.g127{fill:#BC282C}.g128{fill:#B1191D}.g129{fill:#2C2422}.g130{fill:#6D6A6A}.g131{fill:#603913}.g132{fill:#593008}.g133{fill:#B5B5B5}.g134{fill:#563310}.g135{fill:#683F18}.g136{fill:#5C330B}.g137{fill:#5B3511}.g138{fill:#197B30}.g139{fill:#D7CC03}.g140{fill:#FFF200}.g141{fill:#8B3E0E}.g142{fill:#A34E19}.g143{fill:#D7640C}.g144{fill:#BD5717}.g145{fill:#2075A8}.g146{fill:#5F99BB}.g147{fill:#4D463E}.g148{fill:#F33C43}.g149{fill:#0E5024}.g150{fill:#5D981A}.g151{fill:#0C5D28}.g152{fill:#824E1C}.g153{fill:#C69C6D}.g154{fill:#362F2D}.g155{fill:#A67C52}.g156{fill:#F8F8F8}.g157{fill:#111111}.g158{fill:#636363}.g159{fill:#827C53}.g160{fill:#2F2D1E}.g161{fill:#00FFFF}.g162{fill:#27E5E5}.g163{fill:#2E3192}.g164{fill:#E60009}.g165{fill:#ED1C24}.g166{fill:#F6F6F6}.g167{fill:#08FFF4}.g168{fill:#00E4DA}.g169{fill:#6DCFF6}.g170{fill:#EFAE20}.g171{fill:#F8D00F}.g172{fill:#ECB223}.g173{fill:#F2B423}.g174{fill:#F7CE12}.g175{fill:#F7CF0D}.g176{fill:#F5BC13}.g177{fill:#F6CB0D}.g178{fill:#FBBA1E}.g179{fill:#F5CC10}.g180{fill:#F8D00E}.g181{fill:#F3BC1B}.g182{fill:#F6CD0F}.g183{fill:#FBBB1B}.g184{fill:#F9CD12}.g185{fill:#F6BA1B}.g186{fill:#F6C90E}.g187{fill:#EEAD1D}.g188{fill:#F7CB12}.g189{fill:#EBAC1F}.g190{fill:#ECAA16}.g191{fill:#F7C614}.g192{fill:#F0B31A}.g193{fill:#EDAE23}.g194{fill:#F2AD21}.g195{fill:#F3B71B}.g196{fill:#F3BF14}.g197{fill:#E4A12E}.g198{fill:#E5A124}.g199{fill:#EAA621}.g200{fill:#F4B51C}.g201{fill:#F5B619}.g202{fill:#F2B21C}.g203{fill:#F6B71C}.g204{fill:#FFFF00}.g205{fill:#03A600}.g206{fill:#A6001C}.g207{fill:#A1B92F}.g208{fill:#B2813E}.g209{fill:#BB9F4B}.g210{fill:#FCF8FF}.g211{fill:#5D8429}.g212{fill:#6E930F}.g213{fill:#E9EBB9}.g214{fill:#B59854}.g215{fill:#C4994B}.g216{fill:#69A22D}.g217{fill:#7EA21A}.g218{fill:#CAE4A7}.g219{fill:#779A18}.g220{fill:#B2CC09}.g221{fill:#C4EA32}.g222{fill:#7C9F0D}.g223{fill:#C1D224}.g224{fill:#A2CA1C}.g225{fill:#947235}.g226{fill:#906D29}.g227{fill:#6EA21A}.g228{fill:#EBF6D4}.g229{fill:#8AB510}.g230{fill:#8C692F}.g231{fill:#8B6A34}.g232{fill:#86B62E}.g233{fill:#8D9F3B}.g234{fill:#6FA11E}.g235{fill:#F6FBF4}.g236{fill:#FFFFFA}.g237{fill:#D7EFA1}.g238{fill:#F49AC1}.g239{fill:#F06EAA}.g240{fill:#FDBED9}.g241{fill:#F3438F}.g242{fill:#FBD1E3}.g243{fill:#B9006E}.g244{fill:#1A1A18}.g245{fill:#E01313}.g246{fill:#B7B7B7}.g247{fill:#C92121}.g248{fill:#FF0000}.g249{fill:#FF4747}.g250{fill:#6D3703}.g251{fill:#763B02}.g252{fill:#81450B}.g253{fill:#6D3907}.g254{fill:#99724A}.g255{fill:#894C11}.g256{fill:#8C6239}.g257{fill:#592D00}.g258{fill:#9B4E00}.g259{fill:#B47A40}.g260{fill:#261300}.g261{fill:#F9FB96}.g262{fill:#5674B9}.g263{fill:#7DA7D9}.g264{fill:#B5D3F6}.g265{fill:#F26522}.g266{fill:#D65A20}.g267{fill:#8A8A8A}.g268{fill:#8E8E8E}.g269{fill:#ACA49E}.g270{fill:#8560A8}.g271{fill:#F26C4F}.g272{fill:#007236}.g273{fill:#00A651}.g274{fill:#616161}.g275{fill:#BE8053}.g276{fill:#575656}.g277{fill:#A87046}.g278{fill:#302F2F}.g279{fill:#679CF1}.g280{fill:#3C81F0}.g281{fill:#26518F}.g282{fill:#CEB858}.g283{fill:#D6C162}.g284{fill:#EDE198}.g285{fill:#E9DC8E}.g286{fill:#E1D07B}.g287{fill:#D9C569}.g288{fill:#F3EBA7}.g289{fill:#F0E6A0}.g290{fill:#DDCA72}.g291{fill:#F5EEAC}.g292{fill:#BFBCBC}.g293{fill:#ACACAC}.g294{fill:#D7D7D7}.g295{fill:#7FFEA1}.g296{fill:#0FFF50}.g297{fill:#64FB8D}.g298{fill:#FD48AB}.g299{fill:#FF1494}.g300{fill:#980F5A}.g301{fill:#F1A367}.g302{fill:#F08B3C}.g303{fill:#8F5526}.g304{fill:#BB77E2}.g305{fill:#AA51DC}.g306{fill:#643283}.g307{fill:#8E11BF}.g308{fill:#B32DE8}.g309{fill:#F13655}.g310{fill:#BF1330}.g311{fill:#00BFF3}.g312{fill:#069AC3}.g313{fill:#B1462E}.g314{fill:#3CB878}.g315{fill:#0D9951}.g316{fill:#DCD331}.g317{fill:#BBD8A8}.g318{fill:#F26D7D}.g319{fill:#9E0B0F}.g320{fill:#9B5D2F}.g321{fill:#CD0C12}.g322{fill:#FCE695}.g323{fill:#C7945B}.g324{fill:#E9C364}.g325{fill:#F6ED5C}.g326{fill:#754C24}.g327{fill:#CDA0DE}.g328{fill:#E7BAF8}.g329{fill:#DDB2ED}.g330{fill:#AE7C4B}.g331{fill:#E1AEF5}.g332{fill:#CDA3DD}.g333{fill:#E3B5F5}.g334{fill:#E8BFF9}.g335{fill:#BE92D0}.g336{fill:#720F0F}.g337{fill:#1C84C8}.g338{fill:#FBFBFB}.g339{fill:#4DC0B8}.g340{fill:#F7941D}.g341{fill:#FECB4B}.g342{fill:#65D7CF}.g343{fill:#DCA825}.g344{fill:#5C5354}.g345{fill:#FFD8AD}.g346{fill:#C8C9CB}.g347{fill:#706C6D}.g348{fill:#38F152}.g349{fill:#636161}.g350{fill:#A7A7A7}.g351{fill:#AA7147}.g352{fill:#FF5900}.g353{fill:#7A0026}.g354{fill:#7A1010}.g355{fill:#7A2910}.g356{fill:#FF5300}.g357{fill:#E9D837}.g358{fill:#39B54A}.g359{fill:#FFF596}.g360{fill:#FDC689}.g361{fill:#685647}.g362{fill:#C79672}.g363{fill:#9EFAB6}.g364{fill:#4CFB7C}.g365{fill:#CB67FC}.g366{fill:#DA92FE}.g367{fill:#343434}.g368{fill:#BB33FF}.g369{fill:#F9F9F9}.g370{fill:#ACB8B7}.g371{fill:#E58A1D}.g372{fill:#B6714B}.g373{fill:#E0BF6C}.g374{fill:#A67DBD}.g375{fill:#7B2E00}.g376{fill:#A0410D}.g377{fill:#EDE10C}.g378{fill:#BD8CBF}.g379{fill:#2CF222}</style></svg>"
            )
        );
        
        return svg;
    }

    // credits to Anoynmice Mouse Dev for the implementation of the trait set conversion to OpenSea metadata JSON format,
    // which is an MIT licensed contract
    function hashToMetadata(uint256 _traitSet) internal view returns (string memory) {
        string memory metadataString;

        for (uint8 i = 0; i < 7; i++) {
            uint256 idx = _traitSet & 0xff;

            metadataString = string(abi.encodePacked(metadataString,'{"trait_type":"',_attributes[i][idx].attr_type,'","value":"',_attributes[i][idx].name,'"}'));
            
            if (i != 6)
                metadataString = string(abi.encodePacked(metadataString, ","));
            
            _traitSet >>= 8;
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }
    
    function tokenURI(uint256 _id) public view override returns (string memory) {
        require(_exists(_id), "TOKEN_DOES_NOT_EXIST");
        
        uint256 hash = _tokens[_id];
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    GoatLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Goat Soup #',
                                    GoatLibrary.toString(_id),
                                    '", "description": "Goat Soup genesis collection is a fully on chain NFT series of 3,744. All the metadata and images are generated and stored 100% on-chain.", "image": "data:image/svg+xml;base64,',
                                    GoatLibrary.encode(
                                        bytes(_generateSvg(hash))
                                    ),
                                    '","attributes":',
                                        hashToMetadata(hash),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }
    
    function clearAttributes() external onlyOwner {
        for(uint8 i = 0; i < 7; i++) {
            delete _attributes[i];
        }
    }
    
    function addAttributes(uint _attributeIndex, Attribute[] memory attributes) external onlyOwner {
        for(uint8 i = 0; i < attributes.length; i++) {
            _attributes[_attributeIndex].push(
                Attribute(
                    attributes[i].name,
                    attributes[i].attr_type,
                    attributes[i].svgPath,
                    attributes[i].pixelCount
                )
            );
        }
    }
}