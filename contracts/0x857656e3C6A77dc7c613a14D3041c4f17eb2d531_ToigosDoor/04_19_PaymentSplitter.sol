// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
Payees can be changed via changePayees function. Only contract owner can change payees. 
Changing payees will override previous payees.
All payee addresses must be able to receive ETH, otherwise it will revert for everyone. 
Anyone can call withdraw function. Withdraw function will withdraw entire contract balance and split according to shares/totalshares.

*/
contract PaymentSplitter is Ownable {
    IERC20 internal tokenContract;
    address payable[] public payees;
    uint256[] public shares;

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    constructor() { //6% Royalties Total
        payees.push(payable(msg.sender));
        shares.push(100);
    }

    function changePayees(address payable[] memory newPayees, uint256[] memory newShares) public onlyOwner {
        delete payees;
        delete shares;
        uint256 length = newPayees.length;
        require(newPayees.length == newShares.length, "number of new payees must match number of new shares");
        for(uint256 i=0; i<length; i++) {
            payees.push(newPayees[i]);
            shares.push(newShares[i]);
        }
    }

    function getTotalShares() public view returns (uint256) {
        uint256 totalShares;
        uint256 length = payees.length;
        for (uint256 i = 0; i<length; i++) {
            totalShares += shares[i];
        }
        return totalShares;
    }

    function withdraw() public {
        address partner;
        uint256 share;
        uint256 totalShares = getTotalShares();
        uint256 length = payees.length;
        uint256 balanceBeforeWithdrawal = address(this).balance;
        for (uint256 j = 0; j<length; j++) {
            partner = payees[j];
            share = shares[j];
            (bool success, ) = partner.call{value: balanceBeforeWithdrawal * share/totalShares}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }

    function withdrawERC20(address _tokenAddress) external {
        tokenContract = IERC20(_tokenAddress);
        uint256 balance = tokenContract.balanceOf(address(this));
        address partner;
        uint256 share;
        uint256 totalShares = getTotalShares();
        uint256 length = payees.length;
        for (uint256 j = 0; j<length; j++) {
            partner = payees[j];
            share = shares[j];
            tokenContract.transferFrom(address(this), partner, balance * share/totalShares);
        }
        
    }

   

}