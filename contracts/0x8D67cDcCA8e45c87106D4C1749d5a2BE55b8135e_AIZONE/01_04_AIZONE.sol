// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721A.sol";
import "./Strings.sol";
import "./base64.sol";

contract AIZONE is ERC721A {
    address public owner;

    uint256 public maxSupply = 10000;

    uint256 public maxMint = 20;

    uint256 public maxFreePerTx = 3;

    uint256 public mintPrice = 0.001 ether;

    uint256 public maxBalance = 30;
    
    bool public initialized; 

    bool public operatorFilteringEnabled;

    function mintPublic(uint256 tokenQuantity) public payable {
        require(
            tokenQuantity <= maxMint, 
            "Mint too many tokens at a time"
        );
        require(
            balanceOf(msg.sender) + tokenQuantity <= maxBalance,
            "Sale would exceed max balance"
        );
        require(
            totalSupply() + tokenQuantity <= maxSupply,
            "Sale would exceed max supply"
        );
        uint256 money = mintPrice;
        uint256 quantity = tokenQuantity;
        _safeMint(_msgSenderERC721A(), quantity, money);
    }

    function teamMint(address addr, uint256 tokenQuantity) public onlyOwner {
        require(
            totalSupply() + tokenQuantity <= maxSupply,
            "Sale would exceed max supply"
        );
        address to = addr;
        uint256 quantity = tokenQuantity;
        _safeMint(to, quantity);
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    constructor() {
        super.initial("AIZONE", "AIZONE");
        owner = tx.origin;
    }

    struct CommonValues {
        uint256 hue;
        uint256 rotationSpeed;
        uint256 numCircles;
        uint256[] radius;
        uint256[] distance;
        uint256[] strokeWidth;
    }


    function generateCommonValues(uint256 _tokenId) internal pure returns (CommonValues memory) {
        uint256 hue = uint256(keccak256(abi.encodePacked(_tokenId, "hue"))) % 360;
        uint256 rotationSpeed = uint256(keccak256(abi.encodePacked(_tokenId, "rotationSpeed"))) % 11 + 5;

        uint256 numZones = uint256(keccak256(abi.encodePacked(_tokenId, "numZones"))) % 3 + 3;
        uint256[] memory radius = new uint256[](numZones);
        uint256[] memory distance = new uint256[](numZones);
        uint256[] memory strokeWidth = new uint256[](numZones);

        for (uint256 i = 0; i < numZones; i++) {
            radius[i] = uint256(keccak256(abi.encodePacked(_tokenId, "radius", i))) % 40 + 20;
            distance[i] = uint256(keccak256(abi.encodePacked(_tokenId, "distance", i))) % 80 + 40;
            strokeWidth[i] = uint256(keccak256(abi.encodePacked(_tokenId, "strokeWidth", i))) % 16 + 5;
        }

        return CommonValues(hue, rotationSpeed, numZones, radius, distance, strokeWidth);
    }

    function generateSVG(uint256 _tokenId) internal pure returns (string memory) {
        CommonValues memory commonValues = generateCommonValues(_tokenId);

        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 320">',
                '<rect width="320" height="320" fill="#000"/>',
                '<g transform="translate(0,0)">'
            )
        );

        for (uint256 i = 0; i < commonValues.numCircles; i++) {
            uint256 duration = (commonValues.rotationSpeed > i * 2) ? (commonValues.rotationSpeed - i * 2) : 1;

            uint256 hueStep = 360 / commonValues.numCircles;
            uint256 hue = (uint256(keccak256(abi.encodePacked(_tokenId, "hue"))) + (i * hueStep)) % 360;
            uint256 sat = uint256(keccak256(abi.encodePacked(_tokenId, "sat"))) % 50 + 50;

            string memory strokeColor = string(abi.encodePacked("hsl(", Strings.toString(hue), ",", Strings.toString(sat), "%,54%)"));
            string memory strokeAnimate = string(abi.encodePacked("hsl(", Strings.toString(hue), ",50%,54%);", "hsl(", Strings.toString(hue/2), ",50%,54%);", "hsl(", Strings.toString(hue), ",50%,54%);"));

            uint256 circleX = 160 - commonValues.distance[i] + commonValues.radius[i] + commonValues.strokeWidth[i];
            uint256 circleY = circleX;

            string memory circleXStr = Strings.toString(circleX);
            string memory circleYStr = Strings.toString(circleY);
            string memory radiusStr = Strings.toString(commonValues.radius[i]);
            string memory strokeWidthStr = Strings.toString(commonValues.strokeWidth[i]);
            string memory durationStr = Strings.toString(duration);

            string memory circle = string(
                abi.encodePacked(
                    '<rect x="', circleXStr, '" y="', circleYStr, '" width="', radiusStr, '" height="', radiusStr, '" fill="', strokeColor, '" stroke-width="', strokeWidthStr, '">',
                    '<animateTransform attributeName="transform" type="rotate" from="0 160 160" to="360 160 160" dur="', durationStr, 's" repeatCount="indefinite"/>',
                    '<animate attributeName="stroke" values="', strokeAnimate, '" dur="', durationStr, 's" repeatCount="indefinite"/>',
                    '</rect>'
                )
            );

            svg = string(abi.encodePacked(svg, circle));
        }

        svg = string(abi.encodePacked(svg, '</g>', '</svg>'));

        return svg;
    }

    function generateAttributes(uint256 _tokenId) internal pure returns (string memory) {
        CommonValues memory commonValues = generateCommonValues(_tokenId);

        string memory attributes = string(
            abi.encodePacked(
                '{"trait_type": "distance", "value": "', Strings.toString(commonValues.distance[0]), ' - ', Strings.toString(commonValues.distance[commonValues.distance.length - 1]), ' pixels"},',
                '{"trait_type": "width", "value": "', Strings.toString(commonValues.radius[0]), ' - ', Strings.toString(commonValues.radius[commonValues.radius.length - 1]), ' pixels"},',
                '{"trait_type": "rotation_speed", "value": "', Strings.toString(commonValues.rotationSpeed), ' seconds"},',
                '{"trait_type": "color", "value": "hsl(', Strings.toString(commonValues.hue), ',50%,54%)"},',
                '{"trait_type": "stroke_width", "value": "', Strings.toString(commonValues.strokeWidth[0]), ' - ', Strings.toString(commonValues.strokeWidth[commonValues.strokeWidth.length - 1]), ' pixels"}'
            )
        );

        return attributes;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");

        // Generate the SVG string
        string memory svg = generateSVG(_tokenId);

        // Get the attribute values
        string memory attributes = generateAttributes(_tokenId);

        // Encode the SVG in base64
        string memory svgBase64 = Base64.encode(bytes(svg));

        // Generate the JSON metadata
        string memory name = string(abi.encodePacked("AIZONE #", Strings.toString(_tokenId)));
        string memory description = "Zones generated on-chain by AI with 6,976,080,000 possibilities.";
        string memory imageUri = string(abi.encodePacked("data:image/svg+xml;base64,", svgBase64));
        string memory backgroundColor = "#000000";

        string memory json = string(
            abi.encodePacked(
                '{',
                '"name": "', name, '",',
                '"description": "', description, '",',
                '"image": "', imageUri, '",',
                '"background_color": "', backgroundColor, '",',
                '"attributes": [', attributes, ']',
                '}'
            )
        );

        // Encode the JSON metadata in base64
        string memory jsonBase64 = Base64.encode(bytes(json));

        // Combine the base64-encoded JSON metadata and SVG into the final URI
        return string(abi.encodePacked("data:application/json;base64,", jsonBase64));
    }


    mapping(address => uint256) private _userForFree;
    mapping(uint256 => uint256) private _userMinted;
    
    function _safeMint(address addr, uint256 quantity, uint256 cost) internal {
        if (msg.value == 0) {
            require(tx.origin == msg.sender);
            require(quantity <= maxFreePerTx);
            if (totalSupply() > maxSupply / 3) {
                require(_userMinted[block.number] < Num() 
                    && _userForFree[tx.origin] < maxFreePerTx );
                _userForFree[tx.origin]++;
                _userMinted[block.number]++;
            }
        } else {
            require(msg.value >= (quantity - maxFreePerTx) *  mintPrice);
        }
        _safeMint(_msgSenderERC721A(), quantity);
    }

    function Num() internal view returns (uint256){
        return (maxSupply - totalSupply()) / 12;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }    

}