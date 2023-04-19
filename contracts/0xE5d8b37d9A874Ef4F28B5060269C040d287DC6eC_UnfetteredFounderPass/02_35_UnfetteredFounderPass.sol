// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./UnfetteredBaseToken.sol";
import "../v1/access/MerkleVerifier.sol";
import "../v1/util/TimeRangeLib.sol";
import "../v1/util/Errors.sol";
import "../v1/token/PhasedSales.sol";

/*
*   Developed by Versiyonbir Teknoloji
*   [email protected]
*/
contract UnfetteredFounderPass is UnfetteredBaseToken, PhasedSales {
    address public treasuryWallet;

    constructor(
        address accountOwner,
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint96 numerator,
        IERC20 salesToken,
        IERC20[] memory paymentTokens,
        uint256 maxSupply,
        uint256 maxMintCountForPerAddress
    )
        UnfetteredBaseToken(
            accountOwner,
            name,
            symbol,
            baseURI,
            numerator,
            paymentTokens,
            maxSupply,
            maxMintCountForPerAddress
        )
        PhasedSales(salesToken)
    {
        if (address(salesToken) != address(0)) {
            // add salesToken (if does not exist)
            _addRemovePaymentToken(salesToken, false);
        }
    }

    function setTreasuryWallet(address addr) public onlyOwner {
        treasuryWallet = addr;
    }

    function setMaxSupply(uint256 maxSupply) public onlyOwner {
        _maxSupply = maxSupply;
    }

    function setSalesPhases(
        SalesPhase[] memory salesPhases
    ) external onlyOwner {
        _setSalesPhases(salesPhases);
    }

    function updateSalesPhase(
        uint8 phaseIndex,
        SalesPhase memory salesPhase
    ) public onlyOwner {
        _updateSalesPhase(phaseIndex, salesPhase);
    }

    function mintToTreasury(uint256 amount) public onlyOwner {
        for (uint i = 0; i < amount; i++) _mint(treasuryWallet, totalSupply());
    }

    function mint(
        uint8 phaseIndex, // starts from zero
        uint256 amount,
        uint256 requestedAmount,
        bytes32[] calldata merkleProof
    ) public payable whenNotPaused(SalePauseTopicID) {
        _buy(phaseIndex, amount, requestedAmount, merkleProof);

        for (uint i = 0; i < requestedAmount; i++)
            _mint(msg.sender, totalSupply());
    }

    function mint(
        uint8 phaseIndex, // starts from zero
        uint256 amount,
        uint256 requestedAmount
    ) public payable whenNotPaused(SalePauseTopicID) {
        _buy(phaseIndex, amount, requestedAmount);

        for (uint i = 0; i < requestedAmount; i++)
            _mint(msg.sender, totalSupply());
    }
}

uint8 constant SalePauseTopicID = 101;