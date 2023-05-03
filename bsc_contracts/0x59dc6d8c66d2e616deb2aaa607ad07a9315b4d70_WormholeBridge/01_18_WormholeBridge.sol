// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

// Contracts
import { SafeTransferLib, ERC20 } from "solmate/utils/SafeTransferLib.sol";
import { Ownable } from "../../common/utils/Ownable.sol";
import { UUPSUpgradeable } from "../../proxy/UUPSUpgradeable.sol";

// Interfaces
import { IWormhole } from "../interfaces/IWormhole.sol";
import { IUSX } from "../../common/interfaces/IUSX.sol";
import { IERC20 } from "../../common/interfaces/IERC20.sol";

contract WormholeBridge is Ownable, UUPSUpgradeable {
    // Private Constants: no SLOAD to save users gas
    address private constant DEPLOYER = 0xcf1FB53BC91410a909a4fFF521dBa6ABF25d4931;

    // Storage Variables: follow storage slot restrictions
    IWormhole public wormholeCoreBridge;
    address public usx;
    mapping(uint16 => uint256) public sendFeeLookup;
    mapping(bytes32 => bool) public trustedContracts;
    mapping(address => bool) public trustedRelayers;
    mapping(bytes32 => bool) public processedMessages;
    bytes32[] private __trustedContractsList;
    address[] private __trustedRelayersList;
    address public feeSetter;

    // Events
    event SendToChain(uint16 indexed _dstChainId, address indexed _from, bytes indexed _toAddress, uint256 _amount);
    event ReceiveFromChain(
        uint16 indexed _srcChainId, bytes indexed _srcAddress, address indexed _toAddress, uint256 _amount
    );

    function initialize(address _wormholeCoreBridge, address _usx) public initializer {
        /// @dev No constructor, so initialize Ownable explicitly.
        require(msg.sender == DEPLOYER, "Invalid caller.");
        require(_wormholeCoreBridge != address(0) && _usx != address(0), "Invalid parameter.");
        __Ownable_init();
        wormholeCoreBridge = IWormhole(_wormholeCoreBridge);
        usx = _usx;
    }

    /// @dev Required by the UUPS module.
    function _authorizeUpgrade(address) internal override onlyOwner { }

    function sendMessage(address payable _from, uint16 _dstChainId, bytes memory _toAddress, uint256 _amount)
        external
        payable
        returns (uint64 sequence)
    {
        uint256 wormholeMessageFee = wormholeCoreBridge.messageFee();

        require(msg.sender == usx, "Unauthorized.");
        require(msg.value >= sendFeeLookup[_dstChainId] + wormholeMessageFee, "Not enough native token for gas.");

        // Cast encoded _toAddress to uint256
        uint256 toAddressUint = uint256(bytes32(_toAddress));

        bytes memory message = abi.encode(abi.encodePacked(_from), _dstChainId, toAddressUint, _amount);

        // Consistency level of 1 is the most conservative (finalized)
        sequence = wormholeCoreBridge.publishMessage{ value: wormholeMessageFee }(0, message, 1);

        emit SendToChain(_dstChainId, _from, _toAddress, _amount);
    }

    function processMessage(bytes memory _vaa) public {
        // Parse and verify the VAA.
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormholeCoreBridge.parseAndVerifyVM(_vaa);

        // Ensure message verification succeeded.
        require(valid, reason);

        // Ensure the emitterAddress of this VAA is a trusted address.
        require(trustedContracts[vm.emitterAddress], "Unauthorized emitter address.");

        // Ensure that the VAA hasn't already been processed (replay protection).
        require(!processedMessages[vm.hash], "Message already processed.");

        // Enure relayer is trusted.
        require(trustedRelayers[msg.sender], "Unauthorized relayer.");

        // Add the VAA to processed messages, so it can't be replayed.
        processedMessages[vm.hash] = true;

        // The message content can now be trusted.
        (bytes memory srcAddress,, uint256 toAddressUint, uint256 amount) =
            abi.decode(vm.payload, (bytes, uint16, uint256, uint256));

        address toAddress = address(uint160(toAddressUint));

        // Event
        emit ReceiveFromChain(vm.emitterChainId, srcAddress, toAddress, amount);

        // Needs admin privlieges on USX
        IUSX(usx).mint(toAddress, amount);
    }

    /* ****************************************************************************
    **
    **  Admin Functions
    **
    ******************************************************************************/

    /**
     * @dev This function allows contract admins to manage trustworthiness of remote emitter contracts.
     * @param _contract A remote emitter contract.
     * @param _isTrusted True, if trusted. False, if untrusted.
     */
    function manageTrustedContracts(bytes32 _contract, bool _isTrusted) public onlyOwner {
        trustedContracts[_contract] = _isTrusted;

        if (!_isTrusted) {
            for (uint256 i; i < __trustedContractsList.length; i++) {
                if (__trustedContractsList[i] == _contract) {
                    __trustedContractsList[i] = __trustedContractsList[__trustedContractsList.length - 1];
                    __trustedContractsList.pop();
                    break;
                }
            }
        } else {
            __trustedContractsList.push(_contract);
        }
    }

    /**
     * @dev This function allows contract admins to manage trustworthiness of relayers.
     * @param _relayer The address of the relayer.
     * @param _isTrusted True, if trusted. False, if untrusted.
     */
    function manageTrustedRelayers(address _relayer, bool _isTrusted) public onlyOwner {
        trustedRelayers[_relayer] = _isTrusted;

        if (!_isTrusted) {
            for (uint256 i; i < __trustedRelayersList.length; i++) {
                if (__trustedRelayersList[i] == _relayer) {
                    __trustedRelayersList[i] = __trustedRelayersList[__trustedRelayersList.length - 1];
                    __trustedRelayersList.pop();
                    break;
                }
            }
        } else {
            __trustedRelayersList.push(_relayer);
        }
    }

    /**
     * @dev This function allows contract admins to retreive trusted, remote emitter contracts.
     */
    function getTrustedContracts() public view onlyOwner returns (bytes32[] memory) {
        return __trustedContractsList;
    }

    /**
     * @dev This function allows contract admins retreive trusted relayers.
     */
    function getTrustedRelayers() public view onlyOwner returns (address[] memory) {
        return __trustedRelayersList;
    }

    /**
     * @dev This function allows contract admins to extract any ERC20 token.
     * @param _token The address of token to remove.
     */
    function extractERC20(address _token) public onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));

        SafeTransferLib.safeTransfer(ERC20(_token), msg.sender, balance);
    }

    /**
     * @dev This function allows contract admins to extract this contract's native tokens.
     */
    function extractNative() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev This function allows contract admins to set the address of the feeSetter account.
     * @param _feeSetter The address of the account that's allowed to update destination fees.
     */
    function setFeeSetter(address _feeSetter) public onlyOwner {
        feeSetter = _feeSetter;
    }

    /**
     * @dev This function allows contract admins to update send fees.
     * @param _destChainIds an array of destination chain IDs; the order must match `_fees` array.
     * @param _fees an array of destination fees; the order must match `_destChainIds` array. Any
     *              element with a value of zero will not get updated (allows for gas-saving optionality).
     */
    function setSendFees(uint16[] calldata _destChainIds, uint256[] calldata _fees) public {
        require(msg.sender == feeSetter, "Unauthorized.");
        require(_destChainIds.length == _fees.length, "Array lengths do not match");
        for (uint256 i; i < _destChainIds.length; i++) {
            if (_fees[i] != 0) {
                sendFeeLookup[_destChainIds[i]] = _fees[i];
            }
        }
    }

    receive() external payable { }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage slots in the inheritance chain.
     * Storage slot management is necessary, as we're using an upgradable proxy contract.
     * For details, see: https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}