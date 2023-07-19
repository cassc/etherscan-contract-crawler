// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./ERC721Pool.sol";
import "./IERC721PoolFactory.sol";

/// @title ERC721PoolFactory
/// @author Hifi
contract ERC721PoolFactory is IERC721PoolFactory, Ownable {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IERC721PoolFactory
    mapping(address => address) public override getPool;

    /// @inheritdoc IERC721PoolFactory
    address[] public allPools;

    /// @inheritdoc IERC721PoolFactory
    mapping(address => uint256) public override assetNonces;

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc IERC721PoolFactory
    function allPoolsLength() external view override returns (uint256) {
        return allPools.length;
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IERC721PoolFactory
    function createPool(address asset) external override {
        if (!IERC165(asset).supportsInterface(type(IERC721Metadata).interfaceId)) {
            revert ERC721PoolFactory__DoesNotImplementIERC721Metadata();
        }

        address existingPool = getPool[asset];
        if (existingPool != address(0)) {
            revert ERC721PoolFactory__PoolAlreadyExists();
        }

        string memory name = string.concat(IERC721Metadata(asset).name(), " Pool");
        string memory symbol = string.concat(IERC721Metadata(asset).symbol(), "p");

        bytes32 salt = keccak256(abi.encodePacked(asset, assetNonces[asset]));
        ERC721Pool pool = new ERC721Pool{ salt: salt }();
        pool.initialize(name, symbol, asset);

        getPool[asset] = address(pool);
        allPools.push(address(pool));
        assetNonces[asset]++;

        emit CreatePool(name, symbol, asset, address(pool));
    }

    /// @inheritdoc IERC721PoolFactory
    function rescueLastNFT(address asset, address to) external override onlyOwner {
        address poolAddress = getPool[asset];
        if (poolAddress == address(0)) {
            revert ERC721PoolFactory__PoolDoesNotExist();
        }
        if (to == address(0)) {
            revert ERC721PoolFactory__RecipientZeroAddress();
        }
        ERC721Pool pool = ERC721Pool(poolAddress);
        pool.rescueLastNFT(to);
        delete getPool[asset];
    }

    /// @inheritdoc IERC721PoolFactory
    function setENSName(
        address asset,
        address registrar,
        string memory name
    ) external override onlyOwner {
        if (getPool[asset] == address(0)) {
            revert ERC721PoolFactory__PoolDoesNotExist();
        }
        if (registrar == address(0)) {
            revert ERC721PoolFactory__RegistrarZeroAddress();
        }
        ERC721Pool pool = ERC721Pool(getPool[asset]);
        pool.setENSName(registrar, name);
        emit ENSNameSet(address(pool), name);
    }
}