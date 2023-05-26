// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC1644 is IERC20 {
    // Controller Events
    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ControllerRedemption(
        address _controller,
        address indexed _tokenHolder,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Controller Operation
    function isControllable() external view returns (bool);
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;
}

interface IERC1643 {
    // Document Events
    event DocumentRemoved(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);

    // Document Management
    function getDocument(bytes32 _name) external view returns (string memory, bytes32, uint256);
    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external;
    function removeDocument(bytes32 _name) external;
    function getAllDocuments() external view returns (bytes32[] memory);
}

interface IERC1594 is IERC20 {
    // Issuance / Redemption Events
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);

    // Transfers
    function transferWithData(address _to, uint256 _value, bytes calldata _data) external;
    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata _data) external;

    // Token Issuance
    function isIssuable() external view returns (bool);
    function issue(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    // Token Redemption
    function redeem(uint256 _value, bytes calldata _data) external;
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    // Transfer Validity
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (bool, uint8, bytes32);
    function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data) external view returns (bool, uint8, bytes32);
}

interface ISTBT is IERC20, IERC20Metadata, IERC1594, IERC1643, IERC1644 {
    struct Permission {
        bool sendAllowed; // default: true
        bool receiveAllowed;
        // Address holder’s KYC will be validated till this time, after that the holder needs to re-KYC.
        uint64 expiryTime; // default:0 validated forever
    }

    function setIssuer(address _issuer) external;
    function setController(address _controller) external;
    function setModerator(address _moderator) external;
    function setMinDistributeInterval(uint64 interval) external;
    function setMaxDistributeRatio(uint64 ratio) external;
    function setPermission(address addr, Permission calldata permission) external;

    function distributeInterests(int256 _distributedInterest, uint interestFromTime, uint interestToTime) external;

    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool);
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool);

    function sharesOf(address _account) external view returns (uint256);
    function getSharesByAmount(uint256 _amount) external view returns (uint256 result);
    function getAmountByShares(uint256 _shares) external view returns (uint256 result);
}