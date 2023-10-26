// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./UbiquityAlgorithmicDollarManager.sol";
import "./interfaces/IUbiquityGovernance.sol";
import "./interfaces/IIncentive.sol";
import "./TWAPOracle.sol";
import "./UbiquityAlgorithmicDollar.sol";
import "./libs/ABDKMathQuad.sol";

/// @title Uniswap trading incentive contract
/// @author uAD Protocol
/// @dev incentives
contract CurveUADIncentive is IIncentive {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;
    UbiquityAlgorithmicDollarManager public manager;
    bool public isSellPenaltyOn = true;
    bool public isBuyIncentiveOn = true;
    bytes16 private immutable _one = (uint256(1 ether)).fromUInt();
    mapping(address => bool) private _exempt;
    event ExemptAddressUpdate(address indexed _account, bool _isExempt);
    modifier onlyAdmin() {
        require(
            manager.hasRole(manager.INCENTIVE_MANAGER_ROLE(), msg.sender),
            "CurveIncentive: not admin"
        );
        _;
    }
    modifier onlyUAD() {
        require(
            msg.sender == manager.dollarTokenAddress(),
            "CurveIncentive: Caller is not uAD"
        );
        _;
    }

    /// @notice CurveIncentive constructor
    /// @param _manager uAD Manager
    constructor(address _manager) {
        manager = UbiquityAlgorithmicDollarManager(_manager);
    }

    function incentivize(
        address sender,
        address receiver,
        address,
        uint256 amountIn
    ) external override onlyUAD {
        require(sender != receiver, "CurveIncentive: cannot send self");

        if (sender == manager.stableSwapMetaPoolAddress()) {
            _incentivizeBuy(receiver, amountIn);
        }

        if (receiver == manager.stableSwapMetaPoolAddress()) {
            _incentivizeSell(sender, amountIn);
        }
    }

    /// @notice set an address to be exempted from Uniswap trading incentives
    /// @param account the address to update
    /// @param isExempt a flag for whether to exempt or unexempt
    function setExemptAddress(address account, bool isExempt)
        external
        onlyAdmin
    {
        _exempt[account] = isExempt;
        emit ExemptAddressUpdate(account, isExempt);
    }

    /// @notice switch the sell penalty
    function switchSellPenalty() external onlyAdmin {
        isSellPenaltyOn = !isSellPenaltyOn;
    }

    /// @notice switch the buy incentive
    function switchBuyIncentive() external onlyAdmin {
        isBuyIncentiveOn = !isBuyIncentiveOn;
    }

    /// @notice returns true if account is marked as exempt
    function isExemptAddress(address account) public view returns (bool) {
        return _exempt[account];
    }

    function _incentivizeBuy(address target, uint256 amountIn) internal {
        _updateOracle();

        if (isExemptAddress(target) || !isBuyIncentiveOn) {
            return;
        }

        uint256 incentive = _getPercentDeviationFromUnderPeg(amountIn);
        /* swapping 3CRV (or underlying) for uAD (aka buying uAD) will mint x% of uGOV.
             Where x = (1- TWAP_Price) * amountIn.
            E.g. uAD = 0.8, you buy 1000 uAD, you get (1-0.8)*1000 = 200 uGOV */

        if (incentive != 0) {
            // this means CurveIncentive should be a minter of UGOV
            IUbiquityGovernance(manager.governanceTokenAddress()).mint(
                target,
                incentive
            );
        }
    }

    /// @notice returns the percentage of deviation from the peg multiplied by amount
    //          when uAD is <1$
    function _getPercentDeviationFromUnderPeg(uint256 amount)
        internal
        returns (uint256)
    {
        _updateOracle();
        uint256 curPrice = _getTWAPPrice();
        if (curPrice >= 1 ether) {
            return 0;
        }

        uint256 res = _one
            .sub(curPrice.fromUInt())
            .mul((amount.fromUInt().div(_one)))
            .toUInt();
        // returns (1- TWAP_Price) * amount.
        return res;
    }

    function _incentivizeSell(address target, uint256 amount) internal {
        _updateOracle();
        if (isExemptAddress(target) || !isSellPenaltyOn) {
            return;
        }

        /*
        WARNING
        From curve doc :Tokens that take a fee upon a successful transfer may cause the curve pool
        to break or act in unexpected ways.
        fei does it differently because they can make sure only one contract has the ability to sell
        uAD and they control the whole liquidity pool on uniswap.
        here to avoid problem with the curve pool we execute the transfer as specified and then we
        take the penalty so if penalty + amount > balance then we revert
        swapping uAD for 3CRV (or underlying) (aka selling uAD) will burn x% of uAD
        Where x = (1- TWAP_Price) *100.
        */

        uint256 penalty = _getPercentDeviationFromUnderPeg(amount);
        if (penalty != 0) {
            require(penalty < amount, "Dollar: burn exceeds trade size");

            require(
                UbiquityAlgorithmicDollar(manager.dollarTokenAddress())
                    .balanceOf(target) >= penalty + amount,
                "Dollar: balance too low to get penalized"
            );
            UbiquityAlgorithmicDollar(manager.dollarTokenAddress()).burnFrom(
                target,
                penalty
            ); // burn from the recipient
        }
    }

    function _updateOracle() internal {
        TWAPOracle(manager.twapOracleAddress()).update();
    }

    function _getTWAPPrice() internal view returns (uint256) {
        return
            TWAPOracle(manager.twapOracleAddress()).consult(
                manager.dollarTokenAddress()
            );
    }
}