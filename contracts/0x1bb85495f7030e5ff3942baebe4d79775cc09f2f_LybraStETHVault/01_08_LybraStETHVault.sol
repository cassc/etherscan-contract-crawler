// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../interfaces/IEUSD.sol";
import "./base/LybraEUSDVaultBase.sol";

interface Ilido {
    function submit(address _referral) external payable returns (uint256 StETH);
}

contract LybraStETHVault is LybraEUSDVaultBase {
    // Currently, the official rebase time for Lido is between 12PM to 13PM UTC.
    uint256 public lidoRebaseTime = 12 hours;

    // stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84
    // oracle = 0x4c517D4e2C851CA76d7eC94B805269Df0f2201De
    constructor(address _stETH, address _oracle, address _config) LybraEUSDVaultBase(_stETH, _oracle, _config) {
    }

    /**
     * @notice Sets the rebase time for Lido based on the actual situation.
     * This function can only be called by an address with the ADMIN role.
     */
    function setLidoRebaseTime(uint256 _time) external {
        require(configurator.hasRole(keccak256("ADMIN"), msg.sender), "NA");
        lidoRebaseTime = _time;
    }

    /**
     * @notice Allows users to deposit ETH to mint eUSD.
     * ETH is directly deposited into Lido and converted to stETH.
     * @param mintAmount The amount of eUSD to mint.
     * Requirements:
     * The deposited amount of ETH must be greater than or equal to 1 ETH.
     */
    function depositEtherToMint(uint256 mintAmount) external payable override {
        require(msg.value >= 1 ether, "DNL");
        //convert to steth
        uint256 sharesAmount = Ilido(address(collateralAsset)).submit{value: msg.value}(address(configurator));
        require(sharesAmount != 0, "ZERO_DEPOSIT");

        totalDepositedAsset += msg.value;
        depositedAsset[msg.sender] += msg.value;
        depositedTime[msg.sender] = block.timestamp;

        if (mintAmount > 0) {
            _mintEUSD(msg.sender, msg.sender, mintAmount, getAssetPrice());
        }

        emit DepositEther(msg.sender, address(collateralAsset), msg.value, msg.value, block.timestamp);
    }

    /**
     * @notice When stETH balance increases through LSD or other reasons, the excess income is sold for eUSD, allocated to eUSD holders through rebase mechanism.
     * Emits a `LSDValueCaptured` event.
     *
     * *Requirements:
     * - stETH balance in the contract cannot be less than totalDepositedAsset after exchange.
     * @dev Income is used to cover accumulated Service Fee first.
     */
    function excessIncomeDistribution(uint256 stETHAmount) external override {
        uint256 excessAmount = collateralAsset.balanceOf(address(this)) - totalDepositedAsset;
        require(excessAmount != 0 && stETHAmount != 0, "Only LSD excess income can be exchanged");
        uint256 realAmount = stETHAmount > excessAmount ? excessAmount : stETHAmount;
        uint256 dutchAuctionDiscountPrice = getDutchAuctionDiscountPrice();
        uint256 payAmount = realAmount * getAssetPrice() * dutchAuctionDiscountPrice / 10_000 / 1e18;

        uint256 income = feeStored + _newFee();
        if (payAmount > income) {
            bool success = EUSD.transferFrom(msg.sender, address(configurator), income);
            require(success, "TF");

            try configurator.distributeRewards() {} catch {}

            uint256 sharesAmount = EUSD.getSharesByMintedEUSD(payAmount - income);
            if (sharesAmount == 0) {
                //eUSD totalSupply is 0: assume that shares correspond to eUSD 1-to-1
                sharesAmount = (payAmount - income);
            }
            //Income is distributed to LBR staker.
            EUSD.burnShares(msg.sender, sharesAmount);
            feeStored = 0;
            emit FeeDistribution(address(configurator), income, block.timestamp);
        } else {
            bool success = EUSD.transferFrom(msg.sender, address(configurator), payAmount);
            require(success, "TF");
            try configurator.distributeRewards() {} catch {}
            feeStored = income - payAmount;
            emit FeeDistribution(address(configurator), payAmount, block.timestamp);
        }

        lastReportTime = block.timestamp;
        collateralAsset.transfer(msg.sender, realAmount);
        emit LSDValueCaptured(realAmount, payAmount, dutchAuctionDiscountPrice, block.timestamp);
    }

    /**
     * @notice Reduces the discount for the issuance of additional tokens based on the rebase time using the Dutch auction method.
     * The specific rule is that the discount rate increases by 1% every 30 minutes after the rebase occurs.
     */
    function getDutchAuctionDiscountPrice() public view returns (uint256) {
        uint256 time = (block.timestamp - lidoRebaseTime) % 1 days;
        if (time < 30 minutes) return 10_000;
        return 10_000 - (time / 30 minutes - 1) * 100;
    }

    function getAssetPrice() public override returns (uint256) {
        return _etherPrice();
    }
    function getAsset2EtherExchangeRate() external view override returns (uint256) {
        return 1e18;
    }
}