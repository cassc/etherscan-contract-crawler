// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CryptoFaceRoyalty is Ownable {

    event RoyaltyPaid(uint256 amount, bool WETH, address artist, uint256 token);
    event EthPaid(uint256 amount);

    address OPPContract;
    address WETHContract;
    address lastArtist;
    address daoAddress = 0x5A79dEB48abD5e842675e5604ab4Aebadacbb860;
    address truthAddress = 0x12392F348d27488637886E26f8aDD0A8EDdd368F;
    address brotherAddress = 0x12392F348d27488637886E26f8aDD0A8EDdd368F;
    address devAddress1 = 0xa69B6935B0F38506b81224B4612d7Ea49A4B0aCC;
    address devAddress2 = 0x537fb7A86FEcC2Bd63cd694BcFD2856CDccacC2d;

    uint256 lastTokenTransferred = 0;
    uint256 lastWETHBalance = 0;
    uint256 lastETHBalance = 0;

    receive() external payable {
        
    }

    fallback() external payable {
        
    }

    function setLastTokenTransferred(uint256 token, address artist) public {
        require(msg.sender == OPPContract, "OPP only");

        _handleRoyalty();

        lastTokenTransferred = token;
        lastArtist = artist;

    }

    function _handleRoyalty() internal {
        uint256 currentWETHBalance = IERC20(WETHContract).balanceOf(address(this));
        uint256 currentETHBalance = address(this).balance;

        _checkWETHTransfer(currentWETHBalance);
        _checkETHTransfer(currentETHBalance);
    }

    function _checkWETHTransfer(uint256 currentWETHBalance) internal {
        uint256 WETHDifference = currentWETHBalance - lastWETHBalance;
        
        if(WETHDifference != 0) {
            uint256 artistFee = (WETHDifference * 4000) / 10000;
            uint256 daoFee = (WETHDifference * 2667) / 10000;
            uint256 truthFee = (WETHDifference * 1333) / 10000;
            uint256 devFee1 = (WETHDifference * 1200) / 10000;
            uint256 brotherFee = (WETHDifference * 667) / 10000;
            uint256 devFee2 = (WETHDifference * 133) / 10000;

            IERC20(WETHContract).transferFrom(
                address(this),
                lastArtist,
                artistFee
            );

            IERC20(WETHContract).transferFrom(
                address(this),
                daoAddress,
                daoFee
            );

            IERC20(WETHContract).transferFrom(
                address(this),
                truthAddress,
                truthFee
            );

            IERC20(WETHContract).transferFrom(
                address(this),
                devAddress1,
                devFee1
            );

            IERC20(WETHContract).transferFrom(
                address(this),
                brotherAddress,
                brotherFee
            );


            IERC20(WETHContract).transferFrom(
                address(this),
                devAddress2,
                devFee2
            );

            lastWETHBalance = 0;

            emit RoyaltyPaid(artistFee, true, lastArtist, lastTokenTransferred);
            
        }
    }

    function _checkETHTransfer(uint256 currentETHBalance) internal {
        uint256 ETHDifference = currentETHBalance - lastETHBalance;
        
        if(ETHDifference != 0) {
            uint256 artistFee = (ETHDifference * 4000) / 10000;
            uint256 daoFee = (ETHDifference * 2667) / 10000;
            uint256 truthFee = (ETHDifference * 1333) / 10000;
            uint256 devFee1 = (ETHDifference * 1200) / 10000;
            uint256 brotherFee = (ETHDifference * 667) / 10000;
            uint256 devFee2 = (ETHDifference * 133) / 10000;

            (bool t, ) = payable(lastArtist).call{value: artistFee}("");
            
            if(t) {/*Artist was paid woo*/}

            (bool t2, ) = payable(daoAddress).call{value: daoFee}("");
            
            if(t2) {/*dao was paid woo*/}

            (bool t3, ) = payable(truthAddress).call{value: truthFee}("");
            
            if(t3) {/*truth was paid woo*/}

            (bool t4, ) = payable(devAddress1).call{value: devFee1}("");
            
            if(t4) {/*Dev 1 was paid woo*/}

            (bool t5, ) = payable(brotherAddress).call{value: brotherFee}("");
            
            if(t5) {/*Brother was paid woo*/}

            (bool t6, ) = payable(devAddress2).call{value: devFee2}("");
            
            if(t6) {/*Dev 2 was paid woo*/}

            lastETHBalance = 0;

            emit RoyaltyPaid(artistFee, false, lastArtist, lastTokenTransferred);
        }
    }

    function recoverERC20(address _contract) public onlyOwner {
        require(_contract != WETHContract, "Not allowed to withdraw WETH manually");

        IERC20(_contract).transferFrom(
            address(this),
            owner(),
            IERC20(_contract).balanceOf(address(this))
        );
    }

    function setOPPContract(address _address) public onlyOwner {
        OPPContract = _address;
    }

    function setWETHAddress(address _address) public onlyOwner {
        WETHContract = _address;
    }

}