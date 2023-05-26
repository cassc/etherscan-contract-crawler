// Squishiverse by FourLeafClover (www.squishiverse.com) - $SLIME Bridge

// MMMMMW0dxxxdkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMM0cdKNNKloXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMKolk00kloXMWNK0KKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMXkxxddkXWKdoddxxxxkOKXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMWWMMMXllO000KKKOkxxxxkkkkkkkkkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMKccO000000KKXNNNNNNNXXXK0OkkkkkkOKNMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMN0xocck0000000000KKKKXXXNNNNWWWWNX0kkkkOKWMMMMMMMMMMMMMMMMM
// MMMMMMMMWXkoodkOOO00000000000000000000KKXXNNWWWMWXOxxk0NMMMMMMMMMMMMMM
// MMMMMMWKxlokO000000000000000000000000000000KXWMMMMMMN0kxkKWMMMMMMMMMMM
// MMMMMXxlok0000000000000000000000000000000000KNMMMMMMMMMN0xxONMMMMMMMMM
// MMMW0ook0000000000000000000000000000000000000XWMMMMMMMMMMWKxdONMMMMMMM
// MMWkldO000000000000000000000000000000000000000KXNWMMWNNWMMMWKxd0WMMMMM
// MNxcx00000000000000000000000000000000000000000000KXOc,':ONWWMW0dkNMMMM
// Wkcd0000000000000000Oo;,:dO00000000000000000000000d.    .oXWWMMXxdKMMM
// KloO000000000000000k;    .:k000000000000000000000O:    ;'.dNNWWMNxoKMM
// dck000000000000000Oc    '..lO00000000000000000000O:       ;KNNWWMNxoXM
// lo0000000000000000x'   .:;.;k00000000000000000000Ol.      'ONNNWWMXdxN
// cd0000000000000000x'       ,k000000000000000000000x'      .xNNNNWWM0o0
// cd0000000000000000x'       ;O000000000000000000000Oo.     ;kXNNNNWMNdd
// cd0000000000000000k;      .lO0000000000000000000000Od:'.,ck0KXNNNWWWko
// olO0000000000000000d'     'x000000000000000O0000000000Okxk000XNNNNWMOl
// kcx00000000000000000x:...;xOOxkO00000OOxolc::cclooodolccok000KNNNNWMOl
// XolO00000000000000000OkkkO00kollccclcc:;,,;;;;,,,,,'.,lk00000KNNNNWMko
// M0loO0000000000000000000000000Oko:,''',,,,,,,,,,,;;:okO000000KNNNNWWxd
// MWOloO000000000000000000000000000OkkxdddddddoodddxkO000000000XNNNWMKoO
// MMW0lok00000000000000000000000000000000000000000000000000000KXNNWWNddN
// MMMMXdlxO000000000000000000000000000000000000000000000000000XNNNWNxdXM
// MMMMMWOolxO000000000000000000000000000000000000000000000000KNNNWKxdKMM
// MMMMMMMNOoldO000000000000000000000000000000000000000000000KNNNXkdkNMMM
// MMMMMMMMMN0dooxO00000000000000000000000000000000000000000KXKkxdkXWMMMM
// MMMMMMMMMMMWXOxdooxkO0000000000000000000000000000000Okxxdxxxk0NMMMMMMM
// MMMMMMMMMMMMMMMNKOxdddoooddxxxxkkkkkkkxxxxxddddoooodddxkOKNWMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWNKOxdollccccccccccccccccllodxk0KNWMMMMMMMMMMMMMMMM

// Development help from @lozzereth (www.allthingsweb3.com)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error BridgePaused();
error InvalidClaimSignature();
error InvalidClaimNonce();
error CancellingDisabled();

contract BridgeSlime is Ownable {
    using ECDSA for bytes32;

    // Oracle to sign the addresses
    address public oracleAddress;

    // Token and chain we are bridging
    IERC20 public immutable tokenAddress;

    // Bridge Pausibility
    bool public paused;

    // Bridge Fee
    uint256 public feePercent = 100;

    // Claims nonces stored against addresses
    mapping(address => uint256) public claimNonce;

    // Cancellable
    bool public cancellable;

    // Events
    event BridgedToken(address from, uint256 amount, uint256 nonce);
    event CancelClaim(address from, uint256 oldBlock, uint256 newBlock);

    constructor(IERC20 _tokenAddress, address _oracleAddress) {
        tokenAddress = _tokenAddress;
        oracleAddress = _oracleAddress;
    }

    /**
     * @dev Swap a token into the the bridge
     */
    function swap(uint256 amount, uint256 nonce) external notPaused {
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        emit BridgedToken(msg.sender, amount, nonce);
    }

    /**
     * @dev Claim an amount from the bridge
     */
    function claim(
        address recipient,
        uint256 amount,
        uint256 oldBlock,
        uint256 newBlock,
        bytes calldata signature
    ) external notPaused hasValidNonce(recipient, oldBlock, newBlock) {
        bytes32 data = keccak256(
            abi.encodePacked(recipient, amount, oldBlock, newBlock)
        );
        if (data.toEthSignedMessageHash().recover(signature) != oracleAddress) {
            revert InvalidClaimSignature();
        }
        claimNonce[recipient] = newBlock;
        uint256 finalAmount = ((amount * (10000 - feePercent)) / 10000);
        IERC20(tokenAddress).transfer(recipient, finalAmount);
    }

    modifier hasValidNonce(
        address _recipient,
        uint256 _oldBlock,
        uint256 _newBlock
    ) {
        if (
            _oldBlock != claimNonce[_recipient] ||
            _oldBlock >= block.number ||
            _newBlock <= _oldBlock
        ) {
            revert InvalidClaimNonce();
        }
        _;
    }

    /**
     * @dev Cancels a claim for an address
     */
    function cancelClaimAdmin(
        address _address,
        uint256 oldBlock,
        uint256 newBlock
    ) external onlyOwner hasValidNonce(_address, oldBlock, newBlock) {
        claimNonce[_address] = newBlock;
        emit CancelClaim(_address, oldBlock, newBlock);
    }

    /**
     * @dev Cancel claim as a user
     */
    function cancelClaim(uint256 oldBlock, uint256 newBlock)
        external
        cancelEnabled
        hasValidNonce(msg.sender, oldBlock, newBlock)
    {
        claimNonce[msg.sender] = newBlock;
        emit CancelClaim(msg.sender, oldBlock, newBlock);
    }

    modifier cancelEnabled() {
        if (!cancellable) {
            revert CancellingDisabled();
        }
        _;
    }

    /**
     * @dev Toggles the cancellable state
     */
    function toggleCancellable() external onlyOwner {
        cancellable = !cancellable;
    }

    /**
     * @dev Set the oracle address to verify the data
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
    }

    /**
     * @dev Set pause state of the bridge
     */
    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    modifier notPaused() {
        if (paused) revert BridgePaused();
        _;
    }

    /**
     * @dev Adjustable fee for the bridge
     */
    function setFeePercentage(uint256 _percent) external onlyOwner {
        require(_percent >= 0 && _percent <= 10000, "Invalid Percent");
        feePercent = _percent;
    }

    /**
     * @dev Allows contract owner to withdraw token from the contract
     */
    function withdrawTokens(uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }
}