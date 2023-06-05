// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract tokenVesting is ERC20 {
    event TokensClaimed(address vestor, uint256 amount);

    mapping(address => bool) public beneficiary;
    mapping (address => uint256) public claimed;
    function requireBeneficiary(address vestor) internal view {
        require(beneficiary[vestor], "require beneficiary");
    }
    modifier onlyBeneficiary() {
        requireBeneficiary(msg.sender);
        _;
    }

    uint256 constant RATIO_BASE = 10000;
    uint256 constant MONTH = 30 days;
    uint256 constant MONTH_PER_YEAR = 12;

    uint256 public init_timestamp;
    uint256 public maxSupply;
    uint32[] public reduce_ratio;  // reduce ratio(percent) per year
    struct vestInfo {
        address beneficiary;
        uint256 ratio;
        uint256 init_ratio;
        uint256 initReleaseMonth;
        uint256 peroidStartMonth;
        uint256 peroid1Factor;
        uint256 peroid;
        uint256 peroidReleaseTimes;
    }
    mapping(address => vestInfo) public vests;
    mapping(address => uint256) public peroid1Amount;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        uint256 launchTimeStampDist,
        uint32[] memory _reduce_ratio,
        vestInfo[] memory _vests
    ) ERC20(name, symbol) {
        require(launchTimeStampDist <= MONTH, "should launch in 30 days");
        init_timestamp = block.timestamp + launchTimeStampDist - MONTH;
        maxSupply = _maxSupply;

        reduce_ratio = new uint32[](_reduce_ratio.length);
        for(uint256 y = 0; y < _reduce_ratio.length; ++y) {
            reduce_ratio[y] = _reduce_ratio[y];
        }

        for (uint256 i = 0; i < _vests.length; ++i) {
            vestInfo memory v = _vests[i];
            require(beneficiary[v.beneficiary] == false, "beneficiary already exit");
            beneficiary[v.beneficiary] = true;
            vests[v.beneficiary] = v;
            computePeroid1Amount(v);
        }
    }

    function computePeroid1Amount(vestInfo memory v) internal {
        uint256 peroid_total_amount = maxSupply * (v.ratio - v.init_ratio) / RATIO_BASE;

        uint256 factor = v.peroid1Factor;
        uint256 base_factor = RATIO_BASE;
        for (uint256 p = 1; p < v.peroidReleaseTimes; ++p) {
            uint256 m = v.peroidStartMonth + p * v.peroid;

            if (m > MONTH_PER_YEAR && m % MONTH_PER_YEAR == 1) {
                base_factor = base_factor * (RATIO_BASE - reduce_ratio[m / MONTH_PER_YEAR - 1]) / RATIO_BASE;
            }

            factor += base_factor;
        }

        peroid1Amount[v.beneficiary] = peroid_total_amount * v.peroid1Factor / factor;
    }

    function amountPerMonth(address vestor, uint256 month) public view returns (uint256) {
        requireBeneficiary(vestor);

        uint256 amount = 0;
        vestInfo memory v = vests[vestor];

        if (month >= v.initReleaseMonth && v.init_ratio != 0) {
            amount += v.init_ratio * maxSupply / RATIO_BASE;
        }

        if (v.peroidReleaseTimes > 0) {

            // release all remain token
            if (month >= v.peroidStartMonth + (v.peroidReleaseTimes - 1) * v.peroid) {
                return v.ratio * maxSupply / RATIO_BASE;
            }

            if (month >= v.peroidStartMonth) {
                amount += peroid1Amount[v.beneficiary];

                uint256 base_amount = peroid1Amount[v.beneficiary] * RATIO_BASE / v.peroid1Factor;
                // peroid reduce released amount
                for (uint256 m = v.peroidStartMonth + v.peroid; m <= month; m += v.peroid) {
                    if (m > MONTH_PER_YEAR && m % MONTH_PER_YEAR == 1) {
                        base_amount = base_amount * (RATIO_BASE - reduce_ratio[m / MONTH_PER_YEAR - 1]) / RATIO_BASE;
                    }
                    amount += base_amount;
                }
            }
        }

        return amount;
    }

    function claim(uint256 amount) external onlyBeneficiary {
        uint256 month = (block.timestamp - init_timestamp) / MONTH;
        uint256 releasedAmount = amountPerMonth(msg.sender, month);

        require(amount + claimed[msg.sender] <= releasedAmount, "exceed releasedAmount");
        require(totalSupply() + amount <= maxSupply, "exceed maxSupply");

        claimed[msg.sender] += amount;
        _mint(msg.sender, amount);
        emit TokensClaimed(msg.sender, amount);
    }
}