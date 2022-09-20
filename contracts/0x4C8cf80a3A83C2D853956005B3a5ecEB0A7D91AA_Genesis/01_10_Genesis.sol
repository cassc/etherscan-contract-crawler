// SPDX-License-Identifier: MIT
/*

     *+.         =*-.        .*=                 +*    .*+.      *+.         :*:       **#####*-
    .%%%+.       *%+#*=.     -%%%=             -%*.   +%%%%-    .%%%+.       =%-            .##.
    .%*.+%+.     *%  :+%#-   -%=:*%=         .*%-   :##:%#-#*   .%*.+%+.     =%-            +%:
    .%#- .+%+.   *% :+##=.   -%*: :*%=      =%+      :  %#  :   .%#- .+%+.   =%-           =%=
    .%###- .=:   *%%*=.      -%#%*: =%-   :##:          %#      .%###- :%+   =%-    .-    :%+
    .%* -##-     *%#:        -%= =%*+%-   :##:          %#      .%* -##=%+   =%-   +%+   .%#
    .%*   =##:   *%+%+       -%=   =%%-     =%*.        %#      .%*   -#%+   =%- -##:    ##.
    .%*     :.   *% :##-     -%=    =%-      .*%=       %#      .%*    :%+   =%=*%=     *%:
    .%*          *%   =%*.   -%=    =%-        -##:     %#      .%*    :%+   =%%*.     =%+.....
     +-          =+    .+=   .*:    :*.          ++     +=       +-     *-   :*-       +*******-

*/
// @title   FRACTALZ: Genesis
// @author  devberry.eth
// @notice  Explore... 🌌
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

    error MintConfigMissing();
    error MintingDisabled();
    error MintingClosed();
    error MintQuantityExceedsWaystoneBalance();
    error MintQuantityExceedsMaximumSupply();
    error InvalidEthereumValue();
    error MintingBonusFromContractAddress();
    error BonusMinimumQtyNotMet();
    error DivergingDisabled();
    error MergingDisabled();
    error InvalidHash();
    error InvalidSignature();
    error InvalidTokenQuantity();
    error NotTokenOwner();
    error TokenAlreadyBurned();
    error InvalidTokenTier();
    error TokenDoesNotExist();
    error FractalQueryForNonexistentToken();
    error X();

