// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ILGOStakingView} from "../interfaces/ILGOStakingView.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

contract LGOStakingView is Ownable, ILGOStakingView {
    struct EmissionInfo {
        uint256 rewardsPerSecond;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    uint256 public constant LGO_MAX_SUPPLY = 1000 ether;

    EmissionInfo[] public emissions;
    IERC20 public LGO;
    uint256 public totalAuctionLgo;
    address public admin;

    constructor(address _lgo) {
        require(_lgo != address(0), "LGOStakingView::initialize: invalid address");
        LGO = IERC20(_lgo);
        emissions.push(EmissionInfo({rewardsPerSecond: 7928240740741, startTimestamp: 1672063200, endTimestamp: 0}));
    }

    function estimatedLGOCirculatingSupply() external view override returns (uint256) {
        uint256 _balance = totalAuctionLgo;
        for (uint256 i = 0; i < emissions.length;) {
            EmissionInfo memory emission = emissions[i];
            uint256 _now = block.timestamp;
            uint256 _endTime = emission.endTimestamp;
            if (_endTime == 0 || _endTime > _now) {
                _endTime = _now;
            }

            uint256 _startTime = emission.startTimestamp;
            if (_startTime > _now) {
                _startTime = _now;
            }

            uint256 _duration = _endTime > _startTime ? (_endTime - _startTime) : 0;
            _balance = _balance + (emission.rewardsPerSecond * _duration);
            unchecked {
                ++i;
            }
        }
        uint256 _lgoBurnedAmount = getBurnedLGOAmount();
        _balance = _balance > _lgoBurnedAmount ? (_balance - _lgoBurnedAmount) : 0;
        return (_balance > LGO_MAX_SUPPLY ? LGO_MAX_SUPPLY : _balance);
    }

    function getBurnedLGOAmount() public view returns (uint256) {
        uint256 _lgoTotalSupply = LGO.totalSupply();
        return LGO_MAX_SUPPLY > _lgoTotalSupply ? LGO_MAX_SUPPLY - _lgoTotalSupply : 0;
    }

    function addAuctionedAmount(uint256 _amount) external {
        require(msg.sender == admin || msg.sender == owner(), "Only admin or owner");
        totalAuctionLgo += _amount;
    }

    function addEmission(uint256 _rewardsPerSecond, uint256 _startTimestamp, uint256 _endTimestamp) external {
        require(msg.sender == admin || msg.sender == owner(), "Only admin or owner");
        require(_startTimestamp > 0, "< _startTimestamp");
        require(_endTimestamp > _startTimestamp, "_endTimestamp < _startTimestamp");
        emissions.push(
            EmissionInfo({
                rewardsPerSecond: _rewardsPerSecond,
                startTimestamp: _startTimestamp,
                endTimestamp: _endTimestamp
            })
        );
    }

    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Invalid address");
        admin = _admin;
    }
}