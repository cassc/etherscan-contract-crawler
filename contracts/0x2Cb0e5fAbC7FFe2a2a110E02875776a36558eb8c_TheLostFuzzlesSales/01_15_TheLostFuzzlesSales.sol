// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./UniswapQuery.sol";

contract TheLostFuzzlesSales is
    Ownable,
    Pausable,
    UniswapQuery,
    ReentrancyGuard
{
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;
    using Address for address payable;

    enum Phase {
        FH,
        ALFH,
        PUBLIC
    }

    IERC20 public gala;
    Phase public currentPhase;

    address public nft;
    address public crossmint;
    address public corporate;
    uint256 public purchasePriceInEth;
    uint256 public maxPurchase;
    bool private _pausedGala;
    bytes32 private _whitelistMerkleRoot;

    mapping(address => mapping(Phase => bool)) private _claimed;

    event onPurchase(
        address indexed minter,
        uint8 indexed quantity,
        bool paidInGala,
        uint256 totalPrice,
        uint256 timestamp
    );
    event SetPurchasePrice(
        address indexed owner,
        uint256 price,
        uint256 timestamp
    );
    event SetMaxPurchase(
        address indexed owner,
        uint256 indexed max,
        uint256 timestamp
    );
    event SetMerkleRoot(address indexed owner, bytes32 root, uint256 timestamp);
    event Withdraw(
        address indexed owner,
        address indexed receiver,
        uint256 amount
    );

    constructor(
        address _nft,
        address _gala,
        address _corporate,
        address _crossmint
    ) {
        nft = _nft;
        gala = IERC20(_gala); // 0x15D4c048F83bd7e37d49eA4C83a07267Ec4203dA
        corporate = _corporate;
        crossmint = _crossmint; // 0xdab1a1854214684ace522439684a145e62505233
        purchasePriceInEth = 0.05 ether;
        maxPurchase = 10;
    }

    fallback() external payable {}

    receive() external payable {}

    modifier validAmount(uint8 quantity) {
        _checValidAmount(quantity);
        _;
    }

    modifier whenNotPausedGala() {
        require(!pausedGala(), "gala paused");
        _;
    }

    modifier onlyCrossmint() {
        require(msg.sender == crossmint, "not crossmint");
        _;
    }

    function purchase(
        address beneficiary,
        uint8 quantity,
        bytes32[] calldata merkleProof
    )
        external
        payable
        whenNotPaused
        onlyCrossmint
        validAmount(quantity)
        nonReentrant
    {
        _validate(quantity, beneficiary, merkleProof);
        _mint(beneficiary, quantity, msg.value, false);
    }

    function purchase(uint8 quantity, bytes32[] calldata merkleProof)
        external
        payable
        whenNotPaused
        validAmount(quantity)
        nonReentrant
    {
        _validate(quantity, msg.sender, merkleProof);
        _mint(msg.sender, quantity, msg.value, false);
    }

    function purchase(
        uint8 quantity,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external whenNotPausedGala nonReentrant {
        address minter = msg.sender;
        uint256 purchasePriceInGala = getGalaAmount(purchasePriceInEth);

        require(purchasePriceInGala != 0, "purchasePriceInGala is zero");
        require(amount >= purchasePriceInGala * quantity, "amount not enough");
        require(corporate != address(0x0), "corporate is empty");
        require(gala.balanceOf(minter) >= amount, "not enough Gala token");
        require(
            gala.allowance(minter, address(this)) >= amount,
            "insufficient Gala token approval"
        );

        _validate(quantity, minter, merkleProof);
        gala.safeTransferFrom(minter, corporate, amount);
        _mint(minter, quantity, amount, true);
    }

    function _validate(
        uint8 quantity,
        address minter,
        bytes32[] calldata merkleProof
    ) internal {
        require(quantity != 0, "quantity is zero");
        require(quantity <= maxPurchase, "quantity exceeded");

        if (currentPhase != Phase.PUBLIC) {
            require(!_claimed[minter][currentPhase], "already claimed");
            require(_whitelistMerkleRoot != "", "merkle tree not set");
            require(merkleProof.length != 0, "merkleProof empty");
            bytes32 leaf = keccak256(abi.encodePacked(minter));
            require(
                MerkleProof.verify(merkleProof, _whitelistMerkleRoot, leaf),
                "invalid Merkle Proof"
            );

            _claimed[minter][currentPhase] = true;
        }
    }

    function _mint(
        address minter,
        uint8 quantity,
        uint256 amount,
        bool isGala
    ) internal {
        (bool success, ) = address(nft).call(
            abi.encodeWithSignature("mint(address,uint8)", minter, quantity)
        );
        require(success, "mint failed");
        emit onPurchase(minter, quantity, isGala, amount, block.timestamp);
    }

    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getClaimedPhase(address minter, Phase phase)
        external
        view
        returns (bool)
    {
        return _claimed[minter][phase];
    }

    function setCurrentPhase(Phase phase, bytes32 newMerkleRoot)
        external
        onlyOwner
    {
        require(uint8(phase) <= 2, "invalid phase");

        if (phase == Phase.FH || phase == Phase.ALFH) {
            if (phase == Phase.FH) {
                purchasePriceInEth = 0.05 ether;
            } else if (phase == Phase.ALFH) {
                purchasePriceInEth = 0.06 ether;
            }
            require(newMerkleRoot != "", "newMerkleRoot empty");
            _whitelistMerkleRoot = newMerkleRoot;
        } else {
            // PUBLIC
            purchasePriceInEth = 0.07 ether;
            _whitelistMerkleRoot = "";
        }

        currentPhase = phase;
    }

    function setPurchasePrice(uint256 newPrice) external onlyOwner {
        require(newPrice != 0, "newPrice is zero");
        purchasePriceInEth = newPrice;
        emit SetPurchasePrice(msg.sender, newPrice, block.timestamp);
    }

    function setMaxPurchase(uint256 newMaxPurchase) external onlyOwner {
        require(newMaxPurchase != 0, "newMaxPurchase is zero");
        maxPurchase = newMaxPurchase;
        emit SetPurchasePrice(msg.sender, newMaxPurchase, block.timestamp);
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        require(newMerkleRoot != "", "newMerkleRoot empty");
        _whitelistMerkleRoot = newMerkleRoot;
        emit SetMerkleRoot(msg.sender, newMerkleRoot, block.timestamp);
    }

    function setCrossmint(address crosssmintAddress) public onlyOwner {
        require(crosssmintAddress != address(0x0), "crosssmintAddress is empty");
        crossmint = crosssmintAddress;
    }

    function setCorporate(address corporateAddress) public onlyOwner {
        require(corporateAddress != address(0x0), "corporateAddress is empty");
        corporate = corporateAddress;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function pauseGala() external onlyOwner {
        _pausedGala = true;
    }

    function unpauseGala() external onlyOwner {
        _pausedGala = false;
    }

    function pausedGala() public view virtual returns (bool) {
        return _pausedGala;
    }

    /**
     * @dev Throws if the sender has not sent valid amount.
     */
    function _checValidAmount(uint8 quantity) internal view virtual {
        require(
            msg.value >= purchasePriceInEth * quantity,
            "amount not enough"
        );
    }

    function withdraw(address payable receiver) external virtual onlyOwner {
        require(receiver != address(0x0), "receiver is empty");
        uint256 balance = address(this).balance;
        receiver.sendValue(balance);
        emit Withdraw(msg.sender, receiver, balance);
    }
}