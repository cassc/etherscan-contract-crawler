// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GameERC20TreasureSender is Ownable, Pausable {
    using SafeERC20 for IERC20;

    mapping(address => bool) public signers;
    mapping(uint256 => bool) public usedNonce;

    address public controller;
    address public token;

    // Access control
    address public timeLocker;

    event UpChain(address indexed sender, uint256 amount, uint256 nonce);

    constructor(address[] memory _signers, address _token, address _controller, address _timeLocker){
        controller = _controller;
        token = _token;
        timeLocker = _timeLocker;
        for (uint256 i; i < _signers.length; i++)
            signers[_signers[i]] = true;
    }

    receive() external payable {}

    function upChain(
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) public nonceNotUsed(_nonce) whenNotPaused {
        require(verify(msg.sender, address(this), token, _amount, _nonce, this.upChain.selector, _signature), "sign is not correct");
        usedNonce[_nonce] = true;

        IERC20(token).safeTransfer(msg.sender, _amount);
        emit UpChain(msg.sender, _amount, _nonce);
    }

    function verify(
        address _wallet,
        address _this,
        address _token,
        uint256 _amount,
        uint256 _nonce,
        bytes4 _selector,
        bytes memory _signature
    ) public view returns (bool){
        return signers[signatureWallet(_wallet, _this, _token, _amount, _nonce, _selector, _signature)];
    }

    function signatureWallet(
        address _wallet,
        address _this,
        address _token,
        uint256 _amount,
        uint256 _nonce,
        bytes4 _selector,
        bytes memory _signature
    ) internal pure returns (address){
        bytes32 hash = keccak256(abi.encode(_wallet, _this, _token, _amount, _nonce, _selector));
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function unLockEther() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function pause() public onlyController {
        _pause();
    }

    function unpause() public onlyController {
        _unpause();
    }

    function setSigner(address signer, bool isOk) public onlyTimelocker {
        signers[signer] = isOk;
    }

    function setTimeLocker(address timeLocker_) public onlyTimelocker {
        timeLocker = timeLocker_;
    }

    function setController(address _controller) public onlyOwner {
        controller = _controller;
    }

    modifier nonceNotUsed(uint256 _nonce){
        require(!usedNonce[_nonce], "nonce already used");
        _;
    }

    modifier onlyController(){
        require(msg.sender == controller, "only controller");
        _;
    }

    modifier onlyTimelocker() {
        require(msg.sender == timeLocker, "not timelocker");
        _;
    }
}