// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// gm
// https://eightbit.me
// https://twitter.com/eightbit
// https://discord.gg/eightbit

contract EightBit is ERC721, ERC2981, Ownable {
    uint256 public constant MAX_SUPPLY = 8888;

    uint256 public price = .05 ether;
    uint256 public maxPerAddress = 8;
    bool public isPublicSaleActive;
    bool public isPremintSaleActive;
    bytes32 public premintSaleMerkleRoot;
    address public royaltyAddress;
    uint96 public royaltyFee = 500;

    uint256 private _totalSupply;
    bool private _hasTeamMinted;
    string private _baseTokenURI;
    mapping(address => uint256) private _mintCount;
    mapping(uint256 => bool) private _claimedPerk;

    constructor() ERC721("EightBit", "BIT") {
        royaltyAddress = owner();
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Mint a certain number of tokens
     */
    function _mint(uint256 count) private {
        require(count > 0, "Must mint at least 1");
        require(_totalSupply + count <= MAX_SUPPLY, "Exceeds max supply");

        address addr = _msgSender();

        for (uint256 i = 0; i < count; i++) {
            _safeMint(addr, _totalSupply + i + 1);
        }

        _totalSupply += count;
        _mintCount[addr] += count;
    }

    /**
     * @notice Allows the public to mint
     */
    function mint(uint256 count) external payable virtual {
        require(isPublicSaleActive, "Public sale not open");
        require(price * count == msg.value, "Incorrect ETH value sent");
        require(_mintCount[_msgSender()] + count <= maxPerAddress, "Exceeds max mint count");

        _mint(count);
    }

    /**
     * @notice Allows those in the premint list to mint
     */
    function premintMint(uint256 count, bytes32[] calldata merkleProof) external payable virtual {
        require(isPremintSaleActive, "Premint sale not open");
        require(price * count == msg.value, "Incorrect ETH value sent");
        require(
            MerkleProof.verify(merkleProof, premintSaleMerkleRoot, keccak256(abi.encodePacked(_msgSender()))),
            "Address not in premint list"
        );
        require(_mintCount[_msgSender()] + count <= maxPerAddress, "Exceeds max mint count");

        _mint(count);
    }

    /**
     * @notice Allows owner to mint for the team & community
     */
    function teamMint() external onlyOwner {
        require(!_hasTeamMinted, "Team already minted");

        _mint(250);
        _hasTeamMinted = true;
    }

    /**
     * @notice Allows owner to toggle the public sale on/off
     */
    function togglePublicSale() public onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    /**
     * @notice Allows owner to toggle the premint sale on/off
     */
    function togglePremintSale() public onlyOwner {
        isPremintSaleActive = !isPremintSaleActive;
    }

    /**
     * @notice Allows owner to update the price
     */
    function setPrice(uint256 priceInWei) public onlyOwner {
        price = priceInWei;
    }

    /**
     * @notice Allows owner to set the max mints per address
     */
    function setMaxPerAddress(uint256 max) public onlyOwner {
        maxPerAddress = max;
    }

    /**
     * @notice Allow owner to set the Premint allow list merkle root
     */
    function setPremintListMerkleRoot(bytes32 root) public onlyOwner {
        premintSaleMerkleRoot = root;
    }

    /**
     * @notice Allow owner to set the base token uri
     */
    function setBaseURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @notice Returns the base token uri
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Returns whether or not a perk has been claimed for a token
     */
    function hasClaimedPerk(uint256 tokenId) external view returns (bool) {
        return _claimedPerk[tokenId];
    }

    /**
     * @notice Allow owner to specify that a perk has been claimed for a token
     */
    function claimPerk(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        require(!_claimedPerk[tokenId], "Token already claimed");

        _claimedPerk[tokenId] = true;
    }

    /**
     * @notice Allow owner to withdraw amount
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /**
     * @notice Allow owner to update the royalty fee
     */
    function setRoyaltyFee(uint96 fee) external onlyOwner {
        royaltyFee = fee;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Allow owner to update the royalty address
     */
    function setRoyaltyAddress(address addr) external onlyOwner {
        royaltyAddress = addr;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Returns the total supply
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}