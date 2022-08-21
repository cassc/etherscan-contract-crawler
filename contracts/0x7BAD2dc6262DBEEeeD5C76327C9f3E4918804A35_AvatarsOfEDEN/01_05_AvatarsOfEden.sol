// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AvatarsOfEDEN is ERC721A, Ownable {

    uint256 public constant MAX_SUPPLY = 333;
    uint256 public constant MAX_MINT_PER_TX = 2;
    uint256 public constant PAID_PRICE = 0.009 ether;

    bool public teamMinted;

    string private baseTokenUri = "ipfs://bafybeib65k3y4pkua5i5ygpqu3wodgbhd6kqyn5edoz7dikxdjd5f4sjnm/";

    constructor() ERC721A("Avatars of EDEN", "EDEN") {

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        require(_quantity <= MAX_MINT_PER_TX, "Exceeded max quantity per tx");
        require(msg.value >= _quantity * PAID_PRICE);
        _safeMint(msg.sender, _quantity);
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, _toString(tokenId), ".json")) : "";
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://bafkreia7he2aw5uil5rpj573za7uq3qwp5jhqxpvdzavrzs6sbyg7amwhi";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function teamMint() external onlyOwner {
        require(!teamMinted, "Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 10);
    }

    function withdraw() external onlyOwner {
        payable(0x22B7Ef67859eE837060bF6b753E12Fc2dc43a372).transfer(address(this).balance/5);
        payable(0x983EBd97102dbFf830b77D083c149c494E3Cd2D5).transfer(address(this).balance);
    }
}