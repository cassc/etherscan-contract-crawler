// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "./Secutiry/ReEntrancyGuard.sol";
import "./Secutiry/SoftAdministered.sol";

contract MIND is SoftAdministered, ERC721A, ReEntrancyGuard {
    using Address for address;

    // Starting and stopping sale, presale and whitelist
    bool public saleActive = false;

    // The base link that leads to the image / video of the token
    string public baseTokenURI = "#";

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) ERC721A(_name, _symbol) {
        baseTokenURI = _baseTokenURI;
    }

    /**
     *
     * @param _address  addres
     * @param _amount amount
     */
    function mintReserved(
        address _address,
        uint256 _amount
    ) external onlyUserOrOwner noReentrant {
        bool _saleActive = saleActive;

        require(_saleActive, "Sale isn't active");

        _safeMint(_address, _amount);
    }

    /**
     *
     * @param owner onwer
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
     *
     * @param active active
     */
    function setSaleActive(bool active) external onlyOwner {
        saleActive = active;
    }

    /**
     * base uri
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     *
     * @param baseURI uri
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }
}