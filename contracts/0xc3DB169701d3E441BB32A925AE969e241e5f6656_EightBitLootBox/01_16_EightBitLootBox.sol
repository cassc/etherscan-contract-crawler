// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../Loot/ILoot.sol";

/**
 * @title EightBitLootBox
 * EightBitLootBox - a randomized and openable lootbox of
 * Accessories.
 */
contract EightBitLootBox is ERC1155, ERC2981, ReentrancyGuard, Ownable, Pausable {
    struct BoxOptions {
        // Number of items to send per open.
        uint256 quantityPerOpen;
        // Probability in basis points (out of 10,000) of receiving each class (descending)
        uint16[] classProbabilities;
    }

    string public name;
    string public symbol;
    uint96 public royaltyFee;
    address public royaltyAddress;
    address public lootAddress;
    address public airdropTokenAddress;
    uint256 public price;
    uint256 public boxCount;
    uint256 public classCount;
    uint256 public seed;
    uint256 constant INVERSE_BASIS_POINT = 10000;

    mapping(uint256 => BoxOptions) public boxOptions; /* box idx => box options */
    mapping(uint256 => uint256[]) public classTokens; /* class idx => token ids */
    mapping(uint256 => uint256) public tokenSupply; /* box idx => supply */

    constructor() ERC1155("https://eightbit.me/api/lootbox/{id}") {
        name = "EightBit Loot Box";
        symbol = "EBLB";
        royaltyAddress = owner();
        royaltyFee = 500;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * *** EXTERNAL, PAYABLE ***
     *
     * @notice One or more loot boxes with `_boxIdx` will be minted `to` the address specified.
     *
     * @param to | address that will receive the loot box or boxes
     * @param boxIdx | loot box id to mint
     * @param amount | the number of loot boxes to mint
     */
    function mint(
        address to,
        uint256 boxIdx,
        uint256 amount
    ) external payable nonReentrant {
        require(msg.value >= price * amount, "EightBitLootBox#mint: NOT_ENOUGH_ETH");
        _mint(to, boxIdx, amount);
    }

    /**
     * *** EXTERNAL ***
     *
     * @notice This is the randomized selection & minting logic that will select
     * and mint loot box items when called. You must own a lootbox of `boxIdx`.
     * @dev The EightBitLootBox contract must have the minter role.
     *
     * @param boxIdx | loot box id to unpack
     * @param to | address that will receive the loot from the box
     * @param amount | number of loot boxes to unpack
     */
    function unpack(
        uint256 boxIdx,
        address to,
        uint256 amount
    ) external whenNotPaused {
        require(boxIdx < boxCount, "EightBitLootBox#unpack: BOX_DOES_NOT_EXIST");
        require(balanceOf(msg.sender, boxIdx) >= amount, "EightBitLootBox#unpack: MUST_HAVE_BALANCE");

        _burn(_msgSender(), boxIdx, amount);

        // Load settings for this box option
        BoxOptions memory settings = boxOptions[boxIdx];

        for (uint256 i = 0; i < amount; i++) {
            uint256 quantitySent = 0;

            while (quantitySent < settings.quantityPerOpen) {
                uint256 class = _pickRandomClass(settings.classProbabilities);

                _sendTokenWithClass(class, to, 1);
                quantitySent += 1;
            }
        }

        emit Unpack(boxIdx, msg.sender, to, amount);
    }

    /**
     * *** EXTERNAL ***
     *
     * @notice Get tokens associated with a class by `classIdx`.
     *
     * @param classIdx | the class idx
     */
    function getTokensForClass(uint256 classIdx) external view returns (uint256[] memory) {
        return classTokens[classIdx];
    }

    /**
     * *** EXTERNAL ***
     *
     * @notice Get the number of tokens received when opening loot box by `boxIdx`.
     *
     * @param boxIdx | the box idx
     */
    function getQuantityPerOpen(uint256 boxIdx) external view returns (uint256) {
        return boxOptions[boxIdx].quantityPerOpen;
    }

    /**
     * *** EXTERNAL ***
     *
     * @notice Get class probabilities for loot box by `boxIdx`.
     *
     * @param boxIdx | the box idx
     */
    function getClassProbabilities(uint256 boxIdx) external view returns (uint16[] memory) {
        return boxOptions[boxIdx].classProbabilities;
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice Associate an existing class with a new or existing token.
     *
     * @param _tokenId | the `_tokenId` to be associated with the existing `_classIdx`
     * @param _classIdx | the existing `_classIdx` to be associated with the`_tokenId`
     */
    function setClassForTokenId(uint256 _tokenId, uint256 _classIdx) public onlyOwner {
        require(_classIdx < classCount, "EightBitLootBox#setClassForTokenId: CLASS_DOES_NOT_EXIST");
        classTokens[_classIdx].push(_tokenId);

        emit SetClassForTokenId(_tokenId, _classIdx);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice Associate new or existing token ids with an existing class.
     *
     * @param _classIdx | the existing `_classIdx` to be associated with new `_tokenIds`
     * @param _tokenIds | the `_tokenIds` to be associated with the existing `_classIdx`
     */
    function setTokenIdsForClass(uint256 _classIdx, uint256[] memory _tokenIds) public onlyOwner {
        require(_classIdx < classCount, "EightBitLootBox#setTokenIdsForClass: CLASS_DOES_NOT_EXIST");
        classTokens[_classIdx] = _tokenIds;

        emit SetTokenIdsForClass(_classIdx, _tokenIds);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice Create a new class with `_tokenIds`.
     * @dev Multiple classes can technically contain the same token ids.
     * Take care to ensure that there is no intersection between token ids in classes.
     *
     * @param _tokenIds | the `_tokenIds` to be associated with the new class
     */
    function createClass(uint256[] memory _tokenIds) public onlyOwner {
        classCount = classCount + 1;
        setTokenIdsForClass(classCount - 1, _tokenIds);

        emit CreateClass(classCount - 1);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice Remove an existing class.
     *
     * @param _classIdx | new class count
     */
    function removeClass(uint256 _classIdx) public onlyOwner {
        classCount = classCount - 1;
        delete classTokens[_classIdx];

        emit RemoveClass(classCount);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice Update the settings for an existing loot box with `_boxIdx`.
     *
     * @param _boxIdx | the loot box to update
     * @param _quantityPerOpen | maximum number of items to mint per open.
     * @param _classProbabilities | array of probabilities (should add up to 10k and be descending in value).
     */
    function setBoxOptions(
        uint256 _boxIdx,
        uint256 _quantityPerOpen,
        uint16[] memory _classProbabilities
    ) public onlyOwner {
        require(_boxIdx < boxCount, "EightBitLootBox#setBoxOptions: BOX_DOES_NOT_EXIST");

        BoxOptions memory settings = BoxOptions({
            quantityPerOpen: _quantityPerOpen,
            classProbabilities: _classProbabilities
        });

        boxOptions[uint256(_boxIdx)] = settings;

        emit SetBoxOptions(_boxIdx, _quantityPerOpen, _classProbabilities);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice Update the loot address.
     *
     * @param _newLootAddress | the new loot address
     */
    function setLootAddress(address _newLootAddress) public onlyOwner {
        lootAddress = _newLootAddress;

        emit SetLootAddress(_newLootAddress);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice Set the airdrop token address
     *
     * @param _airdropTokenAddress | the token address
     */
    function setAirdropTokenAddress(address _airdropTokenAddress) public onlyOwner {
        airdropTokenAddress = _airdropTokenAddress;

        emit SetAirdropTokenAddress(_airdropTokenAddress);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice Create a new box with box options.
     *
     * @param _quantityPerOpen | maximum number of items to mint per open. Set to 0 to disable this option.
     * @param _classProbabilities | array of probabilities (should add up to 10k and be descending in value).
     */
    function createBox(uint256 _quantityPerOpen, uint16[] memory _classProbabilities) public onlyOwner {
        boxCount = boxCount + 1;
        setBoxOptions(boxCount - 1, _quantityPerOpen, _classProbabilities);

        emit CreateBox(boxCount - 1);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice Update random seed used for RNG.
     *
     * @param _newSeed | the new seed to use for the next transaction
     */
    function setSeed(uint256 _newSeed) public onlyOwner {
        seed = _newSeed;

        emit SetSeed(_newSeed);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice Set the price to mint one loot box.
     *
     * @param _newPrice | the cost to mint 1 box
     */
    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;

        emit SetPrice(_newPrice);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice Set the token URI
     * @dev See {ERC1155.sol} for usage details.
     */
    function setURI(string memory _newURI) external onlyOwner {
        _setURI(_newURI);
        emit SetURI(_newURI);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice Airdrop to EightBitNFT holders
     * @dev See {ERC1155.sol} for usage details.
     */
    function airdrop(
        uint256 boxIdx,
        uint256 amount,
        address[] memory holders
    ) external onlyOwner {
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];

            require(IERC721(airdropTokenAddress).balanceOf(holder) > 0, "EightBitLootBox#airdrop: EIGHT_BIT_ONLY");
            _mint(holder, boxIdx, amount);
            emit AirDrop(boxIdx, holder);
        }
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice When paused, `unpack()` cannot be called.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice When unpaused, `unpack()` can be called.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice Withdraw ETH from contract.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        (bool success, ) = msg.sender.call{ value: balance }("");
        require(success, "unable to send value");

        emit Withdraw(msg.sender, balance);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice update royalty fee
     */
    function setRoyaltyFee(uint96 _royaltyFee) external onlyOwner {
        royaltyFee = _royaltyFee;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice update royalty address
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * *** INTERNAL ***
     *
     * @notice Mints one or more random tokens in class `_classIdx` to `_toAddress`.
     *
     * @param _classIdx | the class index to choose from
     * @param _toAddress | the address that will receive tokens
     * @param _amount | the number tokens to mint from the specified class
     */
    function _sendTokenWithClass(
        uint256 _classIdx,
        address _toAddress,
        uint256 _amount
    ) internal {
        ILoot loot = ILoot(lootAddress);
        uint256 tokenId = _pickRandomAvailableTokenIdForClass(_classIdx);

        loot.mint(_toAddress, tokenId, _amount);
    }

    /**
     * *** INTERNAL ***
     *
     * @notice Choose a random class using class rarity weights.
     *
     * @param _classProbabilities | array of probabilities (out of INVERSE_BASIS_POINT)
     */
    function _pickRandomClass(uint16[] memory _classProbabilities) internal returns (uint256) {
        uint16 value = uint16(_random() % INVERSE_BASIS_POINT);
        // Start at top class (length - 1)
        // skip common (0), we default to it
        for (uint256 i = _classProbabilities.length - 1; i > 0; i--) {
            uint16 probability = _classProbabilities[i];

            if (value < probability) {
                return i;
            } else {
                value = value - probability;
            }
        }

        return 0;
    }

    /**
     * *** INTERNAL ***
     *
     * @notice Pick a random token from a class with `_classIdx`.
     *
     * @param _classIdx | the class to pick from
     */
    function _pickRandomAvailableTokenIdForClass(uint256 _classIdx) internal returns (uint256) {
        uint256[] memory tokenIds = classTokens[_classIdx];
        require(tokenIds.length > 0, "EightBitLootBox#_pickRandomAvailableTokenIdForClass: NO_TOKENS_FOR_CLASS");

        uint256 randIndex = _random() % tokenIds.length;
        uint256 tokenId = tokenIds[randIndex % tokenIds.length];

        return tokenId;
    }

    /**
     * *** INTERNAL ***
     *
     * @notice Pseudo-random number generator.
     */
    function _random() internal returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, seed)));
        seed = randomNumber;
        return randomNumber;
    }

    /**
     * *** PRIVATE ***
     *
     * @notice Pseudo-random number generator.
     */
    function _mint(
        address to,
        uint256 boxIdx,
        uint256 amount
    ) private {
        require(boxIdx < boxCount, "EightBitLootBox#mint: BOX_DOES_NOT_EXIST");
        tokenSupply[boxIdx] = tokenSupply[boxIdx] + amount;
        _mint(to, boxIdx, amount, "");

        emit Mint(to, boxIdx, amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    event AirDrop(uint256 boxIdx, address to);
    event CreateBox(uint256 boxIdx);
    event CreateClass(uint256 classIdx);
    event Unpack(uint256 indexed boxIdx, address from, address indexed to, uint256 amount);
    event Mint(address to, uint256 boxIdx, uint256 amount);
    event RemoveClass(uint256 classIdx);
    event ResetClass(uint256 classIdx);
    event SetBoxOptions(uint256 boxIdx, uint256 quantityPerOpen, uint16[] classProbabilities);
    event SetClassForTokenId(uint256 tokenId, uint256 classIdx);
    event SetAirdropTokenAddress(address airdropTokenAddress);
    event SetLootAddress(address newLootAddress);
    event SetPrice(uint256 newPrice);
    event SetSeed(uint256 newSeed);
    event SetTokenIdsForClass(uint256 classIdx, uint256[] tokenIds);
    event SetURI(string newURI);
    event Warning(string message, address account);
    event Withdraw(address to, uint256 amount);
}