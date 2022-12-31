// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./ToString.sol";
import "./Base64.sol";

contract Zero_V2 is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using ToString for uint256;

    string public version;
    uint256 public MAX_TOKENS;
    uint256 public numTokens;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Initialization and Proxy Administration
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initializeV2() public reinitializer(2) {
        __ERC721_init("ZERO by Mathcastles", "ZERO");
        version = "Version 0.2";
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Public read-only functions
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Returns tokenURI for a given id
    /// @param id The token id
    /// @return a base64-encoded JSON string
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "id does not exist");
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name": "Protoform ',
                            id.toString(),
                            '","description": "ZERO by Mathcastles"',
                            ',"attributes": [{"trait_type": "Status", "value": "Pre-Reveal"}, {"trait_type": "Type", "value": "Protoform"}]',
                            ',"image": "data:image/svg+xml;base64,',
                            Base64.encode(abi.encodePacked(prerevealSVG())),
                            '"}'
                        )
                    )
                )
            );
    }

    function prerevealSVG() public pure returns (string memory) {
        return
            '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg shape-rendering="crispEdges" viewBox="0 0 280 280" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg"><rect class="bg" fill="#161616" x="0" y="0" width="280" height="280"/><path class="y" stroke="#fff" d="m 132.5,126.5 h 2 m 2,0 h 1 m -8,1 h 1 m 3,0 h 1 m 3,0 h 1 m 7,0 h 1 m 3,0 h 2 m -25,1 h 2 m 1,0 h 1 m 3,0 h 1 m 14,0 h 2 m -23,1 h 1 m 2,0 h 1 m 3,0 h 1 m 1,0 h 4 m 1,0 h 4 m 2,0 h 2 m -21,1 h 1 m 3,0 h 2 m 17,0 h 1 m -26,1 h 1 m 4,0 h 1 m 14,0 h 1 m 3,0 h 2 m -22,1 h 1 m 1,0 h 5 m 5,0 h 1 m 1,0 h 1 m 2,0 h 1 m 2,0 h 1 m -24,1 h 1 m 1,0 h 1 m 1,0 h 1 m 2,0 h 1 m 1,0 h 1 m 3,0 h 1 m 1,0 h 1 m 2,0 h 1 m 1,0 h 1 m -19,1 h 1 m 1,0 h 1 m 2,0 h 1 m 2,0 h 1 m 2,0 h 1 m 1,0 h 1 m 2,0 h 1 m 2,0 h 1 m 2,0 h 2 m -24,1 h 1 m 2,0 h 5 m 4,0 h 4 m 3,0 h 1 m 1,0 h 2 m -23,1 h 1 m 18,0 h 1 m -23,1 h 1 m 1,0 h 1 m 3,0 h 1 m 3,0 h 1 m 5,0 h 1 m 4,0 h 1 m -19,1 h 4 m 2,0 h 2 m 5,0 h 1 m 3,0 h 1 m 2,0 h 1 m -23,1 h 3 m 3,0 h 3 m 1,0 h 1 m 2,0 h 1 m 1,0 h 1 m 2,0 h 1 m 2,0 h 2 m -23,1 h 2 m 1,0 h 1 m 2,0 h 2 m 2,0 h 1 m 1,0 h 1 m 3,0 h 3 m 2,0 h 1 m -17,1 h 8 m 1,0 h 2 m 1,0 h 1 m 1,0 h 1 m -9,1 h 1 m -10,1 h 2 m 1,0 h 2 m 8,0 h 5 m -16,1 h 1 m 1,0 h 2 m 6,0 h 4 m -7,1 h 2 m -7,1 h 1 m 2,0 h 2 m 5,0 h 1 m 1,0 h 2 m -16,1 h 4 m 1,0 h 2 m 1,0 h 3 m 2,0 h 1 m -7,1 h 2 m 1,0 h 2 m -6,1 h 1 m 1,0 h 1 m 2,0 h 1 m -6,1 h 1 m 2,0 h 3 m -7,1 h 1 m 3,0 h 1 m -6,1 h 1 m 3,0 h 2 m -6,1 h 1 m 1,0 h 1 m 1,0 h 1 m 0,-27 h 1 m 2,0 h 1 m -2,1 h 1 m -2,5 h 1 m -17,5 h 1 m 0,1 h 1 m 16,1 h 1 m -13,2 h 1 m 8,0 h 1 m -10,2 h 1 m 0,1 h 1 m 11,2 h 1 m 1,-20 h 1 m -11,1 h 1 m -2,2 h 1 m 4,0 h 1 m -15,3 h 1 m 10,1 h 1 m -1,12 h 1 m -1,3 h 1 m -2,5 h 1 m 1,0 h 1 m 1,-26 h 1 m -11,1 h 1 m 14,2 h 1 m -10,4 h 1 m -9,2 h 1 m 2,1 h 1 m 9,1 h 1 m -10,1 h 1 m 14,1 h 1 m -15,8 h 1 m 6,1 h 1 m -5,1 h 1 m 6,-18 h 1 m -9,19 h 1"/><path class="x" stroke="#fff" d="m 135.5,123.5 h 1 m 7,0 h 1 m 4,0 h 1 m -18,1 h 2 m 3,0 h 1 m 2,0 h 1 m 3,0 h 1 m -16,1 h 1 m 3,0 h 1 m 3,0 h 1 m 3,0 h 1 m 7,0 h 1 m -20,1 h 1 m 17,0 h 1 m -15,1 h 9 m 2,0 h 1 m 7,0 h 1 m -27,1 h 2 m 2,0 h 3 m 2,0 h 1 m 6,0 h 1 m 2,0 h 2 m 3,0 h 2 m -25,1 h 1 m 1,0 h 2 m 3,0 h 1 m 1,0 h 2 m 3,0 h 4 m 2,0 h 2 m -20,1 h 1 m 2,0 h 2 m 1,0 h 1 m 1,0 h 1 m 3,0 h 1 m 1,0 h 1 m 1,0 h 1 m 2,0 h 1 m -21,1 h 1 m 3,0 h 2 m 1,0 h 1 m 1,0 h 1 m 3,0 h 1 m 1,0 h 1 m 1,0 h 1 m 2,0 h 1 m -21,1 h 1 m 4,0 h 4 m 4,0 h 1 m 1,0 h 1 m 1,0 h 1 m 2,0 h 1 m -23,1 h 1 m 1,0 h 1 m 5,0 h 3 m 4,0 h 4 m 3,0 h 1 m -23,1 h 1 m 1,0 h 1 m 3,0 h 1 m -7,1 h 1 m 1,0 h 2 m 2,0 h 1 m 4,0 h 1 m 3,0 h 1 m 4,0 h 2 m 2,0 h 2 m -26,1 h 1 m 2,0 h 3 m 1,0 h 1 m 3,0 h 1 m 4,0 h 1 m 2,0 h 2 m 2,0 h 2 m -24,1 h 1 m 2,0 h 2 m 1,0 h 4 m 1,0 h 1 m 1,0 h 1 m 2,0 h 4 m -19,1 h 2 m 4,0 h 1 m 1,0 h 7 m 2,0 h 1 m -19,1 h 2 m 5,0 h 1 m 4,0 h 1 m 3,0 h 3 m -15,2 h 3 m 7,0 h 4 m -12,1 h 3 m 4,0 h 4 m -16,1 h 1 m 9,0 h 1 m -10,1 h 1 m 1,0 h 2 m 4,0 h 2 m 4,0 h 1 m 2,0 h 1 m -18,1 h 3 m 5,0 h 2 m 1,0 h 1 m 2,0 h 1 m 1,0 h 2 m -8,1 h 3 m -7,1 h 6 m -7,1 h 2 m 4,0 h 1 m -7,1 h 1 m 4,0 h 2 m -6,1 h 5 m -4,-27 h 1 m 3,1 h 1 m 7,0 h 1 m -6,1 h 1 m -1,2 h 1 m 7,0 h 1 m -19,1 h 1 m 2,0 h 1 m -2,1 h 1 m -5,6 h 1 m 16,1 h 1 m -1,1 h 2 m -15,2 h 1 m -4,3 h 1 m 6,-19 h 1 m 7,2 h 1 m -20,5 h 1 m 8,2 h 1 m -9,5 h 1 m 5,1 h 1 m -2,3 h 1 m 4,4 h 1 m 4,0 h 1 m -7,1 h 1 m 3,-19 h 1 m -10,2 h 1 m 10,1 h 1 m 3,4 h 1 m -8,2 h 1 m 5,0 h 1 m -16,1 h 1 m 9,0 h 1 m -5,2 h 1 m -10,4 h 1 m -3,-5 h 1"/><style> @keyframes cf{0%{stroke: #151515;}10%{stroke: #151515;}20%{stroke: #151415;}30%{stroke: #151515;}40%{stroke: #151515;}50%{stroke: #151515;}60%{stroke: #151515;}70%{stroke: #151515;}80%{stroke: #151515;}90%{stroke: #151515;}}    .bg{animation:bg .05s .025s steps(1) infinite;} @keyframes bg{0%{fill: #151515;}50%{fill: #151514;}} .x{animation: fr .3s steps(1) infinite,m2 .7s steps(2) infinite, cf 1s steps(1) infinite alternate;} .y{animation: fr .3s .15s steps(1) infinite,m2 1s steps(3) infinite,cf 1s steps(1) infinite alternate;} @keyframes m2{0%{transform: translate(0%, 0%)}50%{transform: translate(0%, -3%)}} @keyframes fr {0%{opacity: 0;}50%{opacity: 1.0;}};}</style></svg>';
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Minting
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Mints a token
    /// @param to The token recipient
    function safeMint(address to) public onlyOwner {
        require(numTokens < MAX_TOKENS, "Tokens are fully minted");
        numTokens += 1;
        uint256 tokenId = numTokens;
        _safeMint(to, tokenId);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Required Overrides
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}