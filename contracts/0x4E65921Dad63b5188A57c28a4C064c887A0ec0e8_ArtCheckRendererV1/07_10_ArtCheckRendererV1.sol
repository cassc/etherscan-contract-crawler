// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "erc721a-upgradeable/contracts/interfaces/IERC721AUpgradeable.sol";
import "./library/Base64.sol";

contract ArtCheckRendererV1 is Initializable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for uint160;

    IERC721AUpgradeable public tokenContract;

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                                set state
    ⌐◨—————————————————————————————————————————————————————————————◨ */
    address private _owner;
    string public description;
    string public name;
    uint256 staticBlockNum;
    string public contractImage;
    string public sellerFeeBasisPoints;
    string public sellerFeeRecipient;
    string public animationUrl;
    string[] public checkColors; 


    function initialize(address owner) public initializer {
        _owner = owner;
        description = "if you don't like the art, don't buy the art";
        name = "Art \xE2\x9C\x93";
        staticBlockNum = 33663;
        contractImage = "ipfs://QmRZSsoXjvhZor8My4q7EKVQUFoVr3pneKbjdbj44KnjGg";
        sellerFeeBasisPoints = "250";
        checkColors = ['E84AA9','F2399D','DB2F96','E73E85','FF7F8E','FA5B67','E8424E','D5332F','C23532','F2281C','D41515','9D262F','DE3237','DA3321','EA3A2D','EB4429','EC7368','FF8079','FF9193','EA5B33','D05C35','ED7C30','EF9933','EF8C37','F18930','F09837','F9A45C','F2A43A','F2A840','F2A93C','FFB340','F2B341','FAD064','F7CA57','F6CB45','FFAB00','F4C44A','FCDE5B','F9DA4D','F9DA4A','FAE272','F9DB49','FAE663','FBEA5B','A7CA45','B5F13B','94E337','63C23C','86E48E','77E39F','5FCD8C','83F1AE','9DEFBF','2E9D9A','3EB8A1','5FC9BF','77D3DE','6AD1DE','5ABAD3','4291A8','33758D','45B2D3','81D1EC','A7DDF9','9AD9FB','A4C8EE','60B1F4','2480BD','4576D0','3263D0','2E4985','25438C','525EAA','3D43B3','322F92','4A2387','371471','3B088C','6C31D7','9741DA','FFFFFF'];
    }

    function contractURI() public view
      returns (string memory) {   
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "',
                                name,
                                '", "description": "',
                                description,
                                '", "image": "',
                                contractImage,
                                '", "seller_fee_basis_points": "',
                                sellerFeeBasisPoints,
                                '", "seller_fee_recipient": "',
                                sellerFeeRecipient,
                                '", "animation_url": "',
                                animationUrl,
                                '"}'
                            )
                        )
                    )
                )
            )
        );
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {   
        require (tokenContract.totalSupply() >= tokenId, "Check your head. This token does't exist.");
        return constructTokenURI(tokenId);
    }

    function constructTokenURI(
        uint256 tokenId
    ) internal view returns (string memory) {                    
        
        uint256[4] memory tokenDNA = [
            random(tokenId, checkColors.length - 1, staticBlockNum * 99), // check color
            random(tokenId, checkColors.length - 1, staticBlockNum * 333), // check color #2            
            random(tokenId, 2, staticBlockNum * 555), // is animated
            random(tokenId, 2, staticBlockNum * 777) // is gradient
        ];
        string memory image = string(
            abi.encodePacked(Base64.encode(bytes(getTokenIdSvg(tokenDNA))))
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "',
                                    name,
                                    ' ',
                                    abi.encodePacked(
                                        string(tokenId.toString())
                                    ),
                                    '","image": "data:image/svg+xml;base64,',
                                    abi.encodePacked(string(image)),
                                    '","description": "',
                                    description,
                                    '","attributes": ',
                                    getTokenIdMetadata(tokenDNA),
                                    '}'
                                )
                            )
                        )
                    )
                )
            );
    }

    function getTokenIdSvg(uint256[4] memory tokenDNA) internal view returns (string memory svg) {   
        string memory gradient = "";
        string memory singleColor = checkColors[tokenDNA[0]];
        string memory checkColor = string(abi.encodePacked('#', singleColor));
        string memory animationDuration = "0";
        if (tokenDNA[3] == 1) {
            gradient = getGradient(tokenDNA);
            checkColor = "url(#grad)";
        }
        if (tokenDNA[2] == 1) {
            animationDuration = "16s";
        }

        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="2000" height="2000" fill="none" viewBox="0 0 100 100" shape-rendering="geometricPrecision"><path fill="#000" d="M0 0h100v100H0z"/><path fill="#fff" d="M39.472 59.124a4.81 4.81 0 0 0 1.598-.256 4.395 4.395 0 0 0 1.305-.744c.39-.326.708-.712.952-1.16h.073v1.953h3.562V49.95c0-.878-.232-1.647-.695-2.305-.456-.66-1.098-1.167-1.928-1.525-.83-.366-1.81-.55-2.94-.55-1.147 0-2.139.18-2.976.538-.83.35-1.48.837-1.952 1.464a4.088 4.088 0 0 0-.793 2.146l-.012.147h3.257l.024-.11c.09-.423.33-.773.72-1.049.39-.277.919-.415 1.586-.415.7 0 1.232.171 1.598.513.366.333.549.788.549 1.366v3.965c0 .455-.122.866-.366 1.232a2.481 2.481 0 0 1-.988.854 3.174 3.174 0 0 1-1.415.305c-.618 0-1.11-.135-1.477-.403-.365-.276-.548-.655-.548-1.134v-.025c0-.463.178-.834.536-1.11.358-.285.879-.447 1.562-.488l4.562-.293v-2.22l-5.099.317c-1.082.073-2 .273-2.757.598-.756.325-1.334.773-1.732 1.342-.399.561-.598 1.24-.598 2.037v.025c0 .764.183 1.447.549 2.049.374.594.89 1.061 1.55 1.403.658.333 1.422.5 2.293.5Zm8.796-.207h3.562v-7.32c0-.634.11-1.171.33-1.61.22-.44.536-.773.951-1 .415-.228.915-.342 1.5-.342.26 0 .505.02.733.061.227.032.414.077.56.134v-3.135a2.881 2.881 0 0 0-.463-.098 4.152 4.152 0 0 0-.56-.036c-.765 0-1.404.224-1.916.67-.513.448-.866 1.074-1.062 1.88h-.073v-2.282h-3.562v13.078Zm14.785.268c.375 0 .704-.016.989-.049a9.22 9.22 0 0 0 .731-.085v-2.61c-.105.015-.22.032-.341.048a6.468 6.468 0 0 1-.427.012c-.537 0-.943-.118-1.22-.354-.268-.244-.403-.67-.403-1.28v-6.344h2.392v-2.684h-2.392v-3.196h-3.598v3.196h-1.818v2.684h1.818v6.734c0 1.399.35 2.403 1.049 3.013.7.61 1.773.915 3.22.915Z"/>',
                    gradient,
                    '<path fill="',
                    checkColor,
                    '" fill-rule="evenodd" d="M68.166 37.5a1.554 1.554 0 0 1 1.33.746 1.56 1.56 0 0 1 1.882 1.882 1.558 1.558 0 0 1 0 2.659 1.56 1.56 0 0 1-1.882 1.882 1.583 1.583 0 0 1-.736.629 1.562 1.562 0 0 1-1.923-.63 1.56 1.56 0 0 1-1.882-1.881 1.558 1.558 0 0 1 0-2.66 1.56 1.56 0 0 1 1.882-1.881 1.554 1.554 0 0 1 1.33-.746Z" clip-rule="evenodd"><animateTransform attributeName="transform" type="rotate" from="0 68.1 41.4" to="360 68.1 41.4" dur="',
                    animationDuration,
                    '" repeatCount="indefinite"/></path>',
                    '<path fill="#000" d="m69.737 40.173-1.806 2.709a.313.313 0 0 1-.433.085l-.859-.849a.313.313 0 1 1 .441-.443l.542.542 1.583-2.39a.319.319 0 0 1 .44-.093.316.316 0 0 1 .093.44Z"/></svg>'
                )
            );
    }

    function getGradient(uint256[4] memory tokenDNA) internal view returns (string memory gradient) {
        string memory color1 = checkColors[tokenDNA[0]];
        string memory color2 = checkColors[tokenDNA[1]];
        gradient = string(
            abi.encodePacked(
                '<defs><linearGradient id="grad" x1="64.5" x2="72" y1="37.5" y2="42.5" gradientUnits="userSpaceOnUse"><stop stop-color="#',
                color1,
                '"/><stop offset="1" stop-color="#',
                color2,
                '"/></linearGradient></defs>'
            )
        );
    }


    function getTokenIdMetadata(uint256[4] memory tokenDNA) internal view returns (string memory metadata) {
        string memory bgColorName = "Warm";
        if (tokenDNA[0] == 1) {
            bgColorName = "Cool";
        }
        string memory animated = "false";
        if (tokenDNA[2] == 1) {
            animated = "true";
        }
        string memory gradient = "false";
        if (tokenDNA[1] == 1) {
            gradient = "true";
        }
        metadata = string(
            abi.encodePacked(
                '{"trait_type":"Check color", "value":"#',
                checkColors[tokenDNA[1]],
                '"},',
                '{"trait_type":"Animated", "value":"',
                animated,
                '"},',
                '{"trait_type":"Gradient", "value":"',
                gradient,
                '"}'
            )
        );

        return string(abi.encodePacked('[', metadata, ']'));
    }  

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                           utility functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */


    function random(uint256 input, uint256 max, uint256 randomNum) internal pure returns (uint256) {
        return (uint256(keccak256(abi.encodePacked((input * randomNum) + (input * max) + input))) % max);
    }

    function isAnimated(uint256 tokenId) internal pure returns (uint256) {
        uint256 num = tokenId * 16550210;
        if (num % 9 < 2) {
            return 1;
        } else {
            return 0;
        }
    }

    function setTokenContract(IERC721AUpgradeable _tokenContract) public {
        require(msg.sender == _owner, "Rejected: not owner");
        tokenContract = _tokenContract;
    }

    function setCheckColors(string[] memory _checkColors) public {
        require(msg.sender == _owner, "Rejected: not owner");
        checkColors = _checkColors;
    }

    function setAnimationUrl(string memory _animationUrl) public {
        require(msg.sender == _owner, "Rejected: not owner");
        animationUrl = _animationUrl;
    }

    function setName(string memory _name) public {
        require(msg.sender == _owner, "Rejected: not owner");
        name = _name;
    }

    function setDescription(string memory _description) public {
        require(msg.sender == _owner, "Rejected: not owner");
        description = _description;
    }

    function setContractImage(string memory _contractImage) public {
        require(msg.sender == _owner, "Rejected: not owner");
        contractImage = _contractImage;
    }

    function setSellerFeeBasisPoints(string memory _sellerFeeBasisPoints) public {
        require(msg.sender == _owner, "Rejected: not owner");
        sellerFeeBasisPoints = _sellerFeeBasisPoints;
    }

    function setSellerFeeRecipient(string memory _sellerFeeRecipient) public {
        require(msg.sender == _owner, "Rejected: not owner");
        sellerFeeRecipient = _sellerFeeRecipient;
    }
}