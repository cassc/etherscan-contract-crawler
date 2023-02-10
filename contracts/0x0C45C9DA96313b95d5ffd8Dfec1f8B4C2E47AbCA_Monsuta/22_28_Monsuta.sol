// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import {ERC721A, IERC721A, ERC721AQueryable} from "./ERC721AQueryable.sol";
import {IOmen} from "./interfaces/IOmen.sol";
import {IMonsutaRegistry} from "./interfaces/IMonsutaRegistry.sol";
import {NameUtils} from "./utils/NameUtils.sol";
import {Base64} from "./utils/Base64.sol";

/**
 * @title Monsuta contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Monsuta is
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    using SafeERC20 for IERC20;

    enum MonsutaState {
        DEFAULT,
        EVOLVED,
        SOUL
    }

    struct Trade {
        uint256 tradeId;
        uint256 openingTokenId;
        uint256 closingTokenId;
        uint256 expiryDate;
        address tradeOpener;
        address tradeCloser;
        bool active;
    }

    // Public variables
    uint256 public constant SALE_START_TIMESTAMP = 1676037600;

    // Time after which monsutas are randomized and allotted
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + 3 * 86400; // 3days

    uint256 public constant MINT_PRICE = 0.059 ether;
    uint256 public constant MAX_NFT_SUPPLY = 8888;

    uint256 public currentPhase; // current phase index 0: stopped 1: phase1, 2: phase2
    mapping(uint256 => bytes32) private _merkleRootsForPhase;
    mapping(uint256 => uint256) public wlPriceForPhase;
    mapping(address => mapping(uint256 => uint256)) public mintedForPhase;

    // Omen Rewards
    uint256 public constant INITIAL_ALLOTMENT = 500 * 1e18;
    uint256 public constant EVOLVED_MULTIPLIER = 3;

    uint256 public nameChangePrice = 500 * 1e18;
    uint256 public sacrificePrice = 250 * 1e18;
    uint256 public resurrectPrice = 750 * 1e18;

    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public devMinted;

    // Name
    mapping(uint256 => string) private tokenName;
    mapping(string => bool) private nameReserved;
    bool public nameChangeEnabled = false;

    // $Omen token address
    address private omenAddress;

    // MonsutaRegistry contract address
    IMonsutaRegistry public registry;

    // Omen Rewards
    uint256 public constant emissionStart = SALE_START_TIMESTAMP;
    uint256 public constant emissionEnd = 1753876800; // July 30th 2025 12:00 GMT;
    uint256 public constant emissionPerDay = 25 * 1e18;

    mapping(uint256 => uint256) private _lastClaim;

    // Trade
    Trade[] public trades;

    // Metadata Variables
    mapping(uint256 => MonsutaState) public tokenState;

    string public defaultImageIPFSURIPrefix = "";
    string public evolvedImageIPFSURIPrefix = "";
    string public soulImageIPFSURIPrefix = "";
    string public placeholderImageIPFSURI =
        "ipfs://QmezsA5i9ACnkpkbod5zkBBqJChRucFGigwEPWiqQScfF2";

    // Events
    event NameChange(uint256 indexed tokenId, string newName);
    event Sacrificed(
        uint256 indexed toEvolveId,
        uint256 indexed toSoulId,
        address caller
    );
    event Resurrect(
        uint256 indexed evolvedTokenId,
        uint256 indexed soulTokenId,
        address caller
    );

    event TradeOpened(
        uint256 indexed tradeId,
        address indexed tradeOpener,
        uint256 openingTokenId,
        uint256 closingTokenId,
        uint256 expiryDate
    );
    event TradeCancelled(uint256 indexed tradeId, address indexed tradeCloser);
    event TradeExecuted(
        uint256 indexed tradeId,
        address indexed tradeOpener,
        address indexed tradeCloser
    );

    // Modifiers
    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "!owner of token id");
        _;
    }

    modifier onlyAfterReveal() {
        require(startingIndex > 0, "only after reveal");
        _;
    }

    /**
     * @dev Initializes the contract
     */
    constructor(bytes32[3] memory _merkleRoots, uint256[3] memory _prices)
        ERC721A("Monsuta", "Monsuta")
    {
        uint64 numPhases = uint64(_merkleRoots.length);
        for (uint256 i = 0; i < numPhases; ) {
            _merkleRootsForPhase[i + 1] = _merkleRoots[i];
            wlPriceForPhase[i + 1] = _prices[i];

            unchecked {
                ++i;
            }
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns name of the NFT at tokenId.
     */
    function tokenNameByIndex(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return tokenName[tokenId];
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function isNameReserved(string memory nameString)
        public
        view
        returns (bool)
    {
        return nameReserved[NameUtils.toLower(nameString)];
    }

    /**
     * @dev Mints Monsuta!
     */
    function mint(uint256 numberOfNfts, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
    {
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(currentPhase > 0, "Sale is paused");
        require(block.timestamp > SALE_START_TIMESTAMP, "not started");
        require(numberOfNfts > 0 && numberOfNfts < 6, "invalid numberOfNfts");
        require(
            totalSupply() + numberOfNfts <= MAX_NFT_SUPPLY,
            "Exceeds max supply"
        );

        (uint256 whitelistMint, uint256 price) = checkWhiteListMint(
            msg.sender,
            merkleProof
        );
        if (whitelistMint > 0) {
            mintedForPhase[msg.sender][currentPhase] += whitelistMint;
        }

        require(
            MINT_PRICE * (numberOfNfts - whitelistMint) + price == msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, numberOfNfts, "");

        // Source of randomness.
        // Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        if (
            startingIndexBlock == 0 &&
            (totalSupply() == MAX_NFT_SUPPLY ||
                block.timestamp >= REVEAL_TIMESTAMP)
        ) {
            startingIndexBlock = block.number;
        }
    }

    function checkWhiteListMint(address account, bytes32[] calldata proof)
        public
        view
        returns (uint256, uint256)
    {
        bytes32 merkleRoot = _merkleRootsForPhase[currentPhase];
        if (merkleRoot != bytes32(0) && proof.length > 0) {
            if (mintedForPhase[account][currentPhase] < 1) {
                if (
                    MerkleProof.verify(
                        proof,
                        merkleRoot,
                        keccak256(abi.encodePacked(account))
                    )
                ) {
                    return (1, wlPriceForPhase[currentPhase]);
                }
            }
        }

        return (0, 0);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory namePostfix = '"';
        if (bytes(tokenName[tokenId]).length != 0) {
            namePostfix = string(abi.encodePacked(tokenName[tokenId], '"'));
        } else {
            namePostfix = string(
                abi.encodePacked("Monsuta #", tokenId.toString(), '"')
            );
        }

        if (startingIndex == 0) {
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '{"name": "',
                                namePostfix,
                                ', "description": "The Monsuta Collection", "image": "',
                                placeholderImageIPFSURI,
                                '" }'
                            )
                        )
                    )
                );
        }

        uint256 tokenIdToMetadataIndex = (tokenId + startingIndex) %
            MAX_NFT_SUPPLY;

        // Block scoping to avoid stack too deep error
        bytes memory uriPartsOfMetadata;
        {
            uriPartsOfMetadata = abi.encodePacked(
                ', "image": "',
                string(
                    abi.encodePacked(
                        baseURI(tokenId),
                        tokenIdToMetadataIndex.toString(),
                        ".png"
                    )
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name": "',
                            namePostfix,
                            ', "description": "The Monsuta Collection", ',
                            registry.getEncodedTraitsOfMonsutaId(
                                tokenId,
                                uint256(tokenState[tokenId])
                            ),
                            uriPartsOfMetadata,
                            '" }'
                        )
                    )
                )
            );
    }

    function baseURI(uint256 tokenId) public view returns (string memory) {
        MonsutaState _state = tokenState[tokenId];
        if (_state == MonsutaState.DEFAULT) {
            return defaultImageIPFSURIPrefix;
        } else if (_state == MonsutaState.EVOLVED) {
            return evolvedImageIPFSURIPrefix;
        } else {
            return soulImageIPFSURIPrefix;
        }
    }

    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() external {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock > 0, "Starting index block must be set");

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex =
                uint256(blockhash(block.number - 1)) %
                MAX_NFT_SUPPLY;
        } else {
            startingIndex =
                uint256(blockhash(startingIndexBlock)) %
                MAX_NFT_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = 1;
        }
    }

    /**
     * @dev Changes the name for Monsuta tokenId
     */
    function changeName(uint256 tokenId, string memory newName)
        external
        onlyTokenOwner(tokenId)
    {
        require(nameChangeEnabled, "disabled!");
        require(NameUtils.validateName(newName) == true, "not valid new name");
        require(
            sha256(bytes(newName)) != sha256(bytes(tokenName[tokenId])),
            "same as the current one"
        );
        require(isNameReserved(newName) == false, "already reserved");

        // If already named, dereserve old name
        if (bytes(tokenName[tokenId]).length > 0) {
            toggleReserveName(tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        tokenName[tokenId] = newName;

        _transferOmenAndBurn(msg.sender, nameChangePrice);

        emit NameChange(tokenId, newName);
    }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        nameReserved[NameUtils.toLower(str)] = isReserve;
    }

    /**
     * @dev sacrifice. 1 nft from default to evolved, 1 nft from default to soul
     */
    function sacrifice(uint256 toEvolveId, uint256 toSoulId)
        external
        onlyTokenOwner(toEvolveId)
        onlyTokenOwner(toSoulId)
        onlyAfterReveal
    {
        require(
            tokenState[toEvolveId] == MonsutaState.DEFAULT,
            "!evolving item default"
        );
        require(
            tokenState[toSoulId] == MonsutaState.DEFAULT,
            "!soul item default"
        );

        tokenState[toEvolveId] = MonsutaState.EVOLVED;
        tokenState[toSoulId] = MonsutaState.SOUL;

        _transferOmenAndBurn(msg.sender, sacrificePrice);

        updateReward(toEvolveId);
        updateReward(toSoulId);

        emit Sacrificed(toEvolveId, toSoulId, msg.sender);
    }

    /**
     * @dev requires: evolved Monsuta NFT, soul Monsuta NFT and $FAVOR
     * For the evolved Monsuta NFT: retract() is activated
     * For the soul Monsuta NFT: descent() is activated
     * $FAVOR is burned
     */
    function resurrect(uint256 evolvedTokenId, uint256 soulTokenId)
        external
        onlyTokenOwner(evolvedTokenId)
        onlyTokenOwner(soulTokenId)
    {
        require(tokenState[soulTokenId] == MonsutaState.SOUL, "!soul");
        require(tokenState[evolvedTokenId] == MonsutaState.EVOLVED, "!evolved");

        tokenState[evolvedTokenId] = MonsutaState.DEFAULT;
        tokenState[soulTokenId] = MonsutaState.DEFAULT;

        updateReward(soulTokenId);
        updateReward(evolvedTokenId);

        _transferOmenAndBurn(msg.sender, resurrectPrice);

        emit Resurrect(evolvedTokenId, soulTokenId, msg.sender);
    }

    function _transferOmenAndBurn(address from, uint256 amount) internal {
        SafeERC20.safeTransferFrom(
            IERC20(omenAddress),
            from,
            address(this),
            amount
        );
        IOmen(omenAddress).burn(amount);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        for (uint256 i; i < quantity; ) {
            uint256 tokenId = startTokenId + i;

            if (from != address(0)) {
                updateReward(tokenId);
                require(tokenState[tokenId] != MonsutaState.SOUL, "soul token");
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev When accumulated FAVORs have last been claimed for a Monsuta tokenId
     */
    function getLastClaim(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "!exist");

        uint256 lastClaimed = uint256(_lastClaim[tokenId]) != 0
            ? uint256(_lastClaim[tokenId])
            : emissionStart;
        return lastClaimed;
    }

    /**
     * @dev Accumulated FAVOR tokens for a Monsuta token id
     */
    function getAccumulated(uint256 tokenId) public view returns (uint256) {
        if (block.timestamp <= emissionStart) return 0;

        uint256 lastClaimed = getLastClaim(tokenId);

        // Sanity check if last claim was on or after emission end
        if (lastClaimed >= emissionEnd) return 0;

        uint256 accumulationPeriod = block.timestamp < emissionEnd
            ? block.timestamp
            : emissionEnd; // Getting the min value of both

        uint256 totalAccumulated = ((accumulationPeriod - lastClaimed) *
            emissionPerDay *
            multiplierFromState(tokenId)) / 86400;

        // If claim hasn't been done before for the index, add initial allotment
        if (lastClaimed == emissionStart) {
            totalAccumulated += INITIAL_ALLOTMENT;
        }

        return totalAccumulated;
    }

    /**
     * @dev Accumulated all FAVOR tokens for all Monsuta balance
     */
    function getAccumulatedAll(address account) public view returns (uint256) {
        if (block.timestamp <= emissionStart) return 0;

        uint256 monsutaBalance = balanceOf(account);
        if (monsutaBalance == 0) return 0;

        uint256 totalAccumulated = 0;

        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != monsutaBalance;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == account) {
                    tokenIdsIdx++;
                    uint256 claimQty = getAccumulated(i);
                    if (claimQty > 0) {
                        totalAccumulated = totalAccumulated + claimQty;
                    }
                }
            }
        }

        return totalAccumulated;
    }

    /**
     * @dev Claim mints Omens for all my Monsuta nft balances
     */
    function claimAll() external returns (uint256) {
        uint256 monsutaBalance = balanceOf(msg.sender);
        require(monsutaBalance > 0, "zero balance");

        require(
            block.timestamp > emissionStart,
            "Emission has not started yet"
        );

        uint256 totalClaimQty = 0;

        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != monsutaBalance;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == msg.sender) {
                    tokenIdsIdx++;
                    uint256 claimQty = getAccumulated(i);
                    if (claimQty > 0) {
                        totalClaimQty += claimQty;
                        _lastClaim[i] = block.timestamp;
                    }
                }
            }
        }

        require(totalClaimQty > 0, "No accumulated Omen");
        IOmen(omenAddress).mint(msg.sender, totalClaimQty);
        return totalClaimQty;
    }

    /**
     * @dev Hook for state change of monsuta nft
     * can be called by only Monsuta Token Contract
     */

    function updateReward(uint256 tokenId) internal {
        uint256 claimQty = getAccumulated(tokenId);
        if (claimQty > 0) {
            _lastClaim[tokenId] = block.timestamp;

            IOmen(omenAddress).mint(ownerOf(tokenId), claimQty);
        }
    }

    function multiplierFromState(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        MonsutaState state = tokenState[tokenId];
        if (state == MonsutaState.DEFAULT) {
            return 1;
        } else if (state == MonsutaState.EVOLVED) {
            return EVOLVED_MULTIPLIER;
        } else {
            return 0;
        }
    }

    function getTradeCount() public view returns (uint256) {
        return trades.length;
    }

    function isTradeExecutable(uint256 tradeId) public view returns (bool) {
        Trade memory trade = trades[tradeId];
        if (trade.expiryDate < block.timestamp) {
            return false;
        }
        if (!trade.active) {
            return false;
        }

        return true;
    }

    /**
     * @dev Open new trade
     */
    function openNewTrade(
        uint256 openingTokenId,
        uint256 closingTokenId,
        uint256 expiryDate
    ) external onlyTokenOwner(openingTokenId) {
        require(expiryDate > block.timestamp, "expiryDate <= block.timestamp");
        require(tokenState[openingTokenId] != MonsutaState.SOUL, "soul item");
        uint256 tradeId = trades.length;
        trades.push(
            Trade(
                tradeId,
                openingTokenId,
                closingTokenId,
                expiryDate,
                msg.sender,
                address(0),
                true
            )
        );

        emit TradeOpened(
            tradeId,
            msg.sender,
            openingTokenId,
            closingTokenId,
            expiryDate
        );
    }

    /**
     * @dev Cancel trade
     */
    function cancelTrade(uint256 tradeId) external {
        Trade memory trade = trades[tradeId];
        require(trade.tradeOpener == msg.sender, "!opener");
        require(
            trade.tradeCloser == address(0),
            "tradeCloser can't already be non-zero address"
        );
        require(
            trade.expiryDate > block.timestamp,
            "trade.expiryDate <= block.timestamp"
        );
        trades[tradeId] = Trade(
            trade.tradeId,
            trade.openingTokenId,
            trade.closingTokenId,
            trade.expiryDate,
            trade.tradeOpener,
            msg.sender,
            false
        );

        emit TradeCancelled(tradeId, msg.sender);
    }

    /**
     * @dev Execute Trade
     */
    function executeTrade(uint256 tradeId) external {
        Trade memory trade = trades[tradeId];
        require(trade.active, "!active trade");
        require(trade.expiryDate > block.timestamp, "expired");
        require(
            tokenState[trade.closingTokenId] != MonsutaState.SOUL,
            "soul item"
        );
        require(
            ownerOf(trade.closingTokenId) == msg.sender,
            "!owner of closing token"
        );

        _transfer(trade.tradeOpener, msg.sender, trade.openingTokenId);
        _transfer(msg.sender, trade.tradeOpener, trade.closingTokenId);

        trades[tradeId] = Trade(
            trade.tradeId,
            trade.openingTokenId,
            trade.closingTokenId,
            trade.expiryDate,
            trade.tradeOpener,
            msg.sender,
            false
        );

        emit TradeExecuted(trade.tradeId, trade.tradeOpener, msg.sender);
    }

    /// Admin Funcs

    /**
     * @dev Set Omen Contract address (Callable by owner)
     */
    function setOmen(address _omen) external onlyOwner {
        require(_omen != address(0), "!zero address");

        omenAddress = _omen;
    }

    /**
     * @dev Set MonsutaRegistry Contract address (Callable by owner)
     */
    function setRegistry(address _registry) external onlyOwner {
        require(_registry != address(0), "!zero address");

        registry = IMonsutaRegistry(_registry);
    }

    /**
     * @dev Set current Phase (Callable by owner)
     */
    function setCurrentPhase(uint256 newPhase) external onlyOwner {
        require(currentPhase != newPhase, "already");

        currentPhase = newPhase;
    }

    function changePhaseSettng(
        uint256 phase,
        bytes32 _merkleRoot,
        uint256 price
    ) external onlyOwner {
        _merkleRootsForPhase[phase] = _merkleRoot;
        wlPriceForPhase[phase] = price;
    }

    /**
     * @dev Metadata will be frozen once ownership of the contract is renounced
     */
    function changeURIs(
        string memory defaultImageURI,
        string memory evolvedImageURI,
        string memory soulImageURI,
        string memory placeholderURI
    ) external onlyOwner {
        defaultImageIPFSURIPrefix = defaultImageURI;
        evolvedImageIPFSURIPrefix = evolvedImageURI;
        soulImageIPFSURIPrefix = soulImageURI;
        placeholderImageIPFSURI = placeholderURI;
    }

    /**
     * @dev Set Name change price (Callable by owner)
     */
    function setNameChangePrice(uint256 _price) external onlyOwner {
        nameChangePrice = _price;
    }

    function toggleNameChangeEnabled() external onlyOwner {
        nameChangeEnabled = !nameChangeEnabled;
    }

    /**
     * @dev Set Sacrifice price (Callable by owner)
     */
    function setSacrificePrice(uint256 _price) external onlyOwner {
        sacrificePrice = _price;
    }

    /**
     * @dev Set Resurrection price (Callable by owner)
     */
    function setResurrectPrice(uint256 _price) external onlyOwner {
        resurrectPrice = _price;
    }

    function devMint() external onlyOwner {
        require(devMinted < 1, "minted all");

        devMinted = 1;
        _safeMint(msg.sender, 1, "");
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        uint256 dev = (balance * 15) / 100;
        Address.sendValue(
            payable(0xfed505c80b72cDca5f72292D4bF1D6194cF23669),
            dev
        );
        Address.sendValue(payable(msg.sender), balance - dev);
    }
}