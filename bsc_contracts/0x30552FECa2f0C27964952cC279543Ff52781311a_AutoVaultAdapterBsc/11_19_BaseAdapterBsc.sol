// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseAdapterBsc is Ownable {
    struct UserAdapterInfo {
        uint256 amount; // Current staking token amount
        uint256 invested; // Current staked ether amount
        uint256 userShares; // First reward token share
        uint256 userShares1; // Second reward token share
        uint256 rewardDebt; // Reward Debt for reward token1
        uint256 rewardDebt1; // Reward Debt for reward token2
    }

    struct AdapterInfo {
        uint256 accTokenPerShare; // Accumulated per share for first reward token
        uint256 accTokenPerShare1; // Accumulated per share for second reward token
        uint256 totalStaked; // Total staked staking token
    }

    uint256 public pid;

    address public stakingToken;

    address public rewardToken;

    address public rewardToken1;

    address public repayToken;

    address public strategy;

    address public router;

    address public swapRouter;

    address public investor;

    address public wbnb;

    string public name;

    AdapterInfo public mAdapter;

    // inToken => outToken => paths
    mapping(address => mapping(address => address[])) public paths;

    // user => nft id => UserAdapterInfo
    mapping(address => mapping(uint256 => UserAdapterInfo))
        public userAdapterInfos;

    // nft id => AdapterInfo
    mapping(uint256 => AdapterInfo) public adapterInfos;

    modifier onlyInvestor() {
        require(msg.sender == investor, "Not investor");
        _;
    }

    event InvestorUpdated(address investor);

    /**
     * @notice Get path
     * @param _inToken token address of inToken
     * @param _outToken token address of outToken
     */
    function getPaths(address _inToken, address _outToken)
        public
        view
        returns (address[] memory)
    {
        require(
            paths[_inToken][_outToken].length > 1,
            "Path length is not valid"
        );
        require(
            paths[_inToken][_outToken][0] == _inToken,
            "Path is not existed"
        );
        require(
            paths[_inToken][_outToken][paths[_inToken][_outToken].length - 1] ==
                _outToken,
            "Path is not existed"
        );

        return paths[_inToken][_outToken];
    }

    /**
     * @notice Set paths from inToken to outToken
     * @param _inToken token address of inToken
     * @param _outToken token address of outToken
     * @param _paths swapping paths
     */
    function setPath(
        address _inToken,
        address _outToken,
        address[] memory _paths
    ) external onlyOwner {
        require(_paths.length > 1, "Invalid paths length");
        require(_inToken == _paths[0], "Invalid inToken address");
        require(
            _outToken == _paths[_paths.length - 1],
            "Invalid inToken address"
        );

        uint8 i;
        for (i; i < _paths.length; i++) {
            if (i < paths[_inToken][_outToken].length) {
                paths[_inToken][_outToken][i] = _paths[i];
            } else {
                paths[_inToken][_outToken].push(_paths[i]);
            }
        }

        if (paths[_inToken][_outToken].length > _paths.length)
            for (
                i = 0;
                i < paths[_inToken][_outToken].length - _paths.length;
                i++
            ) paths[_inToken][_outToken].pop();
    }

    /**
     * @notice Set investor
     * @param _investor  address of investor
     */
    function setInvestor(address _investor) external onlyOwner {
        require(_investor != address(0), "Error: Investor zero address");
        investor = _investor;
        emit InvestorUpdated(investor);
    }

    /**
     * @notice deposit to strategy
     * @param _tokenId YBNFT token id
     * @param _account address of user
     */
    function deposit(uint256 _tokenId, address _account)
        external
        payable
        virtual
        returns (uint256 amountOut)
    {}

    /**
     * @notice withdraw from strategy
     * @param _tokenId YBNFT token id
     * @param _account address of user
     */
    function withdraw(uint256 _tokenId, address _account)
        external
        payable
        virtual
        returns (uint256 amountOut)
    {}

    /**
     * @notice claim reward from strategy
     * @param _tokenId YBNFT token id
     * @param _account address of user
     */
    function claim(uint256 _tokenId, address _account)
        external
        payable
        virtual
        returns (uint256 amountOut)
    {}

    /**
     * @notice Get pending token reward
     * @param _tokenId YBNFT token id
     * @param _account address of user
     */
    function pendingReward(uint256 _tokenId, address _account)
        external
        view
        virtual
        returns (uint256 reward)
    {}
}