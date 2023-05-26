// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721.sol";

/// @notice Thrown when contract functions called by unauthorized address
error NotWhitelisted();

/// @notice Thrown when limit of minted tokens in range reached
error MintAmountExceeded();

/// @notice Thrown in airdrop function when array of receiver is invalid
error InvalidInputArrayLength();

contract PixelmonTrainer is ERC721, Ownable {
    /// @dev Total 10020 tokens supply divided in 3 ranges:
    /// Range 1 - Pixelmon staking rewards, ids [1, 10000]
    /// Range 2 - gold trainers, ids [10001, 10020]
    uint256 public constant FIRST_RANGE_MAX_SUPPLY = 10000;
    uint256 public constant SECOND_RANGE_MAX_SUPPLY = 20;

    /// @notice Supply variables shows how much tokens minted in each range, also used as tokenId counter
    uint256 public firstRangeSupply = 0;
    uint256 public secondRangeSupply = 0;

    /// @notice Token metadata base URI
    string public baseURI;

    /// @notice Whitelisted address can call functions marked with onlyWhitelisted modifier
    mapping(address => bool) private whitelist;

    event SetBaseURI(string _baseURI);
    event WhitelistAddress(address indexed _address, bool _whitelisted);
    event Mint(address indexed _to, uint256 indexed _tokenId);

    modifier onlyWhitelisted() {
        if (!whitelist[msg.sender]) {
            revert NotWhitelisted();
        }
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) ERC721(_name, _symbol) {
        baseURI = _baseTokenURI;
    }

    /// @notice Add/remove address to/from whitelist. Callable only by contract owner
    /// @param _address user or contract address
    /// @param _flag true - add user to whitelist, false - remove from whitelist
    function whitelistAddress(address _address, bool _flag) external onlyOwner {
        whitelist[_address] = _flag;

        emit WhitelistAddress(_address, _flag);
    }

    /// @notice Set base URI for tokens metadata. Callable only by contract owner
    /// @param _baseTokenURI base URI to metadata
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;

        emit SetBaseURI(_baseTokenURI);
    }

    /// @notice Mint new tokens to address from range #1 [1, 10000]. Callable only by whitelisted addresses
    /// @dev Minting process uses incremental token ids, starting from 1
    /// @param _to receiver address
    /// @param _tokensAmount amount of tokens
    function mintRangeOne(address _to, uint256 _tokensAmount) external onlyWhitelisted {
        if (firstRangeSupply + _tokensAmount > FIRST_RANGE_MAX_SUPPLY) {
            revert MintAmountExceeded();
        }

        uint256 mintStartId = firstRangeSupply + 1;

        _mintTokens(_to, mintStartId, _tokensAmount);

        unchecked {
            firstRangeSupply += _tokensAmount;
        }
    }

    /// @notice Airdrop gold trainer tokens to list of addresses. Callable by contract owner and only once
    /// @dev token ids range #2 - [10001, 10020]
    /// @param _to receivers array
    function airdropGoldTrainers(address[] calldata _to) external onlyOwner {
        if (secondRangeSupply == SECOND_RANGE_MAX_SUPPLY) {
            revert MintAmountExceeded();
        }

        if (_to.length != SECOND_RANGE_MAX_SUPPLY) {
            revert InvalidInputArrayLength();
        }

        uint256 secondRangeTokenId = FIRST_RANGE_MAX_SUPPLY + 1;

        for (uint256 i = 0; i < _to.length; i = _uncheckedInc(i)) {
            _mint(_to[i], secondRangeTokenId);
            emit Mint(_to[i], secondRangeTokenId);

            unchecked {
                ++secondRangeTokenId;
            }
        }

        unchecked {
            secondRangeSupply += SECOND_RANGE_MAX_SUPPLY;
        }
    }

    /// @notice Returns true if wallet in whitelist, otherwise false
    /// @return bool
    function isWhitelisted(address _address) external view returns (bool) {
        return whitelist[_address];
    }

    /// @notice Get total supply of trainers NFT
    /// @return NFT total supply
    function totalSupply() external view returns (uint256) {
        return firstRangeSupply + secondRangeSupply;
    }

    /// @notice Private helper functions to mint tokens
    /// @dev Uses batch minting if _tokensAmount > 1
    /// @param _to receiver address
    /// @param _mintStartId starting tokens id
    /// @param _tokensAmount amount of tokens to mint
    function _mintTokens(
        address _to,
        uint256 _mintStartId,
        uint256 _tokensAmount
    ) private {
        if (_tokensAmount > 1) {
            _mintBatch(_to, _mintStartId, _tokensAmount);
        } else {
            _mint(_to, _mintStartId);

            emit Mint(_to, _mintStartId);
        }
    }

    /// @dev Overrides same function from OpenZeppelin ERC721, used in tokenURI function
    /// @return token base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @dev Unchecked increment function, just to reduce gas usage
    /// @param val value to be incremented, should not overflow 2**256 - 1
    /// @return incremented value
    function _uncheckedInc(uint256 val) internal pure returns (uint256) {
        unchecked {
            return val + 1;
        }
    }
}