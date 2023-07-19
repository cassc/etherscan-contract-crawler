// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract BaseZKBridgeErc1155 is ERC1155URIStorage {

    address public bridge;

    bool public isONFT;

    modifier onlyBridge() {
        require(msg.sender == bridge, "caller is not the bridge");
        _;
    }

    constructor(string memory _uri, address _bridge, bool _isONFT) ERC1155(_uri) {
        bridge = _bridge;
        isONFT = _isONFT;
    }

    function zkBridgeMint(address _to, uint256 _id, uint256 _amount, string calldata _uri) external onlyBridge {
        _mint(_to, _id, _amount, "");
        if (!isONFT) {
            _setURI(_id, _uri);
        }
    }

    function zkBridgeBurn(address _from, uint256 _id, uint256 _amount) external onlyBridge {
        _burn(_from, _id, _amount);
    }
}