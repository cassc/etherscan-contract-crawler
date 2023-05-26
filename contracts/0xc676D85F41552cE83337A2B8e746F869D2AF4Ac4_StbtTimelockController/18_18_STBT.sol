// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

import "./interfaces/ISTBT.sol";

contract StbtTimelockController is TimelockController {

    mapping (bytes4 => uint256) public delayMap;

    constructor(
        address[] memory proposers,
        address[] memory executors,
        address admin,
        bytes4[] memory selectors,
        uint256[] memory delays
    ) TimelockController(0/*minDelay*/, proposers, executors, admin) {
        require(selectors.length == delays.length, 'TimelockController: SELECTORS_DELAYS_LEN_NOT_MATCH');
        for (uint256 i = 0; i < selectors.length; i++) {
            delayMap[selectors[i]] = delays[i];
        }
    }

    function updateDelay(uint256 /*newDelay*/) external override pure {
        revert('TimelockController: UNSUPPORTED');
    }

    function scheduleBatch(
        address[] calldata /*targets*/,
        uint256[] calldata /*values*/,
        bytes[] calldata /*payloads*/,
        bytes32 /*predecessor*/,
        bytes32 /*salt*/,
        uint256 /*delay*/
    ) public override pure {
        revert('TimelockController: UNSUPPORTED');
    }

    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 /*delay*/
    ) public override onlyRole(PROPOSER_ROLE) {

        bytes4 sel = bytes4(data[0:4]);
        uint256 delay = delayMap[sel];
        require(delay > 0, 'TimelockController: UNKNOWN_SELECTOR');

        super.schedule(target, value, data, predecessor, salt, delay);
    }

    // function schedule2(
    //     address target,
    //     bytes calldata data,
    //     bytes32 predecessor,
    //     bytes32 salt
    // ) public {
    //     schedule(target, 0, data, predecessor, salt, 0);
    // }

    // function cancelOperation(
    //     address target,
    //     uint256 value,
    //     bytes calldata data,
    //     bytes32 predecessor,
    //     bytes32 salt
    // ) public onlyRole(CANCELLER_ROLE) {

    //     bytes32 id = hashOperation(target, value, data, predecessor, salt);
    //     cancel(id);
    // }

    function _execute(
        address target,
        uint256 value,
        bytes calldata data
    ) internal override {
        (bool success, ) = target.call{value: value}(data);
        if (success == false) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
}

contract UpgradeableSTBT is Proxy {
    // override
    address public owner;
    address public issuer;
    address public controller;
    address public moderator;
    // new state below
    address public implementation;

    constructor(
        address _owner,
        address _issuer,
        address _controller,
        address _moderator,
        address _impl
    ){
        owner = _owner;
        issuer = _issuer;
        controller = _controller;
        moderator = _moderator;
        implementation = _impl;
    }

    function resetImplementation(address _impl) external {
        require(msg.sender == owner, "STBT: NOT_OWNER");
        implementation = _impl;
    }

    function _implementation() internal view override returns (address) {
        return implementation;
    }
}

