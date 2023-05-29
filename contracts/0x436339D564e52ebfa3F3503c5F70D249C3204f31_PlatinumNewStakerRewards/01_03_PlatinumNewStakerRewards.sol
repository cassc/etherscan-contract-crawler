// SPDX-License-Identifier: MIT
/*
Platinum Primates New Staker Rewards 2022
                                    ./#@@@(*                                    
                            &@@@@@@@@@@@@@@@@@@@@@@@*                           
                        @@@@@@@@@@*           #@@@@@@@@@%                       
                    [email protected]@@@@@@.                       (@@@@@@@                    
                  %@@@@@#                               @@@@@@.                 
                /@@@@@                @@@@*               *@@@@@                
               @@@@@                 @@@@@@@                (@@@@%              
              @@@@%                [email protected]@@@@@@@@                 @@@@@             
             @@@@/                (@@@@, @@@@@.                @@@@&            
            @@@@@       @@@@@@@@@@@@@@    (@@@@@@@@@@@@@%       @@@@*           
            @@@@        @@@@@@@%(,             *#%@@@@@@#       &@@@@           
           ,@@@@          /@@@@@@              [email protected]@@@@@           @@@@           
           ,@@@@             @@@@@@          /@@@@@(            [email protected]@@@           
            @@@@              *@@@@          *@@@@              @@@@@           
            &@@@@             @@@@(  /@@@@@.  @@@@/             @@@@,           
             @@@@%           [email protected]@@@@@@@@@@@@@@@@@@@@            @@@@%            
              @@@@@          &@@@@@@@(     &@@@@@@@*          @@@@&             
               @@@@@,         &@%              ,@@*         &@@@@/              
                [email protected]@@@@,                                   %@@@@@                
                  *@@@@@@                              *@@@@@@                  
                     @@@@@@@#                      [email protected]@@@@@@/                    
                       &@@@@@@@@@@&#,       *#@@@@@@@@@@@,                      
                      @@@@@ ,&@@@@@@@@@@@@@@@@@@@@@( [email protected]@@@%                     
                     @@@@&         /@@@@@@@@@.         @@@@@                    
                   *@@@@(         &@@@@  /@@@@/         @@@@@                   
                  %@@@@.         @@@@@    [email protected]@@@&         #@@@@,                 
                 @@@@@         [email protected]@@@&       @@@@@         [email protected]@@@%                
                @@@@& .&@@    /@@@@/         &@@@@    ,@@#  @@@@@               
              *@@@@@@@@@@@@. %@@@@.           (@@@@* @@@@@@@@@@@@@              
              @@@@@@@/ ,@@@@@@@@@              [email protected]@@@@@@@@ .&@@@@@@/             
                        *@@@@@@&                 @@@@@@@                        
                         *@@@@(                   @@@@@       
*/
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function mint(address to, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IPlatinumStaking{


    function getLengthOfStakedNFTs(address _addr)
        external
        view
        returns (uint256);

         function getStakedLengthOfTimeForToken(uint256 _tokenId)
        external
        view
        returns (uint256);

        function getOwnerOfStakedNFT(uint256 _tokenId)
        external
        view
        returns (address);
    
}

contract PlatinumNewStakerRewards is Ownable {
    IERC20 public token;
    IPlatinumStaking public stakingContractAddress;
    mapping(address => uint256) public walletClaimCount;
    mapping(address => uint256) public walletFirstClaim;
    mapping(address => uint256) public walletSecondClaim;
    uint256 public claimStartTimeStamp;
    uint256 public claimAmount;
    bool public claimsActive;

    constructor() {
        token = IERC20(0xe83341b9D5Cc95f0E0D6b94Ed4820C0F191C51BA);
        stakingContractAddress = IPlatinumStaking(0xF2bAB5000f909b5765F61a71fbd76CE749d59FD6);
        claimAmount = 75000000000000000000;
        claimStartTimeStamp = block.timestamp;
    }

    function setTokenAddress(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function setStakingContractaddress(address _address) external onlyOwner {
        stakingContractAddress = IPlatinumStaking(_address);
    }

    function setClaimAmount (uint256 _amount) external onlyOwner{
        claimAmount = _amount;
    }

      function setClaimStartTimestamp (uint256 _timestamp) external onlyOwner{
        claimStartTimeStamp = _timestamp;
    }

    function getCLaim(uint256 _tokenId) external{
        
        require(_tokenId != 0, "invalid token");
        require(walletClaimCount[msg.sender] < 2, "Wallet used up all reward claims.");
        require(stakingContractAddress.getOwnerOfStakedNFT(_tokenId) == msg.sender, "Primate is not yours");
        require(block.timestamp - stakingContractAddress.getStakedLengthOfTimeForToken(_tokenId) > claimStartTimeStamp, "Primate has already been staked before New Reward Mechanics were deployed");
        require(walletFirstClaim[msg.sender] != _tokenId,"Initial claim has already been made by the wallet for this primate");
        require(walletSecondClaim[msg.sender] != _tokenId,"Secondary claim has already been made by the wallet for this primate");

        token.mint(msg.sender, claimAmount);        
        walletClaimCount[msg.sender] ++;

        if (walletFirstClaim[msg.sender] == 0){

            walletFirstClaim[msg.sender] = _tokenId;

        }else if (walletSecondClaim[msg.sender] == 0){

            walletSecondClaim[msg.sender] = _tokenId;

        }



    }

}