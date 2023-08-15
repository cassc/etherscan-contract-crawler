// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SmartBeast is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public MAXIMUM_SUPPLY = 5555;
    uint256 public constant MAXIMUM_MINT = 2;

    uint256 WL_PRICE = 0.20 ether;
    uint256 RAFFLE_PRICE = 0.20 ether;

    bytes32 public merkleRoot;

    string public baseURI;
    string public notRevealedUri;

    bool public isRevealed = false;

    enum WorkflowStatus {
        Before,
        Presale,
        Sale,
        SoldOut,
        Reveal
    }

    WorkflowStatus public workflow;

    mapping(address => uint256) public tokensPerWallet;

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A("SMART BEAST", "SB") {
        workflow = WorkflowStatus.Before;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function privateSalePrice() public view returns (uint256) {
        return WL_PRICE;
    }

    function getPrice() public view returns (uint256) {
        return RAFFLE_PRICE;
    }

    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function hasWhitelist(bytes32[] calldata _merkleProof) public view returns (bool) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function presaleMint(uint256 ammount, bytes32[] calldata _merkleProof) external payable nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 price = privateSalePrice();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(workflow != WorkflowStatus.SoldOut, "SMART BEAST: SOLD OUT!");
        require(workflow == WorkflowStatus.Presale, "SMART BEAST: Presale is not started yet!");
        require(msg.value >= price * ammount, "SMART BEAST: Not enough ETH sent");
        require(tokensPerWallet[msg.sender] + ammount <= MAXIMUM_MINT, string(abi.encodePacked("SMART BEAST: Mint is ", MAXIMUM_MINT.toString(), " token only.")));
        require(supply + ammount <= MAXIMUM_SUPPLY, "SMART BEAST: Mint too large!");
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "SMART BEAST: You are not whitelisted");

        tokensPerWallet[msg.sender] += ammount;

        if(supply + ammount == MAXIMUM_SUPPLY) {
          workflow = WorkflowStatus.SoldOut;
        }

        _safeMint(msg.sender, ammount);
    }

    function raffleMint(uint256 ammount) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 price = getPrice();

        require(workflow != WorkflowStatus.SoldOut, "SMART BEAST: SOLD OUT!");
        require(workflow == WorkflowStatus.Sale, "SMART BEAST: Raffle is not started yet");
        require(msg.value >= price * ammount, "SMART BEAST: Not enough ETH sent");
        require(ammount <= MAXIMUM_MINT, string(abi.encodePacked("SMART BEAST: You can only mint up to ", MAXIMUM_MINT.toString(), " token at once!")));
        require(tokensPerWallet[msg.sender] + ammount <= MAXIMUM_MINT, string(abi.encodePacked("SMART BEAST: You cant mint more than ", MAXIMUM_MINT.toString(), " tokens!")));
        require(supply + ammount <= MAXIMUM_SUPPLY, "SMART BEAST: Mint too large!");

        tokensPerWallet[msg.sender] += ammount;

        if(supply + ammount == MAXIMUM_SUPPLY) {
          workflow = WorkflowStatus.SoldOut;
        }

        _safeMint(msg.sender, ammount);
    }

    function gift(address[] calldata addresses) public onlyOwner {
        require(addresses.length > 0, "SMART BEAST : Need to gift at least 1 NFT");
        for (uint256 i = 0; i < addresses.length; i++) {
          _safeMint(addresses[i], 1);
        }
    }

    function restart() external onlyOwner {
        workflow = WorkflowStatus.Before;
    }

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
    }

    function setUpSale() external onlyOwner {
        workflow = WorkflowStatus.Sale;
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function reveal() public onlyOwner {
        isRevealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function updateWLPrice(uint256 _newPrice) public onlyOwner {
        WL_PRICE = _newPrice;
    }

    function updateRafflePrice(uint256 _newPrice) public onlyOwner {
        RAFFLE_PRICE = _newPrice;
    }

    function updateSupply(uint256 _newSupply) public onlyOwner {
        MAXIMUM_SUPPLY = _newSupply;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        payable(0x956754eeA58E37090A95D44145C425F9E45FeC23).transfer(((_balance * 5000) / 10000));
        payable(0xfC00D9058356fc86bC39bA0795475e496C8A3ef2).transfer(((_balance * 5000) / 10000));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (isRevealed == false) {
          return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

}