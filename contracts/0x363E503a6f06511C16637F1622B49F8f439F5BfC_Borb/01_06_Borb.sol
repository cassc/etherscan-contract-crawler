// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Borb is ERC721A, Ownable {

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant PUBLIC_FREE_SUPPLY = 1000; // not including 1000 free for WL
    uint256 public constant MAX_MINT_PER_TX = 5;
    uint256 public PUBLIC_SALE_PRICE = 0.0077 ether;

    string private baseTokenUri;
    string public  placeholderTokenUri = "ipfs://bafkreibryhtn47nmq7qujrpeektpmfk4ub4vymtlczb2ysxnijah2gmosy";

    bool public isRevealed;
    bool public isPublicLive;
    bool public isWhitelistLive;
    bool public teamMinted;

    bytes32 private merkleRoot;

    mapping(address => bool) public addressClaimed;
    uint256 public numFreeMinted = 0;

    constructor() ERC721A("borb", "BORB") {

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Borb :: Cannot be called by a contract");
        _;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(isPublicLive, "Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        require(_quantity <= MAX_MINT_PER_TX, "Exceeded max quantity per tx");
        if (numFreeMinted >= PUBLIC_FREE_SUPPLY || addressClaimed[msg.sender]) {
            require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Payment is below the price");
        } else {
            // 1 free mint
            require(msg.value + PUBLIC_SALE_PRICE >= PUBLIC_SALE_PRICE * _quantity, "Payment is below the price");
            addressClaimed[msg.sender] = true;
            numFreeMinted += 1;
        }

        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser {
        require(isWhitelistLive, "Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond max supply");
        require(_quantity <= MAX_MINT_PER_TX, "Exceeded max quantity per tx");
        require(!addressClaimed[msg.sender], "Already claimed whitelist mint!");
        require(msg.value + PUBLIC_SALE_PRICE >= PUBLIC_SALE_PRICE * _quantity, "Payment is below the price");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender)); // leaf
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "You are not whitelisted");

        addressClaimed[msg.sender] = true;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner {
        require(!teamMinted, "Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 10);
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if(!isRevealed){
            return placeholderTokenUri;
        }

        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, _toString(tokenId), ".json")) : "";
    }

    // include ipfs:// and end slash
    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner {
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        PUBLIC_SALE_PRICE = price;
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://bafkreidjzwcxmvacjg6r3apezifmdsd72u7xyvistdn76rw75iha55o6bq";
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    function togglePublic() external onlyOwner {
        isPublicLive = !isPublicLive;
    }

    function toggleWhitelist() external onlyOwner {
        isWhitelistLive = !isWhitelistLive;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner {
        uint256 withdrawPortion = address(this).balance / 3;
        payable(0x40cD24A31f44BC398065E9Da992dFB938986e630).transfer(withdrawPortion);
        payable(0x22B7Ef67859eE837060bF6b753E12Fc2dc43a372).transfer(withdrawPortion);
        payable(0xc1410eAC1Ef23fA97D768Ee36a0540209398E5a7).transfer(address(this).balance);
    }
}