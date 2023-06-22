// SPDX-License-Identifier: MIT
/*
+  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +
+                                                                                                                          +
+                                                                                                                          +
+                                                                     iiii  lllllll   1111111   555555SEASON:THREE         +
+                                                                    i::::i l:::::l  1::::::1   5::::::::::::::::5         +
+                                                                     iiii  l:::::l 1:::::::1   5::::::::::::::::5         +
+                                                                           l:::::l 111:::::1   5:::::555555555555         +
+          aaaaaaaaaaaaavvvvvvv           vvvvvvvrrrrr   rrrrrrrrr  iiiiiii  l::::l    1::::1   5:::::5                    +
+          a::::::::::::av:::::v         v:::::v r::::rrr:::::::::r i:::::i  l::::l    1::::1   5:::::5                    +
+          aaaaaaaaa:::::av:::::v       v:::::v  r:::::::::::::::::r i::::i  l::::l    1::::1   5:::::5555555555           +
+                   a::::a v:::::v     v:::::v   rr::::::rrrrr::::::ri::::i  l::::l    1::::l   5:::::::::::::::5          +
+            aaaaaaa:::::a  v:::::v   v:::::v     r:::::r     r:::::ri::::i  l::::l    1::::l   555555555555:::::5         +
+          aa::::::::::::a   v:::::v v:::::v      r:::::r     rrrrrrri::::i  l::::l    1::::l               5:::::5        +
+         a::::aaaa::::::a    v:::::v:::::v       r:::::r            i::::i  l::::l    1::::l               5:::::5        +
+        a::::a    a:::::a     v:::::::::v        r:::::r            i::::i  l::::l    1::::l   5555555     5:::::5        +
+        a::::a    a:::::a      v:::::::v         r:::::r           i::::::il::::::l111::::::1115::::::55555::::::5        +
+        a:::::aaaa::::::a       v:::::v          r:::::r           i::::::il::::::l1::::::::::1 55:::::::::::::55         +
+         a::::::::::aa:::a       v:::v           r:::::r           i::::::il::::::l1::::::::::1   55:::::::::55           +
+          aaaaaaaaaa  aaaa        vvv            rrrrrrr           SEASON:THREEllll111111111111     555555555             +
+                                                                                                                          +
+                                                                                                                          +
+  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +  +
*/

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DefaultOperatorFilterer.sol";

contract Avril15SeasonThree is ERC721A, Ownable, ERC2981, DefaultOperatorFilterer {
    uint256 maxSupply = 375;
    address payable public creator;
    uint96 royaltyFeesInBips;
    address royaltyReceiver;
	string public baseURI = "ipfs://QmXps813AvChPccABu87ZGmABgPc9FvVY79nNLtE1uCKT6/";
	bool public _frozenMeta;

    constructor() ERC721A("Avril15 Season Three", "AVRIL15_S3") {
        _frozenMeta = false;
        royaltyFeesInBips = 1000;
        royaltyReceiver = msg.sender;
    }

    // Owner mint function
    function ownerMint(uint256 quantity) external payable onlyOwner {
		require(totalSupply() + quantity <= maxSupply, "Exceeded maxSupply of 375.");
		_safeMint(msg.sender, quantity);
	}

    // Change Base URI functions
    function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

    // Append .JSON to metadata files
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
		require(!_frozenMeta, "Uri frozen");
		baseURI = baseURI_;
	}

    // WARNING! This function allows the owner of the contract to PERMANENTLY freeze the metadata.
	function freezeMetadata() public onlyOwner {
        _frozenMeta = true;
    }

    // Override supportsInterface() function from both ERC721A and ERC2981 contracts
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //Royalty functions
    function setRoyaltyAddress (address _receiver) public onlyOwner {
        royaltyReceiver = _receiver;
    }

    function setRoyaltyInfo (address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    // OpenSea Operator Filter Registry
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}