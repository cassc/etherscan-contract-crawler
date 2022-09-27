// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Insurance is Ownable {
    // variable general
    address payable private admin;
    uint256 public totalInsurance;
    uint256 public quantity_nain_eligible_for_incentives;
    address public address_nain;
    bool private enable_nain;
    IERC20 token_nain;
    IERC20 usdt;

    // 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684 address USDT bsc testnet
    // 0x539CAFC25E2983bcFC47503F5FD582B20Cbb56c7 address sc NAIN bsc testnet
    // 0x110a13FC3efE6A245B50102D2d79B3E76125Ae83 ropsten testnet

    constructor(address _addressUSDT) {
        admin = payable(msg.sender);
        totalInsurance = 0;
        usdt = IERC20(_addressUSDT);
        quantity_nain_eligible_for_incentives = 99 * 10**18;
        enable_nain = false;
    }

    // insurance struct
    struct InsuranceStruct {
        uint256 idInsurance;
        address buyer;
        string asset;
        uint256 margin;
        uint256 q_covered;
        uint256 p_market;
        uint256 p_claim;
        string state;
        uint256 period;
        uint256 recognition_date;
        uint256 expired;
        bool isUseNain;
    }

    // map id to insurance
    mapping(uint256 => InsuranceStruct) private insurance;

    /*
     @event
    **/
    event EBuyInsurance(
        uint256 idInsurance,
        address buyer,
        string asset,
        uint256 margin,
        uint256 q_covered,
        uint256 p_market,
        uint256 p_claim,
        string state,
        uint256 period,
        uint256 recognition_date,
        bool isUseNain
    );
    event EUpdateStateInsurance(uint256 idInsurance);
    event EUpdateQuantityNainEligibleForIncentives(
        uint256 quantity_nain_eligible_for_incentives
    );

    // Only admin has permission to perform this function
    modifier onlyContractCaller(address _caller) {
        require(
            msg.sender == _caller,
            "Only the person who is calling the contract will be executed"
        );
        _;
    }
    modifier checkAllowanceUSDT(uint256 amount) {
        require(
            usdt.allowance(msg.sender, address(this)) >= amount,
            "Error allowance"
        );
        _;
    }

    function configAddressNain(address _address_nain) external onlyOwner {
        address_nain = _address_nain;
        token_nain = IERC20(_address_nain);
        enable_nain = true;
    }

    function renounceNain() external onlyOwner {
        enable_nain = false;
    }

    function updateQuantityNainEligibleForIncentives(uint256 _quantity)
        external
        onlyOwner
    {
        quantity_nain_eligible_for_incentives = _quantity;
    }

    function insuranceState(uint256 _insuranceId)
        external
        view
        returns (InsuranceStruct memory)
    {
        return insurance[_insuranceId];
    }

    function createInsurance(
        address _buyer,
        string memory _asset,
        uint256 _margin,
        uint256 _q_covered,
        uint256 _p_market,
        uint256 _p_claim,
        uint256 _period,
        bool _isUseNain
    )
        external
        payable
        onlyContractCaller(_buyer)
        checkAllowanceUSDT(_margin)
        returns (InsuranceStruct memory)
    {
        require(
            _period >= 2 && _period <= 15,
            "The time must be within the specified range 2 - 15"
        );
        require(
            usdt.balanceOf(address(msg.sender)) >= _margin,
            "USDT does't enough or not approve please check again!"
        );

        if (_isUseNain && !enable_nain) {
            revert("This feature is disabled");
        }

        if (_isUseNain && enable_nain) {
            require(
                token_nain.balanceOf(address(msg.sender)) >=
                    quantity_nain_eligible_for_incentives,
                "NAIN does't enough, please check again!"
            );

            // transfer nain
            token_nain.transferFrom(
                msg.sender,
                admin,
                quantity_nain_eligible_for_incentives
            );
        }

        InsuranceStruct memory newInsurance = InsuranceStruct(
            totalInsurance + 1,
            _buyer,
            _asset,
            _margin,
            _q_covered,
            _p_market,
            _p_claim,
            "Available",
            _period,
            0,
            block.timestamp,
            _isUseNain
        );

        usdt.transferFrom(msg.sender, admin, _margin);

        insurance[totalInsurance + 1] = newInsurance;

        emit EBuyInsurance(
            totalInsurance + 1,
            _buyer,
            _asset,
            _margin,
            _q_covered,
            _p_market,
            _p_claim,
            "Available",
            _period,
            0,
            _isUseNain
        );

        // increase insurance identifier
        totalInsurance++;

        return newInsurance;
    }

    function updateStateInsurance(uint256 _idInsurance, string memory _state)
        external
        onlyOwner
        returns (bool)
    {
        require(
            compareString(_state, "Claim_waiting") ||
                compareString(_state, "Claimed") ||
                compareString(_state, "Refunded") ||
                compareString(_state, "Liquidated") ||
                compareString(_state, "Expired"),
            "State does not exist"
        );

        if (
            compareString(insurance[_idInsurance].state, "Claimed") ||
            compareString(insurance[_idInsurance].state, "Refunded") ||
            compareString(insurance[_idInsurance].state, "Liquidated") ||
            compareString(insurance[_idInsurance].state, "Expired")
        ) {
            revert("State has been update");
        }

        insurance[_idInsurance].state = _state;
        insurance[_idInsurance].recognition_date = block.timestamp;

        emit EUpdateStateInsurance(_idInsurance);

        return true;
    }

    /*
     @helper
    **/
    function compareString(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}