// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./security/ReEntrancyGuard.sol";
import "./helpers/Withdraw.sol";

contract LandianLands is
    ERC721,
    ERC721Enumerable,
    ERC721Royalty,
    ReEntrancyGuard,
    Withdraw
{
    // @dev SafeMath library
    using SafeMath for uint256;

    uint public MAX_SUPPLY = 0; // Maximum limit of tokens that can ever exist

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
    function supportsInterface(bytes4 interfaceId)
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
    function setDefaultRoyalty(address _owner, uint96 _feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_owner, _feeNumerator);
    }

    /// @dev Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev esta funcion es para que le ownership a los tokens puede hacer el mint de los tokens
    function mintReserved(address _addr, uint256[] memory _lands)
        external
        onlyOwner
    {
        for (uint i = 0; i < _lands.length; i++) {
            _mint(_addr, _lands[i]);
        }
    }

    /// @dev buy land
    function buyLand(uint256[] memory _lands, uint256 _amountTokens)
        external
        noReentrant
    {
        /// @dev valid
        require(saleActive, "Sale is not active");
        require(_lands.length > 0, "Please, enter valid lands");
        require(price > 0, "Please, enter valid price");

        /// @dev calculate total price

        uint256 _landsAmount = _lands.length;
        uint256 _amountTokensTotal = _landsAmount * price;

        /// @dev valid amount of tokens
        require(_amountTokens >= _amountTokensTotal, "Not enough tokens");

        /// @dev  Check that the user's token balance is enough to do the land
        require(
            IERC20(addressLnda).balanceOf(_msgSender()) >= _amountTokens,
            "Buy Land: Your balance is lower than the amount of tokens you want to sell"
        );

        /// @dev allowonce to execute the land
        require(
            IERC20(addressLnda).allowance(_msgSender(), address(this)) >=
                _amountTokens,
            "Buy Land: You don't have enough tokens to buy"
        );

        // @dev Transfer token lnda to the sender  =>  smart contract
        require(
            IERC20(addressLnda).transferFrom(
                _msgSender(),
                address(this),
                _amountTokens
            ),
            "Buy Land: Failed to transfer tokens from user to vendor"
        );

        /// @dev Mint the tokens to sender
        for (uint i = 0; i < _lands.length; i++) {
            /// @dev mint the token
            _mint(_msgSender(), _lands[i]);
        }
    }

    /// @dev verify if the token exists or minted
    function IsExists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// @dev  See which address owns which tokens
    // See which address owns which tokens
    function tokensOfOwner(address addr)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }
}