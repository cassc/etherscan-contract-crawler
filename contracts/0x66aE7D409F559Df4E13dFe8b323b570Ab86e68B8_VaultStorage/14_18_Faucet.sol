// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVaultStorage {
    function isSystemPaused() external view returns (bool);

    function governance() external view returns (address);

    function keeper() external view returns (address);
}

interface IFaucet {
    function setComponents(
        address,
        address,
        address,
        address,
        address,
        address
    ) external;
}

contract Faucet is IFaucet, Ownable {
    address public uniswapMath;
    address public vault;
    address public auction;
    address public vaultMath;
    address public vaultTreasury;
    address public vaultStorage;

    constructor() Ownable() {}

    function setComponents(
        address _uniswapMath,
        address _vault,
        address _auction,
        address _vaultMath,
        address _vaultTreasury,
        address _vaultStorage
    ) public override onlyOwner {
        (uniswapMath, vault, auction, vaultMath, vaultTreasury, vaultStorage) = (
            _uniswapMath,
            _vault,
            _auction,
            _vaultMath,
            _vaultTreasury,
            _vaultStorage
        );
    }

    modifier onlyVault() {
        require(msg.sender == vault || msg.sender == auction, "C12");
        _;
    }

    modifier onlyMath() {
        require(msg.sender == vaultMath, "C13");
        _;
    }

    modifier onlyContracts() {
        require(msg.sender == vault || msg.sender == vaultMath || msg.sender == auction, "C14");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == IVaultStorage(vaultStorage).governance(), "C15");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == IVaultStorage(vaultStorage).keeper(), "C22");
        _;
    }

    /**
     * @notice current balance of a certain token
     */
    function _getBalance(IERC20 token) internal view returns (uint256) {
        return token.balanceOf(vaultTreasury);
    }

    modifier notPaused() {
        require(!IVaultStorage(vaultStorage).isSystemPaused(), "C0");
        _;
    }
}