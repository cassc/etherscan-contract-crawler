// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./KaizenConsole.sol";

contract Kaizen is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    KaizenConsole kaizenConsole;

    uint256 public MAXIMUM_SUPPLY = 10000;

    uint256 public constant MAXIMUM_MINT_WL = 50;
    uint256 public constant MAXIMUM_MINT_PUBLIC = 50;

    uint256 WL_PRICE = 0.30 ether;
    uint256 WL_BUNDLE_PRICE = 0.50 ether;

    uint256 PUBLIC_PRICE = 0.40 ether;
    uint256 PUBLIC_BUNDLE_PRICE = 0.60 ether;

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

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        address _kaizenConsoleAddress
    ) ERC721A("KAIZEN", "KZN") {
        kaizenConsole = KaizenConsole(_kaizenConsoleAddress);
        workflow = WorkflowStatus.Before;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function privateSalePrice() public view returns (uint256) {
        return WL_PRICE;
    }

    function privateSaleBundlePrice() public view returns (uint256) {
        return WL_BUNDLE_PRICE;
    }

    function getPrice() public view returns (uint256) {
        return PUBLIC_PRICE;
    }

    function getBundlePrice() public view returns (uint256) {
        return PUBLIC_BUNDLE_PRICE;
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

        require(workflow == WorkflowStatus.Presale, "KAIZEN: Presale is not started yet!");
        require(tokensPerWalletWhitelist[msg.sender] + ammount <= MAXIMUM_MINT_WL, string(abi.encodePacked("KAIZEN: Presale mint is ", MAXIMUM_MINT_WL.toString(), " token only.")));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "KAIZEN: You are not whitelisted");
        require(msg.value >= price * ammount, "KAIZEN: Not enough ETH sent");
        require(supply + ammount <= MAXIMUM_SUPPLY, "KAIZEN: Mint too large!");

        tokensPerWalletWhitelist[msg.sender] += ammount;

        if(supply + ammount == MAXIMUM_SUPPLY) {
          workflow = WorkflowStatus.SoldOut;
        }

        _safeMint(msg.sender, ammount);
    }

    function presaleBundleMint(uint256 ammount, bytes32[] calldata _merkleProof) external payable nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 price = privateSaleBundlePrice();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(workflow == WorkflowStatus.Presale, "KAIZEN: Presale is not started yet!");
        require(tokensPerWalletWhitelist[msg.sender] + ammount <= MAXIMUM_MINT_WL, string(abi.encodePacked("KAIZEN: Presale mint is ", MAXIMUM_MINT_WL.toString(), " token only.")));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "KAIZEN: You are not whitelisted");
        require(msg.value >= price * ammount, "KAIZEN: Not enough ETH sent");
        require(supply + ammount <= MAXIMUM_SUPPLY, "KAIZEN: Mint too large!");

        tokensPerWalletWhitelist[msg.sender] += ammount;

        if(supply + ammount == MAXIMUM_SUPPLY) {
          workflow = WorkflowStatus.SoldOut;
        }

        _safeMint(msg.sender, ammount);
        kaizenConsole.gift(msg.sender, ammount);
    }

    function publicMint(uint256 ammount) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 price = getPrice();

        require(workflow != WorkflowStatus.SoldOut, "KAIZEN: SOLD OUT!");
        require(workflow == WorkflowStatus.Sale, "KAIZEN: Public is not started yet");
        require(msg.value >= price * ammount, "KAIZEN: Not enough ETH sent");
        require(ammount <= MAXIMUM_MINT_PUBLIC, string(abi.encodePacked("KAIZEN: You can only mint up to ", MAXIMUM_MINT_PUBLIC.toString(), " token at once!")));
        require(tokensPerWalletPublic[msg.sender] + ammount <= MAXIMUM_MINT_PUBLIC, string(abi.encodePacked("KAIZEN: You cant mint more than ", MAXIMUM_MINT_PUBLIC.toString(), " tokens!")));
        require(supply + ammount <= MAXIMUM_SUPPLY, "KAIZEN: Mint too large!");

        tokensPerWalletPublic[msg.sender] += ammount;

        if(supply + ammount == MAXIMUM_SUPPLY) {
          workflow = WorkflowStatus.SoldOut;
        }

        _safeMint(msg.sender, ammount);
    }

    function publicBundleMint(uint256 ammount) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 price = getBundlePrice();

        require(workflow != WorkflowStatus.SoldOut, "KAIZEN: SOLD OUT!");
        require(workflow == WorkflowStatus.Sale, "KAIZEN: Public is not started yet");
        require(msg.value >= price * ammount, "KAIZEN: Not enough ETH sent");
        require(ammount <= MAXIMUM_MINT_PUBLIC, string(abi.encodePacked("KAIZEN: You can only mint up to ", MAXIMUM_MINT_PUBLIC.toString(), " token at once!")));
        require(tokensPerWalletPublic[msg.sender] + ammount <= MAXIMUM_MINT_PUBLIC, string(abi.encodePacked("KAIZEN: You cant mint more than ", MAXIMUM_MINT_PUBLIC.toString(), " tokens!")));
        require(supply + ammount <= MAXIMUM_SUPPLY, "KAIZEN: Mint too large!");

        tokensPerWalletPublic[msg.sender] += ammount;

        if(supply + ammount == MAXIMUM_SUPPLY) {
          workflow = WorkflowStatus.SoldOut;
        }

        _safeMint(msg.sender, ammount);
        kaizenConsole.gift(msg.sender, ammount);
    }

    function gift(address[] calldata addresses) public onlyOwner {
        require(addresses.length > 0, "KAIZEN : Need to gift at least 1 NFT");
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

    function updateWLBundlePrice(uint256 _newPrice) public onlyOwner {
        WL_BUNDLE_PRICE = _newPrice;
    }

    function updatePublicPrice(uint256 _newPrice) public onlyOwner {
        PUBLIC_PRICE = _newPrice;
    }

    function updatePublicBundlePrice(uint256 _newPrice) public onlyOwner {
        PUBLIC_BUNDLE_PRICE = _newPrice;
    }

    function updateSupply(uint256 _newSupply) public onlyOwner {
        MAXIMUM_SUPPLY = _newSupply;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        payable(0x9cB6bDD2d653b5BC079232371020B7bd68ADD16F).transfer(((_balance * 2000) / 10000));
        payable(0xdF6bE09686fB8b973Ec698e38638eCa894AAB47e).transfer(((_balance * 1000) / 10000));
        payable(0x9196367f37fA4c4e65bB99feC58E26738F944782).transfer(((_balance * 3400) / 10000));
        payable(0xEea95B14d8816cab1eD189353824f412948DE412).transfer(((_balance * 3600) / 10000));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (isRevealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

}