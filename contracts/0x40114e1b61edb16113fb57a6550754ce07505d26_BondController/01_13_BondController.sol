pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interfaces/IBondController.sol";
import "./interfaces/ITrancheFactory.sol";
import "./interfaces/ITranche.sol";
import "./interfaces/IRebasingERC20.sol";

/**
 * @dev Controller for a ButtonTranche bond
 *
 * Invariants:
 *  - `totalDebt` should always equal the sum of all tranche tokens' `totalSupply()`
 */
contract BondController is IBondController, OwnableUpgradeable {
    uint256 private constant TRANCHE_RATIO_GRANULARITY = 1000;
    // One tranche for A-Z
    uint256 private constant MAX_TRANCHE_COUNT = 26;
    // Denominator for basis points. Used to calculate fees
    uint256 private constant BPS = 10_000;
    // Maximum fee in terms of basis points
    uint256 private constant MAX_FEE_BPS = 50;

    // to avoid precision loss and other weird math from a small total debt
    // we require the debt to be at least MINIMUM_VALID_DEBT if any
    uint256 private constant MINIMUM_VALID_DEBT = 10e9;

    address public override collateralToken;
    TrancheData[] public override tranches;
    uint256 public override trancheCount;
    mapping(address => bool) public trancheTokenAddresses;
    uint256 public override creationDate;
    uint256 public override maturityDate;
    bool public override isMature;
    uint256 public override totalDebt;
    uint256 public lastScaledCollateralBalance;

    // Maximum amount of collateral that can be deposited into this bond
    // Used as a guardrail for initial launch.
    // If set to 0, no deposit limit will be enforced
    uint256 public depositLimit;
    // Fee taken on deposit in basis points. Can be set by the contract owner
    uint256 public override feeBps;

    /**
     * @dev Constructor for Tranche ERC20 token
     * @param _trancheFactory The address of the tranche factory
     * @param _collateralToken The address of the ERC20 collateral token
     * @param _admin The address of the initial admin for this contract
     * @param trancheRatios The tranche ratios for this bond
     * @param _maturityDate The date timestamp in seconds at which this bond matures
     * @param _depositLimit The maximum amount of collateral that can be deposited. 0 if no limit
     */
    function init(
        address _trancheFactory,
        address _collateralToken,
        address _admin,
        uint256[] memory trancheRatios,
        uint256 _maturityDate,
        uint256 _depositLimit
    ) external initializer {
        require(_trancheFactory != address(0), "BondController: invalid trancheFactory address");
        require(_collateralToken != address(0), "BondController: invalid collateralToken address");
        require(_admin != address(0), "BondController: invalid admin address");
        require(trancheRatios.length <= MAX_TRANCHE_COUNT, "BondController: invalid tranche count");
        __Ownable_init();
        transferOwnership(_admin);

        trancheCount = trancheRatios.length;
        collateralToken = _collateralToken;
        string memory collateralSymbol = IERC20Metadata(collateralToken).symbol();

        uint256 totalRatio;
        for (uint256 i = 0; i < trancheRatios.length; i++) {
            uint256 ratio = trancheRatios[i];
            require(ratio <= TRANCHE_RATIO_GRANULARITY, "BondController: Invalid tranche ratio");
            totalRatio += ratio;

            address trancheTokenAddress = ITrancheFactory(_trancheFactory).createTranche(
                getTrancheName(collateralSymbol, i, trancheRatios.length),
                getTrancheSymbol(collateralSymbol, i, trancheRatios.length),
                _collateralToken
            );
            tranches.push(TrancheData(ITranche(trancheTokenAddress), ratio));
            trancheTokenAddresses[trancheTokenAddress] = true;
        }

        require(totalRatio == TRANCHE_RATIO_GRANULARITY, "BondController: Invalid tranche ratios");
        require(_maturityDate > block.timestamp, "BondController: Invalid maturity date");
        creationDate = block.timestamp;
        maturityDate = _maturityDate;
        depositLimit = _depositLimit;
    }

    /**
     * @dev Skims extraneous collateral that was incorrectly sent to the contract
     */
    modifier onSkim() {
        uint256 scaledCollateralBalance = IRebasingERC20(collateralToken).scaledBalanceOf(address(this));
        // If there is extraneous collateral, transfer to the owner
        if (scaledCollateralBalance > lastScaledCollateralBalance) {
            uint256 _collateralBalance = IERC20(collateralToken).balanceOf(address(this));
            uint256 virtualCollateralBalance = Math.mulDiv(
                lastScaledCollateralBalance,
                _collateralBalance,
                scaledCollateralBalance
            );
            TransferHelper.safeTransfer(collateralToken, owner(), _collateralBalance - virtualCollateralBalance);
        }
        _;
        // Update the lastScaledCollateralBalance after the function call
        lastScaledCollateralBalance = IRebasingERC20(collateralToken).scaledBalanceOf(address(this));
    }

    /**
     * @inheritdoc IBondController
     */
    function deposit(uint256 amount) external override onSkim {
        require(amount > 0, "BondController: invalid amount");

        require(!isMature, "BondController: Already mature");

        uint256 _collateralBalance = IERC20(collateralToken).balanceOf(address(this));
        require(depositLimit == 0 || _collateralBalance + amount <= depositLimit, "BondController: Deposit limit");

        TrancheData[] memory _tranches = tranches;

        uint256 newDebt;
        uint256[] memory trancheValues = new uint256[](trancheCount);
        for (uint256 i = 0; i < _tranches.length; i++) {
            // NOTE: solidity 0.8 checks for over/underflow natively so no need for SafeMath
            uint256 trancheValue = (amount * _tranches[i].ratio) / TRANCHE_RATIO_GRANULARITY;

            // if there is any collateral, we should scale by the debt:collateral ratio
            // note: if totalDebt == 0 then we're minting for the first time
            // so shouldn't scale even if there is some collateral mistakenly sent in
            if (_collateralBalance > 0 && totalDebt > 0) {
                trancheValue = Math.mulDiv(trancheValue, totalDebt, _collateralBalance);
            }
            newDebt += trancheValue;
            trancheValues[i] = trancheValue;
        }
        totalDebt += newDebt;

        TransferHelper.safeTransferFrom(collateralToken, _msgSender(), address(this), amount);
        // saving feeBps in memory to minimize sloads
        uint256 _feeBps = feeBps;
        for (uint256 i = 0; i < trancheValues.length; i++) {
            uint256 trancheValue = trancheValues[i];
            // fee tranche tokens are minted and held by the contract
            // upon maturity, they are redeemed and underlying collateral are sent to the owner
            uint256 fee = (trancheValue * _feeBps) / BPS;
            if (fee > 0) {
                _tranches[i].token.mint(address(this), fee);
            }

            _tranches[i].token.mint(_msgSender(), trancheValue - fee);
        }
        emit Deposit(_msgSender(), amount, _feeBps);

        _enforceTotalDebt();
    }

    /**
     * @inheritdoc IBondController
     */
    function mature() external override onSkim {
        require(!isMature, "BondController: Already mature");
        require(owner() == _msgSender() || maturityDate < block.timestamp, "BondController: Invalid call to mature");
        isMature = true;

        TrancheData[] memory _tranches = tranches;
        uint256 _collateralBalance = IERC20(collateralToken).balanceOf(address(this));
        // Go through all tranches A-Y (not Z) delivering collateral if possible
        for (uint256 i = 0; i < _tranches.length - 1 && _collateralBalance > 0; i++) {
            ITranche _tranche = _tranches[i].token;
            // pay out the entire tranche token's owed collateral (equal to the supply of tranche tokens)
            // if there is not enough collateral to pay it out, pay as much as we have
            uint256 amount = Math.min(_tranche.totalSupply(), _collateralBalance);
            _collateralBalance -= amount;

            TransferHelper.safeTransfer(collateralToken, address(_tranche), amount);

            // redeem fees, sending output tokens to owner
            _tranche.redeem(address(this), owner(), IERC20(_tranche).balanceOf(address(this)));
        }

        // Transfer any remaining collaeral to the Z tranche
        if (_collateralBalance > 0) {
            ITranche _tranche = _tranches[_tranches.length - 1].token;
            TransferHelper.safeTransfer(collateralToken, address(_tranche), _collateralBalance);
            _tranche.redeem(address(this), owner(), IERC20(_tranche).balanceOf(address(this)));
        }

        emit Mature(_msgSender());
    }

    /**
     * @inheritdoc IBondController
     */
    function redeemMature(address tranche, uint256 amount) external override {
        require(isMature, "BondController: Bond is not mature");
        require(trancheTokenAddresses[tranche], "BondController: Invalid tranche address");

        ITranche(tranche).redeem(_msgSender(), _msgSender(), amount);
        totalDebt -= amount;
        emit RedeemMature(_msgSender(), tranche, amount);
    }

    /**
     * @inheritdoc IBondController
     */
    function redeem(uint256[] memory amounts) external override onSkim {
        require(!isMature, "BondController: Bond is already mature");

        TrancheData[] memory _tranches = tranches;
        require(amounts.length == _tranches.length, "BondController: Invalid redeem amounts");
        uint256 total;

        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }

        for (uint256 i = 0; i < amounts.length; i++) {
            require(
                (amounts[i] * TRANCHE_RATIO_GRANULARITY) / total == _tranches[i].ratio,
                "BondController: Invalid redemption ratio"
            );
            _tranches[i].token.burn(_msgSender(), amounts[i]);
        }

        uint256 _collateralBalance = IERC20(collateralToken).balanceOf(address(this));
        // return as a proportion of the total debt redeemed
        uint256 returnAmount = Math.mulDiv(total, _collateralBalance, totalDebt);

        totalDebt -= total;
        TransferHelper.safeTransfer(collateralToken, _msgSender(), returnAmount);
        emit Redeem(_msgSender(), amounts);

        _enforceTotalDebt();
    }

    /**
     * @inheritdoc IBondController
     */
    function setFee(uint256 newFeeBps) external override onlyOwner {
        require(!isMature, "BondController: Invalid call to setFee");
        require(newFeeBps <= MAX_FEE_BPS, "BondController: New fee too high");
        feeBps = newFeeBps;

        emit FeeUpdate(newFeeBps);
    }

    /**
     * @dev Get the string name for a tranche
     * @param collateralSymbol the symbol of the collateral token
     * @param index the tranche index
     * @param _trancheCount the total number of tranches
     * @return the string name of the tranche
     */
    function getTrancheName(
        string memory collateralSymbol,
        uint256 index,
        uint256 _trancheCount
    ) internal pure returns (string memory) {
        return
            string(abi.encodePacked("ButtonTranche ", collateralSymbol, " ", getTrancheLetter(index, _trancheCount)));
    }

    /**
     * @dev Get the string symbol for a tranche
     * @param collateralSymbol the symbol of the collateral token
     * @param index the tranche index
     * @param _trancheCount the total number of tranches
     * @return the string symbol of the tranche
     */
    function getTrancheSymbol(
        string memory collateralSymbol,
        uint256 index,
        uint256 _trancheCount
    ) internal pure returns (string memory) {
        return string(abi.encodePacked("TRANCHE-", collateralSymbol, "-", getTrancheLetter(index, _trancheCount)));
    }

    /**
     * @dev Get the string letter for a tranche index
     * @param index the tranche index
     * @param _trancheCount the total number of tranches
     * @return the string letter of the tranche index
     */
    function getTrancheLetter(uint256 index, uint256 _trancheCount) internal pure returns (string memory) {
        bytes memory trancheLetters = bytes("ABCDEFGHIJKLMNOPQRSTUVWXY");
        bytes memory target = new bytes(1);
        if (index == _trancheCount - 1) {
            target[0] = "Z";
        } else {
            target[0] = trancheLetters[index];
        }
        return string(target);
    }

    // @dev Ensuring total debt isn't too small
    function _enforceTotalDebt() internal {
        require(totalDebt >= MINIMUM_VALID_DEBT, "BondController: Expected minimum valid debt");
    }

    /**
     * @dev Get the virtual collateral balance of the bond
     * @return the virtual collateral balance
     */
    function collateralBalance() external view returns (uint256) {
        uint256 scaledCollateralBalance = IRebasingERC20(collateralToken).scaledBalanceOf(address(this));
        uint256 _collateralBalance = IERC20(collateralToken).balanceOf(address(this));

        return
            (scaledCollateralBalance > lastScaledCollateralBalance)
                ? Math.mulDiv(lastScaledCollateralBalance, _collateralBalance, scaledCollateralBalance)
                : _collateralBalance;
    }
}