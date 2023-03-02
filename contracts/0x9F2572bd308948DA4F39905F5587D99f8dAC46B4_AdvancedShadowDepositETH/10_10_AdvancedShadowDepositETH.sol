// SPDX-License-Identifier: MIT
// Sidus Staking
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AdvancedShadowDepositETH is Ownable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    struct Position {
        uint256 closed;
        uint256 pId;
    }

    mapping(address => Position[]) public userPositions;
    mapping(address => bool) public trustedSigner;

    struct RewardInfo {
        address rewardToken;
        address paymentAddress;
        bool isValid;
    }

    event OpenPosition(address indexed user, uint256 indexed pid);
    event ClosePosition(address indexed user, uint256 indexed pid);

    address payable public keeper;

    /// @param _pid internal id on backend
    /// @param _amount amount
    /// @param _type should be false
    /// @param _msgForSign clear message, before sign
    /// @param _signature signature
    function deposit(
        uint _pid,
        uint _amount,
        bool _type,
        bytes32 _msgForSign,
        bytes memory _signature
    ) external payable {
        require(!_type, "Signature for withdaw");
        require(!positionExists(msg.sender, _pid), "deposit before");
        // 1. Check signer
        address signedBy = _msgForSign.recover(_signature);
        require(trustedSigner[signedBy] == true, "signature check failed");

        //2. Check signed msg integrety
        bytes32 actualMsg = getMsgForSign(msg.sender, _pid, _amount, _type);
        require(
            actualMsg.toEthSignedMessageHash() == _msgForSign,
            "integrety check failed"
        );
        require(msg.value == _amount, "amount is bad");
        keeper.transfer(msg.value);
        //stake
        userPositions[msg.sender].push(Position({closed: 0, pId: _pid}));
        emit OpenPosition(msg.sender, _pid);
    }

    /// @param _keeper address os cold wallet
    /// @notice only owner can call this function
    function setKeeper(address _keeper) external onlyOwner {
        keeper = payable(_keeper);
    }

    /// @param _signer address of signer
    /// @param _isValid true, if we want turn on this signer
    /// @notice only owner can call this function
    function setTrustedSigner(address _signer, bool _isValid) public onlyOwner {
        trustedSigner[_signer] = _isValid;
    }

    /// @param _tokenContract address of token contract
    /// @param _stakeContract address of stake contract
    /// @param _amount amount of approve
    /// @notice only owner can call this function
    function setApprove(
        address _tokenContract,
        address _stakeContract,
        uint256 _amount
    ) public onlyOwner {
        IERC20(_tokenContract).approve(_stakeContract, _amount);
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
        bool _type
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_user, _pid, _amount, _type));
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