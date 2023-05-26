// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "Ownable.sol";
import "ERC721.sol";
import "MerkleProof.sol";

contract Alpacadabraz_3D is ERC721, Ownable {

    bytes32 public merkleRoot = ""; // Construct this from (address, amount) tuple elements for whitelisted mints
    bytes32 public freeMintMerkleRoot = ""; // Construct this from (address, amount) tuple elements for free mints
    mapping(address => uint) public whitelistRemaining; // Maps user address to their remaining mints if they have minted some but not all of their allocation
    mapping(address => bool) public whitelistUsed; // Maps user address to bool, true if user has minted
    mapping(address => uint) public freeMintsRemaining; // Maps user address to their remaining free mints if they have minted some but not all of their allocation
    mapping(address => bool) public freeMintUsed; // Maps user address to bool, true if user has used a free mint

    uint public mintPrice = 0.296 ether;
    uint public whitelistPrice = 0.96 ether;
    uint public maxItems = 19969;
    uint public totalSupply = 0;
    uint public maxPublicMint = 4700;
    uint public publicMinted = 0;
    uint public maxItemsPerTx = 50;
    uint public maxItemsPerPublicMint = 10;
    address public recipient;
    string public _baseTokenURI;
    uint public startTimestamp;

    event Mint(address indexed owner, uint indexed tokenId);

    constructor(address _recipient) ERC721("ALPACADABRAZ 3D", "PACA 3D") {
        recipient = _recipient;
    }

    modifier mintingOpen() {
        require(startTimestamp != 0, "Start timestamp not set");
        require(block.timestamp >= startTimestamp, "Not open yet");
        _;
    }

    function ownerMint(uint amount) external onlyOwner {
        _mintWithoutValidation(msg.sender, amount);
    }

    function publicMint(uint amount) external payable mintingOpen {
        // Require nonzero amount
        require(amount > 0, "Can't mint zero");

        // Check proper amount sent
        require(msg.value == amount * mintPrice, "Send proper ETH amount");

        // Check max items per public mint
        require(amount <= maxItemsPerPublicMint, "publicMint: Surpasses maxItemsPerPublicMint");

        // Check public mint supply cap
        require(publicMinted + amount <= maxPublicMint, "publicMint: Sold out");
        publicMinted += amount;

        _mintWithoutValidation(msg.sender, amount);
    }

    function whitelistMint(uint amount, uint totalAllocation, bytes32 leaf, bytes32[] memory proof) external payable mintingOpen {
        // Verify that (leaf, proof) matches the Merkle root
        require(verify(merkleRoot, leaf, proof), "Not a valid leaf in the Merkle tree");

        // Verify that (msg.sender, amount) correspond to Merkle leaf
        require(keccak256(abi.encodePacked(msg.sender, totalAllocation)) == leaf, "Sender and amount don't match Merkle leaf");

        // Create storage element tracking user mints if this is the first mint for them
        if (!whitelistUsed[msg.sender]) {
            whitelistUsed[msg.sender] = true;
            whitelistRemaining[msg.sender] = totalAllocation;
        } else if (whitelistRemaining[msg.sender] > totalAllocation){
            whitelistRemaining[msg.sender] = totalAllocation;
        }

        // Require nonzero amount
        require(amount > 0, "Can't mint zero");

        // Check proper amount sent
        require(msg.value == amount * whitelistPrice, "Send proper ETH amount");

        require(whitelistRemaining[msg.sender] >= amount, "Can't mint more than remaining allocation");

        whitelistRemaining[msg.sender] -= amount;
        _mintWithoutValidation(msg.sender, amount);
    }

    function freeMint(uint amount, uint totalAllocation, bytes32 leaf, bytes32[] memory proof) external payable {
        // Verify that (leaf, proof) matches the Merkle root
        require(verify(freeMintMerkleRoot, leaf, proof), "Not a valid leaf in the Merkle tree");

        // Verify that (msg.sender, amount) correspond to Merkle leaf
        require(keccak256(abi.encodePacked(msg.sender, totalAllocation)) == leaf, "Sender and amount don't match Merkle leaf");

        // Create storage element tracking user mints if this is the first mint for them
        if (!freeMintUsed[msg.sender]) {        
            freeMintUsed[msg.sender] = true;
            freeMintsRemaining[msg.sender] = totalAllocation;
        } else if (freeMintsRemaining[msg.sender] > totalAllocation){
            freeMintsRemaining[msg.sender] = totalAllocation;
        }

        // Require nonzero amount
        require(amount > 0, "Can't mint zero");

        // Check proper amount sent
        require(msg.value == 0, "Send proper ETH amount");

        require(freeMintsRemaining[msg.sender] >= amount, "Can't mint more than remaining allocation");

        freeMintsRemaining[msg.sender] -= amount;
        _mintWithoutValidation(msg.sender, amount);
    }

    function _mintWithoutValidation(address to, uint amount) internal {
        require(totalSupply + amount <= maxItems, "mintWithoutValidation: Sold out");
        require(amount <= maxItemsPerTx, "mintWithoutValidation: Surpasses maxItemsPerTx");
        for (uint i = 0; i < amount; i++) {
            _mint(to, totalSupply);
            emit Mint(to, totalSupply);
            totalSupply += 1;
        }
    }

    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    // ADMIN FUNCTIONALITY

    function setMintPrice(uint _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setWhitelistPrice(uint _whitelistPrice) external onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    function setMaxPublicMint(uint _maxPublicMint) external onlyOwner {
        maxPublicMint = _maxPublicMint;
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function setStartTimestamp(uint _startTimestamp) external onlyOwner {
        startTimestamp = _startTimestamp;
    }

    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setFreeMintMerkleRoot(bytes32 _freeMintMerkleRoot) public onlyOwner {
        freeMintMerkleRoot = _freeMintMerkleRoot;
    }

    // WITHDRAWAL FUNCTIONALITY

    /**
     * @dev Withdraw the contract balance to the recipient address
     */
    function withdraw() external {
        uint amount = address(this).balance;
        (bool success,) = recipient.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    // METADATA FUNCTIONALITY

    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

}