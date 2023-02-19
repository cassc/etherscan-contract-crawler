// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
* @dev Interface to interact with Quacks contract
* - Limited functionality as needed
**/

interface IERC20 {
    /**
     * @dev // TODO
     */
    function mint(address account, uint256 amount) external;
}

error SignatureExpired();
error AlreadyClaimedError();
error SenderIsNotTheClaimerError();
error InvalidSignatureError();

// TODO: Set custom errors
contract Staking is OwnableUpgradeable, PausableUpgradeable {
    event Claimed(address indexed claimer, uint256 claimAmount, uint256 expirationTime);

    using ECDSA for bytes32;

    // ERC20
    IERC20 public erc20;

    // address => timestamp
    mapping(address => uint256) public stakingTimeByAddress;

    address public validSigner;

    uint256 constant COOL_DOWN_PERIOD = 86400; // One day in seconds

    function initialize(address erc20Address) initializer public {
        erc20 = IERC20(erc20Address);
        __Ownable_init();
        __Pausable_init();
    }

    function isValidSignature(
        address claimer,
        uint256 claimAmount,
        uint256 expirationTime,
        bytes memory signature
    ) private view returns(bool) {
        require(signature.length == 65, "Unsupported signature length");
        bytes32 message = keccak256(abi.encodePacked(claimer, claimAmount, expirationTime));
        return message.recover(signature) == validSigner;
    }

    function claimRewards(address claimer, uint256 claimAmount, uint256 expirationTime, bytes calldata signature) external whenNotPaused {
        if(block.timestamp >= expirationTime) {
            revert SignatureExpired();
        }
        if(stakingTimeByAddress[claimer] + COOL_DOWN_PERIOD >= block.timestamp) {
            revert AlreadyClaimedError();
        }
        if(_msgSender() != claimer) {
            revert SenderIsNotTheClaimerError();
        }
        if(!isValidSignature(
            claimer,
            claimAmount,
            expirationTime,
            signature
        )) {
            revert InvalidSignatureError();
        }
        stakingTimeByAddress[claimer] = block.timestamp;
        // Mint the amount
        erc20.mint(claimer, claimAmount);
        emit Claimed(claimer, claimAmount, expirationTime);

    }
    function setValidSigner(address _validSigner) external onlyOwner {
        require(_validSigner != address(0), "The zero address can't be a valid signer");
        validSigner = _validSigner;
    }


    function pause() public onlyOwner {
        super._pause();
    }

    function unpause() public onlyOwner {
        super._unpause();
    }

}