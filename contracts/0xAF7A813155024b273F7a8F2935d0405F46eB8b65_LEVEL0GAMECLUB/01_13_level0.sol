//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LEVEL0GAMECLUB is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    uint256 public MAX_SUPPLY = 9999;
    uint256 public tokenId = 1;

    address public eyewitness = 0xF1B025679e530A6484B3C00aAF1006Fd47EaFA7a;
    mapping(address => bool) public isMint;


    constructor() ERC721("LEVEL.0 GAME CLUB", "LEVEL.0 GAME CLUB") {}

    function mint(uint8 v, bytes32 r, bytes32 s) public {
        require(totalSupply() <= MAX_SUPPLY, "Over maximum supply");
        require(ecrecover(keccak256(abi.encodePacked(msg.sender)), v, r, s) == eyewitness, 'INVALID_SIGNATURE');
        require(!isMint[msg.sender], "Address invalid");
        isMint[msg.sender] = true;
        _safeMint(msg.sender, tokenId);
        tokenId++;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        _requireMinted(_tokenId);

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json")) : "";
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setEyewitness(address addr) public onlyOwner {
        require(addr != address(0), "addr is 0");
        eyewitness = addr;
    }
}