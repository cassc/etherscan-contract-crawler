pragma solidity ^0.8.0;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2022 Debond Protocol <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDNFT.sol";


contract DNFTBuyer is Ownable {

    enum TIER {TIER0, TIER1}
    mapping(TIER => address) tiers;
    address public mysteryBoxToken;
    bool public onPause = true;
    uint256 public constant TIER1_COMPOSE = 10;

    constructor(address _mysteryBoxToken, address _dnft0, address _dnft1) {
        mysteryBoxToken = _mysteryBoxToken;
        tiers[TIER.TIER0] = _dnft0;
        tiers[TIER.TIER1] = _dnft1;
    }

    modifier notPaused() {
        require(!onPause, "DNFTGovernance Error: cannot process on Pause");
        _;
    }

    function setPauseOn() public onlyOwner {
        require(onPause == false, "Pause Already on ");
        onPause = true;
    }

    function setPauseOff() public onlyOwner {
        require(onPause == true, "Pause Already off");
        onPause = false;
    }


    function composeTier1(address _to, uint[] calldata tokenIds) external notPaused {
        require(tokenIds.length == TIER1_COMPOSE);
        require(IDNFT(tiers[TIER.TIER0]).isOwnerOf(msg.sender, tokenIds), "caller not owner of token ids given");
        _processCompose(_to, tokenIds, TIER.TIER0, TIER.TIER1);
    }

    function claim(address _to, uint quantity) external notPaused {
        IDNFT(tiers[TIER.TIER0]).mint(_to, quantity);
        IERC20(mysteryBoxToken).transferFrom(msg.sender, address(this), quantity);
    }

    function withdrawToOwner() external onlyOwner {
        uint256 _amount = address(this).balance;
        require(_amount > 0, "No ETH to Withdraw");
        payable(_msgSender()).transfer(_amount);
    }

    function _processCompose(address _to, uint[] calldata ids, TIER tierLevelToBurn, TIER tierLevelToMint) internal {
        IDNFT(tiers[tierLevelToBurn]).burn(ids);
        IDNFT(tiers[tierLevelToMint]).mint(_to, 1);
    }








}