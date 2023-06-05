// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
ERC721EnumerableUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {
ERC721Upgradeable,
IERC721Upgradeable,
ERC721PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import {
MerkleProofUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {
StringsUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract AtsuiNft is
OwnableUpgradeable,
ERC721EnumerableUpgradeable,
ERC721PausableUpgradeable, DefaultOperatorFiltererUpgradeable
{
    using StringsUpgradeable for uint256;

    string public constant NAME = "Judgy Dinos";
    string public constant SYMBOL = "JD";
    uint256 public constant PRICE0_0 = 0.007 ether;
    uint256 public constant PRICE0_1 = 0.011 ether;
    uint256 public constant PRICE1_0 = 0.011 ether;
    uint256 public constant PRICE1_1 = 0.011 ether;
    uint256 public constant AMOUNT_MAX = 5;
    uint256 public constant TOTALSUPPLY0 = 1500;
    uint256 public constant TOTALSUPPLY1 = 3500;

    struct PhasePrice {
        uint256 price0;
        uint256 price1;
    }

    address public treasure;
    uint8 public phase;

    string public baseURI;
    PhasePrice[] public prices;
    uint256[] public amountMaxs;
    bytes32[] public merkleRoots;
    uint256[] public totalSupplies;
    uint256[] public balances;

    event NextPhase(address, uint256);
    event SetTreasure(address, address);
    event SetPrice(address, uint256, uint256, uint256);
    event SetAmountMax(address, uint256, uint256);
    event SetMerkleRoot(address, bytes32, uint256);
    event SetTotalSupply(address, uint256, uint256);
    event SetBaseURI(address, string);
    event Withdraw(address, uint256);
    event Price(uint256);

    function initialize(
        address treasure_,
        string memory baseURI_,
        bytes32 merkleRoot0,
        bytes32 merkleRoot1
    ) public virtual initializer {
        __AtsuiNft_init_(treasure_, baseURI_, merkleRoot0, merkleRoot1);
    }

    function __AtsuiNft_init_(
        address treasure_,
        string memory baseURI_,
        bytes32 merkleRoot0,
        bytes32 merkleRoot1
    ) internal onlyInitializing {
        __Ownable_init_unchained();
        __ERC721_init_unchained(NAME, SYMBOL);
        __Pausable_init_unchained();
        __DefaultOperatorFilterer_init();
        __AtsuiNft_init_unchained(
            treasure_,
            baseURI_,
            merkleRoot0,
            merkleRoot1
        );
    }

    function __AtsuiNft_init_unchained(
        address treasure_,
        string memory baseURI_,
        bytes32 merkleRoot0,
        bytes32 merkleRoot1
    ) internal onlyInitializing {
        treasure = treasure_;
        baseURI = baseURI_;
        prices.push(PhasePrice({price0: PRICE0_0, price1: PRICE0_1}));
        prices.push(PhasePrice({price0: PRICE1_0, price1: PRICE1_1}));
        amountMaxs.push(AMOUNT_MAX);
        amountMaxs.push(AMOUNT_MAX);
        merkleRoots.push(merkleRoot0);
        merkleRoots.push(merkleRoot1);
        totalSupplies.push(TOTALSUPPLY0);
        totalSupplies.push(TOTALSUPPLY1);
        balances.push(0);
        balances.push(0);
    }

    /**
     * @dev Sets treasure
     */
    function setTreasure(address treasure_) external onlyOwner {
        require(treasure_ != address(0) && treasure_ != treasure, "!address");
        treasure = treasure_;
        emit SetTreasure(_msgSender(), treasure_);
    }

    /**
     * @dev Sets base uri
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit SetBaseURI(_msgSender(), baseURI_);
    }

    /**
     * @dev Sets price for phase
     */
    function setPrice(uint256 price0_, uint256 price1_, uint256 phase_) external onlyOwner {
        require(
            phase_ >= phase &&
            phase_ < prices.length &&
            prices[phase_].price0 != price0_ &&
            prices[phase_].price1 != price1_,
            "!price"
        );
        prices[phase_] = PhasePrice({price0: price0_, price1: price1_});
        emit SetPrice(_msgSender(), price0_, price1_, phase_);
    }

    /**
     * @dev Sets amount max for phase
     */
    function setAmountMax(uint256 amountMax_, uint256 phase_)
    external
    onlyOwner
    {
        require(
            phase_ >= phase &&
            phase_ < amountMaxs.length &&
            amountMaxs[phase_] != amountMax_,
            "!amount"
        );
        amountMaxs[phase_] = amountMax_;
        emit SetAmountMax(_msgSender(), amountMax_, phase_);
    }

    /**
     * @dev Sets amount max for phase
     */
    function setTotalSupply(uint256 totalSupply_, uint256 phase_)
    external
    onlyOwner
    {
        require(
            phase_ >= phase &&
            phase_ < totalSupplies.length &&
            totalSupplies[phase_] != totalSupply_ &&
            balances[phase_] <= totalSupply_,
            "!supply"
        );
        totalSupplies[phase_] = totalSupply_;
        emit SetTotalSupply(_msgSender(), totalSupply_, phase_);
    }

    /**
     * @dev Sets merkle root for phase
     */
    function setMerkleRoot(bytes32 merkleRoot_, uint256 phase_)
    external
    onlyOwner
    {
        require(
            phase_ >= phase &&
            phase_ < merkleRoots.length &&
            merkleRoots[phase_] != merkleRoot_,
            "!root"
        );
        merkleRoots[phase_] = merkleRoot_;
        emit SetMerkleRoot(_msgSender(), merkleRoot_, phase_);
    }

    /**
     * @dev Returns true if phase is last
     */
    function isLastPhase() public view returns (bool) {
        return phase == prices.length - 1;
    }

    /**
     * @dev Returns true if phase is last
     */
    function nextTokenId() public view returns (uint256 id) {
        unchecked {
            uint256 i = 0;
            while (i <= phase) {
                id += balances[i];
                i++;
            }
        }
    }

    /**
     * @dev Returns available quantity in current phase
     */
    function available() public view returns (uint256 quantity) {
        return totalSupplies[phase] - balances[phase];
    }

    /**
     * @dev Returns available quantity of address in current phase
     */
    function availableFor(address to) public view returns (uint256 quantity) {
        quantity = amountMaxs[phase] - mints[phase][to];

        uint256 _available = available();
        if (quantity > _available) {
            quantity = _available;
        }
    }

    /**
     * @dev Moves NFT SALES to next phase
     */
    function nextPhase() external onlyOwner {
        require(!isLastPhase(), "!phase");
        phase++;
        if (isLastPhase()) {
            _batchMint(treasure, 100);
        }
        totalSupplies[phase] += totalSupplies[phase - 1] - balances[phase - 1];
        emit NextPhase(_msgSender(), phase);
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     */
    function batchMint(
        address to,
        uint256 quantity,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused {
        bool already = mints[phase][to] > 0;
        uint256 cost = ((quantity - (already ? 0 : 1)) * prices[phase].price1) + (already ? 0 : prices[phase].price0);
        require(cost <= msg.value, "!cost ");
        require(
            quantity > 0 && quantity <= availableFor(_msgSender()),
            "!quantity"
        );
        if (!isLastPhase()) {
            _merkleProofVerify(
                merkleRoots[phase],
                index,
                _msgSender(),
                merkleProof
            );
        }
        mints[phase][_msgSender()] += quantity;
        _batchMint(to, quantity);
        if (msg.value > cost) {
            (bool success,) =
            _msgSender().call{value: msg.value - cost}(new bytes(0));
            require(success, "ETH_TRANSFER_FAILED");
        }
    }

    function _merkleProofVerify(
        bytes32 merkleRoot,
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) internal pure {
        bytes32 node = keccak256(abi.encodePacked(index, account, uint256(1)));
        require(
            MerkleProofUpgradeable.verify(merkleProof, merkleRoot, node),
            "!bad proof"
        );
    }

    function _batchMint(address to, uint256 quantity) internal {
        uint256 id = nextTokenId();
        for (uint256 i = 0; i < quantity;) {
            _mint(to, id);
            unchecked {
                i++;
                id++;
            }
        }
        balances[phase] += quantity;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must be an owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must be an owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Withdraws funds to treasure wallet
     */
    function withdraw() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "!balance");
        (bool success,) = treasure.call{value: balance}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
        emit Withdraw(treasure, balance);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        _requireMinted(tokenId);
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize

    )
    internal
    virtual
    override(ERC721EnumerableUpgradeable, ERC721PausableUpgradeable)
    {
        ERC721EnumerableUpgradeable._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override(IERC721Upgradeable, ERC721Upgradeable)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;

    mapping(uint256 => mapping(address => uint256)) public mints;
}