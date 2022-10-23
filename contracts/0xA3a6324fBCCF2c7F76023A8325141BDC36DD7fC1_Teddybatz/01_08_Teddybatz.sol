// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import './utils/MerkleProofLib.sol';
import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';


contract Teddybatz is ERC721A, ERC721AQueryable, Ownable {

    uint48 public constant MAX_SUPPLY = 555;
    uint8  public constant MAX_ALLOWANCE_PER_ADDRESS = 3;
    uint8  public constant MAX_ALLOWANCE_FOR_FRIEND_PER_ADDRESS = 2;

    uint256 public publicPrice = 0.05 ether;
    bool public paused = true;
    string public metadataURI;
    bytes32 private _merkleRoot;

    address private teddybitsCare;
    mapping(address => bool) private teamAddress;
    mapping(address => bool) public addressFreeMintFlag; // 1 Mintable Address
    mapping(address => uint256) public addressMintedBalance; // 3 Mintable Address
    mapping(address => uint256) public addressMintedForFriendBalance; // 2 Mintable Address

    constructor(address[] memory _teamAddress, address _teddybitsCare, string memory _metadataURI) ERC721A("TeddyBatz", "TBZ") {
        for(uint256 i = 0; i < _teamAddress.length; i++) {
            address currentTeamAddress = _teamAddress[i];
            teamAddress[currentTeamAddress] = true;
        }
        teddybitsCare = _teddybitsCare;
        metadataURI = _metadataURI;
    }

    //modifiers
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller must not be contract.");
        _;
    }

    modifier mintCheck(uint256 _mintAmount) {
        uint256 supply = totalSupply();
        require(!paused, "Sale paused");
        require(_mintAmount > 0, "Invalid mint amount");
        require(supply + _mintAmount <= MAX_SUPPLY, "Exceeds maximum supply");
        _;
    }

    modifier teddyBitTeamOnly() {
        require(teamAddress[msg.sender] || owner() == _msgSender(), "Caller is not team or owner");
        _;
    }

    //mint functions
    function publicMint(uint256 _mintAmount) external payable callerIsUser mintCheck(_mintAmount) {
        require(msg.value >= _mintAmount * publicPrice, "Not sufficient funds");
        uint256 senderMintedCount = addressMintedBalance[msg.sender];
        require(_mintAmount + senderMintedCount <= MAX_ALLOWANCE_PER_ADDRESS, "Mint amount exceed user allowance");
        addressMintedBalance[msg.sender] += _mintAmount;
        _mint(msg.sender, _mintAmount);
    }    

    function friendMint(address[] memory _friendAddress) external payable callerIsUser {
        uint256 supply = totalSupply();
        require(!paused, "Sale paused");
        uint256 mintAmount = _friendAddress.length;
        require(msg.value >= mintAmount * publicPrice, "Not sufficient funds");
        require(supply + mintAmount <= MAX_SUPPLY, "Exceeds maximum supply");
        require(addressMintedForFriendBalance[msg.sender] + mintAmount <= MAX_ALLOWANCE_FOR_FRIEND_PER_ADDRESS, "Mint amount exceed for friend");
        for(uint256 i = 0; i < _friendAddress.length; i++) {
            address receiveAddress = _friendAddress[i];
            require(receiveAddress != msg.sender, "Caller cannot send to theirself");
            uint256 receiveMintedCount = addressMintedBalance[receiveAddress];
            require(mintAmount + receiveMintedCount <= MAX_ALLOWANCE_PER_ADDRESS, "Friend address already reach maximum teddybatz");
        }
        for(uint256 i = 0; i < _friendAddress.length; i++) {
            address receiveAddress = _friendAddress[i];
            addressMintedBalance[receiveAddress] += 1;
            addressMintedForFriendBalance[msg.sender] += 1;
            _mint(receiveAddress, 1);
        }
    }    

    function whitelistMint(bytes32[] calldata _proof) external payable callerIsUser mintCheck(1) {
        require(!addressFreeMintFlag[msg.sender], "This address already free minted");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofLib.verify(_proof, _merkleRoot, leaf), "Invalid Merkle Proof");
        addressFreeMintFlag[msg.sender] = true;
        _mint(msg.sender, 1);
    }

    // teddyBitTeamOnly functions
    function airdrop(address[] memory teddybitsOwner) external teddyBitTeamOnly {
        uint256 supply = totalSupply();
        require(supply + teddybitsOwner.length <= MAX_SUPPLY, "Exceeds maximum supply");

        for(uint256 i = 0; i < teddybitsOwner.length; i++) {
            _mint(teddybitsOwner[i], 1);
        }
    }

    function airdropMultiple(address[] memory teddybitsOwner, uint256[] memory mintAmounts) external teddyBitTeamOnly {
        uint256 supply = totalSupply();
        uint256 totalMintAmount = 0;
        for(uint256 i = 0; i < mintAmounts.length; i++) {
            require(mintAmounts[i] > 0, "Invalid mint amount");
            totalMintAmount += mintAmounts[i];
        }
        require(supply + totalMintAmount <= MAX_SUPPLY, "Exceeds maximum supply");

        for(uint256 i = 0; i < teddybitsOwner.length; i++) {
            _mint(teddybitsOwner[i], mintAmounts[i]);
        }
    }

    function setPaused(bool _paused) external teddyBitTeamOnly {
        paused = _paused;
    }

    function setMerkleRoot(bytes32 newRoot_) external teddyBitTeamOnly {
        _merkleRoot = newRoot_;
    }

    function setURI(string calldata _uri) external teddyBitTeamOnly {
        metadataURI = _uri;
    }

    function setPublicMintPrice(uint256 _mintPrice) external teddyBitTeamOnly {
        require(_mintPrice >= 0.01 ether, "Mint price must more than 0.01 eth");
        publicPrice = _mintPrice;
    }    

    function withdraw() external teddyBitTeamOnly {
        uint256 contractBalance = address(this).balance;
        (bool success,) = payable(teddybitsCare).call{value: contractBalance}("");
        require(success, "Withdraw failed");
    }

    // internal functions
    function _baseURI() internal view virtual override returns (string memory) {
        return metadataURI;
    }

}