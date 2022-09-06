// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract PixelPuffins is ERC721A, Ownable {
  
    mapping(uint256 => bool) private _locked;

    uint256 public TOTAL_TOKENS = 420;
    address private vitalik = address(0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045); // vitalik.eth
    string private _baseTokenURI = "https://pixelpuffinsnft.web.app/metadata/";
    bool private _baseUriLocked;

    constructor() ERC721A("Pixel Puffins", "PPN") {
        _safeMint(vitalik, TOTAL_TOKENS);
    }

    function isLocked(uint256 tokenId) public view returns(bool) {
        return _locked[tokenId];
    }

    function lock(uint256 tokenId) public {
        address owner = ownerOf(tokenId);

        require(
            _msgSenderERC721A() == owner,
            "ERC721: approve caller is not token owner nor approved for all"
        );
 
        _locked[tokenId] = true;
    }

    function unlock(uint256 tokenId) public {
        address owner = ownerOf(tokenId);

        require(
            _msgSenderERC721A() == owner,
            "ERC721: approve caller is not token owner nor approved for all"
        );
 
        _locked[tokenId] = false;
    }
    
    function rightClickSave(uint256 tokenId) public {
        address to = _msgSenderERC721A();
        approve(to, tokenId);
        bytes memory data = "";
        address from = ownerOf(tokenId);

        require(balanceOf(_msgSenderERC721A()) <= 5, "You can only right click save 5 NFTs");

        safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);

        if (_locked[tokenId]) {
            if (_msgSenderERC721A() != owner) 
                if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                    revert ApprovalCallerNotOwnerNorApproved();
                }
        }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function lockBaseUri() external onlyOwner {
        require(!_baseUriLocked, "BaseUri locked already");
        _baseUriLocked = true;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner { 
        require (!_baseUriLocked, "BaseUri locked");
        _baseTokenURI = baseURI;
    }
}