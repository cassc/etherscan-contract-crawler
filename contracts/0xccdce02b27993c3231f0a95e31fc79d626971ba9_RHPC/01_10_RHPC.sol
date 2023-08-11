// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract RHPC is ERC20Burnable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant DENOMINATOR = 100000;
    uint256 public constant ANTIWHALE_PERCENTAGE = 150;

    uint256[3] public percentages = [45, 45, 210];
    uint256[3] public timestamps;
    uint256[3] public timestampsAddedTime = [518400, 1209600, 2592000];
    address[2] public sendAddresses;

    bool public antiwhaleActive;

    mapping(address => uint256) public antiwhaleCountdownStarted;

    EnumerableSet.AddressSet private excludedFromFee;
    EnumerableSet.AddressSet private knownV2Factories;
    uint256[2] private _amountsCollected;

    constructor(address owner, uint256 supply, address[2] memory _sendAddresses, address uniswapV2Factory) ERC20("Richie Coin","RHPC") {
        _mint(owner, supply);
        sendAddresses = _sendAddresses;
        for (uint8 i; i < 3; i++) {
            timestamps[i] = block.timestamp + timestampsAddedTime[i];
        }
        knownV2Factories.add(uniswapV2Factory);
        _transferOwnership(owner);
    }

    function excludedFromFeeLength() external view returns(uint256) {
        return excludedFromFee.length();
    }

    function excludedFromFeeList() external view returns(address[] memory) {
        return excludedFromFee.values();
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return excludedFromFee.contains(account);
    }

    function knownV2FactoriesLength() external view returns(uint256) {
        return knownV2Factories.length();
    }

    function knownV2FactoriesList() external view returns(address[] memory) {
        return knownV2Factories.values();
    }

    function isKnownV2Factory(address target) external view returns(bool) {
        return knownV2Factories.contains(target);
    }

    function setAntiwhaleActive(bool _antiwhaleActive) external onlyOwner {
        antiwhaleActive = _antiwhaleActive;
    }

    function excludeFromFee(address[] calldata account) external onlyOwner {
        for (uint256 i; i < account.length; i++) {
            excludedFromFee.add(account[i]);
        }
    }

    function includeInFee(address[] calldata account) external onlyOwner {
        for (uint256 i; i < account.length; i++) {
            excludedFromFee.remove(account[i]);
        }
    }

    function addKnownV2Factories(address[] calldata target) external onlyOwner {
        for (uint256 i; i < target.length; i++) {
            knownV2Factories.add(target[i]);
        }
    }

    function removeKnownV2Factories(address[] calldata target) external onlyOwner {
        for (uint256 i; i < target.length; i++) {
            knownV2Factories.remove(target[i]);
        }
    }

    function setPercentages(uint256[3] calldata _percentages) external onlyOwner {
        require(_sum(_percentages) <= DENOMINATOR, "Invalid percentages sum");
        percentages = _percentages;
    }

    function setSendAddresses(address[2] calldata _sendAddresses) external onlyOwner {
        require(_sendAddresses[0] != address(0) && _sendAddresses[1] != address(0), "Cannot set zero address");
        sendAddresses = _sendAddresses;
    }

    function amountsCollected(uint8 id) public view returns(uint256) {
        if (id == 2) {
            return balanceOf(address(this)) - (_amountsCollected[0] + _amountsCollected[1]);
        }
        else {
            return _amountsCollected[id];
        }
    }

    function handleSend() public {
        for (uint8 i; i < 2; i++) {
            if (block.timestamp >= timestamps[i]) {
                super._transfer(address(this), sendAddresses[i], _amountsCollected[i]);
                _amountsCollected[i] = 0;
                timestamps[i] = block.timestamp + timestampsAddedTime[i];
            }
        }
        if (block.timestamp >= timestamps[2]) {
            _burn(address(this), amountsCollected(2));
            timestamps[2] = block.timestamp + timestampsAddedTime[2];
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (antiwhaleActive && _isAntiwhaleApplicable(to) && amount > (totalSupply() * ANTIWHALE_PERCENTAGE) / DENOMINATOR) {
            if (block.timestamp >= antiwhaleCountdownStarted[from] + 86400) {
                antiwhaleCountdownStarted[from] = block.timestamp;
            }
            else {
                revert("Antiwhale countdown not passed yet");
            }
        }
        if (!excludedFromFee.contains(from)) {
            uint256[3] memory amounts;
            for (uint8 i; i < 3; i++) {
                amounts[i] = (amount * percentages[i]) / DENOMINATOR;
                if (i < 2) {
                    _amountsCollected[i] += amounts[i];
                }
            }
            amount -= _sum(amounts);
            super._transfer(from, address(this), _sum(amounts));
        }
        super._transfer(from, to, amount);
        handleSend();
    }

    function _isAntiwhaleApplicable(address target) private view returns(bool) {
        address token0;
        address token1;
        address factory;

        if (target.code.length > 0) {
            try IUniswapV2Pair(target).token0() returns (address _token0) {
                token0 = _token0;
            } catch {
                return false;
            }

            try IUniswapV2Pair(target).token1() returns (address _token1) {
                token1 = _token1;
            } catch {
                return false;
            }

            try IUniswapV2Pair(target).factory() returns (address _factory) {
                factory = _factory;
            } catch {
                return false;
            }

            return (knownV2Factories.contains(factory) && 
                IUniswapV2Factory(factory).getPair(token0, token1) == target && 
                (token0 == address(this) || token1 == address(this)));
        }
        return false;
    }

    function _sum(uint256[3] memory toSum) private pure returns(uint256) {
        uint256 sum;
        for (uint8 i; i < 3; i++) {
            sum += toSum[i];
        }
        return sum;
    }
}