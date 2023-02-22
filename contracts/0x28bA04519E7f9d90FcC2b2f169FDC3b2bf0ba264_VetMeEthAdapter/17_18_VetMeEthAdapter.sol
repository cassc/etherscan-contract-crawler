//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@routerprotocol/router-crosstalk/contracts/RouterCrossTalkUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract VetMeEthAdapter is
    Initializable,
    UUPSUpgradeable,
    RouterCrossTalkUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public constant VETME =
        IERC20Upgradeable(0xe7eF051C6EA1026A70967E8F04da143C67Fa4E1f);
    address public owner;

    uint64 public nonce;
    mapping(uint64 => bytes32) public nonceToHash;
    mapping(uint8 => uint256) public feesForCrossChainTx;

    event TxCreated(uint64 indexed nonce, uint256 amount);

    function initialize(address _handler, address _feeToken)
        external
        initializer
    {
        __RouterCrossTalkUpgradeable_init(_handler);
        setFeeToken(_feeToken);
        setLink(msg.sender);
        approveFees(_feeToken, 1000000000000000000000000);

        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

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

    function setFeesForCrossChainTx(uint8 destChainId, uint256 amount)
        external
        onlyOwner
    {
        feesForCrossChainTx[destChainId] = amount;
    }

    /// @notice Function to be called to send VetMe tokens to the other chain
    /// @param  _chainID ChainId of the destination chain(router specs)
    /// @param  _amount Amount of tokens to be transferred to the destination chain
    /// @param  _crossChainGasPrice Gas price to be used while executing the cross-chain tx.
    /// @notice If you pass a gas limit and price that are lower than what is expected on the
    /// destination chain, your transaction can get stuck on the bridge. You can always replay
    /// these transactions using the replay transaction function by passing a higher gas limit and price.
    function sendVetMeCrossChain(
        uint8 _chainID,
        address _recipient,
        uint256 _amount,
        uint256 _crossChainGasPrice
    ) external payable returns (bool) {
        require(_amount > 0, "amount = 0");
        require(msg.value >= feesForCrossChainTx[_chainID], "fees too low");

        nonce = nonce + 1;
        bytes memory _data = abi.encode(_recipient, _amount);

        VETME.transferFrom(msg.sender, address(this), _amount);

        (bool success, bytes32 hash) = routerSend(
            _chainID,
            0x00000000,
            _data,
            350000,
            _crossChainGasPrice
        );

        nonceToHash[nonce] = hash;
        require(success == true, "unsuccessful");

        emit TxCreated(nonce, _amount);
        return success;
    }

    /// @notice Function to replay a transaction stuck on the bridge due to insufficient
    /// gas price or limit passed while setting greeting cross-chain
    /// @param _nonce Nonce of the transaction you want to execute
    /// @param _crossChainGasLimit Updated gas limit
    /// @param _crossChainGasPrice Updated gas price
    function replaySendVetMeCrossChain(
        uint64 _nonce,
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
    // /// @param _selector Selector to the function which will be called on this contract
    /// @param _data Data to be called on that selector. You need to decode the data as per
    /// your requirements before calling the function
    /// In this contract, the selector is received for the receiveTokens(uint256) function and
    /// the data contains abi.encode(amount)
    function _routerSyncHandler(
        bytes4, /**_selector*/
        bytes memory _data
    ) internal override returns (bool, bytes memory) {
        (address _recipient, uint256 _amount) = abi.decode(
            _data,
            (address, uint256)
        );

        VETME.transfer(_recipient, _amount);

        return (true, "");
    }

    /// @notice Function to recover fee tokens sent to this contract
    /// @notice Only the owner address can call this function
    function recoverFeeTokens() external onlyOwner {
        address feeToken = this.fetchFeeToken();
        uint256 amount = IERC20Upgradeable(feeToken).balanceOf(address(this));
        IERC20Upgradeable(feeToken).transfer(msg.sender, amount);
    }

    function withdrawNative(address payable recipient) external onlyOwner {
        recipient.transfer(address(this).balance);
    }
}