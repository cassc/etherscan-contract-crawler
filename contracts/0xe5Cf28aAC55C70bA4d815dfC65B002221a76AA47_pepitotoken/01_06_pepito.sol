// SPDX-License-Identifier: MIT
// TG: @pepitotokeneth
//
//EEEEEEEEEEEEEEEEEEEEEElllllll      PPPPPPPPPPPPPPPPP   EEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPPPPPPPPP   IIIIIIIIIITTTTTTTTTTTTTTTTTTTTTTT     OOOOOOOOO     
//E::::::::::::::::::::El:::::l      P::::::::::::::::P  E::::::::::::::::::::EP::::::::::::::::P  I::::::::IT:::::::::::::::::::::T   OO:::::::::OO   
//E::::::::::::::::::::El:::::l      P::::::PPPPPP:::::P E::::::::::::::::::::EP::::::PPPPPP:::::P I::::::::IT:::::::::::::::::::::T OO:::::::::::::OO 
//EE::::::EEEEEEEEE::::El:::::l      PP:::::P     P:::::PEE::::::EEEEEEEEE::::EPP:::::P     P:::::PII::::::IIT:::::TT:::::::TT:::::TO:::::::OOO:::::::O
//  E:::::E       EEEEEE l::::l        P::::P     P:::::P  E:::::E       EEEEEE  P::::P     P:::::P  I::::I  TTTTTT  T:::::T  TTTTTTO::::::O   O::::::O
//  E:::::E              l::::l        P::::P     P:::::P  E:::::E               P::::P     P:::::P  I::::I          T:::::T        O:::::O     O:::::O
//  E::::::EEEEEEEEEE    l::::l        P::::PPPPPP:::::P   E::::::EEEEEEEEEE     P::::PPPPPP:::::P   I::::I          T:::::T        O:::::O     O:::::O
//  E:::::::::::::::E    l::::l        P:::::::::::::PP    E:::::::::::::::E     P:::::::::::::PP    I::::I          T:::::T        O:::::O     O:::::O
//  E:::::::::::::::E    l::::l        P::::PPPPPPPPP      E:::::::::::::::E     P::::PPPPPPPPP      I::::I          T:::::T        O:::::O     O:::::O
//  E::::::EEEEEEEEEE    l::::l        P::::P              E::::::EEEEEEEEEE     P::::P              I::::I          T:::::T        O:::::O     O:::::O
//  E:::::E              l::::l        P::::P              E:::::E               P::::P              I::::I          T:::::T        O:::::O     O:::::O
//  E:::::E       EEEEEE l::::l        P::::P              E:::::E       EEEEEE  P::::P              I::::I          T:::::T        O::::::O   O::::::O
//EE::::::EEEEEEEE:::::El::::::l     PP::::::PP          EE::::::EEEEEEEE:::::EPP::::::PP          II::::::II      TT:::::::TT      O:::::::OOO:::::::O
//E::::::::::::::::::::El::::::l     P::::::::P          E::::::::::::::::::::EP::::::::P          I::::::::I      T:::::::::T       OO:::::::::::::OO 
//E::::::::::::::::::::El::::::l     P::::::::P          E::::::::::::::::::::EP::::::::P          I::::::::I      T:::::::::T         OO:::::::::OO   
//EEEEEEEEEEEEEEEEEEEEEEllllllll     PPPPPPPPPP          EEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPP          IIIIIIIIII      TTTTTTTTTTT           OOOOOOOOO                                                   
                                                    
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract pepitotoken is ERC20, Ownable {
    constructor() ERC20("El Pepito", "PEPITO"){}

    /// turn on/off contributions
    bool public allowContributions;

    /// a minimum contribution to participate in the presale
    uint256 public constant MIN_CONTRIBUTION = .05 ether;

    /// limit the maximum contribution for each wallet
    uint256 public constant MAX_CONTRIBUTION = .15 ether;

    /// the maximum amount of eth that this contract will accept for presale
    uint256 public constant HARD_CAP = 4 ether;

    /// total number of tokens available
    uint256 public constant MAX_SUPPLY = 555555555555550 * 10 ** 18;

    /// ~50% of tokens reserved for presale
    uint256 public constant PRESALE_SUPPLY = 275000000000000 * 10 ** 18;

    /// ~50% of tokens reserved for LP and dev mint
    uint256 public constant RESERVE_MAX_SUPPLY = 280555555555550 * 10 ** 18;

    /// used to track the total contributions for the presale
    uint256 public TOTAL_CONTRIBUTED;

    /// used to track the total number of contributoors
    uint256 public NUMBER_OF_CONTRIBUTOORS;

    /// a struct used to keep track of each contributoors address and contribution amount
    struct Contribution {
        address addr;
        uint256 amount;
    }

    /// mapping of contributions
    mapping (uint256 => Contribution) public contribution;

    /// index of an address to it's contribition information
    mapping (address => uint256) public contributoor;

    /// collect presale contributions
    function sendToPresale() public payable {

        /// look up the sender's current contribution amount in the mapping
        uint256 currentContribution = contribution[contributoor[msg.sender]].amount;

        /// initialize a contribution index so we can keep track of this address' contributions
        uint256 contributionIndex;

        require(msg.value >= MIN_CONTRIBUTION, "Contribution too low");

        /// check to see if contributions are allowed
        require (allowContributions, "Contributions not allowed");

        /// enforce per-wallet contribution limit
        require (msg.value + currentContribution <= MAX_CONTRIBUTION, "Contribution exceeds per wallet limit");

        /// enforce hard cap
        require (msg.value + TOTAL_CONTRIBUTED <= HARD_CAP, "Contribution exceeds hard cap"); 

        if (contributoor[msg.sender] != 0){
            /// no need to increase the number of contributors since this person already added
            contributionIndex = contributoor[msg.sender];
        } else {
            /// keep track of each new contributor with a unique index
            contributionIndex = NUMBER_OF_CONTRIBUTOORS + 1;
            NUMBER_OF_CONTRIBUTOORS++;
        }

        /// add the contribution to the amount contributed
        TOTAL_CONTRIBUTED = TOTAL_CONTRIBUTED + msg.value;

        /// keep track of the address' contributions so far
        contributoor[msg.sender] = contributionIndex;
        contribution[contributionIndex].addr = msg.sender;
        contribution[contributionIndex].amount += msg.value;
    }

    function airdropPresale() external onlyOwner {

        /// determine the price per token
        uint256 pricePerToken = (TOTAL_CONTRIBUTED * 10 ** 18)/PRESALE_SUPPLY;

        /// loop over each contribution and distribute tokens
        for (uint256 i = 1; i <= NUMBER_OF_CONTRIBUTOORS; i++) {

            /// convert contribution to 18 decimals
            uint256 contributionAmount = contribution[i].amount * 10 ** 18;

            /// calculate the percentage of the pool based on the address' contribution
            uint256 numberOfTokensToMint = contributionAmount/pricePerToken;

            /// mint the tokens to the address
            _mint(contribution[i].addr, numberOfTokensToMint);
        }
    }

    /// dev mint the remainder of the pool to round out the supply
    function devMint() external onlyOwner {

        /// calculate the remaining supply
        uint256 numberToMint = MAX_SUPPLY - totalSupply();
        
        /// don't allow the dev mint until the tokens have been airdropped
        require (numberToMint <= RESERVE_MAX_SUPPLY, "Dev mint limited to reserve max");

        /// mint the remaining supply to the dev's wallet
        _mint(msg.sender, numberToMint);
    }

     /// set whether or not the contract allows contributions
    function setAllowContributions(bool _value) external onlyOwner {
        allowContributions = _value;
    }

    /// if there are not enough contributions or we decide this sucks, refund everyone their eth
    function refundEveryone() external onlyOwner {
        for (uint256 i = 1; i <= NUMBER_OF_CONTRIBUTOORS; i++) {
            address payable refundAddress = payable(contribution[i].addr);
            
            /// refund the contribution
            refundAddress.transfer(contribution[i].amount);
        }
    }

    /// allows the owner to withdraw the funds in this contract
    function withdrawBalance(address payable _address) external onlyOwner {
        (bool success, ) = _address.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
}