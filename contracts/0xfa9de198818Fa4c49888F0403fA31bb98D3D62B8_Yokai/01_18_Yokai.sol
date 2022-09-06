//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Yokai is ERC721Enumerable, Ownable, ERC2981 {
    using Counters for Counters.Counter;
    using Strings for uint256;
    uint256 public constant MAX_TO_MINT = 9000;
    uint256 public MINT_PER_PERS = 3;
    uint256 public tokenPrice;
    bytes32 public merkleRoot = 0x56c8a2401993ccf614e155850a863b661359bdddc20fec427cc2be813397f19f;
    string public URI;
    address payable saleReceiver;
    bool public REVEAL = false;
    bool public public_sale = false;

    constructor(
        string memory initialURI,
        address royaltyReceiver
    ) ERC721("Yokai", "YOK") {
        URI = initialURI;
        setPrice(190000000000000000);
        setDefaultRoyalty(royaltyReceiver, 1000);
        updateSaleReceiver(0x0630BA0486a8d85086ED2446D4A9aeB389AA6bdB);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

     /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @dev seul l’admin du contrat peut l’appeler, pour changer la racine
    ///  de l'arbre de merkel de la whitelist
    function setWhitelistRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    /// @dev return token URI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (REVEAL) {
            return string(abi.encodePacked(URI, tokenId.toString()));
        }
        return URI;
    }

    /// @dev make reveal
    function toggleReveal(string memory updatedURI) public onlyOwner {
        REVEAL = !REVEAL;
        URI = updatedURI;
    }

    /// @dev switch from private to public sale, or public to private
    function switchSaleType() public onlyOwner {
        public_sale = !public_sale;
    }

    function updateSaleReceiver(address receiver) public onlyOwner {
        saleReceiver = payable(receiver);
    }

    function setPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
    }

    function setMaxMintPerPerson(uint256 numberMax) public onlyOwner {
        MINT_PER_PERS = numberMax;
    }

    /// @dev private mint sale, only for whitelisted
    function whitelistMint(bytes32[] calldata _merkleProof, uint256 num) public payable {
        require(!public_sale, "Not private sale");
        require(msg.value >= tokenPrice * num, "Insufficient funds");
        require(totalSupply() + num < MAX_TO_MINT, "Exceeds max supply");
        require(msg.sender == tx.origin, "Bots not allowed");
        require(balanceOf(msg.sender) + num <= MINT_PER_PERS, "Can't min't that much NFTs");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof");

        uint256 tokenId = totalSupply();
        for(uint256 i=0; i < num; i++) {
            tokenId += 1;
            _safeMint(msg.sender, tokenId);
        }
        saleReceiver.transfer(msg.value);
    }

    /// @dev public mint sale
    function mint(uint256 num) public payable {
        require(public_sale, "Not public sale");
        require(msg.value >= tokenPrice * num, "Insufficient funds");
        require(totalSupply() + num <= MAX_TO_MINT, "Exceeds max supply");
        require(msg.sender == tx.origin, "Bots not allowed");
        require(balanceOf(msg.sender) + num <= MINT_PER_PERS, "Can't min't that much NFTs");

        uint256 tokenId = totalSupply();
        for(uint256 i=0; i < num; i++) {
            tokenId += 1;
            _safeMint(msg.sender, tokenId);
        }
        saleReceiver.transfer(msg.value);
    }
}