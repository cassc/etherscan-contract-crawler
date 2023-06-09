//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IpSeudo {
    function withdraw(uint wad) external payable;
    function balanceOf(address account) external view returns (uint256);
}

contract Aerarium {

        address immutable romeAddress;
        address immutable pSeudoAddress;
        IERC20 private rome;
        IpSeudo private pSeudo;

        constructor (address _romeAddress, address _pSeudoAddress){
            romeAddress = _romeAddress;
            pSeudoAddress = _pSeudoAddress;
            rome = IERC20(romeAddress);
            pSeudo = IpSeudo(pSeudoAddress);
        }

        receive() external payable {}

        function lfg() public {
            uint256 pSeudoBalance = pSeudo.balanceOf(address(this));
            require(pSeudoBalance > 0, 'No pSeudo');
            pSeudo.withdraw(pSeudoBalance);
            uint256 ethBalance = address(this).balance;
            require(ethBalance == pSeudoBalance, 'Withdraw unsuccessful');
            uint256 callerPortion = (ethBalance*5)/100; //5%
            uint256 romePortion = ethBalance - callerPortion;
            (bool sentRome, ) = romeAddress.call{value: romePortion}("");
            require(sentRome, "Failed to send Eth to Rome");
            (bool sentCaller, ) = msg.sender.call{value: callerPortion}("");
            require(sentCaller, "Failed to send Eth");
        }


}