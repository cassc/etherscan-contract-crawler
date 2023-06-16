// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./ITBDPasses.sol";

contract Receiver is IERC1155Receiver {
    uint256 public constant PASS_ID = 0;

    address public constant TBD_PASS =
        0x9FBb230B1EDD6C69bd0D8E610469031AB658F4b2;

    ITBDPasses public constant ITP = ITBDPasses(TBD_PASS);

    uint256 public accumulator;

    address private _owner;

    constructor() {}

    function init(address owner_) external {
        if (_owner == address(0)) {
            _owner = owner_;
        }
    }

    function mint(uint256 qt, bool count) external payable {
        _onlyOwner();
        ITP.mint{value: msg.value}(qt);
        if (count) {
            accumulator += qt;
        }
    }

    function retrieve(address to, uint256 qt) external {
        _onlyOwner();
        ITP.safeTransferFrom(address(this), to, PASS_ID, qt, "");
    }

    function _onlyOwner() internal view {
        require(msg.sender == _owner, "Unathorized");
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        interfaceId;
        return true;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        operator;
        from;
        id;
        value;
        data;
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        operator;
        from;
        ids;
        values;
        data;
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}