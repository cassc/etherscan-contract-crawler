//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ILLCGift.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LLCGiftV2 is Ownable {
    ILLCGift public immutable LLC_GIFT;

    mapping(address => bool) public minters;

    constructor(address _llcGift) {
        LLC_GIFT = ILLCGift(_llcGift);
    }

    function addMinters(address[] calldata _minters) external onlyOwner {
        uint256 length = _minters.length;
        for (uint256 i = 0; i < length; i++) {
            minters[_minters[i]] = true;
        }
    }

    function removeMinters(address[] calldata _minters) external onlyOwner {
        uint256 length = _minters.length;
        for (uint256 i = 0; i < length; i++) {
            minters[_minters[i]] = false;
        }
    }

    /// @dev Add claimer to the list of claimers
    function addClaimer(address _claimer, uint256 _amount)
        external
        onlyMinters
    {
        require(_claimer != address(0), "LLCGift: Invalid address");
        require(_amount > 0, "LLCGift: Invalid amount");
        LLC_GIFT.addClaimer(_claimer, _amount);
    }

    function claimers(address _claimer) external view returns (uint256) {
        return LLC_GIFT.claimers(_claimer);
    }

    function claimStatuses(address _claimer) external view returns (uint256) {
        return LLC_GIFT.claimStatuses(_claimer);
    }

    modifier onlyMinters() {
        require(minters[_msgSender()], "LLCGift: Only minter can call");
        _;
    }
}