// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

// @@@@@@@@  @@@  @@@   @@@@@@@  @@@@@@@   @@@ @@@  @@@@@@@   @@@@@@@  @@@  @@@  @@@@@@@ 
// @@@@@@@@  @@@@ @@@  @@@@@@@@  @@@@@@@@  @@@ @@@  @@@@@@@@  @@@@@@@  @@@  @@@  @@@@@@@@
// @@!       @@[email protected][email protected]@@  [email protected]@       @@!  @@@  @@! [email protected]@  @@!  @@@    @@!    @@!  [email protected]@  @@!  @@@
// [email protected]!       [email protected][email protected][email protected]!  [email protected]!       [email protected]!  @[email protected]  [email protected]! @!!  [email protected]!  @[email protected]    [email protected]!    [email protected]!  @!!  [email protected]!  @[email protected]
// @!!!:!    @[email protected] [email protected]!  [email protected]!       @[email protected][email protected]!    [email protected][email protected]!   @[email protected]@[email protected]!     @!!     [email protected]@[email protected]!   @[email protected]  [email protected]!
// !!!!!:    [email protected]!  !!!  !!!       [email protected][email protected]!      @!!!   [email protected]!!!      !!!      @!!!    [email protected]!  !!!
// !!:       !!:  !!!  :!!       !!: :!!     !!:    !!:         !!:     !: :!!   !!:  !!!
// :!:       :!:  !:!  :!:       :!:  !:!    :!:    :!:         :!:    :!:  !:!  :!:  !:!
//  :: ::::   ::   ::   ::: :::  ::   :::     ::     ::          ::     ::  :::   :::: ::
// : :: ::   ::    :    :: :: :   :   : :     :      :           :      :   ::   :: :  : 

contract EncryptxD is Ownable, ERC721A {
    constructor() ERC721A("EncryptxD", "EncyrptxD") {}

    uint256 collectionSize = 300;
    uint256 price = 0.04 ether;
    bool allowlistOpen = false; 
    bool waitlistOpen = false;

    string private _baseTokenURI = "";
    bool public isPaused = true;

    bytes32 public allowlistMerkleRoot;
    bytes32 public waitlistMerkleRoot;
    mapping(address => bool) public mintClaimed;

    modifier isAllowlistOpen
    {
        require(allowlistOpen, "Allowlist is closed!");
        _;
    }

    modifier isWaitlistOpen
    {
        require(waitlistOpen, "Waitlist is closed!");
        _;
    }


    modifier callerIsUser 
    {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier isValidMint(uint256 mintAmount) 
    {
        require(mintAmount > 0, "Mint Amount Incorrect");
        require(msg.value >= price * mintAmount, "Incorrect payment amount!");
        require(totalSupply() + mintAmount < collectionSize + 1, "Reached max supply");
        require(!isPaused, "Mint paused");
        _;
    }

    function allowlistMint(uint256 mintAmount, bytes32[] calldata _merkleProof) 
        external 
        payable 
        callerIsUser 
        isAllowlistOpen
        isValidMint(mintAmount)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf), "Proof not on allowlist!");
        require(mintAmount == 1, "Mint Amount Incorrect");
        require(!mintClaimed[msg.sender], "Exceeds max mint amount!");

        mintClaimed[msg.sender] = true;
        _safeMint(msg.sender, mintAmount);
    }

    function waitlistMint(uint256 mintAmount, bytes32[] calldata _merkleProof) 
        external 
        payable 
        callerIsUser 
        isWaitlistOpen
        isValidMint(mintAmount)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, waitlistMerkleRoot, leaf), "Proof not on waitlist!");
        require(mintAmount == 1, "Mint Amount Incorrect");
        require(!mintClaimed[msg.sender], "Exceeds max mint amount!");

        mintClaimed[msg.sender] = true;
        _safeMint(msg.sender, mintAmount);
    }

    // VIEW FUNCTIONS
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // ADMIN FUNCTIONS
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function airdrop(address[] memory addresses, uint256[] memory numMints)
        external
        onlyOwner
    {
        require(addresses.length == numMints.length, "Arrays dont match");

        for (uint i = 0; i < addresses.length; i++) {
            require(totalSupply() + numMints[i] < collectionSize + 1, "Reached max supply");
            require(numMints[i] > 0, "Cannot mint 0!");
            _safeMint(addresses[i], numMints[i]);
        }
    }

    function setAllowlistMerkleRoot(bytes32 root) external onlyOwner {
        allowlistMerkleRoot = root;
    }

    function setWaitlistMerkleRoot(bytes32 root) external onlyOwner {
        waitlistMerkleRoot = root;
    }

    //NOTE: price must be in ethers (value * 10**18)
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setMaxSupply(uint256 size) external onlyOwner {
        collectionSize = size;
    }

    function setPaused(bool paused) external onlyOwner {
        isPaused = paused;
    }

    function setSaleStates(bool allowlistState, bool waitlistState) external onlyOwner {
        allowlistOpen = allowlistState;
        waitlistOpen = waitlistState;
    }

    function withdrawMoney() external onlyOwner {
        require(address(this).balance > 0);
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}