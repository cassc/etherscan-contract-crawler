// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
   _ (`-.    ('-.     _ (`-.    ('-.  _ .-') _           _  .-')        (`-.      ('-.        
  ( (OO  ) _(  OO)   ( (OO  ) _(  OO)( (  OO) )         ( \( -O )     _(OO  )_  _(  OO)       
 _.`     \(,------. _.`     \(,------.\     .'_   ,-.-') ,------. ,--(_/   ,. \(,------.      
(__...--'' |  .---'(__...--'' |  .---',`'--..._)  |  |OO)|   /`. '\   \   /(__/ |  .---'      
 |  /  | | |  |     |  /  | | |  |    |  |  \  '  |  |  \|  /  | | \   \ /   /  |  |          
 |  |_.' |(|  '--.  |  |_.' |(|  '--. |  |   ' |  |  |(_/|  |_.' |  \   '   /, (|  '--.       
 |  .___.' |  .--'  |  .___.' |  .--' |  |   / : ,|  |_.'|  .  '.'   \     /__) |  .--'       
 |  |      |  `---. |  |      |  `---.|  '--'  /(_|  |   |  |\  \     \   /     |  `---.      
 `--'      `------' `--'      `------'`-------'   `--'   `--' '--'     `-'      `------'      
 */

contract PepeDriveII is ERC721A, Ownable, DefaultOperatorFilterer {
    uint256 public MAX_AMOUNT = 3333;
    uint256 public TEAM_AMOUNT = 33;
    bool public saleIsActive = false;
    bool public whitelistActive = true;
    uint256 public listingPrice = 0.069 ether;
    bytes32 private root;
    string public nftBaseURI;
    uint256 public maxPerWallet = 1;

    mapping(address => uint256) public balances;
    address public team1;
    address public team2;

    constructor(address team1_, address team2_) ERC721A("PepeDriveII", "PD2") {
        team1 = team1_;
        team2 = team2_;
    }

    function setRoot(bytes32 root_) public onlyOwner {
        root = root_;
    }

    function setTeam(address[] calldata team) public onlyOwner {
        require(team.length == 2, "Need two team members");
        team1 = team[0];
        team2 = team[1];
    }

    function setMaxPerWallet(uint256 maxPerWallet_) public onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function setBaseURI(string calldata nftBaseURI_) public onlyOwner {
        nftBaseURI = nftBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return nftBaseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipWhitelistState() public onlyOwner {
        whitelistActive = !whitelistActive;
    }

    function setListingPrice(uint256 listingPrice_) public onlyOwner {
        listingPrice = listingPrice_;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        uint256 split = (_balance * 50) / 100;
        (bool os, ) = payable(team1).call{value: split}("");
        require(os);

        (os, ) = payable(team2).call{value: split}("");
        require(os);
    }

    function mint(uint256 amount_, bytes32[] calldata proof_) public payable {
        require(saleIsActive, "Sale is not open");
        require(totalSupply() + amount_ <= MAX_AMOUNT, "Supply is limited");
        require(
            balances[msg.sender] + amount_ <= maxPerWallet,
            "Wallet limit reached"
        );
        require(
            msg.value >= (listingPrice * amount_),
            "Not enough funds submitted"
        );

        if (whitelistActive) {
            bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(proof_, root, _leaf), "Invalid proof");
        }
        balances[msg.sender] += amount_;
        _safeMint(msg.sender, amount_);
    }

    function teamMint(uint256 amount_) public onlyOwner {
        require(totalSupply() + amount_ <= MAX_AMOUNT, "Supply is limited");
        require(
            balances[owner()] + amount_ <= TEAM_AMOUNT,
            "Team supply limited"
        );
        balances[owner()] += amount_;
        _safeMint(owner(), amount_);
    }

    /////////////////////////////
    // OPENSEA FILTER REGISTRY
    /////////////////////////////

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}