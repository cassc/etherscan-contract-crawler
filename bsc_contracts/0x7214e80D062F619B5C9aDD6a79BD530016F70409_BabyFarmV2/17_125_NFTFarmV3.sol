// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMasterChef.sol";

contract NFTFarmV3 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    event Stake(address user, uint256 tokenId, uint256 amount);
    event Unstake(address user, uint256 tokenId, uint256 amount);
    event Claim(address user, uint256 amount);
    event NewNFTInfo(uint256 index, address token, uint256 babyValue);
    event NewVault(address vault);
    event DelNFTInfo(uint256 index);

    uint256 public constant RATIO = 1e18;

    struct PoolInfo {
        uint256 totalShares;
        uint256 accBabyPerShare;
    }

    struct UserInfo {
        uint256 amount;
        uint256 debt;
        uint256 pending;
    }

    struct NFTInfo {
        ERC721 nftToken;
        uint256 babyValue;
    }

    PoolInfo public poolInfo;
    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(address => EnumerableSet.UintSet)) holderTokens;
    EnumerableMap.UintToAddressMap tokenOwners;
    NFTInfo[] private _nftInfos;
    mapping(address => bool) public isNFTExist;
    mapping(address => mapping(uint256 => uint256)) tokenWeight;
    ERC20 public immutable babyToken;
    IMasterChef immutable masterChef;
    address public vault;
    mapping(address => uint256) public babyValue;

    constructor(
        ERC20 _babyToken,
        IMasterChef _masterChef,
        address _vault
    ) {
        require(
            address(_babyToken) != address(0),
            "_babyToken address cannot be 0"
        );
        require(
            address(_masterChef) != address(0),
            "_masterChef address cannot be 0"
        );
        require(_vault != address(0), "_vault address cannot be 0");
        babyToken = _babyToken;
        masterChef = _masterChef;
        vault = _vault;
        emit NewVault(_vault);
    }

    function addNFTInfo(ERC721 _nftToken, uint256 _babyValue)
        external
        onlyOwner
    {
        require(
            address(_nftToken) != address(0),
            "_nftToken address cannot be 0"
        );
        require(!isNFTExist[address(_nftToken)], "nft already exists");
        _nftInfos.push(NFTInfo({nftToken: _nftToken, babyValue: _babyValue}));
        isNFTExist[address(_nftToken)] = true;
        emit NewNFTInfo(_nftInfos.length - 1, address(_nftToken), _babyValue);
    }

    function setNFTInfo(
        uint256 _index,
        ERC721 _nftToken,
        uint256 _babyValue
    ) external onlyOwner {
        require(
            address(_nftToken) != address(0),
            "_nftToken address cannot be 0"
        );
        require(_index < _nftInfos.length, "illegal index");
        require(isNFTExist[address(_nftToken)], "nft does not exist");
        _nftInfos[_index] = NFTInfo({nftToken: _nftToken, babyValue: _babyValue});
        emit NewNFTInfo(_index, address(_nftToken), _babyValue);
    }

    function delNFTInfo(uint256 _index) external onlyOwner {
        require(_index < _nftInfos.length, "illegal index");
        if (_index < _nftInfos.length - 1) {
            NFTInfo memory _lastNFTInfo = _nftInfos[_nftInfos.length - 1];
            _nftInfos[_index] = _nftInfos[_nftInfos.length - 1];
            emit NewNFTInfo(
                _index,
                address(_lastNFTInfo.nftToken),
                _lastNFTInfo.babyValue
            );
        }
        _nftInfos.pop();
        emit DelNFTInfo(_nftInfos.length);
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
        emit NewVault(_vault);
    }

    function stake(uint256 _tokenId, uint256 _idx) public nonReentrant {
        require(_idx < _nftInfos.length, "illegal idx");
        NFTInfo memory nftInfo = _nftInfos[_idx];
        uint256 stakeBaby = nftInfo.babyValue;
        SafeERC20.safeTransferFrom(babyToken, vault, address(this), stakeBaby);
        nftInfo.nftToken.transferFrom(msg.sender, address(this), _tokenId);

        PoolInfo memory _poolInfo = poolInfo;
        UserInfo memory _userInfo = userInfo[msg.sender];
        uint256 balanceBefore = babyToken.balanceOf(address(this));
        masterChef.enterStaking(0);
        uint256 balanceAfter = babyToken.balanceOf(address(this));
        uint256 _pending = balanceAfter.sub(balanceBefore);
        if (_pending > 0 && _poolInfo.totalShares > 0) {
            poolInfo.accBabyPerShare = _poolInfo.accBabyPerShare.add(
                _pending.mul(RATIO).div(_poolInfo.totalShares)
            );
            _poolInfo.accBabyPerShare = _poolInfo.accBabyPerShare.add(
                _pending.mul(RATIO).div(_poolInfo.totalShares)
            );
        }
        if (_userInfo.amount > 0) {
            userInfo[msg.sender].pending = _userInfo.pending.add(
                _userInfo.amount.mul(_poolInfo.accBabyPerShare).div(RATIO).sub(
                    _userInfo.debt
                )
            );
        }
        babyToken.approve(address(masterChef), stakeBaby.add(_pending));
        masterChef.enterStaking(stakeBaby.add(_pending));
        userInfo[msg.sender].amount = _userInfo.amount.add(stakeBaby);
        holderTokens[msg.sender][address(nftInfo.nftToken)].add(_tokenId);
        tokenOwners.set(_tokenId, msg.sender);
        tokenWeight[address(nftInfo.nftToken)][_tokenId] = stakeBaby;
        poolInfo.totalShares = _poolInfo.totalShares.add(stakeBaby);
        userInfo[msg.sender].debt = _poolInfo
            .accBabyPerShare
            .mul(_userInfo.amount.add(stakeBaby))
            .div(RATIO);
        emit Stake(msg.sender, _tokenId, stakeBaby);
    }

    function stakeAll(uint256[] memory _tokenIds, uint _idx) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            stake(_tokenIds[i],_idx);
        }
    }

    function unstake(uint256 _tokenId, uint256 _idx) public nonReentrant {
        require(_idx < _nftInfos.length, "illegal idx");
        NFTInfo memory nftInfo = _nftInfos[_idx];
        require(tokenOwners.get(_tokenId) == msg.sender, "illegal tokenId");

        PoolInfo memory _poolInfo = poolInfo;
        UserInfo memory _userInfo = userInfo[msg.sender];

        uint256 balanceBefore = babyToken.balanceOf(address(this));
        masterChef.leaveStaking(0);
        uint256 balanceAfter = babyToken.balanceOf(address(this));
        uint256 _pending = balanceAfter.sub(balanceBefore);
        if (_pending > 0 && _poolInfo.totalShares > 0) {
            poolInfo.accBabyPerShare = _poolInfo.accBabyPerShare.add(
                _pending.mul(RATIO).div(_poolInfo.totalShares)
            );
            _poolInfo.accBabyPerShare = _poolInfo.accBabyPerShare.add(
                _pending.mul(RATIO).div(_poolInfo.totalShares)
            );
        }

        uint256 _userPending = _userInfo.pending.add(
            _userInfo.amount.mul(_poolInfo.accBabyPerShare).div(RATIO).sub(
                _userInfo.debt
            )
        );
        uint256 _stakeAmount = tokenWeight[address(nftInfo.nftToken)][_tokenId];
        uint256 _totalPending = _userPending.add(_stakeAmount);

        if (_totalPending >= _pending) {
            masterChef.leaveStaking(_totalPending.sub(_pending));
        } else {
            babyToken.approve(address(masterChef), _pending.sub(_totalPending));
            masterChef.enterStaking(_pending.sub(_totalPending));
        }

        if (_userPending > 0) {
            SafeERC20.safeTransfer(babyToken, msg.sender, _userPending);
            emit Claim(msg.sender, _userPending);
        }
        if (_totalPending > _userPending) {
            SafeERC20.safeTransfer(
                babyToken,
                vault,
                _totalPending.sub(_userPending)
            );
        }

        poolInfo.totalShares = _poolInfo.totalShares.sub(_stakeAmount);
        userInfo[msg.sender].amount = _userInfo.amount.sub(_stakeAmount);
        userInfo[msg.sender].pending = 0;
        userInfo[msg.sender].debt = _userInfo
            .amount
            .sub(_stakeAmount)
            .mul(_poolInfo.accBabyPerShare)
            .div(RATIO);
        tokenOwners.remove(_tokenId);
        holderTokens[msg.sender][address(nftInfo.nftToken)].remove(_tokenId);
        nftInfo.nftToken.transferFrom(address(this), msg.sender, _tokenId);
        delete tokenWeight[address(nftInfo.nftToken)][_tokenId];
        emit Unstake(msg.sender, _tokenId, _stakeAmount);
    }

    function unstakeAll(uint256[] memory _tokenIds, uint _idx) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            unstake(_tokenIds[i], _idx);
        }
    }

    function claim(address _user) external nonReentrant {
        PoolInfo memory _poolInfo = poolInfo;
        UserInfo memory _userInfo = userInfo[_user];

        uint256 balanceBefore = babyToken.balanceOf(address(this));
        masterChef.leaveStaking(0);
        uint256 balanceAfter = babyToken.balanceOf(address(this));
        uint256 _pending = balanceAfter.sub(balanceBefore);
        if (_pending > 0 && _poolInfo.totalShares > 0) {
            poolInfo.accBabyPerShare = _poolInfo.accBabyPerShare.add(
                _pending.mul(RATIO).div(_poolInfo.totalShares)
            );
            _poolInfo.accBabyPerShare = _poolInfo.accBabyPerShare.add(
                _pending.mul(RATIO).div(_poolInfo.totalShares)
            );
        }
        uint256 _userPending = _userInfo.pending.add(
            _userInfo.amount.mul(_poolInfo.accBabyPerShare).div(RATIO).sub(
                _userInfo.debt
            )
        );
        if (_userPending == 0) {
            return;
        }
        if (_userPending >= _pending) {
            masterChef.leaveStaking(_userPending.sub(_pending));
        } else {
            babyToken.approve(address(masterChef), _pending.sub(_userPending));
            masterChef.enterStaking(_pending.sub(_userPending));
        }
        SafeERC20.safeTransfer(babyToken, _user, _userPending);
        emit Claim(_user, _userPending);
        userInfo[_user].debt = _userInfo
            .amount
            .mul(_poolInfo.accBabyPerShare)
            .div(RATIO);
        userInfo[_user].pending = 0;
    }

    function pending(address _user) external view returns (uint256) {
        uint256 _pending = masterChef.pendingCake(0, address(this));
        if (poolInfo.totalShares == 0) {
            return 0;
        }
        uint256 acc = poolInfo.accBabyPerShare.add(
            _pending.mul(RATIO).div(poolInfo.totalShares)
        );
        uint256 userPending = userInfo[_user].pending.add(
            userInfo[_user].amount.mul(acc).div(RATIO).sub(userInfo[_user].debt)
        );
        return userPending;
    }

    function balanceOf(address owner,uint256 nftIdx) external view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return holderTokens[owner][address(_nftInfos[nftIdx].nftToken)].length();
    }

    function tokenOfOwnerByIndex(address owner,uint256 nftIdx, uint256 index)
        external
        view
        returns (uint256)
    {
        return holderTokens[owner][address(_nftInfos[nftIdx].nftToken)].at(index);
    }

    function nftInfos() public view returns(NFTInfo[] memory){
        return _nftInfos;
    }
}