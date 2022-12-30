// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Secutiry/SoftAdministered.sol";

contract MEST is SoftAdministered, ERC721A, ReentrancyGuard {
    using Address for address;

    // Starting and stopping sale, presale and whitelist
    bool public saleActive = true;

    // Maximum limit of tokens that can ever exist
    uint256 public MAX_SUPPLY = 0;

    // The base link that leads to the image / video of the token
    string public baseTokenURI = "#";

    // Price of each token
    uint256 public initial_price = 0.001 ether;
    uint256 public price;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        string memory _baseTokenURI
    ) ERC721A(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
        baseTokenURI = _baseTokenURI;
        price = initial_price;
    }

    // Standard mint function
    function mintToken(uint256 _amount) public payable {
        uint256 supply = totalSupply();

        require(saleActive, "Sale isn't active");

        require(
            supply + _amount <= MAX_SUPPLY,
            "Can't mint more than max supply"
        );
        require(msg.value == price * _amount, "Wrong amount of ETH sent");

        /// @dev Minting
        _safeMint(_msgSender(), _amount);
    }

    // @dev  Admin minting function to reserve tokens for the team, collabs, customs and giveaways
    function mintReserved(
        address _address,
        uint256 _amount
    ) external onlyUserOrOwner nonReentrant {
        uint256 supply = totalSupply();
        uint256 _MAX_SUPPLY = MAX_SUPPLY;

        require(
            supply + _amount <= _MAX_SUPPLY,
            "Can't mint more than max supply"
        );

        /// @dev Minting
        _safeMint(_address, _amount);
    }

    // @dev  Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Returns the tokenIds of the address. O(totalSupply) in complexity.
    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory) {
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

    /// @dev Start and stop sale
    function setSaleActive(bool val) external onlyOwner {
        saleActive = val;
    }

    /// @dev Set new baseURI
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseTokenURI = _baseURI;
    }

    /// Withdraw funds from contract for the team
    function withdraw(address _addr, uint256 _amount) public payable onlyOwner {
        require(payable(_addr).send(_amount));
    }
}