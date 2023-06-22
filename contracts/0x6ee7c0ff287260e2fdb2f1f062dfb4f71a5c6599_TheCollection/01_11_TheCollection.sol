// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {ERC721A} from "ERC721A/ERC721A.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import "./Banker.sol";

error InvalidFunds();
error InvalidQuantity();
error InvalidProof();
error InvalidToken();
error MaxQuantityReached();
error MaxQuantityPerTxReached();
error NotEnoughSupply();
error SaleIsNotOpen();
error ContractPaused();

enum Rank {
    GM,
    AGM,
    FO,
    Gold
}

enum Phase {
    Closed,
    One,
    Two
}

enum Sale {
    Allowlist,
    Public
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract TheCollection is Owned, ERC721A, Banker {
    using Strings for uint256;

    event RankedMint(Rank indexed rank, address indexed account, uint256 startId, uint256 quantity);

    struct CountTracker {
        bool phase1ExternalClaim;
        uint32 phase1Allowlist;
        uint32 phase1Public;
        uint32 phase2DraftClaim;
        uint32 phase2Allowlist;
        uint32 phase2Public;
    }

    uint16 public constant MaxMintPhase1Allowlist = 1;
    uint16 public constant MaxMintPhase1Total = 5;
    uint16 public constant MaxMintPhase2Allowlist = 2;

    uint256 public draftPriceGM = 1 ether;
    uint256 public draftPriceAGM = 0.5 ether;
    uint256 public draftPriceFO = 0.19 ether;
    uint256 public phase2AllowlistPrice = 0.1 ether;
    uint256 public phase2PublicPrice = 0.15 ether;

    uint16 public totalSupplyLimit = 6699;

    /// @dev Total remaining supply of ranks (after external presale has ended) to be minted during phase1
    uint16 public mintableTotalSupplyGM;
    uint16 public mintableTotalSupplyAGM;
    uint16 public mintableTotalSupplyFO;

    /// @dev Same as for phase 1, but modifiable by the owner
    uint16 public maxMintPhase2Total = 10;

    /// @dev Keep under 10 mint per tx to avoid running into issues with OpenSea + ERC721A
    /// Modifiable by the owner
    uint16 public maxMintPerTx = 9;

    /// @dev Totals of mints for each rank in phase 1.
    /// Doesn't take in account claims from external presale
    uint16 public totalMintedGM;
    uint16 public totalMintedAGM;
    uint16 public totalMintedFO;

    /// @dev Must be set by admin once phase 1 has ended.
    /// It's used to differenciate between revealed tokens of phase 1 and unrevealed tokens of phase 2.
    /// See {tokenURI(uint256)}.
    uint16 public phase1EndTokenId;

    bool public phase1Revealed;
    bool public phase2Revealed;

    Phase public phase;
    Sale public sale;
    bool public paused;

    /// @dev Not required to be hosted on IPFS and doesn't change between mainnet and testnets.
    /// Except for the royalties recipient address, which will always point to the mainnet wallet.
    string public contractUri = "https://lipsweater.io/collection/collection-metadata.json";

    /// @dev Not required to be hosted on IPFS and doesn't change between mainnet and testnets
    string public unrevealedUri = "ipfs://QmNQyexUM4H2ohxqm91HvFfqYP4hoRqKNE4YSR4BKSqBQC";

    string public phase1RevealedBaseUri;
    string public phase2RevealedBaseUri;

    mapping(address => CountTracker) _counters;

    /// @dev Accounts from external presale before phase1, that can claim `AGM quantity` and `FO quantity`
    /// Structure is <address, AGM quantity, FO quantity>
    bytes32 public phase1ExternalClaimsMerkle;

    /// @dev Allowlist of accounts for phase1
    bytes32 public phase1AllowlistMerkle;

    /// @dev Accounts from phase1 that can claim up to `total claimable quantity` depending on the ranks they own
    /// Structure is <address, total claimable quantity>
    bytes32 public phase2DraftClaimsMerkle;

    /// @dev Allowlist of accounts for phase2
    bytes32 public phase2AllowlistMerkle;

    /// @dev Addresses of marketplaces contracts for pre-approuved transfers.
    /// Modifiable by the owner
    address[] public approvedProxies;

    constructor(
        uint16 supplyGM,
        uint16 supplyAGM,
        uint16 supplyFO,
        address owner,
        address vault,
        uint256 vaultGoldsQuantity,
        address[] memory airdropAccountsGold,
        address[] memory proxies,
        Payee memory teamPayee,
        Payee memory devPayee,
        Payee memory royalties
    ) Owned(owner) ERC721A("Lipsweater", "LST") Banker(teamPayee, devPayee, royalties) {
        mintableTotalSupplyGM = supplyGM;
        mintableTotalSupplyAGM = supplyAGM;
        mintableTotalSupplyFO = supplyFO;
        approvedProxies = proxies;

        // Cheaper batch airdrop on contract creation
        // We don't emit `RankedBatchMint` as in airdropXXX() because those accounts and associated ids are known (ids from 1 to length)
        for (uint256 i = 0; i < airdropAccountsGold.length; ++i) {
            _mintERC2309(airdropAccountsGold[i], 1);
        }
        if (vaultGoldsQuantity > 0) {
            _mintERC2309(vault, vaultGoldsQuantity);
        }
    }

    /// COLLECTION SETTINGS

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @dev See https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    /// @dev Override default behavior to handle an unrevealed phase where all token URIs point to the same image.
    /// The format of URI is: {BASE}{id} which has following implications:
    ///   - BASE must have a trailing slash;
    ///   - URI must not have an extension
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidToken();

        if (phase1Revealed) {
            if (tokenId <= phase1EndTokenId) {
                return string(abi.encodePacked(phase1RevealedBaseUri, tokenId.toString()));
            } else if (phase2Revealed) {
                return string(abi.encodePacked(phase2RevealedBaseUri, tokenId.toString()));
            }
        }

        return unrevealedUri;
    }

