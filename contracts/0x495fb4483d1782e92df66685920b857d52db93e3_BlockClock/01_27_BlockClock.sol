// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// S U N M O N T U E W E D T H U F R I S A T
// J A N F E B M A R A P R M A Y J U N J U L
// A U G S E P O C T N O V D E C 0 0 1 0 0 2
// 0 0 3 0 0 4 0 0 5 0 0 6 0 0 7 0 0 8 0 0 9
// 0 1 0 0 1 1 0 1 2 0 1 3 0 1 4 0 1 5 0 1 6
// 0 1 7 0 1 8 0 1 9 0 2 0 0 2 1 0 2 2 0 2 3
// 0 2 | --------- | 0 2 7 0 2 8 0 2 9 0 3 0
// 0 3 | B L O C K | 0 0 2 0 0 3 0 0 4 0 0 5
// 0 0 | ----------------- | 1 0 0 1 1 0 0 0
// 0 0 1 0 0 2 | C L O C K | 0 5 0 0 6 0 0 7
// 0 0 8 0 0 9 ----------- | 1 2 0 1 3 0 1 4
// 0 1 5 0 1 6 0 1 7 0 1 8 0 1 9 0 2 0 0 2 1
// | --- | 2 3 0 2 4 0 2 5 0 2 6 0 2 7 0 2 8
// | B Y   --------------------- | 3 4 0 3 5
// | --- | @ S A M M Y B A U C H | 4 1 0 4 2
// 0 4 3 ----------------------- | 4 8 0 4 9
// 0 5 0 0 5 1 0 5 2 0 5 3 0 5 4 0 5 5 0 5 6
// 0 5 7 0 5 8 0 5 9 0 0 0 0 0 1 0 0 2 0 0 3
// 0 0 4 0 0 5 0 0 6 0 0 7 0 0 8 0 0 9 0 1 0
// 0 1 1 0 1 2 0 1 3 0 1 4 0 1 5 0 1 6 0 1 7
// 0 1 8 0 1 9 0 2 0 0 2 1 0 2 2 0 2 3 0 2 4
// 0 2 5 0 2 6 0 2 7 0 2 8 0 2 9 0 3 0 0 3 1
// 0 3 2 0 3 3 0 3 4 0 3 5 0 3 6 0 3 7 0 3 8
// 0 3 9 0 4 0 0 4 1 0 4 2 0 4 3 0 4 4 0 4 5
// 0 4 6 0 4 7 0 4 8 0 4 9 0 5 0 0 5 1 0 5 2
// 0 5 3 0 5 4 0 5 5 0 5 6 0 5 7 0 5 8 0 5 9

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../Libraries/Base64.sol";
import "../Libraries/ERC721EnumerableEssential.sol";
import "../Libraries/EssentialStrings.sol";
import "../Libraries/LinearDutchAuction.sol";
import "../Libraries/OpenSeaGasFreeListing.sol";
import "../Libraries/SignedAllowance.sol";

interface IBlockClockRenderer {
    function svgBase64Data(
        int8 hourOffset,
        uint24 hexCode,
        uint256 timestamp
    ) external view returns (string memory);

    function svgRaw(
        int8 hourOffset,
        uint24 hexCode,
        uint256 timestamp
    ) external view returns (bytes memory);
}

