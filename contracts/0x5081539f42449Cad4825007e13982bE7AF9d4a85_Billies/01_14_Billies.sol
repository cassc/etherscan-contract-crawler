// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

/// @dev Administered
import "./SoftAdministered.sol";
import "./ClaimFactory.sol";

contract Billies is ReentrancyGuard, SoftAdministered, ClaimFactory, ERC721A {
    using Address for address;

    // Starting and stopping sale, presale and whitelist
    bool public saleActive = false;
    bool public reserveActive = false;

    // Price of each token
    uint256 public initial_price = 0.001 ether;
    uint256 public price;

    // Maximum limit of tokens that can ever exist
    uint256 public constant MAX_SUPPLY = 10000;

    // The base link that leads to the image / video of the token
    string public baseTokenURI ="#";

    constructor() ERC721A("Billies", "BS") {
        price = initial_price;
    }

    /**
     * @dev Mint tokens
     */
    function mintToken(uint256 _amount) external payable nonReentrant {
        uint256 supply = totalSupply();

        require(saleActive, "Sale isn't active");

        require(
            supply + _amount <= MAX_SUPPLY,
            "Can't mint more than max supply"
        );
        require(msg.value >= price * _amount, "Wrong amount of ETH sent");

        /// @dev Mint tokens
        _safeMint(_msgSender(), _amount);
    }

    /**
     * @dev Mint reserved tokens
     */
    function mintReserved(
        address _address,
        uint256 _amount
    ) external onlyUserOrOwner {
        _mintReserved(_address, _amount);
    }

    /**
     * @dev Claim NFTs
     */
    function claimNft(string memory _code) external nonReentrant {
        /// @dev check if the NFTs is already created
        StructClaim memory clain = _claim[_code];

        /// @dev check if the NFTs is already created
        require(clain.withdrawal, "Mint NFTs already removed");

        /// @dev send the NFTs to the user
        _mintReserved(_msgSender(), clain.amountNft);

        /// @dev update the status of the NFTs
        _claim[_code] = StructClaim(_msgSender(), 0, block.timestamp, false);
    }

    /**
     * @dev Mint reserved tokens
     */
    function _mintReserved(address _address, uint256 _amount) internal {
        uint256 supply = totalSupply();

        require(reserveActive, "Sale isn't active");

        require(
            supply + _amount <= MAX_SUPPLY,
            "Can't mint more than max supply"
        );

        /// @dev Mint reserved tokens
        _safeMint(_address, _amount);
    }

    /**
     * @dev  baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract
     */
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

    /**
     * @dev Mint  active
     */
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    /**
     * @dev Mint reserve active
     */
    function setReserveActive(bool val) public onlyOwner {
        reserveActive = val;
    }

    /**
     * @dev Set new base URI
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    /**
     * @dev Set new price
     */
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    /**
     * @notice Allow the owner of the contract to withdraw MATIC
     */
    function withdraw() public onlyOwner {
        uint256 ownerBalance = address(this).balance;

        require(ownerBalance > 0, "Owner has not balance to withdraw");

        (bool sent, ) = _msgSender().call{value: address(this).balance}("");
        require(sent, "Failed to send user balance back to the owner");
    }
}