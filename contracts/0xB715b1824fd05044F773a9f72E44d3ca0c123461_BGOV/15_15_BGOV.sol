// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Contract by Bittrees, Inc

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

contract BGOV is ERC1155Upgradeable, AccessControlUpgradeable {
    enum TokenType {
        BTREE
    }
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct ERC20TOKEN {
        uint256 mintPrice; // Mint price in wei
        IERC20 erc20Contract;
        address treasuryAddress;
    }

    CountersUpgradeable.Counter private _tokenIds;

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
        tokens[TokenType.BTREE].mintPrice = 1000 ether;
        tokens[TokenType.BTREE].erc20Contract = IERC20(
            0x6bDdE71Cf0C751EB6d5EdB8418e43D3d9427e436
        ); // mainnet
        tokens[TokenType.BTREE]
            .treasuryAddress = 0x7435e7f3e6B5c656c33889a3d5EaFE1e17C033CD;

        __ERC1155_init(
            "ipfs://QmczE3Dn8MMYszGQG2RqPJzY6c4dcuEUQR4FPCFAK3Ckyo/1"
        );
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

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
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

    function mint(
        TokenType _tokenType,
        address to,
        uint256 mintCount
    ) external {
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

        uint256 _totalPrice = tokens[_tokenType].mintPrice * mintCount;
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
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(to, newItemId, 1, "");
        }
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: _balance}("");
        require(success, "Unable to withdraw");
    }
}