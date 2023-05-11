// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract Distributor is Ownable {
    using ECDSA for bytes32;  

    IERC20 public token;

    address public signer;

    uint256 public constant MAX_ADDRESSES = 30_000;
    uint256 public constant MAX_TOKEN = 3_937_500_000_000_000 * 1e6;
    uint256 public constant AMOUNT_CLAIM = 105_000_000_000 * 1e6;

    mapping(uint256 => bool) public _usedNonce;
    mapping(address => bool) public _claimedUser;
    mapping(address => uint256) public inviteRewards;

    uint256 public claimedSupply = 0;
    uint256 public claimedCount = 0;
    uint256 public claimedPercentage = 0;

    mapping(address => uint256) public inviteUsers;

    event Claim(address indexed user, uint128 nonce, uint256 amount, address referrer, uint timestamp);

    function claim(uint128 nonce, bytes calldata signature, address referrer) public {
        require(_usedNonce[nonce] == false, "SPACEPEPE: nonce already used");
        require(_claimedUser[_msgSender()] == false, "SPACEPEPE: already claimed");

        _claimedUser[_msgSender()] = true;
        require(isValidSignature(nonce, signature), "SPACEPEPE: only auth claims");
        
        _usedNonce[nonce] = true;

        require(claimedCount < MAX_ADDRESSES, "SPACEPEPE: airdrop has ended");

        uint256 amount = AMOUNT_CLAIM;
        uint256 refAmount = 0;

        if (referrer != address(0) && referrer != _msgSender()) {
            refAmount = amount * 50 / 1000;
            token.transfer(referrer, refAmount);
            inviteRewards[referrer] += refAmount;
            inviteUsers[referrer]++;
        }

        uint256 claimAmount = amount - refAmount;
        token.transfer(_msgSender(), claimAmount);

        claimedCount++;
        claimedSupply += AMOUNT_CLAIM;

        if (claimedCount > 0) {
            claimedPercentage = (claimedCount * 100) / MAX_ADDRESSES;
        }

        emit Claim(_msgSender(), nonce, amount, referrer, block.timestamp);
    }

    function setSigner(address val) public onlyOwner() {
        require(val != address(0), "SPACEPEPE: val is the zero address");
        signer = val;
    }

    function setToken(address _tokenAddress) public onlyOwner() {
        token = IERC20(_tokenAddress);
    }

    function isValidSignature(
        uint128 nonce,
        bytes memory signature
    ) view internal returns (bool) {
        bytes32 data = keccak256(abi.encodePacked(address(this), _msgSender(), nonce));
        return signer == data.toEthSignedMessageHash().recover(signature);
    }
	
	function withdrawToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }
}