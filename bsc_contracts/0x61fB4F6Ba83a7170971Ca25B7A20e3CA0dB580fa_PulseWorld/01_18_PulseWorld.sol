// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./security/ReEntrancyGuard.sol";

contract PulseWorld is
    ERC721,
    ERC721Enumerable,
    ERC721Royalty,
    ReEntrancyGuard,
    Ownable
{
    /// @dev SafeMath library
    using SafeMath for uint256;

    /// @dev  Starting and stopping sale, presale and whitelist
    bool public saleActive = true;

    /// @dev  The base link that leads to the image / video of the token
    string public baseTokenURI = "#";

    uint public MAX_SUPPLY = 0; // Maximum limit of tokens that can ever exist

    /// @dev  Maximum limit of tokens that can ever exist
    uint256 public MAX_MINT_PER_TX = 1;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _addressRoyalty,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        /// @dev set max supply
        MAX_SUPPLY = _maxSupply;

        /// @dev set baseTokenURI
        setBaseURI(_baseTokenURI);

        /// @dev set the address of the Lnda contract
        _setDefaultRoyalty(_addressRoyalty, 300);
    }

    /// @dev hook for ERC721Enumerable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @dev super method for ERC721Enumerable
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev hook for ERC721Royalty
    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    /// @dev burn a token
    function burnNFT(uint256[] memory _lands) public onlyOwner {
        for (uint i = 0; i < _lands.length; i++) {
            _burn(_lands[i]);
        }
    }

    /// @dev set the address of the Lnda contract
    function setDefaultRoyalty(
        address _owner,
        uint96 _feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(_owner, _feeNumerator);
    }

    /// @dev Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev  Admin minting function to reserve tokens for the team, collabs, customs and giveaways
    function mintReserved(
        address _address,
        uint256 _amount
    ) external onlyOwner noReentrant {
        uint256 supply = totalSupply();
        uint256 _MAX_MINT_PER_TX = MAX_MINT_PER_TX;
        uint256 _MAX_SUPPLY = MAX_SUPPLY;
        bool _saleActive = saleActive;

        require(_saleActive, "Sale isn't active");

        require(
            (_amount > 0) && (_amount <= _MAX_MINT_PER_TX),
            "Can only mint between 1 and 20 tokens at once"
        );
        require(
            supply + _amount <= _MAX_SUPPLY,
            "Can't mint more than max supply"
        );

        for (uint256 i; i < _amount; i++) {
            _safeMint(_address, supply + i);
        }
    }

    /// @dev Minting function for the public
    function mint() external payable noReentrant {
        uint256 supply = totalSupply();
        uint256 _MAX_SUPPLY = MAX_SUPPLY;
        bool _saleActive = saleActive;

        require(_saleActive, "Sale isn't active");

        require((supply + 1) <= _MAX_SUPPLY, "Can't mint more than max supply");

        /// @dev Minting function for the public
        _safeMint(_msgSender(), supply + 1);
    }

    /// @dev  See which address owns which tokens
    function tokensOfOwner(
        address addr
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    /// @dev Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    /// @dev set active
    function setActive(bool _active) public onlyOwner {
        saleActive = _active;
    }

    /// @dev withdraw tokens
    function withdrawOwner(uint256 amount) external payable onlyOwner {
        require(
            payable(address(_msgSender())).send(amount),
            "Withdraw Owner: Failed to transfer token to Onwer"
        );
    }
}