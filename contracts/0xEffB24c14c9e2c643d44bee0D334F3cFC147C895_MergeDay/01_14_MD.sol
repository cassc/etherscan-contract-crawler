// Just wanted to say that I love you mom, dad, sister.
// This message will stay here forever <3

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";

contract MergeDay is ERC721Enumerable, Ownable {
    // Utils
    using Strings for uint256;

    // Errors
    error notEnoughEthSent(string notEnoughMessage);
    error mintDeadlineReached(string deadlineMessage);
    error blockNumberNotMergeBlock(string blockNumberMessage);

    struct MD {
        // Message attributes
        string sender;
        string value;
        // Block attributes
        string blockNum;
    }

    uint256 MINT_DEAD_LINE = block.timestamp + 24 hours;
    uint256 MERGE_BLOCK = 15537220;

    mapping(uint256 => MD) public MDs;

    constructor() ERC721("Merge Day", "MD") {}

    // Public
    function mint() public payable {
        if (block.number < MERGE_BLOCK)
            revert blockNumberNotMergeBlock("Block number is not Merge block");

        if (block.timestamp > MINT_DEAD_LINE)
            revert mintDeadlineReached("Mint was only available for 24 hours");

        if (msg.sender != owner()) {
            if (msg.value < 0.05 ether)
                revert notEnoughEthSent("You must pay 0.05 ETH or more");
        }

        uint256 supply = totalSupply();

        address _sender = msg.sender;
        uint256 _value = msg.value;

        uint256 _block = block.number;

        MD memory newMD = MD(
            Strings.toHexString(uint256(uint160(_sender))),
            Strings.toString(_value),
            Strings.toString(_block)
        );

        MDs[supply + 1] = newMD;
        _safeMint(msg.sender, supply + 1);
    }

    function buildImage(uint256 _tokenId) public view returns (string memory) {
        MD memory currentMD = MDs[_tokenId];
        return
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg width="512" height="512" xmlns="http://www.w3.org/2000/svg">',
                        "<title>NFT</title>",
                        "<g>",
                        '<rect id="svg_19" height="512" width="512" x="-0.02149" stroke-width="0" stroke="#000" fill="#000000"/>',
                        '<text font-style="normal" stroke-width="0" font-weight="bold" xml:space="preserve" text-anchor="start" font-size="43" id="svg_2" y="70.09975" x="20" stroke="#ffffff" fill="#ffffff">I bought this NFT</text>',
                        '<text stroke="#ffffff" stroke-width="0" font-weight="bold" xml:space="preserve" text-anchor="start" font-size="43" id="svg_3" y="150.35143" x="20" fill="#ffffff">on block</text>',
                        '<text font-weight="bold" xml:space="preserve" text-anchor="start" font-size="43" id="svg_13" y="150.35143" x="200" stroke-width="0" stroke="#ff0000" fill="#ff0000">',
                        currentMD.blockNum,
                        "</text>",
                        '<text font-weight="bold" xml:space="preserve" text-anchor="start" font-size="43" id="svg_14" y="150.09975" x="386.92111" stroke-width="0" stroke="#000" fill="#ffffff">for</text>',
                        '<text style="cursor: move;" stroke="#007fff" font-weight="bold" xml:space="preserve" text-anchor="start" font-size="37" id="svg_18" y="230" x="20" stroke-width="0" fill="#007fff">',
                        currentMD.value,
                        "</text>",
                        '<text stroke="#ffffff" font-weight="bold" xml:space="preserve" text-anchor="start" font-size="43" id="svg_1" y="230" x="400" stroke-width="0" fill="#ffffff">WEI</text>',
                        '<text stroke="#ffffff" font-weight="bold" xml:space="preserve" text-anchor="start" font-size="43" id="svg_22" y="310.09975" x="20" stroke-width="0" fill="#ffffff">during merge day.</text>',
                        '<rect stroke="#ffffff" id="svg_16" height="116" width="491.00006" y="367.08801" x="10.49997" stroke-width="0" fill="#ffffff"/>',
                        '<text stroke="#000" font-weight="bold" xml:space="preserve" text-anchor="middle" font-size="42" id="svg_20" y="412.08801" x="50%" fill="#000" dominant-baseline="middle">Buyer</text>',
                        '<text transform="matrix(1 0 0 1 0 0)" font-weight="bold" xml:space="preserve" text-anchor="middle" font-size="22" id="svg_23" y="454.05267" x="50%" stroke="#e0ac00" fill="#e0ac00" dominant-baseline="middle">',
                        currentMD.sender,
                        "</text>",
                        "</g>",
                        "</svg>"
                    )
                )
            );
    }

    function buildMetadata(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        MD memory currentMD = MDs[_tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                currentMD.sender,
                                '", "description":"',
                                currentMD.blockNum,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                buildImage(_tokenId),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return buildMetadata(_tokenId);
    }

    // Withdraw funds
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}