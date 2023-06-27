// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IWATTs {
	function burn(address _from, uint256 _amount) external;
    function burnClaimable(address _from, uint256 _amount) external;
    function balanceOf(address user) external view returns (uint256);
    function mintClaimable(address _to, uint256 _amount) external;
}

interface ITransferExtenderV2 {
    function WATTSOWNER_seeClaimableBalanceOfUser(address user) external view returns (uint256);
    function transfer(
        uint256 amount,
        address recipient
    ) external;
}

contract SlotieEthBscBridge is Ownable, Pausable {
    using ECDSA for bytes32;

    IWATTs public watts;
    ITransferExtenderV2 public transferExtender;
    address public signer;

    mapping (bytes32 => bool) public isUsed;
    mapping (address => bool) public operators;

    modifier onlyOperator{
        require(operators[tx.origin] || (tx.origin == owner()), "CALLER IS NOT THE OPERATOR");
        _;
    }

    constructor(
        address wattsAddress,
        address transferExtenderAddress,
        address signerAddress
    ) {
        watts = IWATTs(wattsAddress);
        transferExtender = ITransferExtenderV2(transferExtenderAddress);
        signer = signerAddress;
        _pause();
    }

    event WattsBridged(address indexed user, uint256 amount, uint256 timestamp);
    event WattsReceived(address indexed user, bytes32 indexed randomHex, uint256 amount, uint256 timestamp);

    function setWattsAddress(address newWattsAddress) external onlyOwner {
        require(isContract(newWattsAddress), "NOT CONTRACT ADDRESS");
        watts = IWATTs(newWattsAddress);
    }

    function setSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function bridgeWatts(uint256 amount) external whenNotPaused {
        require(amount > 0, "ZERO AMOUNT PASSED");
        require(watts.balanceOf(msg.sender) >= amount, "INSUFFICIENT TOKEN BALANCE");

        _burnWatts(amount);

        emit WattsBridged(msg.sender, amount, block.timestamp);
    }

    function receiveWatts(uint256 amount, bytes32 randomHex, bytes memory signature) external whenNotPaused {
        _handleReceive(msg.sender, amount, randomHex, signature);
    }

    function operatorReceivewatts(
        address user,
        uint256 amount,
        bytes32 randomHex,
        bytes memory signature
    ) external onlyOperator whenNotPaused {
        _handleReceive(user, amount, randomHex, signature);
    }

    function addOperator(address _newOperator, bool status) external onlyOwner {
        operators[_newOperator] = status;
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function _handleReceive(address user, uint256 amount, bytes32 randomHex, bytes memory signature) internal {
        require(!isUsed[randomHex], "TOKENS ALREADY CLAIMED");
        require(verifySignature(user, amount, randomHex, signature), "SIGNATURE NOT VERIFIED");

        isUsed[randomHex] = true;
        watts.mintClaimable(user, amount);

        emit WattsReceived(user, randomHex, amount, block.timestamp);
    }

    function verifySignature(address _toAddress, uint _amount, bytes32 _randomHex, bytes memory signature) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(_toAddress, _amount, _randomHex));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address result = ECDSA.recover(message, signature);
        return (signer == result);
    }

    function _burnWatts(uint256 amount) internal {
        require(watts.balanceOf(msg.sender) >= amount, "User does not have enough balance");
        require(amount > 0, "Cannot burn zero watts");
        
        uint256 claimableBalance = transferExtender.WATTSOWNER_seeClaimableBalanceOfUser(msg.sender);
        uint256 burnFromClaimable = claimableBalance >= amount ? amount : claimableBalance;
        uint256 burnFromBalance = claimableBalance >= amount ? 0 : amount - claimableBalance;

        if (claimableBalance > 0) {
            watts.burnClaimable(msg.sender, burnFromClaimable);
        }
        
        if (burnFromBalance > 0) {
            watts.burn(msg.sender, burnFromBalance);
        }
    }
}