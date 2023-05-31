// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "../interfaces/IDavosBridge.sol";

import "../libraries/EthereumVerifier.sol";
import "../libraries/ProofParser.sol";
import "../libraries/Utils.sol";

contract DavosBridge is IDavosBridge, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    // --- Vars ---
    uint256 private _globalNonce;
    address private _consensusAddress;
    Metadata private _nativeTokenMetadata;

    mapping(bytes32 => bool) private _usedProofs;
    mapping(uint256 => address) private _bridgeAddressByChainId;
    mapping(bytes32 => address) private _warpDestinations; // KECCAK256(fromToken,fromChain,_bridgeAddressByChainId(toChain)) => destinationToken

    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(address consensusAddress, string memory nativeTokenSymbol, string memory nativeTokenName) external initializer {

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _consensusAddress = consensusAddress;
        _nativeTokenMetadata = Metadata(
            Utils.stringToBytes32(nativeTokenSymbol),
            Utils.stringToBytes32(nativeTokenName),
            block.chainid,
            address(bytes20(keccak256(abi.encodePacked("DavosBridge", nativeTokenSymbol))))     
        );
    }

    // --- User ---
    function depositToken(address fromToken, uint256 toChain, address toAddress, uint256 amount) external override nonReentrant whenNotPaused {

        if (warpDestination(fromToken, toChain) != address(0)) {
            _depositWarped(fromToken, toChain, toAddress, amount);
        } else revert("DavosBridge/warp-destination-unknown");
    }
    /**
     * @dev Tokens on source and destination chains are linked with independent supplies.
     * Burns tokens on source chain (to later mint on destination chain).
     * @param fromToken one of many warp-able token on source chain.
     * @param toChain one of many destination chain ID.
     * @param toAddress claimer of 'totalAmount' on destination chain.
     * @param totalAmount amout of tokens to be warped.
     */
    function _depositWarped(address fromToken, uint256 toChain, address toAddress, uint256 totalAmount) internal {

        require(_bridgeAddressByChainId[toChain] != address(0), "DavosBridge/non-existing-bridge");
        address fromAddress = address(msg.sender);
        
        uint256 balanceBefore = IERC20Upgradeable(fromToken).balanceOf(fromAddress);
        IERC20Mintable(fromToken).burn(fromAddress, totalAmount); 
        uint256 balanceAfter = IERC20Upgradeable(fromToken).balanceOf(fromAddress);
        require(balanceAfter + totalAmount == balanceBefore, "DavosBridge/incorrect-transfer-amount");

        /* fromToken and toToken are independent, originChain and originAddress are invalid */
        Metadata memory metaData = Metadata(
            Utils.stringToBytes32(IERC20Extra(fromToken).symbol()),
            Utils.stringToBytes32(IERC20Extra(fromToken).name()),
            0,
            address(0)
        );

       _globalNonce++;

        emit DepositWarped(toChain, fromAddress, toAddress, fromToken, warpDestination(fromToken, toChain), _amountErc20Token(fromToken, totalAmount), _globalNonce, metaData);
    }
    function _amountErc20Token(address fromToken, uint256 totalAmount) internal returns (uint256) {

        /* scale amount to 18 decimals */
        require(IERC20Extra(fromToken).decimals() <= 18, "DavosBridge/decimals-overflow");
        totalAmount *= (10**(18 - IERC20Extra(fromToken).decimals()));
        return totalAmount;
    }
    function withdraw(bytes calldata, /* encodedProof */ bytes calldata rawReceipt, bytes memory proofSignature) external override nonReentrant whenNotPaused {

        uint256 proofOffset;
        uint256 receiptOffset;
        assembly {
            proofOffset := add(0x4, calldataload(4))
            receiptOffset := add(0x4, calldataload(36))
        }
        /* we must parse and verify that tx and receipt matches */
        (EthereumVerifier.State memory state, EthereumVerifier.PegInType pegInType) = EthereumVerifier.parseTransactionReceipt(receiptOffset);

        require(state.chainId == block.chainid, "DavosBridge/receipt-points-to-another-chain");

        ProofParser.Proof memory proof = ProofParser.parseProof(proofOffset);
        require(_bridgeAddressByChainId[proof.chainId] == state.contractAddress, "DavosBridge/event-from-unknown-bridge");

        state.receiptHash = keccak256(rawReceipt);
        proof.status = 0x01;
        proof.receiptHash = state.receiptHash;

        bytes32 proofHash;
        assembly {
            proofHash := keccak256(proof, 0x100)
        }

        // we can trust receipt only if proof is signed by consensus
        require(ECDSAUpgradeable.recover(proofHash, proofSignature) == _consensusAddress, "DavosBridge/bad-signature");

        // withdraw funds to recipient
        _withdraw(state, pegInType, proof, proofHash);
    }
    function _withdraw(EthereumVerifier.State memory state, EthereumVerifier.PegInType pegInType, ProofParser.Proof memory proof, bytes32 payload) internal {

        require(!_usedProofs[payload], "DavosBridge/used-proof");
        _usedProofs[payload] = true;
        if (pegInType == EthereumVerifier.PegInType.Warp) {
            _withdrawWarped(state, proof);
        } else revert("DavosBridge/invalid-type");
    }
    function _withdrawWarped(EthereumVerifier.State memory state, ProofParser.Proof memory proof) internal {

        require(warpDestination(state.toToken, proof.chainId) == state.fromToken, "DavosBridge/bridge-from-unknown-destination");
        IERC20Mintable(state.toToken).mint(state.toAddress, state.totalAmount);

        emit WithdrawMinted(state.receiptHash, state.fromAddress, state.toAddress, state.fromToken, state.toToken, state.totalAmount);
    }

    // --- Admin ---
    function pause() public onlyOwner {

        _pause();
    }
    function unpause() public onlyOwner {

        _unpause();
    }
    function addBridge(address bridge, uint256 toChain) public onlyOwner {

        require(_bridgeAddressByChainId[toChain] == address(0x00), "DavosBridge/already-allowed");
        require(toChain > 0, "DavosBridge/invalid-chain");
        _bridgeAddressByChainId[toChain] = bridge;

        emit BridgeAdded(bridge, toChain);
    }
    function removeBridge(uint256 toChain) public onlyOwner {

        require(_bridgeAddressByChainId[toChain] != address(0x00), "already-removed");
        require(toChain > 0, "DavosBridge/invalid-chain");
        address bridge = _bridgeAddressByChainId[toChain];
        delete _bridgeAddressByChainId[toChain];

        emit BridgeRemoved(bridge, toChain);
    }
    function addWarpDestination(address fromToken, uint256 toChain, address toToken) external onlyOwner {

        require(_bridgeAddressByChainId[toChain] != address(0), "DavosBridge/bad-chain");
        bytes32 direction = keccak256(abi.encodePacked(fromToken, block.chainid, _bridgeAddressByChainId[toChain]));
        require(_warpDestinations[direction] == address(0), "DavosBridge/known-destination");
        _warpDestinations[direction] = toToken;

        emit WarpDestinationAdded(fromToken, toChain, toToken);
    }
    function changeConsensus(address consensus) public onlyOwner {

        require(consensus != address(0x0), "DavosBridge/invalid-address");
        _consensusAddress = consensus;

        emit ConsensusChanged(_consensusAddress);
    }
    function changeMetadata(address token, bytes32 name, bytes32 symbol) external onlyOwner {
        
        IERC20MetadataChangeable(token).changeName(name);
        IERC20MetadataChangeable(token).changeSymbol(symbol);
    }

    // --- Views ---
    function warpDestination(address fromToken, uint256 toChain) public view returns(address) {

        return _warpDestinations[keccak256(abi.encodePacked(fromToken, block.chainid, _bridgeAddressByChainId[toChain]))];
    }

    // --- Primitives ---
    receive() external payable {}
}