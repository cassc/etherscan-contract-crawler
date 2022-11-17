// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./OperatorFilter/DefaultOperatorFilterer.sol";

error MaxPerWallet();
error InvalidProof();
error NotStarted();
error InvalidPrice();
error InvalidPhaseParameters();
error InvalidRedemptionContract();
error NotOwnerOfToken();
error SoldOut();
error InvalidAirdrop();
error WithdrawFailed();
error SaleClosed();

// @author bueno.art
contract Lunchbox is
    ERC721AQueryable,
    Ownable,
    ERC2981,
    PaymentSplitter,
    DefaultOperatorFilterer
{
    uint256 public constant MAX_SUPPLY = 10_000;

    uint256 public publicPrice = 0.09 ether;
    uint256 public publicStart;
    uint256 public burnStart;
    uint256 private numPhases;

    address public hkContract = address(0);

    string public _baseTokenURI;

    bool private _paused = false;

    struct Phase {
        uint64 amountMinted;
        uint64 maxPerWallet;
        uint64 price;
        uint64 startTime;
        bytes32 merkleRoot;
    }

    mapping(uint256 => Phase) public phases;

    mapping(address => mapping(uint256 => uint256))
        private amountMintedForPhase;

    constructor(
        Phase[] memory _phases,
        uint256 _publicStart,
        uint256 _burnStart,
        address[] memory _withdrawAddresses,
        uint256[] memory _withdrawPercentages,
        string memory _baseUri,
        address _royaltyAddress,
        uint96 _royaltyAmount
    )
        ERC721A("Humankind Lunchbox", "LNCH")
        PaymentSplitter(_withdrawAddresses, _withdrawPercentages)
    {
        for (uint256 i = 0; i < _phases.length; ) {
            phases[i] = _phases[i];

            unchecked {
                ++i;
            }
        }

        _baseTokenURI = _baseUri;
        publicStart = _publicStart;
        burnStart = _burnStart;
        numPhases = _phases.length;

        _setDefaultRoyalty(_royaltyAddress, _royaltyAmount);
    }

    /**
     * @dev Used for minting in a particular phase. All phases are allowlist-gated.
     */
    function claimLunchbox(
        uint256 quantity,
        bytes32[] calldata proof,
        uint8 phaseIndex
    ) external payable whenNotPaused {
        Phase storage phase = phases[phaseIndex];

        if (phase.startTime > block.timestamp) {
            revert NotStarted();
        }

        if (msg.value != phase.price * quantity) {
            revert InvalidPrice();
        }

        if (
            !MerkleProof.verify(
                proof,
                phase.merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            revert InvalidProof();
        }

        unchecked {
            if (_totalMinted() + quantity > MAX_SUPPLY) {
                revert SoldOut();
            }

            uint256 amountMinted = amountMintedForPhase[msg.sender][phaseIndex];
            uint256 updatedAmountMinted = amountMinted + quantity;

            if (updatedAmountMinted > phase.maxPerWallet) {
                revert MaxPerWallet();
            }

            amountMintedForPhase[msg.sender][phaseIndex] = updatedAmountMinted;
            phase.amountMinted += uint64(quantity);
        }

        _mint(msg.sender, quantity);
    }

    /**
     * @dev Used for minting multiple phases in a single transaction
     */
    function claimLunchboxes(
        uint256[] calldata quantities,
        bytes32[][] calldata proofs,
        uint8[] calldata phaseIndices
    ) external payable whenNotPaused {
        uint256 phaseLength = phaseIndices.length;

        if (phaseLength > numPhases) {
            revert InvalidPhaseParameters();
        }

        uint256 balance = msg.value;

        for (uint256 i = 0; i < phaseLength; ) {
            uint8 phaseIndex = phaseIndices[i];
            uint256 quantity = quantities[i];
            bytes32[] memory proof = proofs[i];

            Phase storage phase = phases[phaseIndex];

            if (phase.startTime > block.timestamp) {
                revert NotStarted();
            }

            if (
                !MerkleProof.verify(
                    proof,
                    phase.merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                )
            ) {
                revert InvalidProof();
            }

            unchecked {
                if (_totalMinted() + quantity > MAX_SUPPLY) {
                    revert SoldOut();
                }

                uint256 priceForPhase = phases[phaseIndex].price * quantity;

                if (balance < priceForPhase) {
                    revert InvalidPrice();
                }

                uint256 amountMinted = amountMintedForPhase[msg.sender][
                    phaseIndex
                ];
                uint256 updatedAmountMinted = amountMinted + quantity;

                if (updatedAmountMinted > phase.maxPerWallet) {
                    revert MaxPerWallet();
                }

                amountMintedForPhase[msg.sender][
                    phaseIndex
                ] = updatedAmountMinted;

                phase.amountMinted += uint64(quantity);

                balance -= priceForPhase;

                _mint(msg.sender, quantity);

                ++i;
            }
        }
    }

    /**
     * @dev Public Lunchbox minting phase
     */
    function claimPublicLunchbox(uint256 quantity)
        external
        payable
        whenNotPaused
    {
        if (block.timestamp < publicStart) {
            revert NotStarted();
        }

        if (msg.value != quantity * publicPrice) {
            revert InvalidPrice();
        }

        if (_totalMinted() + quantity > MAX_SUPPLY) {
            revert SoldOut();
        }

        _mint(msg.sender, quantity);
    }

    /**
     * @dev Burns a Lunchbox if conditions are met. Can only be called by HK Redemption contract
     */
    function openLunchbox(address minter, uint256 tokenId) external {
        if (block.timestamp < burnStart) {
            revert NotStarted();
        }

        if (msg.sender != hkContract) {
            revert InvalidRedemptionContract();
        }

        if (ownerOf(tokenId) != minter) {
            revert NotOwnerOfToken();
        }

        _burn(tokenId, false);
    }

    // View Functions
    function getAmountMintedForPhase(address _address, uint8 phaseIndex)
        external
        view
        returns (uint256)
    {
        return amountMintedForPhase[_address][phaseIndex];
    }

    function getPhaseMintTotal(address _address)
        external
        view
        returns (uint256)
    {
        uint256 total;

        for (uint256 i = 0; i < numPhases; ) {
            total += amountMintedForPhase[_address][i];

            unchecked {
                ++i;
            }
        }

        return total;
    }

    function amountMintedForOwner(address _address)
        external
        view
        returns (uint256)
    {
        return _numberMinted(_address);
    }

    function numberBurnedForOwner(address _address)
        external
        view
        returns (uint256)
    {
        return _numberBurned(_address);
    }

    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function getDataForPhase(uint64 phaseIndex)
        external
        view
        returns (Phase memory)
    {
        return phases[phaseIndex];
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    // Owner functions
    function pauseMint() external onlyOwner {
        _paused = true;
    }

    function unpauseMint() external onlyOwner {
        _paused = false;
    }

    function updatePhaseSettings(uint64 phaseIndex, Phase calldata phase)
        public
        onlyOwner
    {
        Phase storage phaseData = phases[phaseIndex];

        uint64 amountMinted = phaseData.amountMinted;

        phases[phaseIndex] = phase;

        // amount minted cannot be overwritten
        phases[phaseIndex].amountMinted = amountMinted;
    }

    function bulkUpdatePhaseSettings(
        uint64[] calldata phaseIndices,
        Phase[] calldata _phases
    ) external onlyOwner {
        uint256 phaseLength = phaseIndices.length;

        if (phaseLength > numPhases) {
            revert InvalidPhaseParameters();
        }

        for (uint256 i = 0; i < phaseLength; ) {
            updatePhaseSettings(phaseIndices[i], _phases[i]);

            unchecked {
                ++i;
            }
        }
    }

    function updatePublicPrice(uint256 newPrice) external onlyOwner {
        publicPrice = newPrice;
    }

    function updatePublicStart(uint256 _publicStart) external onlyOwner {
        publicStart = _publicStart;
    }

    function updatePhaseStart(uint64 phaseIndex, uint64 phaseStart)
        external
        onlyOwner
    {
        phases[phaseIndex].startTime = phaseStart;
    }

    function updateBurnStart(uint256 _burnStart) external onlyOwner {
        burnStart = _burnStart;
    }

    function setRedemptionContract(address _hkContract) external onlyOwner {
        if (_hkContract == address(0)) {
            revert InvalidRedemptionContract();
        }

        hkContract = _hkContract;
    }

    function airdrop(uint64[] calldata qtys, address[] calldata recipients)
        external
        onlyOwner
    {
        uint256 numRecipients = recipients.length;
        if (numRecipients != qtys.length) revert InvalidAirdrop();

        for (uint256 i = 0; i < numRecipients; ) {
            if (_totalMinted() + qtys[i] > MAX_SUPPLY) {
                revert SoldOut();
            }

            _mint(recipients[i], qtys[i]);

            unchecked {
                ++i;
            }
        }
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        if (balance == 0) {
            revert WithdrawFailed();
        }

        (bool success, ) = msg.sender.call{value: balance}("");

        if (!success) {
            revert WithdrawFailed();
        }
    }

    // OperatorFilter overrides
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Modifiers
    modifier whenNotPaused() {
        if (paused()) {
            revert SaleClosed();
        }
        _;
    }
}