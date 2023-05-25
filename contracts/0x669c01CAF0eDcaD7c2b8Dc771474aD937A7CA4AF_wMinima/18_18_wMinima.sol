import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract wMinima is ERC20PresetMinterPauser {

    struct MinimaStruct {
        bytes32 minimaAddress;
        uint listPointer;
    }

    mapping(address => MinimaStruct) public minimaStructs;
    address[] public minimaList;
    uint256 public latestBridgeBlock;

    event NewAddress(address wminimaAddress, bytes32 minimaAddress);
    event UpdateAddress(address wminimaAddress, bytes32 minimaAddress);
    event DeleteAddress(address wminimaAddress);
    event UpdateLastBridgeBlock(uint256 block);
    

    function isMapped(address wminimaAddress) public view returns(bool isIndeed) {
        if(minimaList.length == 0) return false;
        return (minimaList[minimaStructs[wminimaAddress].listPointer] == wminimaAddress);
    }

    function getAddressCount() public view returns(uint minimaCount) {
        return minimaList.length;
    }

    function newAddress(bytes32 minimaAddress) public returns(bool success) {
        
        address wminimaAddress = msg.sender;
        
        if(isMapped(wminimaAddress)) revert();
        minimaStructs[wminimaAddress].minimaAddress = minimaAddress;
        minimaList.push(wminimaAddress);
        minimaStructs[wminimaAddress].listPointer = minimaList.length - 1;

        emit NewAddress(msg.sender, minimaAddress);
        return true;
    }

    function updateAddress(bytes32 minimaAddress) public returns(bool success) {
        
        address wminimaAddress = msg.sender;

        if(!isMapped(wminimaAddress)) revert();
        minimaStructs[wminimaAddress].minimaAddress = minimaAddress;
        
        emit UpdateAddress(msg.sender, minimaAddress);
        return true;
    }

    function deleteAddress() public returns(bool success) {
        
        address wminimaAddress = msg.sender;

        if(!isMapped(wminimaAddress)) revert();
        uint rowToDelete = minimaStructs[wminimaAddress].listPointer;
        address keyToMove = minimaList[minimaList.length-1];
        minimaList[rowToDelete] = keyToMove;
        minimaStructs[keyToMove].listPointer = rowToDelete;
        minimaList.pop();
        
        emit DeleteAddress(msg.sender);
        return true;
    }

    function updateLatestBridge() public
    {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter, and cannot update this value");
        latestBridgeBlock = block.number;
        emit UpdateLastBridgeBlock(block.number);
    }

    constructor () ERC20PresetMinterPauser("Wrapped Minima", "WMINIMA") {  
        _setupRole(MINTER_ROLE, msg.sender);
        latestBridgeBlock = 0;
    }
}