//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "ERC721A.sol";

contract Othersiderz is ERC721A, Ownable {
    using Strings for uint;

    string private baseTokenURI;
    string private notRevealedUri;
    bytes32 private whitelistRoot;

    uint256 public cost = 0.1 ether;
    uint256 public maxSupply = 600;
    uint256 public maxByWallet = 5;
    mapping(address => uint) public mintedAddressData;

    uint256 public step = 1;
    bool public revealed = false;

    // 1 = closed
    // 2 = Whitelist
    // 3 = Opensale

    constructor() ERC721A("Othersiderz", "OS") {}

    function mint(uint256 amount) public payable {
        require(step == 3, "Mint is closed");
        require(totalSupply() + amount <= maxSupply, "Sold out !");
        require(
            mintedAddressData[msg.sender] + amount <= maxByWallet,
            "You have mint the maximum of nft"
        );
        require(msg.value >= cost * amount, "Not enough ether sended");

        mintedAddressData[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function crossmint(uint256 amount, address _to) public payable {
        require(step == 3, "Mint is closed");
        require(totalSupply() + amount <= maxSupply, "Sold out !");
        require(msg.value >= cost * amount, "Not enough ether sended");
        require(msg.sender == 0xdAb1a1854214684acE522439684a145E62505233,
        "This function is for Crossmint only."
        );

        _safeMint(_to, amount);
    }

    function mintWl(uint256 amount, bytes32[] calldata proof) public payable {
        require(step == 2, "WL Mint is closed");
        require(isWhitelisted(msg.sender, proof), "You are not in the Whitelist");
        require(totalSupply() + amount <= maxSupply, "Sold out !");

        uint256 walletBalance = _numberMinted(msg.sender);
        require(
            walletBalance + amount <= maxByWallet,
            "You have mint the maximum of nft"
        );
        require(msg.value >= cost * amount, "Not enough ether sended");

        _safeMint(msg.sender, amount);
    }

    function gift(uint256 amount, address to) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Sold out");

        _safeMint(to, amount);
    }

    function isWhitelisted(address account, bytes32[] calldata proof)
        internal
        view
        returns (bool)
    {
        return _verify(_leaf(account), proof, whitelistRoot);
    }

    function setWhitelistRoot(bytes32 newWhitelistroot) public onlyOwner {
        whitelistRoot = newWhitelistroot;
    }

    function switchStep(uint256 newStep) public onlyOwner {
        step = newStep;
    }

    function setCost(uint256 newCost) public onlyOwner {
        cost = newCost;
    }

    function setMaxByWallet(uint256 newMaxByWallet) public onlyOwner {
        maxByWallet = newMaxByWallet;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseTokenURI = newBaseURI;
    }

    function _baseUri() internal view virtual returns (string memory) {
        return baseTokenURI;
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(
        bytes32 leaf,
        bytes32[] memory proof,
        bytes32 root
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseUri();
        return string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"));
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}