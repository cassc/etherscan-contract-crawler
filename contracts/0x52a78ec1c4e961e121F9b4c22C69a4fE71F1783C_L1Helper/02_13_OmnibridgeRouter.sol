pragma solidity 0.7.5;

import "omnibridge/contracts/interfaces/IOmnibridge.sol";
import "omnibridge/contracts/interfaces/IWETH.sol";
import "omnibridge/contracts/libraries/AddressHelper.sol";
import "omnibridge/contracts/libraries/Bytes.sol";
import "omnibridge/contracts/upgradeable_contracts/modules/OwnableModule.sol";
import "omnibridge/contracts/upgradeable_contracts/Claimable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title OmnibridgeRouter
 * @dev Omnibridge extension for processing native and wrapped native assets.
 * Intended to work with WETH/WBNB/WXDAI tokens, see:
 *   https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
 *   https://bscscan.com/address/0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
 *   https://blockscout.com/poa/xdai/address/0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d
 */
contract OmnibridgeRouter is OwnableModule, Claimable {

    using SafeERC20 for IERC20;

    IOmnibridge public immutable bridge;
    IWETH public immutable WETH;

    /**
     * @dev Initializes this contract.
     * @param _bridge address of the HomeOmnibridge/ForeignOmnibridge contract.
     * @param _weth address of the WETH token used for wrapping/unwrapping native coins (e.g. WETH/WBNB/WXDAI).
     * @param _owner address of the contract owner.
     */
    constructor(
        IOmnibridge _bridge,
        IWETH _weth,
        address _owner
    ) OwnableModule(_owner) {
        bridge = _bridge;
        WETH = _weth;
        _weth.approve(address(_bridge), uint256(-1));
    }

    /**
     * @dev Wraps native assets and relays wrapped ERC20 tokens to the other chain.
     * Call msg.sender will receive assets on the other side of the bridge.
     */
    function wrapAndRelayTokens(address token, uint256 amount) external payable {
        wrapAndRelayTokens(msg.sender, token, amount);
    }

    /**
     * @dev Wraps native assets and relays wrapped ERC20 tokens to the other chain.
     * @param _receiver bridged assets receiver on the other side of the bridge.
     */
    function wrapAndRelayTokens(address _receiver, address token, uint256 amount) public payable {
        if(token == address(0)) {
            WETH.deposit{ value: msg.value }();
            bridge.relayTokens(address(WETH), _receiver, msg.value);
        }
        else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
            bridge.relayTokens(token, _receiver, amount);
        }    
    }

    /**
    * @dev Wraps native assets and relays wrapped ERC20 tokens to the other chain.
    * It also calls receiver on other side with the _data provided.
    * @param _receiver bridged assets receiver on the other side of the bridge.
    * @param _data data for the call of receiver on other side.
    */
    function wrapAndRelayTokens(address _receiver, address token, uint256 amount, bytes memory _data) public payable {
        if(token == address(0)) {
            WETH.deposit{ value: msg.value }();
            bridge.relayTokensAndCall(address(WETH), _receiver, msg.value, _data);
        }
        else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
            bridge.relayTokensAndCall(token, _receiver, amount, _data);
        }
    }

    /**
     * @dev Bridged callback function used for unwrapping received tokens.
     * Can only be called by the associated Omnibridge contract.
     * @param _token bridged token contract address, should be WETH.
     * @param _value amount of bridged/received tokens.
     * @param _data extra data passed alongside with relayTokensAndCall on the other side of the bridge.
     * Should contain coins receiver address.
     */
    function onTokenBridged(
        address _token,
        uint256 _value,
        bytes memory _data
    ) external virtual {
        require(msg.sender == address(bridge));
        require(_data.length == 20);

        if(_token == address(WETH)) {
            WETH.withdraw(_value);
            AddressHelper.safeSendValue(payable(Bytes.bytesToAddress(_data)), _value);
        }
        else {
            IERC20(_token).transfer(Bytes.bytesToAddress(_data), _value);
        }
    }

    function allowTokens(address _token) external onlyOwner {
        IERC20(_token).approve(address(bridge), uint256(-1));
    }

    /**
     * @dev Claims stuck coins/tokens.
     * Only contract owner can call this method.
     * @param _token address of claimed token contract, address(0) for native coins.
     * @param _to address of tokens receiver
     */
    
    function claimTokens(address _token, address _to) external onlyOwner {
        claimValues(_token, _to);
    }

    /**
     * @dev Ether receive function.
     * Should be only called from the WETH contract when withdrawing native coins. Will revert otherwise.
     */
    receive() external payable {
        require(msg.sender == address(WETH));
    }
}