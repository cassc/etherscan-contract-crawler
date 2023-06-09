// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../Interfaces/IEqbMsgSendEndpoint.sol";
import "../Dependencies/Errors.sol";

abstract contract EqbMsgSenderUpg is OwnableUpgradeable {
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    IEqbMsgSendEndpoint public eqbMsgSendEndpoint;

    uint256 public approxDstExecutionGas;

    // destinationContracts mapping contains one address for each chainId only
    EnumerableMap.UintToAddressMap internal destinationContracts;

    uint256[100] private __gap;

    event MsgSent(uint256 indexed _chainId, bytes _message);

    modifier refundUnusedEth() {
        _;
        if (address(this).balance > 0) {
            AddressUpgradeable.sendValue(
                payable(msg.sender),
                address(this).balance
            );
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __EqbMsgSender_init(
        address _eqbMsgSendEndpoint,
        uint256 _approxDstExecutionGas
    ) internal onlyInitializing {
        __EqbMsgSender_init_unchained(
            _eqbMsgSendEndpoint,
            _approxDstExecutionGas
        );
    }

    function __EqbMsgSender_init_unchained(
        address _eqbMsgSendEndpoint,
        uint256 _approxDstExecutionGas
    ) internal onlyInitializing {
        __Ownable_init_unchained();

        eqbMsgSendEndpoint = IEqbMsgSendEndpoint(_eqbMsgSendEndpoint);
        approxDstExecutionGas = _approxDstExecutionGas;
    }

    function _sendMessage(uint256 _chainId, bytes memory _message) internal {
        assert(destinationContracts.contains(_chainId));
        address toAddr = destinationContracts.get(_chainId);
        uint256 estimatedGasAmount = approxDstExecutionGas;
        uint256 fee = eqbMsgSendEndpoint.calcFee(
            _chainId,
            toAddr,
            _message,
            estimatedGasAmount
        );
        // LM contracts won't hold ETH on its own so this is fine
        if (address(this).balance < fee) {
            revert Errors.InsufficientFeeToSendMsg(address(this).balance, fee);
        }
        eqbMsgSendEndpoint.sendMessage{value: fee}(
            _chainId,
            toAddr,
            _message,
            estimatedGasAmount
        );

        emit MsgSent(_chainId, _message);
    }

    function addDestinationContract(
        uint256 _chainId,
        address _address
    ) external payable onlyOwner {
        destinationContracts.set(_chainId, _address);
    }

    function setApproxDstExecutionGas(uint256 _gas) external onlyOwner {
        approxDstExecutionGas = _gas;
    }

    function getAllDestinationContracts()
        public
        view
        returns (uint256[] memory chainIds, address[] memory addrs)
    {
        uint256 length = destinationContracts.length();
        chainIds = new uint256[](length);
        addrs = new address[](length);

        for (uint256 i = 0; i < length; ++i) {
            (chainIds[i], addrs[i]) = destinationContracts.at(i);
        }
    }

    function _getSendMessageFee(
        uint256 chainId,
        bytes memory message
    ) internal view returns (uint256) {
        return
            eqbMsgSendEndpoint.calcFee(
                chainId,
                destinationContracts.get(chainId),
                message,
                approxDstExecutionGas
            );
    }
}