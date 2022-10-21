// SPDX-License-Identifier: MIT

// @title: All Gold Spaceship
// @author: Humie Devs
//              ..                                              ./%@&(.            
//          *@@@@@@@#                                         (@@&*.,&@@(          
//         *@@@@@@@@@(                                       ,@@,     ,@@*         
//          @@@@@@@@@.             .(@@@@@@@@@@%*             &@&.   .&@&          
//            /#%#/(@@&,     ,%@@@@#/,,&@#   .,*#&@@@%/        .#@@@@@%,           
//                    &@@(*@@@/        ,@@#.,#@@@@@@@@@@@#                         
//                     [email protected]@@&,          #@@@@#/.        ,@@@&,                      
//                    %@&.,&@@(    ,&@@&/.&@@,       /@@@*/@@@,                    
//                  *@@,     #@@&@@@%.     *@@&.  [email protected]@@%    #@@@#                   
//                 /@@.       (@@@@#.        *@@@@@@*      (@&@@#                  
//                ,@@.      %@@%  #@@&*      .&@@@@&.      &@/ @@(                 
//                #@&/.   ,@@%      ,@@@#. (@@@*  /@@@%,  &@%  /@@.                
//                %@%#&@@@@@/          #@@@@%.       ,%@@@@&.  ,@@*                
//                %@#   %@@&@@@&.     /@@@@@@#         /@@&&@@@@@@,                
//                (@%  %@&    /&@@%*%@@%    #@@&*    .&@@,     (@@.                
//                 @@([email protected]@*       /@@@#        ,@@@# &@@*      *@@,                 
//                  &@&@&.    .&@@%.%@@%         &@@@#       ,@@*                  
//                   &@@@,  /@@@/     #@@/    *@@@#,&@@#.   (@@.                   
//                    *@@@@@@%.        [email protected]@@@@@@%      #@@&#@@(                     
//                      *@@@%(,.. .,*(&@@@@@/          ,&@@@(                      
//                         /@@@@@@@@%/.   (@@.      (@@@#  (@@&,                   
//          #@@@@@@@%.         /&@@@@&%%##(&@@&@@@@@/.       .&@@@@@@@#            
//         &@#     *@@*               .,*//*,,                *@@@@@@@@@/          
//         &@#     [email protected]@*                                       ,@@@@@@@@@*          
//         .%@@@&@@@&.                                          #@@@@@#                                                                                                                                                                            
//                                                     
// ............................................................................

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "./Adminable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// Everything required for construction.
/// @param name The ERC721 name.
/// @param symbol The ERC721 symbol.
/// @param baseURI The initial ERC721 baseURI (can be modified by admin).
/// @param merkleRoot1 Stage 1 Whitelist Merkle Tree Root hash (can be modified by admin).
/// @param merkleRoot2 Stage 2 Whitelist Merkle Tree Root hash (can be modified by admin).
/// @param merkleRoot3 Stage 3 Whitelist Merkle Tree Root hash (can be modified by admin).
/// @param merkleRoot4 Stage 4 Whitelist Merkle Tree Root hash (can be modified by admin).
/// @param admin The initial admin address (onchain administration).
/// @param owner The initial owner address (offchain administration).
struct ConstructorConfig {
    string name;
    string symbol;
    string baseURI;
    bytes32 merkleRoot1;
    bytes32 merkleRoot2;
    bytes32 merkleRoot3;
    bytes32 merkleRoot4;
    address admin;
    address owner;
}

