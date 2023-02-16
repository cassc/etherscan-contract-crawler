// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./extensions/EIP712Upgradeable.sol";
import "./extensions/IHPMarketplaceMintV0002.sol";
import "./extensions/HPApprovedMarketplace.sol";
import "./extensions/IHPRoles.sol";

import "hardhat/console.sol";

contract BuyNowMarketplaceSignerV0007 is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, EIP712Upgradeable {

    // Variables
    bool private hasInitialized;
    address payable private feeAccount; // the account that receives fees
    uint private feePercent; // the fee percentage on sales 
    uint private initialFeePercent; // the fee percentage on sales 
    CountersUpgradeable.Counter private itemCount;

    address public hpRolesContractAddress;
    bool private hasUpgradeInitialzed;

    // saleHistory
    mapping(string => bool) public saleHistory;
    mapping(address => mapping (address => bool)) private uniqueWalletMintMapping;

    struct SignerItem {
        string saleId;
        uint price;
        string currency;
        address payable seller;
        address nft;
        uint tokenId;
        address purchaser;
        uint expiry;
        bytes signature;
    }

    struct MintSignerItem {
        string saleId;
        address royaltyAddress;
        uint96 feeNumerator;
        string uri;
        string trackId;
        uint price;
        string currency;
        address payable seller;
        address nft;
        address purchaser;
        uint expiry;
        bool isUniqueMint;
        bytes signature;
    }

    event Bought(
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed buyer,
        string saleId,
        string currency
    );

    event PaymentSplit(
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed from,
        address indexed to,
        string saleId,
        string currency
    );

    function initialize(
        uint _feePercent,
        uint _initialFeePercent,
        address payable _feeAccount,
        address _hpRolesContractAddress,
        string memory name,
        string memory version
    ) initializer public {
        require(hasInitialized == false, "This has already been initialized");
        hasInitialized = true;
        feeAccount = _feeAccount;
        feePercent = _feePercent;
        initialFeePercent = _initialFeePercent;
        hasUpgradeInitialzed = true;
        hpRolesContractAddress = _hpRolesContractAddress;
        __Ownable_init_unchained();
        __ReentrancyGuard_init();
        __EIP712_init_unchained(name, version);

    }

    function upgrader(address _hpRolesContractAddress) external {
        require(hasUpgradeInitialzed == false, "already upgraded");
        hasUpgradeInitialzed = true;
        hpRolesContractAddress = _hpRolesContractAddress;
    }

    function setHasUpgradeInitialized(bool upgraded) external onlyOwner {
        hasUpgradeInitialzed = upgraded;
    }

    function calculateFee(uint amount, uint percentage)
        public
        pure
        returns (uint)
    {
        require((amount / 10000) * 10000 == amount, "Too Small");
        return (amount * percentage) / 10000;
    }

    function nftContractEmit(address nftContract) public {
        HPApprovedMarketplace emittingContract = HPApprovedMarketplace(address(nftContract));
        emittingContract.msgSenderEmit();
    }

    function setFeeAccount(address payable _feeAccount) onlyOwner public {
        feeAccount = _feeAccount;
    }

    function getHpRolesContractAddress() public view returns(address) {
        return hpRolesContractAddress;
    }

    function setHpRolesContractAddress(address contractAddress) external onlyOwner {
        hpRolesContractAddress = contractAddress;
    }

    function recoverSigner(SignerItem calldata item) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("SignerItem(string saleId,uint price,string currency,address seller,address nft,uint tokenId,address purchaser,uint expiry)"),
            keccak256(bytes(item.saleId)),
            item.price,
            keccak256(bytes(item.currency)),
            item.seller,
            item.nft,
            item.tokenId,
            item.purchaser,
            item.expiry
        )));
        (address signer, ) = ECDSAUpgradeable.tryRecover(digest, item.signature);
        return signer;
    }

    function recoverMintSigner(MintSignerItem calldata item) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("MintSignerItem(string saleId,address royaltyAddress,uint96 feeNumerator,string uri,string trackId,uint price,string currency,address seller,address nft,address purchaser,uint expiry,bool isUniqueMint)"),
            keccak256(bytes(item.saleId)),
            item.royaltyAddress,
            item.feeNumerator,
            keccak256(bytes(item.uri)),
            keccak256(bytes(item.trackId)),
            item.price,
            keccak256(bytes(item.currency)),
            item.seller,
            item.nft,
            item.purchaser,
            item.expiry,
            item.isUniqueMint
        )));
        (address signer, ) = ECDSAUpgradeable.tryRecover(digest, item.signature);
        return signer;
    }

    function purchaseMintSignerItem(MintSignerItem calldata mintSignerData) public payable nonReentrant {
        address signer = recoverMintSigner(mintSignerData);
        address buyer = address(mintSignerData.purchaser);

        if (mintSignerData.isUniqueMint) {
            require(uniqueWalletMintMapping[address(mintSignerData.nft)][buyer] == false, "Only 1 unique NFT per address");
            uniqueWalletMintMapping[address(mintSignerData.nft)][buyer] = true;
        }

        require(msg.value >= mintSignerData.price, "Insufficient funds to purchase");
        require(saleHistory[mintSignerData.saleId] != true, "Already minted");
        
        // require(compare(mintSignerData.currency, "usd") == 0 || mintSignerData.price > 0, "Price can't be 0 for ETH sales");
        

        IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
        require(hpRoles.isAdmin(signer) == true, "Admin rights required");
        

        uint fee = 0;
        uint256 sellerTransferAmount = 0;
        if (mintSignerData.price != 0) {
            fee = calculateFee(mintSignerData.price, initialFeePercent);
        
            if (compare(mintSignerData.currency, "usd") == 0) {
                buyer = address(mintSignerData.purchaser);
            }
            sellerTransferAmount = mintSignerData.price - fee;
            mintSignerData.seller.transfer(sellerTransferAmount);
            feeAccount.transfer(fee);
        }

        IHPMarketplaceMintV0002 hpMarketplaceNft = IHPMarketplaceMintV0002(address(mintSignerData.nft));
        uint256 newTokenId = hpMarketplaceNft.marketplaceMint(
            buyer, 
            mintSignerData.royaltyAddress,
            mintSignerData.feeNumerator,
            mintSignerData.uri,
            mintSignerData.trackId);

        emit PaymentSplit(
            address(mintSignerData.nft),
            newTokenId,
            sellerTransferAmount,
            buyer,
            mintSignerData.seller,
            mintSignerData.saleId,
            mintSignerData.currency);

        emit PaymentSplit(
            address(mintSignerData.nft),
            newTokenId,
            fee,
            buyer,
            feeAccount,
            mintSignerData.saleId,
            mintSignerData.currency);

        emit Bought(
            address(mintSignerData.nft),
            newTokenId,
            mintSignerData.price,
            mintSignerData.seller,
            buyer,
            mintSignerData.saleId,
            mintSignerData.currency
        );
    }

    function purchaseSignerItem(SignerItem calldata signerData) public payable nonReentrant {
        address signer = recoverSigner(signerData);

        IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
        require(hpRoles.isAdmin(signer) == true, "Admin rights required");
        require(msg.value >= signerData.price, "Insufficient funds to purchase");
        require(saleHistory[signerData.saleId] != true, "Already sold");
        require(compare(signerData.currency, "usd") == 0 || signerData.price > 0, "Price can't be 0 for ETH sales");

        uint fee = calculateFee(signerData.price, feePercent);

        IERC2981Upgradeable royaltyNft = IERC2981Upgradeable(address(signerData.nft));
        try royaltyNft.royaltyInfo(signerData.tokenId, signerData.price) returns (address receiver, uint256 amount) {
            uint256 sellerTransferAmount = signerData.price - fee - amount;
            signerData.seller.transfer(sellerTransferAmount);
            feeAccount.transfer(fee);
            payable(receiver).transfer(amount);

            emit PaymentSplit(
                address(signerData.nft),
                signerData.tokenId,
                sellerTransferAmount,
                signerData.purchaser,
                signerData.seller,
                signerData.saleId,
                signerData.currency
            );

            emit PaymentSplit(
                address(signerData.nft),
                signerData.tokenId,
                amount,
                signerData.purchaser,
                receiver,
                signerData.saleId,
                signerData.currency
            );
        } catch {
            uint256 sellerTransferAmount = signerData.price - fee;
            signerData.seller.transfer(sellerTransferAmount);
            feeAccount.transfer(fee);

            emit PaymentSplit(
                address(signerData.nft),
                signerData.tokenId,
                sellerTransferAmount,
                signerData.purchaser,
                signerData.seller,
                signerData.saleId,
                signerData.currency
            );
        }

        emit PaymentSplit(
            address(signerData.nft),
            signerData.tokenId,
            fee,
            signerData.purchaser,
            feeAccount,
            signerData.saleId,
            signerData.currency
        );

        IERC721Upgradeable hpMarketplaceNft = IERC721Upgradeable(address(signerData.nft));
        hpMarketplaceNft.safeTransferFrom(
            signerData.seller, 
            signerData.purchaser,
            signerData.tokenId);

        emit Bought(
            address(signerData.nft),
            signerData.tokenId,
            signerData.price,
            signerData.seller,
            signerData.purchaser,
            signerData.saleId,
            signerData.currency
        );
    }

    function compare(string memory _a, string memory _b) public pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
}