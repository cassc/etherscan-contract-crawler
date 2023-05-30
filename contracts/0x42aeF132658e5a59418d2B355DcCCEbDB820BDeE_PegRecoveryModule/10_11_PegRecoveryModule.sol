// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ICurveMetaPool, ICurvePool } from "../external/CurveInterfaces.sol";
import { IVotiumMerkleStash } from "../external/VotiumInterfaces.sol";
import { RewardPool } from "./RewardPool.sol";

// usdm3crv 0x5B3b5DF2BF2B6543f78e053bD91C4Bdd820929f1
// 3crv 0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7
// zap tx https://etherscan.io/tx/0x4a1c6582675b2582849b3947c63f53e209f320225aa501d0347bb8bae278d365
//BASE_COINS: constant(address[3]) = [
//    0x6B175474E89094C44Da98b954EedeAC495271d0F,  # DAI
//    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,  # USDC
//    0xdAC17F958D2ee523a2206206994597C13D831ec7,  # USDT
//]

contract PegRecoveryModule is RewardPool{
    using SafeERC20 for IERC20;

    struct BaseCoins {
        uint256 dai;
        uint256 usdc;
        uint256 usdt;
    }

    // token addresses
    IERC20 public immutable usdm; // 0x31d4Eb09a216e181eC8a43ce79226A487D6F0BA9

    IERC20 public immutable crv3; // 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490

    IERC20 public immutable dai; // 0x6B175474E89094C44Da98b954EedeAC495271d0F

    IERC20 public immutable usdc; // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48

    IERC20 public immutable usdt; // 0xdAC17F958D2ee523a2206206994597C13D831ec7

    // curve addresses
    ICurveMetaPool public immutable usdm3crv; // 0x5B3b5DF2BF2B6543f78e053bD91C4Bdd820929f1

    ICurvePool public immutable crv3pool; // 0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7

    // usdm deposit info

    uint256 public totalUsdm;

    uint256 public usdmProvided;

    mapping(address => uint256) public usdmShare;

    // 3crv deposit info
    uint256 public totalCrv3;

    uint256 public crv3Provided;

    mapping(address => uint256) public crv3Share;

    // reward info

    constructor(
        IERC20 _usdm,
        IERC20 _crv3,
        IERC20 _dai,
        IERC20 _usdc, 
        IERC20 _usdt,
        ICurveMetaPool _usdm3crv,
        ICurvePool _crv3pool,
        IERC20 _gcrv,
        address _operator
    ) RewardPool(_operator, _gcrv){
        usdm = _usdm;
        crv3 = _crv3;
        dai = _dai;
        usdc = _usdc;
        usdt = _usdt;
        usdm3crv = _usdm3crv;
        crv3pool = _crv3pool;
    }

    // 3crv section

    function deposit3Crv(
        uint256 _deposit
    ) external updateReward(msg.sender) {
        totalCrv3 += _deposit;
        crv3Share[msg.sender] += _deposit;
        crv3.transferFrom(msg.sender, address(this), _deposit);
    }

    function withdraw3Crv(
        uint256 _withdraw
    ) external updateReward(msg.sender) {
        totalCrv3 -= _withdraw;
        crv3Share[msg.sender] -= _withdraw;
        crv3.transfer(msg.sender, _withdraw);
    }

    function depositStable(
        uint256[3] calldata _deposit,
        uint256 _min3crv
    ) external updateReward(msg.sender){
        // convert deposit to 3crv
        if(_deposit[0] > 0) {
            dai.safeTransferFrom(msg.sender, address(this), _deposit[0]);
            dai.safeApprove(address(crv3pool), _deposit[0]);
        }
        if(_deposit[1] > 0) {
            usdc.safeTransferFrom(msg.sender, address(this), _deposit[1]);
            usdc.safeApprove(address(crv3pool), _deposit[1]);
        }
        if(_deposit[2] > 0) {
            usdt.safeTransferFrom(msg.sender, address(this), _deposit[2]);
            usdt.safeApprove(address(crv3pool), _deposit[2]);
        }

        // add liquidity to 3pool right away and hold as 3crv
        uint256 balance = crv3.balanceOf(address(this));
        crv3pool.add_liquidity(
            _deposit,
            _min3crv
        );
        // **vague name to use only 1 variable
        balance = crv3.balanceOf(address(this)) - balance;

        // update storage variables
        totalCrv3 += balance;
        crv3Share[msg.sender] += balance;
    }

    function withdrawStable(
        uint256[3] calldata _withdraw,
        uint256 _3crv_max
    ) external updateReward(msg.sender) {
        // update storage variables
        uint256 balance = crv3.balanceOf(address(this));
        crv3pool.remove_liquidity_imbalance(
            _withdraw,
            _3crv_max
        );
        balance = balance - crv3.balanceOf(address(this));
        totalCrv3 -= balance;
        crv3Share[msg.sender] -= balance;
        if(_withdraw[0] > 0){
            dai.safeTransfer(msg.sender, _withdraw[0]);
        }
        if(_withdraw[1] > 0){
            usdc.safeTransfer(msg.sender, _withdraw[1]);
        }
        if(_withdraw[2] > 0){
            usdt.safeTransfer(msg.sender, _withdraw[2]);
        }
    }

    // usdm section
    function depositUsdm(
        uint256 _usdm
    ) external updateReward(msg.sender) {
        usdmShare[msg.sender] += _usdm;
        totalUsdm += _usdm;
        usdm.transferFrom(msg.sender, address(this), _usdm);
    }

    function withdrawUsdm(
        uint256 _usdm
    ) external updateReward(msg.sender){
        usdmShare[msg.sender] -= _usdm;
        totalUsdm -= _usdm;
        usdm.transfer(msg.sender, _usdm);
    }

    // peg recovery section
    function pairLiquidity(uint256 _amount, uint256 _min_liquidity) external onlyOwner {
        uint256[2] memory amounts = [_amount, _amount];
        usdm.safeApprove(address(usdm3crv), _amount);
        crv3.safeApprove(address(usdm3crv), _amount);
        usdmProvided += _amount;
        crv3Provided += _amount;
        usdm3crv.add_liquidity(amounts, _min_liquidity);
    }

    function removeLiquidity(uint256 _amount, uint256 _max_burn) external onlyOwner {
        uint256[2] memory amounts = [_amount, _amount];
        usdmProvided -= _amount;
        crv3Provided -= _amount;
        usdm3crv.remove_liquidity_imbalance(amounts, _max_burn);
    }

    function sweepTokens() external onlyOwner {
        uint256 usdmLeftover = usdm.balanceOf(address(this)) - (totalUsdm - usdmProvided);
        usdm.transfer(msg.sender, usdmLeftover);
        uint256 crv3Leftover = crv3.balanceOf(address(this)) - (totalCrv3 - crv3Provided);
        crv3.transfer(msg.sender, crv3Leftover);
    }

    // --- votium virtual functions ---
    function balanceOf(address _user) public view override returns(uint256) {
        return usdmShare[_user] + crv3Share[_user];
    }

    function totalSupply() public view override returns(uint256) {
        return totalUsdm + totalCrv3;
    }

    function notRecoverableToken(address _token) public view override returns(bool) {
        return address(crv3) == _token || address(usdm) == _token || address(rewardsToken) == _token || address(usdm3crv) == _token;
    }
}