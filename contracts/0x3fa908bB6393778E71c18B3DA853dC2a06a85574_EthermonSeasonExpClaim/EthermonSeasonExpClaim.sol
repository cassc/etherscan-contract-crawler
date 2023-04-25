/**
 *Submitted for verification at Etherscan.io on 2023-04-25
*/

// File: contracts/Context.sol

pragma solidity 0.6.6;


contract Context {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/BasicAccessControl.sol

pragma solidity 0.6.6;

contract BasicAccessControl is Context {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner {
    require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/SafeMathEthermon.sol

pragma solidity 0.6.6;

contract SafeMathEthermon {
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }
}

// File: contracts/EthermonSeasonData.sol

pragma solidity 0.6.6;


contract EthermonSeasonData is
    BasicAccessControl,
    SafeMathEthermon
{

    mapping(uint256 => mapping(uint64 => uint256)) public seasonMonExp;

    uint32 public currentSeason = 0;
    uint256 public seasonEndsBy = 0;

    function getExp(uint64 _objId, uint32 _season)
        public
        view
    returns (uint256)
    {
        return seasonMonExp[_season][_objId];
    }


   function getCurrentSeasonExp(uint64 _objId)
        external
        view
    returns (uint256)
    {
        validateCurrentSeason();
        return seasonMonExp[currentSeason][_objId];
    }





  function setCurrentSeason(uint32 _season, uint256 _seasonEndTime)
        public
        onlyModerators
    {
        currentSeason = _season;
        seasonEndsBy = _seasonEndTime;
    }


    function validateCurrentSeason()  view internal {
        require (block.timestamp < seasonEndsBy);
    }


  function getCurrentSeason()
        view
        external
        returns (uint32)

    {
        validateCurrentSeason();
        return currentSeason;
    }



    function increaseMonsterExp(uint64 _objId, uint256 amount)
        public
        onlyModerators
    {
        validateCurrentSeason();
        uint256 exp = seasonMonExp[currentSeason][_objId];
        seasonMonExp[currentSeason][_objId]  = uint256(safeAdd(exp, amount));
    }

    function decreaseMonsterExp(uint64 _objId, uint256 amount)
        public
        onlyModerators
    {
        validateCurrentSeason();
        uint256 exp = seasonMonExp[currentSeason][_objId];
        seasonMonExp[currentSeason][_objId]  = uint256(safeSubtract(exp, amount));
    }


 function increaseMonsterExpBySeason(uint64 _objId, uint256 amount, uint32 
 _season)
        public
        onlyModerators
    {
        uint256 exp = seasonMonExp[_season][_objId];
        seasonMonExp[_season][_objId]  = uint256(safeAdd(exp, amount));
    }

    function decreaseMonsterExp(uint64 _objId, uint256 amount, uint32 
 _season)
        public
        onlyModerators
    {
        uint256 exp = seasonMonExp[_season][_objId];
        seasonMonExp[_season][_objId]  = uint256(safeSubtract(exp, amount));
    }







  
}

// File: contracts/EthermonSeasonExpClaim.sol

/**
 *Submitted for verification at polygonscan.com on 2021-09-04
 */

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;
// copyright [email protected]



contract EthermonSeasonExpClaim is BasicAccessControl, SafeMathEthermon {
    bytes constant SIG_PREFIX = "\x19Ethereum Signed Message:\n32";


    struct MonsterObjAcc {
        uint64 monsterId;
        uint32 classId;
        address trainer;
        string name;
        uint32 exp;
        uint32 createIndex;
        uint32 lastClaimIndex;
        uint256 createTime;
    }

    struct ExpToken {
        uint32 rId;
        uint64 monster_id;
        uint32 exp;
    }
    address public seasonDataContract;
    address public verifyAddress;
    //address public publicAdress;

    mapping(uint256 => mapping(uint64 => uint256)) public requestStatus;// request_id => status

    event EventClaimExp(uint32 indexed rId, uint64 monster_id, uint32 exp);

   

    /** 
        Below function is beign called the backend which passes some info 
        by encoding like id, exp_value, monster_id, address etc...
    	r, s, v = sign_claim_matic_exp(claim_exp_token, monster.trainer)

     */
    function getVerifySignature(address sender, bytes32 _token)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(sender, _token));
    }

    function getExp(address sender, bytes32 _token)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(sender, _token));
    }



    function getVerifyAddress(
        address sender,
        bytes32 _token,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public pure returns (address) {
        bytes32 hashValue = keccak256(abi.encodePacked(sender, _token));
        bytes32 prefixedHash = keccak256(
            abi.encodePacked(SIG_PREFIX, hashValue)
        );
        return ecrecover(prefixedHash, _v, _r, _s);
    }

    // public
    function extractExpToken(bytes32 _rt)
        public
        pure
        returns (
            uint32 rId,
            uint64 monster_id,
            uint32 exp
        )
    {
        rId = uint32(uint256(_rt >> 192)); //From python backend in crypt.py shifting to right to neglect other values and get reqId (64 + 32 + 32 + 64)
        monster_id = uint64(uint256(_rt >> 128)); //(64 + 32 + 32)
        exp = uint32(uint256(_rt >> 96)); //(64 + 32)
    }

    /**
        After we call getVerifySignature from backend we will need to/be calling 
        below function which will decode and recover signature sent from backend
        in response.
     */
    function claimExp(
        bytes32 _token,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external isActive {
        if (verifyAddress == address(0)) revert();
        //This msg.sender is from backend and sent by the owner of the address it used to deteduct gas
        if (getVerifyAddress(msg.sender, _token, _v, _r, _s) != verifyAddress)
            revert();

        ExpToken memory eToken;

        (eToken.rId, eToken.monster_id, eToken.exp) = extractExpToken(_token);
        EthermonSeasonData seasonData = EthermonSeasonData(
            seasonDataContract
        );
        uint32 currentSeason = seasonData.getCurrentSeason();
        if (eToken.rId == 0 || requestStatus[currentSeason][eToken.rId] > 0) revert(); //rId is reqId coming from python backend should be diff everytime

       

      
        
        seasonData.increaseMonsterExp(eToken.monster_id, eToken.exp);

        requestStatus[currentSeason][eToken.rId] = 1; //request_id already taken 

        emit EventClaimExp(eToken.rId, eToken.monster_id, eToken.exp);
    }

    function incExp(uint64 monster_id, uint32 exp) public onlyModerators {
            EthermonSeasonData seasonData = EthermonSeasonData(
            seasonDataContract
        );

        seasonData.increaseMonsterExp(monster_id, exp);
    }

    function setConfig(address _verifyAddress, address _seasonDataContract)
        public
        onlyModerators
    {
        verifyAddress = _verifyAddress;
        seasonDataContract = _seasonDataContract;
        //        publicAdress = address(0);
    }
}