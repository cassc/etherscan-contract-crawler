// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IZKBridgeErc1155.sol";

contract ZKBridgeErc1155 is IZKBridgeErc1155, ERC1155URIStorage {
    address public bridge;

    modifier onlyBridge() {
        require(msg.sender == bridge, "caller is not the bridge");
        _;
    }

    constructor() ERC1155("") {
        bridge = msg.sender;
    }

    function zkBridgeMint(
        address _to,
        uint256 _id,
        uint256 _amount,
        string calldata _uri
    ) external onlyBridge {
        _mint(_to, _id, _amount, "");
        _setURI(_id, _uri);
    }

    function zkBridgeBurn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external onlyBridge {
        _burn(_from, _id, _amount);
    }

    function uri(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC1155URIStorage, IZKBridgeErc1155)
        returns (string memory)
    {
        return super.uri(tokenId);
    }
}