/// @title AllGoldSpaceship
/// @notice
///
/// this one is about money, power, and the shxt that comes w it. 
/// in the 2500’s i got really famous for my music. 
/// 
/// i lost myself completely and got obsessed w the fame. 
/// when i came through the gate and landed here, i didnt wanna go public. 
/// 
/// i was kind of afraid it could happen again. - angelbaby
///
/// Hume Music NFT 
contract AllGoldSpaceship is ERC721A, Ownable, Adminable {
    
    using Address for address payable;
    using SafeMath for uint256;

    /// Contract constants
    uint256 public constant MAX_TOKENS = 300;
    uint256 public constant TOKENS_RESERVED = 12;
    uint256 public constant MAX_PURCHASE_PUBLIC = 2; // max music nft minted during public sale
    uint256 public constant NFT_PRICE_1 = 0.01 ether; // 0.01
    uint256 public constant NFT_PRICE_2 = 0.03 ether; // 0.03 * 10 ** 18
    uint256 public constant NFT_PRICE_3 = 0.05 ether; // 0.05 * 10 ** 18
    uint256 public constant NFT_PRICE_PUBLIC = 0.07 ether; // 0.07 * 10 ** 18

    /// @dev tracks the state of the contract
    enum State {
        Setup,
        Legendary,
        UltraRare,
        RarePhase1,
        RarePhase2,
        Sale
    }

    /// @dev set by admin and ready by minting methods
    State private _state;

    /// @dev set by admin and read by ERC721A._baseURI
    string private baseURI;

    /// @dev set by admin and read by minting methods
    mapping(State => bytes32) public merkleRoots;

    /// @dev mint price mapping per state
    mapping(State => uint256) public priceByState;

    /// @dev tracks claimed tokens (single token) from Whitelisted
    mapping(State => mapping(address => uint256)) public claimedWhitelistTokens;

    /// Emitted when contract is constructed.
    /// @param sender the `msg.sender` that deploys the contract.
    /// @param config All config used by the constructor.
    event Construct(address sender, ConstructorConfig config);

    /// Emitted when the base URI is changed by the admin.
    /// @param sender the `msg.sender` (admin) that sets the base URI.
    /// @param baseURI the new base URI.
    event BaseURI(address sender, string baseURI);

    /// Emitted when the Merkle Root is changed by the admin.
    /// @param sender the `msg.sender` (admin) that sets the base URI.
    /// @param merkleRoot the new Merkle Root Hash.
    /// @param state which presale state's whitelist changed
    event MerkleRoot(address sender, bytes32 merkleRoot, State state);

    /// Token constructor.
    /// Assigns owner and admin roles, mints all tokens for the admin and sets
    /// initial base URI.
    /// @param config_ All construction config.
    constructor(ConstructorConfig memory config_)
        ERC721A(config_.name, config_.symbol)
    {
        // Enter setup
        _state = State.Setup;

        // Setup roles
        _transferAdmin(config_.admin);
        _transferOwnership(config_.owner);

        // Mint reserve tokens
        _safeMint(admin, TOKENS_RESERVED);

        // Set Merkle Roots
        merkleRoots[State.Legendary] = config_.merkleRoot1;
        merkleRoots[State.UltraRare] = config_.merkleRoot2;
        merkleRoots[State.RarePhase1] = config_.merkleRoot3;
        merkleRoots[State.RarePhase2] = config_.merkleRoot4;

        // Set Prices
        priceByState[State.Legendary] = NFT_PRICE_1;
        priceByState[State.UltraRare] = NFT_PRICE_2;
        priceByState[State.RarePhase1] = NFT_PRICE_3;
        priceByState[State.RarePhase2] = NFT_PRICE_3;
        priceByState[State.Sale] = NFT_PRICE_PUBLIC; // public sale

        // Set initial baseURI.
        baseURI = config_.baseURI;

        // Inform the world.
        emit Construct(msg.sender, config_);
    }

    /// Presale minting function
    /// Allows minting only of the current PreSale state
    /// @param quantity amount of tokens to mint
    /// @param allowance Whitelist slots allowed
    /// @param merkleProof Needed whitelist-check proof
    /// @param state_ For which `State` the minting is targeted at (optional validation - passed from the FE)
    function mintWhitelist(uint64 quantity, uint64 allowance, bytes32[] calldata merkleProof, State state_) public payable {
        // Are we on that Presale?
        require(currentState() != State.Setup, "Presale hasn't opened yet");
        require(currentState() != State.Sale, "Presale has ended, use the public sale mint method");
        require((valueOfState(state_) > valueOfState(State.Setup)) && (valueOfState(state_) < valueOfState(State.Sale)), 
        "This is only available for presale");
        require(currentState() == state_, "Wrong presale stage selected"); // optional
        // Require at least 1 token to be minted
        require(quantity != 0, "Can't mint 0 tokens");
        // Require token not already claimed
        require(claimedWhitelistTokens[currentState()][msg.sender] + quantity <= allowance, "Exceeds whitelist slots");
        // Require no not exceed max tokens
        require(totalSupply().add(quantity) <= MAX_TOKENS, "Sorry, not enough tokens left.");
        // Pay the right price 
        require(priceByState[state_].mul(quantity) <= msg.value, "Not enough ETH sent");
        // Require correct proof (whitelist validation)
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, allowance));
        require(MerkleProof.verify(merkleProof, merkleRoots[currentState()], leaf), "Invalid merkle proof");
        
        // Sender claims token - will be reverted if below fails
        claimedWhitelistTokens[currentState()][msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    /// Public Sale minting function
    /// @param quantity amount of tokens to mint
    function mintPublic(uint64 quantity) public payable {
        // Are we on Public Sale?
        require(currentState()==State.Sale, "Public Sale is not open yet");
        // Require sale to limit to `MAX_PURCHASE_PUBLIC` tokens per humie
        require(balanceOf(msg.sender) + quantity <= MAX_PURCHASE_PUBLIC, "Exceeds public purchase");
        // Require no not exceed max tokens
        require(totalSupply().add(quantity) <= MAX_TOKENS, "Sorry, not enough tokens left.");
        // Pay the correct price
        require(priceByState[State.Sale].mul(quantity) <= msg.value, "Not enough ETH sent");
        
        // Mint tokens
        _safeMint(msg.sender, quantity);
    }

    /// @return current contract state
    function currentState() virtual public view returns (State) {
        return _state;
    }

    /// @return current price to mint
    function currentPrice() virtual public view returns (uint256) {
        return priceByState[_state];
    }

    /// @return current contract state as uint8
    function currentStateValue() internal view returns (uint8) {
        return uint8(_state);
    }

    /// @return State as uint8
    function valueOfState(State state_) internal pure returns (uint8) {
        return uint8(state_);
    }

    /// Admin MAY set a new base URI at any time.
    /// @param baseURI_ The new base URI that all token URIs are build from.
    function adminSetBaseURI(string memory baseURI_) external onlyAdmin {
        baseURI = baseURI_;
        emit BaseURI(msg.sender, baseURI_);
    }

    /// Admin MAY set a new Merkle Root Hash at any time.
    /// @param merkleRoot_ The new Merkle Root
    function adminSetMerkleRoot(bytes32 merkleRoot_, State state_) external onlyAdmin {
        require((valueOfState(state_) > valueOfState(State.Setup)) && (valueOfState(state_) < valueOfState(State.Sale)), 
        "Only Presale states have Merkle Whitelists");
        merkleRoots[state_] = merkleRoot_;
        emit MerkleRoot(msg.sender, merkleRoot_, state_);
    }

    /// Admin MAY set a new owner at any time.
    /// The owner has no onchain rights other than transferring ownership.
    /// @param owner_ The new owner address.
    function adminSetOwner(address owner_) external onlyAdmin {
        _transferOwnership(owner_);
    }

    /// Admin WILL manually progress the state of the contract, until `State.Sale` is reached
    /// @param state_ The new state
    function adminChangeState(State state_) public onlyOwner {
        require(_state != State.Sale, "Sale has gone public, can't change now");
        _state = state_;
    }

    /// @inheritdoc ERC721A
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @inheritdoc ERC721A
    function _baseURI() internal view override returns (string memory baseURI_) {
        baseURI_ = baseURI;
    }

    /// Admin WILL withdraw all ETH
    function adminWithdrawETH(address payable payee) public virtual onlyAdmin {
        payee.sendValue(address(this).balance);
    }
}