// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "../interfaces/IERC20Mintable.sol";
import '../core/SafeOwnable.sol';

contract KIKIVault is SafeOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Mintable;

    event NewHash(bytes32 oldHash, bytes32 newHash, uint256 updateAt);
    event Claim(address user, uint amount, uint totalAmount);

    bytes32 public rootHash;
    IERC20Mintable immutable public rewardToken;
    mapping(address => uint) public userClaimed;
    uint256 public totalReleaseAmount;
    uint256 public lastUpdate;
    mapping(address => uint) public userLastUpdate;

    constructor(IERC20Mintable _rewardToken, address _owner) SafeOwnable(_owner) {
        rewardToken = _rewardToken;
    }

    function updateRootHash(bytes32 _rootHash, uint256 _releaseAmount, uint256 _updateAt) external onlyOwner {
        require(_updateAt > lastUpdate, "already updateed");
        lastUpdate = _updateAt;
        emit NewHash(rootHash, _rootHash, _updateAt);
        rootHash = _rootHash;
        if (_releaseAmount > 0) {
            rewardToken.mint(address(this), _releaseAmount);
            totalReleaseAmount = totalReleaseAmount.add(_releaseAmount);
        }
    }

    function claim(address _to, uint _amount, bytes32[] memory _proof) public {
        bytes32 leaf = keccak256(abi.encodePacked(_to, _amount));
        require(MerkleProof.verify(_proof, rootHash, leaf), "illegal amount");
        _amount = _amount.sub(userClaimed[_to]);
        if (_amount > 0) {
            userClaimed[_to] = userClaimed[_to].add(_amount);
            rewardToken.safeTransfer(_to, _amount);
            emit Claim(_to, _amount, userClaimed[_to]);
            userLastUpdate[_to] = block.timestamp;
        }
    }

    function getAllUserClaimed(address[] memory addresses) external view returns (uint claimed) {
        for (uint i = 0; i < addresses.length; i ++) {
            claimed = claimed.add(userClaimed[addresses[i]]);
        }
    }

    function claimAll(address[] memory _users, uint[] memory _amounts, uint[] memory _sizes, bytes32[] memory _proof) external {
        require(_users.length == _amounts.length && _amounts.length == _sizes.length, "illegal length");
        uint start = 0;
        for (uint i = 0; i < _users.length; i ++) {
            bytes32[] memory currentProof = new bytes32[](_sizes[i]); 
            for (uint j = 0; j < _sizes[i]; j ++) {
                currentProof[j] = _proof[j + start];
            }
            start = start.add(_sizes[i]);
            claim(_users[i], _amounts[i], currentProof);
        }
    }
}