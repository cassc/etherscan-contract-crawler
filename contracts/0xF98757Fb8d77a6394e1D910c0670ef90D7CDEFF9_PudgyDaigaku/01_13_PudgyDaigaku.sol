// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

/**
 * @title PudgyDaigaku - Degen, no roadmap, just sexy art
 * @author Anon
 */
contract PudgyDaigaku is ERC721AQueryable, ERC721ABurnable, Ownable {
    using PRBMathUD60x18 for uint256;
    using Strings for uint256;

    uint256 private constant ONE_PERCENT = 10000000000000000; // 1% (18 decimals)

    // @dev Base uri for the nft
    string private baseURI =
        "ipfs://bafybeign67squygukczpjav7syasjjare2jmby75xynm5f7v3ie47ir7ti/";

    // @dev The price of a mint
    uint256 public price = 0.005 ether;

    // @dev The withdraw address
    address public treasury =
        payable(0x38E3D419D5C4054e804Ebc78b0d211799C6f3B9B);

    // @dev The dev address
    address public dev = payable(0x967bFebEcB40eE0A18Ed9beE9794596499a4D29c);

    // @dev An address mapping for free mints
    mapping(address => uint256) public addressToMinted;

    // @dev The total max per wallet (2 max per person)
    uint256 public maxPerWallet = 3;

    // @dev The total supply of the collection (2k)
    uint256 public maxSupply = 2001;

    constructor() ERC721A("PudgyDaigaku", "PD") {
        _mintERC2309(dev, 1); // Placeholder mint
    }

    /**
     * @notice Mints a new token
     * @param _amount The number of tokens to mint
     */
    function mint(uint256 _amount) external payable {
        require(msg.value >= _amount * price, "1");
        require(addressToMinted[_msgSender()] + _amount < maxPerWallet, "2");
        require(totalSupply() + _amount < maxSupply, "3");
        addressToMinted[_msgSender()] += _amount;
        _mint(_msgSender(), _amount);
    }

    /**
     * @notice Mints a new token for owners
     */
    function ownerMint(address to, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount < maxSupply, "3");
        _mint(to, _amount);
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Returns the URI for a given token id
     * @param _tokenId A tokenId
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert OwnerQueryForNonexistentToken();
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")
            );
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param _baseURI A base uri
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the max per wallet
     * @param _maxPerWallet The max mint count per address
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets the collection max supply
     * @param _maxSupply The max supply of the collection
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets price
     * @param _price price in wei
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * @notice Withdraws funds from contract
     */
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool s1, ) = dev.call{value: amount.mul(ONE_PERCENT * 10)}("");
        (bool s2, ) = treasury.call{value: amount.mul(ONE_PERCENT * 90)}("");
        if (s1 && s2) return;
        // fallback
        (bool s3, ) = dev.call{value: amount}("");
        require(s3, "Payment failed");
    }
}