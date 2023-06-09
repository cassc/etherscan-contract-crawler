// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./utils/Base64.sol";
import "./security/Pausable.sol";
import "./access/Ownable.sol";
import "./token/ERC721A/ERC721A.sol";
import "./CanvasGenerator.sol";
import "./ImageGenerator.sol";
import "./utils/ToString.sol";

/*

      .-``'.          Gen Waves         .'''-.
    .`   .`          by GyozaLabs       '.    '.
_.-'     '._                           _.'     '-._

*/


/**
 * @title GenWaves contract
 * @dev Extends ERC721A implementation (https://www.erc721a.org/)
 */
contract Waves is ERC721A, Ownable, Pausable {

    uint256 public PRICE = 0.04269 ether;
    uint256 public PURCHASE_LIMIT = 1;
    uint256 public MAX_SUPPLY = 222;

    uint16[9] rarities;
    string[9][4] traitValues;

    mapping(uint256 => uint256) private tokenSeed;
    mapping(address => uint256) public whitelist;

    bool publicSale = false;

    error OriginIsNotEOA();
    error NotOnWhitelist();
    error ExceedsPurchaseLimit();
    error SoldOut();
    error WrongAmount();
    error TokenNotFound();

    constructor() ERC721A("Gen Waves", "WVS") {
        //Traits rarities (normal distribution)
        rarities = [
            0,
            75,
            125,
            175,
            225,
            175,
            125,
            75,
            25
        ];

        //Grid size
        traitValues[0] = ['0', '18', '20', '22', '24', '26', '28', '30', '32'];

        //Ellipse size
        traitValues[1] = ['0', '5', '7', '9', '11', '13', '15', '17', '19'];

        //Wave speed
        traitValues[2] = ['0.00', '0.005', '0.007', '0.008' , '0.009', '0.01', '0.011', '0.012', '0.014'];

        //Variation
        traitValues[3] = ['0', '180', '100', '69' , '45', '45', '69', '100', '360'];
    }

    /**
     * @dev Sets the 'paused' state to true
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Sets the 'paused' state to false
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the 'publicSale' state to true
     */
    function openPublicSale() external onlyOwner {
        publicSale = true;
    }

    /**
     * @dev Fills the whitelist array with the addresses passed as arguments
     */
    function fillWhiteList(address[] calldata _users) external onlyOwner {    
       for(uint256 i = 0; i < _users.length; i++){
          address user = _users[i];
          whitelist[user] = PURCHASE_LIMIT;
       }
    }

    /**
     * @dev Mints `numberOfTokens` new tokens
     */
    function mint() external payable whenNotPaused {
        uint256 supply = _totalMinted();
        if (tx.origin != msg.sender) revert OriginIsNotEOA();
        if (!publicSale) {
            if (whitelist[msg.sender] < PURCHASE_LIMIT) revert NotOnWhitelist();
        }
        if (supply + PURCHASE_LIMIT > MAX_SUPPLY) revert SoldOut();
        if (msg.value < PRICE * PURCHASE_LIMIT) revert WrongAmount();

        tokenSeed[supply] = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, supply))
        );
        _safeMint(msg.sender, PURCHASE_LIMIT);
        if (whitelist[msg.sender] > 0) whitelist[msg.sender] -= PURCHASE_LIMIT;    
    }

    /**
     * @dev Returns the base64-encoded metadata for the given tokenId
     */
    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        if(!_exists(tokenId)) revert TokenNotFound();

        (string memory image, string memory svg, string memory properties) = getTraits(tokenSeed[tokenId]);

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"Gen Wave #',
                        ToString.toString(tokenId),
                        '", "description": "Gen Waves is a fully on-chain & interactive piece of art that offers a unique and immersive experience for collectors.", "traits": [',
                        properties,
                        '], "image": "data:image/svg+xml;base64,',
                        image,
                        '", "animation_url":"data:text/html;base64,',
                        svg,
                        '"}'
                    )
                )
            )
        );
    }

    /**
     * @dev Generates a random combination of traits and its corresponding image, animation and metadata
     */
    function getTraits(uint256 seed) private view returns(string memory image, string memory svg, string memory properties) {
        uint16[5] memory randomInputs = expand(seed, 5);
        uint16[4] memory traits;

        //Base color
        string memory baseColor = ToString.toString(randomInputs[0] % 360);
        //Grid width
        traits[0] = getRandomIndex(rarities, randomInputs[1]);
        //Ellipse size
        traits[1] = getRandomIndex(rarities, randomInputs[2]);
        //Wave speed
        traits[2] = getRandomIndex(rarities, randomInputs[3]);
        //Color variation
        traits[3] = getRandomIndex(rarities, randomInputs[4]);

        //Render image
        string memory _image = ImageGenerator.createWave(baseColor, traitValues[1][traits[1]],traitValues[3][traits[3]]);
        image = Base64.encode(abi.encodePacked(_image));

        //Render animation
        string memory _svg = CanvasGenerator.generateCustomCanvas(baseColor, traitValues[0][traits[0]],traitValues[1][traits[1]],traitValues[2][traits[2]],traitValues[3][traits[3]]);
        svg = Base64.encode(abi.encodePacked(_svg));

        //Pack properties (put 1 after the last property for JSON to be formed correctly)
        bytes memory _properties = abi.encodePacked(
            packMetaData("Base Color", baseColor, 0),
            packMetaData("Grid Size", _getTrait(0, traits[0]), 0),
            packMetaData("Ellipse Size", _getTrait(1, traits[1]), 0),
            packMetaData("Wave Speed", _getTrait(2, traits[2]), 0),
            packMetaData("Color Variation", _getTrait(3, traits[3]), 1)
        );
        properties = string(abi.encodePacked(_properties));
        return (image, svg, properties);
    }

    /**
     * @dev Generates a random number for indexing an array position, credits to Anonymice
     */
    function getRandomIndex(uint16[9] memory attributeRarities, uint256 randomNumber) private pure returns (uint16 index) {
        //1000 is the sum of the rarities
        uint16 random10k = uint16(randomNumber % 1000);
        uint16 lowerBound;
        for (uint16 i = 1; i <= 9; i++) {
            uint16 percentage = attributeRarities[i];
            if (random10k < percentage + lowerBound && random10k >= lowerBound) {
                return i;
            }
            lowerBound = lowerBound + percentage;
        }
        revert();
    }
    
    /**
     * @dev Generates an array of random numbers based on a random number
     */
    function expand(uint256 _randomNumber, uint256 n) private pure returns(uint16[5] memory expandedValues) {
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = bytes2uint(keccak256(abi.encode(_randomNumber, i)));
        }
        return expandedValues;
    }

    /**
     * @dev Converts bytes32 to uint16
     */
    function bytes2uint(bytes32 _a) private pure returns (uint16) {
        return uint16(uint256(_a));
    }

    /**
     * @dev Gets the attribute name for the properties of the token by its index
     */
    function _getTrait(uint256 _trait, uint256 index)
        private
        view
        returns (string memory)
    {
        return traitValues[_trait][index];
    }

    /**
     * @dev Bundle metadata so it follows the standard
     */
    function packMetaData(string memory name, string memory svg, uint256 last) private pure returns (bytes memory) {
        string memory comma = ",";
        if (last > 0) comma = "";
        return
        abi.encodePacked(
            '{"trait_type": "',
            name,
            '", "value": "',
            svg,
            '"}',
            comma
        );
    }

    /**
     * @dev Transfers all the contract balance to the owner address
     */
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

}