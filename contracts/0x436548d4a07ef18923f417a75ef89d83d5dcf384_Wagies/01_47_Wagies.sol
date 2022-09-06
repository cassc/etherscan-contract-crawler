// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/interfaces/IERC721AUpgradeable.sol";
import { ERC721AUpgradeable } from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import { ERC721AQueryableUpgradeable } from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC2981Upgradeable } from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import { TruflationIndicator } from "./TruflationIndicator.sol";
import { ETHPriceIndicator } from "./ETHPriceIndicator.sol";

contract Wagies is ERC721AUpgradeable, ERC721AQueryableUpgradeable, OwnableUpgradeable, ERC2981Upgradeable, UUPSUpgradeable {
    using StringsUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    /* Events */

    event TruflationIndicatorEnable(bool resetMints, uint256 difference);
    event ETHPriceIndicatorEnable(bool resetMints, uint256 difference);

    /* Errors */

    error OverMaxMintsPerTx();
    error OverMaxMintsPerPeriod();
    error NotEnoughMints();
    error OnlyEOA();
    error Paused();
    error NotEnoughEthSent();
    error NoBurningAllowed();
    error MintingPeriodIsOver();
    error InvalidSignature();

    /* Constants */

    uint256 constant MAX_MINTS_PER_PERIOD = 3;
    uint256 constant MAX_MINTS_PER_TX = 3;
    uint256 constant MAX_ID = 5500;

    uint256 constant MINTS_PER_PERIOD = 50;
    uint56 constant PERIOD_LENGTH = 1 days;
    uint256 constant PERIOD_RESET_TIME = 6 hours;

    uint256 constant BASE_COST = 0.0420 ether;
    uint256 constant STEP_COST = 0.003 ether;
    uint256 constant STEP = 500;

    address constant SIGNER = 0x084C03d1Abb45b34e842762995fC8bA7D8489436;

    /* Storage */

    // Packs the variables into a single slot
    struct MintSettings {
        uint136 _maxMintId;
        uint56 _periodStart;
        uint56 _periodEnd;
        bool _paused;
    }

    bool _burningEnabled;

    MintSettings _mintSettings;

    address _truflationIndicator;
    address _ethPriceIndicator;

    string _baseUriPrefix;
    string _baseUriSuffix;
    string _contractUri;

    mapping(address => bool) _isManualEnabler;

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializerERC721A initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ERC721A_init("WAGIES", "WAGIES");
        __ERC2981_init();
        __ERC721AQueryable_init();

        _baseUriPrefix = "https://storage.googleapis.com/storage/v1/b/wagies/o/metadata%2F";
        _baseUriSuffix = ".json?alt=media";

        _contractUri = "https://storage.googleapis.com/storage/v1/b/wagies/o/contract.json?alt=media";
    }

    /* Modifiers */

    modifier onlyEOA() {
        if (msg.sender != tx.origin) revert OnlyEOA();
        _;
    }

    modifier mintChecks(uint8 amount) {
        if (_mintSettings._paused) revert Paused();
        if (amount > MAX_MINTS_PER_TX) revert OverMaxMintsPerTx();
        if (block.timestamp > _mintSettings._periodEnd) revert MintingPeriodIsOver();

        // Revert if the remaining mints in the current period are less than the amount requested
        uint256 totalMinted = _totalMinted();
        if (_remainingMints(totalMinted) < amount) revert NotEnoughMints();

        // Revert if the ether sent is less than the price
        uint256 price = _price(amount, totalMinted);
        if (msg.value < price) revert NotEnoughEthSent();

        _;
    }

    modifier onlyIndicator(address indicator) {
        if (msg.sender != indicator) revert();
        _;
    }

    /* Non-view functions */

    function mint(uint8 amount, uint8 v, bytes32 r, bytes32 s) external payable onlyEOA mintChecks(amount) {
        // Verify the signature
        _verifySignature(msg.sender, v, r, s);

        // Spend the mints for this period
        _spendMints(msg.sender, amount);

        // Mint the token
        _mint(msg.sender, amount);
    }

    function burn(uint256[] calldata ids) external onlyEOA {
        if (_burningEnabled == false) revert NoBurningAllowed();

        unchecked {
            for (uint256 i = 0; i < ids.length; i++) {
                _burn(ids[i], true);
            }
        }
    }

    /* Automatic indicators */

    function truflationIndicatorEnable(uint256 difference) external onlyIndicator(_truflationIndicator) {
        bool resetMints = (block.timestamp + PERIOD_RESET_TIME) >= _mintSettings._periodEnd;

        _enableMintForAmount(MINTS_PER_PERIOD, PERIOD_LENGTH, false, resetMints);
        emit TruflationIndicatorEnable(resetMints, difference);
    }

    function ethPriceIndicatorEnable(uint256 difference) external onlyIndicator(_ethPriceIndicator) {
        bool resetMints = (block.timestamp + PERIOD_RESET_TIME) >= _mintSettings._periodEnd;

        _enableMintForAmount(MINTS_PER_PERIOD, PERIOD_LENGTH, false, resetMints);
        emit ETHPriceIndicatorEnable(resetMints, difference);
    }

    /* View functions */

    function getPrice(uint256 amount) external view returns (uint256) {
        uint256 totalMinted = _totalMinted();
        if (_remainingMints(totalMinted) < amount) revert NotEnoughMints();

        return _price(amount, totalMinted);
    }

    function remainingMints() external view returns (uint256) {
        return _remainingMints(_totalMinted());
    }

    function remainingMints(address user) external view returns (uint256) {
        if (block.timestamp > _mintSettings._periodEnd) return 0;

        // Aux: [uint56 userPeriodStart, uint8 mintedAmount]
        uint64 userAux = _getAux(user);
        uint56 userPeriodStart = uint56(userAux >> 8);
        uint8 userAmountMinted = uint8(userAux);

        if (userPeriodStart != _mintSettings._periodStart) {
            userAmountMinted = 0;
        }

        return _min(MAX_MINTS_PER_PERIOD - userAmountMinted, _remainingMints(_totalMinted()));
    }

    function isPaused() external view returns (bool) {
        return _mintSettings._paused;
    }

    function isBurningEnabled() external view returns (bool) {
        return _burningEnabled;
    }

    function amountMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function tokenURI(uint256 id) public view override(ERC721AUpgradeable, IERC721AUpgradeable) returns(string memory) {
        return string(abi.encodePacked(_baseUriPrefix, id.toString(), _baseUriSuffix));
    }

    function contractURI() external view returns(string memory) {
        return _contractUri;
    }

    /* onlyOwner functions */

    function setIndicators(address truflationIndicator, address ethPriceIndicator) external onlyOwner {
        _truflationIndicator = truflationIndicator;
        _ethPriceIndicator = ethPriceIndicator;
    }

    function setEnabler(address[] calldata enablers, bool[] calldata isEnabler) external onlyOwner {
        if(enablers.length != isEnabler.length) revert();
        for(uint i = 0; i < enablers.length; i++ ) {
            _isManualEnabler[enablers[i]] = isEnabler[i];
        }
    }

    function togglePaused() external onlyOwner {
        _mintSettings._paused = !_mintSettings._paused;
    }

    function toggleBurning() external onlyOwner {
        _burningEnabled = !_burningEnabled;
    }

    function setMintManual(uint256 amount, uint56 time, bool allowLowering, bool resetPeriodStart) external {
        if((_isManualEnabler[msg.sender] == false) && (msg.sender != owner())) revert();
        _enableMintForAmount(amount, time, allowLowering, resetPeriodStart);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumberator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumberator);
    }

    function setBaseURI(string calldata prefix, string calldata suffix) external onlyOwner {
        _baseUriPrefix = prefix;
        _baseUriSuffix = suffix;
    }

    function setContractURI(string calldata contractUri) external onlyOwner {
        _contractUri = contractUri;
    }

    function withdraw(address to) external onlyOwner {
        (bool success, ) = to.call{ value: address(this).balance }("");
        if (success == false) revert();
    }

    /* Internal functions */

    function _verifySignature(address user, uint8 v, bytes32 r, bytes32 s) internal pure {
        if(keccak256(abi.encode(user)).toEthSignedMessageHash().recover(v, r, s) != SIGNER) revert InvalidSignature();
    }

    function _enableMintForAmount(uint256 amount, uint56 time, bool allowLowering, bool resetPeriodStart) internal {
        if (resetPeriodStart) {
            _mintSettings._periodStart = uint56(block.timestamp);
        }
        _mintSettings._periodEnd = uint56(block.timestamp) + time;

        uint256 newMaxMintId = _min(_totalMinted() + amount, MAX_ID);

        if (allowLowering || newMaxMintId > _mintSettings._maxMintId) {
            // Casting is safe due to the `_min` above, assuming MAX_ID <= type(uint136).max
            _mintSettings._maxMintId = uint136(newMaxMintId);
        }
    }

    function _spendMints(address user, uint256 amount) internal {
        // Aux: [uint56 userPeriodStart, uint8 mintedAmount]
        uint64 userAux = _getAux(user);
        uint56 userPeriodStart = uint56(userAux >> 8);
        uint8 userAmountMinted = uint8(userAux);

        if (userPeriodStart == _mintSettings._periodStart) {
            userAmountMinted += uint8(amount);
        } else {
            userPeriodStart = _mintSettings._periodStart;
            userAmountMinted = uint8(amount);
        }

        // If the mint amount is over the maximum, revert
        if (userAmountMinted > MAX_MINTS_PER_PERIOD) {
            revert OverMaxMintsPerPeriod();
        }

        // Write the new aux to state
        _setAux(user, (uint64(userPeriodStart) << 8) + uint64(userAmountMinted));
    }

    function _remainingMints(uint256 totalMinted) internal view returns (uint256) {
        if (block.timestamp > _mintSettings._periodEnd) return 0;

        unchecked {
            return _mintSettings._maxMintId - totalMinted;
        }
    }

    /// @dev This function does *not* check for max supply, it is assumed that `_totalMinted + amount <= MAX_ID`
    function _price(uint256 amount, uint256 totalMinted) internal pure returns (uint256 price) {
        unchecked {
            for (uint256 i = totalMinted; i < totalMinted + amount; i++) {
                if (i > STEP - 1) {
                    price += BASE_COST + (((i - STEP) / STEP) * STEP_COST);
                }
            }
        }
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @dev Used for UUPS upgradability, if removed upgradability is no longer possible for the proxy
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable, ERC2981Upgradeable) returns (bool) {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }
}