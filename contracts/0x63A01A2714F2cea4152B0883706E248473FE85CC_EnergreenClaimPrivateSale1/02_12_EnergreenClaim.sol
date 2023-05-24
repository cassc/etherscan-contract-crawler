// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Import required OpenZeppelin contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
  Three types of users are involved in the contract:
  - signer : The address that signs the transaction
  - holder : The address that provides the token
  - owner : The one who manages the contract (can change signer and holder)

  Necessary conditions for claim to work:
  - Holder must have tokens
  - Holder must give allowance to this contract
*/

contract EnergreenClaim is ReentrancyGuard, Ownable {
    // Event to be emitted when a claim is processed
    event ClaimProcessed(address recipient, uint256 nowClaimed, uint256 totalClaimed, uint256 date);

    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    IERC20 private immutable egrn;  // The token interface
    address private signer;  // The address that signs the transaction
    address internal tokenHolder;

    // Blacklisted addresses cannot claim (can be used if an account is stolen after signing)
    mapping(address => bool) private blacklist;

    // Mapping of address to total claim made
    mapping(address => uint256) public claimed;

    constructor(address _tokenAddress , address _signer) {
        signer = _signer;
        egrn = IERC20(_tokenAddress);
    }

    // Override renounceOwnership from Ownable, as we don't want this to be possible
    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here");
    }

    // Function to set the signer
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    // Function to set the token holder
    function setTokenHolder(address _tokenHolder) external onlyOwner {
        tokenHolder = _tokenHolder;
    }

    // Function to change the blacklist status of an address
    function changeBlacklistStatus(address _address, bool value) external onlyOwner {
        blacklist[_address] = value;
    }

    // Function to check if addresses are blacklisted
    function isBlacklisted(address[] memory _addressList) external view returns(bool[] memory ret) {
        ret = new bool[](_addressList.length);
        for (uint256 i = 0 ; i < _addressList.length ; i++)
            ret[i] = blacklist[_addressList[i]];
    }

    // Function to claim tokens
    function claimTokens(
        address _recipient,
        uint256 _claimLimit,
        uint256 _claimStartTimestamp,
        bytes calldata signature
    )
        external nonReentrant
    {
        bytes32 messageHash = keccak256(abi.encodePacked(
            address(this),
            _recipient,
            _claimLimit,
            _claimStartTimestamp
        )).toEthSignedMessageHash();

        require(recoverSigner(messageHash, signature) == signer, "wrong signature");
        require(block.timestamp > _claimStartTimestamp, "tried to claim at future timestamp");
        require(blacklist[_recipient] == false, "recipient in blacklist");
        require(_claimLimit > claimed[_recipient], "claim amount previosly claimed by recipient");

        uint256 claimAmount = _claimLimit - claimed[_recipient];

        claimed[_recipient] = _claimLimit;

        require(egrn.transferFrom(tokenHolder, _recipient, claimAmount),
                "Transfer is not successful");

        emit ClaimProcessed(_recipient,  claimAmount, _claimLimit, block.timestamp);
    }

    // Function to test the claim info
    function testClaimInfo(
        address _recipient,
        uint256 _claimLimit,
        uint256 _claimStartTimestamp,
        bytes calldata _signature
    )
        external view returns (uint256, uint256)
    {
        bytes32 messageHash = keccak256(abi.encodePacked(
            address(this),
            _recipient,
            _claimLimit,
            _claimStartTimestamp
        )).toEthSignedMessageHash();

        require(recoverSigner(messageHash, _signature) == signer , "wrong signature");
        require(block.timestamp > _claimStartTimestamp, "tried to claim at future timestamp");
        require(blacklist[_recipient] == false, "recipient in blacklist");

        uint256 amount = _claimLimit - claimed[_recipient];
        return (claimed[_recipient], amount);
    }

    // Internal function to recover the signer of a message hash
    function recoverSigner(bytes32 messageHash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);
        return messageHash.recover(v, r, s);
    }

    // Internal function to split the signature into its components
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}