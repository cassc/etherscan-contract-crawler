// SPDX-License-Identifier: MIT
// Sidus Staking
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract USDTDeposit is Ownable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    struct Position {
        uint256 closed;
        uint256 pId;
    }

    mapping(address => Position[]) public userPositions;
    mapping(address => mapping(address => RewardInfo)) public trustedSigner;

    struct RewardInfo {
        address rewardToken;
        address paymentAddress;
        bool isValid;
    }
    /// @notice on or off maxdeposit mode
    bool public totalDepositMode;
    /// @notice amount of max deposits
    uint public totalDepositAmount;
    /// @notice current amount of deposit
    uint public depositedAmount;
    event OpenPosition(address indexed user, uint256 indexed pid);
    event ClosePosition(address indexed user, uint256 indexed pid);

    /// @param _pid internal id on backend
    /// @param _amount amount
    /// @param _type should be false
    /// @param _rewardToken address of reward token
    /// @param _msgForSign clear message, before sign
    /// @param _signature signature
    function deposit(
        uint _pid,
        uint _amount,
        bool _type,
        address _rewardToken,
        bytes32 _msgForSign,
        bytes memory _signature
    ) external {
        if (totalDepositMode) {
            require(
                (depositedAmount + _amount) <= totalDepositAmount,
                "deposit limit reached"
            );
        }
        require(!_type, "Signature for withdaw");
        require(!positionExists(msg.sender, _pid), "deposit before");
        // 1. Check signer
        address signedBy = _msgForSign.recover(_signature);
        require(
            trustedSigner[_rewardToken][signedBy].isValid == true,
            "signature check failed"
        );

        //2. Check signed msg integrety
        bytes32 actualMsg = getMsgForSign(
            msg.sender,
            _pid,
            _amount,
            _type,
            _rewardToken
        );
        require(
            actualMsg.toEthSignedMessageHash() == _msgForSign,
            "integrety check failed"
        );

        IERC20(_rewardToken).safeTransferFrom(
            msg.sender,
            trustedSigner[_rewardToken][signedBy].paymentAddress,
            _amount
        );

        depositedAmount += _amount;
        userPositions[msg.sender].push(Position({closed: 0, pId: _pid}));
        emit OpenPosition(msg.sender, _pid);
    }

    /// @param _amount new amount of max deposit
    /// @notice only owner can call this function
    function totalDepositAmountSet(uint _amount) external onlyOwner {
        totalDepositAmount = _amount;
    }

    /// @param _mode on or off total deposit mode
    /// @notice only owner can call this function
    function totalDepositModeSet(bool _mode) external onlyOwner {
        totalDepositMode = _mode;
    }

    /// @param _rewardToken address of token
    /// @param _signer address of signer
    /// @param _paymentAddress coldwallet
    /// @param _isValid true, if we want turn on this signer
    /// @notice only owner can call this function
    function setTrustedSigner(
        address _rewardToken,
        address _signer,
        address _paymentAddress,
        bool _isValid
    ) public onlyOwner {
        trustedSigner[_rewardToken][_signer].isValid = _isValid;
        trustedSigner[_rewardToken][_signer].paymentAddress = _paymentAddress;
    }

    /// @param _user address of user
    /// @param _pid internal id
    /// @return uint date of close
    function getClosedDate(
        address _user,
        uint _pid
    ) public view returns (uint) {
        return userPositions[_user][_getPositionIndexByPid(_user, _pid)].closed;
    }

    ///////////////////////////////////////////////////////////////////
    /////  Internal Functions /////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////
    function getMsgForSign(
        address _user,
        uint256 _pid,
        uint256 _amount,
        bool _type,
        address _rewardToken
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_user, _pid, _amount, _type, _rewardToken));
    }

    function positionExists(
        address _user,
        uint256 _pid
    ) internal view returns (bool result) {
        for (uint256 i = 0; i < userPositions[_user].length; i++) {
            if (userPositions[_user][i].pId == _pid) {
                result = true;
                break;
            }
        }
    }

    function _getPositionIndexByPid(
        address _user,
        uint256 _pid
    ) internal view returns (uint256) {
        for (uint256 i = 0; i < userPositions[_user].length; i++) {
            if (userPositions[_user][i].pId == _pid) {
                return i;
            }
        }
        revert("Position not found for this user");
    }
}