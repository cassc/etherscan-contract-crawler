// contracts/RiskControl.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IRiskControl.sol";
import "./interfaces/IEarningsOracle.sol";
import "./interfaces/IHashNFT.sol";
import "./Liquidator.sol";
import "./Stages.sol";

contract RiskControl is IRiskControl, AccessControl, Stages {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event IssuerHasChanged(address old, address issuer);
    event SetUpHashNFT(address hashnft);
    event Deliver(address from, address to, uint256 amount);
    event InitialPaymentHasGenerated(
        uint256 ratio,
        uint256 deliverReleaseAmount
    );
    event Liquidate(address liquidator, uint256 balance);
    event ClaimInitialPayment(address to, uint256 balance);
    event ClaimOption(address to, uint256 balance);
    event ClaimTax(address to, uint256 balance);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    uint256 public constant defaultInitialPaymentRatio = 3500;

    uint256 public immutable cost;

    uint256 public immutable taxPercent;

    uint256 public immutable optionPercent;

    IERC20 public immutable funds;

    IERC20 public immutable rewards;

    IOracle public immutable priceOracle;

    IEarningsOracle public immutable earningsOracle;

    IHashNFT public hashnft;

    address public issuer;

    uint256 public taxClaimed = 0;

    uint256 public option = 0;

    uint256 public optionClaimed = 0;

    uint256 public initialPayment = 0;

    uint256 public deliverReleaseAmount = 0;

    uint256 public initialPaymentClaimed = 0;

    mapping(uint256 => uint256) public override deliverRecords;

    constructor(
        uint256 _startTime,
        uint256 _cost,
        uint256 _optionPercent,
        uint256 _taxPercent,
        address payment,
        address _rewards,
        address _issuer,
        address po,
        address eo
    ) Stages(_startTime, 35 hours, 30 days, 360 days) {
        cost = _cost;
        taxPercent = _taxPercent;
        optionPercent = _optionPercent;

        funds = IERC20(payment);
        rewards = IERC20(_rewards);
        priceOracle = IOracle(po);
        earningsOracle = IEarningsOracle(eo);
        issuer = _issuer;

        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
        _setupRole(ISSUER_ROLE, issuer);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Set a new issuer address.
     *
     * Requirements:
     *
     * - `new_` cannot be the zero address.
     * - the caller must be the issuer.
     *
     * Emits a {IssuerHasChanged} event.
     */
    function setIssuer(address _new) public onlyRole(ADMIN_ROLE) {
        address old = issuer;
        _revokeRole(ISSUER_ROLE, old);
        issuer = _new;
        _setupRole(ISSUER_ROLE, issuer);
        emit IssuerHasChanged(old, issuer);
    }

    function setHashNFT(address _hashnft) public onlyRole(ADMIN_ROLE) {
        require(
            hashnft == IHashNFT(address(0)),
            "RiskControl: already set hashnft"
        );
        hashnft = IHashNFT(_hashnft);
        emit SetUpHashNFT(_hashnft);
    }

    function price() public view override returns (uint256) {
        return optionPercent.add(taxPercent).add(10000).mul(cost).div(10000);
    }

    function mintAllowed() public view override returns (bool) {
        return _currentStage() == Stage.CollectionPeriod;
    }

    function deliverAllowed() public view override returns (bool) {
        return _currentStage() > Stage.CollectionPeriod;
    }

    function offset() public view override returns (uint256) {
        require(
            _currentStage() > Stage.CollectionPeriod,
            "RiskControl: error stage"
        );
        uint256 duration = block.timestamp -
            (startTime + collectionPeriodDuration);
        return duration / 1 days;
    }

    function deliver() public {
        require(
            deliverAllowed() && offset() > 0,
            "RiskControl: deliver not allowed"
        );
        require(
            initialPayment != 0 || _currentStage() == Stage.ObservationPeriod,
            "RiskControl: must generate initial payment"
        );
        uint256 deliverDesDay = offset() - 1;
        require(deliverRecords[deliverDesDay] == 0, "RiskControl: already deliver");
        uint256 desDay = (block.timestamp / 1 days) - 1;
        uint256 earnings = earningsOracle.getRound(desDay);
        if (earnings == 0) {
            (, uint256 lastEarnings) = earningsOracle.lastRound();
            earnings = lastEarnings;
        }
        require(earnings > 0, "RiskControl: error daily earning");
        uint256 amount = earnings.mul(hashnft.sold());
        deliverRecords[deliverDesDay] = amount;
        rewards.safeTransferFrom(issuer, hashnft.dispatcher(), amount);
        if (deliverReleaseAmount > 0) {
            uint256 balance = funds.balanceOf((address(this)));
            if (deliverReleaseAmount > balance) {
                deliverReleaseAmount = balance;
            }
            funds.safeTransfer(issuer, deliverReleaseAmount);
        }
        emit Deliver(address(issuer), hashnft.dispatcher(), amount);
    }

    /**
     * @dev Liquidate
     */
    function liquidate()
        public
        onlyRole(ADMIN_ROLE)
        afterStage(Stage.CollectionPeriod)
    {
        require(funds.balanceOf(address(this)) != 0, "RiskControl: invalid funds balance");
        uint256 balance = funds.balanceOf(address(this));
        require(balance > 0, "RiskControl: no funds need liquidate");
        Liquidator liquidator = new Liquidator();
        funds.safeApprove(address(liquidator), balance);
        liquidator.liquidate(address(funds), hashnft.dispatcher(), address(hashnft), balance);

        emit Liquidate(address(liquidator), balance);
    }

    /**
     * @dev Generate the initial payment by the average bitcoin network power growth rate in the past
     * year, the option price of bitcoin and lending rates of bitcoin on aave.
     *
     * @param gh Over the past year, the average growth rate of bitcoin's entire network computing power should be multiplied by 10,000
     * @param pc The current value of the option, quoted by the option exchange, needs to be multiplied by 10,000
     * @param rb Bitcoin lending rate, you have to multiply by 10,000
     * Requirements:
     *
     * - `initialPayment` must be the zero.
     */
    function generateInitialPayment(
        uint256 gh,
        uint256 rb,
        uint256 hg,
        uint256 pc
    )
        public
        afterStage(Stage.ObservationPeriod)
        onlyRole(ADMIN_ROLE)
        returns (uint256)
    {
        require(initialPayment == 0, "RiskControl: initial payment not zero");

        uint256 currentPrice = priceOracle.getPrice();
        uint256 d = contractDurationInWeeks - observationDurationInWeeks; // 48
        // uint256 c = 625 * 6 * 24 * 7 * d; // * 100
        uint256 c = 33022100;
        uint256 ph = (100 * c * currentPrice * 10000 * 10000 * 13 * 13) /
            ((10000 * 13 + 6 * gh) * (10000 * 13 + 6 * rb)); // * 10000
        uint256 a = (d * ph) / contractDurationInWeeks / hg; // * 10000
        uint256 b = (100 * 65 * d * cost) / contractDurationInWeeks; // * 10000
        uint256 r = 0; // R=MAX{(48/52*PH-0.65*48/52*P-PC),0}/P

        if (a > b) {
            r = a - b;
            r /= cost;
            if (r > pc) {
                r -= pc;
            }
        }
        uint256 ratio = defaultInitialPaymentRatio * 10; // 35% (constant)+0.5*(0.28(initial risk)-R(current risk))
        if (2800 > r) {
            ratio = ratio + 5 * (2800 - r);
        } else {
            ratio = ratio - 5 * (r - 2800);
        }

        ratio /= 10;
        if (ratio < 2000) {
            ratio = 2000;
        }

        if (ratio > 5000) {
            ratio = 5000;
        }

        uint256 balance = hashnft.sold().mul(cost);
        initialPayment = balance.mul(ratio).div(10000);
        uint256 deliverTimer = contractDuraction.div(1 days).sub(offset());
        deliverTimer = deliverTimer.add(1);
        deliverReleaseAmount = balance.sub(initialPayment).div(deliverTimer);
        emit InitialPaymentHasGenerated(ratio, deliverReleaseAmount);
        return ratio;
    }

    function claimInitialPayment() public onlyRole(ISSUER_ROLE) {
        require(
            initialPaymentClaimed < initialPayment,
            "RiskControl: invalid initialPayment"
        );
        uint256 amount = initialPayment.sub(initialPaymentClaimed);
        initialPaymentClaimed = initialPayment;
        funds.safeTransfer(msg.sender, amount);
        emit ClaimInitialPayment(msg.sender, amount);
    }

    function claimTax(address to)
        public
        onlyRole(ADMIN_ROLE)
        afterStage(Stage.ObservationPeriod)
    {
        uint256 tax = hashnft.sold().mul(cost).mul(taxPercent).div(10000);
        require(taxClaimed < tax, "RiskControl: already tax claimed");
        uint256 amount = tax.sub(taxClaimed);
        taxClaimed = tax;
        funds.safeTransfer(to, amount);
        emit ClaimTax(to, amount);
    }

    function claimOption(address to)
        public
        onlyRole(ADMIN_ROLE)
        afterStage(Stage.CollectionPeriod)
    {
        option = hashnft.sold().mul(cost).mul(optionPercent).div(10000);
        require(optionClaimed < option, "RiskControl: already option claimed");
        uint256 amount = option.sub(optionClaimed);
        optionClaimed = option;
        funds.safeTransfer(to, amount);
        emit ClaimOption(to, amount);
    }
}