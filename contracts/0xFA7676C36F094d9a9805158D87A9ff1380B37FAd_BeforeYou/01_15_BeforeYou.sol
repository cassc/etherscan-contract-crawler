// SPDX-License-Identifier: MIT

// @title: Before You
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
/// @param admin The initial admin address (onchain administration).
/// @param owner The initial owner address (offchain administration).
struct ConstructorConfig {
    string name;
    string symbol;
    string baseURI;
    bytes32 merkleRoot1;
    bytes32 merkleRoot2;
    bytes32 merkleRoot3;
    address admin;
    address owner;
}

/// @title BeforeYou
/// @notice
///
/// it's hard for me to even remember who i was before clio. 
/// there are so many things i would ask her if she was here. 
///
/// holding her in my arms after the bombing, screaming her name, i saw my whole life flash before me. 
/// im sure youve all had someone you loved that gave you purpose. 
///
/// i want you to imagine that person when you listen to this. - angelbaby
///
/// Hume Music NFT 
contract BeforeYou is ERC721A, Ownable, Adminable {
    
    using Address for address payable;
    using SafeMath for uint256;

    /// Contract constants
    uint256 public constant NFT_PRICE_1 = 0.00 ether; // FREE
    uint256 public constant NFT_PRICE_2 = 0.02 ether; // 0.02 * 10 ** 18
    uint256 public constant NFT_PRICE_3 = 0.03 ether; // 0.03 * 10 ** 18

    /// @dev tracks the state of the contract
    enum State {
        Setup,
        Legendary,
        UltraRare,
        Rare,
        SaleEnd
    }

    /// @dev set by admin and ready by minting methods
    State private _state;

    /// @dev set by admin and read by ERC721A._baseURI
    string private baseURI;

    /// @dev set by admin and read by minting methods
    mapping(State => bytes32) public merkleRoots;

    /// @dev mint price mapping per state
    mapping(State => uint256) public priceByState;

    /// @dev set automatically when sale ends
    uint256 public finalSupply;

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

        // Set Merkle Roots
        merkleRoots[State.Legendary] = config_.merkleRoot1;
        merkleRoots[State.UltraRare] = config_.merkleRoot2;
        merkleRoots[State.Rare] = config_.merkleRoot3;

        // Set Prices
        priceByState[State.Legendary] = NFT_PRICE_1;
        priceByState[State.UltraRare] = NFT_PRICE_2;
        priceByState[State.Rare] = NFT_PRICE_3;

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
        require(currentState() != State.SaleEnd, "Sale has ended");
        require((valueOfState(state_) > valueOfState(State.Setup)) && (valueOfState(state_) < valueOfState(State.SaleEnd)), 
        "This is only available for presale");
        require(currentState() == state_, "Wrong presale stage selected"); // optional
        // Require at least 1 token to be minted
        require(quantity != 0, "Can't mint 0 tokens");
        // Require token not already claimed
        require(claimedWhitelistTokens[currentState()][msg.sender] + quantity <= allowance, "Exceeds whitelist slots");
        // Pay the right price 
        require(priceByState[state_].mul(quantity) <= msg.value, "Not enough ETH sent");
        // Require correct proof (whitelist validation)
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, allowance));
        require(MerkleProof.verify(merkleProof, merkleRoots[currentState()], leaf), "Invalid merkle proof");
        
        // Sender claims token - will be reverted if below fails
        claimedWhitelistTokens[currentState()][msg.sender] += quantity;
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
        require((valueOfState(state_) > valueOfState(State.Setup)) && (valueOfState(state_) < valueOfState(State.SaleEnd)), 
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

    /// Owner WILL manually progress the state of the contract, until `State.SaleEnd` is reached
    /// @param state_ The new state
    function adminChangeState(State state_) public onlyOwner {
        require(_state != State.SaleEnd, "Sale has ended, can't change now");
        _state = state_;

        if(_state == State.SaleEnd) {
            finalSupply = totalSupply();
        }
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