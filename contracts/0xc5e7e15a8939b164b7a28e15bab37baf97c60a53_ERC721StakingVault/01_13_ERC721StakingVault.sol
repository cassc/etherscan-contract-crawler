// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ERC721Rewards {
    function approvedCollection(address _contract) external virtual view returns (bool);
    function calculateRewards(address _address, uint8 _type) public virtual view returns (uint256);
}

contract ERC721StakingVault is Ownable, IERC721Receiver, ReentrancyGuard {

    event Claimed(address indexed _address, uint8 _type, uint256 _amount);
    event StakeNFT(address indexed user, address indexed collection, uint256 tokenId, uint8 _type);
    event UnstakeNFT(address indexed user, address indexed collection, uint256 tokenId, uint8 _type);
    event Deposit(address indexed _contact, address indexed _address, uint256 _amount);
    event Withdraw(address indexed _contact, address indexed _address, uint256 _amount);

    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    uint8 SOFT_STAKED = 0;
    uint8 HARD_STAKED = 1;

    mapping(address => mapping(address => EnumerableSet.UintSet)) private hardDeposits;
    mapping(address => mapping(address => mapping(uint256 => uint256))) private hardDepositTimes;
    mapping(address => EnumerableSet.AddressSet) private hardDepositAddresses;
    mapping(address => EnumerableSet.UintSet) private softDeposits;
    mapping(address => mapping(uint256 => uint256)) private softDepositTimes;
    mapping(uint8 => mapping(address => uint256)) private stakeCounter;
    mapping(uint8 => bool) private config;
    mapping(address => mapping(uint256 => address)) public hardOwnership;
    bool public paused;

    address public rewardContract;
    address public erc20Contract;

    constructor(
        bool _softStaking,
        bool _hardStaking,
        address _owner
    ) {
        config[SOFT_STAKED] = _softStaking;
        config[HARD_STAKED] = _hardStaking;
        transferOwnership(_owner);
    }

    function setConfiguration(uint8 _type, bool _active) external onlyOwner {
        config[_type] = _active;
    }

    function getConfiguration(uint8 _type) public view returns (bool) {
        return config[_type];
    }

    function setContracts(address _erc20Contract, address _rewardContract) external onlyOwner {
        erc20Contract = _erc20Contract;
        rewardContract = _rewardContract;
    }

    function stakedCount(address _contract, uint8 _type)
        external
        view
        returns (uint256)
    {
        return stakeCounter[_type][_contract];
    }

    function getStaker(address _contract, uint256 _tokenId, uint8 _type)
        external
        view
        returns (address)
    {
        if (_type == SOFT_STAKED) {
            return softDeposits[_contract].contains(_tokenId) ? IERC721(_contract).ownerOf(_tokenId) : address(0);
        } else {
            return hardOwnership[_contract][_tokenId];
        }
    }

    function getSoftStaked(address _contract) external view returns (uint256[] memory) {
        return softDeposits[_contract].values();
    }

    function getHardStaked(address _contract) external view returns (address[] memory) {
        return hardDepositAddresses[_contract].values();
    }

    function isStaked(address _address, address _contract, uint256 _tokenId, uint8 _type)
        internal
        view
        returns (bool)
    {
        return (
            (_type == HARD_STAKED && hardDeposits[_contract][_address].contains(_tokenId)) ||
            (_type == SOFT_STAKED && softDeposits[_contract].contains(_tokenId) && IERC721(_contract).ownerOf(_tokenId) == _address)
        );
    }

    function depositsOf(address _address, address _contract, uint8 _type)
        public
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage _depositSet = _type == SOFT_STAKED ?
            softDeposits[_contract] : 
            hardDeposits[_contract][_address];

        uint256 size;
        for (uint256 i; i < _depositSet.length(); i++) {
            if (isStaked(_address, _contract, _depositSet.at(i), _type)) {
                size++;
            }
        }
        uint256 index;
        uint256[] memory _tokenIds = new uint256[](size);
        for (uint256 i; i < _depositSet.length(); i++) {
            if (isStaked(_address, _contract, _depositSet.at(i), _type)) {
                _tokenIds[index++] = _depositSet.at(i);
            }
        }
        return _tokenIds;
    }

    function depositTimeOf(address _address, address _contract, uint256 _tokenId, uint8 _type)
        external
        view
        returns (uint256)
    {
        return _type == SOFT_STAKED ? softDepositTimes[_contract][_tokenId] : hardDepositTimes[_contract][_address][_tokenId];
    }

    function stake(address _contract, uint256[] calldata _tokenIds, uint8 _type) external nonReentrant {
        require(!paused, "Contract paused");
        require(config[_type], "Staking disabled");
        require(ERC721Rewards(rewardContract).approvedCollection(_contract), "Bad collection");
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(!isStaked(msg.sender, _contract, _tokenId, _type), "Already staked");
            if (_type == SOFT_STAKED) {
                softDeposits[_contract].add(_tokenId);
                softDepositTimes[_contract][_tokenId] = block.timestamp;
            } else {
                if (!hardDepositAddresses[_contract].contains(msg.sender)) hardDepositAddresses[_contract].add(msg.sender);
                hardDeposits[_contract][msg.sender].add(_tokenId);
                hardDepositTimes[_contract][msg.sender][_tokenId] = block.timestamp;
                hardOwnership[_contract][_tokenId] = msg.sender;
                IERC721(_contract).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _tokenId,
                    ""
                );
            }
            emit StakeNFT(msg.sender, _contract, _tokenId, _type);
        }
        stakeCounter[_type][_contract] += _tokenIds.length;
    }

    function unstake(address _contract, uint256[] calldata _tokenIds, uint8 _type) external nonReentrant {
        require(ERC721Rewards(rewardContract).approvedCollection(_contract), "Bad collection");
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(isStaked(msg.sender, _contract, _tokenId, _type), "Token not deposited");
            if (_type == SOFT_STAKED) {
                softDeposits[_contract].remove(_tokenId);
                delete softDepositTimes[_contract][_tokenId];
            } else {
                hardDeposits[_contract][msg.sender].remove(_tokenId);
                if (hardDepositAddresses[_contract].contains(msg.sender) && 
                    hardDeposits[_contract][msg.sender].length() == 0) hardDepositAddresses[_contract].remove(msg.sender);
                delete hardDepositTimes[_contract][msg.sender][_tokenId];
                delete hardOwnership[_contract][_tokenId];
                IERC721(_contract).safeTransferFrom(
                    address(this),
                    msg.sender,
                    _tokenId,
                    ""
                );
            }
            emit UnstakeNFT(msg.sender, _contract, _tokenId, _type);
        }
        stakeCounter[_type][_contract] -= _tokenIds.length;
    }

    function claimRewards(address _address, uint8 _type) public nonReentrant {
        require(msg.sender == rewardContract, "Not authorized");
        require(!paused, "Contract paused");
        require(getConfiguration(_type), "Not allowed");
        uint256 _rewards = ERC721Rewards(rewardContract).calculateRewards(_address, _type);
        require(_rewards > 0, "No rewards");
        IERC20(erc20Contract).approve(address(this), _rewards);
        IERC20(erc20Contract).transferFrom(address(this), _address, _rewards);
        emit Claimed(_address, _type, _rewards);
    }

    function clearDepositTimesOf(address _address, address[] memory _contracts, uint8 _type) external nonReentrant {
        require(msg.sender == rewardContract, "Not authorized");
        for (uint256 i = 0; i < _contracts.length; i++) {
            address _contract = _contracts[i];
            uint256[] memory _tokenIds = depositsOf(_address, _contract, _type);
            for (uint256 j; j < _tokenIds.length; j++) {
                if (_type == SOFT_STAKED) {
                    softDepositTimes[_contract][_tokenIds[j]] = block.timestamp;
                } else {
                    hardDepositTimes[_contract][_address][_tokenIds[j]] = block.timestamp;
                }
            }
        }
    }

    function depositTokens(uint256 _amount, address _contract) public onlyOwner {
        require(_amount <= IERC20(_contract).balanceOf(msg.sender), "Insufficient funds.");
        IERC20(_contract).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(_contract, msg.sender, _amount);
    }

    function withdrawTokens(uint256 _amount, address _contract) public onlyOwner {
        require(IERC20(_contract).balanceOf(address(this)) >= _amount, "Insufficient balance");
        IERC20(_contract).transfer(msg.sender, _amount);
        emit Withdraw(_contract, msg.sender, _amount);
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}