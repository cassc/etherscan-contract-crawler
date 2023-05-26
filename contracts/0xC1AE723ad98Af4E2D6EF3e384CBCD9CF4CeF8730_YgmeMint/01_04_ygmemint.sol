pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC20USDT {
    function transferFrom(address from, address to, uint value) external;

    function transfer(address to, uint value) external;
}

interface IYGME {
    function swap(address to, address _recommender, uint mintNum) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function PAY() external view returns (uint256 pay);

    function maxLevel() external view returns (uint256 level);

    function recommender(
        address _account
    ) external view returns (address _recommender);

    function rewardLevelAmount(
        uint256 _level
    ) external view returns (uint256 amount);
}

interface IYgmeStake {
    function getStakingTokenIds(
        address _account
    ) external view returns (uint256[] memory);
}

contract YgmeMint is Ownable, ReentrancyGuard {

    address constant ZERO_ADDRESS = address(0);

    IERC20USDT public immutable usdt;

    IYGME public immutable ygme;

    IYgmeStake public immutable ygmestake;

    IERC20 public immutable ygio;

    bool public rewardSwitch;

    bool public mintSwitch;

    constructor(
        address _usdt,
        address _ygme,
        address _ygmestake,
        address _ygio
    ) {
        usdt = IERC20USDT(_usdt);
        ygme = IYGME(_ygme);
        ygmestake = IYgmeStake(_ygmestake);
        ygio = IERC20(_ygio);
    }

    function setRewardSwitch() external onlyOwner {
        rewardSwitch = !rewardSwitch;
    }

    function setMintSwitch() external onlyOwner {
        mintSwitch = !mintSwitch;
    }

    function safeMint(
        address _recommender,
        uint256 mintNum
    ) external nonReentrant {
        address account = _msgSender();

        address superAddress = ygme.recommender(account);

        if(superAddress != ZERO_ADDRESS){
            _recommender = superAddress;
        }else{
            require(_recommender != ZERO_ADDRESS, "recommender can not be zero");
        }

        require(_recommender != account, "recommender can not be self");

        require(
            ygme.balanceOf(_recommender) > 0 ||
                ygmestake.getStakingTokenIds(_recommender).length > 0,
            "invalid recommender"
        );

        uint256 unitPrice = ygme.PAY();

        usdt.transferFrom(account, address(ygme), mintNum * unitPrice);

        ygme.swap(account, _recommender, mintNum);

        if (rewardSwitch) {
            _rewardMint(account, mintNum);
        }
    }

    function safeMintTwo(
        address _recommender,
        uint256 mintNum
    ) external nonReentrant {
        require(mintSwitch, "method invalide");
       
        address account = _msgSender();

        require(_recommender != account, "recommender can not be self");

        uint256 unitPrice = ygme.PAY();

        usdt.transferFrom(account, address(ygme), mintNum * unitPrice);

        ygme.swap(account, _recommender, mintNum);

        if (rewardSwitch) {
            _rewardMint(account, mintNum);
        }
    }

    function _rewardMint(address to, uint mintNum) private {
        address rewward;
        for (uint i = 0; i <= ygme.maxLevel(); i++) {
            if (0 == i) {
                rewward = to;
            } else {
                rewward = ygme.recommender(rewward);
            }

            if (rewward != ZERO_ADDRESS && 0 != ygme.rewardLevelAmount(i)) {
                ygio.transfer(rewward, ygme.rewardLevelAmount(i) * mintNum);
            }
        }
    }
}