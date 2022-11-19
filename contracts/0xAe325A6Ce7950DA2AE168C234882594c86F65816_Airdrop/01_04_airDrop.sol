// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// interface IERC20 {

//     function transferFrom(
//         address from,
//         address to,
//         uint256 amount
//     ) external returns (bool);

//     function balanceOf(address account) external view returns (uint256);

//     function allowance(address owner, address spender) external view returns (uint256);

// }

// interface IERC721{
//     function safeTransferFrom(
//         address from,
//         address to,
//         uint256 tokenId
//     ) external;
// }

contract Airdrop is Ownable {
    using SafeMath for uint;
    event EtherTransfer(address beneficiary, uint amount);
    function dropEther(address[] memory _recipients, uint256[] memory _amount) public payable onlyOwner returns (bool) {
        uint total = 0;

        for(uint j = 0; j < _amount.length; j++) {
            total = total.add(_amount[j]);
        }

        require(total <= msg.value);
        require(_recipients.length == _amount.length);


        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0));

            payable(_recipients[i]).transfer(_amount[i]);

            emit EtherTransfer(_recipients[i], _amount[i]);
        }

        return true;
    }


    function withdrawEther(address payable beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }

}