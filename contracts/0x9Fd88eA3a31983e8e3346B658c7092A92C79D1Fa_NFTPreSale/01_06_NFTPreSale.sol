// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/IERC721A.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "hardhat/console.sol";

/**
 * @notice Represents MetaGoddessesERC721 Smart Contract
 */
contract IMetaGoddessesERC721 {
    /**
     * @dev ERC-721 INTERFACE
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /**
     * @dev CUSTOM INTERFACE
     */
    function mintTo(uint256 amount, address _to) external {}
}

/**
 * @title NFTPreSaleContract.
 *
 * @author itxToledo
 *
 * @notice This Smart Contract can be used to sell any fixed amount of NFTs where only permissioned
 * wallets are allowed to buy. Buying is limited to a certain time period.
 *
 */
contract NFTPreSale is Ownable {
    /**
     * @notice The Smart Contract of the NFT being sold
     * @dev ERC-721A Smart Contract
     */
    IMetaGoddessesERC721 public immutable nft;
    IERC721A public immutable boardAddress;
    IERC721A public immutable metagodsAddress;

    /**
     * @dev MINT DATA
     */
    uint256 public mintPrice = 5_000_000_000_000_000; // 0.005 ETH
    uint256 public publicMaxMintPerWallet = 1;

    uint256 public maxSupply = 200;
    uint256 public minted;

    uint256 public saleStartDate;
    uint256 public publicSaleStartDate;
    uint256 public saleEndDate;

    mapping(address => uint256) public addressToMints;

    /**
     * @dev MERKLE ROOTS
     */
    bytes32 public merkleRoot = "";

    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event Purchase(address indexed buyer, uint256 indexed amount);
    event setMerkleRootEvent(bytes32 indexed merkleRoot);
    event WithdrawAllEvent(address indexed to, uint256 amount);
    event MintDatesChanged(uint256 saleStartDate, uint256 publicSaleStartDate);

    constructor(
        address _nftaddress,
        address boardAddress_,
        address metagodsAddress_
    ) Ownable() {
        nft = IMetaGoddessesERC721(_nftaddress);
        boardAddress = IERC721A(boardAddress_);
        metagodsAddress = IERC721A(metagodsAddress_);
    }

    /**
     * @dev SALE
     */

    modifier canMint(uint256 amount) {
        require(address(nft) != address(0), "nft smart contract not set");
        require(amount > 0, "have to buy at least 1");
        require(
            minted + amount <= maxSupply,
            "mint amount goes over max supply"
        );
        require(
            saleStartDate > 0 && publicSaleStartDate > 0,
            "sale dates not set"
        );
        require(msg.value == mintPrice * amount, "ether sent not correct");

        _;
    }

    /// @dev Updates contract variables and mints `amount` NFTs to users wallet
    function computeNewPurchase(uint256 amount) internal {
        minted += amount;
        addressToMints[_msgSender()] += amount;
        nft.mintTo(amount, _msgSender());

        emit Purchase(_msgSender(), amount);
    }

    /**
     * @notice Function to buy one or more NFTs.
     * @dev Verify if user has one or more eligible NFTs.
     * Finally the NFTs are minted to the user's wallet.
     *
     * @param amount. The amount of NFTs to buy.
     */
    function buy(uint256 amount) external payable canMint(amount) {
        require(block.timestamp >= saleStartDate, "sale hasn't started yet");

        // require(block.timestamp < mintEnd, "sale is closed");

        require(
            addressToMints[_msgSender()] + amount <=
                maxMintForWalletWithNFT(_msgSender()),
            "max mint reached for this wallet"
        );

        computeNewPurchase(amount);
    }

    /**
     * @notice Function to buy one or more NFTs.
     * @dev Verify if user has one or more eligible NFTs.
     * Finally the NFTs are minted to the user's wallet.
     *
     * @param amount. The amount of NFTs to buy.
     * @param mintMaxAmount. The max amount of NFTs can buy.
     * @param proof. merkletree proof.
     */
    function whitelistBuy(
        uint256 amount,
        uint256 mintMaxAmount,
        bytes32[] calldata proof
    ) external payable canMint(amount) {
        require(block.timestamp >= saleStartDate, "sale hasn't started yet");

        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All mint data is embedded in the merkle proof.

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), mintMaxAmount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "INVALID PROOF");

        /// @dev Verifies that user can mint based on the provided parameters.
        require(merkleRoot != "", "PERMISSIONED SALE CLOSED");

        require(
            addressToMints[_msgSender()] + amount <= mintMaxAmount,
            "max mint reached for this wallet"
        );

        computeNewPurchase(amount);
    }

    /**
     * @notice Function to buy one or more NFTs in public sale.
     * @param amount. The amount of NFTs to buy.
     */
    function publicBuy(uint256 amount) external payable canMint(amount) {
        require(
            block.timestamp > publicSaleStartDate,
            "public sale hasn't started yet"
        );

        require(
            addressToMints[_msgSender()] + amount <= publicMaxMintPerWallet,
            "max mint reached for this wallet"
        );

        computeNewPurchase(amount);
    }

    /**
     * @notice Function to return max amount for NFT hold.
     * @param wallet_. The wallet address.
     */
    function maxMintForWalletWithNFT(address wallet_)
        public
        view
        returns (uint256)
    {
        uint256 maxNFT;

        // only one mint for any amount of board hold
        if (boardAddress.balanceOf(wallet_) > 0) maxNFT += 1;

        uint256 metagodsBalance = metagodsAddress.balanceOf(wallet_);

        if (metagodsBalance == 1 || metagodsBalance == 2) maxNFT += 1;
        else if (metagodsBalance == 3 || metagodsBalance == 4) maxNFT += 2;
        else if (metagodsBalance == 5 || metagodsBalance == 6) maxNFT += 3;
        else if (metagodsBalance == 7 || metagodsBalance == 8) maxNFT += 4;
        else if (metagodsBalance == 9 || metagodsBalance == 10) maxNFT += 5;

        return maxNFT;
    }

    /**
     * @notice Change the merkleRoot of the sale.
     *
     * @param merkleRoot_. The new merkleRoot.
     */
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
        emit setMerkleRootEvent(merkleRoot_);
    }

    /**
     * @dev FINANCE
     */

    /**
     * @notice Allows owner to withdraw funds generated from sale.
     *
     * @param _to. The address to send the funds to.
     */
    function withdrawAll(address _to) external onlyOwner {
        require(_to != address(0), "cannot withdraw to zero address");

        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "no ether to withdraw");

        payable(_to).transfer(contractBalance);

        emit WithdrawAllEvent(_to, contractBalance);
    }

    /**
     * @notice Allows owner to set mint dates.
     *
     * @param saleStartDate_. mint start date.
     * @param publicSaleStartDate_. public mint start date.
     */
    function setDates(uint256 saleStartDate_, uint256 publicSaleStartDate_)
        external
        onlyOwner
    {
        saleStartDate = saleStartDate_;
        publicSaleStartDate = publicSaleStartDate_;

        emit MintDatesChanged(saleStartDate_, publicSaleStartDate_);
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(_msgSender(), msg.value);
    }
}