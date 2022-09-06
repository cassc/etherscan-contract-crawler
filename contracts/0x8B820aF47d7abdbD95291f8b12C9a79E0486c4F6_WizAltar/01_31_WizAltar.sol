// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './FullSkull.sol';
import './Shroom.sol';
import './EvilWizNFT.sol';

contract WizAltar is Ownable, Pausable, ReentrancyGuard {
    EvilWizNFT private _evilWizContract;
    Shroom private _shroomContract;
    FullSkull private _fullSkullContract;

    address private _shroomBank;
    uint256 private _shroomCost = 100000*(10**18);

    constructor(address wizNftAddress, address shroomAddress, address fullSkullAddress) {
        pause();
        _evilWizContract = EvilWizNFT(wizNftAddress);
        _shroomContract = Shroom(shroomAddress);
        _fullSkullContract = FullSkull(fullSkullAddress);
        _shroomBank = _msgSender();
    }

    function claim(uint256 skullTokenId, uint256 quantity) external nonReentrant whenNotPaused {
        require(_shroomContract.balanceOf(_msgSender()) >= (_shroomCost*quantity), 'Not enough shrooms to mint');
        require(_fullSkullContract.balanceOf(_msgSender(), skullTokenId) >= quantity, 'Not enough skulls to redeem');

        _fullSkullContract.burn(_msgSender(), skullTokenId, quantity);
        _shroomContract.transferFrom(_msgSender(), _shroomBank, (_shroomCost*quantity));
        _evilWizContract.claimFromSkull(_msgSender(), skullTokenId, quantity);
    }

    function setShroomBank(address shroomBankAddress) public onlyOwner {
        _shroomBank = shroomBankAddress;
    }

    function setShroomCost(uint256 shroomCost) public onlyOwner {
        _shroomCost = shroomCost;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}