// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import "openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "openzeppelin/contracts/utils/Strings.sol";
import "openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MerkleDistributor.sol";

error MintPriceNotPaid();
error PublicSaleNotActive();
error IsNotAdmin();
error MaxSupply();
error MaxMintPerAddress();
error NonExistentTokenURI();
error WithdrawTransfer();

contract AffinityCollective is
    ERC721,
    ERC2981,
    Ownable,
    MerkleDistributor,
    ReentrancyGuard
{
    using Strings for uint256;
    uint256 public constant TOTAL_SUPPLY = 1000;
    address affinityWallet;
    bool public publiSaleActive;
    uint256 public MAX_MINT_PER_ADDRESS;
    uint256 public WHITELIST_MINT_PRICE;
    uint256 public PUBLIC_MINT_PRICE;
    uint256 public currentTokenId;
    string public baseURI;

    /**
     * @notice premint founder NFT's
     */

    constructor(
        uint256 _publicMintPrice,
        uint256 _whitelistMintPrice,
        string memory _baseURI,
        address _admin
    ) ERC721("Affinity Collective", "AFFINITY") {
        baseURI = _baseURI;
        publiSaleActive = false;
        PUBLIC_MINT_PRICE = _publicMintPrice;
        WHITELIST_MINT_PRICE = _whitelistMintPrice;
        MAX_MINT_PER_ADDRESS = 5;
        affinityWallet = _admin;
    }

    /**
     * @dev checks to see whether publiSaleActive is true
     */
    modifier isPublicSaleActive() {
        if (!publiSaleActive) revert PublicSaleNotActive();
        _;
    }

    modifier isAdmin() {
        if (msg.sender != affinityWallet) revert IsNotAdmin();
        _;
    }

    /**
     * @notice airdrop founding members NFT's
     */
    function airdropFounders(address _foundersAirdrop) external onlyOwner {
        require(currentTokenId == 0, "Airdrop already completed");
        uint256 index;
        unchecked {
            for (index = 0; index < 50; index++) {
                _safeMint(_foundersAirdrop, index);
            }
        }
        currentTokenId = index;
    }

    /**
     * @notice Public mint
     */
    function mint(uint256 _amount)
        external
        payable
        nonReentrant
        isPublicSaleActive
    {
        if (_amount > MAX_MINT_PER_ADDRESS) revert MaxMintPerAddress();
        if (currentTokenId >= TOTAL_SUPPLY) revert MaxSupply();
        if (msg.value != PUBLIC_MINT_PRICE * _amount) revert MintPriceNotPaid();
        unchecked {
            for (uint256 index = 0; index < _amount; index++) {
                _safeMint(msg.sender, currentTokenId);
                currentTokenId++;
            }
        }
    }

    /**
     * @notice Public mint
     */
    function adminMint(uint256 _amount, address _to)
        external
        nonReentrant
        isAdmin
    {
        if (currentTokenId >= TOTAL_SUPPLY) revert MaxSupply();
        unchecked {
            for (uint256 index = 0; index < _amount; index++) {
                _safeMint(_to, currentTokenId);
                currentTokenId++;
            }
        }
    }

    /**
     * @notice White list mint
     */
    function whitelistMint(
        address _to,
        uint256 _amount,
        bytes32[] memory _proof
    )
        external
        payable
        nonReentrant
        isAllowListActive
        ableToClaim(_to, _proof)
        tokensAvailable(_to, _amount, MAX_MINT_PER_ADDRESS)
    {
        if (msg.value != WHITELIST_MINT_PRICE * _amount)
            revert MintPriceNotPaid();
        if (currentTokenId + _amount > TOTAL_SUPPLY) revert MaxSupply();
        for (uint256 index = 0; index < _amount; index++) {
            _safeMint(_to, currentTokenId);
            currentTokenId++;
        }
    }

    /**
     * @notice Return token uri of the given token id.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (ownerOf(tokenId) == address(0)) {
            revert NonExistentTokenURI();
        }
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    /**
     * @notice Return current token count.
     */
    function totalSupply() public view returns (uint256) {
        return currentTokenId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @notice Set the token URI's.
     */
    function setTokenURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @dev sets the merkle root for the allow list
     */
    function setAllowList(bytes32 merkleRoot) external onlyOwner {
        _setAllowList(merkleRoot);
    }

    /**
     * @dev sets mint price
     */
    function setMintPrice(uint256 _mintPrice, uint256 _wmintPrice)
        external
        onlyOwner
    {
        PUBLIC_MINT_PRICE = _mintPrice;
        WHITELIST_MINT_PRICE = _wmintPrice;
    }

    /**
     * @dev sets max mint per address
     */
    function setMintPerWallet(uint256 _maxMint) external onlyOwner {
        MAX_MINT_PER_ADDRESS = _maxMint;
    }

    /**
     * @dev allows minting from a list of addresses
     */
    function setAllowListActive(bool allowListActive) external onlyOwner {
        _setAllowListActive(allowListActive);
    }

    /**
     * @dev Enable public sale
     */
    function setPublicSale(bool state) external onlyOwner {
        publiSaleActive = state;
    }

    /**
     * @dev Set admin wallet
     */
    function setAdmin(address _admin) external onlyOwner {
        affinityWallet = _admin;
    }

    /**
     *  @dev Set royalties
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    /**
     * @dev Withdraw contract balance.
     */
    function withdraw() external isAdmin {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = affinityWallet.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }
}