// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

/// @title Anime Metaverse Reward Smart Contract
/// @author LiquidX
/// @notice This smart contract is used for reward on Gachapon event

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./AmvUtils.sol";
import "./IAnimeMetaverseReward.sol";

/// @notice Thrown when invalid destination address specified (address(0) or address(this))
error InvalidAddress();

/// @notice Thrown when given input does not meet with the expected one
error InvalidInput();

/// @notice Thrown when mint amount is more than the maximum limit or equals to zero
error InvalidMintingAmount(uint256 amount);

/// @notice Thrown when address is not included in Burner list
error InvalidBurner();

/// @notice Thrown when address is not included in Minter list
error InvalidMinter();

/// @notice Thrown when token ID is not match with the existing one
error InvalidTokenId();

/// @notice Thrown when token ID is not available for minting
error InvalidMintableTokenId();

/// @notice Thrown when input is equal to zero
error ValueCanNotBeZero();

/// @notice Thrown when token supply already reaches its maximum limit
/// @param range  Amount of token that would be minted
error MintAmountForTokenTypeExceeded(uint256 range);

/// @notice Thrown when address is not allowed to burn the token
error NotAllowedToBurn();

/// @notice Thrown when is not able to mint digital collectible
error ClaimingMerchandiseDeactivated();

