// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract Mafagafo is Initializable, ERC721AUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public constant MAX_SUPPLY = 7117;

    string public preRevealBaseURI;
    string private _baseTokenURI;

    bytes32 public merkleRoot;

    address public firstReceiver;
    address public secondReceiver;
    uint256 public firstOptionAmount;
    uint256 public secondOptionAmount;
    uint256 public thirdOptionAmount;

    bool public isFirstOptionOn;
    bool public isSecondOptionOn;
    bool public isThirdOptionOn;

    mapping(address => uint256) public totalClaimed;
    mapping(address => uint256) public totalClaimed2;

    uint256 public totalMintedPhase2;

    error MaxSupplyExceeded(uint256 totalSupply, uint256 quantity);
    error AlreadyClaimed(address account);
    error InvalidProof();
    error PriceMismatch(uint256 value, uint256 price);
    error QuantityError(uint256 quantity);
    error TransferError();
    error InvalidOption();
    error SoldOut();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata _preRevealBaseURI,
        address mafaTech,
        uint256 mafaTechSupply,
        bytes32 _merkleRoot,
        address _firstReceiver,
        address _secondReceiver,
        uint256 _firstOptionAmount,
        uint256 _secondOptionAmount,
        uint256 _thirdOptionAmount
    ) public initializerERC721A initializer {
        __ERC721A_init("Mafagafo", "MAFA");
        __Ownable_init();
        __UUPSUpgradeable_init();

        preRevealBaseURI = _preRevealBaseURI;

        merkleRoot = _merkleRoot;

        firstReceiver = _firstReceiver;
        secondReceiver = _secondReceiver;
        firstOptionAmount = _firstOptionAmount;
        secondOptionAmount = _secondOptionAmount;
        thirdOptionAmount = _thirdOptionAmount;

        totalMintedPhase2 = 0;

        isFirstOptionOn = true;
        isSecondOptionOn = true;
        isThirdOptionOn = true;

        _safeMint(mafaTech, mafaTechSupply);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setFirstReceiver(address _firstReceiver) external onlyOwner {
        firstReceiver = _firstReceiver;
    }

    function setSecondReceiver(address _secondReceiver) external onlyOwner {
        secondReceiver = _secondReceiver;
    }

    function setFirstOptionAmount(uint256 _firstOptionAmount) external onlyOwner {
        firstOptionAmount = _firstOptionAmount;
    }

    function setSecondOptionAmount(uint256 _secondOptionAmount) external onlyOwner {
        secondOptionAmount = _secondOptionAmount;
    }

    function setThirdOptionAmount(uint256 _thirdOptionAmount) external onlyOwner {
        thirdOptionAmount = _thirdOptionAmount;
    }

    function setFirstOption(bool _flag) external onlyOwner {
        isFirstOptionOn = _flag;
    }

    function setSecondOption(bool _flag) external onlyOwner {
        isSecondOptionOn = _flag;
    }

    function setThirdOption(bool _flag) external onlyOwner {
        isThirdOptionOn = _flag;
    }

    function safeMintMafaTech(address to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded(totalSupply(), quantity);

        _safeMint(to, quantity);
    }

    function safeMint(address to, uint256 quantity) internal {
        if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded(totalSupply(), quantity);

        _safeMint(to, quantity);
    }

    /**
     * @dev Variation of {ERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : preRevealBaseURI;
    }

    function claim1(
        address account,
        uint256 quantity,
        uint256 totalQuantity,
        bytes32[] calldata merkleProof
    ) external {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(account, totalQuantity));

        if (!MerkleProofUpgradeable.verify(merkleProof, merkleRoot, node)) revert InvalidProof();
        if (totalClaimed[account] + quantity > totalQuantity) revert AlreadyClaimed(account);

        totalClaimed[account] += quantity;

        safeMint(account, quantity);

        emit Claimed(account, quantity);
    }

    function claim2(address account, uint256 quantity) external payable {
        if (!(quantity == 1 || quantity == 3 || quantity == 5)) revert QuantityError(quantity);
        if (totalClaimed2[account] > 0) revert AlreadyClaimed(account);
        if (quantity + totalMintedPhase2 > 411) revert SoldOut();

        totalClaimed2[account] += quantity;
        totalMintedPhase2 += quantity;

        uint256 firstAmount;
        uint256 secondAmount;
        uint256 _firstOptionAmount = firstOptionAmount;
        uint256 _secondOptionAmount = secondOptionAmount;
        uint256 _thirdOptionAmount = thirdOptionAmount;
        if (quantity == 1) {
            if (!isFirstOptionOn) revert InvalidOption();
            if (msg.value != _firstOptionAmount) revert PriceMismatch(msg.value, _firstOptionAmount);

            firstAmount = (_firstOptionAmount * 70) / 100;
            secondAmount = (_firstOptionAmount * 30) / 100;
        } else if (quantity == 3) {
            if (!isSecondOptionOn) revert InvalidOption();
            if (msg.value != _secondOptionAmount) revert PriceMismatch(msg.value, _secondOptionAmount);

            firstAmount = (_secondOptionAmount * 70) / 100;
            secondAmount = (_secondOptionAmount * 30) / 100;
        } else if (quantity == 5) {
            if (!isThirdOptionOn) revert InvalidOption();
            if (msg.value != _thirdOptionAmount) revert PriceMismatch(msg.value, _thirdOptionAmount);

            firstAmount = (_thirdOptionAmount * 70) / 100;
            secondAmount = (_thirdOptionAmount * 30) / 100;
        }

        (bool firstSent, ) = firstReceiver.call{ value: firstAmount }("");
        if (!firstSent) revert TransferError();

        (bool secondSent, ) = secondReceiver.call{ value: secondAmount }("");
        if (!secondSent) revert TransferError();

        safeMint(account, quantity);

        emit Claimed(account, quantity);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    event Claimed(address indexed account, uint256 indexed quantity);
}