// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ConvertibleBondBox.sol";
import "../interfaces/ICBBFactory.sol";
import "../interfaces/ISlip.sol";

contract CBBFactory is ICBBFactory, Context {
    using ClonesWithImmutableArgs for address;

    address public immutable implementation;

    struct TranchePair {
        ITranche safeTranche;
        uint256 safeRatio;
        ITranche riskTranche;
        uint256 riskRatio;
    }

    struct SlipPair {
        address safeAddress;
        address riskAddress;
    }

    constructor(address _implementation) {
        implementation = _implementation;
    }

    /**
     * @dev Initializer for Convertible Bond Box
     * @param bond The buttonTranche bond tied to this Convertible Bond Box
     * @param slipFactory The factory for the Slip-Tokens
     * @param penalty The penalty ratio for non-repayment of loan
     * @param stableToken The address of the stable-token being lent for the safe-Tranche
     * @param trancheIndex The index of the safe-Tranche
     * @param owner The initial owner
     */
    function createConvertibleBondBox(
        IBondController bond,
        ISlipFactory slipFactory,
        uint256 penalty,
        address stableToken,
        uint256 trancheIndex,
        address owner
    ) public returns (address) {
        ConvertibleBondBox clone;

        TranchePair memory TrancheSet = getBondData(bond, trancheIndex);

        SlipPair memory SlipData = deploySlips(
            slipFactory,
            TrancheSet.safeTranche,
            TrancheSet.riskTranche
        );

        uint256 maturityDate = bond.maturityDate();
        address collateralToken = bond.collateralToken();

        bytes memory data = bytes.concat(
            abi.encodePacked(
                bond,
                SlipData.safeAddress,
                SlipData.riskAddress,
                penalty,
                collateralToken,
                stableToken,
                trancheIndex,
                maturityDate
            ),
            abi.encodePacked(
                TrancheSet.safeTranche,
                TrancheSet.safeRatio,
                TrancheSet.riskTranche,
                TrancheSet.riskRatio,
                10**IERC20Metadata(collateralToken).decimals(),
                10**IERC20Metadata(stableToken).decimals()
            )
        );

        //Clone CBB and initialize
        clone = ConvertibleBondBox(implementation.clone(data));
        clone.initialize(owner);

        //Transfer ownership of slips back to CBB
        ISlip(SlipData.safeAddress).changeOwner(address(clone));
        ISlip(SlipData.riskAddress).changeOwner(address(clone));

        //emit Event
        emit ConvertibleBondBoxCreated(
            _msgSender(),
            address(clone),
            address(slipFactory)
        );
        return address(clone);
    }

    function deploySlips(
        ISlipFactory slipFactory,
        ITranche safeTranche,
        ITranche riskTranche
    ) private returns (SlipPair memory) {
        string memory collateralSymbolSafe = IERC20Metadata(
            address(safeTranche)
        ).symbol();
        string memory collateralSymbolRisk = IERC20Metadata(
            address(riskTranche)
        ).symbol();

        address safeSlipAddress = slipFactory.createSlip(
            "CBB-Bond-Slip",
            string(abi.encodePacked("CBB-BOND-", collateralSymbolSafe)),
            address(safeTranche)
        );

        address riskSlipAddress = slipFactory.createSlip(
            "CBB-Debt-Slip",
            string(abi.encodePacked("CBB-DEBT-", collateralSymbolRisk)),
            address(riskTranche)
        );

        SlipPair memory SlipData = SlipPair(safeSlipAddress, riskSlipAddress);

        return SlipData;
    }

    function getBondData(IBondController bond, uint256 trancheIndex)
        private
        view
        returns (TranchePair memory)
    {
        uint256 trancheCount = bond.trancheCount();

        // Revert if only one tranche exists.
        if (trancheCount == 1) {
            revert InvalidTrancheCount();
        }

        // Revert if `trancheIndex` is Z-Tranche.
        if (trancheIndex >= trancheCount - 1) {
            // Note that the `trancheCount - 2` expression can not underflow
            // due to check above.
            revert TrancheIndexOutOfBounds({
                given: trancheIndex,
                maxIndex: trancheCount - 2
            });
        }

        (ITranche safeTranche, uint256 safeRatio) = bond.tranches(trancheIndex);
        (ITranche riskTranche, uint256 riskRatio) = bond.tranches(
            trancheCount - 1
        );

        TranchePair memory TrancheSet = TranchePair(
            safeTranche,
            safeRatio,
            riskTranche,
            riskRatio
        );

        return TrancheSet;
    }
}