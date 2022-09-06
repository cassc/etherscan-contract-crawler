// SPDX-License-Identifier: Apache License 2.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/BondingCurveToken.sol";
import "./SecurityToken.sol";

contract CoordinationToken is Ownable, BondingCurveToken {


    uint32 private constant MAX_RESERVE_RATIO = 1000000;
    uint256 private constant HUNDRED_PERCENT = 1e18;
    uint256 private constant COEFFICIENT = 1e9;
    uint256 private immutable phi; // 1e18 = 100%, 1e16 = 1%, 0 = 0%
    SecurityToken public immutable securityToken;
    uint256 internal _poolBalance;

    event BondedToMint(address indexed receiver, uint256 bonded, uint256 received);
    event BurnedToWithdraw(address indexed receiver, uint256 burned, uint256 received);

    /// @notice Constructor that defines BondingTokenCurve and ERC20 parameters
    /// @param token Address of Security token to bond
    /// @param fee fee percentage to pay
    /// @param gasPrice gasPrice limitation to prevent front running
    /// @notice BondingCurveToken is created with _reserveRatio 500000 to set:
    /// CoordinationTokenSupply ^ 2 = SecurityTokenSupply
    constructor(SecurityToken token, uint256 fee, uint256 gasPrice) BondingCurveToken(500000, gasPrice) ERC20("Coordination","CRD") {
        securityToken = token;
        require(fee<HUNDRED_PERCENT,
            "CoordinationToken: Fee needs to be lower then 100%");
        phi = fee;
    }

    /// @notice Function that bonds SecurityTokens to receive CoordinationTokens
    /// @param amountToBond Amount of Security token to bond
    /// @param minimalAmountToReceive Minimal amount of Security tokens to receive
    function bondToMint(uint256 amountToBond, uint256 minimalAmountToReceive) external {
        uint256 minted;
        if(totalSupply() == 0){
            minted = amountToBond;
            _mint(msg.sender, amountToBond);
            emit BondedToMint(msg.sender, amountToBond, amountToBond);
        } else {
            minted = _curvedMint(amountToBond);
            emit BondedToMint(msg.sender, amountToBond, minted);
        }
        require(minted >= minimalAmountToReceive,
            "CoordinationToken.bondToMint: Mints less tokens then expected");
        _poolBalance += amountToBond;
        require(securityToken.transferFrom(msg.sender, address(this), amountToBond),
            "CoordinationToken.bondToMint: Impossible to bond so much tokens");
    }

    /// @notice Function that withdraws SecurityTokens by burning CoordinationTokens
    /// @param amountToWithdraw Amount of Coordination tokens to withdraw
    /// @param minimalAmountToReceive Minimal amount of Security tokens to receive
    function burnToWithdraw(uint256 amountToWithdraw, uint256 minimalAmountToReceive) external {
        require(balanceOf(msg.sender) >= amountToWithdraw,
            "CoordinationToken.burnToWithdraw: Not enough funds to withdraw");
        uint256 currentFee = (amountToWithdraw * phi) / HUNDRED_PERCENT;
        _transfer(msg.sender, address(this), currentFee);
        uint256 burned = _curvedBurn(amountToWithdraw - currentFee);
        _poolBalance = _poolBalance - burned;
        require(burned >= minimalAmountToReceive,
            "CordinationToken.burnToWithdraw: Send less tokens then expected");
        require(securityToken.transfer(msg.sender, burned),
            "Failed to transfer SecurityTokens");
        emit BurnedToWithdraw(msg.sender, amountToWithdraw, burned);
    }

    /// @notice Function that returns the overall amount of bonded SecurityTokens
    /// @return Balance of SecurityTokens of the contract
    function poolBalance() public override view returns (uint256) {
        return _poolBalance;
    }

    function setGasPrice(uint256 gasPrice) public onlyOwner{
        _setGasPrice(gasPrice);
    }
}