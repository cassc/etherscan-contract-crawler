//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./ERC721Farm.sol";
import "./IFarmDeployer.sol";

contract FarmDeployer721 is IFarmDeployer721 {

    modifier onlyFarmDeployer() {
        require(farmDeployer == msg.sender, "Only Farm Deployer");
        _;
    }

    address public immutable farmDeployer;

    /*
     * @notice Initialize the contract
     * @param _farmDeployer: Farm deployer address
     */
    constructor(
        address _farmDeployer
    ) {
        require(_farmDeployer != address(0));
        farmDeployer = _farmDeployer;
    }


    /*
     * @notice Deploys ERC721Farm contract. Requires amount of BNB to be paid
     * @param _stakeToken: Stake token address
     * @param _rewardToken: Reward token address
     * @param _startBlock: Start block
     * @param _rewardPerBlock: Reward per block (in rewardToken)
     * @param _userStakeLimit: Maximum amount of tokens a user is allowed to stake (if any, else 0)
     * @param _minimumLockTime: Minimum number of blocks user should wait after deposit to withdraw without fee
     * @param owner: Owner of the contract
     * @return farmAddress: Address of deployed pool contract
     */
    function deploy(
        address _stakeToken,
        address _rewardToken,
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _userStakeLimit,
        uint256 _minimumLockTime,
        address owner
    ) external onlyFarmDeployer returns(address farmAddress){

        farmAddress = address(new ERC721Farm());
        IERC721Farm(farmAddress).initialize(
            _stakeToken,
            _rewardToken,
            _startBlock,
            _rewardPerBlock,
            _userStakeLimit,
            _minimumLockTime,
            owner
        );
    }
}