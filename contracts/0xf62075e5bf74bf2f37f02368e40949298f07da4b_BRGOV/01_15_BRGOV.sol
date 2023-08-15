// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract BRGOV is ERC1155Upgradeable, AccessControlUpgradeable {
    uint256 public constant MAX_BRGOV_TOKENID_ONE = 1 * 10 ** 12; // 1 - 1,000,000,000,000
    uint256 public constant MAX_BRGOV_TOKENID_TEN = 2 * 10 ** 12; // 1,000,000,000,001 - 2,000,000,000,000
    uint256 public constant MAX_BRGOV_TOKENID_HUNDRED = 3 * 10 ** 12; // 2,000,000,000,001 - 3,000,000,000,000
    uint8 public constant MULTIPLIER_ONE = 1;
    uint8 public constant MULTIPLIER_TEN = 10;
    uint8 public constant MULTIPLIER_HUNDRED = 100;

    enum TokenType {
        BTREE,
        WBTC
    }
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct ERC20TOKEN {
        uint256 mintPrice; // Mint price in wei
        IERC20 erc20Contract;
        address treasuryAddress;
    }

    string public baseURI;

    // three different NFT types 1, 10, 100
    CountersUpgradeable.Counter private _tokenIds;
    CountersUpgradeable.Counter private _tokenTenIds;
    CountersUpgradeable.Counter private _tokenHundredIds;

    mapping(TokenType => ERC20TOKEN) public tokens;

    event PriceUpdated(
        TokenType indexed tokenType,
        uint256 indexed oldValue,
        uint256 indexed newValue
    );

    event ERC20ContractUpdated(
        TokenType indexed tokenType,
        IERC20 indexed oldAddress,
        IERC20 indexed newAddress
    );

    event TreasuryAddressUpdated(
        TokenType indexed tokenType,
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        baseURI = "ipfs://QmXj39Ukat3Tx9BMsQSb4B78vtyZufQmLcdMcspjvYBWYB/";

        tokens[TokenType.BTREE].mintPrice = 1000 ether;
        tokens[TokenType.BTREE].erc20Contract = IERC20(
            0x6bDdE71Cf0C751EB6d5EdB8418e43D3d9427e436
        ); // mainnet
        tokens[TokenType.BTREE]
            .treasuryAddress = 0x2F8f86e6E1Ff118861BEB7E583DE90f0449A264f;

        tokens[TokenType.WBTC].mintPrice = 100000; // 0.001 * (10 ** 8)
        tokens[TokenType.WBTC].erc20Contract = IERC20(
            0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
        ); // mainnet WBTC - https://wbtc.network/
        tokens[TokenType.WBTC]
            .treasuryAddress = 0x2F8f86e6E1Ff118861BEB7E583DE90f0449A264f;

        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function uri(
        uint256 tokenID
    ) public view virtual override returns (string memory) {
        if (tokenID <= MAX_BRGOV_TOKENID_ONE) {
            return string.concat(baseURI, "1");
        }
        if (tokenID <= MAX_BRGOV_TOKENID_TEN) {
            return string.concat(baseURI, "10");
        }
        if (tokenID <= MAX_BRGOV_TOKENID_HUNDRED) {
            return string.concat(baseURI, "100");
        }
        return "";
    }

    function setBaseURI(
        string memory _newBaseURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
    }

    function mintPrice(TokenType _tokenType) external view returns (uint256) {
        return tokens[_tokenType].mintPrice;
    }

    function setMintPrice(
        TokenType _tokenType,
        uint256 _newPrice
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Mint price in wei
        emit PriceUpdated(_tokenType, tokens[_tokenType].mintPrice, _newPrice);
        tokens[_tokenType].mintPrice = _newPrice;
    }

    function erc20Contract(
        TokenType _tokenType
    ) external view returns (IERC20) {
        return tokens[_tokenType].erc20Contract;
    }

    function setERC20Contract(
        TokenType _tokenType,
        IERC20 _erc20Contract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit ERC20ContractUpdated(
            _tokenType,
            tokens[_tokenType].erc20Contract,
            _erc20Contract
        );
        tokens[_tokenType].erc20Contract = _erc20Contract;
    }

    function treasuryAddress(
        TokenType _tokenType
    ) external view returns (address) {
        return tokens[_tokenType].treasuryAddress;
    }

    function setTreasuryAddress(
        TokenType _tokenType,
        address _treasuryAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit TreasuryAddressUpdated(
            _tokenType,
            tokens[_tokenType].treasuryAddress,
            _treasuryAddress
        );
        tokens[_tokenType].treasuryAddress = _treasuryAddress;
    }

    function _mintHelper(
        TokenType _tokenType,
        uint256 tokenIdBase,
        uint8 mintPriceMultiplier,
        address to,
        uint256 mintCount
    ) internal {
        require(
            tokens[_tokenType].treasuryAddress != address(0),
            "treasury address not set"
        );

        require(
            tokens[_tokenType].erc20Contract != IERC20(address(0)),
            "erc20 contract not set"
        );
        uint256 _balance = IERC20(tokens[_tokenType].erc20Contract).balanceOf(
            to
        );

        uint256 _totalPrice = tokens[_tokenType].mintPrice *
            mintCount *
            mintPriceMultiplier;
        require(_totalPrice <= _balance, "not enough erc20 funds sent");

        require(
            tokens[_tokenType].erc20Contract.allowance(to, address(this)) >=
                _totalPrice,
            "Insufficient allowance"
        );
        bool successfulTransfer = IERC20(tokens[_tokenType].erc20Contract)
            .transferFrom(to, tokens[_tokenType].treasuryAddress, _totalPrice);
        require(successfulTransfer, "Unable to transfer erc20 to treasury");

        for (uint256 i = 0; i < mintCount; i++) {
            uint256 newItemId;
            if (tokenIdBase == 0) {
                // increment denomination 1 counter
                _tokenIds.increment();
                newItemId = tokenIdBase + _tokenIds.current();
            }
            if (tokenIdBase == MAX_BRGOV_TOKENID_ONE) {
                // increment denomination 10 counter
                _tokenTenIds.increment();
                newItemId = tokenIdBase + _tokenTenIds.current();
            }
            if (tokenIdBase == MAX_BRGOV_TOKENID_TEN) {
                // increment denomination 100 counter
                _tokenHundredIds.increment();
                newItemId = tokenIdBase + _tokenHundredIds.current();
            }
            _mint(to, newItemId, 1, "");
        }
    }

    function mint(
        TokenType _tokenType,
        address to,
        uint256 mintCount
    ) external {
        _mintHelper(_tokenType, 0, MULTIPLIER_ONE, to, mintCount);
    }

    function mintTen(
        TokenType _tokenType,
        address to,
        uint256 mintCount
    ) external {
        _mintHelper(
            _tokenType,
            MAX_BRGOV_TOKENID_ONE,
            MULTIPLIER_TEN,
            to,
            mintCount
        );
    }

    function mintHundred(
        TokenType _tokenType,
        address to,
        uint256 mintCount
    ) external {
        _mintHelper(
            _tokenType,
            MAX_BRGOV_TOKENID_TEN,
            MULTIPLIER_HUNDRED,
            to,
            mintCount
        );
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: _balance}("");
        require(success, "Unable to withdraw");
    }
}