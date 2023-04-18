// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ShadowHarvest is Ownable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    // user struct
    struct UserInfo {
        uint256 rewardDebt; // harvested tokens
        uint256 lastBlock;
    }

    address public defaultRewardToken;
    address[] internal users;

    mapping(address => UserInfo) private userRewardInfo;

    // from rewardToken address to Signer address and isTrusted
    mapping(address => bool) public trustedSigner;

    event NewUser(address indexed user);
    event Harvest(
        address indexed user,
        uint256 _amount,
        uint256 lastBlockNumber,
        uint256 currentBlockNumber
    );

    constructor(address _defaultRewardToken) {
        trustedSigner[msg.sender] = true;
        defaultRewardToken = _defaultRewardToken;
    }

    function userRegister() external {
        _registration(msg.sender, block.number);
    }

    function harvest(
        uint256 _amount,
        uint256 _lastBlockNumber,
        uint256 _currentBlockNumber,
        bytes32 _msgForSign,
        bytes memory _signature
    ) public {
        require(
            _currentBlockNumber <= block.number,
            "currentBlockNumber cannot be larger than the last block"
        );

        //Double spend check
        require(
            getLastBlock(msg.sender) == _lastBlockNumber,
            "lastBlockNumber must be equal to the value in the storage"
        );

        //1. Lets check signer
        address signedBy = _msgForSign.recover(_signature);
        require(trustedSigner[signedBy] == true, "Signature check failed!");

        //2. Check signed msg integrety
        bytes32 actualMsg = keccak256(
            abi.encode(
                _amount,
                _lastBlockNumber,
                _currentBlockNumber,
                msg.sender
            )
        );
        require(
            actualMsg.toEthSignedMessageHash() == _msgForSign,
            "Integrety check failed!"
        );

        //Actions

        userRewardInfo[msg.sender].rewardDebt += _amount;
        userRewardInfo[msg.sender].lastBlock = _currentBlockNumber;
        if (_amount > 0) {
            IERC20 ERC20Token = IERC20(defaultRewardToken);
            ERC20Token.transfer(msg.sender, _amount);
        }
        emit Harvest(
            msg.sender,
            _amount,
            _lastBlockNumber,
            _currentBlockNumber
        );
    }

    function getLastBlock(address _user) public view returns (uint256) {
        return userRewardInfo[_user].lastBlock;
    }

    function getUsersCount() public view returns (uint256) {
        return users.length;
    }

    function getUser(uint256 _userId) public view returns (address) {
        return users[_userId];
    }

    function getRewards(address _user) public view returns (uint256) {
        return userRewardInfo[_user].rewardDebt;
    }

    ////////////////////////////////////////////////////////////
    /////////// Admin only           ////////////////////////////
    ////////////////////////////////////////////////////////////

    function setTrustedSigner(address _signer, bool _isValid) public onlyOwner {
        trustedSigner[_signer] = _isValid;
    }

    ////////////////////////////////////////////////////////////
    /////////// internal           /////////////////////////////
    ////////////////////////////////////////////////////////////

    function _registration(address _user, uint256 _lastBlock) internal {
        if (getLastBlock(_user) == 0) {
            users.push(_user);
        }
        UserInfo storage _userInfo = userRewardInfo[_user];
        _userInfo.lastBlock = _lastBlock;
        emit NewUser(_user);
    }
}