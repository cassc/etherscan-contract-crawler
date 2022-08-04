//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract PossedNFT is Ownable, ERC721Enumerable {
    using Strings for uint256;

    /// @dev MAX Total supply is 8888
    uint256 public constant MAX_SUPPLY = 8888;

    /// @dev Current NFT index
    uint256 private currentIndex;

    /// @dev BaseTokenURI
    string private baseTokenURI;

    /// @dev Minters addresses
    mapping(address => bool) public minters;

    constructor() ERC721("PSDDMINI", "PDMINI") {}

    /// @dev Add new minter address
    function addMinter(address _who) external onlyOwner {
        require(!minters[_who], "Already added");
        minters[_who] = true;
    }

    /// @dev Remove minter
    function removeMinter(address _who) external onlyOwner {
        require(minters[_who], "Not added");
        minters[_who] = false;
    }

    /// @dev Set BaseTokenURI
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @dev Mint NFT
    function mint(address _who, uint256 _amount) external onlyMinter {
        require(_amount > 0, "Amount should be greater than 0");
        require(currentIndex + _amount <= MAX_SUPPLY, "Overflow");

        for (uint256 i = 0; i < _amount; i++) {
            currentIndex++;
            _mint(_who, currentIndex);
        }
    }

    /// @dev Get LLC TokenURI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseTokenURI).length > 0
                ? string(abi.encodePacked(baseTokenURI, tokenId.toString()))
                : "";
    }

    modifier onlyMinter() {
        require(minters[_msgSender()], "Only whitelisted users can mint");
        _;
    }
}