// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

contract YohToken is ERC20BurnableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public _unused_1;
    uint256 public _unused_2;

    address nullAddress;
    address public yokaiAddress;
    address public _unused_3;

    //Mapping of yokai to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;
    //Mapping of yokai to staker
    mapping(uint256 => address) internal _unused_4; //tokenIdToStaker;
    //Mapping of staker to yokai
    mapping(address => uint256[]) internal stakerToTokenIds;

    address public boostAddress;
    address public oracleVerification;
    uint256 public claimNonce;
    bool public pauseClaim;

    mapping(address => bool) public pauseAddress;


    // Initializer function (replaces constructor)
    function initialize() public initializer {
        __ERC20_init("Yoh Token", "YOH");
        __ERC20Burnable_init();
        __Ownable_init();
        nullAddress = 0x0000000000000000000000000000000000000000;
    }

    function setPauseClaim(bool _pauseClaim) public onlyOwner {
        pauseClaim = _pauseClaim;
    }

    function setPauseAddresses(address[] memory _paused, bool[] memory _values) public onlyOwner {
        for(uint i = 0; i < _paused.length; i++){
          pauseAddress[_paused[i]] = _values[i];
        }
    }

    function setClaimNonce(uint256 _claimNonce) public onlyOwner {
        claimNonce = _claimNonce;
    }

    function setOracleVerification(address _oracleVerification) public onlyOwner {
        oracleVerification = _oracleVerification;
    }

    function unstakeAll() public {
        require(pauseClaim == false, "Unstaking is paused!");
        require(pauseAddress[_msgSender()] == false, "Cannot unstake right now.");

        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];

        for(uint i = 0; i < tokenIds.length; i++){
          IERC721EnumerableUpgradeable(yokaiAddress).transferFrom(address(this), msg.sender, tokenIds[i]);
        }

        delete stakerToTokenIds[msg.sender];
    }

    function unstakeAllWithAccounts(address[] memory accounts) public onlyOwner {
      require(pauseClaim == false, "Unstaking is paused!");

        for(uint i = 0; i < accounts.length; i++){
          address user = accounts[i];
          require(pauseAddress[user] == false, "Cannot unstake right now.");

          uint256[] memory tokenIds = stakerToTokenIds[user];

          for(uint k = 0; k < tokenIds.length; k++){
            IERC721EnumerableUpgradeable(yokaiAddress).transferFrom(address(this), user, tokenIds[k]);
          }

          delete stakerToTokenIds[user];
        }

    }

    function getTokensStaked(address staker) public view returns (uint256[] memory) {
        return stakerToTokenIds[staker];
    }

    function getBoostBalance(address staker) public view returns (uint256 boostAmount) {
        boostAmount = 0;
        if(boostAddress != address(0)){
          boostAmount = IBoost(boostAddress).balanceOf(staker, 1);
        }
    }

    function getStakerInfo(address staker) public view returns (uint256[] memory tokenIds, uint256[] memory timestamps, uint256 boostAmount) {
        tokenIds = stakerToTokenIds[staker];
        uint256[] memory _timestamps = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _timestamps[i] = tokenIdToTimeStamp[tokenIds[i]];
        }

        boostAmount = getBoostBalance(staker);

        timestamps = _timestamps;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(pauseAddress[_msgSender()] == false, "Cannot transfer right now.");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(pauseAddress[_msgSender()] == false, "Cannot transfer right now.");
        require(pauseAddress[sender] == false, "Cannot transfer right now.");

        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

}

interface IBoost {
  function balanceOf(address account, uint256 id) external view  returns (uint256);
}

interface IERC721Enum {
  function tokensOfOwner(address owner) external view returns (uint256[] memory);
}