contract AnimeMetaverseReward is
    ERC1155,
    Ownable,
    AmvUtils,
    IAnimeMetaverseReward
{
    uint256 public constant GIFT_BOX_TOKEN_TYPE = 1;
    uint256 public constant ARTIFACTS_TOKEN_TYPE = 2;
    uint256 public constant RUNE_CHIP_TOKEN_TYPE = 3;
    uint256 public constant SCROLL_TOKEN_TYPE = 4;
    uint256 public constant COLLECTIBLE__TOKEN_TYPE = 5;
    uint256 public constant DIGITAL_COLLECTIBLE_TOKEN_TYPE = 6;

    uint256 public constant MAX_MINTATBLE_TOKEN_ID = 18;
    uint256 public constant MAX_BURNABLE_COLLECTIBLE = 1;
    uint256 public constant COLLECTIBLE_AND_DIGITAL_COLLECTIBLE_DIFF = 3;
    uint256 public constant MAX_TOKEN_SUPPLY = 5550;

    struct TokenInfo {
        string tokenName;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 tokenType;
    }

    mapping(uint256 => TokenInfo) public tokenCollection;

    /// @notice Total of token ID
    uint256 totalToken = 0;
    uint256 maxMintLimit = 100;

    /// @notice List of address that could mint the token
    /// @dev Use this mapping to set permission on who could mint the token
    /// @custom:key A valid ethereum address
    /// @custom:value Set permission in boolean. 'true' means allowed
    mapping(address => bool) public minterList;

    /// @notice List of address that could burn the token
    /// @dev Use this mapping to set permission on who could force burn the token
    /// @custom:key A valid ethereum address
    /// @custom:value Set permission in boolean. 'true' means allowed
    mapping(uint256 => mapping(address => bool)) public burnerList;

    bool public claimMerchandiseActive = false;

    /// @notice Base URL to store off-chain information
    /// @dev This variable could be used to store URL for the token metadata
    string public baseURI = "";

    /// @notice Check whether address is valid
    /// @param _address Any valid ethereum address
    modifier validAddress(address _address) {
        if (_address == address(0)) {
            revert InvalidAddress();
        }
        _;
    }

    /// @notice Check whether token ID exist
    /// @param tokenId token ID
    modifier validTokenId(uint256 tokenId) {
        if (tokenId < 1 || tokenId > totalToken) {
            revert InvalidTokenId();
        }
        _;
    }

    /// @notice Check whether mint amount is more than maximum limit or equals to zero
    /// @param amount Mint amount
    modifier validMintingAmount(uint256 amount) {
        if (amount > maxMintLimit || amount < 1) {
            revert InvalidMintingAmount(amount);
        }
        _;
    }

    modifier validMintableTokenId(uint256 tokenId) {
        if (tokenId < 1 || tokenId > MAX_MINTATBLE_TOKEN_ID) {
            revert InvalidMintableTokenId();
        }
        _;
    }

    /// @notice Check whether an address has permission to mint
    modifier onlyMinter() {
        if (!minterList[msg.sender]) {
            revert InvalidMinter();
        }
        _;
    }

    /// @notice Check whether an address has permission to force burn
    modifier onlyBurner(uint256 id) {
        if (!isValidBurner(id)) {
            revert InvalidBurner();
        }
        _;
    }

    /// @notice There's a batch mint transaction happen
    /// @dev Emit event when calling mintBatch function
    /// @param drawIndex Gachapon draw Index
    /// @param activityId Gachapon activity ID
    /// @param minter Address who calls the function
    /// @param to Address who receives the token
    /// @param ids Item token ID
    /// @param amounts Amount of item that is minted
    event RewardMintBatch(
        uint256 ticket,
        uint256 drawIndex,
        uint256 activityId,
        address minter,
        address to,
        uint256[] ids,
        uint256[] amounts
    );

    /// @notice There's a mint transaction happen
    /// @dev Emit event when calling mint function
    /// @param drawIndex Gachapon draw Index
    /// @param activityId Gachapon activity ID
    /// @param minter Address who calls the function
    /// @param to Address who receives the token
    /// @param id Item token ID
    /// @param amount Amount of item that is minted
    event RewardMint(
        uint256 ticket,
        uint256 drawIndex,
        uint256 activityId,
        address minter,
        address to,
        uint256 id,
        uint256 amount
    );

    /// @notice There's a token being burned
    /// @dev Emits event when forceBurn function is called
    /// @param burner Burner address
    /// @param Owner Token owner
    /// @param tokenId Token ID that is being burned
    /// @param amount Amount of token that is being burned
    event ForceBurn(
        address burner,
        address Owner,
        uint256 tokenId,
        uint256 amount
    );

    /// @notice There's a digital collectible
    /// @dev Emit event when digital merch is minted
    /// @param minter Address who mints digital collectible
    /// @param to Address who receiveses digital collectible
    /// @param id Token ID of the digital collectible
    /// @param amount Amount of the digital collectible that is minted
    event MintDigitalMerch(
        address minter,
        address to,
        uint256 id,
        uint256 amount
    );

    /// @notice Sets token ID, token name, maximum supply and token type for all tokens
    /// @dev The ERC1155 function is derived from Open Zeppelin ERC1155 library
    constructor() ERC1155("") {
        setTokenInfo(1, "Gift of Soul", 170, GIFT_BOX_TOKEN_TYPE);

        setTokenInfo(2, "Sakura", 4, ARTIFACTS_TOKEN_TYPE);
        setTokenInfo(3, "Starburst X", 4000, ARTIFACTS_TOKEN_TYPE);
        setTokenInfo(4, "Starburst C", 2500, ARTIFACTS_TOKEN_TYPE);
        setTokenInfo(5, "Starburst D", 1896, ARTIFACTS_TOKEN_TYPE);
        setTokenInfo(6, "Starburst M", 1500, ARTIFACTS_TOKEN_TYPE);
        setTokenInfo(7, "Starburst V", 100, ARTIFACTS_TOKEN_TYPE);

        setTokenInfo(8, "God Rune", 450, RUNE_CHIP_TOKEN_TYPE);
        setTokenInfo(9, "Man Rune", 1500, RUNE_CHIP_TOKEN_TYPE);
        setTokenInfo(10, "Sun Rune", 3000, RUNE_CHIP_TOKEN_TYPE);
        setTokenInfo(11, "Fire Rune", 4500, RUNE_CHIP_TOKEN_TYPE);
        setTokenInfo(12, "Ice Rune", 5550, RUNE_CHIP_TOKEN_TYPE);

        setTokenInfo(13, "Scroll of Desire", 4715, SCROLL_TOKEN_TYPE);
        setTokenInfo(14, "Scroll of Prophecy", 3301, SCROLL_TOKEN_TYPE);
        setTokenInfo(15, "Scroll of Fortitude", 1414, SCROLL_TOKEN_TYPE);

        setTokenInfo(16, "Hoodie", 200, COLLECTIBLE__TOKEN_TYPE);
        setTokenInfo(17, "Tshirt", 400, COLLECTIBLE__TOKEN_TYPE);
        setTokenInfo(18, "Socks", 800, COLLECTIBLE__TOKEN_TYPE);

        setTokenInfo(19, "Digital Hoodie", 200, DIGITAL_COLLECTIBLE_TOKEN_TYPE);
        setTokenInfo(20, "Digital Tshirt", 400, DIGITAL_COLLECTIBLE_TOKEN_TYPE);
        setTokenInfo(21, "Digital Sock", 800, DIGITAL_COLLECTIBLE_TOKEN_TYPE);
    }

    /// @notice Sets information about specific token
    /// @dev It will set token ID, token name, maximum supply, and token type
    /// @param _tokenId ID for specific token
    /// @param _tokenName Name of the token
    /// @param _maximumSupply The maximum supply for the token
    /// @param _tokenType Type of token
    function setTokenInfo(
        uint256 _tokenId,
        string memory _tokenName,
        uint256 _maximumSupply,
        uint256 _tokenType
    ) private {
        totalToken++;
        tokenCollection[_tokenId] = TokenInfo({
            maxSupply: _maximumSupply,
            totalSupply: 0,
            tokenName: _tokenName,
            tokenType: _tokenType
        });
    }

    /// @notice Update token maximum supply
    /// @dev This function can only be executed by the contract owner
    /// @param _id Token ID
    /// @param _maximumSupply Token new maximum supply
    function updateTokenSupply(uint256 _id, uint256 _maximumSupply)
        external
        onlyOwner
        validTokenId(_id)
    {
        if (tokenCollection[_id].totalSupply > _maximumSupply) {
            revert InvalidInput();
        }
        tokenCollection[_id].maxSupply = _maximumSupply;
    }

    /// @notice Set maximum amount to mint token
    /// @dev This function can only be executed by the contract owner
    /// @param _mintLimit Maximum amount to mint
    function setMaxMintLimit(uint256 _mintLimit) external onlyOwner {
        require(_mintLimit >= 1, "Can not set mintLimit less than 1.");
        require(
            _mintLimit <= MAX_TOKEN_SUPPLY,
            "Can not set mintLimit more than 5550."
        );
        maxMintLimit = _mintLimit;
    }

    /// @notice Registers an address and sets a permission to mint
    /// @dev This function can only be executed by the contract owner
    /// @param _minter A valid ethereum address
    /// @param _flag The permission to mint. 'true' means allowed
    function setMinterAddress(address _minter, bool _flag)
        external
        onlyOwner
        validAddress(_minter)
    {
        minterList[_minter] = _flag;
    }

    /// @notice Set claimMerchandiseActive value
    /// @param _flag 'true' to activate claim collectible event, otherwise 'false'
    function toggleMerchandiseClaim(bool _flag) external onlyOwner {
        claimMerchandiseActive = _flag;
    }

    /// @notice Registers an address and sets a permission to force burn specific token
    /// @dev This function can only be executed by the contract owner
    /// @param _id The token id that can be burned by this address
    /// @param _burner A valid ethereum address
    /// @param _flag The permission to force burn. 'true' means allowed
    function setBurnerAddress(
        uint256 _id,
        address _burner,
        bool _flag
    ) external onlyOwner validAddress(_burner) validTokenId(_id) {
        burnerList[_id][_burner] = _flag;
    }

    /// @notice Mint token in batch
    /// @dev This function will increase total supply for the token that
    ///      is minted.
    ///      Only allowed minter address that could run this function
    /// @param _ticket Gachapon ticket counter for a draw
    /// @param _drawIndex Gachapon draw Index
    /// @param _activityId Gachapon activity ID
    /// @param _to The address that will receive the token
    /// @param _ids The token ID that will be minted
    /// @param _amounts Amount of token that will be minted
    /// @param _data _
    function mintBatch(
        uint256 _ticket,
        uint256 _drawIndex,
        uint256 _activityId,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external onlyMinter validAddress(_to) {
        if (_amounts.length != _ids.length) {
            revert InvalidInput();
        }

        for ( uint256 idCounter = 0; idCounter < _ids.length; idCounter = _uncheckedInc(idCounter) ) {
            uint256 _id = _ids[idCounter];

            if (_amounts[idCounter] > maxMintLimit || _amounts[idCounter] < 1) {
                revert InvalidMintingAmount(_amounts[idCounter]);
            }
            if (_id < 1 || _id > MAX_MINTATBLE_TOKEN_ID) {
                revert InvalidMintableTokenId();
            }
            if (
                tokenCollection[_id].totalSupply + _amounts[idCounter] >
                tokenCollection[_id].maxSupply
            ) {
                revert MintAmountForTokenTypeExceeded(_amounts[idCounter]);
            }

            unchecked {
                tokenCollection[_id].totalSupply += _amounts[idCounter];
            }
        }

        _mintBatch(_to, _ids, _amounts, _data);
        emit RewardMintBatch(
            _ticket,
            _drawIndex,
            _activityId,
            msg.sender,
            _to,
            _ids,
            _amounts
        );
    }

    /// @notice Mint token
    /// @dev This function will increase total supply for the token that
    ///      is minted.
    ///      Only allowed minter address that could run this function
    /// @param _ticket Gachapon ticket counter for a draw
    /// @param _drawIndex Gachapon draw Index
    /// @param _activityId Gachapon activity ID
    /// @param _to The address that will receive the token
    /// @param _id The token ID that will be minted
    /// @param _amount Amount of token that will be minted
    /// @param _data _
    function mint(
        uint256 _ticket,
        uint256 _drawIndex,
        uint256 _activityId,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    )
        external
        onlyMinter
        validAddress(_to)
        validMintableTokenId(_id)
        validMintingAmount(_amount)
    {
        if (
            tokenCollection[_id].totalSupply + _amount >
            tokenCollection[_id].maxSupply
        ) {
            revert MintAmountForTokenTypeExceeded(_amount);
        }
        unchecked {
            tokenCollection[_id].totalSupply += _amount;
        }
        _mint(_to, _id, _amount, _data);
        emit RewardMint(
            _ticket,
            _drawIndex,
            _activityId,
            msg.sender,
            _to,
            _id,
            _amount
        );
    }

    /// @notice Burns specific token from other address
    /// @dev Only burners address who are allowed to burn the token.
    ///      These addresses will be set by owner.
    /// @param _account The owner address of the token
    /// @param _id The token ID
    /// @param _amount Amount to burn
    function forceBurn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external validAddress(_account) onlyBurner(_id) validTokenId(_id) {
        _burn(_account, _id, _amount);
        emit ForceBurn(msg.sender, _account, _id, _amount);
    }

    /// @notice Checks whether the caller has the permission to burn this particular token or not
    /// @param _id The token ID to burn
    function isValidBurner(uint256 _id) public view returns (bool) {
        return burnerList[_id][msg.sender];
    }

    /// @notice Set base URL for storing off-chain information
    /// @param newuri A valid URL
    function setURI(string memory newuri) external onlyOwner {
        baseURI = newuri;
    }

    /// @notice Appends token ID to base URL
    /// @param tokenId The token ID
    function uri(uint256 tokenId) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, intToString(tokenId)))
                : "";
    }

    /// @notice Get information from specific token ID
    /// @param _id Token ID
    function getTokenInfo(uint256 _id)
        external
        view
        validTokenId(_id)
        returns (TokenInfo memory tokenInfo)
    {
        tokenInfo = tokenCollection[_id];
    }

    /// @notice Mint digital collectible
    /// @param _to Receiver of the digital collectible
    /// @param collectible_id Token ID that's included in COLLECTIBLE_TOKEN_TYPE
    function mintDigitalCollectible(address _to, uint256 collectible_id)
        internal
    {
        uint256 _id = collectible_id + COLLECTIBLE_AND_DIGITAL_COLLECTIBLE_DIFF;
        tokenCollection[_id].totalSupply++;
        _mint(_to, _id, MAX_BURNABLE_COLLECTIBLE, "");
        emit MintDigitalMerch(msg.sender, _to, _id, MAX_BURNABLE_COLLECTIBLE);
    }

    /// @notice Claim collectible with digital collectible
    /// @param _account Owner of the collectible
    /// @param _id Token ID that's included in COLLECTIBLE_TOKEN_TYPE
    function claimMerchandise(address _account, uint256 _id)
        external
        validAddress(_account)
    {
        if (!claimMerchandiseActive) {
            revert ClaimingMerchandiseDeactivated();
        }
        if (tokenCollection[_id].tokenType != COLLECTIBLE__TOKEN_TYPE)
            revert NotAllowedToBurn();
        require(
            _account == _msgSender() ||
                isApprovedForAll(_account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(_account, _id, MAX_BURNABLE_COLLECTIBLE);
        mintDigitalCollectible(_account, _id);
    }

    function _uncheckedInc(uint256 val) internal pure returns (uint256) {
        unchecked {
            return val + 1;
        }
    }
}