/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IOffer.sol";

contract BaseOfferSale is Ownable, IOffer {
    using SafeMath for uint256;

    bool internal bInitialized;
    bool internal bFinished;
    bool internal bSuccess;

    uint256 internal nTotalSold;
    uint256 internal nFinishDate;

    uint256 private nRate = 1;


    function initialize() public override {
        require(!bInitialized, "Sale is initialized");
        bInitialized = true;

        _initialize();
    }

    function setSuccess() public onlyOwner {
        require(bInitialized, "Sale is not initialized");

        require(!bSuccess, "Sale is already successful");

        bSuccess = true;
    }

    function getInitialized() public view override returns (bool) {
        return bInitialized;
    }

    function getFinished() public view override returns (bool) {
        return bFinished;
    }

    function getSuccess() public view override returns (bool) {
        return bSuccess;
    }

    function getTotalBought(address _investor)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return 0;
    }

    function getTotalCashedOut(address _investor)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return 0;
    }

    function invest(address _investor, uint256 _amount)
        public
        onlyOwner
    {
        require(_investor != address(0), "Investor is empty");
        require(_amount != 0, "Amount is zero");
        require(!bFinished, "Sale is finished");
        require(bInitialized, "Sale is not initialized");

        // pass the function to one of our modules
        _investInput(_investor, _amount);

        // convert input currency to output
        // - get rate from module
        uint256 nRate = _getRate();

        // - total amount from the rate obtained
        uint256 nOutputAmount = _amount.div(nRate);

        // pass to module to handling outputs
        _investOutput(_investor, nOutputAmount);

        // after everything, add the bought tokens to the total
        nTotalSold = nTotalSold.add(nOutputAmount);

        // now make sure everything we've done is okay
        _rule();

        // and check if the sale is sucessful after this sale
        _checkSuccess();
    }

    function finishSale() public onlyOwner {
        require(!bFinished, "Sale is finished");
        bFinished = true;

        nFinishDate = block.timestamp;

        _finishSale();
    }

    function getTotalSold() public view virtual returns (uint256 totalSold) {
        return nTotalSold;
    }

    function cashoutTokens(address _investor)
        external
        virtual
        override
        returns (bool)
    {
        return bFinished;
    }

    function _initialize() internal virtual {}

    function _investInput(address _investor, uint256 _amount)
        internal
        virtual
    {}

    function _investOutput(address _investor, uint256 _outputAmount)
        internal
        virtual
    {}

    function _finishSale() internal virtual {}

    function _rule() internal virtual {}

    function _checkSuccess() internal virtual {}

    function _getRate() internal view virtual returns (uint256 rate) {
        return nRate;
    }

    function setRate(uint256 _rate) public {
        nRate = _rate;
    }

    function getFinishDate() external view override returns (uint256) {
        return nFinishDate;
    }
}