// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IEvilTeddyBearClub.sol";
import "./IEvilCoin.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract EvilTeddyBearSale2 is Ownable {
    IEvilTeddyBearClub public evilTeddyBear;
    IEvilCoin public evilCoinAddress;
    uint256 public maxSupply = 6666;

    uint256 public priceTeddyCoin = 1000 ether;
    bool public saleIsActive = false;
    address private oracleEthUsd;

    constructor(
        IEvilTeddyBearClub _evilTeddyBear,
        IEvilCoin _evilCoinAddress,
        address _oracleEthUsd
    ) {
        evilTeddyBear = IEvilTeddyBearClub(_evilTeddyBear);
        evilCoinAddress = IEvilCoin(_evilCoinAddress);
        oracleEthUsd = _oracleEthUsd;
    }

    function removeDustFunds(address _treasury) public onlyOwner {
        (bool success,) = _treasury.call{value : address(this).balance}("");
        require(success, "funds were not sent properly to treasury");
    }

    function mintWithEvilCoins(uint256 numberOfEvilTeddyBears) public payable {
        require(saleIsActive == true, "Sale has not started");
        require(msg.value == calculateFee(), "Incorrect value");
        require(evilTeddyBear.totalSupply() <= maxSupply, "Max Supply Reached");
        require(evilCoinAddress.balanceOf(msg.sender) >= priceTeddyCoin * numberOfEvilTeddyBears, "You dont have $EVIL enough");
        require((evilTeddyBear.totalSupply() + numberOfEvilTeddyBears) <= maxSupply, "Exceeds max supply");
        evilCoinAddress.burn(msg.sender, (priceTeddyCoin * numberOfEvilTeddyBears));

        for (uint256 i; i < numberOfEvilTeddyBears; i++) {
            evilTeddyBear.mint(msg.sender);
        }
    }

    function changeSaleStatus() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function changeMaxSupply(uint256 newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    function removeFunds() external onlyOwner {
        uint256 funds = address(this).balance;

        (bool devShare,) = 0x519B8faF8b4eD711F4Aa2B01AA1E3BaF3B915ac9.call{
        value : funds * 30 / 100
        }("");

        (bool operationalShare,) = 0x12AAb452F7896F4f2d3D14cB7ddcAbCA78f4F092.call{
        value : funds * 30 / 100
        }("");

        (bool communityShare,) = 0x4476B95F799AD707aD4cD6dEe7383297b2E1C6D6.call{
        value : address(this).balance
        }("");

        require(
            devShare &&
            operationalShare &&
            communityShare,
            "funds were not sent properly"
        );
    }

    function calculateFee() public view returns (uint256) {
        (, int256 price, , ,) = AggregatorV3Interface(oracleEthUsd)
        .latestRoundData();
        uint256 currentETHPriceInUSD = uint256(price / (10 ** 8)); // price comes in 8 decimals
        uint256 res = 10 * (10000 / currentETHPriceInUSD) * 10 ** 18; // ETH has 18 decimals
        return res / 10000;
    }
}