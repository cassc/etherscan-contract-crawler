// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AVGLToken is ERC20("AVGL", "AVGL"), AccessControl {
    using SafeMath for uint256;

    uint256 public constant BASE_RATE = 1 ether;
    uint256 public constant INITIAL_ISSUANCE = 10 ether;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    IERC721 public avgleCollectionContract;

    event RewardPaid(address indexed user, uint256 reward);

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    function addBurnerRole(address addr) external {
		grantRole(BURNER_ROLE, addr);
	}

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _;
    }

    function setCollectionContractAddress(address _avgleCollection) external onlyAdmin {
        avgleCollectionContract = IERC721(_avgleCollection);
    }

    constructor(address _avgleCollection) {
        avgleCollectionContract = IERC721(_avgleCollection);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // called when minting many NFTs
    function updateRewardOnMint(address _user) external {
        require(
            msg.sender == address(avgleCollectionContract),
            "Can't call this"
        );
        uint256 time = block.timestamp;
        uint256 timerUser = lastUpdate[_user];
        if (timerUser > 0) {
            rewards[_user] = rewards[_user].add(avgleCollectionContract
                    .balanceOf(_user)
                    .mul(BASE_RATE.mul((time.sub(timerUser))))
                    .div(86400));
        }
        lastUpdate[_user] = time;
    }

    // called on transfers
    function updateReward(address _from, address _to) external {
        require(msg.sender == address(avgleCollectionContract));
        uint256 time = block.timestamp;
        uint256 timerFrom = lastUpdate[_from];
        if (timerFrom > 0)
            rewards[_from] += avgleCollectionContract
                .balanceOf(_from)
                .mul(BASE_RATE.mul((time.sub(timerFrom))))
                .div(86400);
        lastUpdate[_from] = time;
        if (_to != address(0)) {
            uint256 timerTo = lastUpdate[_to];
            if (timerTo > 0)
                rewards[_to] += avgleCollectionContract
                    .balanceOf(_to)
                    .mul(BASE_RATE.mul((time.sub(timerTo))))
                    .div(86400);
            lastUpdate[_to] = time;
        }
    }

    function getReward(address _to) external {
        require(msg.sender == address(avgleCollectionContract));
        uint256 reward = rewards[_to];
        if (reward > 0) {
            rewards[_to] = 0;
            _mint(_to, reward);
            emit RewardPaid(_to, reward);
        }
    }

    function burn(address _from, uint256 _amount) external {
        require(msg.sender == address(avgleCollectionContract) || hasRole(BURNER_ROLE, _msgSender()));
        _burn(_from, _amount);
    }

    function getTotalClaimable(address _user) external view returns (uint256) {
        uint256 time = block.timestamp;
        uint256 pending = avgleCollectionContract
            .balanceOf(_user)
            .mul(BASE_RATE.mul((time.sub(lastUpdate[_user]))))
            .div(86400);
        return rewards[_user] + pending;
    }
}