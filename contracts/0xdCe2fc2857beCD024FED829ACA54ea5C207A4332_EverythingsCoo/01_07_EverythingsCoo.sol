// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/*
 *                                           ..
 *                                       ..,d0KOc.
 *                                     .cOKKKdc0N0OOkxdoc;..
 *                                     '0MWKl. 'cc::cloxO0KOdc'.
 *                                    .oXXOd'            .,cd0KOo;.
 *                                   ;OXx'                   .,lkK0o,
 *                                 .cXKc.    .;:c:,.             ;OWNx,
 *                                .oX0,  ..:kXKkxxO0x,         .cOXKOXK:
 *                               .dNO'  .oKXXXx.  .;OKc       .kXKXd.:XK,
 *                              .dNO'   ;XMO,..     ,K0'      lNx... .xWo
 *                             .dNO'    ;XMO.       ;KO'  ..  lNx.    lNk.
 *                            .oNO'     .oKXk,.   .:OKc .oKK0ockXx'.  cNO.
 *                            lX0,        .;x0OxxkO0d'  ,0WMNk,.ck0OkkKWO.
 *                           cXK;            .,::;'.     .;;'     .;:cOWx.
 *                          :XK:                                     .xWo
 *             .          .lXK:                                      '0N:
 *        .,;:d0Oo.      .dXO,                                       :X0'
 *       .kNXNWkkNk.   .:0Xd.                                       .dWx.
 *     .c0WNd:d,,0W0xooON0:                                         '0X:
 *     :XNkoc.. ,0kcodddxkocccoko.                                  lNk.
 *     .lKKxc,. ;0c      .,:c:;x0:. ..                             .ONl
 *       .cx0KKo;xk'           .cdddOKo.                           cNO'
 *          .:KXc'okl'.          .:O0xxxlccldkl.    .             .kNl
 *            lNO' 'lddolc::::ccodxo'  ';:::,:xxl::okx;.   'c:...,xNO'
 *            .dNk'   .';:ccccc:;..            ':cc:,cddooddooddONW0;
 *             .dXO,                                   ....    ,ONk'
 *              .cKXo.                                        ,ONx.
 *                'dK0o.                                    'oKKl.
 *                  'dKKx:.                              .:xKKo.
 *                    .:x0KOdc,..                   .':okKKkc.
 *                       .,lkXWX0o. ,c::::::;. ,ldx0KK0xo;.
 *                          lXXkxl..:c::x0Okd'.,:;lKWd.
 *                         .oW0c;::;.  .dOdl:cc;..cXX:
 *                          .cxO0O0K0OxkXX0OOkO000K0l.
 *                              ....,cll:..    .','.
 */

