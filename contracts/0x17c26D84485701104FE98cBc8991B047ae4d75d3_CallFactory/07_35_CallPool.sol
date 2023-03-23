// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ICallPoolDeployer} from "./interfaces/ICallPoolDeployer.sol";
import {ICallPool} from "./interfaces/ICallPool.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import {IPremium} from "./interfaces/IPremium.sol";
import {ICallToken} from "./interfaces/ICallToken.sol";
import {CallToken} from "./CallToken.sol";
import {NToken} from "./NToken.sol";
import {Errors, ErrorCodes} from "./Errors.sol";
import {DataTypes, MAXIMUM_VALID_DURATION_IDX, MAXIMUM_VALID_STRIKE_PRICE_GAP_IDX, STRIKE_PRICE_DECIMALS, MAXIMUM_STRIKE_PRICE} from "./DataTypes.sol";
import {NFTStatus} from "./NFTStatus.sol";

contract CallPool is ICallPool, Pausable, ReentrancyGuard {
    using NFTStatus for DataTypes.NFTStatusMap; 
    address public immutable override factory;
    address public immutable override nft;
    address public immutable override oracle;
    address public immutable override nToken;
    address public immutable override callToken;
    address public immutable override premium;

    uint16 public constant  exercisePeriodProportion = 5000;  // 5000 means the buyers can exercise at any time in the late 50% of option period
    uint256 public constant minimumPremiumToOwner = 1e18 / 1000;      // 0.001 ether
    uint256 public constant INVALID_PRICE = type(uint256).max;
    uint256 public constant DECIMALS = 18;

    // Assume that the price decimals is greater than the strike price decimals.
    // When the price decimals is less than the strike price decimals, 
    // please use: (DataTypes.STRIKE_PRICE_MAX / (10 ** (DataTypes.STRIKE_PRICE_DECIMALS - DECIMALS)));
    uint256 internal constant STRIKE_PRICE_SCALE = 10 ** (DECIMALS - STRIKE_PRICE_DECIMALS);
    uint256 public constant MAXIMUM_STRIKE_PRICE_IN_CONTRACT_DECIMALS = uint256(type(uint64).max) * STRIKE_PRICE_SCALE;

    uint256 private constant PRECISION = 1e5;
    uint256 private constant RESERVE = 1e4; // 10%

    function STRIKE_PRICE_GAP(uint8 strikePriceGapIdx) public pure returns(uint256) {
        uint24[MAXIMUM_VALID_STRIKE_PRICE_GAP_IDX + 1] memory strikePriceGaps = [0, 1e4, 2*1e4, 3*1e4, 5*1e4, 1e5]; // [0% 10% 20% 30% 50% 100%]
        return uint256(strikePriceGaps[strikePriceGapIdx]);
    }

    function DURATION(uint8 durationIdx) public pure returns(uint40) {
        uint40[MAXIMUM_VALID_DURATION_IDX + 1] memory durations = [uint40(3 days), uint40(7 days), uint40(14 days), uint40(28 days)];
        return uint40(durations[durationIdx]);
    }

    function convertToStrikePrice(uint256 price) private pure returns(uint64) {
        return uint64(price / STRIKE_PRICE_SCALE);
    }

    function convertFromStrikePrice(uint64 strikePrice) private pure returns(uint256) {
        return uint256(strikePrice) * STRIKE_PRICE_SCALE;
    }
    
    bool internal _deactivated;


    mapping(uint256 => DataTypes.NFTStatusMap) private nftStatus;


    mapping(address => uint256) private _balanceOf;

    constructor() {
        (factory, nft, nToken, callToken, oracle, premium) = ICallPoolDeployer(_msgSender()).parameters();
    }

    modifier onlyFactoryOwner() {
        require(_msgSender() == Ownable(factory).owner(), Errors.CP_CALLER_IS_NOT_FACTORY_OWNER);
        _;
    }

    modifier whenActivated() {
        require(!_deactivated, Errors.CP_DEACTIVATED);
        _;
    }

    function pause() external onlyFactoryOwner {
        _pause();
    }

    function unpause() external onlyFactoryOwner {
        _unpause();
    }

    function activate() external onlyFactoryOwner {
        require(_deactivated, Errors.CP_ACTIVATED);
        _deactivated = false;
        emit Activate(_msgSender());
    }

    function deactivate() external onlyFactoryOwner {
        require(!_deactivated, Errors.CP_DEACTIVATED);
        _deactivated = true;
        emit Deactivate(_msgSender());
    }

    function balanceOf(address user) public view override returns (uint256) {
        return _balanceOf[user];
    }

    function checkAvailable(uint256 tokenId) public view returns (bool) {
        if(nftStatus[tokenId].data == 0){
            return false;
        }
        uint256 endTime = uint256(nftStatus[tokenId].getEndTime());
        if (endTime < block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    // Deposit NFT
    function deposit(address onBehalfOf, uint256 tokenId) external override whenNotPaused whenActivated nonReentrant {
        uint256 errorCode = _deposit(onBehalfOf, tokenId, 1, 3, 0);
        require(errorCode == 0, Strings.toString(errorCode));
    }

    function depositBatch(address onBehalfOf, uint256[] calldata tokenIds) external override  whenNotPaused whenActivated nonReentrant returns(uint256[] memory) {
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        uint256[] memory errorCodes = new uint256[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; ++i) {
            errorCodes[i] = _deposit(onBehalfOf, tokenIds[i], 1, 3, 0);
        }
        return errorCodes;
    }

    function depositWithPreference(
        address onBehalfOf,
        uint256 tokenId,
        uint8 lowerStrikePriceGapIdx,
        uint8 upperDurationIdx,
        uint256 minimumStrikePrice
    ) external override whenNotPaused whenActivated nonReentrant{
        uint256 errorCode = _deposit(onBehalfOf, tokenId, lowerStrikePriceGapIdx, upperDurationIdx, minimumStrikePrice);
        require(errorCode == 0, Strings.toString(errorCode));
    }

    function depositWithPreferenceBatch(
        address onBehalfOf,
        uint256[] calldata tokenIds,
        uint8[] calldata lowerStrikePriceGapIdxList,
        uint8[] calldata upperDurationIdxList,
        uint256[] calldata minimumStrikePriceList
    ) external override whenNotPaused whenActivated nonReentrant returns(uint256[] memory){
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        require(tokenIds.length == lowerStrikePriceGapIdxList.length 
                && tokenIds.length == upperDurationIdxList.length 
                && tokenIds.length == minimumStrikePriceList.length
                , Errors.CP_ARRAY_LENGTH_UNMATCHED);
        uint256[] memory errorCodes = new uint256[](tokenIds.length);
        for(uint256 i=0; i < tokenIds.length; ++i){
            errorCodes[i] = _deposit(onBehalfOf, tokenIds[i], lowerStrikePriceGapIdxList[i], upperDurationIdxList[i], minimumStrikePriceList[i]);
        }
        return errorCodes;
    }

    function _deposit(
        address onBehalfOf,
        uint256 tokenId,
        uint8 minimumStrikePriceGapIdx,
        uint8 maximumDurationIdx,
        uint256 minimumStrikePrice
    ) internal returns(uint256){
        if(minimumStrikePrice > MAXIMUM_STRIKE_PRICE_IN_CONTRACT_DECIMALS){
            return ErrorCodes.CP_PRICE_TOO_HIGH;
        }
        DataTypes.NFTStatusMap memory status = DataTypes.NFTStatusMap(DataTypes.NFT_STATUS_MAP_INIT_VALUE);
        status.setIfOnMarket(true);
        status.setMinimumStrikePriceGapIdx(minimumStrikePriceGapIdx);
        status.setMaximumDurationIdx(maximumDurationIdx);
        status.setMinimumStrikePrice(convertToStrikePrice(minimumStrikePrice));
        nftStatus[tokenId].data = status.data;

        CallToken(callToken).mint(nToken, tokenId);
        emit Deposit(nft, _msgSender(), onBehalfOf, tokenId);
        emit PreferenceUpdated(nft, tokenId, minimumStrikePriceGapIdx, maximumDurationIdx, minimumStrikePrice);
        NToken(nToken).mint(onBehalfOf, tokenId);
        IERC721(nft).transferFrom(_msgSender(), nToken, tokenId);

        
        return 0;
    }

    // Withdraw NFT
    function withdraw(address to, uint256 tokenId) external override whenNotPaused nonReentrant{
        uint256 errorCode = _withdraw(_msgSender(), to, tokenId, block.timestamp);
        require(errorCode == 0, Strings.toString(errorCode));
    }

    // Withdraw NFT
    function withdrawBatch(address to, uint256[] calldata tokenIds) external override whenNotPaused nonReentrant returns(uint256[] memory){
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        uint256[] memory errorCodes = new uint256[](tokenIds.length);
        address user = _msgSender();
        uint256 currentTime = block.timestamp;
        for(uint256 i = 0; i < tokenIds.length; ++i){
            errorCodes[i] = _withdraw(user, to, tokenIds[i], currentTime);
        }
        return errorCodes;
    }

    // Withdraw NFT
    function _withdraw(address user, address to, uint256 tokenId, uint256 currentTime) internal returns(uint256) {
        
        if(NToken(nToken).ownerOf(tokenId) != user){
            return ErrorCodes.CP_NOT_THE_OWNER;
        }
        // Check requirements: not commited to a call, etc.
        if(uint256(nftStatus[tokenId].getEndTime()) >= currentTime){
            return ErrorCodes.CP_NFT_ON_MARKET_OR_UNAVAILABLE;
        }
        delete nftStatus[tokenId];
        CallToken(callToken).burn(tokenId);

        emit Withdraw(nft, user, to, tokenId);
        // Burn NToken
        NToken(nToken).burn(user, to, tokenId);
        return 0;
    }

    /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, Errors.CP_UNABLE_TO_TRANSFER_ETH);
    }

    function withdrawETH(
        address to,
        uint256 amount
    ) external override whenNotPaused nonReentrant returns(uint256) {
        require(amount != 0, Errors.CP_INVALID_AMOUNT);
        require(to != address(0), Errors.CP_INVALID_RECEIVER);
        uint256 userBalance = _balanceOf[_msgSender()];
        if(amount == type(uint256).max){
            amount = userBalance;
        }
        require(amount <= userBalance, Errors.CP_NOT_ENOUGH_BALANCE);
        address user = _msgSender();
        _balanceOf[user] = userBalance - amount;
        emit WithdrawETH(_msgSender(), to, amount);
        emit BalanceChangedETH(user, _balanceOf[user]);
        _safeTransferETH(to, amount);
        
        return amount;
    }

    function takeNFTOffMarket(uint256 tokenId) external override whenNotPaused {
        uint256 errorCode = _takeNFTOffMarket(_msgSender(), tokenId);
        require(errorCode == 0, Strings.toString(errorCode));
    }

    function takeNFTOffMarketBatch(uint256[] calldata tokenIds) external override whenNotPaused returns(uint256[] memory){
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        address user = _msgSender();
        uint256[] memory errorCodes = new uint256[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; ++i){
            errorCodes[i] = _takeNFTOffMarket(user, tokenIds[i]);
        }
        return errorCodes;
    }

    function _takeNFTOffMarket(address user, uint256 tokenId) internal returns(uint256) {
        if(NToken(nToken).ownerOf(tokenId) != user){
            return ErrorCodes.CP_NOT_THE_OWNER;
        }
        DataTypes.NFTStatusMap memory status = nftStatus[tokenId];
        status.setIfOnMarket(false);
        nftStatus[tokenId].data = status.data;
        emit OffMarket(nft, user, tokenId);
        return 0;
    }

    function relistNFT(uint256 tokenId) external override whenNotPaused whenActivated{
        uint256 errorCode = _relistNFT(_msgSender(), tokenId);
        require(errorCode == 0, Strings.toString(errorCode));
    }

    function relistNFTBatch(uint256[] calldata tokenIds) external override whenNotPaused whenActivated returns(uint256[] memory){
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        address user = _msgSender();
        uint256[] memory errorCodes = new uint256[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; ++i){
            errorCodes[i] = _relistNFT(user, tokenIds[i]);
        }
        return errorCodes;
    }

    function _relistNFT(address user, uint256 tokenId) internal returns(uint256) {
        if(NToken(nToken).ownerOf(tokenId) != user){
            return ErrorCodes.CP_NOT_THE_OWNER;
        }
        DataTypes.NFTStatusMap memory status = nftStatus[tokenId];
        status.setIfOnMarket(true);
        nftStatus[tokenId].data = status.data;
        emit OnMarket(nft, user, tokenId);
        return 0;
    }

    struct OpenCallLocalVars {
        uint256 strikePrice;
        uint256 premiumToOwner;
        uint256 premiumToReserve;
        uint256 errorCode;
    }

    // Open a call position
    function openCall(
        uint256 tokenId,
        uint8 strikePriceGapIdx,
        uint8 durationIdx
    ) external payable override whenNotPaused whenActivated{
        OpenCallLocalVars memory vars;
        (
            vars.strikePrice,
            vars.premiumToOwner,
            vars.premiumToReserve,
            vars.errorCode
        ) = previewOpenCall(tokenId, strikePriceGapIdx, durationIdx);
        require(vars.errorCode == 0, Strings.toString(vars.errorCode));
        address user = _msgSender();
        uint256 totalPremium = vars.premiumToOwner + vars.premiumToReserve;
        if(msg.value != totalPremium){
            require(totalPremium < msg.value, Errors.CP_DID_NOT_SEND_ENOUGH_ETH);
            _balanceOf[user] += msg.value - totalPremium;
            emit BalanceChangedETH(user, _balanceOf[user]);
        }
        address owner = IERC721(nToken).ownerOf(tokenId);
        _balanceOf[owner] += vars.premiumToOwner;
        emit BalanceChangedETH(owner, _balanceOf[owner]);
        address pool = address(this);
        _balanceOf[pool] += vars.premiumToReserve;
        emit BalanceChangedETH(pool, _balanceOf[pool]);
        uint40 currentTime = uint40(block.timestamp);
        _openCallInteractions(user, tokenId, currentTime, strikePriceGapIdx, durationIdx, vars.strikePrice);
        emit PremiumReceived(nft, owner, tokenId, vars.premiumToOwner, vars.premiumToReserve);


    }

    // Batch open position
    function openCallBatch(
        uint256[] calldata tokenIds,
        uint8[] calldata strikePriceGaps,
        uint8[] calldata durations
    ) external payable override whenNotPaused whenActivated{
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        require(tokenIds.length == strikePriceGaps.length && tokenIds.length == durations.length, Errors.CP_ARRAY_LENGTH_UNMATCHED);
        uint256 totalPremium = 0;
        uint256 totalReservePremium = 0;
        address user = _msgSender();
        uint40 currentTime = uint40(block.timestamp);
        OpenCallLocalVars memory vars;
        for(uint256 i = 0; i < tokenIds.length; ++i){
            (
                vars.strikePrice,
                vars.premiumToOwner,
                vars.premiumToReserve,
                vars.errorCode
            ) = previewOpenCall(tokenIds[i], strikePriceGaps[i], durations[i]);
            if(vars.errorCode == 0){
                totalReservePremium += vars.premiumToReserve;
                totalPremium += vars.premiumToOwner;
                address owner = IERC721(nToken).ownerOf(tokenIds[i]);
                _balanceOf[owner] += vars.premiumToOwner;
                emit BalanceChangedETH(owner, _balanceOf[owner]);
                _openCallInteractions(user, tokenIds[i], currentTime, strikePriceGaps[i], durations[i], vars.strikePrice);
                emit PremiumReceived(nft, owner, tokenIds[i], vars.premiumToOwner, vars.premiumToReserve);
            }
        }
        totalPremium += totalReservePremium;
        address pool = address(this);
        _balanceOf[pool] += totalReservePremium;
        emit BalanceChangedETH(pool, _balanceOf[pool]);
        if(msg.value != totalPremium){
            require(msg.value > totalPremium, Errors.CP_DID_NOT_SEND_ENOUGH_ETH);
            _balanceOf[user] += msg.value - totalPremium;
            emit BalanceChangedETH(user, _balanceOf[user]);
        }
    }

    function previewOpenCall(
        uint256 tokenId,
        uint8 strikePriceGapIdx,
        uint8 durationIdx
    ) public override view returns(
        uint256 strikePrice,
        uint256 premiumToOwner,
        uint256 premiumToReserve,
        uint256 errorCode
    ) {
        return _previewOpenCall(tokenId, strikePriceGapIdx, durationIdx);
    }

    function previewOpenCallBatch( uint256[] calldata tokenIds, uint8[] calldata strikePriceGaps, uint8[] calldata durations) public override view
        returns( uint256[] memory strikePrices, uint256[] memory premiumsToOwner, uint256[] memory premiumsToReserve, uint256[] memory errorCodes) {
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        require(tokenIds.length == strikePriceGaps.length && tokenIds.length == durations.length, Errors.CP_ARRAY_LENGTH_UNMATCHED);
        strikePrices = new uint256[](tokenIds.length);
        premiumsToOwner = new uint256[](tokenIds.length);
        premiumsToReserve = new uint256[](tokenIds.length);
        errorCodes = new uint256[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; ++i){
            (strikePrices[i], premiumsToOwner[i], premiumsToReserve[i], errorCodes[i]) = _previewOpenCall(tokenIds[i], strikePriceGaps[i], durations[i]);
        }
    }

    function _previewOpenCall(
        uint256 tokenId,
        uint8 strikePriceGapIdx,
        uint8 durationIdx
    ) internal view returns(
        uint256 strikePrice,
        uint256 premiumToOwner,
        uint256 premiumToReserve,
        uint256 errorCode
    ) {
        DataTypes.NFTStatusMap storage status = nftStatus[tokenId];
        strikePrice = INVALID_PRICE;
        premiumToOwner = INVALID_PRICE;
        premiumToReserve = INVALID_PRICE;
        if(_msgSender() == IERC721(nToken).ownerOf(tokenId)){
            errorCode = ErrorCodes.CP_CAN_NOT_OPEN_A_POSITION_ON_SELF_OWNED_NFT;
        }
        else if(!status.getIfOnMarket() || (block.timestamp <= uint256(status.getEndTime()))){
            errorCode = ErrorCodes.CP_NFT_ON_MARKET_OR_UNAVAILABLE;
        }
        else if(strikePriceGapIdx < status.getMinimumStrikePriceGapIdx()){
            errorCode = ErrorCodes.CP_STRIKE_GAP_TOO_LOW;
        } 
        else if(durationIdx > status.getMaximumDurationIdx()) {
            errorCode = ErrorCodes.CP_DURATION_TOO_LONG;
        }
        else {
            uint256 openPrice;
            (openPrice, premiumToReserve, premiumToOwner) = _calculatePremium(strikePriceGapIdx, durationIdx);
            if(premiumToOwner < minimumPremiumToOwner){
                errorCode = ErrorCodes.CP_TOO_LITTLE_PREMIUM_TO_OWNER;
            }
            else{
                strikePrice =  openPrice + openPrice * STRIKE_PRICE_GAP(strikePriceGapIdx) / PRECISION;
                if(strikePrice < convertFromStrikePrice(status.getMinimumStrikePrice())){
                    errorCode = ErrorCodes.CP_STRIKE_PRICE_TOO_LOW;
                }
                else if(strikePrice > MAXIMUM_STRIKE_PRICE_IN_CONTRACT_DECIMALS){
                    errorCode = ErrorCodes.CP_PRICE_TOO_HIGH;
                }
                else{
                    errorCode = 0;
                }
            }
        }
    }

    function _openCallInteractions(address user, uint256 tokenId, uint40 currentTime, uint8 strikePriceGapIdx, uint8 durationIdx, uint256 strikePrice) internal {
        uint40 duration = DURATION(durationIdx);
        uint40 exercisePeriodEnd = currentTime + duration;
        uint40 exercisePeriodBegin = exercisePeriodEnd - duration * exercisePeriodProportion / 10000;
        DataTypes.NFTStatusMap memory status = nftStatus[tokenId];
        status.setExerciseTime(exercisePeriodBegin);
        status.setEndTime(exercisePeriodEnd);
        status.setStrikePrice(convertToStrikePrice(strikePrice));
        nftStatus[tokenId].data = status.data;
        ICallToken(callToken).open(user, tokenId);
        emit CallOpened(nft, user, tokenId, strikePriceGapIdx, durationIdx, strikePrice, exercisePeriodBegin, exercisePeriodEnd);
        
    }

    // Exercise a call position
    function exerciseCall(uint256 tokenId) external payable override whenNotPaused whenActivated nonReentrant{
        (uint256 errorCode, uint256 remainValue) = _exerciseCall(_msgSender(), tokenId, msg.value, block.timestamp);
        require(errorCode == 0, Strings.toString(errorCode));
        require(remainValue == 0, Errors.CP_NOT_ENOUGH_OR_TOO_MUCH_ETH);
    }

    // Exercise a call position
    // To avoid reentrancy attack, we can not use the amount in the _balanceOf[user] to pay the strike price.
    function exerciseCallBatch(uint256[] calldata tokenIds) external payable override whenNotPaused whenActivated nonReentrant returns(uint256[] memory){
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        address user = _msgSender();
        uint256 remainValue = msg.value;
        uint256 currentTime = block.timestamp;
        uint256[] memory errorCodes = new uint256[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; ++ i){
            (errorCodes[i], remainValue) = _exerciseCall(_msgSender(), tokenIds[i], remainValue, currentTime);
        }
        if(remainValue > 0){
            _balanceOf[user] += remainValue;
            emit BalanceChangedETH(user, _balanceOf[user]);
        }
        return errorCodes;
    }

    // Exercise a call position
    function _exerciseCall(address user, uint256 tokenId, uint256 value, uint256 currentTime) internal returns(uint256 errorCode, uint256 remainValue){
        DataTypes.NFTStatusMap storage status = nftStatus[tokenId];
        uint256 strikePrice = convertFromStrikePrice(status.getStrikePrice());
        if(uint256(status.getEndTime()) < currentTime || uint256(status.getExerciseTime()) > currentTime){
            return (ErrorCodes.CP_NOT_IN_THE_EXERCISE_PERIOD, value);
        }
        if(CallToken(callToken).ownerOf(tokenId) != user){
            return (ErrorCodes.CP_NOT_THE_OWNER, value);
        }
        if(strikePrice > value){
            return (ErrorCodes.CP_DID_NOT_SEND_ENOUGH_ETH, value);
        }
        // Burn CallToken
        CallToken(callToken).burn(tokenId);
        delete nftStatus[tokenId];
        address originalOwner = NToken(nToken).ownerOf(tokenId);

        // Pay strike price to NToken owner
        _balanceOf[originalOwner] += strikePrice;

        emit BalanceChangedETH(originalOwner, _balanceOf[originalOwner]);
        emit CallClosed(nft, user, originalOwner, tokenId, strikePrice);
        // Burn NToken and transfer underlying NFT
        NToken(nToken).burn(originalOwner, user, tokenId);
        
        return (0, value - strikePrice);
    }

    function collectProtocol(
        address recipient,
        uint256 amountRequested
    ) external override onlyFactoryOwner returns (uint256 amountSent) {
        require(recipient != address(0), Errors.CP_INVALID_RECEIVER);
        require(amountRequested != 0, Errors.CP_INVALID_AMOUNT);
        uint256 balance = _balanceOf[address(this)];
        amountSent = amountRequested > balance ? balance : amountRequested;
        if (amountSent > 0) {
            address pool = address(this);
            _balanceOf[pool] -= amountSent;
            emit BalanceChangedETH(pool, _balanceOf[pool]);
            emit CollectProtocol(_msgSender(), recipient, amountSent);
            _safeTransferETH(recipient, amountSent);
        }
    }

    function _calculatePremium(
        uint8 strikePriceGapIdx,
        uint8 durationIdx
    ) internal view returns(
        uint256 openPrice,
        uint256 premiumToReserve,
        uint256 premiumToOwner
    ){
        require(uint256(strikePriceGapIdx) <= MAXIMUM_VALID_STRIKE_PRICE_GAP_IDX && uint256(durationIdx) <= MAXIMUM_VALID_DURATION_IDX, Errors.CP_GAP_OR_DURATION_OUT_OF_INDEX);

        IPriceOracle _oracle = IPriceOracle(oracle);
        uint256 vol = _oracle.getAssetVol(nft);
        openPrice = _oracle.getAssetPrice(nft);

        IPremium _premium = IPremium(premium);
        uint256 currentPremium = _premium.getPremium(uint256(strikePriceGapIdx) * 4 + uint256(durationIdx), vol);
        uint256 precision = _premium.precision();

        uint256 premiumTotal = openPrice * currentPremium / precision;
        premiumToReserve = premiumTotal * RESERVE / PRECISION;
        premiumToOwner = premiumTotal - premiumToReserve;
    }

    function getNFTStatus(uint256 tokenId) external view override returns (DataTypes.NFTStatusOutput memory) {
        return _getNFTStatus(tokenId);
    }

    function getNFTStatusBatch(uint256[] calldata tokenIds) external view override returns (DataTypes.NFTStatusOutput[] memory) {
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        DataTypes.NFTStatusOutput[] memory statuses = new DataTypes.NFTStatusOutput[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; ++i){
            statuses[i] = _getNFTStatus(tokenIds[i]);
        }
        return statuses;
    }

    function _getNFTStatus(uint256 tokenId) internal view returns (DataTypes.NFTStatusOutput memory) {
        require(IERC721(nToken).ownerOf(tokenId) != address(0), Errors.CP_NFT_ON_MARKET_OR_UNAVAILABLE);
        DataTypes.NFTStatusMap storage _status = nftStatus[tokenId];
        DataTypes.NFTStatusOutput memory status = DataTypes.NFTStatusOutput(
            _status.getIfOnMarket(),
            _status.getMinimumStrikePriceGapIdx(),
            _status.getMaximumDurationIdx(),
            uint256(_status.getExerciseTime()),
            uint256(_status.getEndTime()),
            convertFromStrikePrice(_status.getMinimumStrikePrice()),
            convertFromStrikePrice(_status.getStrikePrice())
        );
        return status;
    }

    function changePreference(
        uint256 tokenId,
        uint8 lowerStrikePriceGapIdx,
        uint8 upperDurationIdx,
        uint256 minimumStrikePrice
    ) external override whenNotPaused whenActivated{
        address user = _msgSender();
        uint256 currentTime = block.timestamp;
        uint256 errorCode = _changePreference(user, tokenId, lowerStrikePriceGapIdx, upperDurationIdx, minimumStrikePrice, currentTime);
        require(errorCode == 0, Strings.toString(errorCode));
    }

    function changePreferenceBatch(
        uint256[] calldata tokenIds,
        uint8[] calldata lowerStrikePriceGapIdxList,
        uint8[] calldata upperDurationIdxList,
        uint256[] calldata minimumStrikePriceList
    ) external override whenNotPaused whenActivated returns(uint256[] memory){
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        require(tokenIds.length == lowerStrikePriceGapIdxList.length 
                && tokenIds.length == upperDurationIdxList.length 
                && tokenIds.length == minimumStrikePriceList.length
                , Errors.CP_ARRAY_LENGTH_UNMATCHED);
        uint256[] memory errorCodes = new uint256[](tokenIds.length);
        address user = _msgSender();
        uint256 currentTime = block.timestamp;
        for(uint256 i=0; i < tokenIds.length; ++i){
            errorCodes[i] = _changePreference(user, tokenIds[i], lowerStrikePriceGapIdxList[i], upperDurationIdxList[i], minimumStrikePriceList[i], currentTime);
        }
        return errorCodes;
    }

    function _changePreference(
        address user,
        uint256 tokenId,
        uint8 lowerStrikePriceGapIdx,
        uint8 upperDurationIdx,
        uint256 minimumStrikePrice,
        uint256 currentTime
    ) internal returns(uint256) {
        if(NToken(nToken).ownerOf(tokenId) != user){
            return ErrorCodes.CP_NOT_THE_OWNER;
        }
        if(currentTime <= uint256(nftStatus[tokenId].getEndTime())){
            return ErrorCodes.CP_NFT_ON_MARKET_OR_UNAVAILABLE;
        }
        if(minimumStrikePrice > MAXIMUM_STRIKE_PRICE){
            return ErrorCodes.CP_PRICE_TOO_HIGH;
        }
        DataTypes.NFTStatusMap memory status = nftStatus[tokenId];
        status.setMinimumStrikePriceGapIdx(lowerStrikePriceGapIdx);
        status.setMaximumDurationIdx(upperDurationIdx);
        status.setMinimumStrikePrice(convertToStrikePrice(minimumStrikePrice));
        nftStatus[tokenId].data = status.data;
        emit PreferenceUpdated(nft, tokenId, lowerStrikePriceGapIdx, upperDurationIdx, minimumStrikePrice);
        return 0;
    }

    function totalOpenInterest() external view override returns(uint256) {
        return IERC721Enumerable(callToken).totalSupply();
    }

    function getEndTime(uint256 tokenId) external view override returns(uint256) {
        return uint256(nftStatus[tokenId].getEndTime());
    }
}