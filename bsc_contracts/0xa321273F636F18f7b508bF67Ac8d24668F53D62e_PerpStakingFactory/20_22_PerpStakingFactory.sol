import "./MintableEscrowToken.sol";
import "./PerpetualTokenRewards.sol";

pragma solidity 0.5.16;

contract PerpStakingFactory {

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

    function initialize (address lp) public onlyOwner {
        address escrowToken = address(new MintableEscrowToken());
        address stakingPool = address(new PerpetualTokenRewards(escrowToken, lp));
        pools.push(stakingPool);
        address poolEscrow = address(new PerpetualPoolEscrow(escrowToken, stakingPool, token, nftFactory));
        IEscrowToken(escrowToken).addMinter(poolEscrow);
        PerpetualTokenRewards(stakingPool).setEscrow(poolEscrow);
        PerpetualTokenRewards(stakingPool).setRewardDistribution(poolEscrow);
        PerpetualTokenRewards(stakingPool).setNotifier(notifier);
        PerpetualTokenRewards(stakingPool).transferOwnership(owner);
        PerpetualPoolEscrow(poolEscrow).setGovernance(owner);
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