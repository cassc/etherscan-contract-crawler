//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract STARCUB is ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;

    string public baseURI;
    uint256 public MAX_SUPPLY = 9999;
    uint256 public tokenId = 1;

    address public eyewitness = 0x6f9990411b0c0596129784D8681f79272aC9D9a6;
    mapping(address => bool) public isMint;


    constructor() ERC721("STAR CUB", "STAR CUB") {}

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function mint(uint8 v, bytes32 r, bytes32 s) public {
        require(totalSupply() <= MAX_SUPPLY, "Over maximum supply");
        require(ecrecover(keccak256(abi.encodePacked(msg.sender)), v, r, s) == eyewitness, 'INVALID_SIGNATURE');
        require(!isMint[msg.sender], "Address already mint");
        isMint[msg.sender] = true;
        _safeMint(msg.sender, tokenId);
        tokenId++;
    }

    function adminMint(uint16 num_) public onlyOwner {
        for(uint16 i; i< num_; i++) {
            require(totalSupply() <= MAX_SUPPLY, "Over maximum supply");
            _safeMint(owner(), tokenId);
            tokenId++;
        }
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