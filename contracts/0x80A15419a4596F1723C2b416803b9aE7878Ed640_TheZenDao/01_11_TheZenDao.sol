pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract TheZenDao is Ownable, ERC721AQueryable {
    using ECDSA for bytes32;

    string public baseURI;

    uint256 private _seed;
    uint256 public totalMinted;
    uint256 public freeMinted;

    uint256 public immutable preSaleStartTime;
    uint256 public immutable publicSaleStartTime;
    uint256 public immutable publicSaleEndTime;

    address public signerAddress;
    address public withdrawalWallet;

    bool public terminatedMint;
    bool public reservedMinted;

    mapping(address => uint256) public freeMintRecord;
    mapping(address => uint256) public preSaleMintRecord;
    mapping(address => uint256) public publicSaleMintRecord;

    mapping(uint256 => CharacterKind) public characterKind;
    mapping(uint256 => uint256) public stepPrice;

    uint256 public constant preSalePrice = 0.08 ether;
    uint256 public constant publicSaleBasePrice = 0.1 ether;
    uint256 public constant SUPPLY_LIMIT = 7777;
    uint256 public constant FREE_LIMIT = 100;

    error PreSaleNotStarted(uint256 currentTime);
    error PreSaleFinished(uint256 currentTime);
    error PublicSaleNotStarted(uint256 currentTime);
    error PublicSaleFinished(uint256 currentTime);

    error SupplyLimitReached();

    error OnlyHuman(address user);

    error InvalidSignature(address recoverUser);
    error MintNumberLimitReached();
    error PayingNotEnough();

    error InvalidAddress(address addr);
    error CallError(bytes data);
    error InvalidArgs();
    error Terminated();
    error FreeLimit();

    enum ComposeType {
        None,
        Fo,
        Mo,
        Random
    }

    enum CharacterKind {
        None,
        Fannao,
        Zhengnian,
        Sheng,
        Mo,
        Fo
    }

    enum Channel {
        None,
        Free,
        Pre,
        Public
    }

    event Compose(uint256 tokenA, uint256 tokenB, uint256 resultToken, CharacterKind result);
    event Sale(address indexed user, uint256 startTokenId, uint256 amount, Channel channel);

    modifier onPreSale() {
        if (block.timestamp < preSaleStartTime) revert PreSaleNotStarted(block.timestamp);
        if (block.timestamp > publicSaleStartTime) revert PreSaleFinished(block.timestamp);
        _;
    }

    modifier onPublicSale() {
        if (block.timestamp < publicSaleStartTime) revert PublicSaleNotStarted(block.timestamp);
        _;
    }

    modifier onSale(uint256 amount) {
        uint256 minted = totalMinted;
        if (terminatedMint) revert Terminated();
        if (minted + amount > SUPPLY_LIMIT) revert SupplyLimitReached();

        _;
        totalMinted = minted + amount;
    }

    modifier onlyHuman() {
        if (msg.sender != tx.origin) revert OnlyHuman(msg.sender);
        _;
    }

    constructor(
        uint256 preSaleStartTime_,
        uint256 publicSaleStartTime_,
        uint256 publicSaleEndTime_,
        address signer,
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) {
        _mint(msg.sender, 1);
        totalMinted = 1;

        preSaleStartTime = preSaleStartTime_;
        publicSaleStartTime = publicSaleStartTime_;
        publicSaleEndTime = publicSaleEndTime_;

        signerAddress = signer;
        stepPrice[1] = 0.3 ether;
        stepPrice[2] = 0.5 ether;
        stepPrice[3] = 0.8 ether;
    }

    function freeMint(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable onPreSale onlyHuman onSale(1) {
        address recoverAddr = keccak256(abi.encodePacked(msg.sender, "free")).toEthSignedMessageHash().recover(v, r, s);
        if (recoverAddr != signerAddress) revert InvalidSignature(recoverAddr);
        if (freeMintRecord[msg.sender] > 0) revert MintNumberLimitReached();
        if (++freeMinted > FREE_LIMIT) revert FreeLimit();

        freeMintRecord[msg.sender] = 1;
        uint256 nextId = _nextTokenId();

        _mint(msg.sender, 1);

        emit Sale(msg.sender, nextId, 1, Channel.Free);
    }

    function preSale(
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable onPreSale onlyHuman onSale(amount) {
        address recoverAddr = keccak256(abi.encodePacked(msg.sender, "pre")).toEthSignedMessageHash().recover(v, r, s);
        if (recoverAddr != signerAddress) revert InvalidSignature(recoverAddr);
        if (msg.value < preSalePrice * amount) revert PayingNotEnough();
        uint256 preSaleNumber = preSaleMintRecord[msg.sender];
        if (preSaleNumber + amount > 3) revert MintNumberLimitReached();

        preSaleMintRecord[msg.sender] = preSaleNumber + amount;
        uint256 nextId = _nextTokenId();

        _mint(msg.sender, amount);

        emit Sale(msg.sender, nextId, amount, Channel.Pre);
    }

    function publicSale(uint256 amount) external payable onPublicSale onlyHuman onSale(amount) {
        if (msg.value < getPublicSalePrice() * amount) revert PayingNotEnough();
        uint256 publicSaleNumber = publicSaleMintRecord[msg.sender];
        if (publicSaleNumber + amount > 5) revert MintNumberLimitReached();

        publicSaleMintRecord[msg.sender] = amount + publicSaleNumber;
        uint256 nextId = _nextTokenId();

        _mint(msg.sender, amount);

        emit Sale(msg.sender, nextId, amount, Channel.Public);
    }

    function terminateMint() external onlyOwner {
        if (terminatedMint) revert Terminated();
        terminatedMint = true;
    }

    function compose(
        uint256 tokenA,
        uint256 tokenB,
        ComposeType cType,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyHuman {
        address recoverAddr = keccak256(abi.encodePacked(msg.sender, tokenA, tokenB, cType))
            .toEthSignedMessageHash()
            .recover(v, r, s);
        if (recoverAddr != signerAddress) revert InvalidSignature(recoverAddr);
        CharacterKind kind;
        if (cType == ComposeType.Fo) {
            kind = CharacterKind.Fo;
        } else if (cType == ComposeType.Mo) {
            kind = CharacterKind.Mo;
        } else if (cType == ComposeType.Random) {
            uint256 rnd = random(1, 100);
            if (rnd <= 50) {
                kind = CharacterKind.Sheng;
            } else {
                kind = CharacterKind.Mo;
            }
        } else {
            revert InvalidArgs();
        }

        uint256 newTokenId = _nextTokenId();
        characterKind[newTokenId] = kind;
        _burn(tokenA, true);
        _burn(tokenB, true);
        _mint(msg.sender, 1);
        emit Compose(tokenA, tokenB, newTokenId, kind);
    }

    function reserved(address receiver) external onlyOwner {
        if (reservedMinted) revert Terminated();
        uint256 amount = 77 - 1;

        totalMinted += amount;
        _mint(receiver, amount);
        reservedMinted = true;
    }

    function setStepPrice(
        uint256 step1,
        uint256 step2,
        uint256 step3
    ) external onlyOwner {
        stepPrice[1] = step1;
        stepPrice[2] = step2;
        stepPrice[3] = step3;
    }

    function getPublicSalePrice() public view returns (uint256 price) {
        bool ended = block.timestamp > publicSaleEndTime;
        if (ended) {
            uint256 minted = totalMinted;
            if (minted <= 5000) {
                price = stepPrice[1];
            } else if (minted <= 7000) {
                price = stepPrice[2];
            } else {
                price = stepPrice[3];
            }
        } else {
            price = publicSaleBasePrice;
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getRandomSeed(address user) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(user, _seed, blockhash(block.number - 1), gasleft())));
    }

    function random(uint256 min, uint256 max) private view returns (uint256) {
        // inclusive,inclusive (don't use absolute min and max values of uint256)
        // deterministic based on seed provided
        uint256 diff = max - min + 1;
        uint256 randomVar = uint256(keccak256(abi.encodePacked(getRandomSeed(tx.origin)))) % diff;
        return randomVar + min;
    }

    function setWithdrawalWallet(address wallet) external onlyOwner {
        withdrawalWallet = wallet;
    }

    function distribute(uint256 amount) external onlyOwner {
        address wallet = withdrawalWallet;
        if (wallet == address(0)) revert InvalidAddress(wallet);
        (bool success, bytes memory data) = wallet.call{value: amount}(new bytes(0));
        if (!success) revert CallError(data);
    }

    function recover(address receiver, uint256 amount) external onlyOwner {
        if (receiver == address(0)) revert InvalidAddress(receiver);
        (bool success, bytes memory data) = receiver.call{value: amount}(new bytes(0));
        if (!success) revert CallError(data);
    }

    function resetSeed() external onlyOwner {
        _seed = getRandomSeed(msg.sender);
    }

    receive() external payable {}
}