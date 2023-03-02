// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../interfaces/IHypervisor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Admin

contract Admin {

    address public admin;
    mapping(address => address) public rebalancers;
    mapping(address => address) public advisors;

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyAdvisor(address hypervisor) {
        require(msg.sender == advisors[hypervisor], "only advisor");
        _;
    }

    modifier onlyRebalancer(address hypervisor) {
        require(msg.sender == rebalancers[hypervisor], "only rebalancer");
        _;
    }

    constructor(address _admin) {
        admin = _admin;
    }

    /// @param _hypervisor Hypervisor Address
    /// @param _baseLower The lower tick of the base position
    /// @param _baseUpper The upper tick of the base position
    /// @param _limitLower The lower tick of the limit position
    /// @param _limitUpper The upper tick of the limit position
    /// @param _feeRecipient Address of recipient of 10% of earned fees since last rebalance
    function rebalance(
        address _hypervisor,
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address _feeRecipient,
        uint256[4] memory inMin, 
        uint256[4] memory outMin
    ) external onlyRebalancer(_hypervisor) {
        IHypervisor(_hypervisor).rebalance(_baseLower, _baseUpper, _limitLower, _limitUpper, _feeRecipient, inMin, outMin);
    }

    /// @notice Pull liquidity tokens from liquidity and receive the tokens
    /// @param _hypervisor Hypervisor Address
    /// @param tickLower lower tick
    /// @param tickUpper upper tick
    /// @param shares Number of liquidity tokens to pull from liquidity
    /// @return base0 amount of token0 received from base position
    /// @return base1 amount of token1 received from base position
    function pullLiquidity(
      address _hypervisor,
      int24 tickLower,
      int24 tickUpper,
      uint128 shares,
      uint256[2] memory minAmounts
    ) external onlyRebalancer(_hypervisor) returns(
        uint256 base0,
        uint256 base1
      ) {
      (base0, base1) = IHypervisor(_hypervisor).pullLiquidity(tickLower, tickUpper, shares, minAmounts);
    }

    function pullLiquidity(
      address _hypervisor,
      uint256 shares,
      uint256[4] memory minAmounts 
    ) external onlyRebalancer(_hypervisor) returns(
        uint256 base0,
        uint256 base1,
        uint256 limit0,
        uint256 limit1
      ) {
      (base0, base1, limit0, limit1) = IHypervisor(_hypervisor).pullLiquidity(shares, minAmounts);
    }

    function addLiquidity(
        address _hypervisor,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1,
        uint256[2] memory inMin
    ) external onlyRebalancer(_hypervisor) {
        IHypervisor(_hypervisor).addLiquidity(tickLower, tickUpper, amount0, amount1, inMin);
    }

    /// @notice Add tokens to base liquidity
    /// @param _hypervisor Hypervisor Address
    /// @param amount0 Amount of token0 to add
    /// @param amount1 Amount of token1 to add
    function addBaseLiquidity(address _hypervisor, uint256 amount0, uint256 amount1, uint256[2] memory inMin) external onlyRebalancer(_hypervisor) {
        IHypervisor(_hypervisor).addBaseLiquidity(amount0, amount1, inMin);
    }

    /// @notice Add tokens to limit liquidity
    /// @param _hypervisor Hypervisor Address
    /// @param amount0 Amount of token0 to add
    /// @param amount1 Amount of token1 to add
    function addLimitLiquidity(address _hypervisor, uint256 amount0, uint256 amount1, uint256[2] memory inMin) external onlyRebalancer(_hypervisor) {
        IHypervisor(_hypervisor).addLimitLiquidity(amount0, amount1, inMin);
    }

    /// @notice compound pending fees 
    /// @param _hypervisor Hypervisor Address
    function compound( address _hypervisor) external onlyAdvisor(_hypervisor) returns(
        uint128 baseToken0Owed,
        uint128 baseToken1Owed,
        uint128 limitToken0Owed,
        uint128 limitToken1Owed,
        uint256[4] memory inMin
    ) {
        IHypervisor(_hypervisor).compound();
    }

    function compound( address _hypervisor, uint256[4] memory inMin)
      external onlyAdvisor(_hypervisor) returns(
        uint128 baseToken0Owed,
        uint128 baseToken1Owed,
        uint128 limitToken0Owed,
        uint128 limitToken1Owed
    ) {
        IHypervisor(_hypervisor).compound(inMin);
    }

    /// @param _hypervisor Hypervisor Address
    function removeWhitelisted(address _hypervisor) external onlyAdmin {
        IHypervisor(_hypervisor).removeWhitelisted();
    }

    /// @param newAdmin New Admin Address
    function transferAdmin(address newAdmin) external onlyAdmin { require(newAdmin != address(0), "newAdmin should be non-zero");
        admin = newAdmin;
    }

    /// @param _hypervisor Hypervisor Address
    /// @param newOwner New Owner Address
    function transferHypervisorOwner(address _hypervisor, address newOwner) external onlyAdmin {
        IHypervisor(_hypervisor).transferOwnership(newOwner);
    }

    /// @param newAdvisor New Advisor Address
    function setAdvisor(address _hypervisor, address newAdvisor) external onlyAdmin {
        require(newAdvisor != address(0), "newAdvisor should be non-zero");
        advisors[_hypervisor] = newAdvisor;
    }

    /// @param newRebalancer New Rebalancer Address
    function setRebalancer(address _hypervisor, address newRebalancer) external onlyAdmin {
        require(newRebalancer != address(0), "newRebalancer should be non-zero");
        rebalancers[_hypervisor] = newRebalancer;
    }

    /// @notice Transfer tokens to the recipient from the contract
    /// @param token Address of token
    /// @param recipient Recipient Address
    function rescueERC20(IERC20 token, address recipient) external onlyAdmin {
        require(recipient != address(0), "recipient should be non-zero");
        require(token.transfer(recipient, token.balanceOf(address(this))));
    }

    /// @param _hypervisor Hypervisor Address
    /// @param newFee fee amount 
    function setFee(address _hypervisor, uint8 newFee) external onlyAdmin {
        IHypervisor(_hypervisor).setFee(newFee);
    }
}