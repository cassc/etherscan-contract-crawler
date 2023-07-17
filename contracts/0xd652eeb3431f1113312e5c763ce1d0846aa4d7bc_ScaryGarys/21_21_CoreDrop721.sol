// SPDX-License-Identifier: CC-BY-NC-ND-4.0

pragma solidity ^0.8.10;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/INA721Standard.sol";
import "./interfaces/INA721DropStandard.sol";
import "./interfaces/IRaribleRoyaltiesV2.sol";
import "./parts/AdminFunctions.sol";
import "./parts/DropFunctions.sol";
import "./parts/PresaleFunctions.sol";
import "./parts/rarible/LibPart.sol";
import "./utils/StringsUtil.sol";

contract CoreDrop721 is Ownable, ERC721, INA721Standard, INA721DropStandard, AdminFunctions, DropFunctions, PresaleFunctions, IRaribleRoyaltiesV2 {
    using SafeMath for uint256;

    // ---
    // Constants
    // ---

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_RARIBLE_ROYALTIES = 0xcad96cca; // bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca

    // ---
    // Constructor
    // ---

    // @dev Contract constructor.
    constructor(NftOptions memory options, DropOptions memory dropOptions) ERC721(options.name, options.symbol) {
        nextTokenId = options.startingTokenId;
        maxInvocations = options.maxInvocations;
        imnotArtBps = options.imnotArtBps;
        royaltyFeeBps = options.royaltyBps;
        contractURI = options.contractUri;
        metadataBaseUri = dropOptions.metadataBaseUri;
        mintPriceInWei = dropOptions.mintPriceInWei;
        active = dropOptions.active;
        presaleMint = dropOptions.presaleMint;
        presaleActive = dropOptions.presaleActive;
        autoPayout = dropOptions.autoPayout;
        imnotArtPayoutAddress = dropOptions.imnotArtPayoutAddress;
        artistPayoutAddress = dropOptions.artistPayoutAddress;
        maxQuantityPerTransaction = dropOptions.maxQuantityPerTransaction;
        maxPerWalletEnabled = dropOptions.maxPerWalletEnabled;
        maxPerWalletQuantity = dropOptions.maxPerWalletQuantity;
        paused = false;
        completed = false;

        // Add default admins.
        isAdmin[msg.sender] = true; // Deployer
        address gnosisSafe = address(0x12b66baFc99D351f7e24874B3e52B1889641D3f3); // imnotArt Gnosis Safe
        isAdmin[gnosisSafe] = true;
    }

    // ---
    // Supported Interfaces
    // ---

    // @dev Return the support interfaces of this contract.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165
        || interfaceId == _INTERFACE_RARIBLE_ROYALTIES
        || interfaceId == _INTERFACE_ID_ERC721
        || interfaceId == _INTERFACE_ID_ERC721_METADATA
        || interfaceId == _INTERFACE_ID_EIP2981
        || super.supportsInterface(interfaceId);
    }

    // ---
    // Minting
    // ---

    // @dev Mint new tokens from the contract.
    function mint(uint256 quantity) public payable onlyActive onlyNonPaused {
        require(quantity <= maxQuantityPerTransaction, StringsUtil.concat("Max limit per transaction is ", StringsUtil.uint2str(maxQuantityPerTransaction)));
        require(invocations.add(quantity) <= maxInvocations, "Must not exceed max invocations.");
        require(msg.value >= (mintPriceInWei * quantity), "Must send minimum value.");

        if (presaleMint && presaleActive) {
            require(isPresaleAddress[_msgSender()], "Wallet is not part of pre-sale.");
        }

        uint256 currentMints = 0;
        if (maxPerWalletEnabled) {
            currentMints = mintsPerWallet[_msgSender()];
            require(currentMints.add(quantity) <= maxPerWalletQuantity, "Must not exceed max mints per wallet.");
        }

        uint8 i;
        uint256 tokenId = nextTokenId;
        for (i = 0; i < quantity; i++) {
            _safeMint(_msgSender(), tokenId);
            emit Mint(tokenId, _msgSender());
            tokenId = tokenId.add(1);
        }

        // Update the nextTokenId
        nextTokenId = nextTokenId.add(quantity);

        // Update number of invocations
        invocations = invocations.add(quantity);

        uint256 balance = msg.value;
        uint256 refund = balance.sub((mintPriceInWei * quantity));
        if (refund > 0) {
            balance = balance.sub(refund);
            (bool refundSuccess, ) = payable(_msgSender()).call{value: refund}("");
            require(refundSuccess, "Transfer failed.");
            emit Payout(refund, _msgSender());
        }

        // Auto-Payout Feature
        if (autoPayout) {
            // Payout imnotArt
            uint256 imnotArtPayout = SafeMath.div(SafeMath.mul(balance, imnotArtBps), 10000);
            if (imnotArtPayout > 0) {
                balance = balance.sub(imnotArtPayout);
                (bool imnotArtPayoutSuccess, ) = payable(imnotArtPayoutAddress).call{value: imnotArtPayout}("");
                require(imnotArtPayoutSuccess, "Transfer failed.");
                emit Payout(imnotArtPayout, imnotArtPayoutAddress);
            }

            // Payout Artist
            (bool artistPayoutSuccess, ) = payable(artistPayoutAddress).call{value: balance}("");
            require(artistPayoutSuccess, "Transfer failed.");
            emit Payout(balance, artistPayoutAddress);
        }

        if (maxPerWalletEnabled) {
            mintsPerWallet[_msgSender()] = currentMints.add(quantity);
        }
    }

    // ---
    // Functions
    // ---

    // @dev Override the updateImNotArtPayoutAddress function to account for admin security.
    function updateImNotArtPayoutAddress(address _payoutAddress) external override onlyAdmin {
        imnotArtPayoutAddress = _payoutAddress;
    }

    // @dev Override the updateArtistPayoutAddress function to account for admin security.
    function updateArtistPayoutAddress(address _payoutAddress) external override onlyAdmin {
        artistPayoutAddress = _payoutAddress;
    }

    // @dev Update the base URL that will be used for the tokenURI() function.
    function updateMetadataBaseUri(string memory _metadataBaseUri) public onlyAdmin {
        metadataBaseUri = _metadataBaseUri;
    }

    // @dev Bulk add wallets to pre-sale list.
    function bulkAddPresaleWallets(address[] memory presaleWallets) external override onlyAdmin {
        require(presaleWallets.length > 1, "Use addPresaleWallet function instead.");
        uint amountOfPresaleWallets = presaleWallets.length;
        for (uint i = 0; i < amountOfPresaleWallets; i++) {
            isPresaleAddress[presaleWallets[i]] = true;
        }
    }

    // @dev Add a wallet to pre-sale list.
    function addPresaleWallet(address presaleWallet) public onlyAdmin {
        isPresaleAddress[presaleWallet] = true;
    }

    // @dev Remove a wallet from pre-sale list.
    function removePresaleWallet(address presaleWallet) public onlyAdmin {
        require((_msgSender() != presaleWallet), "Cannot remove self.");

        isPresaleAddress[presaleWallet] = false;
    }

    // @dev Update the max invocations, this can only be done BEFORE the minting is active.
    function updateMaxInvocations(uint256 newMaxInvocations) public onlyAdmin {
        require(!active, "Cannot change max invocations after active.");
        maxInvocations = newMaxInvocations;
    }

    // @dev Update the max quantity per transaction, this can only be done BEFORE the minting is active.
    function updateMaxQuantityPerTransaction(uint256 newMaxQuantityPerTransaction) public onlyAdmin {
        require(!active, "Cannot change max quantity per transaction after active.");
        maxQuantityPerTransaction = newMaxQuantityPerTransaction;
    }

    // @dev Update the mint price, this can only be done BEFORE the minting is active.
    function updateMintPriceInWei(uint256 newMintPriceInWei) public onlyAdmin {
        require(!active, "Cannot change mint price after active.");
        mintPriceInWei = newMintPriceInWei;
    }

    // @dev Enable minting and make contract active.
    function enableMinting() public onlyAdmin {
        active = true;
    }

    // @dev Enable public sale on the mint function.
    function enablePublicSale() public onlyAdmin {
        presaleActive = false;
    }

    // @dev Toggle the pause state of minting.
    function toggleMintPause() public onlyAdmin {
        paused = !paused;
    }

    // @dev Override the tokenURI function to return the base URL + concat and tokenId.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist.");

        return StringsUtil.concat(metadataBaseUri, StringsUtil.uint2str(tokenId));
    }

    // ---
    // Secondary Marketplace Functions
    // ---

    // @dev Rarible royalties V2 implementation.
    function getRaribleV2Royalties(uint256 id) external view override returns (LibPart.Part[] memory) {
        require(_exists(id), "Token ID does not exist.");

        LibPart.Part[] memory royalties = new LibPart.Part[](1);
        royalties[0] = LibPart.Part({
            account : payable(address(this)),
            value : uint96(royaltyFeeBps)
        });

        return royalties;
    }

    // @dev EIP-2981 royalty standard implementation.
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 amount) {
        require(_exists(tokenId), "Token ID does not exist.");

        uint256 royaltyPercentageAmount = SafeMath.div(SafeMath.mul(salePrice, royaltyFeeBps), 10000);
        return (payable(address(this)), royaltyPercentageAmount);
    }
}