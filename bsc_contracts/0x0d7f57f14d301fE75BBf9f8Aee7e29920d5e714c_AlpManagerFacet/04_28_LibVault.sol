// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IVault} from "../interfaces/IVault.sol";
import {IWBNB} from "../../dependencies/IWBNB.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library LibVault {

    using Address for address payable;
    using SafeERC20 for IERC20;

    bytes32 constant VAULT_POSITION = keccak256("apollox.vault.storage");
    uint16 constant BASIS_POINTS_DIVISOR = 10000;

    struct AvailableToken {
        address tokenAddress;
        uint32 tokenAddressPosition;
        uint16 weight;
        uint16 feeBasisPoints;
        uint16 taxBasisPoints;
        uint8 decimals;
        bool stable;
        bool dynamicFee;
    }

    struct VaultStorage {
        mapping(address => AvailableToken) tokens;
        address[] tokenAddresses;
        // tokenAddress => amount
        mapping(address => uint256) treasury;
        address wbnb;
        address exchangeTreasury;
    }

    function vaultStorage() internal pure returns (VaultStorage storage vs) {
        bytes32 position = VAULT_POSITION;
        assembly {
            vs.slot := position
        }
    }

    event AddToken(address indexed token, uint16 weight, uint16 feeBasisPoints, uint16 taxBasisPoints, bool stable, bool dynamicFee);
    event RemoveToken(address indexed token);
    event UpdateToken(
        address indexed token,
        uint16 oldFeeBasisPoints, uint16 oldTaxBasisPoints, bool oldDynamicFee,
        uint16 feeBasisPoints, uint16 taxBasisPoints, bool dynamicFee
    );
    event ChangeWeight(address[] tokenAddress, uint16[] oldWeights, uint16[] newWeights);

    function initialize(address wbnb, address exchangeTreasury_) internal {
        VaultStorage storage vs = vaultStorage();
        require(vs.wbnb == address(0) && vs.exchangeTreasury == address(0), "LibAlpManager: Already initialized");
        vs.wbnb = wbnb;
        vs.exchangeTreasury = exchangeTreasury_;
    }

    function WBNB() internal view returns (address) {
        return vaultStorage().wbnb;
    }

    function exchangeTreasury() internal view returns (address) {
        return vaultStorage().exchangeTreasury;
    }

    function addToken(address tokenAddress, uint16 feeBasisPoints, uint16 taxBasisPoints, bool stable, bool dynamicFee, uint16[] memory weights) internal {
        VaultStorage storage vs = vaultStorage();
        AvailableToken storage at = vs.tokens[tokenAddress];
        require(at.weight == 0, "LibVault: Can't add token that already exists");
        if (dynamicFee && taxBasisPoints <= feeBasisPoints) {
            revert("LibVault: TaxBasisPoints must be greater than feeBasisPoints at dynamic rates");
        }
        at.tokenAddress = tokenAddress;
        at.tokenAddressPosition = uint32(vs.tokenAddresses.length);
        at.feeBasisPoints = feeBasisPoints;
        at.taxBasisPoints = taxBasisPoints;
        at.decimals = IERC20Metadata(tokenAddress).decimals();
        at.stable = stable;
        at.dynamicFee = dynamicFee;

        vs.tokenAddresses.push(tokenAddress);
        emit AddToken(at.tokenAddress, weights[weights.length - 1], at.feeBasisPoints, at.taxBasisPoints, at.stable, at.dynamicFee);
        changeWeight(weights);
    }

    function removeToken(address tokenAddress, uint16[] memory weights) internal {
        VaultStorage storage vs = vaultStorage();
        AvailableToken storage at = vs.tokens[tokenAddress];
        require(at.weight > 0, "LibVault: Token does not exist");

        changeWeight(weights);
        uint256 lastPosition = vs.tokenAddresses.length - 1;
        uint256 tokenAddressPosition = at.tokenAddressPosition;
        if (tokenAddressPosition != lastPosition) {
            address lastTokenAddress = vs.tokenAddresses[lastPosition];
            vs.tokenAddresses[tokenAddressPosition] = lastTokenAddress;
            vs.tokens[lastTokenAddress].tokenAddressPosition = uint32(tokenAddressPosition);
        }
        require(at.weight == 0, "LibVault: The weight of the removed Token must be 0.");
        vs.tokenAddresses.pop();
        delete vs.tokens[tokenAddress];
        emit RemoveToken(tokenAddress);
    }

    function updateToken(address tokenAddress, uint16 feeBasisPoints, uint16 taxBasisPoints, bool dynamicFee) internal {
        VaultStorage storage vs = vaultStorage();
        AvailableToken storage at = vs.tokens[tokenAddress];
        require(at.weight > 0, "LibVault: Token does not exist");
        if (dynamicFee && taxBasisPoints <= feeBasisPoints) {
            revert("LibVault: TaxBasisPoints must be greater than feeBasisPoints at dynamic rates");
        }
        (uint16 oldFeePoints, uint16 oldTaxPoints, bool oldDynamicFee) = (at.feeBasisPoints, at.taxBasisPoints, at.dynamicFee);
        at.feeBasisPoints = feeBasisPoints;
        at.taxBasisPoints = taxBasisPoints;
        at.dynamicFee = dynamicFee;
        emit UpdateToken(tokenAddress, oldFeePoints, oldTaxPoints, oldDynamicFee, feeBasisPoints, taxBasisPoints, dynamicFee);
    }

    function changeWeight(uint16[] memory weights) internal {
        VaultStorage storage vs = vaultStorage();
        require(weights.length == vs.tokenAddresses.length, "LibVault: Invalid weights");
        uint16 totalWeight;
        uint16[] memory oldWeights = new uint16[](weights.length);
        for (uint256 i; i < weights.length;) {
            totalWeight += weights[i];
            address tokenAddress = vs.tokenAddresses[i];
            uint16 oldWeight = vs.tokens[tokenAddress].weight;
            oldWeights[i] = oldWeight;
            vs.tokens[tokenAddress].weight = weights[i];
            unchecked {
                i++;
            }
        }
        require(totalWeight == BASIS_POINTS_DIVISOR, "LibVault: The sum of the weights is not equal to 10000");
        emit ChangeWeight(vs.tokenAddresses, oldWeights, weights);
    }

    function deposit(address token, uint256 amount) internal {
        deposit(token, amount, address(0), true);
    }

    // The caller checks whether the token exists and the amount>0
    // in order to return quickly in case of an error
    function deposit(address token, uint256 amount, address from, bool transferred) internal {
        if (!transferred) {
            IERC20(token).safeTransferFrom(from, address(this), amount);
        }
        LibVault.VaultStorage storage vs = LibVault.vaultStorage();
        vs.treasury[token] += amount;
    }

    function depositBNB(uint256 amount) internal {
        IWBNB(WBNB()).deposit{value : amount}();
        deposit(WBNB(), amount);
    }

    // The caller checks whether the token exists and the amount>0
    // in order to return quickly in case of an error
    function withdraw(address receiver, address token, uint256 amount) internal {
        LibVault.VaultStorage storage vs = LibVault.vaultStorage();
        require(vs.treasury[token] >= amount, "LibVault: Treasury insufficient balance");
        vs.treasury[token] -= amount;
        IERC20(token).safeTransfer(receiver, amount);
    }

    // The entry for calling this method needs to prevent reentry
    // use "../security/RentalGuard.sol"
    function withdrawBNB(address payable receiver, uint256 amount) internal {
        LibVault.VaultStorage storage vs = LibVault.vaultStorage();
        require(vs.treasury[WBNB()] >= amount, "LibVault: Treasury insufficient balance");
        IWBNB(WBNB()).withdraw(amount);
        vs.treasury[WBNB()] -= amount;
        receiver.sendValue(amount);
    }
}