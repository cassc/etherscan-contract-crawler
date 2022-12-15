//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@routerprotocol/router-crosstalk/contracts/RouterCrossTalk.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Greeter is RouterCrossTalk {
    string private greeting;
    address public owner;
    uint256 public nonce;
    mapping(uint256 => bytes32) public nonceToHash;

    constructor(address _handler) RouterCrossTalk(_handler) {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    /// @notice Function to set the linker address
    /// @dev Only owner can call this function
    /// @param _linker Address of the linker
    function setLinker(address _linker) external onlyOwner {
        setLink(_linker);
    }

    /// @notice Function to set the fee token address
    /// @dev Only owner can call this function
    /// @param _feeToken Address of the fee token
    function setFeesToken(address _feeToken) external onlyOwner {
        setFeeToken(_feeToken);
    }

    /// @notice Function to approve the generic handler to cut fees from this contract
    /// @dev Only owner can call this function
    /// @param _feeToken Address of the fee token
    /// @param _value Amount of approval
    function _approveFees(address _feeToken, uint256 _value)
        external
        onlyOwner
    {
        approveFees(_feeToken, _value);
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    /// @notice Function to be called to set greeting on the other chain
    /// @param  _chainID ChainId of the destination chain(router specs)
    /// @param  _greeting Greeting to be passed to the other chain
    /// @param  _crossChainGasLimit Gas limit to be used while executing the cross-chain tx.
    /// @param  _crossChainGasPrice Gas price to be used while executing the cross-chain tx.
    /// @notice If you pass a gas limit and price that are lower than what is expected on the
    /// destination chain, your transaction can get stuck on the bridge. You can always replay
    /// these transactions using the replay transaction function by passing a higher gas limit and price.
    function setGreetingCrossChain(
        uint8 _chainID,
        string memory _greeting,
        uint256 _crossChainGasLimit,
        uint256 _crossChainGasPrice
    ) external onlyOwner returns (bool) {
        nonce = nonce + 1;
        bytes memory data = abi.encode(_greeting);
        bytes4 _selector = bytes4(keccak256("setGreeting(string)"));
        (bool success, bytes32 hash) = routerSend(
            _chainID,
            _selector,
            data,
            _crossChainGasLimit,
            _crossChainGasPrice
        );
        nonceToHash[nonce] = hash;
        require(success == true, "unsuccessful");
        return success;
    }

    /// @notice Function to replay a transaction stuck on the bridge due to insufficient
    /// gas price or limit passed while setting greeting cross-chain
    /// @param _nonce Nonce of the transaction you want to execute
    /// @param _crossChainGasLimit Updated gas limit
    /// @param _crossChainGasPrice Updated gas price
    function replaySetGreetingCrossChain(
        uint256 _nonce,
        uint256 _crossChainGasLimit,
        uint256 _crossChainGasPrice
    ) external onlyOwner {
        routerReplay(
            nonceToHash[_nonce],
            _crossChainGasLimit,
            _crossChainGasPrice
        );
    }

    /// @notice Function which handles an incoming cross-chain request from another chain
    /// @dev You need to implement your logic here as to what you want to do when a request
    /// from another chain is received
    /// @param _selector Selector to the function which will be called on this contract
    /// @param _data Data to be called on that selector. You need to decode the data as per
    /// your requirements before calling the function
    /// In this contract, the selector is received for the setGreeting(string) function and
    /// the data contains abi.encode(greeting)
    function _routerSyncHandler(bytes4 _selector, bytes memory _data)
        internal
        override
        returns (bool, bytes memory)
    {
        string memory _greeting = abi.decode(_data, (string));
        (bool success, bytes memory data) = address(this).call(
            abi.encodeWithSelector(_selector, _greeting)
        );
        return (success, data);
    }

    /// @notice Function which sets the greeting when a cross-chain request is received
    /// @dev Only this contract itself can call this function
    /// @param _greeting Greeting received from the other chain
    function setGreeting(string memory _greeting) external isSelf {
        console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }

    /// @notice Function to recover fee tokens sent to this contract
    /// @notice Only the owner address can call this function
    function recoverFeeTokens() external onlyOwner {
        address feeToken = this.fetchFeeToken();
        uint256 amount = IERC20(feeToken).balanceOf(address(this));
        IERC20(feeToken).transfer(owner, amount);
    }
}