contract STBT is Ownable, ISTBT {
    // all the following three roles are contracts of governance/TimelockController.sol
    address public issuer;
    address public controller;
    address public moderator;

    uint[300] public placeholders;

    uint public totalSupply;
    uint public totalShares;
    mapping(address => uint256) private shares;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => Permission) public permissions; // Address-specific transfer permissions

    uint64 public lastDistributeTime;
    uint64 public minDistributeInterval;
    uint64 public maxDistributeRatio;

    struct Document {
        bytes32 docHash;
        uint256 lastModified;
        string uri;
    }
    bytes32[] docNames;
    // doc name => doc detail
    mapping(bytes32 => Document) public documents;
    // doc name => doc name index in docNames
    mapping(bytes32 => uint256) public docIndexes;

    // EIP-1066 status code
    uint8 private constant Success = 0x01;
    uint8 private constant UpperLimit = 0x06;
    uint8 private constant PermissionRequested = 0x13;
    uint8 private constant RevokedOrBanned = 0x16;

    event InterestsDistributed(int interest, uint newTotalSupply, uint interestFromTime, uint interestToTime);
    event TransferShares(address indexed from, address indexed to, uint256 sharesValue);

    modifier onlyIssuer() {
        require(msg.sender == issuer, 'STBT: NOT_ISSUER');
        _;
    }

    modifier onlyController() {
        require(msg.sender == controller, 'STBT: NOT_CONTROLLER');
        _;
    }

    modifier onlyModerator() {
        require(msg.sender == moderator, 'STBT: NOT_MODERATOR');
        _;
    }

    function setIssuer(address _issuer) public onlyOwner {
        issuer = _issuer;
    }

    function setController(address _controller) public onlyOwner {
        controller = _controller;
    }

    function setModerator(address _moderator) public onlyOwner {
        moderator = _moderator;
    }

    function setMinDistributeInterval(uint64 interval) public onlyOwner {
        minDistributeInterval = interval;
    }

    function setMaxDistributeRatio(uint64 ratio) public onlyOwner {
        maxDistributeRatio = ratio;
    }

    function setPermission(address addr, Permission calldata permission) public onlyModerator {
        permissions[addr] = permission;
    }

    function name() public pure returns (string memory) {
        return "M Test Bond Token";
    }

    function symbol() public pure returns (string memory) {
        return "MTBT";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return getAmountByShares(shares[_account]);
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        _transferWithCheck(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        uint256 currentAllowance = allowances[_sender][msg.sender];
        require(currentAllowance >= _amount, "STBT: TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE");

        _transferWithCheck(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, currentAllowance - _amount);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender] + _addedValue);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][_spender];
        require(currentAllowance >= _subtractedValue, "STBT: DECREASED_ALLOWANCE_BELOW_ZERO");
        _approve(msg.sender, _spender, currentAllowance - _subtractedValue);
        return true;
    }

    function sharesOf(address _account) public view returns (uint256) {
        return shares[_account];
    }

    function getSharesByAmountRoundUp(uint256 _amount) public view returns (uint256 result) {
        uint _totalSupply = totalSupply;
        return _totalSupply == 0 ? 0 : (_amount * totalShares + _totalSupply - 1) / _totalSupply;
    }

    function getSharesByAmount(uint256 _amount) public view returns (uint256 result) {
        // unchecked {
        //     result = _amount * totalShares / totalSupply; // divide-by-zero will return zero
        // }
        return totalSupply == 0 ? 0 : _amount * totalShares / totalSupply;
    }

    function getAmountByShares(uint256 _shares) public view returns (uint256 result) {
        // unchecked {
        //     result = _shares * totalSupply / totalShares; // divide-by-zero will return zero
        // }
        return totalShares == 0 ? 0 : _shares * totalSupply / totalShares;
    }

    function _transferWithCheck(address _sender, address _recipient, uint256 _amount) internal {
        _checkSendPermission(_sender);
        _checkReceivePermission(_recipient);
        _transfer(_sender, _recipient, _amount);
    }

    function _checkSendPermission(address _sender) private view {
        Permission memory permTx = permissions[_sender];
        require(permTx.sendAllowed, 'STBT: NO_SEND_PERMISSION');
        require(permTx.expiryTime == 0 || permTx.expiryTime > block.timestamp, 'STBT: SEND_PERMISSION_EXPIRED');
    }
    function _checkReceivePermission(address _recipient) private view {
        Permission memory permRx = permissions[_recipient];
        require(permRx.receiveAllowed, 'STBT: NO_RECEIVE_PERMISSION');
        require(permRx.expiryTime == 0 || permRx.expiryTime > block.timestamp, 'STBT: RECEIVE_PERMISSION_EXPIRED');
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        uint256 _sharesToTransfer = getSharesByAmount(_amount);
        _transferShares(_sender, _recipient, _sharesToTransfer);
        emit Transfer(_sender, _recipient, getAmountByShares(_sharesToTransfer));
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal {
        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _transferShares(address _sender, address _recipient, uint256 _shares) internal {
        require(_sender != address(0), "STBT: TRANSFER_FROM_THE_ZERO_ADDRESS");
        require(_recipient != address(0), "STBT: TRANSFER_TO_THE_ZERO_ADDRESS");

        uint256 currentSenderShares = shares[_sender];
        require(_shares <= currentSenderShares, "STBT: TRANSFER_AMOUNT_EXCEEDS_BALANCE");

        shares[_sender] = currentSenderShares - _shares;
        shares[_recipient] = shares[_recipient] + _shares;
        emit TransferShares(_sender, _recipient, _shares);
    }

    function _mintSharesWithCheck(address _recipient, uint256 _shares) internal returns (uint256 newTotalShares) {
        require(_recipient != address(0), "STBT: MINT_TO_THE_ZERO_ADDRESS");
        _checkReceivePermission(_recipient);

        totalShares += _shares;

        shares[_recipient] += _shares;
        emit TransferShares(address(0), _recipient, _shares);
        return totalShares;
    }

    function _burnSharesWithCheck(address _account, uint256 _shares) internal returns (uint256 newTotalShares) {
        _checkSendPermission(_account);
        return _burnShares(_account, _shares);
    }

    function _burnShares(address _account, uint256 _shares) internal returns (uint256 newTotalShares) {
        require(_account != address(0), "STBT: BURN_FROM_THE_ZERO_ADDRESS");

        uint256 accountShares = shares[_account];
        require(_shares <= accountShares, "STBT: BURN_AMOUNT_EXCEEDS_BALANCE");

        newTotalShares = totalShares - _shares;
        totalShares = newTotalShares;

        shares[_account] = accountShares - _shares;

        emit TransferShares(_account, address(0), _shares);
    }

    function distributeInterests(int256 _distributedInterest, uint interestFromTime, uint interestToTime) external onlyIssuer {
        uint oldTotalSupply = totalSupply;
        uint newTotalSupply;
        if(_distributedInterest > 0) {
            require(oldTotalSupply * maxDistributeRatio >= uint(_distributedInterest) * (10 ** 18), 'STBT: MAX_DISTRIBUTE_RATIO_EXCEEDED');
            newTotalSupply = oldTotalSupply + uint(_distributedInterest);
        } else {
            require(oldTotalSupply * maxDistributeRatio >= uint(-_distributedInterest) * (10 ** 18), 'STBT: MAX_DISTRIBUTE_RATIO_EXCEEDED');
            newTotalSupply = oldTotalSupply - uint(-_distributedInterest);
        }
        totalSupply = newTotalSupply;
        require(lastDistributeTime + minDistributeInterval < block.timestamp, 'STBT: MIN_DISTRIBUTE_INTERVAL_VIOLATED');
        emit InterestsDistributed(_distributedInterest, newTotalSupply, interestFromTime, interestToTime);
        lastDistributeTime = uint64(block.timestamp);
    }

    function isControllable() external pure returns (bool) {
        return true;
    }

    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external onlyController {
        _transfer(_from, _to, _value);
        emit ControllerTransfer(msg.sender, _from, _to, _value, _data, _operatorData);
    }

    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external onlyController {
        uint sharesDelta = getSharesByAmountRoundUp(_value);
        _burnShares(_tokenHolder, sharesDelta);
        totalSupply -= _value;
        _value = getAmountByShares(sharesDelta);
        emit ControllerRedemption(msg.sender, _tokenHolder, _value, _data, _operatorData);
        emit Transfer(_tokenHolder, address(0), _value);
    }

    // Transfers
    function transferWithData(address _to, uint256 _value, bytes calldata /*_data*/) external {
        transfer(_to, _value);
    }

    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata /*_data*/) external {
        transferFrom(_from, _to, _value);
    }

    // Token Issuance
    function isIssuable() external pure returns (bool) {
        return true;
    }

    function issue(address _tokenHolder, uint256 _value, bytes calldata _data) external onlyIssuer {
        if (_value == 0) {
            return;
        }
        uint sharesDelta = getSharesByAmount(_value);
        if (sharesDelta == 0) {
            sharesDelta = _value;
            totalSupply = _value;
            lastDistributeTime = uint64(block.timestamp);
        } else {
            totalSupply += _value;
        }
        _mintSharesWithCheck(_tokenHolder, sharesDelta);
        _value = getAmountByShares(sharesDelta);
        emit Issued(msg.sender, _tokenHolder, _value, _data);
        emit Transfer(address(0), _tokenHolder, _value);
    }

    // Token Redemption
    function redeem(uint256 _value, bytes calldata _data) external onlyIssuer {
        if (_value == 0) {
            return;
        }
        uint sharesDelta = getSharesByAmountRoundUp(_value);
        _burnSharesWithCheck(msg.sender, sharesDelta);
        totalSupply -= _value;
        _value = getAmountByShares(sharesDelta);
        emit Redeemed(msg.sender, msg.sender, _value, _data);
        emit Transfer(msg.sender, address(0), _value);
    }

    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external onlyIssuer {
        uint256 currentAllowance = allowances[_tokenHolder][msg.sender];
        require(currentAllowance >= _value, "STBT: REDEEM_AMOUNT_EXCEEDS_ALLOWANCE");

        uint sharesDelta = getSharesByAmountRoundUp(_value);
        _burnSharesWithCheck(_tokenHolder, sharesDelta);
        totalSupply -= _value;
        _value = getAmountByShares(sharesDelta);
        emit Redeemed(msg.sender, _tokenHolder, _value, _data);
        emit Transfer(_tokenHolder, address(0), _value);
        _approve(_tokenHolder, msg.sender, currentAllowance - _value);
    }


    function _checkTransfer(address _sender, address _recipient, uint256 _amount, bytes calldata /*_data*/) internal view returns (bool, uint8, bytes32) {
        Permission memory permTx = permissions[_sender];
        Permission memory permRx = permissions[_recipient];
        bool txOK = permTx.sendAllowed && (permTx.expiryTime == 0 || permTx.expiryTime > block.timestamp) &&
        _sender != address(0);
        if (!txOK) {
            return (false, PermissionRequested, bytes32(bytes("CANNOT_SEND")));
        }
        bool rxOK = permRx.receiveAllowed && (permRx.expiryTime == 0 || permRx.expiryTime > block.timestamp) &&
        _recipient != address(0);
        if (!rxOK) {
            return (false, PermissionRequested, bytes32(bytes("CANNOT_RECEIVE")));
        }
        uint256 _shares = getSharesByAmount(_amount);
        uint256 currentSenderShares = shares[_sender];
        if (_shares > currentSenderShares) {
            return (false, UpperLimit, bytes32(bytes("SHARES_NOT_ENOUGH")));
        }
        return (true, Success, bytes32(0));
    }

    function canTransfer(address _recipient, uint256 _amount, bytes calldata _data) external view returns (bool, uint8, bytes32) {
        return _checkTransfer(msg.sender, _recipient, _amount, _data);
    }

    function canTransferFrom(address _sender, address _recipient, uint256 _amount, bytes calldata _data) external view returns (bool, uint8, bytes32) {
        uint256 currentAllowance = allowances[_sender][msg.sender];
        if (_amount > currentAllowance) {
            return (false, UpperLimit, bytes32(bytes("ALLOWANCE_NOT_ENOUGH")));
        }
        return _checkTransfer(_sender, _recipient, _amount, _data);
    }

    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external onlyOwner {
        require(_name != bytes32(0), "STBT: INVALID_DOC_NAME");
        require(bytes(_uri).length > 0, "STBT: INVALID_URL");
        if (documents[_name].lastModified == uint256(0)) {
            docNames.push(_name);
            docIndexes[_name] = docNames.length;
        }
        documents[_name] = Document(_documentHash, block.timestamp, _uri);
        emit DocumentUpdated(_name, _uri, _documentHash);
    }

    function removeDocument(bytes32 _name) external onlyOwner {
        require(documents[_name].lastModified != uint256(0), "STBT: DOC_NOT_EXIST");
        uint256 index = docIndexes[_name] - 1;
        if (index != docNames.length - 1) {
            docNames[index] = docNames[docNames.length - 1];
            docIndexes[docNames[index]] = index + 1;
        }
        docNames.pop();
        delete documents[_name];
        emit DocumentRemoved(_name, documents[_name].uri, documents[_name].docHash);
    }

    function getDocument(bytes32 _name) external view returns (string memory, bytes32, uint256) {
        return (
        documents[_name].uri,
        documents[_name].docHash,
        documents[_name].lastModified
        );
    }

    function getAllDocuments() external view returns (bytes32[] memory) {
        return docNames;
    }
}