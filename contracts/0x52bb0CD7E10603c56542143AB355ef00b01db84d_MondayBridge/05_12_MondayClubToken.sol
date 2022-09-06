// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MondayClubToken is ERC20,Ownable {
    
    address public trustedBridge;

    event NewTrustedBridgeSet(address newTrustedBridge);

    constructor(address _trustedBridge) ERC20("MondayClub Token", "MONDAY") {
        trustedBridge = _trustedBridge;
    }
    
    modifier onlyTrustedBridge() {
        require(msg.sender == trustedBridge, "caller is not trusted bridge");
        _;
    }
    
    function setBridge(address _newTrustedBridge) onlyOwner external {
        trustedBridge = _newTrustedBridge;
        emit NewTrustedBridgeSet(_newTrustedBridge);
    }

    function bridgeMint(address _account,uint _amount) onlyTrustedBridge external {
        _mint(_account,_amount);
    }

    function bridgeBurn(address _account,uint _amount) onlyTrustedBridge  external {
        _burn(_account,_amount);
    }

}