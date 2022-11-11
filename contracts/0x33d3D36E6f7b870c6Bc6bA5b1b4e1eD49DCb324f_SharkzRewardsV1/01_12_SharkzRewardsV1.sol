// SPDX-License-Identifier: MIT

/**
       █                                                                        
▐█████▄█ ▀████ █████  ▐████    ████████    ███████████  ████▌  ▄████ ███████████
▐██████ █▄ ▀██ █████  ▐████   ██████████   ████   ████▌ ████▌ ████▀       ████▀ 
  ▀████ ███▄ ▀ █████▄▄▐████  ████ ▐██████  ████▄▄▄████  █████████        ████▀  
▐▄  ▀██ █████▄ █████▀▀▐████ ▄████   ██████ █████████    █████████      ▄████    
▐██▄  █ ██████ █████  ▐█████████▀    ▐█████████ ▀████▄  █████ ▀███▄   █████     
▐████  █▀█████ █████  ▐████████▀        ███████   █████ █████   ████ ███████████
       █
 *******************************************************************************
 * Sharkz Rewards (prize claiming program)
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../lib-upgradeable/sharkz/AdminableUpgradeable.sol";
import "../lib-upgradeable/712/EIP712WhitelistTypedUpgradeable.sol";

contract SharkzRewardsV1 is Initializable, UUPSUpgradeable, AdminableUpgradeable, EIP712WhitelistTypedUpgradeable {
    // Implementation version number
    function version() external pure virtual returns (string memory) { return "1.0.0"; }

    struct AddressClaim {
        // non-zero value represent prize claimed
        uint8 claimed;
        // last claim time
        uint40 claimTime;
        // extra data slot
        uint208 aux;
    }

    // Control the claiming is started or paused
    bool public claimStarted;

    // Current claim event id
    uint256 public claimEventId;

    // @dev Solidity can not clear all mapping data by `delete`, thus, 
    // we clear all claim data by changing `uint256` claimEventId as index key to whole mapping
    mapping(uint256 => mapping(address => AddressClaim)) public addressClaim;

    // Init this upgradeable contract
    function initialize() public initializer onlyProxy {
        __Adminable_init();
        __EIP712WhitelistTyped_init();
    }

    // Only admins can upgrade the contract
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    // do not allow contract to call
    modifier callerIsWallet() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Returns given wallet address is not claimed for prize
    function checkPrizeNotClaimed(address _addr) public view returns(bool) {
        return addressClaim[claimEventId][_addr].claimed == 0;
    }
    
    // EOA Wallet owner can claim the prize once only
    function claimPrize(bytes calldata _signature, uint256 _prize) 
        external 
        payable 
        callerIsWallet 
    {
        string memory prizeData = string(abi.encodePacked(_toString(claimEventId), ":", _toString(_prize)));

        require(claimStarted, "Prize claim is not started");
        require(verifySignature(_signature, prizeData), "Invalid prize claim signature");
        require(checkPrizeNotClaimed(msg.sender), "Prize already claimed");

        // store claim data
        AddressClaim memory data;
        data.claimed = 1;
        data.claimTime = uint40(block.timestamp);
        addressClaim[claimEventId][msg.sender] = data;

        // prize delivery
        (bool success, ) = msg.sender.call{value: _prize}("");
        require(success, "Claim prize failed");
    }
    
    // Deposit ethers to contract
    function deposit() external payable {}

    // (Admin) Reset one wallet claim data, allowing it to claim again
    function clearOneClaim(address _addr) external onlyAdmin {
        delete addressClaim[claimEventId][_addr];
    }

    // (Admin) Start next claim cycle (also reset all address claim data)
    function startNextClaimCycle() external onlyAdmin {
        claimEventId += 1;
    }

    // (Admin) Set to particular claim cycle
    function setClaimCycle(uint256 _id) external onlyAdmin {
        claimEventId = _id;
    }

    // (Admin) Start claim
    function startClaim() external onlyAdmin {
        claimStarted = true;
    }

    // (Admin) Pause claim
    function pauseClaim() external onlyAdmin {
        claimStarted = false;
    }

    // (Admin) Withdraw all funds in prize pool
    function withdraw(address payable _to) external onlyAdmin {
        // Call returns a boolean value indicating success or failure.
        uint256 balance = address(this).balance;
        (bool success, ) = _to.call{value: balance}("");
        require(success, "Withdraw failed");
    }

    // Converts `uint256` to ASCII `string`
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}