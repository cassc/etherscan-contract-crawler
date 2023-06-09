// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GanimeMintPass is ERC1155 {

    string public name = "Ganime Mint Pass";
    string public symbol = "GANPASS";

    uint public MINT_PRICE          = 0.04 ether;
    uint public MAX_SUPPLY          = 3000;
    uint public MAX_MINT_PER_WALLET = 3;

    uint public counter = 0;

    bool public MINT_IS_ON;
    bool public MINT_IS_PUBLIC;

    address public owner;

    bytes32 merkleRoot;
    string GANPASS_URI = "ipfs://bafkreihzpfu4pu6yhlvohdccghgffzfejg43flilpphdoapcydjdbttuhy";

    mapping(address => uint) public mintedAmount;

    constructor() ERC1155("") {
        owner = msg.sender;
    }

    function uri(uint256) override public view returns (string memory) {
        return GANPASS_URI;
    }

    function whiteListMint(uint amount, bytes32[] calldata merkleProof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Not whitelisted");

        require(MINT_IS_ON, "Mint is paused");
        require(amount > 0, "Must mint at least one");
        require(MINT_PRICE * amount <= msg.value, "Not enough ETH sent");
        require(mintedAmount[msg.sender] + amount <= MAX_MINT_PER_WALLET, "Wallet amount limit");
        require(counter + amount <= MAX_SUPPLY, "Exceeds supply");
        mintedAmount[msg.sender] += amount;
        counter += amount;
        _mint(msg.sender, 0, amount, "");
    }

    function mint(uint amount) external payable {
        require(MINT_IS_ON, "Mint is paused");
        require(MINT_IS_PUBLIC, "Mint is WL only");
        require(amount > 0, "Must mint at least one");
        require(MINT_PRICE * amount <= msg.value, "Not enough ETH sent");
        require(mintedAmount[msg.sender] + amount <= MAX_MINT_PER_WALLET, "Wallet amount limit");
        require(counter + amount <= MAX_SUPPLY, "Exceeds supply");
        mintedAmount[msg.sender] += amount;
        counter += amount;
        _mint(msg.sender, 0, amount, "");
    }


    // Owner stuff

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function turnMintOn() external onlyOwner {
        MINT_IS_ON = true;
    }

    function turnMintOff() external onlyOwner {
        MINT_IS_ON = false;
    }

    function setMintPublic() external onlyOwner {
        MINT_IS_PUBLIC = true;
    }

    function setMintWhitelisted() external onlyOwner {
        MINT_IS_PUBLIC = false;
    }

    function setPrice(uint price) external onlyOwner {
        MINT_PRICE = price;
    }

    function setMaxSupply(uint max_supply) external onlyOwner {
        MAX_SUPPLY = max_supply;
    }

    function setMaxMintPerWallet(uint max_mint_per_wallet) external onlyOwner {
        MAX_MINT_PER_WALLET = max_mint_per_wallet;
    }

    function setUri(string calldata uri_) external onlyOwner {
        GANPASS_URI = uri_;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "B-baka >_<");
        _;
    }
}