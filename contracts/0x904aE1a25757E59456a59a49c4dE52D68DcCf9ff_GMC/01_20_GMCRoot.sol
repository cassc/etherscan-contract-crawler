//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {LibCrumbMap} from "../lib/LibCrumbMap.sol";
import {FxERC721MRoot} from "ERC721M/extensions/FxERC721MRoot.sol";
import {ERC20UDS as ERC20} from "UDS/tokens/ERC20UDS.sol";

import "solady/utils/ECDSA.sol";
import "solady/utils/LibString.sol";

error ExceedsLimit();
error TransferFailed();
error TimelockActive();
error IncorrectValue();
error MaxSupplyLocked();
error InvalidSignature();
error InvalidPriceUnits();
error WhitelistNotActive();
error PublicSaleNotActive();
error ContractCallNotAllowed();

/// @title Gangsta Mice City Root
/// @author phaze (https://github.com/0xPhaze)
contract GMC is OwnableUDS, FxERC721MRoot {
    using ECDSA for bytes32;
    using LibString for uint256;
    using LibCrumbMap for LibCrumbMap.CrumbMap;

    event SaleStateUpdate();
    event FirstLegendaryRaffleEntered(address user);
    event SecondLegendaryRaffleEntered(address user);

    uint16 public constant MAX_PER_WALLET = 20;
    uint256 public constant PURCHASE_LIMIT = 5;
    uint256 public constant BRIDGE_RAFFLE_LOCK_DURATION = 24 hours;
    uint256 private constant PRICE_UNIT = 0.001 ether;
    uint256 private constant GENESIS_CLAIM = 555;
    uint256 private immutable DEPLOY_TIMESTAMP;

    bool public maxSupplyLocked;
    uint16 public supply;
    uint16 public maxSupply;
    uint32 public mintStart;
    uint8 private publicPriceUnits;
    uint8 private whitelistPriceUnits;
    address private signer;

    string private baseURI;
    string private postFixURI = ".json";
    string private unrevealedURI = "ipfs://QmTv9VoXgkZxFcomTW3kN6CRryUPMfgeUkVekFszcd79gK/";

    LibCrumbMap.CrumbMap gangs;

    constructor(address checkpointManager, address fxRoot)
        FxERC721MRoot("Gangsta Mice City", "GMC", checkpointManager, fxRoot)
    {
        __Ownable_init();

        maxSupply = 6666;
        signer = msg.sender;
        DEPLOY_TIMESTAMP = block.timestamp;

        publicPriceUnits = toPriceUnits(0.049 ether);
        whitelistPriceUnits = toPriceUnits(0.039 ether);
    }

    /* ------------- view ------------- */

    function totalSupply() public view override returns (uint256) {
        return supply;
    }

    function publicPrice() public view returns (uint256) {
        return toPrice(publicPriceUnits);
    }

    function whitelistPrice() public view returns (uint256) {
        return toPrice(whitelistPriceUnits);
    }

    function gangOf(uint256 id) public view returns (uint256) {
        return gangs.get(id);
    }

    /* ------------- external ------------- */

    function mint(uint256 quantity, bool lock)
        external
        payable
        onlyEOA
        requireMintableSupply(quantity)
        requireMintableByUser(quantity, MAX_PER_WALLET)
    {
        unchecked {
            if (msg.value != publicPrice() * quantity) revert IncorrectValue();
            if (block.timestamp < mintStart + 2 hours || mintStart == 0) revert PublicSaleNotActive();

            mintWithPerks(msg.sender, quantity, lock);
        }
    }

    function whitelistMint(
        uint256 quantity,
        bool lock,
        uint256 limit,
        bytes calldata signature
    ) external payable onlyEOA requireMintableSupply(quantity) requireMintableByUser(quantity, limit) {
        unchecked {
            if (!validSignature(signature, limit)) revert InvalidSignature();
            if (mintStart + 2 hours < block.timestamp) revert WhitelistNotActive();
            if (msg.value != whitelistPrice() * quantity) revert IncorrectValue();

            mintWithPerks(msg.sender, quantity, lock);
        }
    }

    function lockAndTransmit(address from, uint256[] calldata tokenIds) external {
        unchecked {
            if (tokenIds.length > 20) revert ExceedsLimit();
            // don't repeat an unnecessary sload if we can avoid it
            if (
                tokenIds.length != 0 &&
                block.timestamp < DEPLOY_TIMESTAMP + 1 weeks &&
                block.timestamp < mintStart + 2 hours
            ) {
                emit SecondLegendaryRaffleEntered(from);
            }

            _lockAndTransmit(from, tokenIds);
        }
    }

    function unlockAndTransmit(address from, uint256[] calldata tokenIds) external {
        if (tokenIds.length > 20) revert ExceedsLimit();
        if (block.timestamp < DEPLOY_TIMESTAMP + 1 weeks && block.timestamp < mintStart + BRIDGE_RAFFLE_LOCK_DURATION) {
            revert TimelockActive();
        }

        _unlockAndTransmit(from, tokenIds);
    }

    /* ------------- private ------------- */

    function validSignature(bytes calldata signature, uint256 limit) private view returns (bool) {
        bytes32 hash = keccak256(abi.encode(address(this), msg.sender, limit));
        address recovered = hash.toEthSignedMessageHash().recover(signature);

        return recovered != address(0) && recovered == signer;
    }

    function toPrice(uint16 priceUnits) private pure returns (uint256) {
        unchecked {
            return uint256(priceUnits) * PRICE_UNIT;
        }
    }

    function toPriceUnits(uint256 price) private pure returns (uint8) {
        unchecked {
            uint256 units;

            if (price % PRICE_UNIT != 0) revert InvalidPriceUnits();
            if ((units = price / PRICE_UNIT) > type(uint8).max) revert InvalidPriceUnits();

            return uint8(units);
        }
    }

    function mintWithPerks(
        address to,
        uint256 quantity,
        bool lock
    ) private {
        unchecked {
            if (quantity > 2) {
                emit FirstLegendaryRaffleEntered(to);

                if (supply < 500 + GENESIS_CLAIM) ++quantity;
            }

            if (lock && block.timestamp < mintStart + 2 hours) emit SecondLegendaryRaffleEntered(to);

            if (lock) _mintLockedAndTransmit(to, quantity);
            else _mint(to, quantity);
        }
    }

    /* ------------- owner ------------- */

    function pause() external onlyOwner {
        mintStart = 0;
    }

    function lockMaxSupply() external onlyOwner {
        maxSupplyLocked = true;
    }

    function setSigner(address addr) external onlyOwner {
        signer = addr;
    }

    function setMaxSupply(uint16 value) external onlyOwner {
        if (maxSupplyLocked) revert MaxSupplyLocked();

        maxSupply = value;
    }

    function setMintStart(uint32 time) external onlyOwner {
        mintStart = time;
    }

    function setPublicPrice(uint256 value) external onlyOwner {
        publicPriceUnits = toPriceUnits(value);
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function setPostFixURI(string calldata postFix) external onlyOwner {
        postFixURI = postFix;
    }

    function setWhitelistPrice(uint256 value) external onlyOwner {
        whitelistPriceUnits = toPriceUnits(value);
    }

    function setUnrevealedURI(string calldata uri) external onlyOwner {
        unrevealedURI = uri;
    }

    function setGangs(uint256[] calldata chunkIndices, uint256[] calldata chunks) external onlyOwner {
        for (uint256 i; i < chunkIndices.length; ++i) gangs.set32BytesChunk(chunkIndices[i], chunks[i]);
    }

    function airdrop(
        address[] calldata users,
        uint256 quantity,
        bool locked
    ) external onlyOwner requireMintableSupply(quantity * users.length) {
        if (locked) for (uint256 i; i < users.length; ++i) _mintLockedAndTransmit(users[i], quantity);
        else for (uint256 i; i < users.length; ++i) _mint(users[i], quantity);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");

        if (!success) revert TransferFailed();
    }

    function recoverToken(ERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));

        token.transfer(msg.sender, balance);
    }

    /* ------------- override ------------- */

    function _authorizeTunnelController() internal override onlyOwner {}

    function _increaseTotalSupply(uint256 amount) internal override {
        supply += uint16(amount);
    }

    /* ------------- modifier ------------- */

    modifier onlyEOA() {
        if (tx.origin != msg.sender) revert ContractCallNotAllowed();
        _;
    }

    modifier requireMintableByUser(uint256 quantity, uint256 limit) {
        unchecked {
            if (quantity > PURCHASE_LIMIT) revert ExceedsLimit();
            if (quantity + numMinted(msg.sender) > limit) revert ExceedsLimit();
        }
        _;
    }

    modifier requireMintableSupply(uint256 quantity) {
        unchecked {
            if (quantity + supply > maxSupply) revert ExceedsLimit();
        }
        _;
    }

    /* ------------- ERC721 ------------- */

    function tokenURI(uint256 id) public view override returns (string memory) {
        return 
            bytes(baseURI).length == 0 
              ? unrevealedURI 
              : string.concat(baseURI, id.toString(), postFixURI); // prettier-ignore
    }
}