// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ERC721EnumerableUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {
    ERC721Upgradeable,
    ERC721PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import {
    MerkleProofUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {
    StringsUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract AtsuiNft is
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721PausableUpgradeable
{
    using StringsUpgradeable for uint256;

    string public constant NAME = "ATSUI NFT";
    string public constant SYMBOL = "ANFT";
    uint256 public constant PRICE0 = 0.089 ether;
    uint256 public constant PRICE1 = 0.098 ether;
    uint256 public constant PRICE2 = 0.098 ether;
    uint256 public constant AMOUNT_MAX = 2;
    uint256 public constant TOTALSUPPLY0 = 2500;
    uint256 public constant TOTALSUPPLY1 = 3000;
    uint256 public constant TOTALSUPPLY2 = 55;

    address public treasure;
    uint8 public phase;

    string public baseURI;
    uint256[] public prices;
    uint256[] public amountMaxs;
    bytes32[] public merkleRoots;
    uint256[] public totalSupplies;
    uint256[] public balances;

    event NextPhase(address, uint256);
    event SetTreasure(address, address);
    event SetPrice(address, uint256, uint256);
    event SetAmountMax(address, uint256, uint256);
    event SetMerkleRoot(address, bytes32, uint256);
    event SetTotalSupply(address, uint256, uint256);
    event SetBaseURI(address, string);
    event Withdraw(address, uint256);

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
        prices.push(PRICE0);
        prices.push(PRICE1);
        prices.push(PRICE2);
        amountMaxs.push(AMOUNT_MAX);
        amountMaxs.push(AMOUNT_MAX);
        amountMaxs.push(AMOUNT_MAX);
        merkleRoots.push(merkleRoot0);
        merkleRoots.push(merkleRoot1);
        totalSupplies.push(TOTALSUPPLY0);
        totalSupplies.push(TOTALSUPPLY1);
        totalSupplies.push(TOTALSUPPLY2);
        balances.push(0);
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
    function setPrice(uint256 price_, uint256 phase_) external onlyOwner {
        require(
            price_ != 0 &&
                phase_ >= phase &&
                phase_ < prices.length &&
                prices[phase_] != price_,
            "!price"
        );
        prices[phase_] = price_;
        emit SetPrice(_msgSender(), price_, phase_);
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
        uint256 total = balanceOf(to);
        uint256 phaseFirstId = phase > 0 ? balances[phase - 1] : 0;
        quantity = amountMaxs[phase];
        for (uint256 i = 0; i < total; ) {
            if (tokenOfOwnerByIndex(to, i) >= phaseFirstId) {
                quantity--;
            }
            unchecked {i++;}
        }

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
            _batchMint(treasure, totalSupplies[phase]);
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
        uint256 cost = quantity * prices[phase];
        require(cost <= msg.value, "!cost");
        require(quantity <= availableFor(_msgSender()), "!quantity");
        if (!isLastPhase()) {
            _merkleProofVerify(
                merkleRoots[phase],
                index,
                _msgSender(),
                merkleProof
            );
        }
        _batchMint(to, quantity);
        if (msg.value > cost) {
            (bool success, ) =
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
        for (uint256 i = 0; i < quantity; ) {
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
        (bool success, ) = treasure.call{value: balance}(new bytes(0));
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
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721EnumerableUpgradeable, ERC721PausableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}