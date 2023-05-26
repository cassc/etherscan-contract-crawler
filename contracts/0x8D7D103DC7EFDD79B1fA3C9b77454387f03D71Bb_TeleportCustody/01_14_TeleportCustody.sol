// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";

contract TeleportCustody is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _allowedAmount;
    mapping(bytes32 => bool) internal _teleportOutRecord;

    bool private _isFrozen;
    Token private _token;

    event AdminUpdated(address indexed account, uint256 allowedAmount);
    event TeleportOut(
        uint256 amount,
        address indexed ethereumAddress,
        bytes32 indexed flowHash
    );
    event TeleportIn(uint256 amount, bytes8 indexed flowAddress);

    constructor(Token token) {
        _token = token;
    }

    /**
     * @dev Throw if contract is currently frozen.
     */
    modifier notFrozen() {
        require(!_isFrozen, "contract is frozen by owner");

        _;
    }

    /**
     * @dev Returns if the contract is currently frozen.
     */
    function isFrozen() public view returns (bool) {
        return _isFrozen;
    }

    /**
     * @dev Owner freezes the contract.
     */
    function freeze() public onlyOwner {
        _isFrozen = true;
    }

    /**
     * @dev Owner unfreezes the contract.
     */
    function unfreeze() public onlyOwner {
        _isFrozen = false;
    }

    /**
     * @dev Returns the teleport token
     */
    function getToken() public view returns (Token) {
        return _token;
    }

    /**
     * @dev Updates the admin status of an account.
     * Can only be called by the current owner.
     */
    function depositAllowance(address account, uint256 amount)
        public
        onlyOwner
    {
        _allowedAmount[account] = _allowedAmount[account].add(amount);
        emit AdminUpdated(account, amount);
    }

    /**
     * @dev Checks the authorized amount of an admin account.
     */
    function allowedAmount(address account) public view returns (uint256) {
        return _allowedAmount[account];
    }

    /**
     * @dev Teleport admin will teleport out tokens by the other chain's tx hash
     */
    function teleportOut(
        uint256 amount,
        address ethereumAddress,
        bytes32 flowHash
    ) public notFrozen {
        // check admin's allowance
        require(
            _allowedAmount[msg.sender] >= amount,
            "caller does not have sufficient allowance"
        );
        _allowedAmount[msg.sender] = _allowedAmount[msg.sender].sub(amount);
        emit AdminUpdated(msg.sender, _allowedAmount[msg.sender]);

        // checking has tx hash unlocked
        require(
            !_teleportOutRecord[flowHash],
            "the hash has already teleported out"
        );
        _teleportOutRecord[flowHash] = true;

        // mint
        _token.mint(ethereumAddress, amount);
        emit TeleportOut(amount, ethereumAddress, flowHash);
    }

    /**
     * @dev teleport in will burn your token and teleport to other chains
     */
    function teleportIn(uint256 amount, bytes8 flowAddress) public notFrozen {
        _token.burnFrom(msg.sender, amount);
        emit TeleportIn(amount, flowAddress);
    }

    /**
     * @dev Overrides the inherited method from Ownable.
     * Disable ownership resounce.
     */
    function renounceOwnership() public override view onlyOwner {
        revert("ownership cannot be renounced");
    }
}