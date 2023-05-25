// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
                                                                                                    
//                                 -+*#%@@@@@@@@@@%#*=:                                    
//             -+*##%%#=        =#@@%%%##########%%%@@@@#=.                                
//            *@@%%%#%@@*    :*@%##******************##%@@@*.                              
//    .=**+:  *@@*****#@@- :#@%#************************#%@@@=                             
//   [email protected]@@@@@@*[email protected]@#*****%@##@%#****************************#%@@*                            
//  [email protected]@#**##%@@@@@%%@@@@@@@#********************************#@@#                           
//  [email protected]%******##%@@@%%%%@@@#**********************************#@@*                          
//  #@%****###%@@%#*##@@@#************************************%@@=                         
//  %@@%%%%%%%@@@%%%%@@@#*************************************#@@@:                        
//  [email protected]@@@@@@@@@@@@@@@@@%*******###%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@%                        
//   .:--====++*#%@@@@@#******#@@@@@@@@@@%%%%%%%####****++==-::.%@@-                       
//                  @@%*******#@@-::[email protected]@*                       
//                 :@@%*******%@@....-*[email protected]%[email protected]@%                       
//                 [email protected]@%*******%@%....%@@-....*@@@@@@@@@*..:@@@[email protected]@%                       
//                  @@@#******%@#....%@@-.....#@@@@@@@%...:@@@:[email protected]@+                       
//                  [email protected]@@%#****%@*.....=-.......:=*##*-......:.:-%@@.                       
//                   %@@%%##**%@%#+=-::::::---===+++****###%%@@@@@-                        
//                   [email protected]@@@%%%#*##%%%%%@@@@@@@@@%%%%%%%%%%%%####@@-                         
//                    .#@@@%%%%##****************************%@@:                          
//                      -%@@@@%%%%%##*********************#%@@*                            
//                        -#@@@@@%%%%%%%###############%%@@@*.                             
//                           -*@@@@@@@@%%%%%%%%@@@@@@@@@@*-                                
//                              .-+#@@@@@@@@@@@@@@@%*+-.                                   
//                                    .::----:::.                                          
//                     
//                  -####**.    +#####*  -################. ****###########+               
//         :+-      *@@@@@@@:   *@@@@@%  [email protected]@@@@@@@@@@@@@@@. @@@@@@@@@@@@@@@%               
//     *%%%@@@%%%:  -%@@@@@@@+  *@@@@@-  :@@@@@@++++++++++  +*****@@@@@****+               
//    =#@@@######.   *@@@@@@@@#.*@@@@@.  [email protected]@@@@@#########*.      [email protected]@@@%                    
//      @@@%%####:   *@@@@@%@@@@%@@@@@. [email protected]@@@@@@@@@@@@@@@@.      [email protected]@@@%                    
//      #%%%%%%@@-   *@@@@% *@@@@@@@@@. -%%%%%%%%%%%%@@@@@:      [email protected]@@@%                    
//      ######%@@-   *@@@@%  [email protected]@@@@@@@   .:::::[email protected]@@@:      [email protected]@@@%                    
//      @@@@@@@@@:   #@@@@#   .%@@@@@@   *@@@@@@@@@@@@@@@@:      [email protected]@@@%                    
//         [email protected]       #@@@@#     *@@@@@:  #@@@@@@@@@@@@@@@@:      [email protected]@@@%                    
//                   =#***=      [email protected]@@+.  -++++++++++++++++       :%@@@%                    
//                                                                 .=#%                                         

