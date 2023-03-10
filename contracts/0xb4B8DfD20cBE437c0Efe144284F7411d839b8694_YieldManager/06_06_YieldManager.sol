// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniV2Pair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function totalSupply() external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface ILockedStakingrewards {
    function balanceOf(address account) external view returns (uint256);
    function stakingToken() external view returns(address);
}

contract YieldManager is ReentrancyGuard {
    using SafeERC20 for IERC20;
    mapping(address => address) public affiliateLookup;

    event AffiliateSet(address indexed sponsor, address indexed client);
    event NewOwner(address owner);
    event NewCanSetSponsor(address canSet, bool status);
    event NewStaking(address staking);
    event NewLPStaking(address lpStaking);
    event NewYFlow(address yflow);
    event NewLPFactor(uint lpFactor);

    // struct configStruct
    // val1 client:  withdrawal fee sponsor: % of fee
    struct configStruct {
        uint level;
        uint val1;
        uint val2;
        uint val3;
        uint val4;
    }

    configStruct[] public clientLevels;
    configStruct[] public sponsorLevels;

    address[] public stakingAddresses;
    address[] public lpStakingAddresses;

    address public owner;
    mapping(address => bool) public canSetSponsor;

    address public YFlowAddress;
    uint public lpFactor = 1;

    // only owner modifier
    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    // only owner view
    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    constructor(address _YFlow) {
        owner = msg.sender;
        YFlowAddress = _YFlow;
        //set client levels initial
        clientLevels.push(
            configStruct({
                level: 0,
                val1: 0,
                // performance fee
                val2: 1500,
                // mgmt fee
                val3: 100,
                // mgmt fee fixed
                val4: 200
            })
        );
        clientLevels.push(
            configStruct({
                level: 500 * 10 ** 18,
                val1: 0,
                val2: 1250,
                val3: 100,
                val4: 200
            })
        );
        clientLevels.push(
            configStruct({
                level: 10000 * 10 ** 18,
                val1: 0,
                val2: 1000,
                val3: 100,
                val4: 200
            })
        );
        clientLevels.push(
            configStruct({
                level: 100000 * 10 ** 18,
                val1: 0,
                val2: 750,
                val3: 75,
                val4: 125
            })
        );
        clientLevels.push(
            configStruct({
                level: 1000000 * 10 ** 18,
                val1: 0,
                val2: 500,
                val3: 75,
                val4: 125
            })
        );

        //set sponsor levels initial
        sponsorLevels.push(
            configStruct({
                level: 0,
                val1: 0,
                val2: 0,
                val3: 0,
                val4: 0
            })
        );
        sponsorLevels.push(
            configStruct({
                level: 500 * 10 ** 18,
                val1: 1000,
                val2: 1500,
                val3: 0,
                val4: 0
            })
        );
        sponsorLevels.push(
            configStruct({
                level: 10000 * 10 ** 18,
                val1: 1500,
                val2: 2500,
                val3: 0,
                val4: 0
            })
        );
        sponsorLevels.push(
            configStruct({
                level: 100000 * 10 ** 18,
                val1: 2000,
                val2: 5000,
                val3: 0,
                val4: 0
            })
        );
        sponsorLevels.push(
            configStruct({
                level: 500000 * 10 ** 18,
                val1: 2500,
                val2: 7500,
                val3: 0,
                val4: 0
            })
        );
    }

    function setYflow(address _Yflow) public onlyOwner {
        YFlowAddress = _Yflow;
        emit NewYFlow(YFlowAddress);
    }

    function setLPFactor(uint _lpFactor) public onlyOwner {
        lpFactor = _lpFactor;
        emit NewLPFactor(lpFactor);
    }

    //updates client levels
    function setClientLevels(uint[] memory levels, uint[] memory val1s, uint[] memory val2s, uint[] memory val3s, uint[] memory val4s) public onlyOwner {
        require(levels.length == val1s.length, "length mismatch");
        require(val1s.length == val2s.length, "length mismatch");
        require(val2s.length == val3s.length, "length mismatch");
        require(val3s.length == val4s.length, "length mismatch");
        delete clientLevels;

        for (uint i=0; i<levels.length; i++) {
            clientLevels.push(
                configStruct({
                    level: levels[i],
                    val1: val1s[i],
                    val2: val2s[i],
                    val3: val3s[i],
                    val4: val4s[i]
            })
            );
        }
    }

    //updates client levels
    function setSponsorLevels(uint[] memory levels, uint[] memory val1s, uint[] memory val2s, uint[] memory val3s, uint[] memory val4s) public onlyOwner {
        require(levels.length == val1s.length, "length mismatch");
        require(val1s.length == val2s.length, "length mismatch");
        require(val2s.length == val3s.length, "length mismatch");
        require(val3s.length == val4s.length, "length mismatch");
        delete sponsorLevels;

        for (uint i=0; i<levels.length; i++) {
            sponsorLevels.push(
                configStruct({
                    level: levels[i],
                    val1: val1s[i],
                    val2: val2s[i],
                    val3: val3s[i],
                    val4: val4s[i]
            })
            );
        }
    }

    // returns sponsor
    function getAffiliate(address client) public view returns (address) {
        return affiliateLookup[client];
    }

    function setAffiliate(address client, address sponsor) public {
        require (canSetSponsor[msg.sender] == true, "not allowed to set sponsor");
        require(affiliateLookup[client] == address(0), "sponsor already set");
        affiliateLookup[client] = sponsor;
        emit AffiliateSet(sponsor, client);
    }

    function ownerSetAffiiliate(address client, address sponsor) public onlyOwner {
        affiliateLookup[client] = sponsor;
        emit AffiliateSet(sponsor, client);
    }

    function setStakingAddress(address[] memory stakingContract) public onlyOwner {
        delete stakingAddresses;

        for (uint i=0; i<stakingContract.length; i++) {
            stakingAddresses.push(stakingContract[i]);
            emit NewStaking(stakingContract[i]);
        }
    }

    function setLPStakingAddress(address[] memory stakingContract) public onlyOwner {
        delete lpStakingAddresses;
        for (uint i=0; i<stakingContract.length; i++) {
            lpStakingAddresses.push(stakingContract[i]);
            emit NewLPStaking(stakingContract[i]);
        }
    }

    function calcLPTokenBonus(uint liquidity, address lpAddress) public view returns (uint) {
        address _token0 = IUniV2Pair(lpAddress).token0();                                // gas savings
        address _token1 = IUniV2Pair(lpAddress).token1();                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(lpAddress);
        uint balance1 = IERC20(_token1).balanceOf(lpAddress);

        uint _totalSupply = IUniV2Pair(lpAddress).totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        uint amount0 = (liquidity * balance0) / _totalSupply; // using balances ensures pro-rata distribution
        uint amount1 = (liquidity * balance1) / _totalSupply; // using balances ensures pro-rata distribution

        if ( _token0 == YFlowAddress) {
            return amount0 * lpFactor;
        }

        return amount1 * lpFactor;
    }

    function getUserStakedAmount(address user) public view returns (uint) {
        uint stakedTokens;

        // check normal staking
        for (uint i = 0; i < stakingAddresses.length; i++) {
            uint tempStaked = ILockedStakingrewards(stakingAddresses[i])
                .balanceOf(user);
            stakedTokens += tempStaked;
        }

        // check lp staking
        for (uint i = 0; i < lpStakingAddresses.length; i++) {
            uint tempStaked = ILockedStakingrewards(lpStakingAddresses[i])
                .balanceOf(user);

            address lpAddress = ILockedStakingrewards(lpStakingAddresses[i]).stakingToken();
            uint userCalc = calcLPTokenBonus(tempStaked,lpAddress);
            stakedTokens += userCalc;
        }

        return stakedTokens;
    }

    function getUserFactors(
        address user,
        uint typer
    ) public view returns (uint, uint, uint, uint) {
        uint stakedtokens = getUserStakedAmount(user);

        // if its for client
        if (typer == 0) {
            // check normal staking
            if (stakedtokens < clientLevels[1].level) {
                return (
                    clientLevels[0].val1,
                    clientLevels[0].val2,
                    clientLevels[0].val3,
                    clientLevels[0].val4
                );
            } else if (
                stakedtokens >= clientLevels[1].level &&
                stakedtokens < clientLevels[2].level
            ) {
                return (
                    clientLevels[1].val1,
                    clientLevels[1].val2,
                    clientLevels[1].val3,
                    clientLevels[1].val4
                );
            } else if (
                stakedtokens >= clientLevels[2].level &&
                stakedtokens < clientLevels[3].level
            ) {
                return (
                    clientLevels[2].val1,
                    clientLevels[2].val2,
                    clientLevels[2].val3,
                    clientLevels[2].val4
                );
            } else if (
                stakedtokens >= clientLevels[3].level &&
                stakedtokens < clientLevels[4].level
            ) {
                return (
                    clientLevels[3].val1,
                    clientLevels[3].val2,
                    clientLevels[3].val3,
                    clientLevels[3].val4
                );
            } else {
                return (
                    clientLevels[4].val1,
                    clientLevels[4].val2,
                    clientLevels[4].val3,
                    clientLevels[4].val4
                );
            }
        }

        // else we calculate sponsor
        if (stakedtokens < sponsorLevels[1].level) {
            return (
                sponsorLevels[0].val1,
                sponsorLevels[0].val2,
                sponsorLevels[0].val3,
                sponsorLevels[0].val4
            );
        } else if (
            stakedtokens >= sponsorLevels[1].level &&
            stakedtokens < sponsorLevels[2].level
        ) {
            return (
                sponsorLevels[1].val1,
                sponsorLevels[1].val2,
                sponsorLevels[1].val3,
                sponsorLevels[1].val4
            );
        } else if (
            stakedtokens >= sponsorLevels[2].level &&
            stakedtokens < sponsorLevels[3].level
        ) {
            return (
                sponsorLevels[2].val1,
                sponsorLevels[2].val2,
                sponsorLevels[2].val3,
                sponsorLevels[2].val4
            );
        } else if (
            stakedtokens >= sponsorLevels[3].level &&
            stakedtokens < sponsorLevels[4].level
        ) {
            return (
                sponsorLevels[3].val1,
                sponsorLevels[3].val2,
                sponsorLevels[3].val3,
                sponsorLevels[3].val4
            );
        } else {
            return (
                sponsorLevels[4].val1,
                sponsorLevels[4].val2,
                sponsorLevels[4].val3,
                sponsorLevels[4].val4
            );
        }
    }

    function newOwner(address newOwner_) external {
        require(msg.sender == owner, "Only factory owner");
        require(newOwner_ != address(0), "No zero address for newOwner");

        owner = newOwner_;
        emit NewOwner(owner);
    }

    function setCanSetSponsor(address factoryContract, bool val) external onlyOwner {
        canSetSponsor[factoryContract] = val;
        emit NewCanSetSponsor(factoryContract, val);
    }
}