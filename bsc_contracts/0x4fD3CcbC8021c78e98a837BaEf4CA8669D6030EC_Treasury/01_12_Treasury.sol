// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./utils/Withdrawable.sol";

contract Treasury is Ownable, Withdrawable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    event TransferredIn(address indexed from, uint256 amount);
    event TransferredOut(
        uint256 indexed id,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 deadline
    );
    event Paused();
    event Unpaused();

    bool public paused;
    address public truthHolder;
    IERC20 public treasuryToken;
    mapping(uint256 => uint256) public transferHistory;

    constructor(address _truthHolder, address _treasuryToken) {
        paused = false;
        truthHolder = _truthHolder;
        treasuryToken = IERC20(_treasuryToken);
    }

    modifier notPaused() {
        require(!paused, "paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "not paused");
        _;
    }

    function transferIn(uint256 amount_)
        external
        notPaused
        returns (address from, uint256 amount)
    {
        require(
            treasuryToken.balanceOf(msg.sender) >= amount_,
            "transferIn: INSUFFICIENT BALANCE"
        );
        treasuryToken.safeTransferFrom(msg.sender, address(this), amount_);
        emit TransferredIn(msg.sender, amount_);
        return (msg.sender, amount_);
    }

    /**
     * @notice It allows the user to transfer the deposited amount from the contract to an address
     * @param message: the string containing the encoded arguments
     * @param signature: the signature for the message
     */
    function transferOut(bytes calldata message, bytes calldata signature)
        external
        notPaused
    {
        address recoveredSource = source(message, signature);
        require(
            recoveredSource == truthHolder,
            "transferOut: only accept truthHolder signed message"
        );
        uint256 id;
        address payable to;
        address currency;
        uint256 amount;
        uint256 deadline;

        (id, to, currency, amount, deadline) = abi.decode(
            message,
            (uint256, address, address, uint256, uint256)
        );

        require(transferHistory[id] == 0, "transferOut: already claimed");
        require(
            currency == address(treasuryToken),
            "transferOut: currency not supported"
        );
        require(
            treasuryToken.balanceOf(address(this)) >= amount,
            "transferOut: not enough currency balance"
        );
        require(
            block.timestamp < deadline,
            "transferOut: already passed deadline"
        );

        transferHistory[id] = block.number;
        treasuryToken.safeTransfer(to, amount);
        emit TransferredOut(id, msg.sender, to, amount, deadline);
    }

    function source(bytes memory message, bytes memory signature)
        public
        pure
        returns (address)
    {
        return ECDSA.toEthSignedMessageHash(message).recover(signature);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unPause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    function seTtruthHolder(address _truthHolder)
        external
        onlyOwner
        whenPaused
    {
        truthHolder = _truthHolder;
    }

    /**
     * @notice It allows the admin to recover ethers stored in the contract
     * @param to: the address of the wallett to receive the tokens
     * @dev This function is only callable by admin or the contract migrator.
     */
    function withdrawEthers(address to) external onlyOwner whenPaused {
        super._withdrawEthers(to);
    }

    /**
     * @notice It allows the admin to recover all the ERC20 tokens sent accidentally to the contract
     * @param _token: the address of the token to recover
     * @param to: the address of the wallett to receive the tokens
     * @dev This function is only callable by admin or the contract migrator.
     */
    function withdrawTokenAll(address _token, address to)
        external
        onlyOwner
        whenPaused
        returns (bool)
    {
        return super._withdrawTokenAll(_token, to);
    }
}