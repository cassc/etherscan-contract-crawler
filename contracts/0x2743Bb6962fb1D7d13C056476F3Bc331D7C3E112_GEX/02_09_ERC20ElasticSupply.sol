// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";
import "IERC20ElasticSupply.sol";
import "TimeLocks.sol";


/**
* @title ERC20ElasticSupply
* @author Geminon Protocol
* @notice Base implementation for tokens that can be minted and burned by
* whitelisted addresses. New minters can only be added after a 7 days
* period after the request of the addition. The maximum amount that can be
* minted each day is limited for security. This limit varies depending on 
* the existing supply.
*/
contract ERC20ElasticSupply is IERC20ElasticSupply, ERC20, Ownable, TimeLocks {

    uint32 public baseMintRatio;
    uint256 public thresholdLimitMint;
    uint64 private _timestampLastMint;
    int256 private _meanMintRatio;

    mapping(address => bool) public minters;


    modifier onlyMinter() {
       require(minters[msg.sender] == true); // dev: Only minter
        _;
    }


    /// @param baseMintRatio_ max percentage of the supply that can be minted per day, 3 decimals [1,1000]
    /// @param thresholdLimitMint_ Minimum supply minted to begin requiring the maxMintRatio limit. 18 decimals.
    constructor(string memory name, string memory symbol, uint32 baseMintRatio_, uint256 thresholdLimitMint_) 
        ERC20(name, symbol) 
    {
        baseMintRatio = baseMintRatio_;
        thresholdLimitMint = thresholdLimitMint_;
    }


    /// @dev Add minter address. It has a 7 days timelock.
    function addMinter(address newMinter) external onlyOwner {
        require(changeRequests[address(0)].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[address(0)].timestampRequest > 7 days); // dev: Time elapsed
        require(newMinter == changeRequests[address(0)].newAddressRequested); // dev: Wrong address
        require(minters[newMinter] == false); // dev: Minter exists
        
        minters[newMinter] = true;
        changeRequests[address(0)].changeRequested = false;
        
        emit MinterAdded(newMinter);
    }

    /// @dev Removes minter address. Does not use timelock
    function removeMinter(address minter) external onlyOwner {
        require(changeRequests[minter].changeRequested); // dev: Not requested
        require(minters[minter] == true); // dev: Minter does not exist
        
        minters[minter] = false;
        changeRequests[minter].changeRequested = false;
        
        emit MinterRemoved(minter);
    }


    /// @dev Mints tokens. Amount is limited to a fraction of the supply per day
    function mint(address to, uint256 amount) external onlyMinter {
        _requireMaxMint(amount);
        
        _timestampLastMint = uint64(block.timestamp);
        _mint(to, amount);

        emit TokenMinted(msg.sender, to, amount);
    }

    /// @dev Burns tokens. Discounts burned amount from daily mint limit
    function burn(address from, uint256 amount) external onlyMinter {
        _meanDailyAmount(-_toInt256(amount));

        _timestampLastMint = uint64(block.timestamp);
        _burn(from, amount);

        emit TokenBurned(msg.sender, from, amount);
    }


    /// @dev Checks that the amount minted is not higher than the max allowed
    /// only when a total supply level has been reached.
    function _requireMaxMint(uint256 amount) internal virtual {
        if (totalSupply() > thresholdLimitMint) {
            int256 maxDailyMintable = _toInt256(_maxMintRatio()*totalSupply()) / 1e3;
            require(_meanDailyAmount(_toInt256(amount)) <= maxDailyMintable); // dev: Max mint rate
        }
    }


    /// @dev Calculates an exponential moving average that tracks the amount 
    /// of tokens minted in the last 24 hours.
    function _meanDailyAmount(int256 amount) internal returns(int256) {
        int256 elapsed = _toInt256(block.timestamp - _timestampLastMint);
        
        if (elapsed > 0) {
            int256 timeWeight = (24 hours * 1e6) / elapsed;
            int256 alpha = 2*1e12 / (1e6+timeWeight);
            int256 w = (alpha*timeWeight)/1e6;
            int256 w2 = 1e6 - alpha;
            _meanMintRatio = (w*amount + w2*_meanMintRatio) / 1e6;
        } else {
            _meanMintRatio += amount;
        }
        
        return _meanMintRatio;
    }

    /// @dev Calculates the max percentage of supply that can be minted depending
    /// on the actual supply. Simulates a logarithmic curve. It is calibrated
    /// for stablecoins supply.
    function _maxMintRatio() internal view returns(uint256 mintRatio) {
        uint256 supply = totalSupply();
                
        if (supply < 1e5*1e18)
            mintRatio = (baseMintRatio * (1000*1e6 - 900*1e6 * supply / (1e5*1e18))) / 1e6;
        
        else if (supply < 1e6*1e18)
            mintRatio = (baseMintRatio * (100*1e6 - 80*1e6 * (supply-1e5*1e18) / (9*1e5*1e18))) / 1e6;
    
        else if (supply < 1e7*1e18)
            mintRatio = (baseMintRatio * (20*1e6 - 10*1e6 * (supply-1e6*1e18) / (9*1e6*1e18))) / 1e6;
        
        else if (supply < 1e8*1e18)
            mintRatio = (baseMintRatio * (10*1e6 - 6*1e6 * (supply-1e7*1e18) / (9*1e7*1e18))) / 1e6;
            
        else if (supply < 1e9*1e18)
            mintRatio = (baseMintRatio * (4*1e6 - 2*1e6 * (supply-1e8*1e18) / (9*1e8*1e18))) / 1e6;
            
        else if (supply < 1e10*1e18)
            mintRatio = (baseMintRatio * (2*1e6 - 1e6 * (supply-1e9*1e18) / (9*1e9*1e18))) / 1e6;
        
        else
            mintRatio = baseMintRatio;
    }

    /// @dev safe casting of integer to avoid overflow
    function _toInt256(uint256 value) internal pure returns(int256) {
        require(value <= uint256(type(int256).max)); // dev: Unsafe casting
        return int256(value);
    }
    
}