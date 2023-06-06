// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Tezoro {
    using SafeERC20 for ERC20;

    uint8 public constant version = 2;

    address private immutable creator;
    address public immutable tokenAddress;
    address public immutable owner;
    address public immutable beneficiary;
    uint256 public immutable delay;
    uint256 public immutable initTimestamp;
 
    uint8 public state;
    uint256 public timestamp;
    
    error NotOwnerOrCreator();
    error AlreadyRevoked();
    error NotActive();
    error CouldNotRestoreYet();
    error CouldNotRevokeYet();
    error ZeroTransferAmount();
    error CouldNotAbortRestoration();
    error IllegalStateChange();
    error ZeroAddress();
    error ZeroDelay();

    event Restored();
    event StateChanged(uint8 state);

    /**
    * @dev Throws if called by any account other than the owner or creator.
    */
    modifier isOwnerOrCreator() {
        if (msg.sender != creator && msg.sender != owner)
            revert NotOwnerOrCreator();
        _;
    }

    constructor(
        address _creatorAddress,
        address _ownerAddress,
        address _beneficiaryAddress,
        address _tokenAddress,
        uint256 _delay
    ) {
        if (_creatorAddress == address(0)) revert ZeroAddress();
        if (_ownerAddress == address(0)) revert ZeroAddress();
        if (_beneficiaryAddress == address(0)) revert ZeroAddress();
        if (_tokenAddress == address(0)) revert ZeroAddress();
        if (_delay == 0) revert ZeroDelay();
   
        creator = _creatorAddress;
        owner = _ownerAddress;
        beneficiary = _beneficiaryAddress;
        tokenAddress = _tokenAddress;

        delay = _delay;

        state = 0;
        timestamp = block.timestamp + delay;
        initTimestamp = block.timestamp;
    }

    function changeState(uint8 _state) 
        external
        isOwnerOrCreator
    {
        if (state == _state) revert IllegalStateChange();
        if (state >= 3) revert NotActive(); // states (3), (4) are terminal
        if (state == 0) { // from INIT STATE (0)
            if (_state != 1 && _state != 2) revert IllegalStateChange();
            // go to RESTORE STATE (1) (initiate restoration process)  
            //    or REVOKE STATE (2) (initiate rovocation process)
        }
        else if (state == 1) { // from RESTORE STATE (1)
            if (_state == 0 || _state == 2) { 
                if (block.timestamp >= timestamp) revert CouldNotAbortRestoration();
                // go to INIT STATE (0) (abort restoration)  
                //    or REVOKE STATE (2) (initiate rovocation process)
            }
            else if (_state == 3) { 
                if (block.timestamp < timestamp) revert CouldNotRestoreYet();
                // go to RESTORED STATE (3) (restore)
                ERC20 token = ERC20(tokenAddress);
                uint256 allowance = token.allowance(owner, address(this));
                uint256 ownerBalance = token.balanceOf(owner);
                uint256 amountToTransfer = allowance < ownerBalance
                    ? allowance
                    : ownerBalance;
                if (amountToTransfer == 0) revert ZeroTransferAmount();
                ERC20(tokenAddress).safeTransferFrom(
                    owner,
                    beneficiary,
                    amountToTransfer
                );
                emit Restored();
            }
            else revert IllegalStateChange(); 
        }
        else { // from REVOKE STATE (2)
            if (_state == 0) { // go to INIT STATE (0) (abort revocation)
                if (block.timestamp >= timestamp) revert AlreadyRevoked();
            }
            else if (_state == 4) { 
                if (block.timestamp < timestamp) revert CouldNotRevokeYet();
                // go to REVOKED STATE (4) (revoke) - optional 
            }
            else revert IllegalStateChange();
        }
        state = _state;
        timestamp = block.timestamp + delay;
        emit StateChanged(state);
    }
}