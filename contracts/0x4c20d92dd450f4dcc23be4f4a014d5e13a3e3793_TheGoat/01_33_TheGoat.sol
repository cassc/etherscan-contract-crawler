// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libraries/Base64.sol";
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IWETH } from './interfaces/IWETH.sol';

contract TheGoat is ERC721, ERC721Enumerable, Ownable, EIP712, ERC721Votes {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;
    uint256 public deploymentTimestamp;
    using Base64 for *;
    address private constant dev2 = 0xCC44A5Feb6Ee172dAaa31c1Fee3FC1Ce1654057F;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    event Bid (
        address indexed bidder,
        uint256 amount,
        uint256 day
    );

    struct Day {
        address winner;
        uint256 highestBid;
        bool minted;
    }

    mapping(uint256 => Day) public day;
    mapping(uint256 => uint256) private dayReward;
    mapping(uint256 => uint256) private claimed;

    enum ItemType {
        Head,
        Horn,
        Eye,
        Body
    }

    struct Item {
        string name;
        string svg;
        string json;
    }

    struct Art {
        Item[] heads;
        Item[] horns;
        Item[] bodies;
        Item[] eyes;
        uint8[3][2][4] skins;
    }

    Art private art;

    bool public artComplete = false;

    uint256 private intervalFee = 10;

    function addItems(
        ItemType _itemType,
        string[] memory _names,
        string[] memory _svgs,
        string[] memory _jsons
    ) public onlyOwner {
        require(
            _names.length == _svgs.length && _names.length == _jsons.length,
            "Array lengths must match"
        );

        require(!artComplete, "Art is already complete");

        for (uint256 i = 0; i < _names.length; i++) {
            if (_itemType == ItemType.Head) {
                art.heads.push(Item(_names[i], _svgs[i], _jsons[i]));
            } else if (_itemType == ItemType.Horn) {
                art.horns.push(Item(_names[i], _svgs[i], _jsons[i]));
            } else if (_itemType == ItemType.Eye) {
                art.eyes.push(Item(_names[i], _svgs[i], _jsons[i]));
            } else if (_itemType == ItemType.Body) {
                art.bodies.push(Item(_names[i], _svgs[i], _jsons[i]));
            }
        }
    }

    function lockArt() public onlyOwner {
        require(!artComplete, "Art is already complete");
        artComplete = true;
    }

    constructor() ERC721("The GOAT", "GOAT") EIP712("TheGoat", "1") {
        deploymentTimestamp = block.timestamp;
        art.skins = [
            [[102, 72, 33], [135, 103, 46]],
            [[98, 98, 98], [160, 160, 160]],
            [[119, 39, 23], [162, 70, 28]],
            [[176, 173, 134], [205, 202, 166]]
        ];
        safeMint(owner(), 0);
        safeMint(0x0e802Eef59d855375e4826123a4145B829Bc3F83, 1);
        safeMint(0x184Fd7ACe17722dA2fFD9DC1F951DA8283253cdf, 2);
        safeMint(0xf728Ce79C82BB99335e0A781CAc0254B6a9AEb37, 3);
        safeMint(0x5D2A610dfCFF2B38e82DF7F2C3C100CF6332527D, 4);
        safeMint(0xa73827D96540E1d8CAcd48017a2eb08B0e073e27, 5);
        safeMint(0xc2B35534e47cdF3D787e01630129631d8270abFb, 6);
    }

    function getDayId() public view returns (uint256) {
        return (block.timestamp - deploymentTimestamp) / 1 days + 1;
    }

    function getGoatsSinceDeployment() public view returns (uint256) {
        return 6 + getDayId() + getDayId() / intervalFee;
    }

    function bid() public payable {
        require(
            msg.value > 0,
            "You must send some ether to participate in the auction."
        );
        uint256 currentDay = getGoatsSinceDeployment();
        require(msg.value > day[currentDay].highestBid + 1000000 gwei, "Your bid is too low.");
        require(
            day[currentDay].winner != msg.sender,
            "You are already the winner."
        );

        address payable lastBidder = payable(day[currentDay].winner);
        uint256 lastBid = day[currentDay].highestBid;
        
        day[currentDay].highestBid = msg.value;
        day[currentDay].winner = msg.sender;
        calculateRewards(currentDay);
        emit Bid(msg.sender, msg.value, currentDay);
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, lastBid);
        }
    }

    function mint(uint256 goatId) public {
        require(day[goatId].winner == msg.sender, "You are not the winner.");
        require(day[goatId].minted == false, "You already minted your NFT.");
        require(goatId % intervalFee != 0, "It's Sunday.");
        require(goatId < getGoatsSinceDeployment(), "Day not reached yet.");
        safeMint(msg.sender, goatId);
    }

    function mintSunday(uint256 goatId) public {
        require(goatId % intervalFee == 0, "It's not Sunday.");
        require(day[goatId].minted == false, "You already minted your NFT.");
        require(goatId < getGoatsSinceDeployment(), "Day not reached yet.");
        if (goatId % 20 == 0) {
            safeMint(owner(), goatId);
        } else {
            safeMint(dev2, goatId);
        }
    }

    function mintUnminted(uint256 goatId) public {
        require(day[goatId].minted == false, "You already minted your NFT.");
        require(
            goatId + intervalFee < getGoatsSinceDeployment(),
            "Day not reached yet."
        );

        safeMint(owner(), goatId);
    }

    function safeMint(address to, uint256 id) internal {
        day[id].minted = true;
        claimed[id] += dayReward[id];
        _safeMint(to, id);
    }

    function dna(uint256 _tokenId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_tokenId, "TheGoat")));
    }

    function claim(uint256 _tokenId) public {
        require(_exists(_tokenId));
        require(_msgSender() == ownerOf(_tokenId));
        require(_tokenId < getGoatsSinceDeployment());

        uint256 amount = claimable(_tokenId);

        if (amount > 0) {
            claimed[_tokenId] += amount;
            payable(_msgSender()).transfer(amount);
        }
    }

    function claimMultiple(uint256[] calldata ownedNfts) public {
        for (uint256 i = 0; i < ownedNfts.length; ) {
            claim(ownedNfts[i]);
            unchecked {
                i++;
            }
        }
    }

    function claimable(uint256 tokenId) public view returns (uint256) {
        uint256 yesterday = getGoatsSinceDeployment() - 1;
        while (dayReward[yesterday] == 0 && yesterday > 0) {
            yesterday--;
        }
        return dayReward[yesterday] - claimed[tokenId];
    }

    function calculateRewards(uint256 _day) public {
        require(_day <= getGoatsSinceDeployment());
        require(_day > 0);
        if (dayReward[_day - 1] == 0 && _day > 1) {
            calculateRewards(_day - 1);
        }
        dayReward[_day] = dayReward[_day - 1] + day[_day].highestBid / _day;
    }

    function getWinningDays(
        address user
    ) public view returns (uint256[] memory) {
        uint256 goatsSinceDeployment = getGoatsSinceDeployment();
        uint256[] memory winningDays = new uint256[](goatsSinceDeployment);
        uint256 count = 0;

        for (uint256 i = 0; i < goatsSinceDeployment; i++) {
            if (day[i].winner == user && day[i].minted == false) {
                winningDays[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = winningDays[i];
        }

        return result;
    }

    // image

    function imageData(uint256 _tokenId) public view returns (string memory) {
        require(_tokenId <= getGoatsSinceDeployment(), "Day not reached yet.");

        uint8[4] memory tdna = splitNumber(dna(_tokenId));

        require(tdna[0] < art.heads.length, "Invalid index for art.heads");
        require(tdna[1] < art.horns.length, "Invalid index for art.horns");
        require(tdna[2] < art.bodies.length, "Invalid index for art.bodies");
        require(tdna[3] < art.eyes.length, "Invalid index for art.eyes");
        uint8[3][9] memory colors = magicColors(_tokenId);

        return
            string(
                abi.encodePacked(
                    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 -0.5 28 28' shape-rendering='crispEdges'><style> .c1{stroke:",
                    rgbToString(colors[0]),
                    ";} .c2{stroke:",
                    rgbToString(colors[1]),
                    ";} .c3{stroke:",
                    rgbToString(colors[2]),
                    ";} .c5{stroke:",
                    rgbToString(colors[3]),
                    ";} .c6{stroke:",
                    rgbToString(colors[4]),
                    ";} .d2{stroke:",
                    rgbToString(colors[5]),
                    ";} .d3{stroke:",
                    rgbToString(colors[6]),
                    ";} .d4{stroke:",
                    rgbToString(colors[7]),
                    ";} .d6{stroke:",
                    rgbToString(colors[8]),
                    ";} .s1{stroke:",
                    rgbToString(art.skins[tdna[0]][0]),
                    ";} .s2{stroke:",
                    rgbToString(art.skins[tdna[0]][1]),
                    ';} </style><path class="c1" d="M0 0h28M0 1h28M0 2h28M0 3h28M0 4h28M0 5h28M0 6h28M0 7h28M0 8h28M0 9h28M0 10h28M0 11h28M0 12h28M0 13h28M0 14h28M0 15h28M0 16h28M0 17h28M0 18h28M0 19h28M0 20h28M0 21h28M0 22h28M0 23h28M0 24h28M0 25h28M0 26h28M0 27h28"/>',
                    art.bodies[tdna[2]].svg,
                    art.heads[tdna[0]].svg,
                    art.horns[tdna[1]].svg,
                    art.eyes[tdna[3]].svg,
                    "</svg>"
                )
            );
    }

    function splitNumber(
        uint256 _number
    ) internal view returns (uint8[4] memory) {
        uint8[4] memory numbers;
        numbers[0] = uint8(_number % art.heads.length); // head
        _number /= art.heads.length;
        numbers[1] = uint8(_number % art.horns.length); // horns
        _number /= art.horns.length;
        numbers[2] = uint8(_number % art.bodies.length); // body
        _number /= art.bodies.length;
        numbers[3] = uint8(_number % art.eyes.length); // eyes

        return numbers;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        uint8[4] memory tdna = splitNumber(dna(_tokenId));
        bytes memory baseURI = (
            abi.encodePacked(
                '{ "attributes": [',
                art.heads[tdna[0]].json,
                ",",
                art.horns[tdna[1]].json,
                ",",
                art.bodies[tdna[2]].json,
                ",",
                art.eyes[tdna[3]].json,
                ",",
                '{"trait_type": "Color", "value": "',
                rgbToString(getRandomColor(_tokenId)),
                '"}',
                "],",
                '"description": "Created by thegoat.wtf","external_url": "https://thegoat.wtf","image": "data:image/svg+xml;base64,',
                bytes(imageData(_tokenId)).encode(),
                '","name": "The Goat #',
                _tokenId.toString(),
                '"}'
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    baseURI.encode()
                )
            );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Votes) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function magicColors(
        uint256 _tokenId
    ) public pure returns (uint8[3][9] memory) {
        uint8[3] memory c = getRandomColor(_tokenId);
        uint8[3] memory d = getCColor(c);
        return (
            [
                adjustColor(c, 210, 253),
                adjustColor(c, 128, 240),
                adjustColor(c, 64, 200),
                adjustColor(c, 64, 128),
                adjustColor(c, 20, 64),
                adjustColor(d, 128, 240),
                adjustColor(d, 64, 200),
                adjustColor(d, 64, 128),
                adjustColor(d, 20, 64)
            ]
        );
    }

    function getRandomColor(uint id) internal pure returns (uint8[3] memory) {
        return [
            getRandomNumber(id),
            getRandomNumber(id + 1337),
            getRandomNumber(id + 13371337)
        ];
    }

    function getRandomNumber(uint256 nonce) internal pure returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(nonce))) % 256);
    }

    function getCColor(
        uint8[3] memory color
    ) internal pure returns (uint8[3] memory) {
        uint8[3] memory complementary;

        complementary[0] = 255 - color[0];
        complementary[1] = 255 - color[1];
        complementary[2] = 255 - color[2];

        return complementary;
    }

    function adjustColor(
        uint8[3] memory input,
        uint8 minOutput,
        uint8 maxOutput
    ) internal pure returns (uint8[3] memory) {
        uint256 inputRange = 255;
        uint256 outputRange = uint256(maxOutput) - uint256(minOutput);

        uint8[3] memory adjustedColor;
        adjustedColor[0] = uint8(
            (uint256(input[0]) * outputRange) / inputRange + uint256(minOutput)
        );
        adjustedColor[1] = uint8(
            (uint256(input[1]) * outputRange) / inputRange + uint256(minOutput)
        );
        adjustedColor[2] = uint8(
            (uint256(input[2]) * outputRange) / inputRange + uint256(minOutput)
        );

        return adjustedColor;
    }

    function rgbToString(
        uint8[3] memory color
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "rgb(",
                    Strings.toString(color[0]),
                    ",",
                    Strings.toString(color[1]),
                    ",",
                    Strings.toString(color[2]),
                    ")"
                )
            );
    }

    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{value: amount}();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(
        address to,
        uint256 value
    ) internal returns (bool) {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }
}