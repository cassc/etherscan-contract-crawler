// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "@ensdomains/ens-contracts/contracts/registry/IReverseRegistrar.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IERC721Pool.sol";
import "./ERC20Wnft.sol";

/// @title ERC721Pool
/// @author Hifi

contract ERC721Pool is IERC721Pool, ERC20Wnft {
    using EnumerableSet for EnumerableSet.UintSet;

    /// PUBLIC STORAGE ///

    /// @inheritdoc IERC721Pool
    bool public poolFrozen;

    /// INTERNAL STORAGE ///

    /// @dev The asset token IDs held in the pool.
    EnumerableSet.UintSet internal holdings;

    /// CONSTRUCTOR ///

    constructor() ERC20Wnft() {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// MODIFIERS ///

    /// @notice Ensures that the pool is not frozen.
    modifier notFrozen() {
        if (poolFrozen) {
            revert ERC721Pool__PoolFrozen();
        }
        _;
    }

    /// @notice Ensures that the caller is the factory.
    modifier onlyFactory() {
        if (msg.sender != factory) {
            revert ERC721Pool__CallerNotFactory({ factory: factory, caller: msg.sender });
        }
        _;
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc IERC721Pool
    function holdingAt(uint256 index) external view override returns (uint256) {
        return holdings.at(index);
    }

    function holdingContains(uint256 id) external view override returns (bool) {
        return holdings.contains(id);
    }

    /// @inheritdoc IERC721Pool
    function holdingsLength() external view override returns (uint256) {
        return holdings.length();
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IERC721Pool
    function deposit(uint256 id, address beneficiary) external override notFrozen {
        // Checks: beneficiary is not zero address
        if (beneficiary == address(0)) {
            revert ERC721Pool__ZeroAddress();
        }
        // Checks: Add a NFT to the holdings.
        if (!holdings.add(id)) {
            revert ERC721Pool__NFTAlreadyInPool(id);
        }

        // Interactions: perform the Erc721 transfer from caller.
        IERC721(asset).transferFrom(msg.sender, address(this), id);

        // Effects: Mint an equivalent amount of pool tokens to the beneficiary.
        _mint(beneficiary, 10**18);

        emit Deposit(id, beneficiary, msg.sender);
    }

    /// @inheritdoc IERC721Pool
    function rescueLastNFT(address to) external override onlyFactory {
        // Checks: The pool must contain exactly one NFT.
        if (holdings.length() != 1) {
            revert ERC721Pool__MustContainExactlyOneNFT();
        }
        uint256 lastNFT = holdings.at(0);

        // Effects: Remove lastNFT from the holdings.
        holdings.remove(lastNFT);

        // Interactions: Transfer the NFT to the specified address.
        IERC721(asset).transferFrom(address(this), to, lastNFT);

        // Effects: Freeze the pool.
        poolFrozen = true;

        emit RescueLastNFT(lastNFT, to);
    }

    /// @inheritdoc IERC721Pool
    function setENSName(address registrar, string memory name) external override onlyFactory returns (bytes32) {
        bytes32 nodeHash = IReverseRegistrar(registrar).setName(name);
        return nodeHash;
    }

    /// @inheritdoc IERC721Pool
    function withdraw(uint256 id, address beneficiary) public override notFrozen {
        // Checks: Remove the NFT from the holdings.
        if (!holdings.remove(id)) {
            revert ERC721Pool__NFTNotFoundInPool(id);
        }

        // Effects: Burn an equivalent amount of pool token from the caller.
        // `msg.sender` is the caller of this function. Pool tokens are burnt from their account.
        _burn(msg.sender, 10**18);

        // Interactions: Perform the ERC721 transfer from the pool to the beneficiary address.
        IERC721(asset).transferFrom(address(this), beneficiary, id);

        emit Withdraw(id, beneficiary, msg.sender);
    }
}