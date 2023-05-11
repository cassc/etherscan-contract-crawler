//FFFFFFFFFFFFFFFFFFFFFF     888888888                      TTTTTTTTTTTTTTTTTTTTTTT     OOOOOOOOO     KKKKKKKKK    KKKKKKKEEEEEEEEEEEEEEEEEEEEEENNNNNNNN        NNNNNNNN
//F::::::::::::::::::::F   88:::::::::88                    T:::::::::::::::::::::T   OO:::::::::OO   K:::::::K    K:::::KE::::::::::::::::::::EN:::::::N       N::::::N
//F::::::::::::::::::::F 88:::::::::::::88                  T:::::::::::::::::::::T OO:::::::::::::OO K:::::::K    K:::::KE::::::::::::::::::::EN::::::::N      N::::::N
//FF::::::FFFFFFFFF::::F8::::::88888::::::8                 T:::::TT:::::::TT:::::TO:::::::OOO:::::::OK:::::::K   K::::::KEE::::::EEEEEEEEE::::EN:::::::::N     N::::::N
//  F:::::F       FFFFFF8:::::8     8:::::8                 TTTTTT  T:::::T  TTTTTTO::::::O   O::::::OKK::::::K  K:::::KKK  E:::::E       EEEEEEN::::::::::N    N::::::N
//  F:::::F             8:::::8     8:::::8                         T:::::T        O:::::O     O:::::O  K:::::K K:::::K     E:::::E             N:::::::::::N   N::::::N
//  F::::::FFFFFFFFFF    8:::::88888:::::8                          T:::::T        O:::::O     O:::::O  K::::::K:::::K      E::::::EEEEEEEEEE   N:::::::N::::N  N::::::N
//  F:::::::::::::::F     8:::::::::::::8   ---------------         T:::::T        O:::::O     O:::::O  K:::::::::::K       E:::::::::::::::E   N::::::N N::::N N::::::N
//  F:::::::::::::::F    8:::::88888:::::8  -:::::::::::::-         T:::::T        O:::::O     O:::::O  K:::::::::::K       E:::::::::::::::E   N::::::N  N::::N:::::::N
//  F::::::FFFFFFFFFF   8:::::8     8:::::8 ---------------         T:::::T        O:::::O     O:::::O  K::::::K:::::K      E::::::EEEEEEEEEE   N::::::N   N:::::::::::N
//  F:::::F             8:::::8     8:::::8                         T:::::T        O:::::O     O:::::O  K:::::K K:::::K     E:::::E             N::::::N    N::::::::::N
//  F:::::F             8:::::8     8:::::8                         T:::::T        O::::::O   O::::::OKK::::::K  K:::::KKK  E:::::E       EEEEEEN::::::N     N:::::::::N
//FF:::::::FF           8::::::88888::::::8                       TT:::::::TT      O:::::::OOO:::::::OK:::::::K   K::::::KEE::::::EEEEEEEE:::::EN::::::N      N::::::::N
//F::::::::FF            88:::::::::::::88                        T:::::::::T       OO:::::::::::::OO K:::::::K    K:::::KE::::::::::::::::::::EN::::::N       N:::::::N
//F::::::::FF              88:::::::::88                          T:::::::::T         OO:::::::::OO   K:::::::K    K:::::KE::::::::::::::::::::EN::::::N        N::::::N
//FFFFFFFFFFF                888888888                            TTTTTTTTTTT           OOOOOOOOO     KKKKKKKKK    KKKKKKKEEEEEEEEEEEEEEEEEEEEEENNNNNNNN         NNNNNNN
//                                                                                                                                                                      
//                                                                                                                                                                      
//                                                                                                                                                                      
//                                                                                                                                                                      
//                                                                                                                                                                      
//                                                                                                                                                                      
//                                                                                                                                                                      
//       $$$$$                                                                                                                                                          
//       $:::$                                                                                                                                                          
//   $$$$$:::$$$$$$ FFFFFFFFFFFFFFFFFFFFFF      AAA         TTTTTTTTTTTTTTTTTTTTTTTEEEEEEEEEEEEEEEEEEEEEE                                                               
// $$::::::::::::::$F::::::::::::::::::::F     A:::A        T:::::::::::::::::::::TE::::::::::::::::::::E                                                               
//$:::::$$$$$$$::::$F::::::::::::::::::::F    A:::::A       T:::::::::::::::::::::TE::::::::::::::::::::E                                                               
//$::::$       $$$$$FF::::::FFFFFFFFF::::F   A:::::::A      T:::::TT:::::::TT:::::TEE::::::EEEEEEEEE::::E                                                               
//$::::$              F:::::F       FFFFFF  A:::::::::A     TTTTTT  T:::::T  TTTTTT  E:::::E       EEEEEE                                                               
//$::::$              F:::::F              A:::::A:::::A            T:::::T          E:::::E                                                                            
//$:::::$$$$$$$$$     F::::::FFFFFFFFFF   A:::::A A:::::A           T:::::T          E::::::EEEEEEEEEE                                                                  
// $$::::::::::::$$   F:::::::::::::::F  A:::::A   A:::::A          T:::::T          E:::::::::::::::E                                                                  
//   $$$$$$$$$:::::$  F:::::::::::::::F A:::::A     A:::::A         T:::::T          E:::::::::::::::E                                                                  
//            $::::$  F::::::FFFFFFFFFFA:::::AAAAAAAAA:::::A        T:::::T          E::::::EEEEEEEEEE                                                                  
//            $::::$  F:::::F         A:::::::::::::::::::::A       T:::::T          E:::::E                                                                            
//$$$$$       $::::$  F:::::F        A:::::AAAAAAAAAAAAA:::::A      T:::::T          E:::::E       EEEEEE                                                               
//$::::$$$$$$$:::::$FF:::::::FF     A:::::A             A:::::A   TT:::::::TT      EE::::::EEEEEEEE:::::E                                                               
//$::::::::::::::$$ F::::::::FF    A:::::A               A:::::A  T:::::::::T      E::::::::::::::::::::E                                                               
// $$$$$$:::$$$$$   F::::::::FF   A:::::A                 A:::::A T:::::::::T      E::::::::::::::::::::E                                                               
//      $:::$       FFFFFFFFFFF  AAAAAAA                   AAAAAAATTTTTTTTTTT      EEEEEEEEEEEEEEEEEEEEEE                                                               
//      $$$$$        

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract F8TOKEN is ERC20, Ownable {
    constructor() ERC20("F8 Token", "FATE"){}

    /// turn on/off contributions
    bool public allowContributions;

    /// a minimum contribution to participate in the seed round
    uint256 public constant MIN_CONTRIBUTION = .1 ether;

    /// limit the maximum contribution for each wallet
    uint256 public constant MAX_CONTRIBUTION = .5 ether;

    /// the maximum amount of eth that this contract will accept for seed round
    uint256 public constant HARD_CAP = 65 ether;

    /// total number of tokens available
    uint256 public constant MAX_SUPPLY = 8_888_000_000_000 * 10**18;

    /// 46% of tokens reserved for seed round
    uint256 public constant SEED_SUPPLY = 4_088_480_000_000 * 10**18;

    /// 54% of tokens reserved for LP, social airdrops, and team mint
    uint256 public constant RESERVE_MAX_SUPPLY = 4_799_520_000_000 * 10**18;

    /// used to track the total contributions for the seed round
    uint256 public TOTAL_CONTRIBUTED;

    /// used to track the total number of contributors
    uint256 public NUMBER_OF_CONTRIBUTORS;

    /// a struct used to keep track of each contributors address and contribution amount
    struct Contribution {
        address addr;
        uint256 amount;
    }

    /// mapping of contributions
    mapping (uint256 => Contribution) public contribution;

    /// index of an address to it's contribition information
    mapping (address => uint256) public contributor;


 mapping(address => bool) public whitelist;

    /**
     * @notice Add to whitelist
     */
    function addToWhitelist(address[] calldata toAddAddresses) 
    external onlyOwner
    {
        for (uint i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
        }
    }

    /// collect seed round contributions
    function sendToSeed() public payable {

    require(whitelist[msg.sender], "NOT_IN_WHITELIST");

        /// look up the sender's current contribution amount in the mapping
        uint256 currentContribution = contribution[contributor[msg.sender]].amount;

        /// initialize a contribution index so we can keep track of this address' contributions
        uint256 contributionIndex;

        require(msg.value >= MIN_CONTRIBUTION, "Contribution too low");

        /// check to see if contributions are allowed
        require (allowContributions, "Contributions not allowed");

        /// enforce per-wallet contribution limit
        require (msg.value + currentContribution <= MAX_CONTRIBUTION, "Contribution exceeds per wallet limit");

        /// enforce hard cap
        require (msg.value + TOTAL_CONTRIBUTED <= HARD_CAP, "Contribution exceeds hard cap"); 

        if (contributor[msg.sender] != 0){
            /// no need to increase the number of contributors since this person already added
            contributionIndex = contributor[msg.sender];
        } else {
            /// keep track of each new contributor with a unique index
            contributionIndex = NUMBER_OF_CONTRIBUTORS + 1;
            NUMBER_OF_CONTRIBUTORS++;
        }

        /// add the contribution to the amount contributed
        TOTAL_CONTRIBUTED = TOTAL_CONTRIBUTED + msg.value;

        /// keep track of the address' contributions so far
        contributor[msg.sender] = contributionIndex;
        contribution[contributionIndex].addr = msg.sender;
        contribution[contributionIndex].amount += msg.value;
    }

        /// allow contributors to send directly to the contract
    receive() external payable {
        sendToSeed();
    }

    function airdropSeed() external onlyOwner {
        
        /// determine the price per token
        uint256 pricePerToken = (TOTAL_CONTRIBUTED * 10 ** 18)/SEED_SUPPLY;

        /// loop over each contribution and distribute tokens
        for (uint256 i = 1; i <= NUMBER_OF_CONTRIBUTORS; i++) {

            /// convert contribution to 18 decimals
            uint256 contributionAmount = contribution[i].amount * 10 ** 18;

            /// calculate the percentage of the pool based on the address' contribution
            uint256 numberOfTokensToMint = contributionAmount/pricePerToken;

            /// mint the tokens to the address
            _mint(contribution[i].addr, numberOfTokensToMint);
        }
    }

    /// team mint the remainder of the pool to round out the supply
    function teamMint() external onlyOwner {

        /// calculate the remaining supply
        uint256 numberToMint = MAX_SUPPLY - totalSupply();
        
        /// don't allow the team mint until the tokens have been airdropped
        require (numberToMint <= RESERVE_MAX_SUPPLY, "Team mint limited to reserve max");

        /// mint the remaining supply to the team's wallet
        _mint(msg.sender, numberToMint);
    }

     /// set whether or not the contract allows contributions
    function setAllowContributions(bool _value) external onlyOwner {
        allowContributions = _value;
    }

    /// if there are not enough contributions or we hit a bug, refund everyone their ETH
    function refundContributors(uint256 _startIndex, uint256 _endIndex) external onlyOwner {
        for (uint256 i = _startIndex; i <= _endIndex;) {
            payable(contribution[i].addr).transfer(contribution[i].amount);
            ++i;
        }
    }

    /// allows the owner to withdraw the funds in this contract
    function withdrawBalance(address payable _address) external onlyOwner {
        (bool success, ) = _address.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
}