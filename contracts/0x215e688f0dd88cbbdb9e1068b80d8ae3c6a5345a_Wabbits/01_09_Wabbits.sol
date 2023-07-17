//SPDX-License-Identifier: MIT
//IN BILLIONAIRE WE TRUST

pragma solidity ^0.8.7;


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import ".deps/npm/@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract Wabbits is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 111;
    uint256 public constant WHITELIST_PRICE = 0.03 ether;
    uint256 public constant PUBLIC_PRICE = 0.03 ether;

    uint256 public constant MAX_QUANTITY = 1;


    mapping(address => bool) public whitelistedMint;
    mapping(address => bool) public publicMint;

    bool public mintTime = false;
    bool public publicMintTime = false;

    string private baseTokenUri = "https://stfupals.mypinata.cloud/ipfs/QmWGZ48ZrV8TbeiiiVYh8GU5u3bPwiY7dE1Ax8cg8Cdf93/";

    bytes32 public whitelistMerkleRoot = 0xf7eb5e446b8eaa3227510168a0cf0908ec7e8d5bdd71f36fe3d4361ac11a06b7;

    constructor() ERC721A("Wabbits", "WBT") {

        _safeMint(0x5668D454a0594a0A18B720080eC3052C5Ecf871E, 1);

    }


    function whitelistMint(bytes32[] calldata _merkleProof) external payable {

        require((totalSupply() + MAX_QUANTITY) <= MAX_SUPPLY, "Out Of Stock!");
        require(mintTime, "It is not time to mint");
        require(whitelistedMint[msg.sender] == false, "Already Minted!");
        require(msg.value >= WHITELIST_PRICE, "Not enough Ether");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Invalid Merkle Proof");

            whitelistedMint[msg.sender] = true;
            _safeMint(msg.sender, MAX_QUANTITY);

    }

    function mint() external payable {

        require((totalSupply() + MAX_QUANTITY) <= MAX_SUPPLY, "Out Of Stock!");
        require(publicMintTime, "It is not time to mint");
        require(publicMint[msg.sender] == false, "Already Minted!");
        require(msg.value >= PUBLIC_PRICE, "Not enough Ether");

            publicMint[msg.sender] = true;
            _safeMint(msg.sender, MAX_QUANTITY);

    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId;

        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    function setTokenURI(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function flipState() public onlyOwner {

        mintTime = !mintTime;
    }

    function flipStatePublic() public onlyOwner {

        publicMintTime = !publicMintTime;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {

        whitelistMerkleRoot = _merkleRoot;

    }

    function withdraw() external onlyOwner {

        uint256 balance = address(this).balance;

        Address.sendValue(payable(owner()), balance);
    }

}