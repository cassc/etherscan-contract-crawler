// SPDX-License-Identifier: MIT
// @unsupported: ovm

/**
 Note: This contract has not been audited, exercise caution when using this on mainnet
 */
pragma solidity >0.7.5;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iL1ERC1155Bridge } from "./interfaces/iL1ERC1155Bridge.sol";
import { iL2ERC1155Bridge } from "./interfaces/iL2ERC1155Bridge.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC1155MetadataURI } from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

/* Library Imports */
import { CrossDomainEnabled } from "@eth-optimism/contracts/contracts/libraries/bridge/CrossDomainEnabled.sol";
import { Lib_PredeployAddresses } from "@eth-optimism/contracts/contracts/libraries/constants/Lib_PredeployAddresses.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/* Contract Imports */
import { IL1StandardERC1155 } from "../standards/IL1StandardERC1155.sol";

/* External Imports */
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title L1ERC1155Bridge
 * @dev The L1 ERC1155 Bridge is a contract which stores deposited L1 ERC1155
 * tokens that are in use on L2. It synchronizes a corresponding L2 Bridge, informing it of deposits
 * and listening to it for newly finalized withdrawals.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract L1ERC1155Bridge is iL1ERC1155Bridge, CrossDomainEnabled, ERC1155Holder, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeMath for uint;

    /********************************
     * External Contract References *
     ********************************/

    address public owner;
    address public l2Bridge;
    // Default gas value which can be overridden if more complex logic runs on L2.
    uint32 public depositL2Gas;

    enum Network { L1, L2 }

    // Info of each token
    struct PairTokenInfo {
        address l1Contract;
        address l2Contract;
        Network baseNetwork; // L1 or L2
    }

    // Maps L1 token to tokenId to L2 token contract deposited for the native L1 token
    mapping(address => mapping (uint256 => uint256)) public deposits;
    // Maps L1 token address to tokenInfo
    mapping(address => PairTokenInfo) public pairTokenInfo;

    /***************
     * Constructor *
     ***************/

    // This contract lives behind a proxy, so the constructor parameters will go unused.
    constructor()
        CrossDomainEnabled(address(0))
    {}

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyOwner() {
        require(msg.sender == owner, 'Caller is not the owner');
        _;
    }

    modifier onlyInitialized() {
        require(address(messenger) != address(0), "Contract has not yet been initialized");
        _;
    }

    /******************
     * Initialization *
     ******************/

    /**
     * @dev transfer ownership
     *
     * @param _newOwner new owner of this contract
     */
    function transferOwnership(
        address _newOwner
    )
        public
        onlyOwner()
        onlyInitialized()
    {
        owner = _newOwner;
    }

    /**
     * @dev Configure gas.
     *
     * @param _depositL2Gas default finalized deposit L2 Gas
     */
    function configureGas(
        uint32 _depositL2Gas
    )
        public
        onlyOwner()
        onlyInitialized()
    {
        depositL2Gas = _depositL2Gas;
    }

    /**
     * @param _l1messenger L1 Messenger address being used for cross-chain communications.
     * @param _l2Bridge L2 bridge address.
     */
    function initialize(
        address _l1messenger,
        address _l2Bridge
    )
        public
        initializer()
    {
        require(_l1messenger != address(0) && _l2Bridge != address(0), "zero address not allowed");
        messenger = _l1messenger;
        l2Bridge = _l2Bridge;
        owner = msg.sender;
        configureGas(1400000);

        __Context_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    /***
     * @dev Add the new token pair to the pool
     * DO NOT add the same token token more than once.
     *
     * @param _l1Contract L1 token contract address
     * @param _l2Contract L2 token contract address
     * @param _baseNetwork Network where the token contract was created
     *
     */
    function registerPair(
        address _l1Contract,
        address _l2Contract,
        string memory _baseNetwork
    )
        public
        onlyOwner()
    {
        //create2 would prevent this check
        //require(_l1Contract != _l2Contract, "Contracts should not be the same");
        bytes4 erc1155 = 0xd9b67a26;
        require(ERC165Checker.supportsInterface(_l1Contract, erc1155), "L1 token is not ERC1155 compatible");
        bytes32 bn = keccak256(abi.encodePacked(_baseNetwork));
        bytes32 l1 = keccak256(abi.encodePacked("L1"));
        bytes32 l2 = keccak256(abi.encodePacked("L2"));
        // l2 token address equal to zero, then pair is not registered yet.
        // use with caution, can register only once
        PairTokenInfo storage pairToken = pairTokenInfo[_l1Contract];
        require(pairToken.l2Contract == address(0), "L2 token address already registered");
        // _baseNetwork can only be L1 or L2
        require(bn == l1 || bn == l2, "Invalid Network");
        Network baseNetwork;
        if (bn == l1) {
            baseNetwork = Network.L1;
        }
        else {
            require(ERC165Checker.supportsInterface(_l1Contract, 0xc8a973c4), "L1 contract is not bridgable");
            baseNetwork = Network.L2;
        }

        pairTokenInfo[_l1Contract] =
            PairTokenInfo({
                l1Contract: _l1Contract,
                l2Contract: _l2Contract,
                baseNetwork: baseNetwork
            });
    }

    /**************
     * Depositing *
     **************/

    // /**
    //  * @inheritdoc iL1ERC1155Bridge
    //  */
    function deposit(
        address _l1Contract,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data,
        uint32 _l2Gas
    )
        external
        virtual
        override
        nonReentrant()
        whenNotPaused()
    {
        _initiateDeposit(_l1Contract, msg.sender, msg.sender, _tokenId, _amount, _data, _l2Gas);
    }

    // /**
    //  * @inheritdoc iL1ERC1155Bridge
    //  */
    function depositBatch(
        address _l1Contract,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes memory _data,
        uint32 _l2Gas
    )
        external
        virtual
        override
        nonReentrant()
        whenNotPaused()
    {
        _initiateDepositBatch(_l1Contract, msg.sender, msg.sender, _tokenIds, _amounts, _data, _l2Gas);
    }

    //  /**
    //  * @inheritdoc iL1ERC1155Bridge
    //  */
    function depositTo(
        address _l1Contract,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data,
        uint32 _l2Gas
    )
        external
        virtual
        override
        nonReentrant()
        whenNotPaused()
    {
        _initiateDeposit(_l1Contract, msg.sender, _to, _tokenId, _amount, _data, _l2Gas);
    }

    //  /**
    //  * @inheritdoc iL1ERC1155Bridge
    //  */
    function depositBatchTo(
        address _l1Contract,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes memory _data,
        uint32 _l2Gas
    )
        external
        virtual
        override
        nonReentrant()
        whenNotPaused()
    {
        _initiateDepositBatch(_l1Contract, msg.sender, _to, _tokenIds, _amounts, _data, _l2Gas);
    }

    /**
     * @dev Performs the logic for deposits by informing the L2 Deposited Token
     * contract of the deposit and calling a handler to lock the L1 token. (e.g. transferFrom)
     *
     * @param _l1Contract Address of the L1 token contract we are depositing
     * @param _from Account to pull the deposit from on L1
     * @param _to Account to give the deposit to on L2
     * @param _tokenId token Id to deposit.
     * @param _amount Amount of token Id to deposit.
     * @param _data Optional data for events
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * or encoded tokenURI, in this order of priority if user choses to send, is empty otherwise
     */
    function _initiateDeposit(
        address _l1Contract,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data,
        uint32 _l2Gas
    )
        internal
    {
        PairTokenInfo storage pairToken = pairTokenInfo[_l1Contract];
        require(pairToken.l2Contract != address(0), "Can't Find L2 token Contract");

        require(_amount > 0, "Amount should be greater than 0");

        if (pairToken.baseNetwork == Network.L1) {
            //  This check could be bypassed by a malicious contract via initcode,
            // but it takes care of the user error we want to avoid.
            require(!Address.isContract(msg.sender), "Account not EOA");
            // When a deposit is initiated on L1, the L1 Bridge transfers the funds to itself for future
            // withdrawals. safeTransferFrom also checks if the contract has code, so this will fail if
            // _from is an EOA or address(0).
            IERC1155(_l1Contract).safeTransferFrom(
                _from,
                address(this),
                _tokenId,
                _amount,
                _data
            );

            // Construct calldata for _l2Contract.finalizeDeposit(_to, _amount)
            bytes memory message = abi.encodeWithSelector(
                iL2ERC1155Bridge.finalizeDeposit.selector,
                _l1Contract,
                pairToken.l2Contract,
                _from,
                _to,
                _tokenId,
                _amount,
                _data
            );

            // Send calldata into L2
            sendCrossDomainMessage(
                l2Bridge,
                _l2Gas,
                message
            );

            deposits[_l1Contract][_tokenId] += _amount;
        } else {
            address l2Contract = IL1StandardERC1155(_l1Contract).l2Contract();
            require(pairToken.l2Contract == l2Contract, "L2 token Contract Address Error");

            // When a withdrawal is initiated, we burn the withdrawer's funds to prevent subsequent L2
            // usage
            uint256 balance = IL1StandardERC1155(_l1Contract).balanceOf(msg.sender, _tokenId);
            require(_amount <= balance, "Amount exceeds balance");

            IL1StandardERC1155(_l1Contract).burn(msg.sender, _tokenId, _amount);

            // Construct calldata for l2ERC1155Bridge.finalizeDeposit(_to, _amount)
            bytes memory message;

            message = abi.encodeWithSelector(
                iL2ERC1155Bridge.finalizeDeposit.selector,
                _l1Contract,
                l2Contract,
                _from,
                _to,
                _tokenId,
                _amount,
                _data
            );

            // Send calldata into L2
            sendCrossDomainMessage(
                l2Bridge,
                _l2Gas,
                message
            );
        }

        emit DepositInitiated(_l1Contract, pairToken.l2Contract, _from, _to, _tokenId, _amount, _data);
    }

    /**
     * @dev Performs the logic for deposits by informing the L2 Deposited Token
     * contract of the deposit and calling a handler to lock the L1 token. (e.g. transferFrom)
     *
     * @param _l1Contract Address of the L1 token contract we are depositing
     * @param _from Account to pull the deposit from on L1
     * @param _to Account to give the deposit to on L2
     * @param _tokenIds token Ids to deposit.
     * @param _amounts Amounts of token Id to deposit.
     * @param _data Optional data for events
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * or encoded tokenURI, in this order of priority if user choses to send, is empty otherwise
     */
    function _initiateDepositBatch(
        address _l1Contract,
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes memory _data,
        uint32 _l2Gas
    )
        internal
    {
        PairTokenInfo storage pairToken = pairTokenInfo[_l1Contract];
        require(pairToken.l2Contract != address(0), "Can't Find L2 token Contract");

        for (uint256 i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0, "Amount should be greater than 0");
        }

        if (pairToken.baseNetwork == Network.L1) {
            //  This check could be bypassed by a malicious contract via initcode,
            // but it takes care of the user error we want to avoid.
            require(!Address.isContract(msg.sender), "Account not EOA");
            // When a deposit is initiated on L1, the L1 Bridge transfers the funds to itself for future
            // withdrawals. safeTransferFrom also checks if the contract has code, so this will fail if
            // _from is an EOA or address(0).
            IERC1155(_l1Contract).safeBatchTransferFrom(
                _from,
                address(this),
                _tokenIds,
                _amounts,
                _data
            );

            // Construct calldata for _l2Contract.finalizeDeposit(_to, _amount)
            bytes memory message = abi.encodeWithSelector(
                iL2ERC1155Bridge.finalizeDepositBatch.selector,
                _l1Contract,
                pairToken.l2Contract,
                _from,
                _to,
                _tokenIds,
                _amounts,
                _data
            );

            // Send calldata into L2
            sendCrossDomainMessage(
                l2Bridge,
                _l2Gas,
                message
            );

            for (uint256 i = 0; i < _tokenIds.length; i++) {
                deposits[_l1Contract][_tokenIds[i]] += _amounts[i];
            }
        } else {
            address l2Contract = IL1StandardERC1155(_l1Contract).l2Contract();
            require(pairToken.l2Contract == l2Contract, "L2 token Contract Address Error");

            IL1StandardERC1155(_l1Contract).burnBatch(msg.sender, _tokenIds, _amounts);

            // Construct calldata for l2ERC1155Bridge.finalizeDepositBatch(_to, _amount)
            bytes memory message;

            message = abi.encodeWithSelector(
                iL2ERC1155Bridge.finalizeDepositBatch.selector,
                _l1Contract,
                l2Contract,
                _from,
                _to,
                _tokenIds,
                _amounts,
                _data
            );

            // Send calldata into L2
            sendCrossDomainMessage(
                l2Bridge,
                _l2Gas,
                message
            );
        }

        emit DepositBatchInitiated(_l1Contract, pairToken.l2Contract, _from, _to, _tokenIds, _amounts, _data);
    }

    // /**
    //  * @inheritdoc iL1ERC1155Bridge
    //  */
    function finalizeWithdrawal(
        address _l1Contract,
        address _l2Contract,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    )
        external
        override
        onlyFromCrossDomainAccount(l2Bridge)
    {
        PairTokenInfo storage pairToken = pairTokenInfo[_l1Contract];

        if (pairToken.baseNetwork == Network.L1) {
            // When a withdrawal is finalized on L1, the L1 Bridge transfers the funds to the withdrawer
            IERC1155(_l1Contract).safeTransferFrom(address(this), _to, _tokenId, _amount, _data);

            deposits[_l1Contract][_tokenId] -= _amount;

            emit WithdrawalFinalized(_l1Contract, _l2Contract, _from, _to, _tokenId, _amount, _data);
        } else {
            // replyNeeded helps store the status if a message needs to be sent back to the other layer
            bool replyNeeded = false;
            // Check the target token is compliant and
            // verify the deposited token on L2 matches the L1 deposited token representation here
            if (
                // check with interface of IL1StandardERC1155
                ERC165Checker.supportsInterface(_l1Contract, 0xc8a973c4) &&
                _l2Contract == IL1StandardERC1155(_l1Contract).l2Contract()
            ) {
                // When a deposit is finalized, we credit the account on L2 with the same amount of
                // tokens.
                try IL1StandardERC1155(_l1Contract).mint(_to, _tokenId, _amount, _data) {
                    emit WithdrawalFinalized(_l1Contract, _l2Contract, _from, _to, _tokenId, _amount, _data);
                } catch {
                    replyNeeded = true;
                }
            } else {
                replyNeeded = true;
            }

            if (replyNeeded) {
                bytes memory message = abi.encodeWithSelector(
                    iL2ERC1155Bridge.finalizeDeposit.selector,
                    _l1Contract,
                    _l2Contract,
                    _to,   // switched the _to and _from here to bounce back the deposit to the sender
                    _from,
                    _tokenId,
                    _amount,
                    _data
                );

                // Send message up to L1 bridge
                sendCrossDomainMessage(
                    l2Bridge,
                    depositL2Gas,
                    message
                );
                emit WithdrawalFailed(_l1Contract, _l2Contract, _from, _to, _tokenId, _amount, _data);
            }
        }
    }

    // /**
    //  * @inheritdoc iL1ERC1155Bridge
    //  */
    function finalizeWithdrawalBatch(
        address _l1Contract,
        address _l2Contract,
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes memory _data
    )
        external
        override
        onlyFromCrossDomainAccount(l2Bridge)
    {
        PairTokenInfo storage pairToken = pairTokenInfo[_l1Contract];

        if (pairToken.baseNetwork == Network.L1) {
            // remove the amount from the deposits
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                deposits[_l1Contract][_tokenIds[i]] -= _amounts[i];
            }

            // When a withdrawal is finalized on L1, the L1 Bridge transfers the funds to the withdrawer
            IERC1155(_l1Contract).safeBatchTransferFrom(address(this), _to, _tokenIds, _amounts, _data);

            emit WithdrawalBatchFinalized(_l1Contract, _l2Contract, _from, _to, _tokenIds, _amounts, _data);
        } else {
            // replyNeeded helps store the status if a message needs to be sent back to the other layer
            bool replyNeeded = false;
            // Check the target token is compliant and
            // verify the deposited token on L2 matches the L1 deposited token representation here
            if (
                // check with interface of IL1StandardERC1155
                ERC165Checker.supportsInterface(_l1Contract, 0xc8a973c4) &&
                _l2Contract == IL1StandardERC1155(_l1Contract).l2Contract()
            ) {
                // When a deposit is finalized, we credit the account on L2 with the same amount of
                // tokens.
                try IL1StandardERC1155(_l1Contract).mintBatch(_to, _tokenIds, _amounts, _data) {
                    emit WithdrawalBatchFinalized(_l1Contract, _l2Contract, _from, _to, _tokenIds, _amounts, _data);
                } catch {
                    replyNeeded = true;
                }
            } else {
                replyNeeded = true;
            }

            if (replyNeeded) {
                bytes memory message = abi.encodeWithSelector(
                    iL2ERC1155Bridge.finalizeDeposit.selector,
                    _l1Contract,
                    _l2Contract,
                    _to,   // switched the _to and _from here to bounce back the deposit to the sender
                    _from,
                    _tokenIds,
                    _amounts,
                    _data
                );

                // Send message up to L1 bridge
                sendCrossDomainMessage(
                    l2Bridge,
                    depositL2Gas,
                    message
                );
                emit WithdrawalBatchFailed(_l1Contract, _l2Contract, _from, _to, _tokenIds, _amounts, _data);
            }
        }
    }

    /******************
     *      Pause     *
     ******************/

    /**
     * Pause contract
     */
    function pause() external onlyOwner() {
        _pause();
    }

    /**
     * UnPause contract
     */
    function unpause() external onlyOwner() {
        _unpause();
    }
}