// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract HWS is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using ECDSA for bytes32;

    Counters.Counter private _tokenIdCounter;

    address constant team_address = 0x14d60F4D82361192143C7Afd2b72d5afa69071ED;

    bytes32 public merkleRootPrivate;
    bytes32 public merkleRootRaffle;

    uint256 public constant MAXIMUM_SUPPLY = 7777;
    uint256 public constant MAXIMUM_GIFT = MAXIMUM_SUPPLY;

    uint256 public constant MAXIMUM_MINT = 7;

    uint256 public giftCount;

    string public baseURI;
    string public notRevealedUri;

    bool public raffleMode = true;
    bool public isRevealed = false;
    bool public whitelistSoldOut = false;

    enum WorkflowStatus {
        Before,
        Presale,
        Sale,
        SoldOut,
        Reveal
    }

    WorkflowStatus public workflow;

    address private _owner;

    mapping(address => uint256) public tokensPerWalletRaffle;
    mapping(address => uint256) public tokensPerWalletWhitelist;

    event ChangePresaleConfig(uint256 _maxCount);
    event ChangeSaleConfig(uint256 _maxCount);
    event ChangeIsBurnEnabled(bool _isBurnEnabled);
    event ChangeBaseURI(string _baseURI);
    event GiftMint(address indexed _recipient, uint256 _amount);
    event PresaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event SaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721("Hustlers Of Wall Street", "HWS") {
        transferOwnership(msg.sender);
        workflow = WorkflowStatus.Before;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        _tokenIdCounter.increment();
    }

    //GETTERS

    function publicSaleLimit() public pure returns (uint256) {
        return MAXIMUM_SUPPLY;
    }

    function privateSalePrice() public pure returns (uint256) {
        return 0.10 ether;
    }

    function getPrice() public pure returns (uint256) {
        return 0.15 ether;
    }

    function allowedGiftLimit() public pure returns (uint256) {
        return MAXIMUM_GIFT;
    }

    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function hasWhitelist(bytes32[] calldata _merkleProof) public view returns (bool) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      return MerkleProof.verify(_merkleProof, merkleRootPrivate, leaf);
    }

    function hasOnRaffle(bytes32[] calldata _merkleProof) public view returns (bool) {
      if(raffleMode == true) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRootRaffle, leaf);
      } else {
        return true;
      }
    }

    function presaleMint(uint256 ammount, bytes32[] calldata _merkleProof) external payable nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 price = privateSalePrice();

        require(workflow == WorkflowStatus.Presale, "HWS: Presale is not started yet!");
        require(whitelistSoldOut == false, "HWS: Presale is SOLD OUT!");

        require(tokensPerWalletWhitelist[msg.sender] + ammount <= 2, "HWS: Presale mint is two token only.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootPrivate, leaf), "HWS: You are not whitelisted");

        require(msg.value >= price * ammount, "HWS: Not enough ETH sent");

        tokensPerWalletWhitelist[msg.sender] += ammount;
        for (uint256 i = 1; i <= ammount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function publicSaleMint(uint256 ammount, bytes32[] calldata _merkleProof) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 price = getPrice();

        require(workflow != WorkflowStatus.SoldOut, "HWS: SOLD OUT!");
        require(workflow == WorkflowStatus.Sale, "HWS: Raffle is not started yet");
        require(msg.value >= price * ammount, "HWS: Not enough ETH sent");
        require(ammount <= 5, "HWS: You can only mint up to five token at once!");
        require(tokensPerWalletRaffle[msg.sender] + ammount <= 5, "HWS: You can't mint more than 5 tokens!");
        require(supply + ammount <= MAXIMUM_SUPPLY, "HWS: Mint too large!");

        if(raffleMode == true) {
          bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
          require(MerkleProof.verify(_merkleProof, merkleRootRaffle, leaf), "HWS: You haven't been selected");
        }

        tokensPerWalletRaffle[msg.sender] += ammount;

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
        require(giftCount + _mintAmount <= MAXIMUM_GIFT, "max NFT limit exceeded");
        uint256 initial = 1;
        uint256 condition = _mintAmount;
        giftCount += _mintAmount;
        for (uint256 i = initial; i <= condition; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // Before All.

    function restart() external onlyOwner {
        workflow = WorkflowStatus.Before;
    }

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
    }

    function closePresale() external onlyOwner {
        whitelistSoldOut = true;
    }

    function setUpSale() external onlyOwner {
        require(workflow == WorkflowStatus.Presale, "HWS: Unauthorized Transaction");
        workflow = WorkflowStatus.Sale;
        emit WorkflowStatusChange(WorkflowStatus.Presale, WorkflowStatus.Sale);
    }

    function setMerkleRootPrivate(bytes32 root) public onlyOwner {
        merkleRootPrivate = root;
    }

    function setMerkleRootRaffle(bytes32 root) public onlyOwner {
        merkleRootRaffle = root;
    }

    function reveal() public onlyOwner {
        isRevealed = true;
    }

    function switchRaffleMode() public onlyOwner {
        raffleMode = !raffleMode;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public onlyOwner {
      uint256 balance = address(this).balance;
      payable(team_address).transfer(balance);
    }

    // FACTORY

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        if (isRevealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

}