// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INFT.sol";
import "./interfaces/ITHE.sol";

contract TheStaking is Ownable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint16 boostPointsBP;
        uint112 amount;
        uint256 startedAt;
        address[] NFTContracts;
        uint256[] NFTTokenIDs;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
    }

    struct UsersNFTs {
        address NFTContract;
        uint256 TokenId;
    }

    //One day in seconds
    uint256 public ONE_DAY = 86400;

    //vitaliks address
    address vb = address(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B);

    uint256 public pointsPerDay = 41;
    // The token
    IThe public The;
    // The boost nft contracts
    mapping(address => bool) public isNFTContract;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    bool public started;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event NFTStaked(
        address indexed user,
        address indexed NFTContract,
        uint256 tokenID
    );
    event NFTWithdrawn(
        address indexed user,
        address indexed NFTContract,
        uint256 tokenID
    );
    event Emergency(uint256 timestamp, bool ifEmergency);
    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    mapping(address => bool) public authorized;
    modifier onlyAuthorized() {
        require(
            authorized[msg.sender] == true,
            "onlyAuthorized: address not authorized"
        );
        _;
    }

    constructor(IThe _the) {
        The = _the;
        started = false;
    }

    // Return number of pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return (_to - _from);
    }

    function snapshotORGVotingPower(address _user)
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[0][_user];

        uint256 weightedVotingPower = getVotingPower(0, _user);
        uint256 theBalance = The.balanceOf(_user);

        uint256 total = weightedVotingPower + theBalance;

        if (_user != vb) {
            if (user.boostPointsBP == 0) {
                //no nft
                return total > 5000000 * 1e18 ? 5000000 * 1e18 : total;
            } else if (user.boostPointsBP == 41) {
                //bronze
                return total > 10000000 * 1e18 ? 10000000 * 1e18 : total;
            } else if (user.boostPointsBP == 82) {
                //silver
                return total > 20000000 * 1e18 ? 20000000 * 1e18 : total;
            } else if (user.boostPointsBP == 123) {
                //gold
                return total > 30000000 * 1e18 ? 30000000 * 1e18 : total;
            } else if (user.boostPointsBP == 206) {
                //diamond
                return total > 50000000 * 1e18 ? 50000000 * 1e18 : total;
            }
        } else {
            //if user is vitalik
            return total > 200000000 * 1e18 ? 200000000 * 1e18 : total;
        }

        return 0;
    }

    function getVotingPower(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][_user];

        uint256 userWeightedAmount = 0;
        uint256 multiplier = getMultiplier(user.startedAt, block.timestamp);
        uint256 totalMultiplier = 10000 +
            (multiplier * (pointsPerDay + user.boostPointsBP)) /
            ONE_DAY;

        userWeightedAmount = (user.amount * totalMultiplier) / 10000;

        return userWeightedAmount;
    }

    function getUsersNFTs(uint256 _pid, address _user)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        UserInfo storage user = userInfo[_pid][_user];
        uint256 nftCount = user.NFTContracts.length;

        address[] memory _nftContracts = new address[](nftCount);
        uint256[] memory _nftTokenIds = new uint256[](nftCount);

        for (uint256 i = 0; i < nftCount; i++) {
            _nftContracts[i] = user.NFTContracts[i];
            _nftTokenIds[i] = user.NFTTokenIDs[i];
        }

        return (_nftContracts, _nftTokenIds);
    }

    // Deposit tokens for rewards.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        _deposit(msg.sender, _pid, _amount);
    }

    // Withdraw unlocked tokens.
    function withdraw(uint32 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount && _amount > 0, "withdraw: not good");

        if (_amount == user.amount) {
            require(user.boostPointsBP == 0, "Withdraw NFTs first");
        }

        user.amount = uint112(user.amount - _amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw previously staked NFT, loosing the rewards boost
    function withdrawNFT(
        uint256 _pid,
        address NFTContract,
        uint256 tokenID
    ) public nonReentrant {
        address sender = msg.sender;
        uint256 NFTIndex;
        bool tokenFound;
        uint256 length = userInfo[_pid][sender].NFTContracts.length;

        for (uint256 i; i < userInfo[_pid][sender].NFTContracts.length; i++) {
            if (userInfo[_pid][sender].NFTContracts[i] == NFTContract) {
                if (userInfo[_pid][sender].NFTTokenIDs[i] == tokenID) {
                    tokenFound = true;
                    NFTIndex = i;
                    break;
                }
            }
        }
        require(tokenFound == true, "withdrawNFT, token not found");
        userInfo[_pid][sender].boostPointsBP -= uint16(
            INFT(NFTContract).getStakingBP(tokenID)
        );
        userInfo[_pid][sender].NFTContracts[NFTIndex] = userInfo[_pid][sender]
            .NFTContracts[length - 1];
        userInfo[_pid][sender].NFTContracts.pop();
        userInfo[_pid][sender].NFTTokenIDs[NFTIndex] = userInfo[_pid][sender]
            .NFTTokenIDs[length - 1];
        userInfo[_pid][sender].NFTTokenIDs.pop();

        INFT(NFTContract).safeTransferFrom(address(this), sender, tokenID);
        emit NFTWithdrawn(sender, NFTContract, tokenID);
    }

    function boostWithNFT(
        uint256 _pid,
        address NFTContract,
        uint256 tokenID
    ) public nonReentrant {
        require(msg.sender == tx.origin, "boostWithNFT : no contracts");
        require(
            isNFTContract[NFTContract],
            "boostWithNFT: incorrect contract address"
        );
        require(
            userInfo[_pid][msg.sender].amount >= 0,
            "Stake tokens before you deposit NFT"
        );
        require(
            userInfo[_pid][msg.sender].NFTTokenIDs.length <= 1,
            "You can deposit maximum 1 NFT"
        );
        INFT(NFTContract).safeTransferFrom(msg.sender, address(this), tokenID);
        userInfo[_pid][msg.sender].NFTContracts.push(NFTContract);
        userInfo[_pid][msg.sender].NFTTokenIDs.push(tokenID);
        userInfo[_pid][msg.sender].boostPointsBP += uint16(
            INFT(NFTContract).getStakingBP(tokenID)
        );
        emit NFTWithdrawn(msg.sender, NFTContract, tokenID);
    }

    function depositFor(
        address sender,
        uint256 _pid,
        uint256 amount
    ) public onlyAuthorized {
        _deposit(sender, _pid, amount);
    }

    function add(IERC20 _lpToken) public onlyOwner nonDuplicated(_lpToken) {
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({lpToken: _lpToken}));
    }

    function addNFTContract(address NFTcontract) public onlyOwner {
        isNFTContract[NFTcontract] = true;
    }

    // Pull out tokens accidentally sent to the contract. Doesnt work with the reward token or any staked token. Can only be called by the owner.
    function rescueToken(address tokenAddress) public onlyOwner {
        require(
            !poolExistence[IERC20(tokenAddress)],
            "rescueToken : wrong token address"
        );
        uint256 bal = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(msg.sender, bal);
    }

    function start() public onlyOwner {
        require(!started, "Can't stop staking");
        started = true;
    }


    function authorize(address _address) public onlyOwner {
        authorized[_address] = true;
    }

    function unauthorize(address _address) public onlyOwner {
        authorized[_address] = false;
    }

    function _deposit(
        address sender,
        uint256 _pid,
        uint256 _amount
    ) internal {
        require(started, "Staking is not started yet");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][sender];

        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );

            if (user.amount > 0) {
                uint256 userVotingPower = getVotingPower(_pid, sender);
                uint256 totalMultiplier = ((userVotingPower + _amount) *
                    10000) / (user.amount + _amount);

                uint256 multiplier = (ONE_DAY * (totalMultiplier - 10000)) /
                    (pointsPerDay + user.boostPointsBP);

                user.startedAt = block.timestamp - multiplier;
            } else {
                user.startedAt = block.timestamp;
            }

            user.amount = uint112(user.amount + _amount);
        }

        emit Deposit(sender, _pid, _amount);
    }
}