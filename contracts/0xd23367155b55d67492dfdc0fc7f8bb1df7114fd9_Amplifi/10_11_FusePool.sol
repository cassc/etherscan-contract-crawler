// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswap.sol";
import "./interfaces/INetwork.sol";
import "./Types.sol";

contract FusePool is INetwork, Ownable {
    address immutable token;
    uint256 immutable duration;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;
    mapping(address => uint256) public totalRewardsToUser;
    mapping(address => Types.Share) public shares;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    modifier onlyToken() {
        require(msg.sender == token);
        _;
    }

    constructor(address _owner, uint256 _duration) {
        _transferOwnership(_owner);

        token = msg.sender;
        duration = _duration;
    }

    function increaseShare(address _shareholder, uint256 _unlocks) external override onlyToken {
        if (shares[_shareholder].amount == 0) {
            addShareholder(_shareholder);
        }

        totalShares++;
        shares[_shareholder].amount++;
        shares[_shareholder].unlocks = _unlocks;
        shares[_shareholder].started = block.timestamp;
        shares[_shareholder].totalExcluded = getCumulativeDividends(
            shares[_shareholder].amount,
            shares[_shareholder].started,
            shares[_shareholder].unlocks
        );
        assert(shares[_shareholder].totalExcluded == 0);
    }

    function decreaseShare(address _shareholder) external override onlyToken {
        if (shares[_shareholder].amount == 1) {
            removeShareholder(_shareholder);
        }

        totalShares--;
        shares[_shareholder].totalExcluded = getCumulativeDividends(
            shares[_shareholder].amount,
            shares[_shareholder].started,
            shares[_shareholder].started
        );
        shares[_shareholder].amount--;
        shares[_shareholder].started = 0;
        shares[_shareholder].unlocks = 0;
    }

    function deposit() external payable override onlyOwner {
        uint256 amount = msg.value;
        totalDividends += amount;
        dividendsPerShare += (dividendsPerShareAccuracyFactor * amount) / totalShares;
    }

    function distributeDividend(address _shareholder) external onlyToken {
        uint256 amount = getPendingDividend(_shareholder);

        if (amount > 0) {
            shares[_shareholder].totalExcluded = getCumulativeDividends(
                shares[_shareholder].amount,
                shares[_shareholder].started,
                shares[_shareholder].unlocks
            );
            shares[_shareholder].totalRealised += amount;
            totalDistributed += amount;

            (bool success, ) = _shareholder.call{value: amount}("");
            require(success, "Could not send ETH");

            totalRewardsToUser[_shareholder] = totalRewardsToUser[_shareholder] + amount;
        }
    }

    function getPendingDividend(address _shareholder) public view returns (uint256) {
        if (shares[_shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[_shareholder].amount,
            shares[_shareholder].started,
            shares[_shareholder].unlocks
        );
        uint256 shareholderTotalExcluded = shares[_shareholder].totalExcluded;
        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(
        uint256 share,
        uint256 started,
        uint256 unlocks
    ) internal view returns (uint256) {
        if (unlocks > block.timestamp) {
            unlocks = block.timestamp;
        }

        uint256 total = (share * dividendsPerShare) / dividendsPerShareAccuracyFactor;

        uint256 end = started + duration;
        uint256 endAbs = end - started;
        uint256 nowAbs = unlocks - started;

        return (total * nowAbs) / endAbs;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function withdrawETH(address _recipient) external onlyOwner {
        (bool success, ) = _recipient.call{value: address(this).balance}("");
        require(success, "Could not send ETH");
    }

    function withdrawToken(IERC20 _token, address _recipient) external onlyOwner {
        _token.transfer(_recipient, _token.balanceOf(address(this)));
    }
}