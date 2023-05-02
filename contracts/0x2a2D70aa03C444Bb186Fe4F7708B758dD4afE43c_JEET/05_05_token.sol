pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract JEET is ERC20 {
    uint256 public constant initialToken = 1428600000;
    uint256 public constant thresholdTimePeriod = 45 minutes;
    uint256 public immutable tempMaxTxnCap = 7143000 * 10 ** decimals();
    uint256 public immutable thresholdTimeStamp;

    bool public capped = true;
    address public immutable deployer;

    modifier checks(
        address from,
        address to,
        uint256 amount
    ) {
        if (capped) {
            if (from != deployer && to != deployer) {
                if (block.timestamp < thresholdTimeStamp) {
                    require(
                        amount <= tempMaxTxnCap,
                        "CAN'T TRANSACT MORE THAN THE CAP FOR NOW"
                    );
                } else {
                    capped = false;
                }
            }
        }
        _;
    }

    constructor() ERC20("JEET", "$JEET") {
        thresholdTimeStamp = block.timestamp + thresholdTimePeriod;
        deployer = msg.sender;
        _mint(msg.sender, initialToken * 10 ** decimals());
    }

    function transfer(
        address to,
        uint256 amount
    ) public override checks(msg.sender, to, amount) returns (bool success) {
        success = super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override checks(from, to, amount) returns (bool success) {
        success = super.transferFrom(from, to, amount);
    }

    function removeCap() external {
        require(msg.sender == deployer, "NOT AUTHORIZED");
        capped = false;
    }
}