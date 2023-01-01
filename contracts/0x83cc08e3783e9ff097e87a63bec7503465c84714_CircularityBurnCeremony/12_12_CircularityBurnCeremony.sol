// SPDX-License-Identifier: MIT
// Contract by Will Papper <https://twitter.com/WillPapper>
// This contract is not audited!

pragma solidity 0.8.15;

import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {BokkyPooBahsDateTimeLibrary} from "../lib/BokkyPooBahsDateTimeLibrary/contracts/BokkyPooBahsDateTimeLibrary.sol";

contract CircularityBurnCeremony is ERC721 {
    using Strings for uint256;

    uint256 public currentId;

    address public constant ARTIST_ADDRESS =
        0x29b18dFc73C410A98078753c4e718Ca317bC71D5;

    // We want the January Burn Ceremony NFT to be minted when January ends. As
    // a result, we'll use January 31st 2023 as the start timestamp to ensure
    // that February 2023 is eligible for a mint
    // UNIX timestamp for Tue Jan 31 2023 23:59:59 GMT+0000
    uint256 public constant CIRCULARITY_START_TIMESTAMP = 1675209599;

    constructor() ERC721("Circularity - Burn Ceremony", "CBC") {}

    function mint(uint256 amount) public {
        // Checks
        require(amount != 0, "Amount cannot be 0");
        require(
            amount <= amountEligibleToMint(),
            "Amount exceeds amount eligible"
        );

        for (uint256 i = 0; i < amount; ) {
            // Effects

            // Won't overflow without running out of gas long before then
            unchecked {
                ++i;
            }

            // Interactions
            _mint(ARTIST_ADDRESS, currentId + i);
        }

        // Update currentId at the end instead of in the loop to save gas
        currentId = currentId + amount;
    }

    function amountEligibleToMint() public view returns (uint256) {
        uint256 monthsSinceStart = BokkyPooBahsDateTimeLibrary.diffMonths(
            CIRCULARITY_START_TIMESTAMP,
            block.timestamp
        );
        return monthsSinceStart - currentId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();

        // December is 12 % 12, so December is 0. Everything else is 1 (January)
        // through 11 (November).
        string memory tokenIdString = (tokenId % 12).toString();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenIdString))
                : "";
    }

    // ID 0 is December
    // ID 1 through 11 is January through November
    function _baseURI() internal pure override returns (string memory) {
        return
            "ar://KPR1gXzI5LBSzRaWf-6OWjUxU2q__NtZLou6b7xUBpE/Circularity-Burn-Ceremony-NFT-Metadata/";
    }
}