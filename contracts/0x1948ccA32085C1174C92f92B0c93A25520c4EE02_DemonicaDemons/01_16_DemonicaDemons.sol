// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Mintable.sol";

contract DemonicaDemons is Ownable, ERC721, ReentrancyGuard, Mintable {
    using Strings for uint256;

    address private constant TEAM = 0x87003EE80aF44E57bb530a83F557F167d48ABB33;
    
    bool public isPublicLive = true;
    bool public isRevealed = true;

    bytes32 public merkleRoot;
    string private _baseTokenURI = "https://demonica.azurewebsites.net/api/metadata/characters/demons/";
    string private _contractURI = "https://demonica.azurewebsites.net/api/metadata/characters/demons";
    string private _notRevealedBaseTokenURI = "";

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {}

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }
    
    // Set whitelist
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function flipPublicState() external onlyOwner {
        isPublicLive = !isPublicLive;
    }

    function flipIsRevealedState() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        if (isRevealed == false) {
            return _notRevealedBaseTokenURI;
        }

        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string calldata uri) external onlyOwner {
         _contractURI = uri;
    }

    function setNotRevealedBaseURI(string calldata _notRevealedTokenUri) external onlyOwner {
        _notRevealedBaseTokenURI = _notRevealedTokenUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() external onlyOwner {
        payable(TEAM).transfer(address(this).balance);
    }
}