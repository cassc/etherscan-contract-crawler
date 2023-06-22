// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721APausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStaking.sol";

contract LAND is ERC721APausable, Ownable {
    // Metadata
    string public constant PROVENANCE_SHA1 = "ba3a6eb897fbb146b77ec32c73a712a4066d4a50";

    string private _baseTokenURI = "https://cloud-01.isotile.com/basic/land/unrevealed/json/";
    string private _name = "isotile Genesis LAND";
    string private _symbol = "LAND";
    uint256 private constant RESERVED_LAND = 50;
    uint256 public price = 0.059 ether;

    // PHASE 1: Whitelist
    bytes32 private _merkleRoot = 0xd7cddc2efbdd756f6cb18957deed6634825004002304cc89cfb6f4b56c8d05f2;
    mapping(uint256 => uint256) private _whitelists;

    // PHASE 2: Minting
    uint256 public currentMintingId;
    uint256 private _maxSupplyForMinting = 1438;
    bool private _allowPublicMint = false;
    uint256 private _maxMintPerTx = 5;

    // PHASE 3: Stake
    uint256 public currentStakingId;
    uint256 private _maxSupplyForStaking = 4491;
    bool private _allowStakingMint = false;
    IStaking private _stakingInstance = IStaking(0x073a5c788eb3B3Ff72d17f6a9eDd29C50586c776);
    mapping (address => bool) private _stakers;

    constructor() ERC721A(_name, _symbol) {
        currentMintingId += RESERVED_LAND;
        _mint(_msgSender(), RESERVED_LAND, "", false);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller must be user");
        _;
    }
    
    function mintTo(address account, uint256 num) private {
        require(num > 0, "You cant mint negative LAND");
        require(num <= _maxMintPerTx, "You can mint max 5 LAND per tx");
        require(currentMintingId + num <= _maxSupplyForMinting, "Exceeds maximum LAND supply");
        
        currentMintingId += num;
        _mint(account, num, "", false);
    }

    function stakingMintTo(address account) private {
        require(!_stakers[account], "You already minted by staking");
        _stakers[account] = true;

        uint256 tickets = _stakingInstance.tickets(account);
        require(tickets > 0, "You have no staking tickets");
        require(currentStakingId + tickets <= _maxSupplyForStaking, "Exceeds maximum LAND supply");

        currentStakingId += tickets;
        _mint(account, tickets, "", false);
    }

    function isClaimedWhitelist(uint256 index) private view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = _whitelists[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);

        return claimedWord & mask == mask;
    }

    function setClaimedWhitelist(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        _whitelists[claimedWordIndex] = _whitelists[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function whitelistMint(uint256 index, uint256 num, bytes32[] calldata merkleProof) external payable {
        require(!isClaimedWhitelist(index), "Whitelist already claimed");
        require(msg.value == price * num, "Ether sent is not correct");

        bytes32 node = keccak256(abi.encodePacked(index, _msgSender(), num));
        require(MerkleProof.verify(merkleProof, _merkleRoot, node), "Invalid proof");

        setClaimedWhitelist(index);

        mintTo(_msgSender(), num);
    }

    function publicMint(uint256 num) callerIsUser external payable {
        require(_allowPublicMint, "Public minting didnt start");
        require(msg.value == price * num, "Ether sent is not correct");

        mintTo(_msgSender(), num);
    }

    function stakingMint() external {
        require(_allowStakingMint, "Staking minting didnt start");
        
        stakingMintTo(_msgSender());
    }
    
    /* onlyOwner */
    function publicMintAdmin(address account, uint256 num) onlyOwner external {
        mintTo(account, num);
    }

    function stakingMintAdmin(address account) onlyOwner external {
        stakingMintTo(account);
    }

    function setMerkleRoot(bytes32 merkleRoot) onlyOwner external {
        _merkleRoot = merkleRoot;
    }
  
    function setBaseURI(string memory baseURI) onlyOwner public {
        _baseTokenURI = baseURI;
    }
    
    function setPrice(uint256 price_) onlyOwner external {
        price = price_;
    }
    
    function setName(string memory name_) onlyOwner external {
        _name = name_;
    }
    
    function setSymbol(string memory symbol_) onlyOwner external {
        _symbol = symbol_;
    }

    function stopPublicMint() onlyOwner external {
        _allowPublicMint = false;
    }

    function startPublicMint() onlyOwner external {
        _allowPublicMint = true;
    }

    function stopStakingMint() onlyOwner external {
        _allowStakingMint = false;
    }

    function startStakingMint() onlyOwner external {
        _allowStakingMint = true;
    }

    function setMaxSupplyForMinting(uint256 maxSupplyForMinting) onlyOwner external {
        require(maxSupplyForMinting < _maxSupplyForMinting, "Can not increase supply");

        _maxSupplyForMinting = maxSupplyForMinting;
    }

    function setMaxSupplyForStaking(uint256 maxSupplyForStaking) onlyOwner external {
        require(maxSupplyForStaking < _maxSupplyForStaking, "Can not increase supply");

        _maxSupplyForStaking = maxSupplyForStaking;
    }

    function pause() onlyOwner external {
        _pause();
    }
  
    function unpause() onlyOwner external {
        _unpause();
    }

    function withdraw() onlyOwner external {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}