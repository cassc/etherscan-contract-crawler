// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HookedPickaxe is ERC721, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant GAMER_ROLE = keccak256("GAMER_ROLE");
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => uint256) public adventures;
    mapping(uint256 => uint256) public level;

    event LevelUp(uint256 indexed to, uint256 value);

    constructor() ERC721("Hooked Pickaxe", "HPA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function adventure(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not token owner nor approved");
        adventures[tokenId] += 1;
    }

    function levelUp(uint256 tokenId) external onlyRole(GAMER_ROLE) {
        _requireMinted(tokenId);
        level[tokenId] += 1;
        emit LevelUp(tokenId, level[tokenId]);
    }

    function mint(address to) external onlyRole(GAMER_ROLE) {
        require(balanceOf(to) == 0, "Wallet HPA limit exceeded");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        level[tokenId] = 1;
        _mint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[5] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 200 200"><style>.base { fill: white; font-family: serif; font-size: 18px; }</style><rect width="100%" height="100%" fill="black" /><text x="30" y="80" class="base">';
        parts[1] = string(abi.encodePacked("Level", " ", Strings.toString(level[tokenId])));
        parts[2] = '</text><text x="30" y="110" class="base">';
        parts[3] = string(abi.encodePacked("Adventures", " ", Strings.toString(adventures[tokenId])));
        parts[4] = '</text></svg>';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Hooked Pickaxe #', Strings.toString(tokenId), '", "description": "The fortune explorer that gives access for one to earn and own the first share of crypto in Hooked platform.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }


    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}