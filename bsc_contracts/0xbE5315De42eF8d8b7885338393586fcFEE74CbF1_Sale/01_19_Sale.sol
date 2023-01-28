// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "AccessControl.sol";
import "IMiningPermit.sol";
import "WrappedNFT.sol";
import "MinterIERC20.sol";

contract Sale is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event MinerPurchased(uint256 busdValue, uint256 minerValue);

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant TRANSFEROUT_ROLE = keccak256("TRANSFEROUT_ROLE");

    struct TierBundleInformation {
        uint256 costInBusd;
        uint256 qtyTaxiNFTs;
        uint256 qtyLandNFTs;
        uint256 qtyGovernanceMiner;
        uint256 slabTotal;
        uint256 slabRemaining;
    }

    TierBundleInformation[] public tierBundles;

    WrappedNFT public wrappedTaxi;
    WrappedNFT public wrappedLand;
    IERC20 public SMiner;
    IERC20 public Busd;
    MinterIERC20 public Excavate;
    IMiningPermit public miningPermit;

    uint256 public slabCounter = 0;

    address treasury;

    uint256 minerPrice = 1;
    uint256 public currentRate;
    uint256 public slabTotalMinerAvailableForPurchase = 20000000000000000000;
    bool public presaleOpen = false;
    uint256 public totalRaised;
    uint256 public totalMinerSold;
    uint256 public maxPerWalletBUSDLimit = 2000 ether;

    bool isInitialised = false;

    function initialize(
        uint256 _startingRate,
        uint256 _slabTotalMinerAvailableToPurchase,
        uint256 _totalRaised,
        uint256 _totalMinerSold
    ) public {
        require(!isInitialised, "Already Initialised");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(TRANSFEROUT_ROLE, msg.sender);

        currentRate = _startingRate;
        slabTotalMinerAvailableForPurchase = _slabTotalMinerAvailableToPurchase;
        totalRaised = _totalRaised;
        totalMinerSold = _totalMinerSold;

        isInitialised = true;
    }

    function addNewTier(
        uint256 _costInBusd,
        uint256 _qtyTaxiNFTs,
        uint256 _qtyLandNFTs,
        uint256 _qtyGovernanceMiner,
        uint256 _slabTotal,
        uint256 _slabRemaining
    ) public onlyRole(OPERATOR_ROLE) {
        tierBundles.push(
            TierBundleInformation({
                costInBusd: _costInBusd,
                qtyTaxiNFTs: _qtyTaxiNFTs,
                qtyLandNFTs: _qtyLandNFTs,
                qtyGovernanceMiner: _qtyGovernanceMiner,
                slabTotal: _slabTotal,
                slabRemaining: _slabRemaining
            })
        );
    }

    function removeTier(uint256 _index) external onlyRole(OPERATOR_ROLE) {
        require(_index < tierBundles.length);
        tierBundles[_index] = tierBundles[tierBundles.length - 1];
        tierBundles.pop();
    }

    function setTier(
        uint256 _index,
        uint256 _costInBusd,
        uint256 _qtyTaxiNFTs,
        uint256 _qtyLandNFTs,
        uint256 _qtyGovernanceMiner,
        uint256 _slabTotal,
        uint256 _slabRemaining
    ) external onlyRole(OPERATOR_ROLE) {
        TierBundleInformation storage tier = tierBundles[_index];
        tier.costInBusd = _costInBusd;
        tier.qtyTaxiNFTs = _qtyTaxiNFTs;
        tier.qtyLandNFTs = _qtyLandNFTs;
        tier.qtyGovernanceMiner = _qtyGovernanceMiner;
        tier.slabTotal = _slabTotal;
        tier.slabRemaining = _slabRemaining;
    }

    function setTokens(
        address _wrappedTaxi,
        address _wrappedLand,
        address _miner,
        address _busd,
        address _excavate,
        address _miningPermit
    ) external onlyRole(OPERATOR_ROLE) {
        wrappedTaxi = WrappedNFT(_wrappedTaxi);
        wrappedLand = WrappedNFT(_wrappedLand);
        SMiner = IERC20(_miner);
        Busd = IERC20(_busd);
        Excavate = MinterIERC20(_excavate);
        miningPermit = IMiningPermit(_miningPermit);
    }

    function setTreasuryAddress(address _treasury)
        external
        onlyRole(OPERATOR_ROLE)
    {
        treasury = _treasury;
    }

    function getTier(uint256 amount) public view returns (uint256) {
        uint256 index = 0;
        uint256 index_cost = 0;
        for (uint256 i = 0; i < tierBundles.length; i++) {
            //available bundle eligible for reward
            if (
                amount >= tierBundles[i].costInBusd &&
                tierBundles[i].slabRemaining > 0
            ) {
                if (index_cost <= tierBundles[i].costInBusd) {
                    // closest index
                    index_cost = tierBundles[i].costInBusd;
                    index = i;
                }
            }
        }

        return index;
    }

    function getAllTier() public view returns (TierBundleInformation[] memory) {
        return tierBundles;
    }

    function purchase(uint256 amountIn) external {
        uint256 _index = getTier(amountIn);
        TierBundleInformation storage tier = tierBundles[_index];
        require(tier.slabRemaining > 0, "No more left in this tier.");
        require(
            IERC20(Busd).balanceOf(msg.sender) >= amountIn,
            "Not enough Busd in your wallet!"
        );
        uint256 minerToGive = amountIn / currentRate;
        // Giving back based on Max Purchasable Miner
        uint256 amountOut = min(
            (slabTotalMinerAvailableForPurchase - slabCounter),
            minerToGive
        );
        amountIn = amountOut * currentRate;

        // if the slab give its whole amount
        minerToGive = amountIn / currentRate;

        require(presaleOpen, "Presale is not open!");
        require(
            slabCounter < slabTotalMinerAvailableForPurchase,
            "All Miner sold out. Wait for the next round on Miner."
        );
        //to do
        require(
            amountIn <= maxPerWalletBUSDLimit,
            "Exceeded Buy Limit. Ask a discord admin on how to buy more."
        );
        require(
            amountOut <= IERC20(SMiner).balanceOf(address(this)),
            "Not enough Miner to sell!"
        );
        require(
            IERC20(Busd).balanceOf(msg.sender) >= amountIn,
            "Not enough Busd in your wallet!"
        );
        checkIfHasMiningPermitIfNotMintOne(msg.sender);
        slabCounter += amountOut;
        tier.slabRemaining--;
        totalRaised += amountIn;
        totalMinerSold += amountOut;
        Busd.safeTransferFrom(msg.sender, treasury, amountIn);
        // TODO remember to transfer some Miner to this contract
        SMiner.safeTransfer(msg.sender, minerToGive);
        // TODO remember to give this contract mint permission on wrappedLand - runtime
        for (uint256 i = 0; i < tier.qtyLandNFTs; i++) {
            wrappedLand.safeMint(msg.sender);
        }
        // TODO remember to give this contract mint permission on wrappedTaxi - runtime
        for (uint256 i = 0; i < tier.qtyTaxiNFTs; i++) {
            wrappedTaxi.safeMint(msg.sender);
        }
        // TODO grant minter role to this contract on GMiner - runtime
        if(tier.qtyGovernanceMiner > 0){
            Excavate.mint(msg.sender, tier.qtyGovernanceMiner);
        }
        emit MinerPurchased(amountIn, amountOut);
    }

    function transferOut(
        address _token,
        uint256 value,
        address to
    ) public onlyRole(TRANSFEROUT_ROLE) {
        require(
            value >= IERC20(_token).balanceOf(address(this)),
            "Requested Value Exceeds Balance."
        );
        IERC20(_token).safeTransfer(to, value);
    }

    function setNewSlab(uint256 _newSlab, uint256 _newPrice)
        external
        onlyRole(OPERATOR_ROLE)
    {
        slabCounter = 0;
        currentRate = _newPrice;
        slabTotalMinerAvailableForPurchase = _newSlab;
    }

    function startPresale() external onlyRole(OPERATOR_ROLE) {
        presaleOpen = true;
    }

    function pausePresale() external onlyRole(OPERATOR_ROLE) {
        presaleOpen = false;
    }

    function getSMinerBalance() external view returns (uint256) {
        return SMiner.balanceOf(address(this));
    }

    function getBUSDBalance() external view returns (uint256) {
        return totalRaised;
    }

    function checkIfHasMiningPermitIfNotMintOne(address target) internal {
        if (!miningPermit.checkPermitOfWallet(target)) {
            miningPermit.issuePermit(target);
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function setPerWalletMaxBuyLimitBUSD(uint256 _limit)
        external
        onlyRole(OPERATOR_ROLE)
    {
        maxPerWalletBUSDLimit = _limit;
    }
}