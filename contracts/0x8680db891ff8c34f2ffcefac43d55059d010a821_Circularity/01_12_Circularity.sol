// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {BokkyPooBahsDateTimeLibrary} from "../lib/BokkyPooBahsDateTimeLibrary/contracts/BokkyPooBahsDateTimeLibrary.sol";

contract Circularity is ERC721 {
    // Keep track of the last month and year the burn function was triggered
    uint256 public contractMonth;
    uint256 public contractYear;
    // Use a zero-indexed array of 13 elements. This allows us to use 1-indexed
    // months as-is.  Difference in gas usage is negligible so we'll strive for
    // simplicity here.
    // owners[0] is unused and automatically initialized to address(0)
    address[13] public owners;

    // UNIX timestamp for Mon Jan 09 2023 00:00:00 GMT+0000
    // The initialize() function **must** be called after this date but before
    // the end of January 2023
    uint256 public constant CIRCULARITY_INITIALIZE_TIMESTAMP = 1673222400;

    address public constant ARTIST_ADDRESS =
        0x29b18dFc73C410A98078753c4e718Ca317bC71D5;

    constructor() ERC721("Circularity", "CIRC") {
        for (uint256 i = 1; i <= 12; ) {
            _mint(ARTIST_ADDRESS, i);
            // We're only minting 12 NFTs so this won't overflow
            unchecked {
                ++i;
            }
        }
    }

    function initialize() public {
        // This avoids needing to track a separate initialized variable
        // Only one NFT will exist at a time post-initialization, so checking
        // for the existence of multiple NFTs is sufficient. We could check all
        // 12, but we only check a subset to save gas (especially since this
        // function becomes completely inoperable after January 2023)
        require(
            _exists(1) && _exists(2) && _exists(3) && _exists(12),
            "Already initialized"
        );
        // Comparing against `block.timestamp` saves us an SLOAD
        require(
            block.timestamp >= CIRCULARITY_INITIALIZE_TIMESTAMP,
            "Not Jan 9 2023 yet"
        );
        // We want to avoid the possibility of calling initialize() after
        // January 2023
        // UNIX timestamp for Wed Feb 01 2023 00:00:00 GMT+0000
        require(block.timestamp < 1675209600, "Too late to initialize");

        // Record the owner of the January NFT
        owners[1] = ownerOf(1);

        // Burn the NFTs for February through December
        for (uint256 i = 2; i <= 12; ) {
            owners[i] = ownerOf(i);
            _burn(i);
            // We're only burning 11 NFTs so this won't overflow
            unchecked {
                ++i;
            }
        }

        // We know that we're calling this in January 2023
        contractMonth = 1;
        contractYear = 2023;
    }

    function burn() public {
        uint256 blockMonth = BokkyPooBahsDateTimeLibrary.getMonth(
            block.timestamp
        );
        uint256 blockYear = BokkyPooBahsDateTimeLibrary.getYear(
            block.timestamp
        );
        require(
            blockMonth != contractMonth || blockYear != contractYear,
            "Already burned this month"
        );
        // We only need to burn and mint if we're in a new month
        if (blockMonth != contractMonth) {
            owners[contractMonth] = ownerOf(contractMonth);

            _burn(contractMonth);
            _mint(owners[blockMonth], blockMonth);

            contractMonth = blockMonth;
        }
        // If we're in a new year, we need to update the year too. This happens
        // regardless of whether we're in a new month
        if (blockYear != contractYear) {
            contractYear = blockYear;
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "ar://XscXGj-2F1_ZAyzrQPAqKqPFniC9lYrVaWcxDn_Ti8c/Circularity-NFT-Metadata/";
    }
}