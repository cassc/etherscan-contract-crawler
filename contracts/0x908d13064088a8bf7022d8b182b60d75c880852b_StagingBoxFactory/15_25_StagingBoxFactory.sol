// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./StagingBox.sol";
import "./ConvertibleBondBox.sol";
import "../interfaces/ICBBFactory.sol";
import "../interfaces/IStagingBoxFactory.sol";

contract StagingBoxFactory is IStagingBoxFactory, Context {
    using ClonesWithImmutableArgs for address;

    address public immutable implementation;

    mapping(address => address) public CBBtoSB;

    struct SlipPair {
        address lendSlip;
        address borrowSlip;
    }

    constructor(address _implementation) {
        implementation = _implementation;
    }

    /**
     * @dev Deploys a staging box with a CBB
     * @param cBBFactory The ConvertibleBondBox factory
     * @param slipFactory The factory for the Slip-Tokens
     * @param bond The buttonwood bond
     * @param penalty The penalty for late repay
     * @param stableToken The stable token
     * @param trancheIndex The tranche index used to determine the safe tranche
     * @param initialPrice The initial price of the safe asset
     * @param cbbOwner The owner of the ConvertibleBondBox
     */

    function createStagingBoxWithCBB(
        ICBBFactory cBBFactory,
        ISlipFactory slipFactory,
        IBondController bond,
        uint256 penalty,
        address stableToken,
        uint256 trancheIndex,
        uint256 initialPrice,
        address cbbOwner
    ) public returns (address) {
        ConvertibleBondBox convertibleBondBox = ConvertibleBondBox(
            cBBFactory.createConvertibleBondBox(
                bond,
                slipFactory,
                penalty,
                stableToken,
                trancheIndex,
                address(this)
            )
        );

        address deployedSB = this.createStagingBoxOnly(
            slipFactory,
            convertibleBondBox,
            initialPrice,
            cbbOwner
        );

        //transfer ownership of CBB to SB
        convertibleBondBox.transferOwnership(deployedSB);

        return deployedSB;
    }

    /**
     * @dev Deploys only a staging box
     * @param slipFactory The factory for the Slip-Tokens
     * @param convertibleBondBox The CBB tied to the staging box being deployed
     * @param initialPrice The initial price of the safe asset
     * @param owner The owner of the StagingBox
     */

    function createStagingBoxOnly(
        ISlipFactory slipFactory,
        ConvertibleBondBox convertibleBondBox,
        uint256 initialPrice,
        address owner
    ) public returns (address) {
        require(
            _msgSender() == convertibleBondBox.owner(),
            "StagingBoxFactory: Deployer not owner of CBB"
        );

        SlipPair memory SlipData = deploySlips(
            slipFactory,
            address(convertibleBondBox.safeTranche()),
            address(convertibleBondBox.riskTranche()),
            address(convertibleBondBox.stableToken())
        );

        bytes memory data = bytes.concat(
            abi.encodePacked(
                SlipData.lendSlip,
                SlipData.borrowSlip,
                convertibleBondBox,
                initialPrice,
                convertibleBondBox.stableToken(),
                convertibleBondBox.safeTranche(),
                address(convertibleBondBox.safeSlip()),
                convertibleBondBox.safeRatio()
            ),
            abi.encodePacked(
                convertibleBondBox.riskTranche(),
                address(convertibleBondBox.riskSlip()),
                convertibleBondBox.riskRatio(),
                convertibleBondBox.s_priceGranularity(),
                convertibleBondBox.trancheDecimals(),
                convertibleBondBox.stableDecimals()
            )
        );

        // clone staging box
        StagingBox clone = StagingBox(implementation.clone(data));
        clone.initialize(owner);

        //tansfer slips ownership to staging box
        ISlip(SlipData.lendSlip).changeOwner(address(clone));
        ISlip(SlipData.borrowSlip).changeOwner(address(clone));

        address oldStagingBox = CBBtoSB[address(convertibleBondBox)];

        if (oldStagingBox == address(0)) {
            emit StagingBoxCreated(
                _msgSender(),
                address(clone),
                address(slipFactory)
            );
        } else {
            emit StagingBoxReplaced(
                convertibleBondBox,
                _msgSender(),
                oldStagingBox,
                address(clone),
                address(slipFactory)
            );
        }

        CBBtoSB[address(convertibleBondBox)] = address(clone);

        return address(clone);
    }

    function deploySlips(
        ISlipFactory slipFactory,
        address safeTranche,
        address riskTranche,
        address stableToken
    ) private returns (SlipPair memory) {
        string memory collateralSymbolSafe = IERC20Metadata(
            address(safeTranche)
        ).symbol();
        string memory collateralSymbolRisk = IERC20Metadata(
            address(riskTranche)
        ).symbol();

        // clone deploy lend slip
        address lendSlipTokenAddress = slipFactory.createSlip(
            "IBO-Buy-Order",
            string(abi.encodePacked("IBO-BUY-", collateralSymbolSafe)),
            stableToken
        );

        //clone deployborrow slip
        address borrowSlipTokenAddress = slipFactory.createSlip(
            "IBO-Issue-Order",
            string(abi.encodePacked("IBO-ISSUE-", collateralSymbolRisk)),
            stableToken
        );

        SlipPair memory SlipData = SlipPair(
            lendSlipTokenAddress,
            borrowSlipTokenAddress
        );

        return SlipData;
    }
}