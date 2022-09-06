// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@gnosis.pm/zodiac/contracts/core/Module.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPOAP.sol";


contract Test is Module {
    error TokenAlreadyRedeemedError(); // TODO: if a token already redeemed. Prevents users from trading around POAPs and claiming
    error PoapNotPartOfEventError(); // If token passed not part of our event
    error NotPoapOwnerError(); // If user doesn't own the poap
    error NotAllowedError(); //If user does not own the POAP
    error HasClaimedError(); //If user already claimed
    error ExpiredError(); //If claim period has passed

    //TODO - gas: we could prob reduce gas by not importing the whole interface here
    IPOAP public poap; // poap to verify 
    IERC20 public token; // the collection token


    // Allow only one claim per address
    mapping(uint256 => bool) public hasClaimed;

    //TODO - gas: would uint32 really save any storage here?
    // When this contract expires
    uint256 public expirationTime;
    uint256 public eventID;


    constructor(address _owner, address _poap, address _token, uint256 _expirationTime, uint256 _eventID) {
        bytes memory initializeParams = abi.encode(_owner, _poap, _token, _expirationTime, _eventID);
        setUp(initializeParams);
    }

    // Boilerplate for gnosis modules
    /// @dev Initialize function, will be triggered when a new proxy is deployed
    /// @param initializeParams Parameters of initialization encoded
    function setUp(bytes memory initializeParams) public override initializer {
        __Ownable_init();
        (address _owner, address _poap, address _token, uint256 _expirationTime, uint256 _eventID) = abi.decode(initializeParams, (address, address, address, uint256, uint256));

        poap = IPOAP(_poap);
        token = IERC20(_token);
        expirationTime = _expirationTime;
        eventID = _eventID;
        setAvatar(_owner); // Usually the safe
        setTarget(_owner); // Usually the safe
        transferOwnership(_owner);
    }

  
    function mint(uint256 _tokenID) external {

        // Check poap token part of event
        if(poap.tokenEvent(_tokenID) != eventID) {
            revert PoapNotPartOfEventError();
        }

        // Check owner
        if(poap.ownerOf(_tokenID) != msg.sender) {
            revert NotPoapOwnerError();
        }

        //Check expiration
        if(expirationTime <= block.timestamp) {
            revert ExpiredError();
        }
        
        //Check has claimed
        if(hasClaimed[_tokenID]) {
            revert HasClaimedError();
        }

        // Even though unlikely, do before exec() call to preven reentrancy attack
        hasClaimed[_tokenID] = true;

        exec(
            address(token),
            0,
            abi.encodeWithSelector(
                bytes4(keccak256("mint(address,uint256)")), 
                msg.sender, 
                1e18
            ),
            Enum.Operation.Call
        );    
    }
}