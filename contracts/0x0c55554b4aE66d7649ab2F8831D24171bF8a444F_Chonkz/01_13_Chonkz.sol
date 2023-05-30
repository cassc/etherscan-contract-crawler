// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Chonkz is ERC721A, ReentrancyGuard, Ownable {

    uint256 public constant MAX_SUPPLY = 5555;

    uint256 public constant TEAM_ALLOCATION = 71;

    uint256 public constant MAX_MINT_PER_TX = 5;

    uint256 public constant MAX_MINT_PER_TX_PRIVATE = 2;

    uint256 public constant PRIVATE_PRICE = 0.05 ether;

    uint256 public constant PUBLIC_PRICE = 0.07 ether;

    uint256 public amountPublicAndTeam = 4071;

    uint256 public publicSaleOpens = 1651708800;

    uint256 public publicSaleCloses = 1651795199;

    uint256 public privateSaleOpens = 1651795200;

    uint256 public privateSaleCloses = 1651881599;

    string public baseURI;

    mapping(address => uint256) public ChonkzList;

    event Mintable(uint256 publicSaleOpens);

    event PrivateSaleMintable(uint256 privateSaleOpens);

    event MintableCloses(uint256 publicSaleCloses);

    event PrivateSaleCloses(uint256 privateSaleCloses);

    event BaseURI(string baseURI);

    event AddToChonkzList(address[] accounts);

    event RemoveFromChonkzList(address account);

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}

    modifier isMintable() {
        require(
            publicSaleOpens != 0 && 
            block.timestamp >= publicSaleOpens && 
            publicSaleCloses >= block.timestamp, 
            "CHONKZ: Public sale not active sir."
        );
        _;
    }

    modifier isPrivateSaleMintable() {
        require(
            privateSaleOpens != 0 && 
            block.timestamp >= privateSaleOpens && 
            privateSaleCloses >= block.timestamp, 
            "CHONKZ: Private sale not active sir."
        );
        _;
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender, 
            "CHONKZ: Caller is a contract."
        );
        _;
    }

    modifier isNotExceedAvailableSupply(uint256 amount) {
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "CHONKZ: Sorry, insufficient supply remaining."
        );
        _;
    }

    modifier doesNotExceedPublicAndTeamSupply(uint256 amount) {
        require(
            totalSupply() + amount <= amountPublicAndTeam,
            "CHONKZ: Sorry, insufficient public supply remaining."
        );
        _;
    }

    modifier isPrivateSaleValueAndAmountValid(uint256 amount) {
        require(
            msg.value == PRIVATE_PRICE * amount,
            "CHONKZ: Ether value does not meet requirement."
        );
        require(
            ChonkzList[msg.sender] >= amount, 
            "CHONKZ: Exceeds allocation for wallet."
        );
        _;
    }

    modifier isPublicSaleValueAndAmountValid(uint256 amount) {
        require(
            msg.value == PUBLIC_PRICE * amount,
            "CHONKZ: Ether value does not meet requirement."
        );
        require(
            amount <= MAX_MINT_PER_TX,
            "CHONKZ: Exceeds transaction mint limit."  
        );
        _;
    }

    modifier isChonkzList(){
        require(
            ChonkzList[msg.sender] > 0,
            "CHONKZ: You're not on the list for the presale."
        );
        _;
    }

    function devMint(uint256 amount)
        public
        onlyOwner
        doesNotExceedPublicAndTeamSupply(amount)
    {
        require(amount <= TEAM_ALLOCATION, "CHONKZ: Exceeds allocation for developer wallet.");
        _safeMint(msg.sender, amount);
    }

    function privateSaleMint(uint256 amount)
        public
        payable
        nonReentrant 
        callerIsUser
        isPrivateSaleMintable
        isChonkzList
        isNotExceedAvailableSupply(amount)
        isPrivateSaleValueAndAmountValid(amount)
    {
        _safeMint(msg.sender, amount);
        ChonkzList[msg.sender] -= amount;
    }

    function mint(uint256 amount)
        public
        payable
        nonReentrant
        callerIsUser
        isMintable
        doesNotExceedPublicAndTeamSupply(amount)
        isPublicSaleValueAndAmountValid(amount)
    {
        _safeMint(msg.sender, amount);
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
        emit BaseURI(baseURI);
    }

    function setPublicAndTeamSupply(uint256 supply) external onlyOwner {
        require(
            supply <= MAX_SUPPLY,
            "CHONKZ: Exceeds max possible supply."
        );
        amountPublicAndTeam = supply;
    }

    function setPublicSaleOpens(uint256 timestamp) external onlyOwner {
        publicSaleOpens = timestamp;
        emit Mintable(publicSaleOpens);
    }

    function setPrivateSaleOpens(uint256 timestamp) external onlyOwner {
        privateSaleOpens = timestamp;
        emit PrivateSaleMintable(privateSaleOpens);
    }

    function setPublicSaleCloses(uint256 timestamp) external onlyOwner {
        publicSaleCloses = timestamp;
        emit MintableCloses(publicSaleCloses);
    }

    function setPrivateSaleCloses(uint256 timestamp) external onlyOwner {
        privateSaleCloses = timestamp;
        emit PrivateSaleCloses(privateSaleCloses);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        payable(0x4090E94213f473Cb9572B85D89dBd9a11c8B03c9).transfer(address(this).balance);
    }

    function setAddressesToChonkzList(address[] memory _addresses, uint8[] memory _allocations)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            ChonkzList[_addresses[i]] = _allocations[i];
        }

        emit AddToChonkzList(_addresses);
    }

    function removeAddressFromChonkzList(address _address) external onlyOwner {
        ChonkzList[_address] = 0;
        emit RemoveFromChonkzList(_address);
    }
}

/* Curated by @Scarlet_Swarm */