// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HWRegistry is Ownable {
    struct Whitelist {
        address token;
        uint256 maxAllowed;
    }

    Counters.Counter public counter;

    mapping(uint256 => Whitelist) public whitelisted;

    event WhitelistedAdded(address indexed _address, uint256 _maxAllowed);
    event WhitelistedRemoved(address indexed _address);
    event WhitelistedUpdated(address indexed _address, uint256 _maxAllowed);

    function addWhitelisted(
        address _address,
        uint256 _maxAllowed
    ) external onlyOwner returns (bool) {
        whitelisted[Counters.current(counter)] = Whitelist({
            token: _address,
            maxAllowed: _maxAllowed
        });
        Counters.increment(counter);
        emit WhitelistedAdded(_address, _maxAllowed);
        return true;
    }

    function removeWhitelisted(uint256 _id) external onlyOwner returns (bool) {
        address _address = whitelisted[_id].token;
        whitelisted[_id] = Whitelist({token: address(0), maxAllowed: 0});
        emit WhitelistedRemoved(_address);
        return true;
    }

    function updateWhitelisted(
        address _address,
        uint256 _maxAllowed
    ) external onlyOwner returns (bool) {
        whitelisted[getWhitelistedID(_address)].maxAllowed = _maxAllowed;
        emit WhitelistedUpdated(_address, _maxAllowed);
        return true;
    }

    function getWhitelistedID(address _address) private view returns (uint256) {
        uint256 token_id;
        for (uint256 i = 0; i < Counters.current(counter); i++) {
            if (whitelisted[i].token == _address) {
                token_id = i;
            }
        }
        return token_id;
    }

    function isWhitelisted(address _address) external view returns (bool) {
        bool isWhitelisted_;
        for (uint256 i = 0; i < Counters.current(counter); i++) {
            if (whitelisted[i].token == _address) {
                isWhitelisted_ = true;
            }
        }
        return isWhitelisted_;
    }

    function isAllowedAmount(
        address _address,
        uint256 _amount
    ) external view returns (bool) {
        bool isAllowedAmount_;
        for (uint256 i = 0; i < Counters.current(counter); i++) {
            if (whitelisted[i].token == _address) {
                if (whitelisted[i].maxAllowed >= _amount) {
                    isAllowedAmount_ = true;
                }
            }
        }
        return isAllowedAmount_;
    }

    function allWhitelisted() external view returns (Whitelist[] memory) {
        Whitelist[] memory whitelisted_ = new Whitelist[](
            Counters.current(counter)
        );
        for (uint256 i = 0; i < Counters.current(counter); i++) {
            whitelisted_[i] = whitelisted[i];
        }
        return whitelisted_;
    }
}