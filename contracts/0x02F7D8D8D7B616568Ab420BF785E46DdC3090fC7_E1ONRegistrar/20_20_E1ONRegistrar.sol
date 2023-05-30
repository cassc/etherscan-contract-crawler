//SPDX-License-Identifier: COPYRIGHT
pragma solidity ^0.8.15;

import {INameWrapper, PARENT_CANNOT_CONTROL, CAN_EXTEND_EXPIRY} from "@ensdomains/ens-contracts/contracts/wrapper/INameWrapper.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {BaseSubdomainRegistrar, InsufficientFunds, DataMissing, Unavailable, NameNotRegistered} from "./BaseSubdomainRegistrar.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


struct Name { 
    bool available;
    uint256 balance;
    string readableName;
    mapping(string => bool) subdomainMinted;
}

error ParentNameNotAvailable();
error SubdomainAlreadyMinted();
error InvalidLabel();
error InsufficientValue();
error TransferFailed();

contract E1ONRegistrar is BaseSubdomainRegistrar, ERC1155Holder, ReentrancyGuard, Ownable {
    mapping(bytes32 => Name) public names;
    AggregatorV3Interface internal priceFeed;
    
    event AddressRegistered(address owner, string name, bytes32 parent, uint64 expiry, string humanReadable, uint256 fee, uint256 timestamp);
    event AddressSetup(string labelName, bytes32 node);
    event Received(address sender, uint256 amount);
    event AddressRenewed(string name, bytes32 parent, uint64 newExpiry, uint256 fee, address owner);
    

    address public resolver;
    address private payout;

    constructor(address wrapper) BaseSubdomainRegistrar(wrapper) {
        payout = msg.sender;
    }

    function setPriceFeed(address _priceFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(
            _priceFeed 
        );

    }

    function setupDomain(
        bytes32 node,
        string calldata name
    ) public authorised(node) {
        names[node].available = true;
        names[node].readableName = name;
        emit AddressSetup(name, node);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    function subdomainMinted(bytes32 parentNode, string calldata label) public view returns (bool) {
        return names[parentNode].subdomainMinted[label];
    }

    function _parseUint(string memory s) internal pure returns (uint, bool) {
    bytes memory b = bytes(s);
    uint result = 0;
    bool success = false;
    for (uint i = 0; i < b.length; i++) {
        uint8 val = uint8(b[i]);
        if (val >= 48 && val <= 57) {
            success = true;
            result = result * 10 + (val - 48);
        } else {
            success = false;
            break;
        }
    }
    return (result, success);
}

    function _isAlphanumeric(string memory s) internal pure returns (bool) {
        bytes memory b = bytes(s);
        for (uint i = 0; i < b.length; i++) {
            uint8 val = uint8(b[i]);
            if (!((val >= 48 && val <= 57) || (val >= 65 && val <= 90) || (val >= 97 && val <= 122))) {
                return false;
            }
        }
        return true;
    }

    //change to we own 1-1000 + others 
    function isValidLabel(string memory label, address sender) internal view returns (bool) {
    uint labelAsInt;
    bool success;
    (labelAsInt, success) = _parseUint(label);

    if (success) {
        if ((labelAsInt >= 1 && labelAsInt <= 1000) ||
            (labelAsInt >= 1100 && labelAsInt <= 1200) ||
            (labelAsInt >= 2200 && labelAsInt <= 2300) ||
            (labelAsInt >= 3300 && labelAsInt <= 3400) ||
            (labelAsInt >= 4400 && labelAsInt <= 4500) ||
            (labelAsInt >= 5500 && labelAsInt <= 5600) ||
            (labelAsInt >= 6600 && labelAsInt <= 6700) ||
            (labelAsInt >= 7700 && labelAsInt <= 7800) ||
            (labelAsInt >= 8800 && labelAsInt <= 8900) ||
            (labelAsInt >= 9900 && labelAsInt <= 9999)) {
            return sender == owner();
        } else {
            return true;
        }
    }

    return bytes(label).length >= 3 && _isAlphanumeric(label);
}

    function register(
        bytes32 parentNode,
        string calldata label,
        address newOwner,
        uint64 duration,
        bytes[] calldata records
    ) public payable nonReentrant {
        require(names[parentNode].available, "parent name is not available for subdomains");
        uint256 fee = msg.sender == owner() ? 0 : duration * getRegistrationFee();
        if (msg.sender != owner()) {
            require(msg.value >= fee, "msg value does not meet the price");
        } 
        require(!names[parentNode].subdomainMinted[label], "this subdomain has been minted");
        require(isValidLabel(label, msg.sender), "Label must be a number between 1 and 9999");
        require(bytes(label).length > 0, "No label specified");
        
        duration = duration * 365 days;

        (, , uint64 parentExpiry) = wrapper.getData(uint256(parentNode));
        require(parentExpiry - uint64(block.timestamp) > duration, "duration exceeds limit");
        
        string memory readableName = names[parentNode].readableName;

        (bool success1, ) = payable(payout).call{value: msg.value}("");

        if (!success1) {
                revert TransferFailed();
            }
        

        _register(
            parentNode,
            label,
            newOwner,
            resolver,
            0, 
            uint64(block.timestamp) + duration,
            records
        );

        names[parentNode].subdomainMinted[label] = true;

        emit AddressRegistered(newOwner, label, parentNode, duration, readableName, fee, block.timestamp);
    }

    function renew(
        bytes32 parentNode,
        string calldata label,
        uint64 duration
    ) external payable onlySubdomainOwner(parentNode, label) returns (uint64 newExpiry) {
        _checkParent(parentNode, duration);

        uint256 fee = duration * getRegistrationFee();
        require(msg.value >= fee, "msg value does not meet the price");
        
        duration = duration * 365 days;

        (, , uint64 parentExpiry) = wrapper.getData(uint256(parentNode));
        require(parentExpiry - uint64(block.timestamp) > duration, "duration exceeds limit");

        (bool success1, ) = payable(payout).call{value: msg.value}("");

        if (!success1) {
                revert TransferFailed();
            }
        newExpiry = _renew(parentNode, keccak256(abi.encodePacked(label)), duration);
        emit AddressRenewed(label, parentNode, newExpiry, fee, msg.sender);
        return newExpiry;
    }

    function getLatestPrice() public view returns (int) {
    (
        , int price,,,
    ) = priceFeed.latestRoundData();
    return price;
    }

    function getRegistrationFee() public view returns (uint256) {
        int ethPriceInUsd = getLatestPrice(); // Price of 1 ETH in USD with 8 decimals
        uint256 feeInUsd = 50 * 1e8; // Fee in USD with 8 decimals to match ethPriceInUsd
        uint256 feeInEth = feeInUsd * 1e18 / uint256(ethPriceInUsd); // Calculate the registration fee in Wei considering $50
        return feeInEth;
    }

    function _renew(
        bytes32 parentNode,
        bytes32 labelhash,
        uint64 duration
    ) internal returns (uint64 newExpiry) {
        bytes32 node = _makeNode(parentNode, labelhash);
        (, , uint64 expiry) = wrapper.getData(uint256(node));
        if (expiry < block.timestamp) {
            revert NameNotRegistered();
        }

        newExpiry = expiry += duration;

        wrapper.setChildFuses(parentNode, labelhash, 0, newExpiry);

        emit NameRenewed(node, newExpiry);
    }

    function _checkParent(bytes32 parentNode, uint64 duration) internal view {
        (, uint64 parentExpiry) = super._checkParent(parentNode);

        require(duration + block.timestamp < parentExpiry, "duration exceeds limit");
    }

    function _makeNode(bytes32 node, bytes32 labelhash)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(node, labelhash));
    }

    function setResolver(address _resolver) public onlyOwner {
        resolver = _resolver;
    }

    function ownerOfSubdomain(bytes32 parentNode, string memory label) public view returns (address) {
        bytes32 node = _makeNode(parentNode, keccak256(abi.encodePacked(label)));
        address currentOwner = INameWrapper(wrapper).ownerOf(uint256(node));
        return currentOwner;
    }

    function setPayoutAddress(address _payout) external onlyOwner {
        payout = _payout;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier onlySubdomainOwner(bytes32 parentNode, string memory label) {
        bytes32 node = _makeNode(parentNode, keccak256(abi.encodePacked(label)));
        address currentOwner = INameWrapper(wrapper).ownerOf(uint256(node));
        require(msg.sender == currentOwner, "Caller is not the subdomain owner");
        _;
    }


}