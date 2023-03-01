// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./base64.sol";

contract GasCards is ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    string private _contractURI;

    event tokenChanged(uint256 tokenId);

    uint256 constant public MINT_PRICE = 0.01 ether;

    constructor() ERC721("GasCards", "GAS") {}

    function svgToImageURI(string memory _gwei) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string[4] memory parts;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 300 420"><defs><linearGradient id="g" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" style="stop-color:#141414;stop-opacity:1"/><stop offset="100%" style="stop-color:#343434;stop-opacity:1"/></linearGradient><mask id="m"><rect fill="#FFF" rx="20" ry="20" width="300" height="420"/></mask></defs><style>text{font-family:Luminari;font-size:22px}.s{fill:#8c8c8c}.p{fill:#ecf0f1}</style><rect mask="url(#m)" ry="20" rx="20" width="300" height="420" stroke="#FFF"/><rect x="5" y="5" ry="20" rx="20" width="290" height="410" stroke="#FFF" stroke-width="2" fill="url(#g)"/><text class="s" x="20" y="36">';
        parts[1] = '</text><text class="p" text-anchor="end" x="280" y="36">gwei</text><text class="p" text-anchor="middle" x="150" y="226" style="font-size:108px">';
        parts[2] = '</text><text class="s" text-anchor="end" x="280" y="394">';
        parts[3] = '</text><path fill="#8A92B2" d="M30.794 381.006V368L20 385.912z"/><path fill="#62688F" d="M30.794 392.294v-11.288L20 385.912zm0-11.288 10.796 4.906L30.794 368z"/><path fill="#454A75" d="M30.794 381.006v11.288l10.796-6.382z"/><path fill="#8A92B2" d="M30.794 394.338 20 387.96l10.794 15.212z"/><path fill="#62688F" d="m41.596 387.96-10.802 6.378v8.834z"/></svg>';

        bytes memory svgBytes = bytes(string(abi.encodePacked(parts[0], _gwei, parts[1], _gwei, parts[2], _gwei, parts[3])));
        string memory svgBase64Encoded = Base64.encode(svgBytes);
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function formatTokenURI(string memory _imageURI, string memory _gwei) public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', _gwei,
                            ' Gwei", "description": "GasCards are on-chain reminders of how much you once paid for gas"',
                            ', "attributes": { "gwei" : "', _gwei, '"}',
                            ', "image":"', _imageURI, '"}'
                        )
                    )
                )
            )
        );
    }

    // Public minting function
    function mint() external payable {
        require(msg.sender == tx.origin, "Minting to bots or smart contracts isn't allowed");
        require(msg.value == MINT_PRICE, "Wrong price");

        string memory _gwei = Strings.toString((tx.gasprice / 1_000_000_000));
        _mint(msg.sender, _tokenIdCounter.current());
        string memory imageURI = svgToImageURI(_gwei);
        _setTokenURI(_tokenIdCounter.current(), formatTokenURI(imageURI, _gwei));
        emit tokenChanged(_tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    // Contract URI functions
    function setContractURI(string memory contractURI_) public onlyOwner() {
        _contractURI = string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(contractURI_))));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // Overrides required for ERC721Enumerable.
    function withdraw(address payable _to) public onlyOwner() {
        uint256 balance = address(this).balance;
        _to.transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Overrides required for ERC721URIStorage.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner() {
        _setTokenURI(_tokenId, _tokenURI);
        emit tokenChanged(_tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}