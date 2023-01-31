import "../perpStaking/MintableEscrowToken.sol";
import "./LockedTokenRewards.sol";

pragma solidity 0.5.16;

contract LockedStakingFactory {

    address public token;
    address public nftFactory;
    INotifier public notifier;
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    address[] pools;

    constructor(address _token, INotifier _notifier, address _nftFactory) public {
        token = _token;
        nftFactory = _nftFactory;
        notifier = _notifier;
        owner = msg.sender;
    }

    function setOwner(address account) public onlyOwner {
        owner = account;
    }

    function initialize(address lp) public onlyOwner {
        address escrowToken = address(new MintableEscrowToken());
        address stakingPool = address(new LockedTokenRewards(escrowToken, lp));
        pools.push(stakingPool);
        address poolEscrow = address(new LockedPoolEscrow(escrowToken, stakingPool, token, nftFactory));
        IEscrowToken(escrowToken).addMinter(poolEscrow);
        LockedTokenRewards(stakingPool).setEscrow(poolEscrow);
        LockedTokenRewards(stakingPool).setRewardDistribution(poolEscrow);
        LockedTokenRewards(stakingPool).setNotifier(notifier);
        LockedTokenRewards(stakingPool).transferOwnership(owner);
        LockedPoolEscrow(poolEscrow).setGovernance(owner);
    }

    function getPools() public view returns(address[] memory) {
        return pools;
    }

    // function recoverTokens(
    //     address _token,
    //     address benefactor
    // ) public onlyOwner {
    //     uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
    //     IERC20(_token).transfer(benefactor, tokenBalance);
    // }

}

interface IEscrowToken {
        function addMinter(address account) external;
}