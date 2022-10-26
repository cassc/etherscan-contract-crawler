// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.17;

import "./Utils.sol";
import "./EpochTree.sol";

contract FirnBase is EpochTree {
    address _owner;
    address _logic;

    mapping(bytes32 => Utils.Point[2]) public acc; // main account mapping
    mapping(bytes32 => Utils.Point[2]) public pending; // storage for pending transfers

    struct Info { // try to save storage space by using smaller int types here
        uint64 epoch;
        uint64 index; // index in the list
        uint64 amount;
    }
    mapping(bytes32 => Info) public info; // public key --> deposit info
    mapping(uint64 => bytes32[]) public lists; // epoch --> list of depositing accounts

    function lengths(uint64 epoch) external view returns (uint256) { // see https://ethereum.stackexchange.com/a/20838.
        return lists[epoch].length;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner.");
        _;
    }

    modifier onlyLogic() {
        require(msg.sender == _logic, "Caller is not the logic contract.");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function administrate(address owner_, address logic_) external onlyOwner {
        _owner = owner_;
        _logic = logic_;
    }

    receive() external payable onlyLogic {
        // modifier isn't necessary for security, but will prevent people from wasting funds
    }

    function setAcc(bytes32 pub, Utils.Point[2] calldata value) external onlyLogic {
//        acc[pub] = value; // Copying of type struct Utils.Point calldata[2] calldata to storage not yet supported.
        acc[pub][0] = value[0];
        acc[pub][1] = value[1];
    }

    function setPending(bytes32 pub, Utils.Point[2] calldata value) external onlyLogic {
//        pending[pub] = value; // Copying of type struct Utils.Point calldata[2] calldata to storage not yet supported.
        pending[pub][0] = value[0];
        pending[pub][1] = value[1];
    }

    function setInfo(bytes32 pub, Info calldata value) external onlyLogic {
        info[pub] = value;
    }

    function setList(uint64 epoch, uint256 index, bytes32 value) external onlyLogic {
        lists[epoch][index] = value;
    }

    function popList(uint64 epoch) external onlyLogic {
        lists[epoch].pop();
    }

    function pushList(uint64 epoch, bytes32 value) external onlyLogic {
        lists[epoch].push(value);
    }

    function insertEpoch(uint64 epoch) external onlyLogic {
        insert(epoch);
    }

    function removeEpoch(uint64 epoch) external onlyLogic {
        remove(epoch);
    }

    function pay(address destination, uint256 value, bytes calldata data) external payable onlyLogic {
        (bool success,) = payable(destination).call{value: value}(data);
        require(success, "External call failed.");
    }
}