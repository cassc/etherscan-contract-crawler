// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RudeKidz is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public MAXIMUM_SUPPLY = 7777;

    uint256 public constant MAXIMUM_MINT_WL = 2;
    uint256 public constant MAXIMUM_MINT_RAFFLE = 2;

    uint256 WL_PRICE = 0.29 ether;
    uint256 RAFFLE_PRICE = 0.29 ether;

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

    mapping(address => uint256) public tokensPerWalletRaffle;
    mapping(address => uint256) public tokensPerWalletWhitelist;

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A("RUDE KIDZ", "RKZ") {
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
        uint256 price = privateSalePrice();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(workflow == WorkflowStatus.Presale, "RUDE KIDZ: Presale is not started yet!");
        require(tokensPerWalletWhitelist[msg.sender] + ammount <= MAXIMUM_MINT_WL, string(abi.encodePacked("RUDE KIDZ: Presale mint is ", MAXIMUM_MINT_WL.toString(), " token only.")));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "RUDE KIDZ: You are not whitelisted");
        require(msg.value >= price * ammount, "RUDE KIDZ: Not enough ETH sent");

        tokensPerWalletWhitelist[msg.sender] += ammount;
        _safeMint(msg.sender, ammount);
    }

    function raffleMint(uint256 ammount) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 price = getPrice();

        require(workflow != WorkflowStatus.SoldOut, "RUDE KIDZ: SOLD OUT!");
        require(workflow == WorkflowStatus.Sale, "RUDE KIDZ: Raffle is not started yet");
        require(msg.value >= price * ammount, "RUDE KIDZ: Not enough ETH sent");
        require(ammount <= MAXIMUM_MINT_RAFFLE, string(abi.encodePacked("RUDE KIDZ: You can only mint up to ", MAXIMUM_MINT_RAFFLE.toString(), " token at once!")));
        require(tokensPerWalletRaffle[msg.sender] + ammount <= MAXIMUM_MINT_RAFFLE, string(abi.encodePacked("RUDE KIDZ: You cant mint more than ", MAXIMUM_MINT_RAFFLE.toString(), " tokens!")));
        require(supply + ammount <= MAXIMUM_SUPPLY, "RUDE KIDZ: Mint too large!");

        tokensPerWalletRaffle[msg.sender] += ammount;

        if(supply + ammount == MAXIMUM_SUPPLY) {
          workflow = WorkflowStatus.SoldOut;
        }

        _safeMint(msg.sender, ammount);
    }

    function gift(address[] calldata addresses) public onlyOwner {
        require(addresses.length > 0, "RUDE KIDZ : Need to gift at least 1 NFT");
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
        payable(0x0b94251DC32F5419103582026B10edCCD1F06012).transfer(((_balance * 2000) / 10000));
        payable(0x82925659dA88055457d1a54F83e82a933edeea6C).transfer(((_balance * 50) / 10000));
        payable(0x7769D6A10e54A8149FF0c985615e9fbecC632f7B).transfer(((_balance * 2000) / 10000));
        payable(0x52AD4186A8Ef9C1b3aAA6D6DCA01f8D489F90744).transfer(((_balance * 100) / 10000));
        payable(0xB75f0036bb9D7cc0936Edc1398A470C1542bb1Ef).transfer(((_balance * 100) / 10000));
        payable(0x00fE07FC82A9717E8E91c8a760E55460224D7CC0).transfer(((_balance * 5750) / 10000));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (isRevealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

}