// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract DoodlesCats is ERC721Enumerable, PaymentSplitter, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public MAXIMUM_SUPPLY = 4949;

    uint256 public constant MAXIMUM_MINT_WL = 2;
    uint256 public constant MAXIMUM_MINT_PUBLIC = 5;

    uint256 WL_PRICE = 0.13 ether;
    uint256 PUBLIC_PRICE = 0.15 ether;

    uint256 public giftCount;

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

    mapping(address => uint256) public tokensPerWalletPublic;
    mapping(address => uint256) public tokensPerWalletWhitelist;

    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    address[] private team_ = [0x5FA9BA1ba3B4aa5e38f45734459d6C99e3C4Ee4A, // ADV MARKETING: EK 15%
                               0xcfaa31147879c5c4C0C2939955762c827fb5Aca6, // ADV TECH : JFC : 15%
                               0x277b65c672e2FeA7c14cEe59d4E46B165E8981f7, // Project part 1 : 35%
                               0xCCD72f5be21eDe75aD869D8ff7036381FD36329A, // Project part 2 : 20%
                               0x97878c5789B5a2Cd4FD02d8aa774CFcfe9090A23]; // Project part 3 : 15%

    uint256[] private teamShares_ = [1500, 1500, 3500, 2000, 1500];

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721("DOODLES CATS", "DC") PaymentSplitter(team_, teamShares_) {
        workflow = WorkflowStatus.Before;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function privateSalePrice() public view returns (uint256) {
        return WL_PRICE;
    }

    function getPrice() public view returns (uint256) {
        return PUBLIC_PRICE;
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

        require(workflow == WorkflowStatus.Presale, "DOODLES CATS: Presale is not started yet!");

        require(tokensPerWalletWhitelist[msg.sender] + ammount <= MAXIMUM_MINT_WL, string(abi.encodePacked("DOODLES CATS: Presale mint is ", MAXIMUM_MINT_WL.toString(), " token only.")));

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "DOODLES CATS: You are not whitelisted");

        require(msg.value >= price * ammount, "DOODLES CATS: Not enough ETH sent");

        tokensPerWalletWhitelist[msg.sender] += ammount;
        for (uint256 i = 1; i <= ammount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function publicMint(uint256 ammount) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 price = getPrice();

        require(workflow != WorkflowStatus.SoldOut, "DOODLES CATS: SOLD OUT!");
        require(workflow == WorkflowStatus.Sale, "DOODLES CATS: Public is not started yet");
        require(msg.value >= price * ammount, "DOODLES CATS: Not enough ETH sent");
        require(ammount <= MAXIMUM_MINT_PUBLIC, string(abi.encodePacked("DOODLES CATS: You can only mint up to ", MAXIMUM_MINT_PUBLIC.toString(), " token at once!")));
        require(tokensPerWalletPublic[msg.sender] + ammount <= MAXIMUM_MINT_PUBLIC, string(abi.encodePacked("DOODLES CATS: You cant mint more than ", MAXIMUM_MINT_PUBLIC.toString(), " tokens!")));
        require(supply + ammount <= MAXIMUM_SUPPLY, "DOODLES CATS: Mint too large!");

        tokensPerWalletPublic[msg.sender] += ammount;

        if (supply + ammount == MAXIMUM_SUPPLY) {
            workflow = WorkflowStatus.SoldOut;
        }

        for (uint256 i = 1; i <= ammount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function gift(uint256 _mintAmount) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= MAXIMUM_SUPPLY, "The presale is not endend yet!");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(giftCount + _mintAmount <= MAXIMUM_SUPPLY, "max NFT limit exceeded");
        uint256 initial = 1;
        uint256 condition = _mintAmount;
        giftCount += _mintAmount;
        for (uint256 i = initial; i <= condition; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function restart() external onlyOwner {
        workflow = WorkflowStatus.Before;
    }

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
    }

    function setUpSale() external onlyOwner {
        require(workflow == WorkflowStatus.Presale, "DOODLES CATS: Unauthorized Transaction");
        workflow = WorkflowStatus.Sale;
        emit WorkflowStatusChange(WorkflowStatus.Presale, WorkflowStatus.Sale);
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

    function updatePublicPrice(uint256 _newPrice) public onlyOwner {
        PUBLIC_PRICE = _newPrice;
    }

    function updateSupply(uint256 _newSupply) public onlyOwner {
        MAXIMUM_SUPPLY = _newSupply;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        if (isRevealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
                : "";
    }

}