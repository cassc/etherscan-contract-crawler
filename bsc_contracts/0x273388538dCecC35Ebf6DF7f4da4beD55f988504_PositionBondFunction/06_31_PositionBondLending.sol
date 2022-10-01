pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../impl/Issuer.sol";
import "../impl/lending/UnderlyingAssetLending.sol";
import "../impl/lending/FaceAssetLending.sol";
import "../impl/SaleStrategyBase.sol";
import "../impl/PositionAdmin.sol";
import "../impl/lending/LoanRatio.sol";

import "../interfaces/IPositionBondFunction.sol";
import "../interfaces/IPositionBondLending.sol";
import "../impl/lending/BondStatusLending.sol";
import "../impl/lending/BondUnitLending.sol";

contract PositionBondLending is
    Issuer,
    BondStatusLending,
    UnderlyingAssetLending,
    FaceAssetLending,
    BondUnitLending,
    IPositionBondLending,
    LoanRatio,
    ReentrancyGuard
{
    IPositionBondFunction private positionBondFunction;
    bool private initialized;
    uint256 public fee;
    address public positionAdmin;
    uint256 public soldAmount;
    address public bondRouter;

    modifier onlyBondRouter() {
        require(msg.sender == bondRouter,  "onlyBondRouter" );
        _;
    }

    function bondInitialize(
        BondInformation memory bondInformation,
        AssetInformation memory assetInformation,
        BondSetup memory bondSetup,
        address issuer_
    ) external nonReentrant {
        require(!initialized, "!init");
        initialized = true;

        positionBondFunction = bondSetup.positionBondFunction;
        LoanRatio.initChainLinkPriceFeed(bondSetup.chainLinkPriceFeed);
        positionAdmin = bondSetup.positionAdmin;
        fee = bondSetup.fee;
        UnderlyingAssetLending.updateUnderlyingAmount(assetInformation.collateralAmount);
        bondRouter = bondSetup.bondRouter;
        setIssuer(issuer_);


        UnderlyingAssetLending.initUnderlyingAssetLending(
            assetInformation.underlyingAssetType,
            assetInformation.underlyingAsset,
            assetInformation.collateralAmount,
            assetInformation.nftIds
        );

        FaceAssetLending.initFaceAssetLending(
            assetInformation.faceAssetType,
            assetInformation.faceAsset,
            assetInformation.faceValue,
            bondInformation.issuePrice
        );

        LoanRatio.initLoanLoanRatio(
            assetInformation.priceFeedKeyUnderlyingAsset,
            assetInformation.priceFeedKeyFaceAsset
        );


        BondUnitLending.initBondUnit(
            bondInformation.bondSupply,
            bondInformation.bondName,
            bondInformation.bondSymbol
        );

        BondStatusLending.setDuration(bondInformation.duration);
        BondStatusLending.active(
            bondInformation.startSale,
            bondInformation.active,
            bondInformation.active + getDuration()
        );
    }

    function isNotReachMaxLoanRatio() public view override returns (bool) {

        uint256 bondAmountInPhase = BondStatusLending.getStatus() ==
            Status.Pending
            ? bondSupply
            : totalSupply();
        return
            LoanRatio.isNotReachMaxLoanRatio(
                UnderlyingAssetLending._underlyingAssetAmount(),
                (FaceAssetLending.getIssuePrice() * bondAmountInPhase) /
                    (10**18)
            );
    }

    // If underlyingAsset is Tokens or Ether,  amountsRemoved must be format [123*10**18], only one element
    // and the value is amount issuer want to remove
    // If underlyingAsset is NFT, amountsRemoved must be format [1,3,5]. These are indexes of NFTs issuer want to remove
    function removeCollateral(uint256[] calldata amountsRemoved)
        public
        onlyIssuer
        onlyOnSaleOrActive
        nonReentrant
    {
        uint256 totalAmountRemoved = positionBondFunction
            .verifyRemoveCollateral(
                amountsRemoved,
                UnderlyingAssetLending.getNfts(),
                UnderlyingAssetLending._underlyingAssetAmount(),
                getUnderlyingAssetType()
            );
        require(totalAmountRemoved > 0, "!AmountRemove");
        require(
            LoanRatio.isNotReachMaxLoanRatio(
                UnderlyingAssetLending._underlyingAssetAmount() -
                    totalAmountRemoved,
                (FaceAssetLending.getIssuePrice() * totalSupply()) / (10**18)
            ),
            "!Remove"
        );
        UnderlyingAssetLending._removeCollateral(
            amountsRemoved,
            totalAmountRemoved
        );
        emit CollateralRemoved(totalAmountRemoved);
    }

    function addCollateral(uint256[] calldata amountTransferAdded)
        public
        payable
        onlyIssuer
        onlyOnSaleOrActive
        nonReentrant
    {
        uint256 _underlyingAssetType = getUnderlyingAssetType();
        require(
            positionBondFunction.verifyAddCollateral(
                amountTransferAdded,
                _underlyingAssetType
            ),
            "!pass"
        );
        uint256 amountAdded;
        if (_underlyingAssetType == 0) {
            amountAdded = amountTransferAdded[0];
        } else if (_underlyingAssetType == 1) {
            amountAdded = positionBondFunction.getParValue(amountTransferAdded);
        } else if (_underlyingAssetType == 2) {
            amountAdded = msg.value;
        }
        UnderlyingAssetLending._addCollateral(amountTransferAdded, amountAdded);
        emit CollateralAdded(amountAdded);
    }

    function cancel() public onlyIssuer onlyPending nonReentrant {
        BondStatusLending._setUnderlyingAssetCanceled();
        UnderlyingAssetLending.claimUnderlyingAsset();
        emit BondCanceled(issuer());
    }

    /**
     * @dev see {IPositionBondLending-claimUnderlyingAsset}
     */
    function claimUnderlyingAsset()
        public
        override(IPositionBondLending, UnderlyingAssetLending)
        onlyIssuer
    {
        if ( totalSupply() == 0) {
            require(
                BondStatusLending.getStatus() == Status.Active
                || BondStatusLending.getStatus() == Status.Matured,
                "!Claim"
            );
            UnderlyingAssetLending.claimUnderlyingAsset();
            BondStatusLending._setUnderlyingAssetStatusRefunded();
            BondStatusLending.matured();
        } else {
            require(BondStatusLending._isReadyToClaim(), "!claim");
            UnderlyingAssetLending.claimUnderlyingAsset();
            BondStatusLending._setUnderlyingAssetStatusRefunded();
            BondStatusLending.matured();
        }
    }

    function claimLiquidatedUnderlyingAsset() public onlyLiquidated {
        uint256 _bondBalance = balanceOf(msg.sender);
        require(_bondBalance != 0, "!balance");
        UnderlyingAssetLending._transferUnderlyingAssetLiquidated(
            _bondBalance,
            totalSupply()
        );
        _burn(msg.sender, _bondBalance);
    }

    /// @dev see {IPositionBondLending-claimSoldAmount}
    function claimSoldAmount(uint256 amount)
        external
        virtual
        onlyIssuer
        nonReentrant
    {
        require(getStatus() != Status.Pending && getStatus() != Status.OnSale, "!claimSold");
        uint256 maxClaim =  ((totalSupply() * getIssuePrice())/ 10 ** 18);
        require(
            totalSoldAmountClaimed <= maxClaim,
            "!claim"
        );

        uint256 minClaim =  FaceAssetLending.getBalanceFaceAmount();
        uint256 amountClaim = minClaim >= maxClaim ? maxClaim : minClaim;
        totalSoldAmountClaimed += amountClaim;

        uint256 fee = calculateFee(amountClaim);
        FaceAssetLending._transferOut(amountClaim - fee, msg.sender);
        if (fee > 0) {
            FaceAssetLending._transferOut(fee, positionAdmin);
        }
        emit SoldAmountClaimed(msg.sender, amountClaim);
    }

    /**
     * @dev see {IPositionBond-claimFaceValue}
     */
    function claimFaceValue()
        external
        onlyMatured
        onlyReadyToClaimFaceValue
        nonReentrant
    {
        uint256 _bondBalance = balanceOf(msg.sender);
        require(_bondBalance != 0, "!balance");
        _burn(msg.sender, _bondBalance);
        FaceAssetLending._transferFaceValueOut(_bondBalance);
    }

    /**
     * @dev see {IPositionBond-purchase}
     */
    function purchaseBondLending(uint256 bondAmount, address recipient)
        external
        payable
        onlyOnSale
        onlyBondRouter
        notIssuer(recipient)
        nonReentrant
        returns (uint256)
    {
         uint256 _faceAmount = getFaceAmount(bondAmount);
        require(_faceAmount != 0 && bondAmount != 0, "!bond");
        BondUnitLending._mint(recipient, bondAmount);
        _afterPurchase(recipient, bondAmount);
        soldAmount += bondAmount;
        emit Purchased(recipient, _faceAmount, bondAmount);
        return _faceAmount;
    }

    function repayBondLending() external payable virtual onlyIssuer onlyActive {
        FaceAssetLending._transferRepaymentFaceValue(totalSupply());
        BondStatusLending._setUnderlyingAssetStatusReadyToClaim();
        // claim underlying asset in one transaction
        claimUnderlyingAsset();
    }

    /// @dev see {IPositionBond-liquidate}
    function liquidate() external nonReentrant {
        require(isCanLiquidate(), "!Liquidate");
        if (getUnderlyingAssetType() == 1) {
            (address underlyingAsset, ) = UnderlyingAssetLending
                .underlyingAsset();
            address tokenMapped = positionBondFunction.getTokenMapped(
                underlyingAsset
            );
            uint256 balanceBefore = IERC20(tokenMapped).balanceOf(
                address(this)
            );
            UnderlyingAssetLending.decompose(
                address(
                    positionBondFunction.getPosiNFTFactory()
                ),
                positionBondFunction.getTokenMapped(underlyingAsset)
            );
            UnderlyingAssetLending.updateUnderlyingAmount(
                IERC20(tokenMapped).balanceOf(address(this)) - balanceBefore
            );
        }

        BondStatusLending._setUnderlyingAssetStatusLiquidated();
        emit Liquidated(address(this), msg.sender, issuer());
    }

    /**
     *
     *      VIEW FUNCTIONS
     *
     */
    function isPurchasable(address caller) public view virtual returns (bool) {}

    function isCanLiquidate() public view returns (bool) {
        if (
            BondStatusLending.getUnderlyingAssetStatus() ==
            UnderlyingAssetStatus.ReadyToClaim ||
            BondStatusLending.getUnderlyingAssetStatus() ==
            UnderlyingAssetStatus.Liquidated ||
            BondStatusLending.getUnderlyingAssetStatus() ==
            UnderlyingAssetStatus.Refunded ||
            totalSupply() == 0
        ) {
            return false;
        }
        return
            (BondStatusLending._isMatured() ||
                LoanRatio.isLiquidate(
                    UnderlyingAssetLending._underlyingAssetAmount(),
                    FaceAssetLending._amountLending(totalSupply())
                ))
                ? true
                : false;
    }

    function faceAmount(address account) public view returns (uint256) {
        return FaceAssetLending._calculateFaceValueOut(balanceOf(account));
    }

    function getBondAmount(uint256 amount)
        public
        view
        virtual
        returns (uint256, uint256)
    {
        return (
            BondMath.calculateBondAmountWithFixPrice(
                amount,
                FaceAssetLending.getIssuePrice()
            ),
            amount
        );
    }

    function getFaceAmount(uint256 bondAmount) public view virtual  returns ( uint256){
        return BondMath.calculateFaceValue(bondAmount, FaceAssetLending.getIssuePrice());
    }

    function getFaceAssetAndType() external view returns (address faceAsset, uint256 faceAssetType) {
        return(FaceAssetLending.faceAsset(), FaceAssetLending.getFaceAssetType());
    }

    function getLoanRatio() public view returns (uint256) {
        return
            LoanRatio._getLoanRatio(
                UnderlyingAssetLending._underlyingAssetAmount(),
                FaceAssetLending._amountLending(totalSupply())
            );
    }

    /**
     *
     *      INTERNAL FUNCTIONS
     *
     */

    function calculateFee(uint256 amount) internal view returns (uint256) {
        return (amount * fee) / 10_000;
    }

    function _transferUnderlyingAsset()
        internal
        override(UnderlyingAssetLending, BondStatusLending)
    {}

    function _issuer() internal view override returns (address) {
        return issuer();
    }

    function _bondTransferable()
        internal
        override(BondUnitLending, BondStatusLending)
        returns (bool)
    {
        return BondStatusLending._bondTransferable();
    }

    /// @dev Hook function
    function _afterPurchase(address _buyer, uint256 _bondAmount)
        internal
        virtual
    {
        if (totalSupply() == bondSupply) {
            _updateTimePhase();
        }
    }
}