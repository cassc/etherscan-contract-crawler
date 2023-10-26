// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// XPhoton staking bridge contract to be used on secondary chains
// Burns xphoton tokens on secondary chain, then uses l0 to stake on primary chain
// This contract is deployed on secondary chains only

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

contract XPhotonStakingProxy is NonblockingLzApp, Ownable2Step {
    uint8 public constant ACTION_STAKE = 1;
    uint16 public dstChainId;
    address public dstChainApp;
    uint256 public stakeGas;
    IERC20 public immutable xPhoton;

    constructor(
        address _token,
        address _lzEndpoint,
        address _dstChainApp,
        uint16 _dstChainId
    ) NonblockingLzApp(_lzEndpoint) {
        require(_token != address(0), "XPhotonStakingProxy: !_token");
        require(
            _dstChainApp != address(0),
            "XPhotonStakingProxy: !_dstChainApp"
        );
        dstChainId = _dstChainId;
        dstChainApp = _dstChainApp;
        // set the dstChainApp as trusted remote contract
        // SetTrustedRemoteAddress(_dstChainId, _dstChainApp);
        // set xPhoton token address
        xPhoton = IERC20(_token);
        stakeGas = 600000;
    }

    // PUBLIC FUNCTIONS:

    function estimateFees(
        uint8 _action,
        uint256 _amount
    ) public view returns (uint msgFee) {
        bytes memory payload = abi.encode(msg.sender, _action, _amount);
        bytes memory adapterParams = abi.encodePacked(
            uint16(2),
            stakeGas,
            uint256(0),
            address(0x0)
        );
        (msgFee, ) = lzEndpoint.estimateFees(
            dstChainId,
            dstChainApp,
            payload,
            false,
            adapterParams
        );
    }

    function stake(uint256 _amount) external payable {
        xPhoton.transferFrom(msg.sender, address(this), _amount);
        bytes memory payload = abi.encode(msg.sender, ACTION_STAKE, _amount);
        // setup adapter params for custom gas
        bytes memory adapterParams = abi.encodePacked(
            uint16(2),
            stakeGas,
            uint256(0),
            address(0x0)
        );
        _lzSend(
            dstChainId,
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams,
            msg.value
        );
    }

    // ADMIN FUNCTIONS:

    function setDstChainApp(
        address _dstChainApp,
        uint16 _dstChainId
    ) external onlyOwner {
        dstChainApp = _dstChainApp;
        dstChainId = _dstChainId;
    }

    function setStakeGas(uint256 _stakeGas) external onlyOwner {
        stakeGas = _stakeGas;
    }

    // conversion from ownable to ownable2step
    function transferOwnership(
        address newOwner
    ) public override(Ownable, Ownable2Step) onlyOwner {
        Ownable2Step.transferOwnership(newOwner);
    }

    function _transferOwnership(
        address newOwner
    ) internal override(Ownable, Ownable2Step) {
        Ownable2Step._transferOwnership(newOwner);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual override {}
}