    /// PHASE 1 (= draft)

    /// Claim free-mint for users who reserved their AGMs and FOs using the external presale.
    /// Each user can only claim once, so it needs to claim all available tokens at once.
    ///
    /// Can be claimed at any point during phase 1.
    function claimFromExternalPresale(
        uint256 quantityAGM,
        uint256 quantityFO,
        bytes32[] calldata proof
    ) external isPhase(Phase.One) {
        // The leaf must match encoded form of <address, quantityAGM, quantityFO>
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, quantityAGM, quantityFO));
        if (!MerkleProof.verifyCalldata(proof, phase1ExternalClaimsMerkle, leaf)) {
            revert InvalidProof();
        }

        if (_counters[msg.sender].phase1ExternalClaim) {
            revert MaxQuantityReached();
        }
        _counters[msg.sender].phase1ExternalClaim = true;

        /// Do not increment totalMintedXXX, as those are externally presold NFTs before contract creation,
        /// thus the contract will already have adjusted Supply to match those.
        if (quantityAGM > 0) {
            _mintRanked(Rank.AGM, msg.sender, quantityAGM);
        }

        if (quantityFO > 0) {
            _mintRanked(Rank.FO, msg.sender, quantityFO);
        }
    }

    /// Mint of phase 1 for allowlisted users.
    /// No difference in price with the public mint.
    /// Quantity is fixed to `MaxMintPhase1Allowlist`, regardless of the choosen rank.
    /// User can mint up to `MaxMintPhase1Total` tokens in total (not including claims).
    ///
    /// Can be minted only during allowlist sale of phase 1.
    function mintDraftAllowlist(bytes32[] calldata proof)
        external
        payable
        isPhase(Phase.One)
        isSale(Sale.Allowlist)
    {
        if (
            !MerkleProof.verifyCalldata(
                proof,
                phase1AllowlistMerkle,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            revert InvalidProof();
        }

        CountTracker memory tracker = _counters[msg.sender];

        if (
            tracker.phase1Allowlist >= MaxMintPhase1Allowlist ||
            (tracker.phase1Public + MaxMintPhase1Allowlist > MaxMintPhase1Total)
        ) {
            revert MaxQuantityReached();
        }

        _counters[msg.sender].phase1Allowlist = MaxMintPhase1Allowlist;

        _mintDraft(msg.sender, MaxMintPhase1Allowlist);
    }

    /// Public mint of phase 1.
    /// Until supplies of GM, AGM and FO run out.
    ///
    /// User can mint up to `MaxMintPhase1Total` tokens in total (not including claims).
    ///
    /// Token is minted and transfered `to` account.
    /// Expected to be called by USDT API.
    ///
    /// Can be minted only during public sale of phase 1.
    function crossmintDraft(address to, uint16 quantity)
        external
        payable
        isPhase(Phase.One)
        isSale(Sale.Public)
    {
        CountTracker memory tracker = _counters[to];

        if (tracker.phase1Allowlist + tracker.phase1Public + quantity > MaxMintPhase1Total) {
            revert MaxQuantityReached();
        }

        _counters[to].phase1Public += quantity;

        _mintDraft(to, quantity);
    }

    function _mintDraft(address to, uint16 quantity) internal {
        if (msg.value == draftPriceGM * quantity) {
            if (quantity + totalMintedGM > mintableTotalSupplyGM) {
                revert NotEnoughSupply();
            }

            totalMintedGM += quantity;
            _mintRanked(Rank.GM, to, quantity);
        } else if (msg.value == draftPriceAGM * quantity) {
            if (quantity + totalMintedAGM > mintableTotalSupplyAGM) {
                revert NotEnoughSupply();
            }

            totalMintedAGM += quantity;
            _mintRanked(Rank.AGM, to, quantity);
        } else if (msg.value == draftPriceFO * quantity) {
            if (quantity + totalMintedFO > mintableTotalSupplyFO) {
                revert NotEnoughSupply();
            }

            totalMintedFO += quantity;
            _mintRanked(Rank.FO, to, quantity);
        } else {
            revert InvalidFunds();
        }
    }

    function _mintRanked(
        Rank rank,
        address to,
        uint256 quantity
    ) internal {
        emit RankedMint(rank, to, _nextTokenId(), quantity);
        _mint(to, quantity);
    }

    /// PHASE 2

    /// Claim free-mint for users who own ranked tokens from phase 1.
    /// User can claim as many time as they want, however they cannot exceed the total claimable quantity,
    /// which is defined off-chain when phase 1 is finished, based on what & how many ranks each user owns.
    ///
    /// Can be claimed at any point during phase 2, until total supply runs out.
    function claimFromDraft(
        uint32 quantity,
        uint256 totalClaimableQuantity,
        bytes32[] calldata proof
    )
        external
        isPhase(Phase.Two)
        maxQuantityPerTxNotReached(quantity)
        totalSupplyNotReached(quantity)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, totalClaimableQuantity));
        if (!MerkleProof.verifyCalldata(proof, phase2DraftClaimsMerkle, leaf)) {
            revert InvalidProof();
        }

        if (_counters[msg.sender].phase2DraftClaim + quantity > totalClaimableQuantity) {
            revert MaxQuantityReached();
        }
        _counters[msg.sender].phase2DraftClaim += quantity;

        _mint(msg.sender, quantity);
    }

    /// Mint of phase 2 for allowlisted users.
    /// Price is cheaper than the public mint.
    /// Total minted quantity in allowlist cannot exceed `MaxMintPhase2Allowlist`.
    /// User can mint up to `maxMintPhase2Total` tokens in total (not including claims).
    ///
    /// Can be minted only during allowlist sale of phase 2.
    function mintPhase2Allowlist(uint32 quantity, bytes32[] calldata proof)
        external
        payable
        isPhase(Phase.Two)
        isSale(Sale.Allowlist)
        totalSupplyNotReached(quantity)
        withProperFunds(quantity, phase2AllowlistPrice)
    {
        if (
            !MerkleProof.verifyCalldata(
                proof,
                phase2AllowlistMerkle,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            revert InvalidProof();
        }

        CountTracker memory tracker = _counters[msg.sender];

        if (
            tracker.phase2Allowlist + quantity > MaxMintPhase2Allowlist ||
            (tracker.phase2Allowlist + tracker.phase2Public + quantity > maxMintPhase2Total)
        ) {
            revert MaxQuantityReached();
        }

        _counters[msg.sender].phase2Allowlist += quantity;

        _mint(msg.sender, quantity);
    }

    /// Public cross-mint of phase 2.
    /// Until total supply runs out.
    ///
    /// User can mint up to `maxMintPhase2Total` tokens in total (not including claims).
    ///
    /// Token is minted and transfered `to` account.
    /// Expected to be called by USDT API.
    ///
    /// Can be minted only during public sale of phase 2.
    function crossmintPhase2(address to, uint32 quantity)
        external
        payable
        isPhase(Phase.Two)
        isSale(Sale.Public)
        maxQuantityPerTxNotReached(quantity)
        totalSupplyNotReached(quantity)
        withProperFunds(quantity, phase2PublicPrice)
    {
        CountTracker memory tracker = _counters[to];

        if (tracker.phase2Allowlist + tracker.phase2Public + quantity > maxMintPhase2Total) {
            revert MaxQuantityReached();
        }

        _counters[to].phase2Public += quantity;

        _mint(to, quantity);
    }

    /// AIR DROP

    /// Airdrop 1 or more GMs to provided accounts
    /// `accounts` length must match `quantities` length
    /// @dev Owner should respect the `maxQuantityPerTx` limit, we don't enforce it as it's impractical and gas costly
    function airdropGM(address[] memory accounts, uint256[] memory quantities) external onlyOwner {
        if (accounts.length != quantities.length) {
            revert();
        }

        for (uint256 i = 0; i < accounts.length; ++i) {
            _mintRanked(Rank.GM, accounts[i], quantities[i]);
        }
    }

    /// Airdrop 1 Gold to each provided accounts
    /// @dev Limited to `maxQuantityPerTx`
    function airdropGold(address[] memory accounts)
        external
        onlyOwner
        maxQuantityPerTxNotReached(accounts.length)
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _mintRanked(Rank.Gold, accounts[i], 1);
        }
    }

    /// Mint and transfer `quantity` of golds to `vault`
    /// @dev Limited to `maxQuantityPerTx`
    function airdropGoldsToVault(address vault, uint256 quantity)
        external
        onlyOwner
        maxQuantityPerTxNotReached(quantity)
    {
        _mintRanked(Rank.Gold, vault, quantity);
    }

    /// GETTERS

    function getCountTracker(address account) external view returns (CountTracker memory) {
        return _counters[account];
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /// ADMIN

    function setStatus(Phase phase_, Sale sale_) external onlyOwner {
        phase = phase_;
        sale = sale_;
    }

    /// Reveal the phase 1 and provide the real URI of the IPFS folder
    /// @param revealed allowing to unreveal in case you revealed too soon by mistake
    /// @param uri pointing to the metadata folder hosted on IPFS. **Don't forget the trailing slash!**
    /// @param endTokenId the last token id minted in phase 1
    function setPhase1Reveal(
        bool revealed,
        string memory uri,
        uint16 endTokenId
    ) external onlyOwner {
        phase1Revealed = revealed;
        phase1RevealedBaseUri = uri;
        phase1EndTokenId = endTokenId;
    }

    /// @dev Allows to only update base URI when partial phase 1 data is revealed, without having to provide the same values for other params.
    function setPhase1RevealedUri(string memory uri) external onlyOwner {
        phase1RevealedBaseUri = uri;
    }

    /// Reveal the phase 2 and provide the real URI of the IPFS folder
    /// @param revealed allowing to unreveal in case you revealed too soon by mistake
    /// @param uri pointing to the metadata folder hosted on IPFS. **Don't forget the trailing slash!**
    function setPhase2Reveal(bool revealed, string memory uri) external onlyOwner {
        phase2Revealed = revealed;
        phase2RevealedBaseUri = uri;
    }

    function setMaxMintPhase2Total(uint16 total) external onlyOwner {
        maxMintPhase2Total = total;
    }

    function setMaxMintPerTx(uint16 value) external onlyOwner {
        maxMintPerTx = value;
    }

    function setPhase1ExternalClaimsMerkle(bytes32 root) external onlyOwner {
        phase1ExternalClaimsMerkle = root;
    }

    function setPhase1AllowlistMerkle(bytes32 root) external onlyOwner {
        phase1AllowlistMerkle = root;
    }

    function setPhase2DraftClaimsMerkle(bytes32 root) external onlyOwner {
        phase2DraftClaimsMerkle = root;
    }

    function setPhase2AllowlistMerkle(bytes32 root) external onlyOwner {
        phase2AllowlistMerkle = root;
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId, true);
    }

    function setPaused(bool paused_) external onlyOwner {
        paused = paused_;
    }

    function setContractUri(string memory uri) external onlyOwner {
        contractUri = uri;
    }

    function setUnrevealedUri(string memory uri) external onlyOwner {
        unrevealedUri = uri;
    }

    function setApprovedProxies(address[] memory proxies) external onlyOwner {
        approvedProxies = proxies;
    }

    function setMintableTotalSupplyGM(uint16 total) external onlyOwner {
        mintableTotalSupplyGM = total;
    }

    function setMintableTotalSupplyAGM(uint16 total) external onlyOwner {
        mintableTotalSupplyAGM = total;
    }

    function setMintableTotalSupplyFO(uint16 total) external onlyOwner {
        mintableTotalSupplyFO = total;
    }

    function setTotalSupplyLimit(uint16 total) external onlyOwner {
        totalSupplyLimit = total;
    }

    function setDraftPriceGM(uint256 price) external onlyOwner {
        draftPriceGM = price;
    }

    function setDraftPriceAGM(uint256 price) external onlyOwner {
        draftPriceAGM = price;
    }

    function setDraftPriceFO(uint256 price) external onlyOwner {
        draftPriceFO = price;
    }

    function setPhase2AllowlistPrice(uint256 price) external onlyOwner {
        phase2AllowlistPrice = price;
    }

    function setPhase2PublicPrice(uint256 price) external onlyOwner {
        phase2PublicPrice = price;
    }

    /// PAUSABLE

    /// @dev Override to handle the pause state. No using OZ Pausable because it adds event logging which is not needed.
    /// See {ERC721A-_beforeTokenTransfers}.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        if (paused) revert ContractPaused();
    }

    /// GASLESS PROXIES

    /// @dev Override to approve OpenSea and Rarible proxy contracts for gas-less trading
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        for (uint256 i = 0; i < approvedProxies.length; ++i) {
            ProxyRegistry proxyRegistry = ProxyRegistry(approvedProxies[i]);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

    /// OVERRIDES

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, Banker)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || Banker.supportsInterface(interfaceId);
    }

    /// MODIFIERS

    modifier isPhase(Phase phase_) {
        if (phase != phase_) {
            revert SaleIsNotOpen();
        }

        _;
    }

    modifier isSale(Sale sale_) {
        if (sale != sale_) {
            revert SaleIsNotOpen();
        }

        _;
    }

    modifier totalSupplyNotReached(uint256 quantity) {
        if (_totalMinted() + quantity > totalSupplyLimit) {
            revert NotEnoughSupply();
        }

        _;
    }

    modifier maxQuantityPerTxNotReached(uint256 quantity) {
        if (quantity > maxMintPerTx) {
            revert MaxQuantityPerTxReached();
        }

        _;
    }

    modifier withProperFunds(uint256 quantity, uint256 price) {
        if (msg.value != quantity * price) {
            revert InvalidFunds();
        }

        _;
    }
}