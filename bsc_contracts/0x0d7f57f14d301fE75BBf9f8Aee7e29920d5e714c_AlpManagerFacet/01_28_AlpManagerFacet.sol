// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Pausable} from "../security/Pausable.sol";
import {LibVault} from  "../libraries/LibVault.sol";
import {LibCexVault} from  "../libraries/LibCexVault.sol";
import {IAlpManager} from "../interfaces/IAlpManager.sol";
import {LibAlpManager} from  "../libraries/LibAlpManager.sol";
import {LibStakeReward} from  "../libraries/LibStakeReward.sol";
import {ReentrancyGuard} from "../security/ReentrancyGuard.sol";
import {LibAccessControlEnumerable} from  "../libraries/LibAccessControlEnumerable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

interface IAlp {
    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract AlpManagerFacet is ReentrancyGuard, Pausable, IAlpManager {

    using Address for address;
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    function initAlpManagerFacet(address alpToken, uint256 safeguard_) external {
        LibAccessControlEnumerable.checkRole(LibAccessControlEnumerable.DEPLOYER_ROLE);
        require(alpToken != address(0), "AlpManagerFacet: Invalid alpToken");
        LibAlpManager.initialize(alpToken, safeguard_);
    }

    function ALP() public view override returns (address) {
        return LibAlpManager.alpManagerStorage().alp;
    }

    function coolingDuration() external view override returns (uint256) {
        return LibAlpManager.alpManagerStorage().coolingDuration;
    }

    function setCoolingDuration(uint256 coolingDuration_) external override {
        LibAccessControlEnumerable.checkRole(ADMIN_ROLE);
        LibAlpManager.AlpManagerStorage storage ams = LibAlpManager.alpManagerStorage();
        ams.coolingDuration = coolingDuration_;
    }

    function safeguard() external view override returns (uint256) {
        return LibAlpManager.alpManagerStorage().safeguard;
    }

    function setSafeguard(uint256 safeguard_) external override {
        LibAccessControlEnumerable.checkRole(ADMIN_ROLE);
        LibAlpManager.AlpManagerStorage storage ams = LibAlpManager.alpManagerStorage();
        ams.safeguard = safeguard_;
    }

    function mintAlp(address tokenIn, uint256 amount, uint256 minAlp, bool stake) external whenNotPaused nonReentrant override {
        require(tokenIn != BUSD, "AlpManagerFacet: BUSD mint ALP is not supported at this time");
        require(amount > 0, "AlpManagerFacet: invalid amount");
        (int256 totalValueUsd, uint256 blockNo) = LibCexVault.getCexTotalValueUsd();
        if (_needPause(blockNo)) {
            _pause();
        } else {
            address account = msg.sender;
            uint256 alpAmount = LibAlpManager.mintAlp(account, tokenIn, amount, LibAlpManager.alpPrice(totalValueUsd, blockNo));
            require(alpAmount >= minAlp, "LibLiquidity: insufficient ALP output");
            _mint(account, tokenIn, amount, alpAmount, stake);
        }
    }

    function mintAlpBNB(uint256 minAlp, bool stake) external payable whenNotPaused nonReentrant override {
        uint amount = msg.value;
        require(amount > 0, "AlpManagerFacet: invalid msg.value");
        (int256 totalValueUsd, uint256 blockNo) = LibCexVault.getCexTotalValueUsd();
        if (_needPause(blockNo)) {
            _pause();
        } else {
            address account = msg.sender;
            uint256 alpAmount = LibAlpManager.mintAlpBNB(account, amount, LibAlpManager.alpPrice(totalValueUsd, blockNo));
            require(alpAmount >= minAlp, "LibLiquidity: insufficient ALP output");
            _mint(account, LibVault.WBNB(), amount, alpAmount, stake);
        }
    }

    function _mint(address account, address tokenIn, uint256 amount, uint256 alpAmount, bool stake) private {
        IAlp(ALP()).mint(account, alpAmount);
        emit MintAlp(account, tokenIn, amount, alpAmount);
        if (stake) {
            LibStakeReward.stake(alpAmount);
        }
    }

    function burnAlp(address tokenOut, uint256 alpAmount, uint256 minOut, address receiver) external whenNotPaused nonReentrant override {
        require(alpAmount > 0, "AlpManagerFacet: invalid alpAmount");
        (int256 totalValueUsd, uint256 blockNo) = LibCexVault.getCexTotalValueUsd();
        if (_needPause(blockNo)) {
            _pause();
        } else {
            address account = msg.sender;
            uint256 amountOut = LibAlpManager.burnAlp(account, tokenOut, alpAmount, LibAlpManager.alpPrice(totalValueUsd, blockNo), receiver);
            require(amountOut >= minOut, "LibLiquidity: insufficient token output");
            IAlp(ALP()).burnFrom(account, alpAmount);
            emit BurnAlp(account, receiver, tokenOut, alpAmount, amountOut);
        }
    }

    function burnAlpBNB(uint256 alpAmount, uint256 minOut, address payable receiver) external whenNotPaused nonReentrant override {
        require(alpAmount > 0, "AlpManagerFacet: invalid alpAmount");
        (int256 totalValueUsd, uint256 blockNo) = LibCexVault.getCexTotalValueUsd();
        if (_needPause(blockNo)) {
            _pause();
        } else {
            address account = msg.sender;
            uint256 amountOut = LibAlpManager.burnAlpBNB(account, alpAmount, LibAlpManager.alpPrice(totalValueUsd, blockNo), receiver);
            require(amountOut >= minOut, "LibLiquidity: insufficient BNB output");
            IAlp(ALP()).burnFrom(account, alpAmount);
            emit BurnAlp(account, receiver, LibVault.WBNB(), alpAmount, amountOut);
        }
    }

    function _needPause(uint256 blockNo) private view returns (bool) {
        return block.number > blockNo + LibAlpManager.alpManagerStorage().safeguard;
    }

    function alpPrice() external view override returns (uint256){
        (int256 totalValueUsd, uint256 blockNo) = LibCexVault.getCexTotalValueUsd();
        return LibAlpManager.alpPrice(totalValueUsd, blockNo);
    }

    function lastMintedTimestamp(address account) external view override returns (uint256) {
        return LibAlpManager.alpManagerStorage().lastMintedAt[account];
    }
}