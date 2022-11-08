//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AbstractNouveau is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 999;
    uint256 public constant WHITELIST_PRICE = 0.07 ether;
    uint256 public constant PUBLIC_PRICE = 0.09 ether;

    uint256 public constant MAX_QUANTITY = 2;

    mapping(address => uint256) public hasMinted;

    bool public mintTime = false;
    bool public publicMintTime = false;

    string private baseTokenUri = "";

    bytes32 public whitelistMerkleRoot = 0x73739025a6474df67aa5c5cf067afa3492de621fab7b24b393899b3ebed95b08;

    constructor() ERC721A("Abstract Nouveau", "AN") {

    }

    function whitelistMint(uint256 _quantity, bytes32[] calldata _merkleProof) external payable {

        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Out Of Stock!");
        require(mintTime, "It is not time to mint");
        require(hasMinted[msg.sender] + _quantity <= MAX_QUANTITY, "Already Minted!");
        require(msg.value >= WHITELIST_PRICE * _quantity, "Not enough Ether");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Invalid Merkle Proof");

            hasMinted[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);

    }

    function mint(uint256 _quantity) external payable {

        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Out Of Stock!");
        require(publicMintTime, "It is not time to mint");
        require(hasMinted[msg.sender] + _quantity <= MAX_QUANTITY, "Already Minted!");
        require(msg.value >= PUBLIC_PRICE * _quantity, "Not enough Ether");
            
            
            hasMinted[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);

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