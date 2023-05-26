// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Governable.sol";
import "./CollectableDust.sol";
import "../Interfaces/IWHAsset.sol";
import "../Interfaces/Keep3r/IKeep3rV1.sol";
import "../Interfaces/Keep3r/IChainLinkFeed.sol";
import "../Interfaces/Keep3r/IKeep3rV1Helper.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract WhiteKeep3r is Governable, CollectableDust {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IKeep3rV1 public keep3r = IKeep3rV1(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
    IChainLinkFeed public immutable ETHUSD = IChainLinkFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    IChainLinkFeed public constant FASTGAS = IChainLinkFeed(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);
    
    uint public constant gasUsed = 100_000;
    address public job;

    IERC20 public token; 

    constructor(IERC20 _token) public Governable(msg.sender) CollectableDust() {
        token = _token;
    }

    function unwrapAll(address whAsset, uint[] calldata tokenIds) external paysKeeper(tokenIds) {
        IWHAssetv2(whAsset).autoUnwrapAll(tokenIds, address(this));
    }

    function refillCredit() external onlyGovernor {
        uint balance = token.balanceOf(address(this));
        keep3r.addCredit(address(token), job, balance);
    }

    function _isKeeper() internal {
        require(tx.origin == msg.sender, "keep3r::isKeeper:keeper-is-a-smart-contract");
        require(keep3r.isKeeper(msg.sender), "keep3r::isKeeper:keeper-is-not-registered");
    }

    function getRequestedPayment() public view returns(uint){
        uint256 gasPrice = Math.min(tx.gasprice, uint256(FASTGAS.latestAnswer()));

        return gasPrice.mul(gasUsed).mul(uint(ETHUSD.latestAnswer())).div(1e20);
    }

    function getRequestedPaymentETH() public view returns(uint){
        uint256 gasPrice = Math.min(tx.gasprice, uint256(FASTGAS.latestAnswer()));

        return gasPrice.mul(gasUsed);
    }

    function setJob(address newJob) external onlyGovernor {
        job = newJob;
    }

    modifier paysKeeper(uint[] calldata tokenIds) {
        _isKeeper();
        
        _; // function executed by keep3r

        uint paidReward = tokenIds.length.mul(getRequestedPayment());

        keep3r.receipt(address(token), msg.sender, paidReward);
    }

    function setKeep3r(address _keep3r) external onlyGovernor {
        token.safeApprove(address(keep3r), 0);
        keep3r = IKeep3rV1(_keep3r);
        token.safeApprove(address(_keep3r), type(uint256).max);
    }

    // Governable
    function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
        _setPendingGovernor(_pendingGovernor);
    }

    function acceptGovernor() external override onlyPendingGovernor {
        _acceptGovernor();
    }

    // Collectable Dust
    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external override onlyGovernor {
        _sendDust(_to, _token, _amount);
    }

}