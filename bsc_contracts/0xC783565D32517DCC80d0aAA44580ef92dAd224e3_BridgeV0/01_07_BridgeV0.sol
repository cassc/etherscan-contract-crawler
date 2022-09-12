// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "Pausable.sol";
import "IERC20ElasticSupply.sol";
import "IGeminonOracle.sol";


/**
* @title BridgeV0
* @author Geminon Protocol
* @notice Private bridge for interchain arbitrage.
* This bridge can only be used by one address (the arbitrageur).
* It has a limit of 10.000$ per day of mintable GEX value. This
* value can't be modified: the bridge is designed to deprecate itself as
* the protocol grows and other ways of arbitrage are available.
*/
contract BridgeV0 is Ownable, Pausable {

    IERC20ElasticSupply private immutable GEX;
    IGeminonOracle private immutable oracle;

    address public arbitrageur;
    address public validator;

    uint256 public immutable valueLimit;
    int256 public balanceVirtualGEX;
    
    uint64 private _timestampLastMint;
    int256 private _meanMintRatio;

    mapping(address => uint256) public claims;


    modifier onlyArbitrageur {
        require(msg.sender == arbitrageur);
        _;
    }

    modifier onlyValidator {
        require(msg.sender == validator);
        _;
    }



    constructor(address gexToken, address arbitrageur_, address validator_, address oracle_) {
        GEX = IERC20ElasticSupply(gexToken);
        arbitrageur = arbitrageur_;
        validator = validator_;
        oracle = IGeminonOracle(oracle_);

        _timestampLastMint = uint64(block.timestamp);

        valueLimit = 10000 * 1e18;
    }


    /// @dev Owner can set the arbitrageur address
    function setArbitrageur(address arbitrageur_) external onlyOwner {
        claims[arbitrageur] = 0;
        arbitrageur = arbitrageur_;
    }

    /// @dev Owner can set the validator address
    function setValidator(address validator_) external onlyOwner {
        validator = validator_;
    }


    /// @dev Arbitrageur sends GEX through the bridge
    function sendGEX(uint256 amount) external onlyArbitrageur {
        _meanDailyAmount(-_toInt256(amount));

        balanceVirtualGEX += int256(amount);
        GEX.burn(msg.sender, amount);
    }

    /// @dev Arbitrageur claims GEX sent from other chain
    function claimGEX(uint256 amount) external onlyArbitrageur {
        require(claims[msg.sender] >= amount); // dev: Invalid claim
        _requireMaxMint(amount);

        balanceVirtualGEX -= int256(amount);
        claims[msg.sender] -= amount;
        GEX.mint(msg.sender, amount);
    }


    /// @dev Validator validates the bridge transaction
    function validateClaim(address claimer, uint256 amount) external onlyValidator {
        require(claimer == arbitrageur); // dev: claimer is not the arbitrageur
        claims[claimer] += amount;
    }

    /// @dev Calculates max amount that can be minted by the bridge to not pass the daily limit
    function getMaxMintable() external view onlyArbitrageur returns(uint256) {
        int256 maxAmount = _toInt256((valueLimit*1e18) / oracle.getSafePrice());
        (int256 w, int256 w2) = _weightsMean();

        int256 amount = (1e6*maxAmount - w2*_meanMintRatio)/w;
        amount = amount > maxAmount ? maxAmount : amount;
        return amount > 0 ? uint256(amount) : 0;
    }


    /// @dev Checks that the amount minted is not higher than the max allowed
    function _requireMaxMint(uint256 amount) private {
        uint256 price = oracle.getSafePrice();
        require((price * amount)/1e18 <= valueLimit);

        int256 meanValue = (_toInt256(price) * _meanDailyAmount(_toInt256(amount))) / 1e18;
        require(meanValue <= _toInt256(valueLimit)); // dev: Max mint rate
    }


    /// @dev Calculates an exponential moving average that tracks the amount 
    /// of tokens minted in the last 24 hours.
    function _meanDailyAmount(int256 amount) private returns(int256) {
        (int256 w, int256 w2) = _weightsMean();
        _meanMintRatio = (w*amount + w2*_meanMintRatio) / 1e6;
        return _meanMintRatio;
    }

    /// @dev Calculates the weights of the mean of the mint ratio
    function _weightsMean() private view returns(int256 w, int256 w2) {
        int256 elapsed = _toInt256(block.timestamp - _timestampLastMint);
        
        if (elapsed > 0) {
            int256 timeWeight = (24 hours * 1e6) / elapsed;
            int256 alpha = 2*1e12 / (1e6+timeWeight);
            w = (alpha*timeWeight)/1e6;
            w2 = 1e6 - alpha;
        } else {
            w = 1e6;
            w2 = 1e6;
        }
    }

    /// @dev safe casting of integer to avoid overflow
    function _toInt256(uint256 value) private pure returns(int256) {
        require(value <= uint256(type(int256).max)); // dev: Unsafe casting
        return int256(value);
    } 
}