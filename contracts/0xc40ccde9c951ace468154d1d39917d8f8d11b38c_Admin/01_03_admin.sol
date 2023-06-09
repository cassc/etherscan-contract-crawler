pragma solidity 0.7.6;

import "../../interfaces/IHypervisor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Admin {

    address public admin;
    address public advisor;

    modifier onlyAdvisor {
        require(msg.sender == advisor, "only advisor");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor(address _admin, address _advisor) public {
        admin = _admin;
        advisor = _advisor;
    }

    function rebalance(
        address _hypervisor,
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address _feeRecipient,
        int256 swapQuantity
    ) external onlyAdvisor {
        IHypervisor(_hypervisor).rebalance(_baseLower, _baseUpper, _limitLower, _limitUpper, _feeRecipient, swapQuantity);
    }

    function emergencyWithdraw(
        address _hypervisor,
        IERC20 token,
        uint256 amount
    ) external onlyAdmin {
        IHypervisor(_hypervisor).emergencyWithdraw(token, amount);
    }

    function emergencyBurn(
        address _hypervisor,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external onlyAdmin {
        IHypervisor(_hypervisor).emergencyBurn(tickLower, tickUpper, liquidity);
    }

    function setDepositMax(address _hypervisor, uint256 _deposit0Max, uint256 _deposit1Max) external onlyAdmin {
        IHypervisor(_hypervisor).setDepositMax(_deposit0Max, _deposit1Max);
    }

    function setMaxTotalSupply(address _hypervisor, uint256 _maxTotalSupply) external onlyAdmin {
        IHypervisor(_hypervisor).setMaxTotalSupply(_maxTotalSupply);
    }

    function toggleWhitelist(address _hypervisor) external onlyAdmin {
        IHypervisor(_hypervisor).toggleWhitelist();
    }

    function appendList(address _hypervisor, address[] memory listed) external onlyAdmin {
        IHypervisor(_hypervisor).appendList(listed);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function transferAdvisor(address newAdvisor) external onlyAdmin {
        advisor = newAdvisor;
    }

    function transferHypervisorOwner(address _hypervisor, address newOwner) external onlyAdmin {
        IHypervisor(_hypervisor).transferOwnership(newOwner);
    }

    function rescueERC20(IERC20 token, address recipient) external onlyAdmin {
        require(token.transfer(recipient, token.balanceOf(address(this))));
    }

}