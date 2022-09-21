// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity >0.7.5;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iL1NFTBridge } from "./interfaces/iL1NFTBridge.sol";
import { iL2NFTBridge } from "./interfaces/iL2NFTBridge.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/* Library Imports */
import { CrossDomainEnabled } from "@eth-optimism/contracts/contracts/libraries/bridge/CrossDomainEnabled.sol";
import { Lib_PredeployAddresses } from "@eth-optimism/contracts/contracts/libraries/constants/Lib_PredeployAddresses.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/* Contract Imports */
import { IL1StandardERC721 } from "../standards/IL1StandardERC721.sol";
import { iSupportBridgeExtraData } from "./interfaces/iSupportBridgeExtraData.sol";

/* External Imports */
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title L1NFTBridge
 * @dev The L1 NFT Bridge is a contract which stores deposited L1 ERC721
 * tokens that are in use on L2. It synchronizes a corresponding L2 Bridge, informing it of deposits
 * and listening to it for newly finalized withdrawals.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract L1NFTBridge is iL1NFTBridge, CrossDomainEnabled, ERC721Holder, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeMath for uint;

    /********************************
     * External Contract References *
     ********************************/

    address public owner;
    address public l2NFTBridge;
    // Default gas value which can be overridden if more complex logic runs on L2.
    uint32 public depositL2Gas;

    enum Network { L1, L2 }

    // Info of each NFT
    struct PairNFTInfo {
        address l1Contract;
        address l2Contract;
        Network baseNetwork; // L1 or L2
    }

    // Maps L1 token to tokenId to L2 token contract deposited for the native L1 NFT
    mapping(address => mapping (uint256 => address)) public deposits;
    // Maps L1 NFT address to NFTInfo
    mapping(address => PairNFTInfo) public pairNFTInfo;

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
     * @param _l2NFTBridge L2 NFT bridge address.
     */
    function initialize(
        address _l1messenger,
        address _l2NFTBridge
    )
        public
        initializer()
    {
        require(_l1messenger != address(0) && _l2NFTBridge != address(0), "zero address not allowed");
        messenger = _l1messenger;
        l2NFTBridge = _l2NFTBridge;
        owner = msg.sender;
        configureGas(1400000);

        __Context_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    /***
     * @dev Add the new NFT pair to the pool
     * DO NOT add the same NFT token more than once.
     *
     * @param _l1Contract L1 NFT contract address
     * @param _l2Contract L2 NFT contract address
     * @param _baseNetwork Network where the NFT contract was created
     *
     */
    function registerNFTPair(
        address _l1Contract,
        address _l2Contract,
        string memory _baseNetwork
    )
        public
        onlyOwner()
    {
        //create2 would prevent this check
        //require(_l1Contract != _l2Contract, "Contracts should not be the same");
        bytes4 erc721 = 0x80ac58cd;
        require(ERC165Checker.supportsInterface(_l1Contract, erc721), "L1 NFT is not ERC721 compatible");
        bytes32 bn = keccak256(abi.encodePacked(_baseNetwork));
        bytes32 l1 = keccak256(abi.encodePacked("L1"));
        bytes32 l2 = keccak256(abi.encodePacked("L2"));
        // l2 NFT address equal to zero, then pair is not registered yet.
        // use with caution, can register only once
        PairNFTInfo storage pairNFT = pairNFTInfo[_l1Contract];
        require(pairNFT.l2Contract == address(0), "L2 NFT address already registered");
        // _baseNetwork can only be L1 or L2
        require(bn == l1 || bn == l2, "Invalid Network");
        Network baseNetwork;
        if (bn == l1) {
            baseNetwork = Network.L1;
        }
        else {
            require(ERC165Checker.supportsInterface(_l1Contract, 0xec88b5ce), "L1 contract is not bridgable");
            baseNetwork = Network.L2;
        }

        pairNFTInfo[_l1Contract] =
            PairNFTInfo({
                l1Contract: _l1Contract,
                l2Contract: _l2Contract,
                baseNetwork: baseNetwork
            });
    }

    /**************
     * Depositing *
     **************/

    // /**
    //  * @inheritdoc iL1NFTBridge
    //  */
    function depositNFT(
        address _l1Contract,
        uint256 _tokenId,
        uint32 _l2Gas
    )
        external
        virtual
        override
        nonReentrant()
        whenNotPaused()
    {
        _initiateNFTDeposit(_l1Contract, msg.sender, msg.sender, _tokenId, _l2Gas, "");
    }

    //  /**
    //  * @inheritdoc iL1NFTBridge
    //  */
    function depositNFTTo(
        address _l1Contract,
        address _to,
        uint256 _tokenId,
        uint32 _l2Gas
    )
        external
        virtual
        override
        nonReentrant()
        whenNotPaused()
    {
        _initiateNFTDeposit(_l1Contract, msg.sender, _to, _tokenId, _l2Gas, "");
    }

    //  /**
    //  * @inheritdoc iL1NFTBridge
    //  */
    function depositNFTWithExtraData(
        address _l1Contract,
        uint256 _tokenId,
        uint32 _l2Gas
    )
        external
        virtual
        override
        nonReentrant()
        whenNotPaused()
    {
        bytes memory extraData;
        // if token has base on this layer
        if (pairNFTInfo[_l1Contract].baseNetwork == Network.L1) {
            // check the existence of bridgeExtraData(uint256) on l1Contract
            if (ERC165Checker.supportsInterface(_l1Contract, 0x9b9284f9)) {
                extraData = iSupportBridgeExtraData(_l1Contract).bridgeExtraData(_tokenId);
            } else {
                // otherwise send tokenURI return (encoded in bytes)
                // allow to fail if the call fails
                extraData = abi.encode(IERC721Metadata(_l1Contract).tokenURI(_tokenId));
            }
        }
        // size limits unchecked
        _initiateNFTDeposit(_l1Contract, msg.sender, msg.sender, _tokenId, _l2Gas, extraData);
    }

    //  /**
    //  * @inheritdoc iL1NFTBridge
    //  */
    function depositNFTWithExtraDataTo(
        address _l1Contract,
        address _to,
        uint256 _tokenId,
        uint32 _l2Gas
    )
        external
        virtual
        override
        nonReentrant()
        whenNotPaused()
    {
        bytes memory extraData;
        // if token has base on this layer
        if (pairNFTInfo[_l1Contract].baseNetwork == Network.L1) {
            // check the existence of bridgeExtraData(uint256) on l1Contract
            if (ERC165Checker.supportsInterface(_l1Contract, 0x9b9284f9)) {
                extraData = iSupportBridgeExtraData(_l1Contract).bridgeExtraData(_tokenId);
            } else {
                // otherwise send tokenURI return (encoded in bytes)
                // allow to fail if the call fails
                extraData = abi.encode(IERC721Metadata(_l1Contract).tokenURI(_tokenId));
            }
        }
        // size limits unchecked
        _initiateNFTDeposit(_l1Contract, msg.sender, _to, _tokenId, _l2Gas, extraData);
    }

    /**
     * @dev Performs the logic for deposits by informing the L2 Deposited Token
     * contract of the deposit and calling a handler to lock the L1 token. (e.g. transferFrom)
     *
     * @param _l1Contract Address of the L1 NFT contract we are depositing
     * @param _from Account to pull the deposit from on L1
     * @param _to Account to give the deposit to on L2
     * @param _tokenId NFT token Id to deposit.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Data/metadata to forward to L2. This data is either extraBridgeData,
     * or encoded tokenURI, in this order of priority if user choses to send, is empty otherwise
     */
    function _initiateNFTDeposit(
        address _l1Contract,
        address _from,
        address _to,
        uint256 _tokenId,
        uint32 _l2Gas,
        bytes memory _data
    )
        internal
    {
        PairNFTInfo storage pairNFT = pairNFTInfo[_l1Contract];
        require(pairNFT.l2Contract != address(0), "Can't Find L2 NFT Contract");

        if (pairNFT.baseNetwork == Network.L1) {
            //  This check could be bypassed by a malicious contract via initcode,
            // but it takes care of the user error we want to avoid.
            require(!Address.isContract(msg.sender), "Account not EOA");
            // When a deposit is initiated on L1, the L1 Bridge transfers the funds to itself for future
            // withdrawals. safeTransferFrom also checks if the contract has code, so this will fail if
            // _from is an EOA or address(0).
            IERC721(_l1Contract).safeTransferFrom(
                _from,
                address(this),
                _tokenId
            );

            // Construct calldata for _l2Contract.finalizeDeposit(_to, _amount)
            bytes memory message = abi.encodeWithSelector(
                iL2NFTBridge.finalizeDeposit.selector,
                _l1Contract,
                pairNFT.l2Contract,
                _from,
                _to,
                _tokenId,
                _data
            );

            // Send calldata into L2
            sendCrossDomainMessage(
                l2NFTBridge,
                _l2Gas,
                message
            );

            deposits[_l1Contract][_tokenId] = pairNFT.l2Contract;
        } else {
            address l2Contract = IL1StandardERC721(_l1Contract).l2Contract();
            require(pairNFT.l2Contract == l2Contract, "L2 NFT Contract Address Error");

            // When a withdrawal is initiated, we burn the withdrawer's funds to prevent subsequent L2
            // usage
            address NFTOwner = IL1StandardERC721(_l1Contract).ownerOf(_tokenId);
            require(
                msg.sender == NFTOwner || IL1StandardERC721(_l1Contract).getApproved(_tokenId) == msg.sender ||
                IL1StandardERC721(_l1Contract).isApprovedForAll(NFTOwner, msg.sender)
            );

            IL1StandardERC721(_l1Contract).burn(_tokenId);

            // Construct calldata for l2NFTBridge.finalizeDeposit(_to, _amount)
            bytes memory message;

            message = abi.encodeWithSelector(
                iL2NFTBridge.finalizeDeposit.selector,
                _l1Contract,
                l2Contract,
                _from,
                _to,
                _tokenId,
                _data
            );

            // Send calldata into L2
            sendCrossDomainMessage(
                l2NFTBridge,
                _l2Gas,
                message
            );
        }

        emit NFTDepositInitiated(_l1Contract, pairNFT.l2Contract, _from, _to, _tokenId, _data);
    }

    // /**
    //  * @inheritdoc iL1NFTBridge
    //  */
    function finalizeNFTWithdrawal(
        address _l1Contract,
        address _l2Contract,
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    )
        external
        override
        onlyFromCrossDomainAccount(l2NFTBridge)
    {
        PairNFTInfo storage pairNFT = pairNFTInfo[_l1Contract];

        if (pairNFT.baseNetwork == Network.L1) {
            // needs to verify comes from correct l2Contract
            require(deposits[_l1Contract][_tokenId] == _l2Contract, "Incorrect Burn");

            // When a withdrawal is finalized on L1, the L1 Bridge transfers the funds to the withdrawer
            IERC721(_l1Contract).safeTransferFrom(address(this), _to, _tokenId);

            emit NFTWithdrawalFinalized(_l1Contract, _l2Contract, _from, _to, _tokenId, _data);
        } else {
            // Check the target token is compliant and
            // verify the deposited token on L2 matches the L1 deposited token representation here
            if (
                // check with interface of IL1StandardERC721
                ERC165Checker.supportsInterface(_l1Contract, 0xec88b5ce) &&
                _l2Contract == IL1StandardERC721(_l1Contract).l2Contract()
            ) {
                // When a deposit is finalized, we credit the account on L2 with the same amount of
                // tokens.
                IL1StandardERC721(_l1Contract).mint(_to, _tokenId, _data);
                emit NFTWithdrawalFinalized(_l1Contract, _l2Contract, _from, _to, _tokenId, _data);
            } else {
                bytes memory message = abi.encodeWithSelector(
                    iL2NFTBridge.finalizeDeposit.selector,
                    _l1Contract,
                    _l2Contract,
                    _to,   // switched the _to and _from here to bounce back the deposit to the sender
                    _from,
                    _tokenId,
                    _data
                );

                // Send message up to L1 bridge
                sendCrossDomainMessage(
                    l2NFTBridge,
                    depositL2Gas,
                    message
                );
                emit NFTWithdrawalFailed(_l1Contract, _l2Contract, _from, _to, _tokenId, _data);
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