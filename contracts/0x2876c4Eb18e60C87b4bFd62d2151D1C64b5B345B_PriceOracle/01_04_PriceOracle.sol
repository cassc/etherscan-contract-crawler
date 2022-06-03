pragma solidity ^0.8.2;

import "./interface/IOracle.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PriceOracle is Initializable{

    address public admin;
    address public pendingAdmin;

    mapping(address => mapping(address => uint256)) public prices;

    mapping(address => bool) public feedPriceAddressMap;

    event PriceChanged(address collection, address denotedToken, uint256 price);

    function initialize() public initializer {
        admin = msg.sender;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "require admin auth");
        _;
    }
    
    modifier onlyFeedPriceAddress(){
        require(feedPriceAddressMap[msg.sender], "this address cannot be feed price");
        _;
    }

    function setPendingAdmin(address newPendingAdmin) external onlyAdmin{
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() external{
        require(msg.sender == pendingAdmin, "only pending admin could accept");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setFeedPriceAddressMap(address[] memory accounts, bool[] memory flags) external onlyAdmin{
        require(accounts.length == flags.length, "different length");
        for(uint256 i=0; i<accounts.length; i++){
            feedPriceAddressMap[accounts[i]] = flags[i];
        }
    }

    function getPrice(address collection, address denotedToken) external view returns (uint256, bool){
        return (prices[collection][denotedToken], true);
    }

    function setPrice(address[] memory collections, address denotedToken, uint256[] memory _prices) external onlyFeedPriceAddress{
        require(collections.length == _prices.length, "different lengths");
        for(uint256 i=0; i<collections.length; i++){
            prices[collections[i]][denotedToken] = _prices[i];
            emit PriceChanged(collections[i], denotedToken, _prices[i]);
        }
    }
}