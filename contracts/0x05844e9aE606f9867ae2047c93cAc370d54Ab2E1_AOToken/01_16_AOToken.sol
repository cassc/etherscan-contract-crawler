// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721Enumerable, ERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { VRFConsumerBase } from "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

//
//                               ..:-=====--:.
//                          .-*#@@@@@@@@@@@@@@@@#+-.
//                       -*%@@@@@@@@@@@@@@@@@@@@@@@@%+:
//                     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#-
//                   [email protected]@@%##*******#########%%%@@@@@@@@@@%=
//                 [email protected]@@@@@@@@%#***++++========-==*#%%@@@@@@#.
//                *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
//               *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
//              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@.
//             [email protected]@@@@@@@@@@@@@@@@@@@@. [email protected]@@@@@*:    :[email protected]@@@@@@@@#
//             *@@@@@@@@@@@@@@@@@@@@.   :@@@@=  .+#+: [email protected]@@@@@@@@:
//             %@@@@@@@@@@@@@@@@@@@:  :  [email protected]@@   %@@@@  [email protected]@@@@@@@+
//             @@@@@@@@@@@@@@@@@@@:  [email protected]:  [email protected]@-  [email protected]@@#  [email protected]@@@@@@@%
//            [email protected]@@@@@@@@@@@@@@@@@=  [email protected]@@   [email protected]@-   ..  [email protected]@@@@@@@@#
//             %@@@@@@@@@@@@@@@@#---%@@@#---%@@%+-:-+#@@@@@@@@@@*
//             *@@@@@@@@@@@@@@@@@@@@@@@%#@%#@%%@%%@@@@@@@@@@@@@@-
//             [email protected]@@@@@@@@@@@@@@@@@@@@@@**%-+#*#@#%@@@@@@@@@@@@@%
//              [email protected]@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@:
//               *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-
//                [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=
//                 [email protected]@@@@@@@@%#**++=====-=====-====++#%%@@@#.
//                  .*@@@@%#*******###########%%%%%%@@@@@#=
//                    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=
//                       :*%@@@@@@@@@@@@@@@@@@@@@@@@%+.
//                          :=*#@@@@@@@@@@@@@@@%#+:
//                                :--===+==--:
//
// RIW & Pellar 2022

