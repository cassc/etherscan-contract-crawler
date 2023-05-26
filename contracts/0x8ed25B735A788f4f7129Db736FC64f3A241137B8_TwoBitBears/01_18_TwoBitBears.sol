// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "./BearComposition.sol";
import "./IBearDetail.sol";

contract TwoBitBears is ERC721Enumerable, IBearDetail, Ownable, ReentrancyGuard {

    /*
                           #(###                                                
                          ###.,,#   ###########      ####                       
                           ## ,,##################%#* .(###                     
                             ########################,,*##                      
                           /##########################                          
                          ########@####################          * **           
                         ##############(/(######%@######        #,#,#*%         
                        #########@@#,,@  &@,,#&@@#######*      ##*,,,%#.        
                        ##########,,,,@&&&@,,,##########%      ###*,*#%#        
                        .########(,,,,,,@,,,,,,#########      #########,        
                          ########*****@@@*,***########*     ##########         
                            ,%######********(######%#%   (############          
                            %%%%%%#%############%#%%%%###############           
                        ###%%%%%%%%%%%%%%%%%%%%%%%%%%%%############             
                     #####%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%########               
                   ######%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#%                    
                 #######%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#                     
               #######(%%%%%%%%%%%%************(%%%%%%%%%%%                     
             .########%%%%%%%%%%**,,,,,,,,,,,******%%%%%%%%%                    
            ##########%%%%%%%%*,,,,,,,,,,,,,,,*******%%%%%%%%                   
           (#########%%%%%%%/*,,,,,,,,,,,,,,,,,*******#%%%%%%                   
           (#########%%%%%%*,,,,,,,,,,,,,,,,,,,,*******%%%%%%#                  
           *#**%####%%%%%%%*,,,,,,,,,,,,.,,,,,,,,*******#%%%%%                  
             * **   %%%%%%*,,,,,,,,,,,......,,,,,*******%%%%%%                  
                    %%%%%%*,,,,,,,,,,,,,.,,,,,,,,*******%%%%%%                  
                    %%%%%%%*,,,,,,,,,,,,,,,,,,,,********#%%%%%                  
                     %%%%%%(**,,,,,,,,,,,,,************#%%%%%                   
                     *%%%%%%#***,,,,,,,***************%%%%%%%                   
                      %%%%%%%%%*********************%%%%%%%%                    
                       %%%%%%%%%%%#(************%%%%%%%%%%%#                    
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                     
                        ####%%%%%%%%%%%%%%%%%%%%%%%%%%%###                      
                         #########%%%%%%  %%%%%%#########                       
                          ############%%  %%############(                       
                           #############  (#############                        
                          ,,############,,,############,.                       
                     ,,/####(##########,,,,*########(######,,,                  
                        ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.                     
    */

    using Counters for Counters.Counter;
    using Strings for uint256;

    uint8 public constant decimals = 0;

    /// @dev Counter for token Ids
    Counters.Counter private _tokenIds;

    /// @dev Price for one bear
    uint256 public constant bearPrice = 0.05 ether;

    /// @dev Maximum bears that will be minted
    uint256 private constant _maxTokens = 5000;

    /// @dev Maximum quantity of bears that will be minted at once
    uint256 public constant maximumMintQuantity = 10;

    uint256 private _seed;
    bool private _reveal;

    // Mapping of TokenIds to generated Bear Detail
    mapping(uint256 => IBearDetail.Detail) private _tokenIdToBearDetails;

    mapping(uint256 => string) private _giftTokenURIs;

    string[4] private _species = ["Brown Bear", "Black Bear", "Polar Bear", "Panda Bear"];
    string[4] private _moods = ["Happy", "Hungry", "Sleepy", "Grumpy"];
    string[18] private _names = ["Deafbeef", "Benyamin", "Tropo", "Karkai", "Beanie", "Itzel", "Hunter", "Fvck", "GFunk", "Pak", "xCopy", "Deeze", "Robness", "Gargamel", "Cole", "Farokh", "Snofro", "Squarci"];
    string[18] private _families = ["Winkelmann", "Hirst", "Watkinson", "Hall", "Rainaud", "Sachs", "Pleasr", "Vee", "Aversano", "Furie", "Stark", "Hofmann", "Nines", "Bellini", "Aoki", "Davis", "Cherniak", "Timpers"];

    constructor() ERC721("TwoBitBears", "TBB") {
        _seed = uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number-1), block.timestamp)));
        _reveal = false;
    }

    function createBear(uint256 quantity) public payable nonReentrant {
        require(quantity > 0 && quantity <= maximumMintQuantity, "Quantity is invalid");
        require(msg.value >= bearPrice * quantity, "Ether sent is not correct");
        require(_tokenIds.current() + quantity <= _maxTokens, "Maximum Bears exceeded");

        _seed = uint256(keccak256(abi.encodePacked(_seed >> 1, msg.sender, blockhash(block.number-1), block.timestamp)));
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            _tokenIds.increment();
            _tokenIdToBearDetails[tokenId] = _createDetailFromRandom(_seed, tokenId);
            if (i + 1 < quantity) {
                _seed = uint256(keccak256(abi.encodePacked(_seed >> 1)));
            }
        }
    }

    /// @inheritdoc IBearDetail
    function details(uint256 tokenId) external view override returns (Detail memory detail) {
        require(_exists(tokenId) && tokenId < _maxTokens, "Nonexistent token");
        detail = _tokenIdToBearDetails[tokenId];
    }

    function giftBear(uint256 tokenId, string memory tokenUri) public onlyOwner {
        require(tokenId >= _maxTokens && tokenId < _maxTokens + 20, "Invalid gift tokenId");
        if (bytes(_giftTokenURIs[tokenId]).length == 0) {
            _safeMint(msg.sender, tokenId);
        }
        _giftTokenURIs[tokenId] = tokenUri;
    }

    function revealBears() public onlyOwner {
        _reveal = true;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        if (bytes(_giftTokenURIs[tokenId]).length > 0) {
            return _giftTokenURIs[tokenId];
        }
        if (_reveal == false) {
            return string(abi.encodePacked(
                _baseURI(),
                Base64.encode(abi.encodePacked(
                    '{"name":"Rendering Bear #', (tokenId + 1).toString(), '...","description":"Unrevealed","image":"ipfs://QmTBgvAvbYFM5S3UK2VLCLSFiBbvAvto6hERNmQghXSENR"}'
                ))
            ));
        }

        return _tokenUriForDetail(_tokenIdToBearDetails[tokenId], tokenId);
    }

    function _tokenUriForDetail(Detail memory detail, uint256 tokenId) private view returns (string memory) {
        return string(abi.encodePacked(
            _baseURI(),
            Base64.encode(abi.encodePacked(
                '{"name":"',
                    _nameFromDetail(detail, tokenId),
                '","description":"',
                    _moods[detail.moodIndex], ' ', _species[detail.speciesIndex],
                '","attributes":[{"',
                    _attributesFromDetail(detail),
                '"}],"image":"',
                    "data:image/svg+xml;base64,", Base64.encode(BearComposition.createSvg(detail)),
                '"}'
            ))
        ));
    }

    /// @notice Send funds from sales to the team
    function withdrawAll() public payable onlyOwner {
        uint256 amount = address(this).balance;
        payable(0xB87A5d10d52c415FfE213D4a2242eD69761024B6).transfer(amount / 2);
        payable(0x6Ba003943E62BeA4D1c416E5663a5fA746749Fd6).transfer(amount / 2);
    }

    function _baseURI() internal pure virtual override returns (string memory) {
        return "data:application/json;base64,";
    }

    function _createDetailFromRandom(uint256 random, uint256 tokenId) private view returns (Detail memory) {
        bytes memory randomPieces = abi.encodePacked(random);
        uint256 increment = (tokenId % 20) + 1;
        uint256 speciesIndex = BearComposition.fourIndexFromRandom(uint8(randomPieces[9 + increment]));
        return Detail(
            block.timestamp,
            uint8(uint8(randomPieces[2 + increment]) % _names.length),
            uint8(BearComposition.fourIndexFromRandom(uint8(randomPieces[increment]))),
            uint8(uint8(randomPieces[8 + increment]) % _families.length),
            uint8(speciesIndex),
            BearComposition.colorTopFromRandom(randomPieces, 6 + increment, 3 + increment, 4 + increment, speciesIndex),
            BearComposition.colorBottomFromRandom(randomPieces, 5 + increment, 7 + increment, 1 + increment, speciesIndex)
        );
    }

    function _attributesFromDetail(Detail memory detail) private view returns (string memory) {
        return string(abi.encodePacked(
            'trait_type":"Species","value":"', _species[detail.speciesIndex],
            '"},{"trait_type":"Mood","value":"', _moods[detail.moodIndex],
            '"},{"trait_type":"Name","value":"', _names[detail.nameIndex],
            '"},{"trait_type":"Family","value":"', _families[detail.familyIndex],
            '"},{"trait_type":"Realistic Head Fur","value":"', BearComposition.svgColor(detail.topColor),
            '"},{"trait_type":"Realistic Body Fur","value":"', BearComposition.svgColor(detail.bottomColor)
        ));
    }

    function _nameFromDetail(Detail memory detail, uint256 tokenId) private view returns (string memory) {
        return string(abi.encodePacked(_names[detail.nameIndex], ' ', _families[detail.familyIndex], ' the ', _moods[detail.moodIndex], ' ', _species[detail.speciesIndex], ' #', (tokenId + 1).toString()));
    }
}