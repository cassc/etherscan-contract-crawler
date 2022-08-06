// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Degen is ERC721A, Ownable {

    uint256 public constant MAX_SUPPLY = 2500;
    uint256 public constant MAX_MINT_PER_TX = 5;
    uint256 public constant PAID_PRICE = 0.001 ether;

    string private baseTokenUri = "ipfs://bafybeigwh7lwtsy7evpznp4wmqlxprq7doqruricmtmm7op3yzmlk5orsa/";

    constructor() ERC721A("Nightbirds", "NIGHTBIRD") {

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        require(_quantity <= MAX_MINT_PER_TX, "Exceeded max quantity per tx");
        require(msg.value >= _quantity * PAID_PRICE - PAID_PRICE);
        _safeMint(msg.sender, _quantity);
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, _toString(tokenId), ".json")) : "";
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://bafybeifgzehdlhsgessvtcreltkl6lzw2767zeib53af5bvvl6kpj2zony/contractMD.json";
    }

    function withdraw() external onlyOwner {
        payable(0x22B7Ef67859eE837060bF6b753E12Fc2dc43a372).transfer(address(this).balance);
    }
}