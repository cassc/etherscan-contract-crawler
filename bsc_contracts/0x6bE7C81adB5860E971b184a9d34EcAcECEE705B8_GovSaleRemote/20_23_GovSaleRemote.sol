// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../layerZero/interfaces/ILayerZeroEndpoint.sol";
import "../interfaces/ISaleGatewayRemote.sol";
import "../interfaces/IGovFactory.sol";
import "../utils/AdminProxyManager.sol";
import "../utils/SaleLibrary.sol";

contract GovSaleRemote is
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    AdminProxyManager
    {

    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    uint256 public gasForDestinationLzReceive;
    uint256 public booster1BuyerLength;

    uint128 public sold;
    uint128 public paymentDecimals;

    uint128 public sale;
    uint128 public feeMoved;
    
    uint128 public price; // in payment decimal
    uint128 public refund_d2; // refund in percent 2 decimal
    
    uint128 public raised; // sale amount get
    uint128 public revenue; // fee amount get

    uint128 public minFCFSBuy;
    uint128 public maxFCFSBuy;

    uint128 public minComBuy;
    uint128 public maxComBuy;

    address[] public buyers;

    uint16 public dstChainId; // polygon
    bool public isFinalized;
    address public targetSale;
    ILayerZeroEndpoint public endpoint;
    IGovFactory public factory;
    IERC20MetadataUpgradeable public payment;

    struct Round{
        uint128 start;
        uint128 end;
        uint128 fee_d2; // in percent 2 decimal
    }
    
    struct Summary{
        uint256 received; // token received
        uint128 bought; // payment given
        uint128 feeGiven;
    }

    mapping(uint32 => Round) public booster;
    mapping(address => string) public recipient;
    mapping(address => bool) public refunded;
    mapping(address => bool) public isBuyer;
    mapping(address => Summary) public summaries;

    mapping(address => bool) internal ableToBuy;
    
    event TokenBought(
        uint32 indexed booster,
        address indexed buyer,
        uint128 tokenReceived,
        uint128 buyAmount,
        uint128 feeCharged
    );

    event Finalize(
        uint128 remoteRaised,
        uint128 remoteRevenue,
        uint256 remoteSold
    );

    /**
     * @dev Initialize project for raise fund
     * @param _start Epoch date to start round 1
     * @param _duration Duration per booster (in seconds)
     * @param _sale Amount token project to sell (based on token decimals of project)
     * @param _price Token project price in payment decimal
     * @param _fee_d2 Fee project percent in each rounds in 2 decimal
     * @param _payment Tokens to raise
     * @param _targetSale Tokens to raise
     */
    function init(
        uint128 _start,
        uint128 _duration,
        uint128 _sale,
        uint128 _price,
        uint128[3] calldata _fee_d2,
        address _payment,
        address _targetSale
    ) external initializer proxied {
        factory = IGovFactory(_msgSender());

        __UUPSUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __AdminProxyManager_init(tx.origin);

        sale = _sale;
        price = _price;
        payment = IERC20MetadataUpgradeable(_payment);
        targetSale = _targetSale;
        endpoint = ISaleGatewayRemote(factory.saleGateway()).lzEndpoint();
        gasForDestinationLzReceive = factory.gasForDestinationLzReceive();
        paymentDecimals = payment.decimals();
        dstChainId = 109;

        uint32 i = 1;
        do {
            if(i==1){
                booster[i].start = _start;
            }else{
                booster[i].start = booster[i-1].end + 1;
            }
            if(i < 3) booster[i].end = booster[i].start + _duration;
            booster[i].fee_d2 = _fee_d2[i-1];

            ++i;
        } while(i <= 3);

        transferOwnership(tx.origin);
    }
    
    function _authorizeUpgrade(address newImplementation) internal virtual override proxied {}

    // **** VIEW AREA ****
    
    /**
     * @dev Get all buyers/participants length
     */
    function getBuyersLength() external view returns(uint) {
        return buyers.length;
    }
    
    /**
     * @dev Get user able to buy at booster 1
     * @param _user User address
     */
    function getBooster1EligibleUsers(address _user) external view returns(bool){
        return ableToBuy[_user];
    }
    
    /**
     * @dev Get booster running now, 0 = no booster running
     */
    function boosterProgress() public view returns (uint32 running) {
        for(uint32 i=1; i<=3; ++i){
            if( (uint128(block.timestamp) >= booster[i].start && uint128(block.timestamp) <= booster[i].end) ||
                (i == 3 && uint128(block.timestamp) >= booster[i].start)
            ){
                running = i;
                break;
            }
        }
    }

    function getAdapterParams() internal view returns(bytes memory adapterParams){
        uint16 version = 1;
        adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
    }

    /**
     * @dev Get payload
     * @param _amountIn Amount to buy
     * @param _buyer User address
     */
    function getPayload(
        uint128 _amountIn,
        address _buyer
    ) internal view returns(bytes memory payload){
        // change to 6 decimal
        _amountIn = uint128((_amountIn * 1e6) / 10**paymentDecimals);
        payload = abi.encode(targetSale, _amountIn, _buyer);
    }

    /**
     * @dev Estimate cross chain fees
     * @param _amountIn Amount to buy
     * @param _buyer User address
     */
    function estimateFees(
        uint128 _amountIn,
        address _buyer
    ) public view returns(uint256 fees, uint256 tax){
        (fees,) = endpoint.estimateFees(dstChainId, factory.saleGateway(), getPayload(_amountIn, _buyer), false, getAdapterParams());
        tax = SaleLibrary.calcPercent2Decimal(factory.crossFee_d2(), fees);
    }

    function isEligible() internal view {
        address sender = _msgSender();
        require((sender == factory.savior() || sender == factory.keeper() || sender == owner()), "??");
    }

    function isSufficient(uint256 _amount) internal view {
        require(payment.balanceOf(address(this)) >= _amount, "less");
    }

    function changeToOriginalDecimal(uint128 _amount) internal view returns(uint128 result){
        result = uint128((_amount * 10**paymentDecimals) / 1e6);
    }
    
    // **** MAIN AREA ****

    function releaseToken(
        address _target,
        uint256 _amount
    ) internal {
        payment.safeTransfer(_target, _amount);
    }

    /**
     * @dev Move raised fund to devAddr/project owner
     */
    function moveFund(
        uint16 _percent_d2,
        bool _devAddr,
        address _target
    ) external {
        isEligible();

        uint256 amount = SaleLibrary.calcPercent2Decimal(raised, _percent_d2);

        isSufficient(amount);
        require(refund_d2 == 0 && isFinalized, "bad");

        if(_devAddr){
            releaseToken(factory.operational(), amount);
        } else{
            releaseToken(_target, amount);
        }
    }

    /**
     * @dev Move fee to devAddr
     */
    function moveFee() external {
        isEligible();
        
        uint128 amount = revenue;
        uint128 left = amount - feeMoved;

        isSufficient(left);

        require(left > 0 && isFinalized, "bad");
        
        feeMoved = amount;
        
        releaseToken(factory.operational(), SaleLibrary.calcPercent2Decimal(left, factory.operationalPercentage_d2()));
        releaseToken(factory.marketing(), SaleLibrary.calcPercent2Decimal(left, factory.marketingPercentage_d2()));
        releaseToken(factory.treasury(), SaleLibrary.calcPercent2Decimal(left, factory.treasuryPercentage_d2()));
    }

    /**
     * @dev Buy token project using token raise
     * @param _amountIn Buy amount
     */
    function buyToken(uint128 _amountIn) external payable whenNotPaused nonReentrant {
        uint32 running = boosterProgress();
        address sender = _msgSender();

        if(running == 1) require(ableToBuy[sender], "next");

        uint128 tokenReceivedEstimate = uint128(SaleLibrary.calcTokenReceived(_amountIn, price));

        if(running == 2){
			require(minFCFSBuy <= tokenReceivedEstimate && tokenReceivedEstimate <= maxFCFSBuy, "!range");
		} else if(running == 3){
			require(minComBuy <= tokenReceivedEstimate && tokenReceivedEstimate <= maxComBuy, "!range");
		}

        (uint256 fees, uint256 tax) = estimateFees(_amountIn, sender);
        uint256 feeNeeded = fees + tax;
        uint256 feeIn = msg.value;

        require(running > 0 && feeIn >= feeNeeded, "bad");

        uint128 feeCharged = uint128(SaleLibrary.calcPercent2Decimal(_amountIn, booster[running].fee_d2));

        raised += _amountIn;
        revenue += feeCharged;
        sold += tokenReceivedEstimate;
        
        summaries[sender].received += tokenReceivedEstimate;
        summaries[sender].bought += _amountIn;
        summaries[sender].feeGiven += feeCharged;

        ISaleGatewayRemote(factory.saleGateway()).buyToken{value: feeNeeded}(address(factory), getPayload(_amountIn, sender), getAdapterParams(), tax);
    
        payment.safeTransferFrom(sender, address(this), _amountIn + feeCharged);

        if(!isBuyer[sender]){
            isBuyer[sender] = true;
            buyers.push(sender);
        }

        if(feeIn > feeNeeded) {
            (bool success,) = payable(sender).call{value: feeIn - feeNeeded}("");
            require(success, "fail");
        }
    }

    function finalize(bytes calldata _payload) external {
        require(_msgSender() == factory.saleGateway(), "unknown");

        (
            , uint128 remoteRaised,
            uint128 remoteRevenue,
            uint256 remoteSold,
            address[] memory remoteUsers,
            uint128[] memory remoteUsersBought,
            uint128[] memory remoteUsersReceived,
            uint128[] memory remoteUsersFee
        ) = abi.decode(_payload, (address, uint128, uint128, uint256, address[], uint128[], uint128[], uint128[]));

        raised = changeToOriginalDecimal(remoteRaised);
        revenue = changeToOriginalDecimal(remoteRevenue);
        sold = uint128(remoteSold);

        for(uint16 i = 0; i < remoteUsers.length; ++i){
            address buyer = remoteUsers[i];
            uint128 remoteBought = changeToOriginalDecimal(remoteUsersBought[i]);
            Summary memory summary = summaries[buyer];

            if(summary.bought > remoteBought){
                uint128 surplusFee;
                uint128 remoteFee = changeToOriginalDecimal(remoteUsersFee[i]);
                if(summary.feeGiven > remoteFee) surplusFee = summary.feeGiven - remoteFee;

                uint128 payback = (summary.bought - remoteBought) + surplusFee;
                summaries[buyer] = Summary(remoteUsersReceived[i], remoteBought, remoteFee);

                releaseToken(buyer, payback);
            }
        }

        isFinalized = true;

        emit Finalize(
            raised,
            revenue,
            sold
        );
    }

    /**
     * @dev Refund payment
     */
    function refund() external {
        address sender = _msgSender();
        _refund(sender, sender);
    }

    function _refund(
        address _from,
        address _to
    ) internal {
        uint128 _refund_d2 = refund_d2;
        uint256 amount = SaleLibrary.calcPercent2Decimal(summaries[_from].bought, _refund_d2);

        isSufficient(amount);

        require(
            _refund_d2 > 0 &&
            amount > 0 &&
            !refunded[_from]
        , "bad");
        
        refunded[_from] = true;

        releaseToken(_to, amount);
    }
    
    /**
     * @dev Set recipient address
     * @param _recipient Recipient address
     */
    function setRecipient(string calldata _recipient) external whenNotPaused {
        require(boosterProgress() > 0 && bytes(_recipient).length != 0, "bad");

        recipient[_msgSender()] = _recipient;
    }
    
    // **** ADMIN AREA ****
    
    function removePurchase(address _buyer) external onlyOwner {
        Summary memory summary = summaries[_buyer];

        delete summaries[_buyer];

        if(!isFinalized){
            raised -= summary.bought;
            revenue -= summary.feeGiven;
            sold -= uint128(summary.received);
        }

        releaseToken(_buyer, summary.bought + summary.feeGiven);
    }

    function refundAirdrop(
        address _from,
        address _to
    ) external onlyOwner {
        _refund(_from, _to);
    }

    /**
     * @dev Set booster 1 buyer
     * @param _buyers User addresses
     */
    function setBooster1Buyer(address[] calldata _buyers) external onlyOwner {
        for(uint16 i=0; i<_buyers.length; ++i){
            if(ableToBuy[_buyers[i]]) continue;

            ableToBuy[_buyers[i]] = true;
            ++booster1BuyerLength;
        }
    }

    /**
     * @dev Set Min & Max in FCFS
     * @param _minMaxFCFSBuy Min and max token to buy
     */
    function setMinMaxFCFS(uint128[2] calldata _minMaxFCFSBuy) external onlyOwner {
        if(boosterProgress() < 2) minFCFSBuy = _minMaxFCFSBuy[0];
        maxFCFSBuy = _minMaxFCFSBuy[1];
    }

    /**
     * @dev Set Min & Max in Community Round
     * @param _minMaxComBuy Min and max token to buy
     */
    function setMinMaxCom(uint128[2] calldata _minMaxComBuy) external onlyOwner {
        if(boosterProgress() < 3) minComBuy = _minMaxComBuy[0];
        maxComBuy = _minMaxComBuy[1];
    }

    /**
     * @dev Config sale data
     * @param _payment Tokens to raise
     * @param _start Epoch date to start round 1
     * @param _duration Duration per booster (in seconds)
     * @param _sale Amount token project to sell (based on token decimals of project)
     * @param _price Token project price in payment decimal
     * @param _fee_d2 Fee project percent in each rounds in 2 decimal
     */
    function config(
        address _payment,
        uint128 _start,
        uint128 _duration,
        uint128 _sale,
        uint128 _price,
        uint128[3] calldata _fee_d2,
        address _targetSale
    ) external onlyOwner {
        require(uint128(block.timestamp) < booster[1].start, "started");

        payment = IERC20MetadataUpgradeable(_payment);
        sale = _sale;
        price = _price;
        targetSale = _targetSale;

        uint32 i = 1;
        do {
            if(i==1){
                booster[i].start = _start;
            }else{
                booster[i].start = booster[i-1].end + 1;
            }
            if(i < 3) booster[i].end = booster[i].start + _duration;
            booster[i].fee_d2 = _fee_d2[i-1];

            ++i;
        } while(i <= 3);
    }

    function setTargetSale(address _targetSale) external onlyOwner {
        targetSale = _targetSale;
    }

    /**
     * @dev Set refund
     * @param _refund_d2 Refund percent in 2 decimal
     */
    function setRefund(uint128 _refund_d2) external onlyOwner {
        refund_d2 = _refund_d2;
    }

    /**
     * @dev Set dst chain id
     * @param _dstChainId Dst chain id
     */
    function setDstChainId(uint16 _dstChainId) external onlyOwner {
        dstChainId = _dstChainId;
    }
    
    /**
     * @dev Toggle buyToken pause
     */
    function togglePause() external onlyOwner {
        if(paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
}