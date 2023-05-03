// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC2981.sol";
import "./ERC721OperatorFilterer.sol";

contract PapaNFT is ERC721OperatorFilterer, ERC2981, Ownable {
    uint256 public maxSupply = 3000;

    uint256 public price = 0.05 ether;

    uint256 public maxAmount = 10;

    string public baseURI = "";
    string public defaultURI = "";

    // mints
    mapping(address => uint256) public mints;

    constructor() ERC721OperatorFilterer("PAPA", "PAPA") {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Reveal metadata
     */
    function setBaseURI(string calldata __baseURI) external onlyOwner
    {
        baseURI = __baseURI;
    }

    /**
    * @notice sets default URI
    */
    function setDefaultURI(string calldata __defaultURI) external onlyOwner {
        defaultURI = __defaultURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory _tokenURI = super.tokenURI(tokenId);
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
        return defaultURI;
    }

    /**
    * @dev Sets the max supply of the contract.
    */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
    * @dev Sets the price.
    */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
    * @dev Sets the max amount.
    */
    function setMaxAmount(uint256 _maxAmount) external onlyOwner {
        maxAmount = _maxAmount;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
    * @dev mint papas
    * @param amount number of papas to mint
    */
    function mint(uint256 amount) external payable {
        // check the amount is not 0
        require(amount > 0, "Amount must be greater than 0");
        // check the amount is not greater than max amount
        require(amount + mints[msg.sender] <= maxAmount, "Max amount exceeded");
        // check the sale not sold out
        require(totalSupply() + amount <= maxSupply, "Sold out");
        // check the amount sent to the contract
        require(msg.value == price * amount, "Wrong payment amount");

        mints[msg.sender] += amount;
        _mint(msg.sender, amount);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}