contract Genesis is ERC721A, Ownable, IERC2981 {

    event Roll(uint256 val);

    using Strings for uint256;
    using ECDSA for bytes32;

    struct Window {
        uint64 epoch;
        uint64 duration;
    }

    struct MintConfig {
        Window window;
        uint256 price;
        uint256 waystonePrice;
        uint64 specialSupply;
        uint64 maximumSupply;
        uint64 allowancePerWaystone;
        uint64 closeDuration;
        uint64 closeTrigger;
        uint64 bonusPrice;
        uint64 bonusChance;
        uint64 bonusChanceIncrease;
        uint64 bonusIncreaseQuantity;
    }

    struct TransformationConfig {
        Window window;
        uint64 burnQuantity;
        uint64 mintQuantity;
        uint64 burnTier;
        uint64 mintTier;
    }

    struct Fractal {
        address minter;
        uint64 epoch;
        uint64 tier;
        bool special;
        uint256 random;
    }

    struct ContractState {
        address waystonesAddress;
        MintConfig mintConfig;
        TransformationConfig divergeConfig;
        TransformationConfig mergeConfig;
        uint64 closeEpoch;
        uint256 totalMinted;
        uint256 totalBurned;
    }

    IERC1155 private waystones;

    mapping(uint256 => Fractal) private fractalz;

    MintConfig public mintConfig;
    TransformationConfig public divergeConfig;
    TransformationConfig public mergeConfig;

    string private baseURI;

    address private signer;

    uint64 private x; /// § ///
    uint64 public closeEpoch;
    uint64 public toll = 500;
    uint64 private randomNonce;

    address constant private shuffleGnosis  = 0x42A21bA79D2fe79BaE4D17A6576A15b79f5d36B0;
    address constant private fractalzGnosis = 0xF3FAbb566FBc6FA29ED86c583448F13F48009D23;

    constructor(address _waystones) ERC721A("FRACTALZ: Genesis", "FRCTLZ"){
        waystones = IERC1155(_waystones);
    }

    function mint(uint64 quantity, bool bonus) external payable {
        if (!insideWindow(mintConfig.window)) revert MintingDisabled();

        uint256 waystoneBalance = waystoneBalanceOf(msg.sender);
        uint256 allowance = fractalzAllowance(msg.sender, waystoneBalance);

        bool rolledBonus;

        uint256 hash = randomHash();

        if (bonus && msg.sender.code.length > 0) revert MintingBonusFromContractAddress();

        if (bonus && quantity < 2) revert BonusMinimumQtyNotMet();

        if (bonus) rolledBonus = rollRandom(hash, mintConfig.bonusChance + (waystoneBalance * mintConfig.bonusChanceIncrease));

        if ((rolledBonus && quantity + 1 + _totalMinted() > mintConfig.maximumSupply) || (!rolledBonus && quantity + _totalMinted() > mintConfig.maximumSupply)) revert MintQuantityExceedsMaximumSupply();

        if (allowance > 0) {
            if ((bonus && msg.value != (quantity * mintConfig.waystonePrice) + mintConfig.bonusPrice) || (!bonus && msg.value != quantity * mintConfig.waystonePrice)) revert InvalidEthereumValue();
            if (quantity > allowance) revert MintQuantityExceedsWaystoneBalance();
            if (rolledBonus) quantity += bonusFractalzQuantity(quantity);
            internalEpochMint(quantity, _nextTokenId() + quantity <= mintConfig.specialSupply, hash);
        } else {
            if ((bonus && msg.value != (quantity * mintConfig.price) + mintConfig.bonusPrice) || (!bonus && msg.value != quantity * mintConfig.price)) revert InvalidEthereumValue();
            if (_numberMinted(msg.sender) >= 1 || quantity > 1) revert MintQuantityExceedsWaystoneBalance();
            if (rolledBonus) quantity += bonusFractalzQuantity(quantity);
            internalEpochMint(quantity, false, hash);
        }
    }

    function diverge(uint256[] calldata tokenIds) external {
        if (!insideWindow(divergeConfig.window)) revert DivergingDisabled();
        internalTransformation(tokenIds, divergeConfig);
    }

    function merge(uint256[] calldata tokenIds, bytes32 hash, bytes memory signature) external {
        if (!insideWindow(mergeConfig.window)) revert MergingDisabled();
        if (hashTransformation(msg.sender, tokenIds, mergeConfig.burnTier) != hash) revert InvalidHash();
        if (signer != hash.recover(signature)) revert InvalidSignature();
        internalTransformation(tokenIds, mergeConfig);
    }

    function internalEpochMint(uint64 quantity, bool special, uint256 hash) internal {
    unchecked{
        if (closeEpoch > 0 && block.timestamp >= closeEpoch) {
            revert MintingClosed();
        } else {
            if (_nextTokenId() - 1 + quantity >= mintConfig.closeTrigger) {
                closeEpoch = uint64(block.timestamp) + mintConfig.closeDuration;
            }
        }
    }
        internalMint(msg.sender, quantity, 0, special, hash);
    }

    function internalMint(address to, uint256 quantity, uint64 tier, bool special, uint256 hash) internal {
        if (x == 1) revert X();
        Fractal storage _fractal = fractalz[_nextTokenId()];
        (
        _fractal.epoch,
        _fractal.random,
        _fractal.minter,
        _fractal.special,
        _fractal.tier
        ) = (
        uint64(block.timestamp),
        hash,
        to,
        special,
        tier
        );
        x = 1;
        _mint(to, quantity);
        x = 0;
    }

    function internalTransformation(uint256[] calldata tokenIds, TransformationConfig memory config) internal {
        if (tokenIds.length % config.burnQuantity != 0) revert InvalidTokenQuantity();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            TokenOwnership memory ownership = _ownershipOf(tokenIds[i]);
            if (ownership.addr != msg.sender) revert NotTokenOwner();
            if (ownership.burned) revert TokenAlreadyBurned();
            _burn(tokenIds[i]);
        }
        internalMint(msg.sender, (tokenIds.length / config.burnQuantity) * config.mintQuantity, config.mintTier, false, randomHash());
    }

    function insideWindow(Window memory window) internal view returns (bool){
        return (window.epoch > 0 && block.timestamp > window.epoch && block.timestamp < window.epoch + window.duration);
    }

    function secondsUntilMintClose() external view returns (uint64){
        if (mintConfig.window.epoch == 0) revert MintConfigMissing();
        uint64 end;
        if (closeEpoch > 0) {
            end = closeEpoch;
        } else {
            end = mintConfig.window.epoch + mintConfig.window.duration;
        }
        if (block.timestamp >= end) {
            return 0;
        } else {
            return end - uint64(block.timestamp);
        }
    }

    function fractalDNA(uint256 tokenId) public view returns (uint256) {
        Fractal memory _fractal = fractal(tokenId);
        return uint256(
            keccak256(
                abi.encodePacked(
                    _fractal.random,
                    tokenId,
                    _fractal.minter
                )
            )
        );
    }

    function randomHash() private returns (uint256) {
        uint256 hash = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.difficulty,
                    msg.sender,
                    randomNonce++
                )
            )
        );
        emit Roll(hash);
        return hash;
    }

    function rollRandom(uint256 hash, uint256 chance) private pure returns (bool){
        return (hash % 100000) <= chance;
    }

    function fractal(uint256 tokenId) public view returns (Fractal memory){
        if (!_exists(tokenId)) revert FractalQueryForNonexistentToken();
        Fractal memory _fractal;
        uint256 curr = tokenId;
        while (_fractal.epoch == 0) {
            Fractal memory currFractal = fractalz[curr];
            if (currFractal.epoch > 0) {
                return currFractal;
            } else {
                curr--;
            }
        }
        return _fractal;
    }

    function waystoneBalanceOf(address owner) public view returns (uint256) {
        return waystones.balanceOf(owner, 1);
    }

    function fractalzMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function fractalzAllowance(address owner, uint256 waystoneBalance) public view returns (uint256) {
        if (!mintConfigExists()) revert MintConfigMissing();
        uint256 allowance = waystoneBalance * mintConfig.allowancePerWaystone;
        uint256 minted = _numberMinted(owner);
        if (minted >= allowance) {
            return 0;
        } else {
            return allowance - minted;
        }
    }

    function bonusFractalzQuantity(uint64 quantity) public view returns (uint64){
        if (quantity == 0) revert MintZeroQuantity();
        if (!mintConfigExists()) revert MintConfigMissing();
        return (quantity - (quantity % mintConfig.bonusIncreaseQuantity)) / mintConfig.bonusIncreaseQuantity;
    }

    function bonusFractalzChance(uint256 waystoneBalance) public view returns (uint256){
        if (!mintConfigExists()) revert MintConfigMissing();
        if (waystoneBalance * mintConfig.bonusChanceIncrease < 100000 - mintConfig.bonusChance) return mintConfig.bonusChance + (waystoneBalance * mintConfig.bonusChanceIncrease);
        return 100000;
    }

    function reserveMint(address to, uint256 quantity) external onlyOwner {
        if (quantity + _totalMinted() > mintConfig.maximumSupply) revert MintQuantityExceedsMaximumSupply();
        internalMint(to, quantity, 0, false, randomHash());
    }

    function setToll(uint64 _toll) external onlyOwner {
        toll = _toll;
    }

    function setMintConfig(MintConfig memory config) external onlyOwner {
        closeEpoch = 0;
        mintConfig = config;
    }

    function mintConfigExists() public view returns (bool){
        return mintConfig.allowancePerWaystone > 0;
    }

    function setTransformationConfig(uint64 configType, TransformationConfig memory config) external onlyOwner {
        if (configType == 0) {
            divergeConfig = config;
        } else if (configType == 1) {
            mergeConfig = config;
        }
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setWaystones(address _waystones) external onlyOwner {
        waystones = IERC1155(_waystones);
    }

    function state() external view returns (ContractState memory){
        return ContractState(address(waystones), mintConfig, divergeConfig, mergeConfig, closeEpoch, _totalMinted(), _totalBurned());
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view virtual returns (uint256[] memory) {
    unchecked {
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        uint256 tokenIdsLength = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);
        TokenOwnership memory ownership;
        for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
            ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                tokenIds[tokenIdsIdx++] = i;
            }
        }
        return tokenIds;
    }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    function _baseURI() internal view override virtual returns (string memory) {
        return baseURI;
    }

    function hashTransformation(address sender, uint256[] memory tokenIds, uint64 tier)
    private
    pure
    returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, tokenIds, tier))
            )
        );
        return hash;
    }

    function withdraw() external onlyOwner {
        uint256 fivePercent = address(this).balance / 20;

        (bool successShuffle,) = address(shuffleGnosis).call{
        value : fivePercent * 4          // 20% - ShuffleDAO
        }("");
        if (!successShuffle) revert("Shuffle transfer failed");

        (bool success,) = address(fractalzGnosis).call{
        value : address(this).balance   // 80% - FRACTALZ
        }("");
        if (!success) revert("Failed");
    }

    function withdrawBackup() external {
        if (msg.sender != fractalzGnosis) revert("Not FRACTALZ Gnosis");
        (bool success,) = address(shuffleGnosis).call{
        value : address(this).balance   // 100% - ShuffleDAO - Can only be triggered by FRACTALZ
        }("");
        if (!success) revert("Failed");
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) public view virtual override returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * toll) / 10000;
        return (fractalzGnosis, royaltyAmount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        return
        interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
        interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
        interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }
}