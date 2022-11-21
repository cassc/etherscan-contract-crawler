// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ImportToken is Ownable {
    address public signer;
    IERC20 public immutable importToken;
    IERC20 public immutable importTokenSub;
    mapping(uint => bool) public importRequestId;
    mapping(uint => bool) public exportRequestId;
    mapping(uint => mapping(IERC20 => uint)) public importInfos; // importRequestId => token => amount
    mapping(uint => mapping(IERC20 => uint)) public exportInfos; // importRequestId => token => amount

    constructor(address _signer, IERC20 _importToken, IERC20 _importTokenSub) {
        signer = _signer;
        importToken = _importToken;
        importTokenSub = _importTokenSub;
    }
    function getMessageHash(uint _id, address _user, IERC20 _token, uint amount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_id, _user, _token, amount));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function permit(uint _id, address _user, IERC20 _token, uint amount, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        return ecrecover(getEthSignedMessageHash(getMessageHash(_id, _user, _token, amount)), v, r, s) == signer;
    }
    function export(uint _id, IERC20 _token, uint amount, uint8 v, bytes32 r, bytes32 s) public {
        require(permit(_id, _msgSender(), _token, amount, v, r, s), "Export: Invalid signature");
        require(!exportRequestId[_id], "Export: Invalid id");
        _token.transfer(_msgSender(), amount);
        exportRequestId[_id] = true;
        exportInfos[_id][_token] = amount;
    }
    function getImportInfos(uint _importRequestId, IERC20 _importToken) external view returns(uint) {
        return importInfos[_importRequestId][_importToken];
    }
    function Import(uint _importRequestId, uint _amount) external {
        require(!importRequestId[_importRequestId], "ImportToken::Import:Imported");
        importInfos[_importRequestId][importToken] = _amount;
        importToken.transferFrom(_msgSender(), address(this), _amount);
        importRequestId[_importRequestId] = true;
    }

    function ImportTokenSub(uint _importRequestId, uint _amount) external {
        require(!importRequestId[_importRequestId], "ImportToken::ImportTokenSub:Imported");
        importInfos[_importRequestId][importTokenSub] = _amount;
        importTokenSub.transferFrom(_msgSender(), address(this), _amount);
        importRequestId[_importRequestId] = true;
    }

    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
}