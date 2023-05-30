// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

/// @title Pixelmon Trainer Gear Smart Contract
/// @author LiquidX
/// @notice This smart contract is used for reward on Pixelmon Adventure event

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @notice Thrown when invalid destination address specified address(0)
error InvalidAddress();

/// @notice Thrown when given input does not meet with the expected one
error InvalidInput();

/// @notice Thrown when address is not included in Minter list
error InvalidMinter();

/// @notice Thrown for transfer request who does not have permission
error NotAllowedToTransfer();

/// @notice Thrown when token ID is not match with the existing one
error InvalidTokenId();

/// @notice Thrown when input is equal to zero
error ValueCanNotBeZero();

/// @notice Thrown when token supply already reaches its maximum limit
/// @param _range Amount of token that would be minted
error MintAmountForTokenTypeExceeded(uint256 _range);

/// @notice Thrown when minting is not active and minter tries to mint
error MintingNotActive();

/// @notice Strings library will be used to convert uint256 to string
using Strings for uint256;

/// @notice Pixelmon Trainer Gear smart contract
/// @dev This is a ERC1155 token token standard smart contract
/// @dev Using Ownable modifiers for configuration methods
/// @dev Using ReentrancyGuard for mint and mintBatch method 
contract PixelmonTrainerGear is ERC1155, Ownable, ReentrancyGuard {
    /// @notice Data structure for holding each type token information
    /// @param tokenName token name for a specific token Id
    /// @param maximumTokenSupply Maximum amount of a token Id allowed to mint
    /// @param totalMintedTokenAmount Minted amount of a token Id
    /// @param tokenId token Id value
    struct TokenInfo {
        string tokenName;
        uint256 maximumTokenSupply;
        uint256 totalMintedTokenAmount;
        uint256 tokenId;
    }

    /// @notice List of address that could mint the token
    /// @dev Use this mapping to set permission on who could mint the token
    /// @custom:key A valid ethereum address
    /// @custom:value Set permission in boolean. 'true' means allowed
    mapping(address => bool) public minterList;

    /// @notice List of address that could transfer tokens
    /// @dev Use this mapping to set permission on who could transfer tokens
    /// @custom:key A valid ethereum address
    /// @custom:value Set permission in boolean. 'true' means allowed
    mapping(address => bool) public isAllowedToTransfer; 

    /// @notice List of ERC1155 token types of this smart contract
    /// @dev Use this mapping to store token information
    /// @custom:key tokenId
    /// @custom:value Token information with TokenInfo structure
    mapping(uint256 => TokenInfo) public tokenCollections;

    /// @notice Total of token ID
    uint256 public totalToken = 0;

    /// @notice Sum of total supply for each token
    uint256 public maximumTokenSupply = 0;

    /// @notice Flag for validate is minting active or not
    bool public isMintingActive = true;

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

    /// @notice Check whether minting is active or not
    modifier mintingActive() {
        if(!isMintingActive) {
            revert MintingNotActive();
        }
        _;
    }

    /// @notice Check whether token ID exist
    /// @param _tokenId token ID
    modifier validTokenId(uint256 _tokenId) {
        if (_tokenId < 1 || _tokenId > totalToken) {
            revert InvalidTokenId();
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

    /// @notice Check whether an address has permission to transfer
    modifier allowedToTransfer() {
        if (!isAllowedToTransfer[msg.sender]) {
            revert NotAllowedToTransfer();
        }
        _;
    }

    /// @notice There's a batch mint transaction happen
    /// @dev Emit event when calling mintBatch function
    /// @param minter Address who calls the function
    /// @param receiver Address who receives the token
    /// @param tokenIdList Item token ID
    /// @param amountList Amount of item that is minted
    event BatchPixelmonTrainerGearMint(
        address minter,
        address receiver,
        uint256[] tokenIdList,
        uint256[] amountList
    );

    /// @notice There's a mint transaction happen
    /// @dev Emit event when calling mint function
    /// @param minter Address who calls the function
    /// @param receiver Address who receives the token
    /// @param tokenId Item token ID
    /// @param amount Amount of item that is minted
    event PixelmonTrainerGearMint(
        address minter,
        address receiver,
        uint256 tokenId,
        uint256 amount
    );

    /// @notice Sets token ID, token name, maximum supply and token type for all tokens
    /// @dev The ERC1155 function is derived from Open Zeppelin ERC1155 library
    /// @param _baseURI Metadata server base URI
    constructor(string memory _baseURI) ERC1155("") {
        baseURI = _baseURI;

        addTokenInfo("Helm 1", 200);
        addTokenInfo("Helm 2", 200);
        addTokenInfo("Helm 3", 200);
        addTokenInfo("Helm 4", 200);

        addTokenInfo("Armor 1", 200);
        addTokenInfo("Armor 2", 200);
        addTokenInfo("Armor 3", 200);
        addTokenInfo("Armor 4", 200);

        addTokenInfo("Weapon 1", 200);
        addTokenInfo("Weapon 2", 200);
        addTokenInfo("Weapon 3", 200);
        addTokenInfo("Weapon 4", 200);
    }

    /// @notice Sets information about specific token
    /// @dev It will set token ID, token name, maximum supply, and token type
    /// @param _tokenName Name of the token
    /// @param _maximumSupply The maximum supply for the token
    function addTokenInfo(string memory _tokenName, uint256 _maximumSupply) public onlyOwner {
        unchecked {
            maximumTokenSupply += _maximumSupply;
            totalToken++;
        }
        
        tokenCollections[totalToken] = TokenInfo({
            maximumTokenSupply: _maximumSupply,
            totalMintedTokenAmount: 0,
            tokenName: _tokenName,
            tokenId: totalToken
        });
    }

    /// @notice Update token maximum supply
    /// @dev This function can only be executed by the contract owner
    /// @param _tokenId Token ID
    /// @param _maximumTokenSupply Token new maximum supply
    function updateTokenSupply(uint256 _tokenId, uint256 _maximumTokenSupply) external onlyOwner validTokenId(_tokenId) {
        if (tokenCollections[_tokenId].totalMintedTokenAmount > _maximumTokenSupply) {
            revert InvalidInput();
        }
        tokenCollections[_tokenId].maximumTokenSupply = _maximumTokenSupply;
    }

    /// @notice Registers an address and sets a permission to mint
    /// @dev This function can only be executed by the contract owner
    /// @param _minter A valid ethereum address
    /// @param _flag The permission to mint. 'true' means allowed
    function setMinterAddress(address _minter, bool _flag) external onlyOwner validAddress(_minter) {
        minterList[_minter] = _flag;
    }

    /// @notice Registers an address and sets a permission to transfer
    /// @dev This function can only be executed by the contract owner
    /// @param _wallet A valid ethereum address
    /// @param _flag The permission to transfer. 'true' means allowed
    function setAllowedToTransfer(address _wallet, bool _flag) external onlyOwner validAddress(_wallet) {
        isAllowedToTransfer[_wallet] = _flag;
    }

    /// @notice This method is for activate/deactivate minting functionality
    /// @dev This function can only be executed by the contract owner
    /// @param _flag New minting status
    function setMintingStatus(bool _flag) external onlyOwner {
        isMintingActive = _flag;
    }

    /// @notice Mint token in batch
    /// @dev Only allowed minter address that could run this function
    /// @param _receiver The address that will receive the token
    /// @param _tokenIds The token ID that will be minted
    /// @param _amounts Amount of token that will be minted
    function mintBatch(
        address _receiver,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external nonReentrant onlyMinter validAddress(_receiver) mintingActive {
        if (_amounts.length != _tokenIds.length) {
            revert InvalidInput();
        }

        if (_amounts.length < 1) {
            revert InvalidInput();
        }

        for (uint256 index = 0; index < _tokenIds.length; index = _uncheckedInc(index)) {
            uint256 _tokenId = _tokenIds[index];

            if (_tokenId < 1 || _tokenId > totalToken) {
                revert InvalidTokenId();
            }

            if (_amounts[index] == 0) {
                revert ValueCanNotBeZero();
            }

            if (
                tokenCollections[_tokenId].totalMintedTokenAmount + _amounts[index] >
                tokenCollections[_tokenId].maximumTokenSupply
            ) {
                revert MintAmountForTokenTypeExceeded(_amounts[index]);
            }

            unchecked {
                tokenCollections[_tokenId].totalMintedTokenAmount += _amounts[index];
            }
        }

        _mintBatch(_receiver, _tokenIds, _amounts, "");
        
        emit BatchPixelmonTrainerGearMint(msg.sender, _receiver, _tokenIds, _amounts);
    }

    /// @notice Mint token
    /// @dev Only allowed minter address that could run this function
    /// @param _receiver The address that will receive the token
    /// @param _tokenId The token ID that will be minted
    /// @param _amount Amount of token that will be minted
    function mint(
        address _receiver,
        uint256 _tokenId,
        uint256 _amount
    )
        external
        nonReentrant
        onlyMinter
        validAddress(_receiver)
        validTokenId(_tokenId)
        mintingActive
    {

        if(_amount == 0) {
            revert ValueCanNotBeZero();
        }
        
        if (
            tokenCollections[_tokenId].totalMintedTokenAmount + _amount >
            tokenCollections[_tokenId].maximumTokenSupply
        ) {
            revert MintAmountForTokenTypeExceeded(_amount);
        }

        unchecked {
            tokenCollections[_tokenId].totalMintedTokenAmount += _amount;
        }

        _mint(_receiver, _tokenId, _amount, "");
        
        emit PixelmonTrainerGearMint(msg.sender, _receiver, _tokenId, _amount);
    }

    /// @notice Wallets that allowed to transfer only can use this method
    /// @dev See {IERC1155-safeTransferFrom}.
    /// @param from from address
    /// @param to receiver address 
    /// @param id tokenId to transfer
    /// @param amount token amount
    /// @param data custom data parameter during transfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override allowedToTransfer {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /// @notice Wallets that allowed to transfer only can use this method
    /// @dev See {IERC1155-safeBatchTransferFrom}.
    /// @param from from address
    /// @param to receiver address 
    /// @param ids tokenId list
    /// @param amounts token amounts
    /// @param data custom data parameter during transfer
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override allowedToTransfer {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// @notice Set base URL for storing off-chain information
    /// @param newuri A valid URL
    function setURI(string memory newuri) external onlyOwner {
        baseURI = newuri;
    }

    /// @notice Appends token ID to base URL
    /// @param _tokenId The token ID
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    }

    /// @notice Get information from specific token ID
    /// @param _tokenId Token ID
    function getTokenInfo(uint256 _tokenId) external view validTokenId(_tokenId) returns (TokenInfo memory tokenInfo) {
        tokenInfo = tokenCollections[_tokenId];
    }

    /// @dev Unchecked increment function, just to reduce gas usage
    /// @notice This value can not be greater than 1000
    /// @param _value value to be incremented, should not overflow 2**256 - 1
    /// @return incremented value
    function _uncheckedInc(uint256 _value) internal pure returns (uint256) {
        unchecked { return _value + 1; }
    }
}