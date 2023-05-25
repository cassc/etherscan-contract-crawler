pragma solidity ^0.5.11;

import "./IERC20Token.sol";
import "./HBTCAdmin.sol";
import "./HBTCLogic.sol";
import "./HBTCStorage.sol";
import "./Pausable.sol";

contract HBTCToken is IERC20Token,Pausable, HBTCAdmin{
    string public constant name = "Huobi BTC";

    string public constant symbol = "HBTC";

    uint8 public constant decimals = 18;

    HBTCLogic private logic;

    event Burning(address indexed from, uint256 value, string proof, string  btcAddress, address burner);
    event Burned(address indexed from, uint256 value, string proof, string  btcAddress);
    event Minting(address indexed to, uint256 value, string proof, address  minter);
    event Minted(address indexed to, uint256 value, string proof);

    constructor(address owner0, address owner1, address owner2) public{
        initAdmin(owner0, owner1, owner2);
    }


    function totalSupply() public view returns (uint256 supply) {
        return logic.getTotalSupply();
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return logic.balanceOf(owner);
    }

    function mint(address to, uint256 value, string memory proof,bytes32 taskHash) public whenNotPaused returns(bool){
        require(itemAddressExists(OPERATORHASH, msg.sender), "wrong operator");
        uint256 status = logic.mintLogic(value,to,proof,taskHash, msg.sender, operatorRequireNum);
        if (status == 1){
            emit Minting(to, value, proof, msg.sender);
        }else if (status == 3) {
            emit Minting(to, value, proof, msg.sender);
            emit Minted(to, value, proof);
            emit Transfer(address(0x0),to,value);
        }
        return true;
    }


    function burn(address from,uint256 value,string memory btcAddress,string memory proof, bytes32 taskHash)
    public whenNotPaused returns(bool){
        require(itemAddressExists(OPERATORHASH, msg.sender), "wrong operator");
        uint256 status = logic.burnLogic(from,value,btcAddress,proof,taskHash, msg.sender, operatorRequireNum);
        if (status == 1){
           emit Burning(from, value, proof,btcAddress, msg.sender);
        }else if (status == 3) {
           emit Burning(from, value, proof,btcAddress,  msg.sender);
           emit Burned(from, value, proof,btcAddress);
           emit Transfer(from, address(0x0),value);
        }
        return true;
    }

    function cancelTask(bytes32 taskHash)  public returns(uint256){
        require(itemAddressExists(OPERATORHASH, msg.sender), "wrong operator");
        return logic.cancelTask(taskHash);
    }

    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        bool flag = logic.transferLogic(msg.sender,to,value);
        require(flag, "transfer failed");
        emit Transfer(msg.sender,to,value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused  returns (bool){
        bool flag = logic.transferFromLogic(msg.sender,from,to,value);
        require(flag,"transferFrom failed");
        emit Transfer(from, to, value);
        return true;
    }


    function approve(address spender, uint256 value) public whenNotPaused returns (bool){
        bool flag = logic.approveLogic(msg.sender,spender,value);
        require(flag, "approve failed");
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256 remaining){
        return logic.getAllowed(owner,spender);
    }

    function modifyAdminAddress(string memory class, address oldAddress, address newAddress) public whenPaused{
        require(newAddress != address(0x0), "wrong address");
        bool flag = modifyAddress(class, oldAddress, newAddress);
        if(flag){
            bytes32 classHash = keccak256(abi.encodePacked(class));
            if(classHash == LOGICHASH){
                logic = HBTCLogic(newAddress);
            }else if(classHash == STOREHASH){
                logic.resetStoreLogic(newAddress);
            }
        }
    }

    function getLogicAddress() public view returns(address){
        return address(logic);
    }

    function getStoreAddress() public view returns(address){
        return logic.getStoreAddress();
    }

    function pause() public{
        require(itemAddressExists(PAUSERHASH, msg.sender), "wrong user to pauser");
        doPause();
    }

}