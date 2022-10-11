pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TokenClaim is Context, AccessControlEnumerable, Initializable {
    address public owner;
    address public deposit_address;

    IERC20 paymentToken;

    struct Claim {
        bytes32 _hashedMessage;
        uint256 claimId;
        uint256 value;
        address toAddress;
    }

    mapping(uint256 => Claim) public claimHistory;
    mapping(bytes32 => Claim) public hashClaim;
    bool public paused;

    event event_claim(uint256 claimId, uint256 value, address to);
    event event_deposit(address depositFrom, address depositReceiveAddress, uint256 value);

    function initialize(address _paymentToken, address _owner, address _deposit_address)
    public
    initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        paymentToken = IERC20(_paymentToken);
        owner = _owner;
        deposit_address = _deposit_address;
    }

    function depositToken(uint256 _value) public {
        paymentToken.transferFrom(_msgSender(), deposit_address, _value);
        emit event_deposit(_msgSender(), deposit_address, _value);
    }

    function claimToken(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _claimId,
        uint256 _value,
        uint256 _expTime
    ) public {
        bytes32 msgHash = keccak256(
            abi.encodePacked(_msgSender(), _claimId, _value, _expTime)
        );
        require(checkSign(msgHash, _v, _r, _s), "Invalid sign");

        require(hashClaim[msgHash].claimId == 0, "hash was exist");
        require(claimHistory[_claimId].claimId == 0, "claimId was exist");
        require(block.timestamp < _expTime, "claim token was end");
        require(
            _value <= paymentToken.balanceOf(address(this)),
            "token not enough"
        );
        require(!paused, "paused");

        Claim memory cl = Claim(msgHash, _claimId, _value, _msgSender());
        claimHistory[_claimId] = cl;
        hashClaim[msgHash] = cl;
        //Transfer
        paymentToken.transfer(_msgSender(), _value);
        emit event_claim(_claimId, _value, _msgSender());
    }

    function getRemainBalance() public view returns (uint256) {
        return paymentToken.balanceOf(address(this));
    }

    function setPause(bool _bool) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role"
        );
        paused = _bool;
    }

    function safuToken(address _token, uint256 _value) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role"
        );
        IERC20 token = IERC20(_token);
        token.transfer(_msgSender(), _value);
    }

    // player claims price
    function checkSign(
        bytes32 _hashedMessage,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public view returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _hashedMessage)
        );
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        // if the signature is signed by the owner
        if (signer == owner) {
            return true;
        }
        return false;
    }

    function VerifyMessage(
        bytes32 _hashedMessage,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _hashedMessage)
        );
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function setOwner(address newOwner) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role"
        );
        owner = newOwner;
    }

    function setDepositAddress(address _deposit_address) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role"
        );
        deposit_address = _deposit_address;
    }

    function getClaimById(uint256 _claimId) public view returns (Claim memory) {
        return claimHistory[_claimId];
    }
}