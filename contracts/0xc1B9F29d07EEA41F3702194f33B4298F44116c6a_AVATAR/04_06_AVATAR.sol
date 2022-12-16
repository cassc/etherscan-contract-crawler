// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AVATAR is ERC20, Ownable {
    uint256 private constant MAX_BPS = 100_00;

    uint256 public immutable start;
    uint256 public immutable end;
    uint256 public immutable initialPenalty;

    uint96 public fee;
    address public pair;
    bool private active;

    mapping(address => bool) public whitelisted;

    constructor() ERC20("Avatar Moon", "AVATAR", 18) {
        start = block.timestamp;
        initialPenalty = 7_00; // 7%
        end = block.timestamp + 30 days;
        fee = 3_33; // 3.33%
        active = false;

        require(initialPenalty <= MAX_BPS, "max penalty is 100%");
        require(fee <= MAX_BPS, "max fee is 100%");
        require(start <= end, "start must be <= end");

        whitelisted[msg.sender] = true;

        _mint(msg.sender, 250_000_000e18);
    }

    function currentPenalty() public view returns (uint256 _penalty) {
        if (block.timestamp < end) {
            unchecked {
                uint256 _remaining = end - block.timestamp;
                _penalty = (initialPenalty * _remaining) / (end - start);
            }
        }
    }

    function _transfer(address sender_, address recipient_, uint256 amount_) internal override {
        if (!whitelisted[sender_]) {
            require(active, "!active");

            uint256 _feeAmount = (amount_ * fee) / MAX_BPS;

            // Burn penalty
            if (sender_ != pair && block.timestamp < end) {
                uint256 _burnt = (amount_ * currentPenalty()) / MAX_BPS;

                if (_burnt > 0) {
                    super._transfer(sender_, address(0), _burnt);

                    // `_burnt` is always <= `amount_`
                    unchecked {
                        amount_ -= _burnt;
                    }
                }
            }

            // Collect fee
            if (_feeAmount > 0) {
                super._transfer(sender_, owner(), _feeAmount);
                // `_feeAmount` is always <= `amount_`
                unchecked {
                    amount_ -= _feeAmount;
                }
            }
        }

        super._transfer(sender_, recipient_, amount_);
    }

    function updatePair(address pair_) external onlyOwner {
        pair = pair_;
        active = true;
    }

    function updateFee(uint96 fee_) external onlyOwner {
        require(fee_ <= MAX_BPS, "max fee is 100%");
        fee = fee_;
    }

    function toggleWhitelist(address address_) external onlyOwner {
        whitelisted[address_] = !whitelisted[address_];
    }

    function sweep(IERC20 token_) external onlyOwner {
        if (address(token_) == address(0)) {
            Address.sendValue(payable(owner()), address(this).balance);
        } else {
            token_.transfer(owner(), token_.balanceOf(address(this)));
        }
    }
}