/// @creator:     NinjaSquad
/// @author:      peker.eth - twitter.com/peker_eth

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NinjaSquadToken is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    uint constant public MAX_SUPPLY = 10 ** 7 * 1e18;

    uint public immutable YIELD_START_DATE;
    uint constant MINT_LIMIT_IN_A_TIMEFRAME = 50000 ether;

    uint public constant TEAM_TOKENS = MAX_SUPPLY * 4 / 100;
    uint public constant PARTNERSHIP_TOKENS = MAX_SUPPLY * 5 / 100;
    uint public constant ECOSYSTEM_TOKENS = MAX_SUPPLY * 5 / 100;

    bool _isLockedTokensClaimed = false;
    bool _isOnlyWhitelist = true;

    address _signer;
    address _teamAddress;
    address _ecosystemAddress;
    address _partnershipAddress;

    bytes32 private immutable _MINT_WITH_SIGNATURE_TYPEHASH =
        keccak256("MintWithSignature(address to_,uint256 amount_,uint256 nonce_,uint256 deadline_)");

    mapping (address => bool) _isWhitelisted;
    mapping (uint => uint) _mintAmountInTimeframe;

    /*
    * @params
    * signer_: 0xAF9980f1b55205b4cEc62892A5494917Cb506109
    * yieldStartDate_: 1640995200 –  1 January 2022 00:00:00
    * liquidityAddress_: 0xaB910585A6dACEeA4EAbB587e6aAefC888dd9716
    * stakeRewardAddress_: 0xb1887F24b412b026F935F76fE47305Fcb22885E9
    * teamAddress_: 0xB0152681977B0ecEC8dAF37BBd8008188FBf3a99
    * ecosystemAddress_: 0x73Caae3598d8b2381c36ae5778909cf42DC0c65D
    * partnershipAddress_: 0x0d3A6A576dF2681c6Eb0ab739E701D6AfE168CB3
    */

    constructor(address signer_, uint yieldStartDate_, address liquidityAddress_, address stakeRewardAddress_, address teamAddress_, address ecosystemAddress_, address partnershipAddress_) ERC20("Ninja Squad Token", "NST") ERC20Permit("Ninja Squad Token") {
        _signer = signer_;
        
        YIELD_START_DATE = yieldStartDate_;

        _isWhitelisted[address(0)] = true;
        _isWhitelisted[address(this)] = true;
        _isWhitelisted[msg.sender] = true;

        uint liquidityTokens = MAX_SUPPLY * 10 / 100;
        uint stakeRewardTokens = MAX_SUPPLY * 10 / 100;

        _isWhitelisted[liquidityAddress_] = true;
        _isWhitelisted[stakeRewardAddress_] = true;

        _teamAddress = teamAddress_;
        _ecosystemAddress = ecosystemAddress_;
        _partnershipAddress = partnershipAddress_;

        _mint(liquidityAddress_, liquidityTokens);
        _mint(stakeRewardAddress_, stakeRewardTokens);
    }

    function getSigner() public view returns (address) {
        return _signer;
    }

    function setSigner(address signer_) public onlyOwner () {
        _signer = signer_;
    }

    function setWhitelist(address[] memory addresses_, bool value_) public onlyOwner {
        for (uint i = 0; i < addresses_.length; i++) {
            _isWhitelisted[addresses_[i]] = value_;
        }
    }

    function stopOnlyWhitelist() public onlyOwner {
        _isOnlyWhitelist = false;
    }

    function mintWithSignature(address to_, uint256 amount_, uint256 nonce_, uint256 deadline_, uint8 v, bytes32 r, bytes32 s) public {
        require(msg.sender == to_, "Not allowed");
        require(block.timestamp <= deadline_, "expired deadline");

        require(totalSupply() + amount_ <= MAX_SUPPLY, "Excceds max supply");

        uint timeframe = block.timestamp / 1 days;
        require(_mintAmountInTimeframe[timeframe] + amount_ <= MINT_LIMIT_IN_A_TIMEFRAME, "Exceeds mint limit");

        bytes32 structHash = keccak256(abi.encode(_MINT_WITH_SIGNATURE_TYPEHASH, msg.sender, amount_, _useNonce(msg.sender), deadline_));

        bytes32 hash = _hashTypedDataV4(structHash);
 
        address signer_ = ECDSA.recover(hash, v, r, s);
        require(signer_ == _signer, "invalid signature");

        _mintAmountInTimeframe[timeframe] += amount_;

        _mint(msg.sender, amount_);
    }

    function claimLockedTokens() public onlyOwner {
        require(block.timestamp >= YIELD_START_DATE + 365 days, "not yet");
        require(_isLockedTokensClaimed == false, "already claimed");

        _isLockedTokensClaimed = true;

        require(totalSupply() + TEAM_TOKENS + PARTNERSHIP_TOKENS + ECOSYSTEM_TOKENS <= MAX_SUPPLY, "Excceds max supply");

        _mint(_teamAddress, TEAM_TOKENS);
        _mint(_partnershipAddress, PARTNERSHIP_TOKENS);
        _mint(_ecosystemAddress, ECOSYSTEM_TOKENS);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override { 
        if (_isOnlyWhitelist) {
            if (tx.origin != owner()) {
                require(_isWhitelisted[msg.sender], "not whitelisted");
                require(_isWhitelisted[from], "not whitelisted");
                require(_isWhitelisted[to], "not whitelisted");
            }
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}