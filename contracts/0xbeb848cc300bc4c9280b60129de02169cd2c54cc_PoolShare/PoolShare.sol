/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

/*
                                                              ,----,                                                               
                                                            ,/   .`|                      ,----..       ,----..             ____   
  .--.--.       ,---,.  ,----..  ,-.----.       ,---,.    ,`   .'  :        ,-.----.     /   /   \     /   /   \          ,'  , `. 
 /  /    '.   ,'  .' | /   /   \ \    /  \    ,'  .' |  ;    ;     /        \    /  \   /   .     :   /   .     :      ,-+-,.' _ | 
|  :  /`. / ,---.'   ||   :     :;   :    \ ,---.'   |.'___,/    ,'         ;   :    \ .   /   ;.  \ .   /   ;.  \  ,-+-. ;   , || 
;  |  |--`  |   |   .'.   |  ;. /|   | .\ : |   |   .'|    :     |          |   | .\ :.   ;   /  ` ;.   ;   /  ` ; ,--.'|'   |  ;| 
|  :  ;_    :   :  |-,.   ; /--` .   : |: | :   :  |-,;    |.';  ;          .   : |: |;   |  ; \ ; |;   |  ; \ ; ||   |  ,', |  ': 
 \  \    `. :   |  ;/|;   | ;    |   |  \ : :   |  ;/|`----'  |  |          |   |  \ :|   :  | ; | '|   :  | ; | '|   | /  | |  || 
  `----.   \|   :   .'|   : |    |   : .  / |   :   .'    '   :  ;          |   : .  /.   |  ' ' ' :.   |  ' ' ' :'   | :  | :  |, 
  __ \  \  ||   |  |-,.   | '___ ;   | |  \ |   |  |-,    |   |  '          ;   | |  \'   ;  \; /  |'   ;  \; /  |;   . |  ; |--'  
 /  /`--'  /'   :  ;/|'   ; : .'||   | ;\  \'   :  ;/|    '   :  |          |   | ;\  \\   \  ',  /  \   \  ',  / |   : |  | ,     
'--'.     / |   |    \'   | '/  ::   ' | \.'|   |    \    ;   |.'           :   ' | \.' ;   :    /    ;   :    /  |   : '  |/      
  `--'---'  |   :   .'|   :    / :   : :-'  |   :   .'    '---'             :   : :-'    \   \ .'      \   \ .'   ;   | |`-'       
            |   | ,'   \   \ .'  |   |.'    |   | ,'                        |   |.'       `---`         `---`     |   ;/           
            `----'      `---`    `---'      `----'                          `---'                                 '---'            

KOLs now earn lifetime rewards for helping to spread the word.

https://secretroom.app/ 

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract PoolShare {
    address private owner;
    mapping(address => uint256) private sharePercentages;
    mapping(address => uint256) private shareBalances;
    address[] private wallets;

    event SharePercentageSet(address indexed wallet, uint256 percentage);
    event Withdraw(address indexed wallet, uint256 amount);
    event Deposit(address indexed wallet, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    function setSharePercentage(address _wallet, uint256 _percentage)
        external
        onlyOwner
    {
        require(_percentage <= 100, "Percentage must be <= 100");

        if (sharePercentages[_wallet] == 0) {
            wallets.push(_wallet);
        }

        sharePercentages[_wallet] = _percentage;

        emit SharePercentageSet(_wallet, _percentage);
    }

    function removeShareWallet(address _wallet) external onlyOwner {
        require(sharePercentages[_wallet] > 0, "Wallet not found");

        delete sharePercentages[_wallet];

        for (uint256 i = 0; i < wallets.length; i++) {
            if (wallets[i] == _wallet) {
                wallets[i] = wallets[wallets.length - 1];
                wallets.pop();
                break;
            }
        }
    }

    function deposit() private {
        require(msg.value > 0, "Amount must be greater than 0");

        uint256 totalShares;
        for (uint256 i = 0; i < wallets.length; i++) {
            totalShares += sharePercentages[getAddressAtIndex(i)];
        }

        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = getAddressAtIndex(i);
            uint256 shareAmount = (msg.value * sharePercentages[wallet]) /
                totalShares;
            shareBalances[wallet] += shareAmount;
        }
    }

    function withdraw() external {
        uint256 availableBalance = shareBalances[msg.sender];
        require(availableBalance > 0, "No balance available to withdraw");

        shareBalances[msg.sender] = 0;
        payable(msg.sender).transfer(availableBalance);

        emit Withdraw(msg.sender, availableBalance);
    }

    function getSharePercentage(address _wallet)
        external
        view
        returns (uint256)
    {
        return sharePercentages[_wallet];
    }

    function getShareBalance(address _wallet) external view returns (uint256) {
        return shareBalances[_wallet];
    }

    function getWalletCount() external view returns (uint256) {
        return wallets.length;
    }

    function getWalletAtIndex(uint256 _index) external view returns (address) {
        require(_index < wallets.length, "Invalid index");

        return wallets[_index];
    }

    function getAddressAtIndex(uint256 _index) private view returns (address) {
        require(_index < wallets.length, "Invalid index");

        return wallets[_index];
    }

    function getTotalPoolBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTotalWalletsBalance() external view returns (uint256) {
        uint256 totalBalance = 0;

        for (uint256 i = 0; i < wallets.length; i++) {
            totalBalance += shareBalances[wallets[i]];
        }

        return totalBalance;
    }

    fallback() external payable {
        deposit();

        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        deposit();

        emit Deposit(msg.sender, msg.value);
    }
}