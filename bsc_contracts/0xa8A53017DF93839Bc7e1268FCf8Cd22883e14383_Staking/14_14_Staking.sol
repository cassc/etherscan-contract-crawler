/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./ManageableUpgradeable.sol";

interface TokensOfOwnerNFT {
    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory);
}

interface IERC20Mintable is IERC20Upgradeable {
    function circulatingSupply() external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burnFrom(address to, uint256 amount) external;
}

contract Staking is Initializable, OwnableUpgradeable, ManageableUpgradeable {
    struct Init {
        uint256 precision;
        address payable growth;
        address token;
        address xburns;
        address nft;
        address router;
        uint256[] circSupThreshold_;
        uint256[] fixedAPYs_;
        uint256 minDuration_;
        uint256 maxDuration_;
        uint256 stakeFees_;
        uint256 refShare_;
        uint256 unstakeFees_;
        uint256 claimFeeThreshold_;
        uint256 nftBonus;
    }

    struct Stake {
        uint256 id;
        uint256 amount;
        uint256 apy;
        uint256 duration;
        uint256 startTimestamp;
    }
    uint256 public PRECISION;

    address payable public GROWTH;
    IERC20Mintable public TOKEN;
    IERC20Mintable public XBURNS;
    IERC721EnumerableUpgradeable public NFT;
    IUniswapV2Router02 public ROUTER;

    uint256[] public circSupThreshold;
    uint256[] public fixedAPYs;

    uint256 public minDuration;
    uint256 public maxDuration;

    uint256 public stakeFees;
    uint256 public refShare;
    uint256 public unstakeFees;

    uint256 public claimFeeThreshold;
    uint256 public claimFeeCounter;

    uint256 public nftBonus;

    uint256 public nStakes;

    uint256 public totalStaked;

    mapping(address => Stake[]) public stakes;
    mapping(address => bool) public isBlacklisted;
    mapping(address => uint256) public nReferred;
    mapping(address => uint256) public amountFromRef;
    mapping(uint256 => bool) public isXBurnsStake;

    function initialize(Init memory init) public initializer {
        __Ownable_init();
        PRECISION = init.precision;

        GROWTH = init.growth;
        TOKEN = IERC20Mintable(init.token);
        XBURNS = IERC20Mintable(init.xburns);
        NFT = IERC721EnumerableUpgradeable(init.nft);
        ROUTER = IUniswapV2Router02(init.router);

        circSupThreshold = init.circSupThreshold_;
        fixedAPYs = init.fixedAPYs_;

        minDuration = init.minDuration_;
        maxDuration = init.maxDuration_;

        stakeFees = init.stakeFees_;
        refShare = init.refShare_;
        unstakeFees = init.unstakeFees_;

        claimFeeThreshold = init.claimFeeThreshold_;
        claimFeeCounter = 0;

        nftBonus = init.nftBonus;

        nStakes = 0;
        totalStaked = 0;

        emit OwnershipTransferred(address(0), _msgSender());
    }

    function getCurrentAPY() public view returns (uint256 currAPY) {
        uint256 circSupply = TOKEN.totalSupply() -
            TOKEN.balanceOf(address(this));
        for (uint8 i = 0; i < fixedAPYs.length; i++) {
            if (totalStaked <= (circSupply * circSupThreshold[i]) / PRECISION)
                return fixedAPYs[i];
        }
        return 0;
    }

    function stake(
        uint256 amount,
        uint256 duration,
        address ref,
        bool boost
    ) public {
        require(ref != _msgSender(), "STAKE: Can't referrer yourself.");
        require(
            TOKEN.balanceOf(_msgSender()) >= amount,
            "STAKE: Unsufficient balance"
        );
        require(
            TOKEN.allowance(_msgSender(), address(this)) >= amount,
            "STAKE: Unsufficient allowance"
        );
        require(duration <= maxDuration, "STAKE: Invalid duration");
        require(duration >= minDuration, "STAKE: Invalid duration");

        uint256 apy = getCurrentAPY();

        if (boost) {
            NFT.transferFrom(
                _msgSender(),
                address(0x000000000000000000000000000000000000dEaD),
                TokensOfOwnerNFT(address(NFT)).tokensOfOwner(_msgSender())[0]
            );
            apy += nftBonus;
        }

        TOKEN.burnFrom(_msgSender(), amount);

        uint256 fees = (amount * stakeFees) / PRECISION;
        amount -= fees;
        uint256 toRef = (amount * refShare) / PRECISION;

        if (toRef > 0) {
            mintOrSend(ref, toRef);
            amountFromRef[ref] += toRef;
            nReferred[ref]++;
        }

        totalStaked += amount;
        nStakes++;
        stakes[_msgSender()].push(
            Stake(nStakes, amount, apy, duration, block.timestamp)
        );
    }

    function stakeXburns(uint256 amount, uint256 duration, bool boost) public {
        require(
            XBURNS.balanceOf(_msgSender()) >= amount,
            "STAKE: Unsufficient balance"
        );
        require(
            XBURNS.allowance(_msgSender(), address(this)) >= amount,
            "STAKE: Unsufficient allowance"
        );
        require(duration <= maxDuration, "STAKE: Invalid duration");
        require(duration >= minDuration, "STAKE: Invalid duration");

        uint256 apy = getCurrentAPY();

        if (boost) {
            NFT.transferFrom(
                _msgSender(),
                address(0x000000000000000000000000000000000000dEaD),
                TokensOfOwnerNFT(address(NFT)).tokensOfOwner(_msgSender())[0]
            );
            apy += nftBonus;
        }

        XBURNS.burnFrom(_msgSender(), amount);

        uint256 fees = (amount * stakeFees) / PRECISION;
        amount -= fees;

        nStakes++;
        isXBurnsStake[nStakes] = true;
        stakes[_msgSender()].push(
            Stake(nStakes, amount, apy, duration, block.timestamp)
        );
    }

    function stakeEth(
        uint256 duration,
        address ref,
        bool boost
    ) public payable {
        require(ref != _msgSender(), "STAKE: Can't referrer yourself.");
        require(duration <= maxDuration, "STAKE: Invalid duration");
        require(duration >= minDuration, "STAKE: Invalid duration");

        address[] memory path = new address[](2);
        path[0] = ROUTER.WETH();
        path[1] = address(TOKEN);

        uint256 amountOut = ROUTER.getAmountsOut(msg.value, path)[0];

        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, GROWTH, block.timestamp);

        TOKEN.burnFrom(address(this), amountOut);

        uint256 fees = (amountOut * stakeFees) / PRECISION;
        amountOut -= fees;
        uint256 toRef = (amountOut * refShare) / PRECISION;

        mintOrSend(ref, toRef);

        uint256 apy = getCurrentAPY();

        if (boost) {
            NFT.transferFrom(
                _msgSender(),
                address(0x000000000000000000000000000000000000dEaD),
                TokensOfOwnerNFT(address(NFT)).tokensOfOwner(_msgSender())[0]
            );
            apy += nftBonus;
        }

        nStakes++;
        totalStaked += amountOut;

        stakes[_msgSender()].push(
            Stake(nStakes, amountOut, apy, duration, block.timestamp)
        );
    }

    function unstake(uint256 index) public {
        require(index < stakes[_msgSender()].length, "UNSTAKE: Invalid index");
        Stake memory stake_ = stakes[_msgSender()][index];
        require(
            block.timestamp >= stake_.startTimestamp + stake_.duration,
            "UNSTAKE: You must wait the whole duration"
        );

        uint256 timeSinceFinished = block.timestamp -
            (stake_.startTimestamp + stake_.duration);

        uint256 fractionOfYear = (stake_.duration * PRECISION) / 365 / 86400;
        uint256 apyForDuration = stake_.apy * fractionOfYear;

        uint256 amount = stake_.amount +
            (stake_.amount * apyForDuration) /
            PRECISION /
            1000;

        if (stakes[_msgSender()].length > 1) {
            stakes[_msgSender()][index] = stakes[_msgSender()][
                stakes[_msgSender()].length - 1
            ];
        }
        stakes[_msgSender()].pop();

        totalStaked -= stake_.amount;

        uint256 fees = (amount * unstakeFees) / PRECISION;

        if (timeSinceFinished >= 14 * 86400) {
            fees +=
                (((amount * (timeSinceFinished - 14 * 86400) * PRECISION) / 7) *
                    86400) /
                PRECISION /
                100;
        }

        amount -= fees;

        if (amount > 0) mintOrSend(_msgSender(), amount);
        if (fees > 0) processClaimFee(fees);
    }

    function emergencyUnstake(uint256 index) public {
        require(
            index < stakes[_msgSender()].length,
            "EMERGENCY: Invalid index"
        );
        Stake memory stake_ = stakes[_msgSender()][index];
        require(!isXBurnsStake[stake_.id], "EMERGENCY: Can't unstake XBURNS");
        require(
            block.timestamp < stake_.duration + stake_.startTimestamp,
            "EMERGENCY: Can't emergency unstake a completed stake"
        );
        uint256 halfwayPoint = stake_.duration / 2;
        uint256 amount = 0;
        uint256 fees = 0;
        if (block.timestamp >= halfwayPoint + stake_.startTimestamp) {
            uint256 fractionOfYear = ((block.timestamp -
                stake_.startTimestamp *
                PRECISION) / 365) / 86400;
            uint256 apyForDuration = stake_.apy * fractionOfYear;

            amount =
                stake_.amount +
                (stake_.amount * apyForDuration) /
                PRECISION /
                1000;

            fees = (amount * unstakeFees) / PRECISION;
            amount -= fees;
        } else {
            uint256 timeSinceStart = block.timestamp - stake_.startTimestamp;
            uint256 fractionOfHalfway = (timeSinceStart * 100) / halfwayPoint;

            amount = (stake_.amount * fractionOfHalfway) / 100;
        }

        totalStaked -= stake_.amount;

        if (stakes[_msgSender()].length > 1) {
            stakes[_msgSender()][index] = stakes[_msgSender()][
                stakes[_msgSender()].length - 1
            ];
        }
        stakes[_msgSender()].pop();

        if (amount > 0) mintOrSend(_msgSender(), amount);
        if (fees > 0) processClaimFee(fees);
    }

    function processClaimFee(uint256 amount) internal {
        claimFeeCounter += amount;
        if (claimFeeCounter >= claimFeeThreshold) {
            if (TOKEN.balanceOf(address(this)) < claimFeeCounter)
                TOKEN.mint(address(this), claimFeeCounter);
            address[] memory path = new address[](2);
            path[0] = address(TOKEN);
            path[1] = ROUTER.WETH();

            ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
                claimFeeCounter,
                0,
                path,
                GROWTH,
                block.timestamp
            );

            claimFeeCounter = 0;
        }
    }

    function mintOrSend(address user, uint256 amount) internal {
        if (TOKEN.balanceOf(address(this)) > amount)
            TOKEN.transfer(user, amount);
        else TOKEN.mint(user, amount);
    }

    function getRefStats(address user) public view returns (uint256, uint256) {
        return (amountFromRef[user], nReferred[user]);
    }

    function getUserStakes(address user) public view returns (Stake[] memory) {
        return stakes[user];
    }

    function updatePrecision(uint256 value) public onlyOwner {
        PRECISION = value;
    }

    function updateGrowth(address payable value) public onlyOwner {
        GROWTH = value;
    }

    function updateToken(address value) public onlyOwner {
        TOKEN = IERC20Mintable(value);
    }

    function updateNft(address value) public onlyOwner {
        NFT = IERC721EnumerableUpgradeable(value);
    }

    function updateRouter(address value) public onlyOwner {
        ROUTER = IUniswapV2Router02(value);
    }

    function updateApys(
        uint256[] memory circSup,
        uint256[] memory apys
    ) public onlyOwner {
        require(circSup.length == apys.length, "Invalid arrays");
        circSupThreshold = circSup;
        fixedAPYs = apys;
    }

    function updateMinDuration(uint256 value) public onlyOwner {
        minDuration = value;
    }

    function updateMaxDuration(uint256 value) public onlyOwner {
        maxDuration = value;
    }

    function updateStakeFees(uint256 value) public onlyOwner {
        stakeFees = value;
    }

    function updateRefShare(uint256 value) public onlyOwner {
        refShare = value;
    }

    function updateUnstakeFees(uint256 value) public onlyOwner {
        unstakeFees = value;
    }

    function updateClaimFeeThreshold(uint256 value) public onlyOwner {
        claimFeeThreshold = value;
    }

    function updateNftBonus(uint256 value) public onlyOwner {
        nftBonus = value;
    }

    function setIsBlacklisted(address user, bool value) public onlyOwner {
        isBlacklisted[user] = value;
    }

    function updateXburns(address value) public onlyOwner {
        XBURNS = IERC20Mintable(value);
    }

    function executeApprovals() public onlyOwner {
        TOKEN.approve(address(this), type(uint256).max);
        TOKEN.approve(address(ROUTER), type(uint256).max);
    }

    function updateApyForStake(
        address user,
        uint256 index,
        uint256 apy
    ) public onlyOwner {
        stakes[user][index].apy = apy;
    }

    receive() external payable {}

    fallback() external payable {}
}