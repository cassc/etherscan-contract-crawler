pragma solidity ^0.8.17;
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract R {
    function mintYin(address to, uint256 amount) public virtual;

    function mintYang(address to, uint256 amount) public virtual;
}

contract ReviverArtSaleContract is Ownable, ReentrancyGuard {
    uint256 public constant price = 1 ether;

    // used to validate whitelists
    bytes32 public whitelistMerkleRoot;

    // set time
    uint64 public immutable whitelistStartTime = 1676563200; // 2023-02-17 00:00:00 GMT+8
    uint64 public immutable whitelistEndTime = 1676692800; // 2023-02-18 12:00:00 GMT+8
    uint64 public immutable publicStartTime = 1676736000; // 2023-02-19 00:00:00 GMT+8
    uint64 public immutable publicEndTime = 1676822400; // 2023-02-20 00:00:00 GMT+8

    mapping(address => bool) public whitelistMinted;
    mapping(address => bool) public publicYinMinted;
    mapping(address => bool) public publicYangMinted;

    address RTokenAddress = address(0x890dc5Dd5fc40c056c8D4152eDB146a1c76d1C29);
    address withdrawAddress =
        address(0x96ea39997ffCE1dF2f3f157F56Cc7d7763c7E40f);

    constructor() {}

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Your address is not on the list"
        );
        _;
    }

    modifier isCorrectPayment(uint256 _price, uint256 _numberOfTokens) {
        require(
            _price * _numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier checkWhitelistTime() {
        require(
            block.timestamp >= uint256(whitelistStartTime) &&
                block.timestamp <= uint256(whitelistEndTime),
            "It's not a whitelist sale period now"
        );
        _;
    }

    modifier checkPublicTime() {
        require(
            block.timestamp >= uint256(publicStartTime) &&
                block.timestamp <= uint256(publicEndTime),
            "It's not a public sale period now"
        );
        _;
    }

    function mintYinWhitelist(bytes32[] calldata merkleProof)
        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(price, 1)
        checkWhitelistTime
        nonReentrant
    {
        require(
            whitelistMinted[msg.sender] == false,
            "You already exceed max mint amount"
        );
        R tokenAttribution = R(RTokenAddress);
        tokenAttribution.mintYin(msg.sender, 1);
        whitelistMinted[msg.sender] = true;
    }

    function mintYangWhitelist(bytes32[] calldata merkleProof)
        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(price, 1)
        checkWhitelistTime
        nonReentrant
    {
        require(
            whitelistMinted[msg.sender] == false,
            "You already exceed max mint amount"
        );
        R tokenAttribution = R(RTokenAddress);
        tokenAttribution.mintYang(msg.sender, 1);
        whitelistMinted[msg.sender] = true;
    }

    function mintYinPublic()
        public
        payable
        isCorrectPayment(price, 1)
        checkPublicTime
        nonReentrant
    {
        require(tx.origin == msg.sender);
        require(
            publicYinMinted[msg.sender] == false,
            "You already exceed max mint amount"
        );
        R tokenAttribution = R(RTokenAddress);
        tokenAttribution.mintYin(msg.sender, 1);
        publicYinMinted[msg.sender] = true;
    }

    function mintYangPublic()
        public
        payable
        isCorrectPayment(price, 1)
        checkPublicTime
        nonReentrant
    {
        require(tx.origin == msg.sender);
        require(
            publicYangMinted[msg.sender] == false,
            "You already exceed max mint amount"
        );
        R tokenAttribution = R(RTokenAddress);
        tokenAttribution.mintYang(msg.sender, 1);
        publicYangMinted[msg.sender] = true;
    }

    function adminMintYin(uint256 n) public onlyOwner nonReentrant {
        require(
            block.timestamp > uint256(publicEndTime),
            "The public sale has not ended"
        );
        R tokenAttribution = R(RTokenAddress);
        tokenAttribution.mintYin(msg.sender, n);
    }

    function adminMintYang(uint256 n) public onlyOwner nonReentrant {
        require(
            block.timestamp > uint256(publicEndTime),
            "The public sale has not ended"
        );
        R tokenAttribution = R(RTokenAddress);
        tokenAttribution.mintYang(msg.sender, n);
    }

    function withdraw() public {
        require(msg.sender == withdrawAddress, "not withdrawAddress");
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public {
        require(msg.sender == withdrawAddress, "not withdrawAddress");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setRTokenAddress(address newAddress) public onlyOwner {
        RTokenAddress = newAddress;
    }

    function setWithdrawAddress(address newAddress) public onlyOwner {
        withdrawAddress = newAddress;
    }
}