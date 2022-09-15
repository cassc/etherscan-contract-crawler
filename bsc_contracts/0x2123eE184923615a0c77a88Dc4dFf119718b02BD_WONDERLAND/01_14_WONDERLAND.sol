// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ReEntrancyGuard.sol";
import "./Secutiry/SoftAdministered.sol";

contract WONDERLAND is SoftAdministered, ERC721A, ReEntrancyGuard {
    using Address for address;

    // Starting and stopping sale, presale and whitelist
    bool public saleActive = false;

    // Price of each token
    uint256 public price;

    // Maximum limit of tokens that can ever exist
    uint256 public MAX_SUPPLY = 0;
    uint256 public MAX_MINT_PER_TX = 20;
    // The base link that leads to the image / video of the token
    string public baseTokenURI = "#";

    /// DEV CONTRACT: 0xDffCAA553f6404674daf51Ac60762A1993813920
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) ERC721A(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
    }

    // @dev  Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // @dev  Admin minting function to reserve tokens for the team, collabs, customs and giveaways
    function mintReserved(address _address, uint256 _amount)
        external
        onlyUserOrOwner
        noReentrant
    {
        uint256 supply = totalSupply();
        uint256 _MAX_MINT_PER_TX = MAX_MINT_PER_TX;
        uint256 _MAX_SUPPLY = MAX_SUPPLY;
        bool _saleActive = saleActive;

        require(_saleActive, "Sale isn't active");

        require(
            (_amount > 0) && (_amount <= _MAX_MINT_PER_TX),
            "Can only mint between 1 and 10 tokens at once"
        );
        require(
            supply + _amount <= _MAX_SUPPLY,
            "Can't mint more than max supply"
        );

        _safeMint(_address, _amount);
    }

    // @dev Returns the tokenIds of the address. O(totalSupply) in complexity.
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256[] memory a = new uint256[](balanceOf(owner));
            uint256 end = _currentIndex;
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            for (uint256 i; i < end; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    a[tokenIdsIdx++] = i;
                }
            }
            return a;
        }
    }

    // @dev Start and stop sale
    function setSaleActive(bool val) external onlyOwner {
        saleActive = val;
    }

    // @dev Set new baseURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    // @dev Set a different price in case MATIC  changes drastically
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }
}