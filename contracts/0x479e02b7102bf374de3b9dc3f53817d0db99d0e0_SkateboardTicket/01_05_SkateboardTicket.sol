// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

error NotAuctionHouseOrOwner();
error MaxSupplyReached();
error AuctionHouseNotSet();
error InvalidTokenOwner();

contract SkateboardTicket is Ownable, ERC721A {
    uint256 public constant MAX_SUPPLY = 9;

    // The auction house contract that will do all the minting
    address public auctionHouse;

    string private _baseTokenURI;

    mapping(uint256 => address) public redeemedTickets;

    constructor() ERC721A("SkateboardTicket", "SKATETICKET") {}

    /**
     * @notice Only allow the auction house contract or owner to mint.
     * Owner minting is needed for the final skateboard token which is
     * not part of the auction.
     */
    modifier onlyAuctionHouseOrOwner() {
        if (auctionHouse == address(0)) revert AuctionHouseNotSet();
        if (msg.sender != auctionHouse && msg.sender != owner()) {
            revert NotAuctionHouseOrOwner();
        }
        _;
    }

    function mint(address to) public onlyAuctionHouseOrOwner {
        if (_totalMinted() >= MAX_SUPPLY) revert MaxSupplyReached();
        _mint(to, 1);
    }

    function redeemTickets(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            if (ownerOf(tokenId) != msg.sender) {
                revert InvalidTokenOwner();
            }
            _burn(tokenId);
            redeemedTickets[tokenId] = msg.sender;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Get all redeemed ticket addresses.
     * @dev Useful for ethers client to get the entire array at once.
     */
    function getAllRedeemedTickets()
        external
        view
        returns (address[MAX_SUPPLY] memory)
    {
        return [
            redeemedTickets[0],
            redeemedTickets[1],
            redeemedTickets[2],
            redeemedTickets[3],
            redeemedTickets[4],
            redeemedTickets[5],
            redeemedTickets[6],
            redeemedTickets[7],
            redeemedTickets[8]
        ];
    }

    function setAuctionHouse(address _auctionHouse) external onlyOwner {
        auctionHouse = _auctionHouse;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}