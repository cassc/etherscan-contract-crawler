// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ReceiverFactory.sol";
import "./ITBDPasses.sol";
import "./IReceiver.sol";

contract CrossmintProxy is ReceiverFactory, Ownable, IERC1155Receiver {
    event CrossmintProxyToggled(bool indexed newState);

    uint256 private immutable PER_TX_LIMIT;

    uint256 public constant PASS_ID = 0;

    address public constant TBD_PASS =
        0x9FBb230B1EDD6C69bd0D8E610469031AB658F4b2;

    ITBDPasses public constant ITP = ITBDPasses(TBD_PASS);

    IReceiver private defaultReceiver;

    bool public paused;

    constructor() ReceiverFactory(address(this)) {
        PER_TX_LIMIT = ITP.MAX_MINT();
        defaultReceiver = IReceiver(deployReceiver());
    }

    function toggle() external {
        _onlyOwner();
        emit CrossmintProxyToggled(!paused);
        paused = !paused;
    }

    function mint(address to, uint256 qt) external payable {
        _whenNotPaused();

        require(qt > 0, "ZeroTokensRequested");

        if (qt < PER_TX_LIMIT) { 
            _mintToDefaultReceiver(to, qt);
        } else {
            _mintWithMultipleReceivers(to, qt);
        }
    }

    function _mintToDefaultReceiver(address to, uint256 qt) internal {
        if (defaultReceiver.accumulator() + qt > PER_TX_LIMIT) {
            delete defaultReceiver;
            defaultReceiver = IReceiver(deployReceiver());
        }

        defaultReceiver.mint{value: msg.value}(qt, true);
        defaultReceiver.retrieve(to, qt);
    }

    function _mintWithMultipleReceivers(address to, uint256 qt) internal {
        uint256 fullBatches = qt / PER_TX_LIMIT;
        uint256 tail = qt % PER_TX_LIMIT;
        
        for (uint256 b; b < fullBatches; b++) {
            IReceiver receiver = IReceiver(deployReceiver());
            uint256 price = ITP.price();
            receiver.mint{value: price * PER_TX_LIMIT}(PER_TX_LIMIT, false);
            receiver.retrieve(address(this), PER_TX_LIMIT);
        }

        if (tail > 0) {
            IReceiver receiver = IReceiver(deployReceiver());
            uint256 price = ITP.price();
            receiver.mint{value: price * tail}(tail, false);
            receiver.retrieve(address(this), tail);
        }

        ITP.safeTransferFrom(address(this), to, PASS_ID, qt, "");
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

    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        interfaceId;
        return true;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner(), "Unauthorized");
    }

    function _whenNotPaused() internal view {
        require(!paused, "ContractPaused");
    }
}