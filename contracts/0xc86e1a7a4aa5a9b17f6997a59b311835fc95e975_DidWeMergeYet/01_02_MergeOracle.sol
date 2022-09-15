// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "solmate/tokens/ERC721.sol";

IMergeOracle constant ADDRESS = IMergeOracle(0xD6a6f0D7f08c2D31455a210546F85DdfF1D9030a);

interface IMergeOracle {
    /// Returns the earliest block on which we know the merge was already active.
    function mergeBlock() external view returns (uint256);

    /// Returns the timestamp of the recorded block.
    function mergeTimestamp() external view returns (uint256);
}

contract MergeOracle is IMergeOracle {
    uint256 public immutable override mergeBlock = block.number;
    uint256 public immutable override mergeTimestamp = block.timestamp;
}

/// How to use this?
///
/// The `oracle` address is pre-calculated, but the account will be empty until the
/// merge takes place.
///
/// If you are interested to check if the merge took place, it is enough to check if the
/// oracle address has code in it. This can be achieved by `require(ADDRESS.code.length != 0);`.
///
/// If you also need to know what (a potential) merge block is, the oracle needs to be called
/// and ensured that a non-zero value is returned: `require(ADDRESS.mergeBlock() != 0);`
contract DidWeMergeYet is ERC721 {
    /// The merge is not here yet.
    error No();

    /// Merge already recorded.
    error AlreadyTrigerred();

    IMergeOracle public immutable oracle;

    constructor() ERC721("Merge Oracle Triggerer", "MOT") {
        oracle = MergeOracle(calculateCreate(address(this), 1));
        // Ensure we arrived at the correct value.
        assert(oracle == ADDRESS);
    }

    function trigger() external returns (IMergeOracle _oracle) {
        // Based on EIP-4399 and the Beacon Chain specs, the mixHash field should be greater than 2**64.
        //
        // However 
        // Since difficulty values around 
        if (block.difficulty <= type(uint64).max) {
            revert No();
        }

        if (address(oracle).code.length != 0) {
            revert AlreadyTrigerred();
        }

        _oracle = new MergeOracle();
        assert(_oracle == oracle);

        _mint(msg.sender, 1);
    }

    function calculateCreate(address from, uint256 nonce) private pure returns (address) {
        assert(nonce <= 127);
        bytes memory data =
            bytes.concat(hex"d694", bytes20(uint160(from)), nonce == 0 ? bytes1(hex"80") : bytes1(uint8(nonce)));
        return address(uint160(uint256(keccak256(data)))); // Take the lower 160-bits
    }

    function tokenURI(uint256 /*id*/) public pure override returns (string memory) {
        return "ipfs://QmcnZk7CrAeS2NcY62FUcoH9knbTS1HK8mdYbshwF1S8kh";
    }
}