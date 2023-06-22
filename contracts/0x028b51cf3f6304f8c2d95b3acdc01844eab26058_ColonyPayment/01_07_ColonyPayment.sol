//import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ColonyPayment is Ownable {
    IERC20 public prime = IERC20(0xb23d80f5FefcDDaa212212F028021B41DEd428CF);
    mapping(address => bool) public allowList;
//    mapping(address => bool) public users;

    uint public price = 100 ether;
//    address public collectionAddress; // controlled at the echelon handler level

    uint public userCount = 0;
    uint public maxUsers = 14;
    bool public disabled = false;

    event Paid(uint userCount, address _address, uint primeAmount);

    constructor(address primeAddress) Ownable() {
        prime=IERC20(primeAddress);
    }

    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = true;
        }
    }

    function removeFromAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = false;
        }
    }

    function setMaxUsers(uint _maxUsers) external onlyOwner {
        maxUsers = _maxUsers;
    }

    function setUserCount(uint _userCount) external onlyOwner {
        userCount = _userCount;
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setDisabled(bool _val) external onlyOwner {
        disabled = _val;
    }

    function handleInvokeEchelon(
        address _from,
        address,
        address,
        uint256 _id,
        uint256,
        uint256 _primeValue,
        bytes memory _data
    ) public payable {

        require(disabled == false, "disabled");
        require(msg.sender == address(prime), "invalid caller");

        require(allowList[_from] == true, "invalid payer");
        require(_primeValue == price, "wrong amount");
        require(userCount < maxUsers, "max users reached");

        userCount += 1;
        allowList[_from] = false;

        emit Paid(userCount, _from, _primeValue);
    }


}