contract BlockClock is ERC721EnumerableEssential, Ownable, LinearDutchAuction, SignedAllowance, PaymentSplitter {
    using EssentialStrings for uint256;
    using EssentialStrings for uint24;
    using EssentialStrings for uint8;

    uint256 private nextTokenId = 1;
    string private _animationBaseUrl;
    IBlockClockRenderer public renderer;

    struct ClockConfig {
        int8 hourOffset;
        uint24 onHex;
    }

    mapping(uint256 => ClockConfig) public clockConfig;

    constructor(address[] memory _payees, uint256[] memory _shares)
        ERC721("BlockClock", "CLOCK")
        PaymentSplitter(_payees, _shares)
        LinearDutchAuction(
            LinearDutchAuction.DutchAuctionConfig({
                startPoint: 1640106000, // 2021-12-21T17:00:00+00:00
                startPrice: 2.47 ether,
                unit: AuctionIntervalUnit.Time,
                decreaseInterval: 120, // 2 minutes
                decreaseSize: 0.025 ether,
                numDecreases: 96 // rests at 0.07
            }),
            0.07 ether,
            Seller.SellerConfig({
                totalInventory: 455,
                maxPerAddress: 0, // unlimited
                maxPerTx: 1,
                freeQuota: 0,
                reserveFreeQuota: false,
                lockTotalInventory: true,
                lockFreeQuota: true
            }),
            payable(address(this))
        )
    {
        _setAllowancesSigner(msg.sender);
    }

    function _handlePurchase(
        address to,
        uint256,
        bool
    ) internal override {
        _mint(to, nextTokenId);
        nextTokenId += 1;
    }

    function publicMint() public payable {
        _purchase(msg.sender, 1);
    }

    function claimGift(
        int8 offset,
        uint24 onHex,
        uint256 nonce,
        bytes memory signature
    ) public {
        require(nextTokenId <= 1024, "BC:cG:500");
        _useAllowance(msg.sender, nonce, signature);
        _mint(msg.sender, nextTokenId);
        clockConfig[nextTokenId] = ClockConfig({hourOffset: offset, onHex: onHex});
        nextTokenId += 1;
    }

    function updateConfig(
        uint256 tokenId,
        int8 offset,
        uint24 onHex
    ) public {
        require(msg.sender == ownerOf(tokenId), "BC:uC:401");

        clockConfig[tokenId] = ClockConfig({hourOffset: offset, onHex: onHex});
    }

    function svgRaw(uint256 tokenId, uint256 timestamp) public view returns (bytes memory) {
        ClockConfig memory clock = clockConfig[tokenId];
        uint256 _timestamp = timestamp == 0
            ? uint256(int256(block.timestamp) + int256(clock.hourOffset) * 1 hours)
            : timestamp;

        return renderer.svgRaw(clock.hourOffset, clock.onHex, _timestamp);
    }

    /* solhint-disable quotes */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "BC:tU:404");
        ClockConfig memory clock = clockConfig[tokenId];

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"BlockClock ',
                                tokenId.toString(),
                                '", "description":"BlockClocks are on-chain SVG clocks. The program is also available on IPFS for easier animated display.", "image": "',
                                renderer.svgBase64Data(clock.hourOffset, clock.onHex, block.timestamp),
                                '", "animation_url": "',
                                animationUrl(tokenId),
                                tokenProperties(tokenId),
                                '"}}'
                            )
                        )
                    )
                )
            );
    }

    function animationUrl(uint256 tokenId) internal view returns (bytes memory) {
        return abi.encodePacked(_animationBaseUrl, animationQuery(tokenId));
    }

    function setAnimationBaseUrl(string memory newBaseUrl) external onlyOwner {
        _animationBaseUrl = newBaseUrl;
    }

    function setRenderer(address rendererAddress) external onlyOwner {
        renderer = IBlockClockRenderer(rendererAddress);
    }

    function animationQuery(uint256 tokenId) internal view returns (bytes memory) {
        ClockConfig memory clock = clockConfig[tokenId];

        return abi.encodePacked("?h=", clock.onHex.toHexString(), "&tz=", offsetBytes(clock.hourOffset));
    }

    function tokenProperties(uint256 tokenId) internal view returns (bytes memory) {
        ClockConfig memory clock = clockConfig[tokenId];
        return
            abi.encodePacked(
                '", "properties": { "Highlight Color": "',
                clock.onHex.toHtmlHexString(),
                '", "Timezone": "UTC',
                offsetBytes(clock.hourOffset)
            );
    }

    function offsetBytes(int8 offset) internal view returns (bytes memory) {
        return
            offset >= 0
                ? abi.encodePacked("+", uint8(offset).toString())
                : abi.encodePacked("-", uint8(-offset).toString());
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return OpenSeaGasFreeListing.isApprovedForAll(owner, operator) || super.isApprovedForAll(owner, operator);
    }
}