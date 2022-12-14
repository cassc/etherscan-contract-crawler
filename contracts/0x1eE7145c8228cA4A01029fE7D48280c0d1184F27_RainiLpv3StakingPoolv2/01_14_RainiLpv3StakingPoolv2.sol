// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IRainiLpv3StakingPoolv2.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract RainiLpv3StakingPoolv2 is AccessControl, ERC721Holder {

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

    using SafeERC20 for IERC20;

    uint256 public rewardRate;
    uint256 public xphotonRewardRate;
    uint256 public minRewardStake;

    uint256 public maxBonus;
    uint256 public bonusDuration;
    uint256 public bonusRate;

    int24 public minTickUpper;
    int24 public maxTickLower;
    uint24 public feeRequired;

    INonfungiblePositionManager public rainiLpNft;
    IERC20 public photonToken;
    IERC20UtilityToken public xphotonToken;
    address public exchangeTokenAddress;
    address public rainiTokenAddress;

    // Universal variables
    uint256 public totalSupply;

    IRainiLpv3StakingPoolv2.GeneralRewardVars public generalRewardVars;

    // account specific variables

    mapping(address => IRainiLpv3StakingPoolv2.AccountRewardVars) public accountRewardVars;
    mapping(address => IRainiLpv3StakingPoolv2.AccountVars) public accountVars;
    mapping(address => uint32[]) public stakedNfts;
    mapping(address => uint256) public staked;

    constructor(
        address _rainiLpNft, 
        address _xphotonToken,
        address _exchangeToken,
        address _rainiToken
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        rainiLpNft = INonfungiblePositionManager(_rainiLpNft);
        exchangeTokenAddress = _exchangeToken;
        xphotonToken = IERC20UtilityToken(_xphotonToken);
        rainiTokenAddress = _rainiToken;
    }

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "not owner"
        );
        _;
    }

    modifier onlyEditor() {
        require(
            hasRole(EDITOR_ROLE, _msgSender()),
            "not editor"
        );
        _;
    }

    function getStakedPositions(address _owner)
        public
        view
        returns (uint32[] memory)
    {
        return stakedNfts[_owner];
    }

    function setRewardRate(uint256 _rewardRate) external onlyEditor {
        rewardRate = _rewardRate;
    }
    function setXphotonRewardRate(uint256 _xphotonRewardRate) external onlyEditor {
        xphotonRewardRate = _xphotonRewardRate;
    }
    function setMinRewardStake(uint256 _minRewardStake) external onlyEditor {
        minRewardStake = _minRewardStake;
    }

    function setMaxBonus(uint256 _maxBonus) external onlyEditor {
        maxBonus = _maxBonus;
    }
    function setBonusDuration(uint256 _bonusDuration) external onlyEditor {
        bonusDuration = _bonusDuration;
    }
    function setBonusRate(uint256 _bonusRate) external onlyEditor {
        bonusRate = _bonusRate;
    }

    function setPhotonToken(address _photonTokenAddress) external onlyOwner {
        require (_photonTokenAddress != address(rainiLpNft), "bad addr");
        photonToken = IERC20(_photonTokenAddress);
    }

    function setGeneralRewardVars(IRainiLpv3StakingPoolv2.GeneralRewardVars memory _generalRewardVars) external onlyEditor {
        generalRewardVars = _generalRewardVars;
    }

    function setAccountRewardVars(address _user, IRainiLpv3StakingPoolv2.AccountRewardVars memory _accountRewardVars) external onlyEditor {
        accountRewardVars[_user] = _accountRewardVars;
    }

    function setAccountVars(address _user, IRainiLpv3StakingPoolv2.AccountVars memory _accountVars) external onlyEditor {
        accountVars[_user] = _accountVars;
    }

    function setMinTickUpper(int24 _minTickUpper) external onlyEditor {
        minTickUpper = _minTickUpper;
    }

    function setMaxTickLower(int24 _maxTickLower) external onlyEditor {
        maxTickLower = _maxTickLower;
    }

    function setFeeRequired(uint24 _feeRequired) external onlyEditor {
        feeRequired = _feeRequired;
    }

    function setStaked(address _user, uint256 _staked) external onlyEditor {
        staked[_user] = _staked;
    }

    function setTotalSupply(uint256 _totalSupply) external onlyEditor {
        totalSupply = _totalSupply;
    }

    function stakeLpNft(address _user, uint32 _tokenId) external onlyEditor {

        
        rainiLpNft.safeTransferFrom(_user, address(this), _tokenId);
        uint32[] memory nfts = stakedNfts[_user];
        
        bool wasAdded = false;
        for (uint256 i = 0; i < nfts.length; i++) {
            if (nfts[i] == 0) {
                stakedNfts[_user][i] = _tokenId;
                wasAdded = true;
                break;
            }
        }
        if (!wasAdded) {
            stakedNfts[_user].push(_tokenId);
        }
    }

    function withdrawLpNft(address _user, uint32 _tokenId) external onlyEditor {
        bool ownsNft = false;
        uint32[] memory nfts = stakedNfts[_user];
        for (uint256 i = 0; i < nfts.length; i++) {
            if (nfts[i] == _tokenId) {
                ownsNft = true;
                delete stakedNfts[_user][i];
                break;
            }
        }

        require(ownsNft, "Not the owner");
        rainiLpNft.safeTransferFrom(address(this), _user, _tokenId);
    }

    function withdrawPhoton(address _user, uint256 _amount) external onlyEditor {        
        photonToken.safeTransfer(_user, _amount);
    }
}