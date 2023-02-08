// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../Signable.sol";
import "../../libs/ERC721ASignatureLib.sol";
import "../../tokens/interfaces/IWETH.sol";
import "../../tokens/source/ERC721ASource.sol";
import "../BaseTransactor.sol";

/**
    @dev This contract will be used as a store transactor for the clones of 
    ERC721ASource contract.
 */
contract ERC721ATransactor is BaseTransactor, Signable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ERC721ASignatureLib for ERC721ASignatureLib.ERC721ASignature;

    event NFTAdded(address[] indexed nfts);
    event NFTRemoved(address[] indexed nfts);
    event TokensBought(
        address indexed buyer,
        address indexed signer,
        address indexed paymentToken,
        uint256 purchaseId,
        uint256 quantity,
        uint256 totalPrice
    );

    address public immutable multisig;

    // purchaseId => [token ids]
    mapping(uint256 => uint256[]) public purchases;

    // NFT allowed => true or false
    mapping(address => bool) public isAllowedNFT;

    constructor(
        address adminAddress,
        address configuratorAddress,
        address signerAddress,
        address multisigAddress,
        address wethAddress,
        uint256 secondsToBuyValue,
        bool addEthAsPayment
    )
        BaseTransactor(
            adminAddress,
            configuratorAddress,
            signerAddress,
            secondsToBuyValue,
            wethAddress,
            addEthAsPayment
        )
    {
        multisig = multisigAddress;
    }

    function buyTokens(ERC721ASignatureLib.ERC721ASignature calldata buy)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        require(isAllowedNFT[buy.nft], "!nft");
        require(purchases[buy.purchaseId].length == 0, "purchase_processed");
        require(buy.timestamp > block.timestamp - secondsToBuy, "too_late");
        require(buy.amount > 0, "!amount");

        address signer = buy.getSigner(msg.sender, address(this), _getChainId());
        require(hasRole(SIGNER_ROLE, signer), "!signer");

        _requireValidNonceAndSet(signer, buy.nonce);

        if (buy.mustTransferTokens && buy.totalPrice > 0) {
            require(isAllowedToken[buy.paymentToken], "!payment_token");
            address paymentToken = buy.paymentToken;
            if (paymentToken == ETH_CONSTANT) {
                require(msg.value == buy.totalPrice, "!value");
                IWETH(weth).deposit{value: msg.value}();
                IERC20(weth).safeTransfer(multisig, IERC20(weth).balanceOf(address(this)));
            } else {
                IERC20(paymentToken).safeTransferFrom(msg.sender, multisig, buy.totalPrice);
            }
        }

        uint256[] memory tokenIds = getPurchasedIds(buy.nft, buy.amount);
        ERC721ASource(buy.nft).safeMint(msg.sender, buy.amount);
        purchases[buy.purchaseId] = tokenIds;

        emit TokensBought(
            msg.sender,
            signer,
            buy.paymentToken,
            buy.purchaseId,
            buy.amount,
            buy.totalPrice
        );
    }

    function getPurchaseInfo(uint256 purchaseId) external view returns (uint256[] memory tokenIds) {
        tokenIds = purchases[purchaseId];
    }

    function addNFT(address[] calldata nftList) external onlyRole(CONFIGURATOR_ROLE) {
        require(nftList.length > 0, "!nft_list");
        for (uint256 index = 0; index < nftList.length; index++) {
            isAllowedNFT[nftList[index]] = true;
        }
        emit NFTAdded(nftList);
    }

    function removeNFT(address[] calldata nftList) external onlyRole(CONFIGURATOR_ROLE) {
        require(nftList.length > 0, "!nft_list");
        for (uint256 index = 0; index < nftList.length; index++) {
            isAllowedNFT[nftList[index]] = false;
        }
        emit NFTRemoved(nftList);
    }

    function getPurchasedIds(address nft, uint256 amount)
        internal
        view
        returns (uint256[] memory tokenIds)
    {
        tokenIds = new uint256[](amount);
        uint256 startTokenId = ERC721ASource(nft).totalSupply() + 1;
        for (uint256 i = startTokenId; i < startTokenId + amount; i++) {
            tokenIds[i - startTokenId] = i;
        }
    }
}