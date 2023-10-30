pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./library/IERC20BurnNMintable.sol";

contract ETHBridge {
    using SafeMath for uint256;

    bool public whiteListOn;

    address public owner;
    address public signWallet1;
    address public signWallet2;
    uint256 public feeCollected;

    // key: payback_id
    mapping(bytes32 => bool) public executedMap;
    mapping(address => bool) public isWhiteList;

    event Payback(address indexed sender,address indexed from, address indexed token, uint256 amount,uint256 destinationChainID, bytes32 migrationId);
    event Withdraw(bytes32 paybackId, address indexed to, address indexed token, uint256 amount, uint256 fee);
    event SignerChanged(address indexed oldSigner1, address  newSigner1,address indexed oldSigner2, address  newSigner2);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    constructor(address _signer1,address _signer2) {
        require(_signer1 != address(0) || _signer2 != address(0), "INVALID_ADDRESS");
        signWallet1 = _signer1;
        signWallet2 = _signer2;
        owner = msg.sender;
        whiteListOn = true;
    }

    function toggleWhiteListOnly() external {
        require(msg.sender == owner, "Sender not Owner");
        whiteListOn = !whiteListOn;

    }

     function toggleWhiteListAddress(address[] calldata _addresses) external {
        require(msg.sender == owner, "Sender not Owner");
        require(_addresses.length<=200,"Addresses length exceeded");
        for (uint256 i = 0; i < _addresses.length; i++) {
            isWhiteList[_addresses[i]] = !isWhiteList[_addresses[i]];
        }
    }


  function changeSigner(address _wallet1, address _wallet2) external {
        require(msg.sender == owner, "CHANGE_SIGNER_FORBIDDEN");
        require(_wallet1!=address(0) && _wallet2!=address(0),"Invalid Address");
        emit SignerChanged(signWallet1, _wallet1,signWallet2, _wallet2);
        signWallet1 = _wallet1;
        signWallet2 = _wallet2;
    }


    function changeOwner(address _newowner) external {
        require(msg.sender == owner, "CHANGE_OWNER_FORBIDDEN");
        require(_newowner!=address(0),"Invalid Address");
        emit OwnerChanged(owner, _newowner);
        owner = _newowner;
    }



    function paybackTransit(address _token, uint256 _amount, address _to, uint256 _destinationChainID, bytes32 _migrationId) external {
        address sender=msg.sender;
        require(_amount > 0, "INVALID_AMOUNT");
        require(!whiteListOn || isWhiteList[sender], "Forbidden in White List mode");
        IERC20(_token).transferFrom(sender, address(this), _amount);
        emit Payback(sender,_to, _token, _amount,_destinationChainID,_migrationId);
    }

    function withdrawTransitToken(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 _paybackId,
        address _token,
        address _beneficiary,
        uint256 _amount,
        uint256 _fee
    ) external {
        require(signWallet1 == msg.sender || signWallet2 == msg.sender, "Sender Does not Have Claim Rights");
        require(!executedMap[_paybackId], "ALREADY_EXECUTED");
        require(_amount > 0, "NOTHING_TO_WITHDRAW");
        require(_amount > _fee, "Fee cannot be greater then withdrawl amount");
        bytes32 message = keccak256(abi.encode(_paybackId, _beneficiary, _amount, _token));
        _validate(v, r, s, message);
        uint256 userAmount = _amount - _fee;
        feeCollected = feeCollected.add(_fee);
        executedMap[_paybackId] = true;
        IERC20(_token).transfer(_beneficiary, userAmount);
        
        emit Withdraw(_paybackId, _beneficiary, _token, _amount, _fee);
    }

    function getDomainSeparator() internal view returns (bytes32) {
        return keccak256(abi.encode("0x01", address(this)));
    }

    function _validate(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 encodeData
    ) internal view {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), encodeData));
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress!= address(0) && (recoveredAddress == signWallet1 || recoveredAddress == signWallet2), "INVALID_SIGNATURE");
    }

    function withdrawPlatformFee(
            address _token,
            address _to,
            uint256 _amount
        ) external {
            require(_amount>=0,"Invalid Amount");
            require(msg.sender == owner, "INVALID_OWNER");
            require(_amount<=feeCollected,"Amount Exceeds Fee Collected");
            feeCollected = feeCollected.sub(_amount);
            IERC20(_token).transfer(_to, _amount);
        }
}