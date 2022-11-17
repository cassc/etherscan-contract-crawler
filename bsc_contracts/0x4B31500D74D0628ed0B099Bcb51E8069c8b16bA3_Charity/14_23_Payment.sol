// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "ApeSwap-AMM-Periphery/contracts/interfaces/IApePair.sol";
import "ApeSwap-AMM-Periphery/contracts/interfaces/IApeRouter02.sol";


pragma solidity ^0.8.12;

contract Payment is Ownable {
    address public burnReserve;
    address public treasury;
    address public liquidityReserve;
    struct Lessons {
        uint256 price;
        uint16 tutorPercent;
        uint16 profitPercent;
        bool available;
        address tutor;
    }
    // lessonId -> Lessons struct
    mapping(uint256 => Lessons) public lesson;
    // user ->  subscribtionEndBlock
    mapping(address => uint256) public subscribtionInfo;
    // user address -> lessonId -> availability
    mapping(address => mapping(uint256 => bool)) public lessonAvailability;
    uint256 public lessonsId;
    // TODO fix
    uint256 public constant BLOCKS_PER_MONTH = 560;
    // Count of hours for free trial
    uint256 public freeTrialDuration;
    IERC20 public token;
    AggregatorInterface public priceFeed;
    IApePair public pair;
    IApeRouter02 public router;
    // Fix for network
    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    mapping(uint256 => uint256) public subscribtionPrice;
    event NewLessonAdded(uint256 lessonId, uint256 price, bool availability);
    event LessonAvailabilityChanged(uint256 lessonId, bool availability);
    event LessonPriceChanged(uint256 lessonId, uint256 price);
    event FreeTrialDurationChanged(uint256 newDuration);
    event NewsSubscribtionPlanAded(uint256 months, uint256 price);
    event PaidForLesson(uint256 lessonId, address user, uint256 price, uint256 tokenAmount);
    event SubscibtionComplited(
        uint256 months,
        address user,
        uint256 subscribtionEndBlock,
        uint256 price,
        uint256 tokenAmount
    );

    constructor(
        address burnReserve_,
        address priceFeed_,
        IApePair pair_,
        IApeRouter02 router_,
        IERC20 token_,
        uint256 freeTrialDuration_,
        address treasury_,
        address liquidityReserve_
    ) {
        require(burnReserve_ != address(0), "Payment: BurnReserve can't be address zero");
        require(priceFeed_ != address(0), "Payment: PriceFeed can't be address zero");
        require(address(pair_) != address(0), "Payment: Pair can't be address zero");
        require(address(router_) != address(0), "Payment: Router can't be address zero");
        require(address(token_) != address(0), "Payment: Pair can't be address zero");
        require(treasury_ != address(0), "Payment: Treasury can't be address zero");
        require(liquidityReserve_ != address(0), "Payment: LiquidityReserve can't be address zero");
        burnReserve = burnReserve_;
        priceFeed = AggregatorInterface(priceFeed_);
        pair = pair_;
        router = router_;
        token = token_;
        freeTrialDuration = freeTrialDuration_;
        treasury = treasury_;
        liquidityReserve = liquidityReserve_;
    }

    // Admin functions
    function addLesson(
        uint256 price_,
        uint16 tutorPercent_,
        uint16 profitPercent_,
        bool available_,
        address tutor_
    ) external onlyOwner {
        require(price_ != 0, "Paymant: Price can't be zero");
        require(tutor_ != address(0), "Payment: Tutor address can't be zero");
        require(tutorPercent_ + profitPercent_ == 3000, "Payment: Invalid percents");
        lesson[lessonsId].price = price_;
        lesson[lessonsId].tutorPercent = tutorPercent_;
        lesson[lessonsId].profitPercent = profitPercent_;
        lesson[lessonsId].available = available_;
        lesson[lessonsId].tutor = tutor_;
        emit NewLessonAdded(lessonsId, price_, available_);
        lessonsId++;
    }

    function changeLessonAvailability(uint256 lessonId_, bool availability_) external onlyOwner {
        require(lesson[lessonId_].price != 0, "Payment: Lesson with this id doesn't exist");
        require(lesson[lessonId_].available != availability_, "Payment: Nothing to change");
        lesson[lessonId_].available = availability_;
        emit LessonAvailabilityChanged(lessonId_, availability_);
    }

    function changeLessonPrice(uint256 lessonId_, uint256 newPrice_) external onlyOwner {
        require(lesson[lessonId_].price != 0, "Payment: Lesson with this id doesn't exist");
        require(lesson[lessonId_].price != newPrice_, "Payment: Nothing to change");
        require(newPrice_ != 0, "Paymant: Price can't be zero");
        lesson[lessonId_].price = newPrice_;
        emit LessonPriceChanged(lessonId_, newPrice_);
    }

    function changeFreeTrialDurtion(uint256 newDuration_) external onlyOwner {
        require(freeTrialDuration != newDuration_, "Payment: Nothing to change");
        freeTrialDuration = newDuration_;
        emit FreeTrialDurationChanged(newDuration_);
    }

    function addNewsSubscibtionPlan(uint256 months_, uint256 price_) external onlyOwner {
        subscribtionPrice[months_] = price_;
        emit NewsSubscribtionPlanAded(months_, price_);
    }

    // User functions
    function payForLesson(uint256 lessonId_) external {
        require(lesson[lessonId_].price != 0, "Payment: Lesson with this id doesn't exist");
        require(lesson[lessonId_].available, "Payment: Lesson is now unavailable");
        require(!lessonAvailability[msg.sender][lessonId_], "Payment: Lessen already paid");
        uint256 tokenAmount = getTokenAmountForCurrentPrice(lesson[lessonId_].price) * 1e18;
        token.transferFrom(msg.sender, address(burnReserve), (tokenAmount * 7000) / 10000);
        token.transferFrom(msg.sender, lesson[lessonId_].tutor, (tokenAmount * lesson[lessonId_].tutorPercent) / 10000);
        token.transferFrom(msg.sender, treasury, (tokenAmount * lesson[lessonId_].profitPercent) / 10000);
        // Add tokens to pool
        swap(tokenAmount);
        lessonAvailability[msg.sender][lessonId_] = true;
        emit PaidForLesson(lessonId_, msg.sender, lesson[lessonId_].price, tokenAmount);
    }

    function payForLessonWithBNB(
        uint256 lessonId_,
        uint256 amountOutMin,
        uint256 deadline
    ) external payable {
        require(lesson[lessonId_].price != 0, "Payment: Lesson with this id doesn't exist");
        require(lesson[lessonId_].available, "Payment: Lesson is now unavailable");
        require(!lessonAvailability[msg.sender][lessonId_], "Payment: Lessen already paid");
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(token);
        uint256 amount = getTokenAmountForCurrentPrice(lesson[lessonId_].price) * 1e18;
        uint256 minTokenAmount = getTokenAmountForCurrentPrice(lesson[lessonId_].price - 5) * 1e18;
        uint256[] memory tokenAmount = router.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            address(this),
            deadline
        );
        require(tokenAmount[1] >= minTokenAmount, "Payment: Insufficient tokens");
        if (tokenAmount[1] > amount) {
            lessonAvailability[msg.sender][lessonId_] = true;
            emit PaidForLesson(lessonId_, msg.sender, lesson[lessonId_].price, amount);
            token.transfer(address(burnReserve), (amount * 7000) / 10000);
            token.transfer(lesson[lessonId_].tutor, (amount * lesson[lessonId_].tutorPercent) / 10000);
            token.transfer(treasury, (amount * lesson[lessonId_].profitPercent) / 10000);
            token.transfer(msg.sender, tokenAmount[1] - amount);
            // Add tokens to pool
            swap(amount);
        } else {
            lessonAvailability[msg.sender][lessonId_] = true;
            emit PaidForLesson(lessonId_, msg.sender, lesson[lessonId_].price, tokenAmount[1]);
            token.transfer(address(burnReserve), (tokenAmount[1] * 7000) / 10000);
            token.transfer(lesson[lessonId_].tutor, (tokenAmount[1] * lesson[lessonId_].tutorPercent) / 10000);
            token.transfer(treasury, (tokenAmount[1] * lesson[lessonId_].profitPercent) / 10000);
            // Add tokens to pool
            swap(tokenAmount[1]);
        }
    }

    function subscribeForNews(uint256 months_) external {
        require(subscribtionPrice[months_] != 0, "Payment: Invalid subscription plan");
        if (subscribtionInfo[msg.sender] > block.number) {
            subscribtionInfo[msg.sender] += months_ * BLOCKS_PER_MONTH;
        }
        if (subscribtionInfo[msg.sender] < block.number) {
            subscribtionInfo[msg.sender] = block.number + months_ * BLOCKS_PER_MONTH;
        }
        token.transferFrom(
            msg.sender,
            address(burnReserve),
            getTokenAmountForCurrentPrice(subscribtionPrice[months_]) * 1e18
        );
        emit SubscibtionComplited(
            months_,
            msg.sender,
            subscribtionInfo[msg.sender],
            subscribtionPrice[months_],
            getTokenAmountForCurrentPrice(subscribtionPrice[months_])
        );
    }

    function freeTrialActivation() external {
        require(subscribtionInfo[msg.sender] == 0, "Payment: You can't activate free trial");
        subscribtionInfo[msg.sender] = block.number + freeTrialDuration;
    }

    // View functions

    function newsAvailability(address user_) public view returns (bool) {
        if (subscribtionInfo[user_] > block.number) {
            return true;
        }
        return false;
    }

    function getTokenAmountForCurrentPrice(uint256 price_) public view returns (uint256) {
        uint256 bnbPrice = uint256(priceFeed.latestAnswer());
        uint256 tokenBalance = token.balanceOf(address(pair));
        uint256 bnbBalance = IERC20(WBNB).balanceOf(address(pair));
        uint256 tokenPrice = bnbPrice / (tokenBalance / bnbBalance);
        return (price_ * 1e8) / tokenPrice;
    }

    function swap(uint256 amount) internal {
        uint256 amountForLiquidity = (amount * 6000) / 10000;
        address[] memory path = new address[](2);

        path[0] = address(token);
        path[1] = WBNB;
        if (token.balanceOf(liquidityReserve) >= amountForLiquidity) {
            token.transferFrom(liquidityReserve, address(this), amountForLiquidity);
            token.approve(address(router), amountForLiquidity);
            router.swapExactTokensForETH(amountForLiquidity, 0, path, treasury, block.timestamp + 1000);
        }
    }
}