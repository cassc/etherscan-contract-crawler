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
    uint256 private constant YinTokenID = 8;
    uint256 private constant YangTokenID = 9;

    uint256 public constant YinPrice = 0.1369 ether;
    uint256 public constant YangPrice = 0.1 ether;

    // used to validate whitelists
    bytes32 public YinALMerkleRoot =
        0xcff07dc68ba9dfd0bfa02a7bff39dad7398fb3c7e680ea964d6a43f77a968903;
    bytes32 public YangALMerkleRoot =
        0xffd75a16d758086a01faed5a96b850bd6991b9755f7869e10906c6ad06cb2929;
    bytes32 public YinWLMerkleRoot =
        0x37cfde56a702a79abc0885c4a030a5762c6ac569ce6794ca89e8ab2ff494a6c9;
    bytes32 public YangWLMerkleRoot =
        0xe13f1b5bd347a619aaed943a296698f7639c18a42a8ee5c2a9cc3ad932923060;

    // set times
    uint64 public immutable ALStartTime = 1677859200; // 2023-03-04 00:00:00 GMT+8
    uint64 public immutable ALEndTime = 1677945600; // 2023-03-05 00:00:00 GMT+8
    uint64 public immutable WLStartTime = 1677945600; // 2023-03-05 00:00:00 GMT+8
    uint64 public immutable WLEndTime = 1677988800; // 2023-03-05 12:00:00 GMT+8

    mapping(address => uint256) public YinALMinted;
    mapping(address => uint256) public YangALMinted;
    mapping(address => uint256) public YinWLMinted;
    mapping(address => uint256) public YangWLMinted;

    uint256 public YinEditionMinted;
    uint256 public YangEditionMinted;
    uint256 public YinMaxMintAmount = 75;
    uint256 public YangMaxMintAmount = 75;

    address RTokenAddress = address(0x890dc5Dd5fc40c056c8D4152eDB146a1c76d1C29);
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