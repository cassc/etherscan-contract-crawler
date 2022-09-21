// SPDX-License-Identifier: Apache License 2.0

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/BondingCurveToken.sol";
import "./DelphiaPlatformToken.sol";

contract Phi is Ownable, BondingCurveToken {


    uint32 private constant MAX_RESERVE_RATIO = 1000000;
    uint256 private constant HUNDRED_PERCENT = 1e18;
    uint256 private constant COEFFICIENT = 1e9;
    uint256 private immutable _fee; // 1e18 = 100%, 1e16 = 1%, 0 = 0%
    DelphiaPlatformToken public immutable delphiaPlatformToken;
    uint256 internal _poolBalance;

    event BondedToMint(address indexed receiver, uint256 bonded, uint256 received);
    event BurnedToWithdraw(address indexed receiver, uint256 withdrawn, uint256 received);

    /// @notice Constructor that defines BondingTokenCurve and ERC20 parameters
    /// @param token Address of Delphia Platform Token to bond
    /// @param fee fee percentage to pay
    /// @param gasPrice gasPrice limitation to prevent front running
    /// @notice BondingCurveToken is created with _reserveRatio 500000 to set:
    /// PhiSupply ^ 2 = DelphiaPlatformTokenSupply
    constructor(DelphiaPlatformToken token, uint256 fee, uint256 gasPrice) BondingCurveToken(500000, gasPrice) ERC20("Phi","PHI") {
        delphiaPlatformToken = token;
        require(fee<HUNDRED_PERCENT,
            "Phi: Fee needs to be lower then 100%");
        _fee = fee;
    }

    /// @notice Function that bonds DelphiaPlatformTokens to receive Phis
    /// @param amountToBond Amount of Delphia Platform Token to bond
    /// @param minimalAmountToReceive Minimal amount of Delphia Platform Tokens to receive
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
            "Phi.bondToMint: Mints less tokens then expected");
        _poolBalance += amountToBond;
        require(delphiaPlatformToken.transferFrom(msg.sender, address(this), amountToBond),
            "Phi.bondToMint: Impossible to bond so much tokens");
    }

    /// @notice Function that withdraws DelphiaPlatformTokens by burning Phis
    /// @param amountToBurn Amount of Phi to burn
    /// @param minimalAmountToReceive Minimal amount of Delphia Platform Tokens to receive
    function burnToWithdraw(uint256 amountToBurn, uint256 minimalAmountToReceive) external {
        require(balanceOf(msg.sender) >= amountToBurn,
            "Phi.burnToWithdraw: Not enough funds to withdraw");
        uint256 currentFee = (amountToBurn * _fee) / HUNDRED_PERCENT;
        _transfer(msg.sender, address(this), currentFee);
        uint256 withdrawn = _curvedBurn(amountToBurn - currentFee);
        _poolBalance = _poolBalance - withdrawn;
        require(withdrawn >= minimalAmountToReceive,
            "CordinationToken.burnToWithdraw: Send less tokens then expected");
        require(delphiaPlatformToken.transfer(msg.sender, withdrawn),
            "Failed to transfer DelphiaPlatformTokens");
        emit BurnedToWithdraw(msg.sender, amountToBurn, withdrawn);
    }

    /// @notice Function that returns the overall amount of bonded DelphiaPlatformTokens
    /// @return Balance of DelphiaPlatformTokens of the contract
    function poolBalance() public override view returns (uint256) {
        return _poolBalance;
    }

    function setGasPrice(uint256 gasPrice) public onlyOwner{
        _setGasPrice(gasPrice);
    }
}