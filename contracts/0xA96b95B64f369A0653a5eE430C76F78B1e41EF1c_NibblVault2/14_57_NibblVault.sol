// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.10;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { BancorFormula } from "./Bancor/BancorFormula.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { NibblVaultFactory } from "./NibblVaultFactory.sol";
import { Twav } from "./Twav/Twav.sol";
import { EIP712Base } from "./Utilities/EIP712Base.sol";
import { INibblVault } from "./Interfaces/INibblVault.sol";

/// @title Vault to lock NFTs and fractionalize ERC721 to ERC20.
/// @dev This contract uses Bancor Formula to create an automated market for fractionalized ERC20s.
/// @dev This contract creates 2 bonding curves, referred to as primary curve and secondary curve.
/// @dev The primary curve has fixed specifications and reserveRatio.
/// @dev The secondary curve is dynamic and has a variable reserveRatio, which depends on initial conditions given by the curator and the fee accumulated by the curve.
contract NibblVault is INibblVault, BancorFormula, ERC20Upgradeable, Twav, EIP712Base {

    using SafeERC20 for IERC20;

    /// @notice Scale for calculations to avoid rounding errors
    uint256 private constant SCALE = 1_000_000; 

    /// @notice Reserve ratio of primary curve 
    /// @dev primaryReserveRatio has been multiplied with SCALE
    /// @dev primaryReserveRatio lies between 0 and 1_000_000, 500_000 is equivalent to 50% reserve ratio
    uint32 private constant primaryReserveRatio = 300_000; //30%
    
    /// @notice The premium percentage above the buyoutBid at which the buyout is rejected
    /// @dev REJECTION_PREMIUM has been multiplied with SCALE
    /// @dev REJECTION_PREMIUM lies between 0 and 1_000_000, i.e. 100_000 means 10%
    /// @dev if REJECTION_PREMIUM is 15% and the buyoutBid is 100, then the buyout is rejected when the valuation reaches 115
    uint256 private constant REJECTION_PREMIUM = 150_000; //15%

    /// @notice The days until which a buyout bid is valid, if the bid isn't rejected in buyout duration time, its automatically considered boughtOut
    uint256 private constant BUYOUT_DURATION = 4 days; 


    /// @notice minimum reserve ratio that the secondary curve can have initially 
    uint256 private constant MIN_SECONDARY_RESERVE_RATIO = 50_000;

    /// @notice minimum curator fee that the curator will get on adding minimal liquidity to the secondary curve
    uint256 private constant MIN_CURATOR_FEE = 7_500; //.75%

    uint256 private constant CURATOR_FEE_VARIABLE = 7_500; //.75%
    
    uint256 private constant MAX_CURATOR_FEE = 15_000; //1.5%

    /// @notice minimum reserve balance that the secondary curve can have initially 
    uint256 private constant MIN_SECONDARY_RESERVE_BALANCE = 1e9;

    bytes32 private constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice The percentage of fee that goes for liquidity in lower curve until its reserve ratio becomes equal to primaryReserveRatio
    uint256 private curveFee;

    /// @notice The reserve ratio of the secondary curve.
    /// @dev secondaryReserveRatio has been multiplied with SCALE
    /// @dev secondary reserve ratio is dynamic and it can be <= primaryReserveRatio
    uint32 public secondaryReserveRatio;

    /// @notice address of the factory contract
    address payable public factory;

    /// @notice address of the original NFT owner
    address public curator; 

    /// @notice token address of the NFT being deposited in the vault
    address public assetAddress;

    /// @notice token ID of the NFT being deposited in the vault  
    uint256 public assetID;

    /// @notice address which triggered the buyout
    address public bidder; 

    /// @notice initial price of the fractional ERC20 Token set by the curator
    uint256 public initialTokenPrice;

    /// @notice fictitious primary reserve balance, this is used for calculation purposes of trading on primary bonding curve.
    /// @dev This variable defines the amount of reserve token that should be in the secondary curve if secondaryReserveRatio == primaryReserveRatio
    /// @dev This variable also defines the amount of reserve token that should be in the primary curve if the primary curve started from 0 and went till initialTokenSupply 
    uint256 public fictitiousPrimaryReserveBalance;

    /// @notice the valuation at which the buyout is rejected.
    uint256 public buyoutRejectionValuation; 
    
    /// @notice deposit made by bidder to initiate buyout 
    /// @dev buyoutValuationDeposit = currentValuation - ((reserveTokens in primary curve) + (reserveTokens in secondary curve))
    uint256 public buyoutValuationDeposit; 
    
    /// @notice initial token supply minted by curator
    uint256 public initialTokenSupply; 
    
    /// @notice reserve balance of the primary curve
    uint256 public primaryReserveBalance;
    
    /// @notice reserve balance of the secondary curve
    uint256 public secondaryReserveBalance;
    
    /// @notice total value of unclaimed fees accrued to the curator via trading on the bonding curve
    uint256 public feeAccruedCurator; 
    
    /// @notice the time at which the current buyout ends
    uint256 public buyoutEndTime; 
    
    /// @notice valuation at which the buyout was triggered
    uint256 public buyoutBid;

    /// @notice percentage of trading fee on the bonding curve that goes to the curator
    uint256 public curatorFee;

    /// @notice total value of unclaimed buyout bids
    uint256 public totalUnsettledBids; 

    /// @notice minimum time after which buyout can be triggered
    uint256 public minBuyoutTime;

    /// @notice mapping of buyout bidders and their respective unsettled bids
    mapping(address => uint256) public unsettledBids; 
    mapping(address => uint256) public nonces; 
    
    enum Status {initialized, buyout}

    ///@notice current status of vault
    Status public status;

    ///@notice reentrancy guard
    uint256 private unlocked = 2;

    string public imageUrl;

    modifier lock() {
        require(unlocked == 1, 'NibblVault: LOCKED');
        unlocked = 2;
        _;
        unlocked = 1;
    }


    /// @notice To check if buyout hasn't succeeded
    /// @dev Check for the case when buyoutTime has not passed or buyout has been rejected
    modifier notBoughtOut() {
        require(buyoutEndTime > block.timestamp || buyoutEndTime == 0,'NibblVault: Bought Out');
        _;
    }

    /// @notice To check if buyout has succeeded
    /// @dev For the case when buyoutTime has passed and buyout has not been rejected
    modifier boughtOut() {
        require(status == Status.buyout, "NibblVault: status != buyout");
        require(buyoutEndTime <= block.timestamp, "NibblVault: buyoutEndTime <= now");
        _;
    }

    /// @notice To check if system isn't paused
    /// @dev pausablity implemented in factory
    modifier whenNotPaused() {
        require(!NibblVaultFactory(factory).paused(), 'NibblVault: Paused');
        _;
    }

    constructor () {
        _disableInitializers();
    }

    /// @notice the function to initialize proxy vault parameters
    /// @param _tokenName name of the fractionalized ERC20 token to be created
    /// @param _tokenSymbol symbol of the fractionalized ERC20 token
    /// @param _assetAddress address of the ERC721 being fractionalized
    /// @param _assetID tokenId of the ERC721 being fractionalized
    /// @param _curator owner of the asset getting fractionalized
    /// @param _initialTokenSupply desired initial supply to be minted to curator
    /// @param _initialTokenPrice desired initial token price set by curator 
    /// @param  _minBuyoutTime minimum time after which buyout can be triggered 
    /// @dev valuation = price * supply
    /// @dev reserveBalance = valuation * reserveRatio
    /// @dev Reserve Ratio = Reserve Token Balance / (Continuous Token Supply x Continuous Token Price)
    /// @dev curatorFee is proportional to initialLiquidity added by user. 
    /// @dev curatorFee can be maximum of 2 * MinimumCuratorFee.

    function initialize(
        string memory _tokenName, 
        string memory _tokenSymbol, 
        address _assetAddress,
        uint256 _assetID,
        address _curator,
        uint256 _initialTokenSupply,
        uint256 _initialTokenPrice,
        uint256 _minBuyoutTime
    ) external override initializer payable {
        uint32 _secondaryReserveRatio = uint32((msg.value * SCALE * 1e18) / (_initialTokenSupply * _initialTokenPrice));
        require(_secondaryReserveRatio <= primaryReserveRatio, "NibblVault: Excess initial funds");
        require(_secondaryReserveRatio >= MIN_SECONDARY_RESERVE_RATIO, "NibblVault: secResRatio too low");
        INIT_EIP712("NibblVault", "1");
        __ERC20_init(_tokenName, _tokenSymbol);
        unlocked = 1;
        initialTokenPrice=_initialTokenPrice;
        factory = payable(msg.sender);
        assetAddress = _assetAddress;
        assetID = _assetID;
        curator = _curator;
        initialTokenSupply = _initialTokenSupply;
        uint256 _primaryReserveBalance = (primaryReserveRatio * _initialTokenSupply * _initialTokenPrice) / (SCALE * 1e18);
        primaryReserveBalance = _primaryReserveBalance;
        fictitiousPrimaryReserveBalance = _primaryReserveBalance;
        secondaryReserveBalance = msg.value;
        secondaryReserveRatio = _secondaryReserveRatio;
        //curator fee is proportional to the secondary reserve ratio/primaryReserveRatio i.e. initial liquidity added by curator
        curatorFee = (((_secondaryReserveRatio - MIN_SECONDARY_RESERVE_RATIO) * CURATOR_FEE_VARIABLE) / (primaryReserveRatio - MIN_SECONDARY_RESERVE_RATIO)) + MIN_CURATOR_FEE; //curator fee is proportional to the secondary reserve ratio/primaryReseveRatio i.e. initial liquidity added by curator
        curveFee = MAX_CURATOR_FEE - curatorFee;
        minBuyoutTime = _minBuyoutTime;
        _mint(_curator, _initialTokenSupply);
    }

    /// @notice Function used to charge fee on trades
    /// @dev There are 3 different fees charged - admin, curator and curve
    /// @dev Admin fee percentage is fetched from the factory contract and the fee charged is transferred to factory contract
    /// @dev Curator fee is fetched from curatorFee variable and total fee accrued is stored in feeAccruedCurator variable
    /// @dev Curve fee is fetched from the curveFee variable and is added to the secondaryReserveBalance variable
    /// @param _amount amount to charge fee on either a buy or sell order, fee is charged in reserve token
    /// @return the amount after fee is deducted
    function _chargeFee(uint256 _amount) private returns(uint256) {
        address payable _factory = factory;
        uint256 _adminFeeAmt = NibblVaultFactory(_factory).feeAdmin();
        uint256 _feeAdmin = (_amount * _adminFeeAmt) / SCALE ;
        uint256 _feeCurator = (_amount * curatorFee) / SCALE ;
        uint256 _feeCurve = (_amount * curveFee) / SCALE ;
        feeAccruedCurator += _feeCurator;
        //_maxSecondaryBalanceIncrease: is the max amount of secondary reserve balance that can be added to the vault
        //_maxSecondaryBalanceIncrease cannot be more than fictitiousPrimaryReserveBalance
        uint256 _maxSecondaryBalanceIncrease = fictitiousPrimaryReserveBalance - secondaryReserveBalance;
        // _feeCurve can't be higher than _maxSecondaryBalanceIncrease
        _feeCurve = _maxSecondaryBalanceIncrease > _feeCurve ? _feeCurve : _maxSecondaryBalanceIncrease; // the curve fee is capped so that secondaryReserveBalance <= fictitiousPrimaryReserveBalance
        secondaryReserveBalance = secondaryReserveBalance + _feeCurve;
        secondaryReserveRatio = uint32((secondaryReserveBalance * SCALE * 1e18) / (initialTokenSupply * initialTokenPrice)); //secondaryReserveRatio is updated on every trade 
        if(_feeAdmin > 0) {
            safeTransferETH(_factory, _feeAdmin); //Transfers admin fee to the factory contract
        }
        return _amount - (_feeAdmin + _feeCurator + _feeCurve);
    }

    /// @notice Function to charge fee in secondary curve
    /// @dev only admin and curator fee is charged in secondary curve
    /// @param _amount amount to charge fee on trade order, fee is charged in reserve token
    /// @return amount of tokens after fee is deducted
    function _chargeFeeSecondaryCurve(uint256 _amount) private returns(uint256) {
       address payable _factory = factory;
        uint256 _adminFeeAmt = NibblVaultFactory(_factory).feeAdmin();
        uint256 _feeAdmin = (_amount * _adminFeeAmt) / SCALE ;
        uint256 _feeCurator = (_amount * curatorFee) / SCALE ;
        feeAccruedCurator += _feeCurator;
        if(_adminFeeAmt > 0) {
            safeTransferETH(_factory, _feeAdmin); //Transfers admin fee to the factory contract
        }
        return _amount - (_feeAdmin + _feeCurator);
    }

    /// @notice Maximum number of reserve tokens that can be held on SecondaryCurve at current secondary reserve ratio
    /// @dev The max continuous tokens on SecondaryCurve is equal to initialTokenSupply
    /// @dev Reserve Token Balance = Reserve Ratio * (Continuous Token Supply x Continuous Token Price)
    function getMaxSecondaryCurveBalance() private view returns(uint256){
            return ((secondaryReserveRatio * initialTokenSupply * initialTokenPrice) / (1e18 * SCALE));
    }

    /// @notice gives current valuation of the system
    /// @dev valuation = price * supply
    /// @dev fictitiousPrimaryReserveBalance doesn't denote any actual reserve balance its just for calculation purpose
    /// @dev Actual reserve balance in primary curve = primaryReserveBalance - fictitiousPrimaryReserveBalance
    /// @dev Total reserve balance = Actual reserve balance in primary curve + secondaryReserveBalance
    /// @dev Total reserve balance = (primaryReserveBalance - fictitiousPrimaryReserveBalance) + secondaryReserveBalance
    /// @dev Valuation = (Continuous Token Supply x Continuous Token Price) = Reserve Token Balance / Reserve Ratio
    /// @dev Valuation = If current supply is on secondary curve we use secondaryReserveBalance and secondaryReserveRatio to calculate valuation else we use primary reserve ratio and balance
    /// @return Current valuation of the system
    function getCurrentValuation() private view returns(uint256) {
            return totalSupply() < initialTokenSupply ? (secondaryReserveBalance * SCALE /secondaryReserveRatio) : ((primaryReserveBalance) * SCALE  / primaryReserveRatio);
    }

    /// @notice function to buy tokens on the primary curve
    /// @param _amount amount of reserve tokens to buy continuous tokens
    /// @dev This is executed when current supply >= initial supply
    /// @dev _amount is charged with fee
    /// @dev _purchaseReturn is minted to _to
    /// @return _purchaseReturn Purchase return
    function _buyPrimaryCurve(uint256 _amount, uint256 _totalSupply) private returns (uint256 _purchaseReturn) {
        uint256 _amountIn = _chargeFee(_amount);
        uint256 _primaryReserveBalance = primaryReserveBalance;
        _purchaseReturn = _calculatePurchaseReturn(_totalSupply, _primaryReserveBalance, primaryReserveRatio, _amountIn);
        primaryReserveBalance = _primaryReserveBalance + _amountIn;
    }
    /// @notice function to buy tokens on secondary curve
    /// @param _amount amount of reserve tokens to buy continuous tokens
    /// @dev This is executed when current supply < initial supply
    /// @dev only admin and curator fee is charged in secondary curve
    /// @dev _purchaseReturn is minted to _to
    /// @return _purchaseReturn Purchase return
    function _buySecondaryCurve(uint256 _amount, uint256 _totalSupply) private returns (uint256 _purchaseReturn) {
        uint256 _amountIn = _chargeFeeSecondaryCurve(_amount);
        uint256 _secondaryReserveBalance = secondaryReserveBalance;
        _purchaseReturn = _calculatePurchaseReturn(_totalSupply, _secondaryReserveBalance, secondaryReserveRatio, _amountIn);
        secondaryReserveBalance = _secondaryReserveBalance + _amountIn;
    }

    /// @notice The function to buy fractional tokens for reserveTokens
    /// @dev TWAV is updated only if buyout is active and only on first buy or sell txs of block.
    /// @dev It internally calls _buyPrimaryCurve or _buySecondaryCurve or both depending on the buyAmount and current supply
    /// @dev if current totalSupply < initialTokenSupply AND _amount to buy tokens for is greater than (maxSecondaryCurveBalance - currentSecondaryCurveBalance) then buy happens on secondary curve and primary curve both
    /// @param _minAmtOut Minimum amount of continuous token user receives, else the tx fails.
    /// @param _to Address to mint the purchase return to
    function buy(uint256 _minAmtOut, address _to) external override payable notBoughtOut lock whenNotPaused returns(uint256 _purchaseReturn) {
        //Make update on the first tx of the block
        if (status == Status.buyout) {
            uint32 _blockTimestamp = uint32(block.timestamp % 2**32);
            if (_blockTimestamp != lastBlockTimeStamp) {
                _updateTWAV(getCurrentValuation(), _blockTimestamp);   
                _rejectBuyout();
            }
        }
        uint256 _totalSupply = totalSupply();
        if (_totalSupply >= initialTokenSupply) {
            _purchaseReturn = _buyPrimaryCurve(msg.value, _totalSupply);
        } else {
            uint256 _lowerCurveDiff = getMaxSecondaryCurveBalance() - secondaryReserveBalance;
            if (_lowerCurveDiff >= msg.value) {
                _purchaseReturn = _buySecondaryCurve(msg.value, _totalSupply);
            } else {
                //Gas Optimization
                _purchaseReturn = initialTokenSupply - _totalSupply;
                secondaryReserveBalance += _lowerCurveDiff;
                // _purchaseReturn = _buySecondaryCurve(_to, _lowerCurveDiff);
                _purchaseReturn += _buyPrimaryCurve(msg.value - _lowerCurveDiff, _totalSupply + _purchaseReturn);
            } 
        }
        require(_minAmtOut <= _purchaseReturn, "NibblVault: Return too low");
        _mint(_to, _purchaseReturn);
        emit Buy(msg.sender, _purchaseReturn, msg.value);
    }

    /// @notice The function to sell fractional tokens on primary curve
    /// @dev Executed when currentSupply > initialSupply
    /// @dev _amount is charged with fee
    /// @param _amount Amount of tokens to be sold on primary curve
    /// @return _saleReturn Sale Return
    function _sellPrimaryCurve(uint256 _amount, uint256 _totalSupply) private returns(uint256 _saleReturn) {
        uint256 _primaryReserveBalance = primaryReserveBalance;
        _saleReturn = _calculateSaleReturn(_totalSupply, _primaryReserveBalance, primaryReserveRatio, _amount);
        primaryReserveBalance = _primaryReserveBalance - _saleReturn;
        _saleReturn = _chargeFee(_saleReturn);
    }

    /// @notice The function to sell fractional tokens on secondary curve
    /// @dev Executed when current supply <= initial supply
    /// @dev only admin and curator fee is charged in secondary curve
    /// @param _amount Amount of tokens to be sold on SecondaryCurve
    ///  @return _saleReturn Sale Return
    function _sellSecondaryCurve(uint256 _amount, uint256 _totalSupply) private returns(uint256 _saleReturn){
        uint256 _secondaryReserveBalance = secondaryReserveBalance;
        _saleReturn = _calculateSaleReturn(_totalSupply, _secondaryReserveBalance, secondaryReserveRatio, _amount);
        secondaryReserveBalance = _secondaryReserveBalance - _saleReturn;
        require(_secondaryReserveBalance - _saleReturn >= MIN_SECONDARY_RESERVE_BALANCE, "NibblVault: Excess sell");
        _saleReturn = _chargeFeeSecondaryCurve(_saleReturn);
    }

    /// @notice The function to sell fractional tokens for reserve token
    /// @dev TWAV is updated only if buyout is active and only on first buy or sell txs of block.
    /// @dev internally calls _sellPrimaryCurve or _sellSecondaryCurve or both depending on the sellAmount and current supply
    /// @dev if totalSupply > initialTokenSupply AND _amount to sell is greater than (_amtIn > totalSupply - initialTokenSupply) then sell happens on primary curve and secondary curve both
    /// @param _amtIn continuous Tokens to be sold
    /// @param _minAmtOut Minimum amount of reserve token user receives, else the tx fails.
    /// @param _to Address to receive the reserve token to
    function sell(uint256 _amtIn, uint256 _minAmtOut, address payable _to) external override notBoughtOut whenNotPaused lock returns(uint256 _saleReturn) {
        //Make update on the first tx of the block
        if (status == Status.buyout) {
            uint32 _blockTimestamp = uint32(block.timestamp % 2**32);

            if (_blockTimestamp >= lastBlockTimeStamp) {
                _updateTWAV(getCurrentValuation(), _blockTimestamp);   
                _rejectBuyout(); //For the case when TWAV goes up when updated on sell
            }
        }
        uint256 _initialTokenSupply = initialTokenSupply;
        uint256 _totalSupply = totalSupply();
        if(_totalSupply > _initialTokenSupply) {
            if ((_initialTokenSupply + _amtIn) <= _totalSupply) {
                _saleReturn = _sellPrimaryCurve(_amtIn, _totalSupply);
            } else {
                //Gas Optimization
                uint256 _tokensPrimaryCurve = _totalSupply - _initialTokenSupply;
                _saleReturn = primaryReserveBalance - fictitiousPrimaryReserveBalance;
                primaryReserveBalance -= _saleReturn;
                _saleReturn = _chargeFee(_saleReturn);
                // _saleReturn = _sellPrimaryCurve(_tokensPrimaryCurve);
                _saleReturn += _sellSecondaryCurve(_amtIn - _tokensPrimaryCurve, _initialTokenSupply);
            } } else {
                _saleReturn = _sellSecondaryCurve(_amtIn,_totalSupply);
        }
        require(_saleReturn >= _minAmtOut, "NibblVault: Return too low");
        _burn(msg.sender, _amtIn);
        safeTransferETH(_to, _saleReturn); //send _saleReturn to _to
        emit Sell(msg.sender, _amtIn, _saleReturn);
    }

    /// @notice Function to initiate buyout of ERC721
    /// @dev buyoutBid is set to current valuation
    /// @dev bidder needs to send funds equal to current valuation - ((primaryReserveBalance - fictitiousPrimaryReserveBalance) + secondaryReserveBalance) to initiate buyout
    /// This ensures that the original bidder doesn't need to support the whole valuation and liquidity in reserve can be used as well.
    /// Buyout is initiated only when total bid amount >= currentValuation but extra funds over currentValuation are sent back to bidder.
    function initiateBuyout() external override payable whenNotPaused returns(uint256 _buyoutBid) {
        require(block.timestamp >= minBuyoutTime, "NibblVault: minBuyoutTime < now");
        require(status == Status.initialized, "NibblVault: Status!=initialized");
        _buyoutBid = msg.value + (primaryReserveBalance - fictitiousPrimaryReserveBalance) + secondaryReserveBalance;
        //_buyoutBid: Bid User has made
        uint256 _currentValuation = getCurrentValuation();
        require(_buyoutBid >= _currentValuation, "NibblVault: Bid too low");
        // buyoutValuationDeposit = _currentValuation - ((primaryReserveBalance - fictitiousPrimaryReserveBalance) + secondaryReserveBalance); 
        buyoutValuationDeposit = msg.value - (_buyoutBid - _currentValuation);
        bidder = msg.sender;
        buyoutBid = _currentValuation;
        // buyoutBid: Bid can only be placed at current valuation
        buyoutRejectionValuation = (_currentValuation * (SCALE + REJECTION_PREMIUM)) / SCALE;
        buyoutEndTime = block.timestamp + BUYOUT_DURATION;
        status = Status.buyout;
        _updateTWAV(_currentValuation, uint32(block.timestamp % 2**32));
        if (_buyoutBid > _currentValuation) {
            safeTransferETH(payable(msg.sender), (_buyoutBid - _currentValuation));
        }
        emit BuyoutInitiated(msg.sender, _buyoutBid);
    }

    /// @notice Function to reject buyout
    /// @dev Triggered when someone buys tokens and curve valuation increases
    /// @dev If TWAV >= Buyout rejection valuation then the buyout is rejected
    /// @dev Called only when TWAV is updated
    function _rejectBuyout() private notBoughtOut {
        uint256 _twav = _getTwav();
        if (_twav >= buyoutRejectionValuation) {
            uint256 _buyoutValuationDeposit = buyoutValuationDeposit;
            unsettledBids[bidder] += _buyoutValuationDeposit;
            totalUnsettledBids += _buyoutValuationDeposit;
            delete buyoutRejectionValuation;
            delete buyoutEndTime;
            delete bidder;
            delete twavObservations;
            delete twavObservationsIndex;
            delete lastBlockTimeStamp;
            status = Status.initialized;
            emit BuyoutRejected(_twav);
        }
    }

    function setURL(string memory _url) public {
        require(msg.sender == curator, "NibblVault: Only Curator");
        require(bytes(imageUrl).length == 0, "NibblVault: Already set");
        imageUrl = _url;
    }

    /// @notice Function to allow withdrawal of unsettledBids after buyout has been rejected
    /// @param _to Address to receive the funds
    function withdrawUnsettledBids(address payable _to) external override {
        uint256 _amount = unsettledBids[msg.sender];
        delete unsettledBids[msg.sender];
        totalUnsettledBids -= _amount;
        safeTransferETH(_to, _amount);
    }

    /// @notice Function for tokenholders to redeem their tokens for reserve token in case of buyout success
    /// @dev The redeemed reserve token are in proportion to the token supply someone owns
    /// @dev The amount available for redemption is contract balance - (total unsettled bid and curator fees accrued)
    function redeem(address payable _to) external override boughtOut returns(uint256 _amtOut){
        uint256 _balance = balanceOf(msg.sender);
        _amtOut = ((address(this).balance - feeAccruedCurator - totalUnsettledBids) * _balance) / totalSupply();
        _burn(msg.sender, _balance);
        safeTransferETH(_to, _amtOut);
    }

    /// @notice Function to allow curator to redeem accumulated curator fee.
    /// @param _to the address where curator fee will be sent
    /// @dev can only be called by curator
    function redeemCuratorFee(address payable _to) external override returns(uint256 _feeAccruedCurator) {
        require(msg.sender == curator,"NibblVault: Only Curator");
        _feeAccruedCurator = feeAccruedCurator;
        feeAccruedCurator = 0;
        safeTransferETH(_to, _feeAccruedCurator);
    }


    /// @notice to update the curator address
    /// @param _newCurator new curator address 
    /// @dev can only be called by curator
    function updateCurator(address _newCurator) external override {
        require(msg.sender == curator,"NibblVault: Only Curator");
        curator = _newCurator;
    }


    /// @notice Function for allowing bidder to unlock his ERC721 in case of buyout success
    /// @param _assetAddress the address of asset to be unlocked
    /// @param _assetID the ID of asset to be unlocked
    /// @param _to the address where unlocked NFT will be sent
    function withdrawERC721(address _assetAddress, uint256 _assetID, address _to) external override boughtOut {
        require(msg.sender == bidder,"NibblVault: Only winner");
        IERC721(_assetAddress).safeTransferFrom(address(this), _to, _assetID);
    }

    ///@notice withdraw multiple ERC721s
    /// @param _assetAddresses the addresses of assets to be unlocked
    /// @param _assetIDs the IDs of assets to be unlocked
    /// @param _to the address where unlocked NFT will be sent
    function withdrawMultipleERC721(address[] calldata _assetAddresses, uint256[] calldata _assetIDs, address _to) external override boughtOut {
        require(msg.sender == bidder,"NibblVault: Only winner");
        uint256 _length = _assetAddresses.length;
        for (uint256 i; i < _length; ++i) {
            IERC721(_assetAddresses[i]).safeTransferFrom(address(this), _to, _assetIDs[i]);
        }
    }

    /// @notice Function for allowing bidder to unlock his ERC20s in case of buyout success
    /// @notice ERC20s can be accumulated by the underlying ERC721 in the vault as royalty or airdrops 
    /// @param _asset the address of asset to be unlocked
    /// @param _to the address where unlocked NFT will be sent
    function withdrawERC20(address _asset, address _to) external override boughtOut {
        require(msg.sender == bidder, "NibblVault: Only winner");
        IERC20(_asset).safeTransfer(_to, IERC20(_asset).balanceOf(address(this)));
    }

    /// @notice withdraw multiple ERC20s
    /// @param _assets the addresses of assets to be unlocked
    /// @param _to the address where unlocked NFTs will be sent
    function withdrawMultipleERC20(address[] calldata _assets, address _to) external override boughtOut {
        require(msg.sender == bidder, "NibblVault: Only winner");
        uint256 _length = _assets.length;
        for (uint256 i; i < _length; ++i) {
            IERC20(_assets[i]).safeTransfer(_to, IERC20(_assets[i]).balanceOf(address(this)));
        }
    }

    /// @notice Function for allowing bidder to unlock his ERC1155s in case of buyout success
    /// @notice ERC1155s can be accumulated by the underlying ERC721 in the vault as royalty or airdrops 
    /// @param _asset the address of asset to be unlocked
    /// @param _assetID the ID of asset to be unlocked
    /// @param _to the address where unlocked NFT will be sent
    function withdrawERC1155(address _asset, uint256 _assetID, address _to) external override boughtOut {
        require(msg.sender == bidder, "NibblVault: Only winner");
        uint256 balance = IERC1155(_asset).balanceOf(address(this),  _assetID);
        IERC1155(_asset).safeTransferFrom(address(this), _to, _assetID, balance, "0");
    }

    /// @notice withdraw multiple ERC1155s
    /// @param _assets the addresses of assets to be unlocked
    /// @param _assetIDs the IDs of assets to be unlocked
    /// @param _to the address where unlocked NFT will be sent
    function withdrawMultipleERC1155(address[] calldata _assets, uint256[] calldata _assetIDs, address _to) external override boughtOut {
        require(msg.sender == bidder, "NibblVault: Only winner");
        uint256 _length = _assets.length;
        for (uint256 i; i < _length; ++i) {
            uint256 balance = IERC1155(_assets[i]).balanceOf(address(this),  _assetIDs[i]);
            IERC1155(_assets[i]).safeTransferFrom(address(this), _to, _assetIDs[i], balance, "0");
        }
    }
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner != address(0));
        require(block.timestamp <= deadline, "NibblVault: expired deadline");
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        address signer = ecrecover(toTypedMessageHash(structHash), v, r, s);
        require(signer == owner, "NibblVault: invalid signature");
        _approve(owner, spender, value);
    }
    
    function safeTransferETH(address payable _to, uint256 _amount) private {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "NibblVault: ETH transfer failed");
    }

    function onERC721Received( address, address, uint256, bytes calldata ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    receive() external payable {}
}