// SPDX-License-Identifier: CC0
pragma solidity ^0.8.14;

// Name: Bonhomme 3x3
// Description: Bonhomme is a collection of generated, on-chain, 3x3 grids that represent your wallet address.
// Website: https://bonhomme.lol
// Twitter: @pixel_arts
// Build: himlate.eth
// Design: biron.eth
// Using to HotChainSVG: 0xa7988c8abb7706e024a8f2a1328e376227aaad18

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './Utils.sol';
import './SVG.sol';
import './Base64.sol';

contract Bonhomme is ERC721A, Ownable {
    string[9] public colors = [
        '#9b51e0',
        '#2f80ed',
        '#56ccf2',
        '#6fcf97',
        '#27ae60',
        '#f2c94c',
        '#f2994a',
        '#eb5757',
        '#ff86dd'
    ];
    uint256 public constant PX_SIZE = 300;
    string public description =
        'Bonhomme is a collection of generated, on-chain, 3x3 grids that represent your wallet address. Only one per wallet. Free forever.';

    mapping(address => bool) public hasAddressMinted;
    mapping(uint256 => address) public seeds;

    constructor() ERC721A('bonhomme.lol', 'BONHOMME') {}

    error OnlyOneMintAllowed();

    modifier hasNeverMinted(address _address) {
        if (hasAddressMinted[_address] == true) revert OnlyOneMintAllowed();
        _;
    }

    function mint() external payable hasNeverMinted(msg.sender) {
        uint256 _currentTokenId = _nextTokenId();

        _mint(msg.sender, 1);
        hasAddressMinted[msg.sender] = true;
        seeds[_currentTokenId] = msg.sender;
    }

    function airdrop(address _address)
        external
        onlyOwner
        hasNeverMinted(_address)
    {
        uint256 _currentTokenId = _nextTokenId();

        _mint(_address, 1);
        hasAddressMinted[_address] = true;
        seeds[_currentTokenId] = _address;
    }

    function getShape(
        uint256 _seed,
        uint256 _x,
        uint256 _y
    ) internal view returns (string memory) {
        string memory stringX = utils.uint2str(_x);
        string memory stringY = utils.uint2str(_y);
        uint256 color = utils.getRandomInteger(
            string.concat('color', stringX, stringY),
            _seed,
            0,
            9
        );
        uint256 circleOrRect = utils.getRandomInteger(
            string.concat('shape', stringX, stringY),
            _seed,
            0,
            10
        );
        string memory shape;

        if (circleOrRect < 5) {
            shape = svg.circle(
                string.concat(
                    svg.prop('fill', colors[color]),
                    svg.prop('cx', utils.uint2str(_x + (PX_SIZE / 2))),
                    svg.prop('cy', utils.uint2str(_y + (PX_SIZE / 2))),
                    svg.prop('r', utils.uint2str(PX_SIZE / 2)),
                    svg.prop('width', utils.uint2str(PX_SIZE)),
                    svg.prop('height', utils.uint2str(PX_SIZE))
                ),
                utils.NULL
            );
        } else {
            shape = svg.rect(
                string.concat(
                    svg.prop('fill', colors[color]),
                    svg.prop('x', stringX),
                    svg.prop('y', stringY),
                    svg.prop('width', utils.uint2str(PX_SIZE)),
                    svg.prop('height', utils.uint2str(PX_SIZE))
                ),
                utils.NULL
            );
        }

        return shape;
    }

    function getRow(uint256 _seed, uint256 _y)
        internal
        view
        returns (string memory)
    {
        return
            string.concat(
                getShape(_seed, 0, _y),
                getShape(_seed, 300, _y),
                getShape(_seed, 600, _y)
            );
    }

    function render(uint256 _seed) public view returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" viewbox="0 0 900 900" width="900" height="900">',
                getRow(_seed, 0),
                getRow(_seed, 300),
                getRow(_seed, 600),
                '</svg>'
            );
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 seed = uint256(uint160(seeds[_tokenId]));

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Bonhomme #',
                                utils.uint2str(_tokenId),
                                '", "description":"',
                                description,
                                '", ',
                                '"attributes": [{"trait_type": "seed", "value": "',
                                utils.uint2str(seed),
                                '"}]',
                                ', "image":"',
                                string(
                                    abi.encodePacked(
                                        'data:image/svg+xml;base64,',
                                        Base64.encode(bytes(render(seed)))
                                    )
                                ),
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}