// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/math/SafeMath.sol";

contract BITSTARS is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public itemPrice;
    bool public isSaleActive;
    uint256 public tokensPurchased;
    uint256 public constant TOTAL_TOKENS_TO_MINT = 10000;
    address public fundWallet;

    constructor(
        string memory _tokenBaseUri,
        address _fundWallet,
        string memory _name,
        string memory _symbol,
        uint256 _price
    ) ERC721(_name, _symbol) {
        _setBaseURI(_tokenBaseUri);
        itemPrice = _price;
        fundWallet = _fundWallet;
    }

    ////////////////////
    // Action methods //
    ////////////////////

    function mint(uint256 _howMany) external payable {
        require(_howMany > 0, "Minimum 1 tokens need to be minted");
        require(
            _howMany <= tokenRemainingToBeMinted(),
            "Tokens needs to be minted is greater than the token available"
        );
        require(isSaleActive, "Sale is not active");
        require(_howMany <= 20, "max 20 tokens at once");
        require(
            itemPrice.mul(_howMany) == msg.value,
            "Insufficient ETH to mint"
        );

        for (uint256 i = 0; i < _howMany; i++) {
            _mint(_msgSender());
        }
    }

    function _mint(address _to) private {
        tokensPurchased++;
        require(!_exists(tokensPurchased), "Mint: Token already exist.");
        _mint(_to, tokensPurchased);
    }

    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    ///////////////////
    // Query methods //
    ///////////////////

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function tokenRemainingToBeMinted() public view returns (uint256) {
        return TOTAL_TOKENS_TO_MINT - tokensPurchased;
    }

    function isAllTokenMinted() external view returns (bool) {
        return tokensPurchased == TOTAL_TOKENS_TO_MINT;
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return _isApprovedOrOwner(_spender, _tokenId);
    }


    /////////////
    // Setters //
    /////////////

    function stopSale() external onlyOwner {
        isSaleActive = false;
    }

    function startSale() external onlyOwner {
        isSaleActive = true;
    }

    function changeFundWallet(address _fundWallet) external onlyOwner {
        fundWallet = _fundWallet;
    }

    function withdrawETH(uint256 _amount) external onlyOwner {
        payable(fundWallet).transfer(_amount);
    }

    function setTokenURI(uint256 _tokenId, string memory _uri)
        external
        onlyOwner
    {
        _setTokenURI(_tokenId, _uri);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    // sets the price for an item
    function setItemPrice(uint256 _price) public onlyOwner {
        itemPrice = _price;
    }
}