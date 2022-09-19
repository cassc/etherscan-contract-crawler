//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract POTATO is Ownable, ERC721A {
    uint256 constant public maxSupply = 3333;
    uint256 public publicPrice = 0.02 ether;
    string public revealedURI = "ipfs:// ----IFPS---/";
    bool public whiteMintEnabled = true;
    bool public publicMintEnabled = false;
    uint256 constant public whiteMintNum = 1;
    uint256 constant public publicMintNum = 3;
    mapping(address => uint256) public WhiteMintedWallets;
    mapping(address => uint256) public PublicMintedWallets;

    bytes32 public root;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _revealedURI,
        bytes32 _root
    ) ERC721A(_name, _symbol) {
        revealedURI = _revealedURI;
        root = _root;
    }

    function setRoot(bytes32 _root) public onlyOwner {
        root = _root;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }


    function whiteMint(uint256 quantity, bytes32[] memory proof) external payable mintCompliance(quantity) {
        require(whiteMintEnabled,"Unable to mint on white");
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "user not in whitelist");
        require(maxSupply > totalSupply(), "sold out");
        uint256 currMints = WhiteMintedWallets[msg.sender];
        require(quantity <= whiteMintNum, "u want white mint too many");
        require(currMints + quantity  <= whiteMintNum, "u wanna mint too many");
        
        if(quantity <= whiteMintNum) {
            WhiteMintedWallets[msg.sender] = (currMints + quantity);
            _safeMint(msg.sender, quantity);
        }
    }

    function getWhiteMintNum() public view returns (uint256) {
        return WhiteMintedWallets[msg.sender];
    }


    function publicMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(publicMintEnabled,"Unable to mint on public");
        require(maxSupply > totalSupply(), "sold out");
        uint256 currMints = PublicMintedWallets[msg.sender];
        require(quantity <= publicMintNum, "u want white mint too many");
        require(currMints + quantity  <= publicMintNum, "u wanna mint too many");
        
        if(quantity <= publicMintNum) {
            require(msg.value >= (quantity) * publicPrice, "give me more money");
            PublicMintedWallets[msg.sender] = (currMints + quantity);
            _safeMint(msg.sender, quantity);
        }
    }

    function getpublicMintNum() public view returns (uint256) {
        return PublicMintedWallets[msg.sender];
    }

    function ShowTotalSupply() public view returns (uint256) {
        return totalSupply();
    }
    

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }

        currentTokenId++;
        }

        return ownedTokenIds;
    }


    function contractURI() public view returns (string memory) {
        return revealedURI;
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        revealedURI = _contractURI;
    }

    function setWhiteMintEnabled(bool _state) public onlyOwner {
        whiteMintEnabled = _state;
    }

    function setPublicMintEnabled(bool _state) public onlyOwner {
        publicMintEnabled = _state;
    }
    

    function mintToUser(uint256 quantity, address receiver) public onlyOwner mintCompliance(quantity) {
        _safeMint(receiver, quantity);
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    modifier mintCompliance(uint256 quantity) {
        require(quantity != 0,"mint num is 0");
        require(totalSupply() + quantity <= maxSupply, "you cant become ugly anymore");
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}