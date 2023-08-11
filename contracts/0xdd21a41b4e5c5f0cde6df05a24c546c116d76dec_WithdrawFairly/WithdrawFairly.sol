/**
 *Submitted for verification at Etherscan.io on 2023-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IBlurPool {
    function withdraw(uint256 amount) external;
}

/**
 * @title WithdrawFairly
 * @author 0x0
 */
contract WithdrawFairly {
    error Unauthorized();
    error ZeroBalance();
    error TransferFailed();

    struct Part {
        address wallet;
        uint16 royaltiesPart;
    }

    address private blurPool = 0x0000000000A39bb272e79075ade125fd351887Ac;

    Part[] public parts;
    mapping(address => bool) public callers;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        
        parts.push(Part(0xecB4278af1379c38Eab140063fFC426f05FEde28, 20));
        callers[0xecB4278af1379c38Eab140063fFC426f05FEde28] = true;
        // Sensei
        parts.push(Part(0xE1580cA711094CF2888716a54c5A892245653435, 50));
        // AJay
        parts.push(Part(0x963363fc0BDf5D4b48Ef3dc5CA374e909f13e730, 10));
        // Fud
        parts.push(Part(0xd3b886134F8c265A27b539dF12907bB88Ee6b094, 10));
        // Brongis
        parts.push(Part(0x5074B0Ee74e886b8e88D5d0Ef67592825dF44D81, 5));
        // Camino
        parts.push(Part(0x95B5b3c1Dc12c6124B077133aBc86e809382934E, 5));
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function setCaller(address addr, bool allow) external onlyOwner {
        callers[addr] = allow;
    }

    function setPart(uint256 index, Part calldata part) external onlyOwner {
        parts[index] = part;
    }

    function setBlurPool(address addr) external onlyOwner {
        blurPool = addr;
    }

    function shareETHRoyaltiesPart() external {
        if (!callers[msg.sender]) revert Unauthorized();

        uint256 balance = address(this).balance;

        if (balance == 0) revert ZeroBalance();

        for (uint256 i; i < parts.length;) {
            Part memory part = parts[i];

            unchecked {
                if (part.royaltiesPart != 0) {
                    _withdraw(
                        part.wallet,
                        balance * part.royaltiesPart / 100
                    );
                }

                ++i;
            }
        }
    }

     function shareTokenRoyaltiesPart(address token) external {
        if (!callers[msg.sender]) revert Unauthorized();

        IERC20 tokenContract = IERC20(token);

        uint256 balance = tokenContract.balanceOf(address(this));

        if (balance == 0) revert ZeroBalance();

        for (uint256 i; i < parts.length;) {
            Part memory part = parts[i];

            if (part.royaltiesPart != 0) {
                if (!tokenContract.transfer(
                    part.wallet,
                    balance * part.royaltiesPart / 100
                )) revert TransferFailed();
            }

            unchecked {
                ++i;
            }
        }
    }

    function withdrawFromBlurPool() external {
        IBlurPool(blurPool).withdraw(IERC20(blurPool).balanceOf(address(this)));
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");

        if (!success) revert TransferFailed();
    }

    receive() external payable {}

}