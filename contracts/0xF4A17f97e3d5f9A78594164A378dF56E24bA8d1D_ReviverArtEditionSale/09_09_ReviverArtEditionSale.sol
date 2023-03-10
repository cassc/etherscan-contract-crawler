pragma solidity ^0.8.17;
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract R {
    function mintBaseExisting(
        address[] calldata to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) public virtual;
}

contract ReviverArtEditionSale is Ownable, ReentrancyGuard {
    uint256 private constant YinTokenID = 10;
    uint256 private constant YangTokenID = 11;

    uint256 public constant YinPrice = 0.069 ether;
    uint256 public constant YangPrice = 0.069 ether;

    // used to validate whitelists
    bytes32 public YinALMerkleRoot =
        0xdfc49e55095c5a85ff9be52bcc9301207d7406e56927c57ebb924082161925db;
    bytes32 public YangALMerkleRoot =
        0xb13db5d108cb01b227dc70e7bb3664cee78d98d58d273fbf23faf480d297637d;
    bytes32 public YinWLMerkleRoot =
        0xaf60557d84d32beebb4989e74d02e47e0fe0ff1624ad769322f1780993de0c07;
    bytes32 public YangWLMerkleRoot =
        0xe48cf250b0f018bd4cf5ed5b4951d8edf74569f79c8211b621ee65d4275d0ca4;

    // set times
    uint64 public immutable ALStartTime = 1678464000; // 2023-03-11 00:00:00 GMT+8
    uint64 public immutable ALEndTime = 1678550400; // 2023-03-12 00:00:00 GMT+8
    uint64 public immutable WLStartTime = 1678550400; // 2023-03-12 00:00:00 GMT+8
    uint64 public immutable WLEndTime = 1678593600; // 2023-03-12 12:00:00 GMT+8

    mapping(address => uint256) public YinALMinted;
    mapping(address => uint256) public YangALMinted;
    mapping(address => uint256) public YinWLMinted;
    mapping(address => uint256) public YangWLMinted;

    uint256 public YinEditionMinted;
    uint256 public YangEditionMinted;
    uint256 public YinMaxMintAmount = 90;
    uint256 public YangMaxMintAmount = 75;

    address RTokenAddress = address(0x4EbaCA9a34e647F045a8fD520f5EAe96dFc464b6);
    R tokenAttribution = R(RTokenAddress);
    address withdrawAddress =
        address(0x96ea39997ffCE1dF2f3f157F56Cc7d7763c7E40f);
    address public cSigner =
        address(0x3a5e8a465a7F87531C13A4fcfa963B4A878B2E24);

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

    modifier checkALTime() {
        require(
            block.timestamp >= uint256(ALStartTime) &&
                block.timestamp <= uint256(ALEndTime),
            "It's not a allowlist period now"
        );
        _;
    }

    modifier checkWLTime() {
        require(
            block.timestamp >= uint256(WLStartTime) &&
                block.timestamp <= uint256(WLEndTime),
            "It's not a waitlist period now"
        );
        _;
    }

    modifier checkSignedMsg(
        bytes32 r,
        bytes32 s,
        uint8 v,
        address _receiver,
        uint256 _maxAmount
    ) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(_receiver)),
                keccak256(abi.encode(_maxAmount))
            )
        );
        require(ecrecover(digest, v, r, s) == cSigner, "Invalid signer");
        _;
    }

    //
    // AL
    //

    function mintYinEditionAL(
        bytes32[] calldata merkleProof,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 amount,
        uint256 maxAmount
    )
        public
        payable
        isValidMerkleProof(merkleProof, YinALMerkleRoot)
        checkSignedMsg(r, s, v, msg.sender, maxAmount)
        isCorrectPayment(YinPrice, amount)
        checkALTime
        nonReentrant
    {
        require(
            YinALMinted[msg.sender] + amount <= maxAmount &&
                YinEditionMinted + amount <= YinMaxMintAmount,
            "exceed max amount"
        );
        address[] memory addr = new address[](1);
        uint256[] memory tokenID = new uint256[](1);
        uint256[] memory mintAmount = new uint256[](1);
        addr[0] = msg.sender;
        tokenID[0] = YinTokenID;
        mintAmount[0] = amount;

        tokenAttribution.mintBaseExisting(addr, tokenID, mintAmount);
        YinALMinted[msg.sender] += amount;
        YinEditionMinted += amount;
    }

    function mintYangEditionAL(
        bytes32[] calldata merkleProof,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 amount,
        uint256 maxAmount
    )
        public
        payable
        isValidMerkleProof(merkleProof, YangALMerkleRoot)
        checkSignedMsg(r, s, v, msg.sender, maxAmount)
        isCorrectPayment(YangPrice, amount)
        checkALTime
        nonReentrant
    {
        require(
            YangALMinted[msg.sender] + amount <= maxAmount &&
                YangEditionMinted + amount <= YangMaxMintAmount,
            "exceed max amount"
        );
        address[] memory addr = new address[](1);
        uint256[] memory tokenID = new uint256[](1);
        uint256[] memory mintAmount = new uint256[](1);
        addr[0] = msg.sender;
        tokenID[0] = YangTokenID;
        mintAmount[0] = amount;

        tokenAttribution.mintBaseExisting(addr, tokenID, mintAmount);
        YangALMinted[msg.sender] += amount;
        YangEditionMinted += amount;
    }

    //
    // WL
    //

    function mintYinEditionWL(
        bytes32[] calldata merkleProof,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 amount,
        uint256 maxAmount
    )
        public
        payable
        isValidMerkleProof(merkleProof, YinWLMerkleRoot)
        checkSignedMsg(r, s, v, msg.sender, maxAmount)
        isCorrectPayment(YinPrice, amount)
        checkWLTime
        nonReentrant
    {
        require(
            YinWLMinted[msg.sender] + amount <= maxAmount &&
                YinEditionMinted + amount <= YinMaxMintAmount,
            "exceed max amount"
        );
        address[] memory addr = new address[](1);
        uint256[] memory tokenID = new uint256[](1);
        uint256[] memory mintAmount = new uint256[](1);
        addr[0] = msg.sender;
        tokenID[0] = YinTokenID;
        mintAmount[0] = amount;

        tokenAttribution.mintBaseExisting(addr, tokenID, mintAmount);
        YinWLMinted[msg.sender] += amount;
        YinEditionMinted += amount;
    }

    function mintYangEditionWL(
        bytes32[] calldata merkleProof,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 amount,
        uint256 maxAmount
    )
        public
        payable
        isValidMerkleProof(merkleProof, YangWLMerkleRoot)
        checkSignedMsg(r, s, v, msg.sender, maxAmount)
        isCorrectPayment(YangPrice, amount)
        checkWLTime
        nonReentrant
    {
        require(
            YangWLMinted[msg.sender] + amount <= maxAmount &&
                YangEditionMinted + amount <= YangMaxMintAmount,
            "exceed max amount"
        );
        address[] memory addr = new address[](1);
        uint256[] memory tokenID = new uint256[](1);
        uint256[] memory mintAmount = new uint256[](1);
        addr[0] = msg.sender;
        tokenID[0] = YangTokenID;
        mintAmount[0] = amount;

        tokenAttribution.mintBaseExisting(addr, tokenID, mintAmount);
        YangWLMinted[msg.sender] += amount;
        YangEditionMinted += amount;
    }

    //
    // ADMIN
    //

    function adminMintYinEdition(uint256 n) public onlyOwner nonReentrant {
        require(
            block.timestamp > uint256(WLEndTime),
            "The waitlist round has not ended"
        );
        require(n + YinEditionMinted <= YinMaxMintAmount, "exceed max amount");
        address[] memory addr = new address[](1);
        uint256[] memory tokenID = new uint256[](1);
        uint256[] memory mintAmount = new uint256[](1);
        addr[0] = msg.sender;
        tokenID[0] = YinTokenID;
        mintAmount[0] = n;

        tokenAttribution.mintBaseExisting(addr, tokenID, mintAmount);
        YinEditionMinted += n;
    }

    function adminMintYangEdition(uint256 n) public onlyOwner nonReentrant {
        require(
            block.timestamp > uint256(WLEndTime),
            "The waitlist round has not ended"
        );
        require(
            n + YangEditionMinted <= YangMaxMintAmount,
            "exceed max amount"
        );
        address[] memory addr = new address[](1);
        uint256[] memory tokenID = new uint256[](1);
        uint256[] memory mintAmount = new uint256[](1);
        addr[0] = msg.sender;
        tokenID[0] = YangTokenID;
        mintAmount[0] = n;

        tokenAttribution.mintBaseExisting(addr, tokenID, mintAmount);
        YangEditionMinted += n;
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

    function setWhitelistMerkleRoot(uint256 rootType, bytes32 merkleRoot)
        external
        onlyOwner
    {
        if (rootType == 1) {
            YinALMerkleRoot = merkleRoot;
        } else if (rootType == 2) {
            YangALMerkleRoot = merkleRoot;
        } else if (rootType == 3) {
            YinWLMerkleRoot = merkleRoot;
        } else if (rootType == 4) {
            YangWLMerkleRoot = merkleRoot;
        } else {
            revert("not allow");
        }
    }

    function setRTokenAddress(address newAddress) public onlyOwner {
        RTokenAddress = newAddress;
    }

    function setWithdrawAddress(address newAddress) public onlyOwner {
        withdrawAddress = newAddress;
    }

    function setSigner(address newAddress) public onlyOwner {
        cSigner = newAddress;
    }

    function getMessageHash(address receiver, uint256 maxAmount)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encode(receiver)),
                    keccak256(abi.encode(maxAmount))
                )
            );
    }
}