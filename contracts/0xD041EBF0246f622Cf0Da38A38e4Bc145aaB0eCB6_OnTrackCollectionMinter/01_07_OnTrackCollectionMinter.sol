// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IOnTrackCollectionNFT.sol";

contract OnTrackCollectionMinter is ReentrancyGuard, Ownable {
    uint256 public mintPrice;
    bool public mintingEnabled;
    mapping(uint256 => bool) public tokenMinted;
    uint256 public maxSupply;
    uint256 public totalSupply;

    IERC721 public atemCarClubCardsAssets;
    IOnTrackCollectionNFT public onTrackCollectionNft;

    event Minted(
        address indexed minter,
        uint256[] indexed tokenIds,
        uint256 amount
    );
    event EtherWithdrawn(address to, uint256 amount);

    constructor(
        IOnTrackCollectionNFT _onTrackCollectionNft,
        IERC721 _atemCarClubCardsAssets,
        uint256 _mintPrice,
        uint256 _maxSupply
    ) {
        onTrackCollectionNft = _onTrackCollectionNft;
        atemCarClubCardsAssets = _atemCarClubCardsAssets;
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        totalSupply = 0;
        mintingEnabled = false;
    }

    /* @dev: Setter for atemCarClubCardsAssets
     */
    function setAtemCarClubCardsAssets(IERC721 _address) external onlyOwner {
        atemCarClubCardsAssets = _address;
    }

    /* @dev: Setter for onTrackCollectionNft
     */
    function setOnTrackCollectionNft(IOnTrackCollectionNFT _address)
        external
        onlyOwner
    {
        onTrackCollectionNft = _address;
    }

    /* @dev: Setter for mintPrice
     */
    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    /* @dev: Setter for mintingEnabled
     */
    function setEnabled(bool _bool) external onlyOwner {
        mintingEnabled = _bool;
    }

    /* @dev: Setter for maxSuppoly
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /* @dev: Mint Collection NFT
     * @param: tokenIds Array of tokenIds to mint against
     */
    function mintCollectionNft(uint256[] memory tokenIds)
        external
        payable
        nonReentrant
    {
        require(mintingEnabled, "Minting not open");
        require(msg.sender == tx.origin, "Contracts cant mint");

        uint256 tokenAmount = tokenIds.length;
        require(
            totalSupply + tokenAmount <= maxSupply,
            "Claim has reached max supply"
        );
        require(msg.value >= mintPrice * tokenAmount, "Insufficient fee");
        require(
            tokenAmount <= 10,
            "You can't mint more than 10 tokens at once"
        );

        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                require(
                    !tokenMinted[tokenIds[i]],
                    "Claim has already been made for this token"
                );
                require(
                    atemCarClubCardsAssets.ownerOf(tokenIds[i]) == msg.sender,
                    "You are not the owner of the token"
                );
                tokenMinted[tokenIds[i]] = true;
            }
        }

        onTrackCollectionNft.mint(msg.sender, tokenAmount);
        totalSupply += tokenAmount;

        emit Minted(msg.sender, tokenIds, tokenAmount);
    }

    /* @dev: Function to withdraw Ether of contract
     * @param: _to The recipient address to withdraw to
     */
    function withdraw(address payable _to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = _to.call{value: balance}("");
        require(sent, "Failed to withdraw Ether");
        emit EtherWithdrawn(_to, balance);
    }

    /* @dev: View function to see minting status
     * @param: Array of tokenIds
     */
    function getTokensMintedStatus(uint256[] calldata tokenIds)
        public
        view
        returns (bool[] memory)
    {
        bool[] memory tokenStatus = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenStatus[i] = tokenMinted[tokenIds[i]];
        }
        return tokenStatus;
    }
}