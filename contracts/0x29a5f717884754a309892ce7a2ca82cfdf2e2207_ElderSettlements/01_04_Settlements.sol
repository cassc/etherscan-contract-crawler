// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

//import "hardhat/console.sol";
import "./ERC721.sol"; 
import "./Interfaces.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract ElderSettlements is ERC721 {

    function name() external pure returns (string memory) { return "EthernalElves: Elven Settlement"; }
    function symbol() external pure returns (string memory) { return "ELS"; }
       
    IERC1155Lite public artifacts;    

    bool private initialized; 
    address public validator;   
    bytes32 ketchup;
    
    mapping(uint256 => address) public landOwner; //memory slot for Owners, Timestamp and Actions    
    mapping(address => bool)    public auth; //memory slot for Authorized addresses
    mapping(bytes => uint256)  public usedSignatures; //memory slot for used signatures

    function initialize() public {
    
       require(!initialized, "Already initialized");
       admin                = msg.sender;   
       maxSupply            = 1000; 
       initialized          = true;
       validator            = 0x5A5f094437df669a2ec79a99589bB0E7aa9c26Bb;    
    }


    function mint(uint256 quantity) external returns (uint256 id) {
    
        isPlayer();
        uint256 price = totalSupply <= 800 ? 20 : 30;
        uint256 totalCost = price * quantity;

        require(artifacts.balanceOf(msg.sender, 1) >= totalCost, "Not Enough Artifacts");
        require(maxSupply - quantity >= 0, "No Elders Left");        
        
        artifacts.burn(msg.sender, 1, totalCost);

        return _mintLand(msg.sender, quantity);
    }


     function _mintLand(address _to, uint256 qty) private returns (uint16 id) {
        ////
        for(uint256 i = 0; i < qty; i++) {
        
        id = uint16(totalSupply + 1);           
         _mint(_to, id);           

        }
     
     }

    function tokenURI(uint256 _id) external view returns(string memory) {

      //return eldermetaDataHandler.getTokenURI(uint16(_id), eldersMeta[_id], isRevealed);
      string memory tokenURI = 'https://api.ethernalelves.com/api/settlements/';
      return string(abi.encodePacked(tokenURI, Strings.toString(_id)));

    }

    function stake(uint256[] calldata _id) external {

         isPlayer();
          
         for(uint256 i = 0; i < _id.length; i++) {
         isLandOwner(_id[i]);         
         require(ownerOf[_id[i]] != address(this));
         _transfer(msg.sender, address(this), _id[i]);      
         landOwner[_id[i]] = msg.sender;
         }
                    
    }

     function unstake(uint256[] calldata _id, bytes[] memory signatures, bytes[] memory authCodes) external {

         isPlayer();
         address owner = msg.sender;

          for (uint256 index = 0; index < _id.length; index++) {  
            isLandOwner(_id[index]);
            require(usedSignatures[signatures[index]] == 0, "Signature already used");   
            require(_isSignedByValidator(encodeSentinelForSignature(_id[index], owner, authCodes[index]),signatures[index]), "incorrect signature");
            usedSignatures[signatures[index]] = 1;
            
            landOwner[_id[index]] = address(0);
            _transfer(address(this), owner, _id[index]);      

            }
                    
    }


    
/*

█▀▄▀█ █▀█ █▀▄ █ █▀▀ █ █▀▀ █▀█ █▀
█░▀░█ █▄█ █▄▀ █ █▀░ █ ██▄ █▀▄ ▄█
*/

    function onlyOperator() internal view {    
       require(auth[msg.sender] == true, "not operator");

    }

    function onlyOwner() internal view {    
        require(admin == msg.sender, "not admin");
    }

    function isPlayer() internal {    
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}
        require((msg.sender == tx.origin && size == 0));
        ketchup = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    function isLandOwner(uint256 id) internal view {    
        require(msg.sender == landOwner[id] || msg.sender == ownerOf[id], "not your elder");
    }


/*
▄▀█ █▀▄ █▀▄▀█ █ █▄░█   █▀▀ █░█ █▄░█ █▀▀ ▀█▀ █ █▀█ █▄░█ █▀
█▀█ █▄▀ █░▀░█ █ █░▀█   █▀░ █▄█ █░▀█ █▄▄ ░█░ █ █▄█ █░▀█ ▄█
*/

    function setAddresses(address _artifacts)  public {
       onlyOwner();       
       artifacts            = IERC1155Lite(_artifacts);
       
    } 

    function setValidator(address _validator)  public {
       onlyOwner();
       validator = _validator;
    }
    
    function setAuth(address[] calldata adds_, bool status) public {
       onlyOwner();
       
        for (uint256 index = 0; index < adds_.length; index++) {
            auth[adds_[index]] = status;
        }
    }


    function encodeSentinelForSignature(uint256 id, address owner, bytes memory authCode) public pure returns (bytes32) {
        return keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", 
                    keccak256(
                            abi.encodePacked(id, owner, authCode))
                            )
                        );
    } 


    function _isSignedByValidator(bytes32 _hash, bytes memory _signature) private view returns (bool) {
                
                bytes32 r;
                bytes32 s;
                uint8 v;
                    assembly {
                            r := mload(add(_signature, 0x20))
                            s := mload(add(_signature, 0x40))
                            v := byte(0, mload(add(_signature, 0x60)))
                        }
                    
                        address signer = ecrecover(_hash, v, r, s);
                        return signer == validator;
  
            }
     


}