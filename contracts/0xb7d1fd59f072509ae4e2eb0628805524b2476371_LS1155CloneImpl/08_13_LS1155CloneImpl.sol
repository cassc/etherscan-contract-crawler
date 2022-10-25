// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {Base64} from "solady/utils/Base64.sol";

import {LiquidSplitCloneImpl} from "src/CloneImpl/LiquidSplitCloneImpl.sol";
import {Renderer} from "src/libs/Renderer.sol";
import {utils} from "src/libs/Utils.sol";

/// @title 1155LiquidSplit
/// @author 0xSplits
/// @notice A minimal liquid split implementation designed to be used as part of a
/// clones-with-immutable-args implementation.
/// Ownership in a split is represented by 1155s (each = 0.1% of split)
/// @dev This contract uses token = address(0) to refer to ETH.
contract LS1155CloneImpl is Owned, LiquidSplitCloneImpl, ERC1155 {
    /// -----------------------------------------------------------------------
    /// errors
    /// -----------------------------------------------------------------------

    /// Unauthorized msg.sender
    error Unauthorized();

    /// Array lengths of accounts & percentAllocations don't match (`accountsLength` != `allocationsLength`)
    /// @param accountsLength Length of accounts array
    /// @param allocationsLength Length of percentAllocations array
    error InvalidLiquidSplit__AccountsAndAllocationsMismatch(uint256 accountsLength, uint256 allocationsLength);

    /// Invalid initAllocations sum `allocationsSum` must equal `TOTAL_SUPPLY`
    /// @param allocationsSum Sum of percentAllocations array
    error InvalidLiquidSplit__InvalidAllocationsSum(uint32 allocationsSum);

    /// -----------------------------------------------------------------------
    /// libraries
    /// -----------------------------------------------------------------------

    using LibString for uint256;

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    uint256 internal constant TOKEN_ID = 0;
    uint256 public constant TOTAL_SUPPLY = 1e3;
    uint256 public constant SUPPLY_TO_PERCENTAGE = 1e3; // = PERCENTAGE_SCALE / TOTAL_SUPPLY = 1e6 / 1e3

    /// -----------------------------------------------------------------------
    /// storage - cwia
    /// -----------------------------------------------------------------------

    // first item is uint32 distributorFee in LiquidSplitCloneImpl
    // 4; second item
    uint256 internal constant MINTED_ON_TIMESTAMP_OFFSET = 4;

    /// @dev equivalent to uint256 public immutable mintedOnTimestamp;
    function mintedOnTimestamp() public pure returns (uint256) {
        return _getArgUint256(MINTED_ON_TIMESTAMP_OFFSET);
    }

    /// -----------------------------------------------------------------------
    /// constructor & initializer
    /// -----------------------------------------------------------------------

    /// only run when implementation is deployed
    constructor(address _splitMain) Owned(address(0)) LiquidSplitCloneImpl(_splitMain) {}

    /// initializes each clone
    function initializer(address[] calldata accounts, uint32[] calldata initAllocations, address _owner) external {
        /// checks

        // only liquidSplitFactory may call `initializer`
        if (msg.sender != liquidSplitFactory) {
            revert Unauthorized();
        }

        if (accounts.length != initAllocations.length) {
            revert InvalidLiquidSplit__AccountsAndAllocationsMismatch(accounts.length, initAllocations.length);
        }

        {
            uint32 sum = _getSum(initAllocations);
            if (sum != TOTAL_SUPPLY) {
                revert InvalidLiquidSplit__InvalidAllocationsSum(sum);
            }
        }

        /// effects

        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);

        LiquidSplitCloneImpl.initializer();

        /// interactions

        // mint NFTs to initial holders
        uint256 numAccs = accounts.length;
        unchecked {
            for (uint256 i; i < numAccs; ++i) {
                _mint({to: accounts[i], id: TOKEN_ID, amount: initAllocations[i], data: ""});
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external - view & pure
    /// -----------------------------------------------------------------------

    function scaledPercentBalanceOf(address account) public view override returns (uint32) {
        unchecked {
            // can't overflow;
            // sum(balanceOf) == TOTAL_SUPPLY = 1e3
            // SUPPLY_TO_PERCENTAGE = 1e6 / 1e3 = 1e3
            // =>
            // sum(balanceOf[i] * SUPPLY_TO_PERCENTAGE) == PERCENTAGE_SCALE = 1e6 << 2^32)
            return uint32(balanceOf[account][TOKEN_ID] * SUPPLY_TO_PERCENTAGE);
        }
    }

    function name() external view returns (string memory) {
        return string.concat("Liquid Split ", utils.shortAddressToString(address(this)));
    }

    function uri(uint256) public view override returns (string memory) {
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name": "Liquid Split ',
                        utils.shortAddressToString(address(this)),
                        '", "description": ',
                        '"Each token represents 0.1% of this Liquid Split.", ',
                        '"external_url": ',
                        '"https://app.0xsplits.xyz/accounts/',
                        utils.addressToString(address(this)),
                        "/?chainId=",
                        utils.uint2str(block.chainid),
                        '", ',
                        '"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(Renderer.render(address(this)))),
                        '"}'
                    )
                )
            )
        );
    }

    /// -----------------------------------------------------------------------
    /// functions - private & internal
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - private & internal - pure
    /// -----------------------------------------------------------------------

    /// Sums array of uint32s
    /// @param numbers Array of uint32s to sum
    /// @return sum Sum of `numbers`
    function _getSum(uint32[] calldata numbers) internal pure returns (uint32 sum) {
        uint256 numbersLength = numbers.length;
        for (uint256 i; i < numbersLength;) {
            sum += numbers[i];
            unchecked {
                // overflow should be impossible in for-loop index
                ++i;
            }
        }
    }
}