contract EverythingsCoo is Ownable, Pausable, ERC721A {
    string internal _baseMetadataURI;

    address public withdrawalAddress;

    struct TokenAllocation {
        uint32 collectionSize;
        uint32 mintsPerTransaction;
        uint32 mintsPerWallet;
    }

    TokenAllocation public tokenAllocation;

    struct AuctionConfig {
        uint72 startPrice;
        uint72 floorPrice;
        uint72 priceDelta;
        uint32 expectedStepMintRate;
        uint32 startTime;
        uint32 endTime;
        uint32 stepDurationInSeconds;
    }

    AuctionConfig public auctionConfig;

    struct AuctionState {
        bool isEnabled;
        uint32 step;
        uint32 stepMints;
        uint72 stepPrice;
    }

    AuctionState internal _auctionState;

    constructor() ERC721A("EverythingsCoo", "ETC") {}

    /**
     * -----EVENTS-----
     */

    /**
     * @dev Emit on calls to auctionMint().
     */
    event AuctionMint(
        address indexed to,
        uint256 quantity,
        uint256 price,
        uint256 totalMinted,
        uint256 timestamp,
        uint256 step
    );

    /**
     * @dev Emit on calls to airdropMint().
     */
    event AirdropMint(address indexed to, uint256 quantity, uint256 price, uint256 totalMinted, uint256 timestamp);

    /**
     * @dev Emits on calls to setBaseMetadataURI()
     */
    event BaseMetadataURIChange(string baseMetadataURI, uint256 timestamp);

    /**
     * @dev Emits on calls to setWithdrawalAddress()
     */
    event WithdrawalAddressChange(address withdrawalAddress, uint256 timestamp);

    /**
     * @dev Emits on calls to withdraw()
     */
    event Withdrawal(address indexed withdrawalAddress, uint256 amount, uint256 timestamp);

    /**
     * @dev Emits on calls to setTokenAllocation()
     */
    event TokenAllocationChange(
        uint256 collectionSize,
        uint256 mintsPerTransaction,
        uint256 mintsPerWallet,
        uint256 timestamp
    );

    /**
     * @dev Emits on calls to setAuctionConfig()
     */
    event AuctionConfigChange(
        uint256 startPrice,
        uint256 floorPrice,
        uint256 priceDelta,
        uint256 expectedStepMintRate,
        uint256 startTime,
        uint256 endTime,
        uint256 stepDurationInSeconds,
        uint256 timestamp
    );

    /**
     * @dev Emits on calls to setExpectedStepMintRate()
     */
    event ExpectedStepMintRateChange(uint256 expectedStepMintRate, uint256 timestamp);

    /**
     * -----MODIFIERS-----
     */

    /**
     * @dev Check that a given mint transaction follows guidelines,
     * like not putting us over our total supply or minting too many NFTs in a single transaction,
     * (which is bad for 721A NFTs).
     */
    modifier checkMintLimits(uint256 quantity) {
        require(quantity > 0, "Mint quantity must be > 0");
        require(_totalMinted() + quantity <= tokenAllocation.collectionSize, "Exceeds total supply");
        require(quantity <= tokenAllocation.mintsPerTransaction, "Cannot mint this many in a single transaction");
        _;
    }

    /**
     * -----OWNER FUNCTIONS-----
     */

    /**
     * @dev Wrap the _pause() function from OpenZeppelin/Pausable
     * To allow preventing any mint operations while the project is paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Allow unpausing the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets `baseMetadataURI` for computing tokenURI().
     */
    function setBaseMetadataURI(string calldata baseMetadataURI) external onlyOwner {
        emit BaseMetadataURIChange(baseMetadataURI, block.timestamp);

        _baseMetadataURI = baseMetadataURI;
    }

    /**
     * @dev Sets `withdrawalAddress` for withdrawal of funds from the contract.
     */
    function setWithdrawalAddress(address withdrawalAddress_) external onlyOwner {
        require(withdrawalAddress_ != address(0), "withdrawalAddress_ cannot be the zero address");

        emit WithdrawalAddressChange(withdrawalAddress_, block.timestamp);

        withdrawalAddress = withdrawalAddress_;
    }

    /**
     * @dev Sends all ETH from the contract to `withdrawalAddress`.
     */
    function withdraw() external onlyOwner {
        require(withdrawalAddress != address(0), "withdrawalAddress cannot be the zero address");

        emit Withdrawal(withdrawalAddress, address(this).balance, block.timestamp);

        (bool success, ) = withdrawalAddress.call{value: address(this).balance}("");
        require(success, "Withdrawal transfer failed");
    }

    /**
     * @dev Sets `tokenAllocation` for mint phases.
     */
    function setTokenAllocation(
        uint32 collectionSize,
        uint32 mintsPerTransaction,
        uint32 mintsPerWallet
    ) external onlyOwner {
        require(collectionSize > 0, "collectionSize must be > 0");
        require(mintsPerTransaction > 0, "mintsPerTransaction must be > 0");
        require(mintsPerTransaction <= collectionSize, "mintsPerTransaction must be <= collectionSize");
        require(mintsPerWallet > 0, "mintsPerWallet must be > 0");
        require(mintsPerWallet <= collectionSize, "mintsPerWallet must be <= collectionSize");

        emit TokenAllocationChange(collectionSize, mintsPerTransaction, mintsPerWallet, block.timestamp);

        tokenAllocation.collectionSize = collectionSize;
        tokenAllocation.mintsPerTransaction = mintsPerTransaction;
        tokenAllocation.mintsPerWallet = mintsPerWallet;
    }

    /**
     * @dev Sets configuration for the auction mint.
     */
    function setAuctionConfig(
        uint72 startPrice,
        uint72 floorPrice,
        uint72 priceDelta,
        uint32 expectedStepMintRate,
        uint32 startTime,
        uint32 endTime,
        uint32 stepDurationInSeconds
    ) external onlyOwner {
        require(startPrice >= floorPrice, "startPrice must be >= floorPrice");
        require(priceDelta > 0, "priceDelta must be > 0");
        require(startTime >= block.timestamp, "startTime must be >= block.timestamp");
        require(endTime > startTime, "endTime must be > startTime");
        // Require stepDurationInSeconds to be at least ~1 block (current average is 14.5s per block)
        require(stepDurationInSeconds >= 30, "stepDurationInSeconds must be >= 30");

        emit AuctionConfigChange(
            startPrice,
            floorPrice,
            priceDelta,
            expectedStepMintRate,
            startTime,
            endTime,
            stepDurationInSeconds,
            block.timestamp
        );

        auctionConfig.startPrice = startPrice;
        auctionConfig.floorPrice = floorPrice;
        auctionConfig.priceDelta = priceDelta;
        auctionConfig.expectedStepMintRate = expectedStepMintRate;

        auctionConfig.startTime = startTime;
        auctionConfig.endTime = endTime;
        auctionConfig.stepDurationInSeconds = stepDurationInSeconds;

        // Set the current price of the auction to the start price,
        // and enable the auction
        _auctionState.isEnabled = true;
        _auctionState.stepPrice = startPrice;
    }

    /**
     * @dev Sets `expectedStepMintRate` for calculating price deltas.
     */
    function setExpectedStepMintRate(uint32 expectedStepMintRate) external onlyOwner {
        emit ExpectedStepMintRateChange(expectedStepMintRate, block.timestamp);

        auctionConfig.expectedStepMintRate = expectedStepMintRate;
    }

    /**
     * @dev Mints tokens to given address at no cost.
     */
    function airdropMint(address to, uint256 quantity) external onlyOwner checkMintLimits(quantity) {
        emit AirdropMint(to, quantity, 0, _totalMinted() + quantity, block.timestamp);

        _mint(to, quantity);
    }

    /**
     * -----INTERNAL FUNCTIONS-----
     */

    /**
     * @dev Base URI for computing tokenURI() (from the 721A contract). If set, the resulting URI for each
     * token will be the concatenation of the `baseMetadataURI` and the token ID. Overridden from the 721A contract.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseMetadataURI;
    }

    /**
     * @dev Returns the current auction price given the current step.
     */
    function _getAuctionPrice(uint256 currStep) internal view returns (uint256) {
        require(currStep >= _auctionState.step, "currStep must be >= auctionState.step");

        // No danger of either currStep or _auctionState.step being manipulated by an attacker,
        // and we need to do a strict equality check here to return the current auction price.
        //
        // slither-disable-next-line incorrect-equality
        if (currStep == _auctionState.step) {
            return _auctionState.stepPrice;
        }

        // passedSteps will always be > 0, because of the require & if statement above
        uint256 passedSteps = currStep - _auctionState.step;
        uint256 price = _auctionState.stepPrice;
        uint256 numMinted = _auctionState.stepMints;
        uint256 floorPrice = auctionConfig.floorPrice;
        uint256 priceDelta = auctionConfig.priceDelta;

        if (numMinted >= auctionConfig.expectedStepMintRate) {
            price += 3 * priceDelta;
        } else {
            // If the `priceChange` would put the price below the floor, return the floor
            price = floorPrice + priceDelta < price ? price - priceDelta : floorPrice;
        }

        // If there were steps where nobody minted anything, then determine price change for nothing minted
        if (passedSteps > 1) {
            uint256 aggregatePriceChange = (passedSteps - 1) * priceDelta;

            // If the `aggregatePriceChange` would put the price below the floor, return the floor
            price = floorPrice + aggregatePriceChange < price ? price - aggregatePriceChange : floorPrice;
        }

        return price;
    }

    /**
     * -----VIEW FUNCTIONS-----
     */

    /**
     * @dev Returns a tuple of the current step and price.
     */
    function getCurrentStepAndPrice() public view returns (uint256, uint256) {
        uint256 currentStep = getCurrentStep();
        uint256 currentPrice = _getAuctionPrice(currentStep);

        return (currentStep, currentPrice);
    }

    /**
     * @dev Returns the current step of the auction based on the elapsed time.
     */
    function getCurrentStep() public view returns (uint256) {
        require(_auctionState.isEnabled && block.timestamp >= auctionConfig.startTime, "Auction has not started");

        uint256 elapsedTime = block.timestamp - auctionConfig.startTime;
        uint256 step = Math.min(
            elapsedTime / auctionConfig.stepDurationInSeconds,
            (auctionConfig.endTime - auctionConfig.startTime) / auctionConfig.stepDurationInSeconds
        );

        return step;
    }

    /**
     * @dev Returns the current auction price.
     */
    function getCurrentAuctionPrice() external view returns (uint256) {
        (, uint256 price) = getCurrentStepAndPrice();

        return price;
    }

    /**
     * -----EXTERNAL FUNCTIONS-----
     */

    /**
     * @dev Mints `quantity` of tokens at the current auction price and transfers them to the sender.
     * If the sender sends more ETH than needed, it refunds them.
     */
    function auctionMint(uint256 quantity) external payable whenNotPaused checkMintLimits(quantity) {
        // We explicitly want to use tx.origin to check if the caller is a contract
        // solhint-disable-next-line avoid-tx-origin
        require(tx.origin == msg.sender, "Caller must be user");
        require(_auctionState.isEnabled && block.timestamp >= auctionConfig.startTime, "Auction has not started");
        require(block.timestamp < auctionConfig.endTime, "Auction has ended");
        require(
            _numberMinted(msg.sender) + quantity <= tokenAllocation.mintsPerWallet,
            "Cannot mint this many from a single wallet"
        );

        (uint256 auctionStep, uint256 auctionPrice) = getCurrentStepAndPrice();
        uint256 cost = auctionPrice * quantity;

        require(msg.value >= cost, "Insufficient payment");

        // Update auction state to the new step and new price
        if (auctionStep > _auctionState.step) {
            _auctionState.stepMints = 0;
            _auctionState.stepPrice = uint72(auctionPrice);
            _auctionState.step = uint32(auctionStep);
        }

        _auctionState.stepMints += uint32(quantity);
        emit AuctionMint(msg.sender, quantity, auctionPrice, _totalMinted() + quantity, block.timestamp, auctionStep);

        // Contracts can't call this function so we don't need _safeMint()
        _mint(msg.sender, quantity);

        if (msg.value > cost) {
            (bool success, ) = msg.sender.call{value: msg.value - cost}("");
            require(success, "Refund transfer failed");
        }
    }
}