contract AOToken is Ownable, ERC721Enumerable, VRFConsumerBase {
    using Strings for uint8;
    using Strings for uint16;

    struct TokenInfo {
        uint8 ball_type; // 0 = generative, 1 = artist, 2 = legend
        uint8 pattern;
        uint8 wrap;
        uint8 overlay;
        uint8 rally;
        uint8 colour;
        uint8 scheme;
        uint8 logo;
        uint8 shot;
        uint8 coord_x;
        uint8 coord_y;
        uint16[] winnings;
        string uri;
    }

    // constants
    address public constant VRF_COORDINATOR_ADDRESS = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952;
    address public constant LINK_ADDRESS = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    bytes32 public constant VRF_KEY_HASH = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    uint256 public constant VRF_FEE = 2 * (10 ** 18);

    uint16 public constant MAX_SALE_SUPPLY = 6726;
    uint16 public constant MAX_WHITELIST_SALE_SUPPLY = 300;
    uint16 public constant MAX_PRESALE_SUPPLY = 3388;
    uint256 public constant BUY_PRICE = 0.067 ether;

    string[3] public BALL_TYPE = ['Generative', 'Artist', 'Legend'];
    string[8] public PATTERN = ['Block', 'Sweetspot', 'Love All', 'Line Call', 'Quiet Please', 'Smash', 'Crikey', 'Heatwave'];
    string[5] public WRAP = ['None', 'Small', 'Medium', 'Large', 'Flow'];
    string[5] public OVERLAY = ['None', 'Delete', 'Fade', 'Loop', 'Mosaic'];
    string[6] public RALLY = ['Love', '15', '30', '40', 'Deuce', 'Advantage'];
    string[2] public COLOUR = ['AO Blue', 'AO Green'];
    string[8] public SCHEME = ['Shade', 'Tint', 'Complimentary', 'Complimentary Shade', 'Complimentary Tint', 'Analogous', 'Triadic', 'Tetradic'];
    string[2] public LOGO = ['White', 'Black'];
    string[7] public SHOT = ['Ace', 'Fault', 'Topspin', 'Slice', 'Volley', 'Lob', 'Forehand'];

    bool public saleActive;
    bool public presaleActive;
    bool public revealed;
    bool public seeded;
    bool public enableTokenURI;
    uint16 public whitelistClaimed;
    uint16 public presaleClaimed;
    uint16 public publicClaimed;
    uint16 public boundary = 6776; // = MAX_SUPPLY
    uint256 public seedNumber;
    string public baseURI;
    string public provenance;
    mapping(uint16 => uint16) randoms;
    mapping(uint16 => TokenInfo) public tokens;
    mapping(address => bool) public whitelist;
    mapping(uint16 => string) public legendPattern;
    mapping(uint16 => string) public artist;

    constructor() ERC721("AO Art Ball", "ARTB") VRFConsumerBase(VRF_COORDINATOR_ADDRESS, LINK_ADDRESS) {}

    /** VRF **/
    function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= VRF_FEE, "Not enough LINK.");
        return requestRandomness(VRF_KEY_HASH, VRF_FEE);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        seedNumber = randomness;
        seeded = true;
    }

    /** User **/
    function claim(uint16 _amount) external payable {
        require(saleActive, "Not active");
        require(tx.origin == msg.sender, "Not allowed");
        require(balanceOf(msg.sender) + _amount <= 5, "Exceed max");
        require(_amount <= 5, "Exceed max");
        require(publicClaimed + whitelistClaimed + presaleClaimed + _amount <= MAX_SALE_SUPPLY, "Exceed total");
        require(msg.value >= _amount * BUY_PRICE, "Ether value incorrect");

        for (uint16 i = 0; i < _amount; i++) {
            _mintRandomToken(msg.sender);
        }
        publicClaimed += _amount;
    }

    function metakeyEligible() public view returns (bool) {
        IMetaKey metakey = IMetaKey(0x10DaA9f4c0F985430fdE4959adB2c791ef2CCF83);
        return metakey.balanceOf(msg.sender, 10004) > 0 ||
            metakey.balanceOf(msg.sender, 10003) > 0 ||
            metakey.balanceOf(msg.sender, 2) > 0 ||
            metakey.balanceOf(msg.sender, 1) > 0;
    }

    function eligiblePresale() public view returns(bool) {
        return metakeyEligible() || (whitelist[msg.sender] && whitelistClaimed < MAX_WHITELIST_SALE_SUPPLY);
    }

    function presaleClaim() external payable {
        require(presaleActive, "Not active");
        require(tx.origin == msg.sender, "Not allowed");
        require(eligiblePresale(), "Not eligible");
        require(balanceOf(msg.sender) == 0, "Exceed max");
        require(msg.value >= 1 * BUY_PRICE, "Ether value incorrect.");

        if (whitelist[msg.sender] && whitelistClaimed < MAX_WHITELIST_SALE_SUPPLY) {
            _mintRandomToken(msg.sender);
            whitelistClaimed++;
            whitelist[msg.sender] = false;
        }
        else if (metakeyEligible()) {
            require(presaleClaimed + 1 <= MAX_PRESALE_SUPPLY, "Exceeds total presale.");
            _mintRandomToken(msg.sender);
            presaleClaimed++;
        }
    }

    function _mintRandomToken(address _to) internal {
        require(seeded, "Need VRF seed");

        uint16 index = uint16(uint256(keccak256(abi.encodePacked(seedNumber, block.timestamp, _to, block.number, totalSupply(), address(this)))) % boundary) + 1;
        uint16 tokenId = randoms[index] > 0 ? randoms[index] - 1 : index - 1;
        randoms[index] = randoms[boundary] > 0 ? randoms[boundary] : boundary;
        boundary -= 1;
        _safeMint(_to, tokenId);
    }

    /** onchain **/
    function getTokenWinnings(uint256 _tokenId) public view returns (uint16[] memory) {
        require(_exists(_tokenId), "Token does not exist");
        return tokens[uint16(_tokenId)].winnings;
    }

    function commonAttributes(uint256 _tokenId) internal view returns (string memory) {
        TokenInfo memory ball = tokens[uint16(_tokenId)];
        return string(abi.encodePacked(
            '{"trait_type":"Plot No","value":"', uint16(_tokenId + 1).toString(), '"},'
            '{"trait_type":"X Coordinate","value":"', ball.coord_x.toString(), '"},',
            '{"trait_type":"Y Coordinate","value":"', ball.coord_y.toString(), '"},',
            '{"trait_type":"Ball Type","value":"', BALL_TYPE[ball.ball_type % 3], '"}'
        ));
    }

    function genericAttributes(uint256 _tokenId) internal view returns (string memory) {
        TokenInfo memory ball = tokens[uint16(_tokenId)];
        return string(abi.encodePacked(
            string(abi.encodePacked(
                '{"trait_type":"Pattern","value":"', PATTERN[ball.pattern], '"},',
                '{"trait_type":"Wrap","value":"', WRAP[ball.wrap], '"},',
                '{"trait_type":"Overlay","value":"', OVERLAY[ball.overlay], '"},',
                '{"trait_type":"Rally","value":"', RALLY[ball.rally], '"},'
            )),
            string(abi.encodePacked(
                '{"trait_type":"Colour","value":"', COLOUR[ball.colour], '"},',
                '{"trait_type":"Scheme","value":"', SCHEME[ball.scheme], '"},',
                '{"trait_type":"Logo","value":"', LOGO[ball.logo], '"},',
                '{"trait_type":"Shot","value":"', SHOT[ball.shot], '"}'
            ))
        ));
    }

    function legendAttributes(uint256 _tokenId) internal view returns (string memory) {
        return string(abi.encodePacked('{"trait_type":"Legendary Pattern","value":"', legendPattern[uint16(_tokenId)], '"}'));
    }

    function artistAttributes(uint256 _tokenId) internal view returns (string memory) {
        return string(abi.encodePacked('{"trait_type":"Artist","value":"', artist[uint16(_tokenId)], '"}'));
    }

    function getAttributes(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        function(uint256) internal view returns (string memory)[3] memory options = [
            genericAttributes,
            artistAttributes,
            legendAttributes
        ];
        return string(abi.encodePacked(
            '[', commonAttributes(_tokenId), ',',
            options[tokens[uint16(_tokenId)].ball_type % 3](_tokenId),
            ']'
        ));
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for non exists token.");
        if (!revealed) {
            return 'ipfs://QmUMeAJdjrZYcaLbCRDF35MBXa1LdEPpt6RziwhTAbpgA4';
        }
        uint16 tokenId = uint16(_tokenId);
        if (bytes(tokens[tokenId].uri).length > 0 && enableTokenURI) {
            return string(abi.encodePacked(tokens[tokenId].uri, tokenId.toString()));
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /** Admin **/
    function teamClaim() external onlyOwner {
        for (uint16 i = 0; i < 5; i++) {
            _mintRandomToken(0x6b37Ca573f0A877F342434236721D1eE6CE83bb1);
        }
        for (uint16 i = 0; i < 15; i++) {
            _mintRandomToken(0x5151FCF0ED173426d9D095367360Be58F1AE7993);
        }
        for (uint16 i = 0; i < 15; i++) {
            _mintRandomToken(0x01cE3D2A58c85983Ab6f40e1f05B6f7EceC3f379);
        }
        for (uint16 i = 0; i < 15; i++) {
            _mintRandomToken(0x3c02bA1b4E3149e34880f7bf39C61087B4262a18);
        }
    }

    function addWhitelist(address[] calldata _accounts, bool _status) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            whitelist[_accounts[i]] = _status;
        }
    }

    function setProvenance(string calldata _provenance) external onlyOwner {
        provenance = _provenance;
    }

    function toggleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function togglePresaleActive() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleTokenURI() external onlyOwner {
        enableTokenURI = !enableTokenURI;
    }

    function toggleReveal() external onlyOwner {
        revealed = !revealed;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setTokenBaseURI(uint16[] calldata _tokenIds, string calldata _uri) external onlyOwner {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            tokens[_tokenIds[i]].uri = _uri;
        }
    }

    function setTokenWinnings(uint16[] calldata _tokenIds, uint16[][] calldata _winnings) external onlyOwner {
        require(_tokenIds.length == _winnings.length, "Input data mismatch.");
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            tokens[_tokenIds[i]].winnings = _winnings[i];
        }
    }

    function addTokenWinnings(uint16[] calldata _tokenIds, uint16[] calldata _winnings) external onlyOwner {
        require(_tokenIds.length == _winnings.length, "Input data mismatch.");
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            tokens[_tokenIds[i]].winnings.push(_winnings[i]);
        }
    }

    function updateLegendToken(uint16[] calldata _tokenIds, uint8[2][] calldata _attributes, string[] calldata _pattern) external onlyOwner {
        require(_tokenIds.length == _attributes.length, "Input mismatch.");
        require(_tokenIds.length == _pattern.length, "Input mismatch.");
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            tokens[_tokenIds[i]].ball_type = 2;
            tokens[_tokenIds[i]].coord_x = _attributes[i][0]; // 0 => coordination X
            tokens[_tokenIds[i]].coord_y = _attributes[i][1]; // 1 => coordination Y
            legendPattern[_tokenIds[i]] = _pattern[i];
        }
    }

    function updateArtistToken(uint16[] calldata _tokenIds, uint8[2][] calldata _attributes, string[] calldata _artist) external onlyOwner {
        require(_tokenIds.length == _attributes.length, "Input mismatch.");
        require(_tokenIds.length == _artist.length, "Input mismatch.");
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            tokens[_tokenIds[i]].ball_type = 1;
            tokens[_tokenIds[i]].coord_x = _attributes[i][0]; // 0 => coordination X
            tokens[_tokenIds[i]].coord_y = _attributes[i][1]; // 1 => coordination Y
            artist[_tokenIds[i]] = _artist[i];
        }
    }

    function updateGenerativeToken(uint16[] calldata _tokenIds, uint8[10][] calldata _attributes) external onlyOwner {
        require(_tokenIds.length == _attributes.length, "Input mismatch.");
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            tokens[_tokenIds[i]].ball_type = 0; // ball type = generative
            tokens[_tokenIds[i]].coord_x = _attributes[i][0]; // 0 => coordination X
            tokens[_tokenIds[i]].coord_y = _attributes[i][1]; // 1 => coordination Y
            tokens[_tokenIds[i]].pattern = _attributes[i][2]; // 2 => pattern
            tokens[_tokenIds[i]].wrap = _attributes[i][3]; // 3 => wrap
            tokens[_tokenIds[i]].overlay = _attributes[i][4]; // 4 => overlay
            tokens[_tokenIds[i]].rally = _attributes[i][5]; // 5 => rally
            tokens[_tokenIds[i]].colour = _attributes[i][6]; // 6 => colour
            tokens[_tokenIds[i]].scheme = _attributes[i][7]; // 7 => scheme
            tokens[_tokenIds[i]].logo = _attributes[i][8]; // 8 => logo
            tokens[_tokenIds[i]].shot = _attributes[i][9]; // 9 => shot
        }
    }

    function withdraw() public onlyOwner {
        uint balanceA = (address(this).balance * 75) / 1000;
        uint balanceB = (address(this).balance * 400) / 1000;
        uint balanceC = (address(this).balance * 200) / 1000;
        uint balanceD = address(this).balance - balanceA - balanceB - balanceC;

        payable(0x6b37Ca573f0A877F342434236721D1eE6CE83bb1).transfer(balanceA);
        payable(0x5151FCF0ED173426d9D095367360Be58F1AE7993).transfer(balanceB);
        payable(0x01cE3D2A58c85983Ab6f40e1f05B6f7EceC3f379).transfer(balanceC);
        payable(0x3c02bA1b4E3149e34880f7bf39C61087B4262a18).transfer(balanceD);
    }

    function withdrawLink() external onlyOwner {
        uint256 balance = LINK.balanceOf(address(this));
        LINK.transfer(msg.sender, balance);
    }
}

interface IMetaKey {
    function balanceOf(address, uint256) external view returns (uint256);
}