// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./BaseRouter.sol";
import "./interfaces/IPortalV2.sol";
import "./interfaces/ISynthesisV2.sol";
import "./interfaces/IRouterV2.sol";
import "./interfaces/IAddressBook.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IERC20WithPermit.sol";
import "./interfaces/ISynth.sol";


contract RouterV2 is BaseRouter, ReentrancyGuard, IRouter {

    enum CrossChainOpState { Unknown, Succeeded, Reverted }

    /// @dev permit operation code
    bytes32 public constant PERMIT_CODE = keccak256(abi.encodePacked("P"));
    /// @dev lock operation code
    bytes32 public constant LOCK_MINT_CODE = keccak256(abi.encodePacked("LM"));
    /// @dev unlock operation code
    bytes32 public constant BURN_UNLOCK_CODE = keccak256(abi.encodePacked("BU"));
    /// @dev mint operation code
    bytes32 public constant BURN_MINT_CODE = keccak256(abi.encodePacked("BM"));
    /// @dev wrap operation code
    bytes32 public constant WRAP_CODE = keccak256(abi.encodePacked("W"));
    /// @dev unwrap operation code
    bytes32 public constant UNWRAP_CODE = keccak256(abi.encodePacked("Uw"));
    /// @dev emergency cancel lock operation code
    bytes32 public constant EMERGENCY_UNLOCK_CODE = keccak256(abi.encodePacked("!M"));
    /// @dev emergency cancel burn operation code
    bytes32 public constant EMERGENCY_MINT_CODE = keccak256(abi.encodePacked("!U"));
    /// @dev processed cross-chain ops (can't be reverted)
    mapping(bytes32 => CrossChainOpState) public processedOps;

    modifier onlyBridge() {
        address bridge = IAddressBook(addressBook).bridge();
        require(bridge == msg.sender, "EndPoint: bridge only");
        _;
    }

    constructor(address addressBook_) BaseRouter(addressBook_) {}

    receive() external payable {}

    function receiveValidatedData(bytes4 selector, address from, uint64 chainIdFrom) external virtual onlyBridge returns (bool) {
        address router = IAddressBook(addressBook).router(chainIdFrom);
        require(from == router, "Router: wrong sender");
        require(selector == RouterV2.resume.selector, "Router: wrong selector");
        currentChainIdFrom = chainIdFrom;
        return true;
    }

    /**
     * @dev Token synthesize request to another EVM chain via native payment.
     *
     * A: Lock(X) -> B: Mint(sX_A) = sX_A
     *
     * @param operations operation types;
     * @param params operation params;
     * @param receipt clp invoice.
     */
    function start(
        string[] calldata operations,
        bytes[] memory params,
        Invoice calldata receipt
    ) external payable nonReentrant {
        _start(operations, params, receipt);
    }

    function resume(
        bytes32 requestId,
        uint8 cPos,
        string[] calldata operations,
        bytes[] memory params
    ) external onlyBridge crosschainHandling(requestId) nonReentrant {
        _resume(requestId, cPos, operations, params);
    }

    /**
     * @dev Should be implemented for each router.
     *
     * Each implementation must:
     * Revert execution if op is not supported;
     * Return chainId and destination router if current op is cross-chain; 
     */
    function _executeOp(
        bool isOpHalfDone,
        bytes32 op,
        bytes32 nextOp,
        bytes memory params,
        MaskedParams memory prevMaskedParams
    ) internal virtual override returns (uint64 chainIdTo, bytes memory updatedParams, MaskedParams memory maskedParams, ExecutionResult result) {
        result = ExecutionResult.Succeeded;
        if (PERMIT_CODE == op) {
            PermitParams memory p = abi.decode(params, (PermitParams));
            IERC20WithPermit(p.token).permit(
                p.owner,
                address(this),
                p.amount,
                p.deadline,
                p.v,
                p.r,
                p.s
            );
        } else if (LOCK_MINT_CODE == op || BURN_UNLOCK_CODE == op || BURN_MINT_CODE == op) {
            SynthParams memory p = abi.decode(params, (SynthParams));
            if (isOpHalfDone == false) {
                (p.amountIn, p.from, p.emergencyTo) = _checkMaskedParams(p.amountIn, p.from, p.emergencyTo, prevMaskedParams);
                p.to = _checkTo(p.to, p.emergencyTo, p.chainIdTo, nextOp);
                address possibleAdapter;
                if (LOCK_MINT_CODE == op) {
                    _lock(p);
                } else {
                    address synthesis = IAddressBook(addressBook).synthesis(uint64(block.chainid));
                    possibleAdapter = ISynthesisV2(synthesis).synthBySynth(p.tokenIn);
                    if (possibleAdapter != address(0)) {
                        if (p.from != synthesis) {
                            SafeERC20.safeTransferFrom(IERC20(p.tokenIn), p.from, synthesis, p.amountIn);
                        }
                        p.from = synthesis;
                    } else {
                        possibleAdapter = p.tokenIn;
                    }
                    ISynthesisV2(synthesis).burn(p.tokenIn, p.amountIn, p.from, p.to, p.chainIdTo);
                }
                chainIdTo = p.chainIdTo;
                if (LOCK_MINT_CODE != op) {
                    ISynthAdapter synthImpl = ISynthAdapter(possibleAdapter);
                    p.tokenIn = synthImpl.originalToken();
                    p.tokenInChainIdFrom = synthImpl.chainIdFrom();
                } else {
                    p.tokenInChainIdFrom = uint64(block.chainid);
                }
                updatedParams = abi.encode(p);
            } else {
                require(processedOps[currentRequestId] == CrossChainOpState.Unknown, "Router: op processed");
                processedOps[currentRequestId] = CrossChainOpState.Succeeded;
                if (p.to == address(0)) {
                    p.to = _checkTo(p.to, p.emergencyTo, p.chainIdTo, nextOp);
                }
                maskedParams.amountOut = BURN_UNLOCK_CODE == op ? _unlock(p) : _mint(p);
                maskedParams.to = p.to;
                maskedParams.emergencyTo = p.emergencyTo;
            }
        } else if (WRAP_CODE == op || UNWRAP_CODE == op) {
            WrapParams memory p = abi.decode(params, (WrapParams));
            address tmp;
            (p.amountIn, p.from, tmp) = _checkMaskedParams(p.amountIn, p.from, address(0), prevMaskedParams);
            p.to = _checkTo(p.to, p.to, uint64(block.chainid), nextOp);
            maskedParams.amountOut = WRAP_CODE == op ? _wrap(p) : _unwrap(p);
            maskedParams.to = p.to;
            maskedParams.emergencyTo = prevMaskedParams.emergencyTo;
        } else if (EMERGENCY_UNLOCK_CODE == op || EMERGENCY_MINT_CODE == op) {
            CancelParams memory p = abi.decode(params, (CancelParams));
            if (isOpHalfDone == false) {
                require(processedOps[p.requestId] != CrossChainOpState.Succeeded, "Router: op processed");
                processedOps[currentRequestId] = CrossChainOpState.Reverted;
                chainIdTo = p.chainIdTo;
            } else {
                bytes memory emergencyParams = startedOps[p.requestId];
                require(emergencyParams.length != 0, "Router: op not started");
                SynthParams memory eP = abi.decode(emergencyParams, (SynthParams));
                delete startedOps[p.requestId];
                if (EMERGENCY_UNLOCK_CODE == op) {
                    maskedParams.amountOut = _emergencyUnlock(eP);
                } else {
                    maskedParams.amountOut = _emergencyMint(eP);
                }
            }
        } else {
            maskedParams = prevMaskedParams;
            result = ExecutionResult.Failed;
        }
    }

    function _lock(SynthParams memory p) internal {
        address portal = IAddressBook(addressBook).portal(uint64(block.chainid));
        if (p.from != portal) {
            SafeERC20.safeTransferFrom(IERC20(p.tokenIn), p.from, portal, p.amountIn);
        }
        IPortalV2(portal).lock(p.tokenIn, p.amountIn, p.from, p.to);
    }

    function _unlock(SynthParams memory p) internal returns (uint256 amountOut) {
        address portal = IAddressBook(addressBook).portal(uint64(block.chainid));
        amountOut = IPortalV2(portal).unlock(p.tokenIn, p.amountIn, p.from, p.to);
    }

    function _emergencyUnlock(SynthParams memory p) internal returns (uint256 amountOut) {
        require(currentChainIdFrom == p.chainIdTo, "Router: wrong emergency init");
        address portal = IAddressBook(addressBook).portal(uint64(block.chainid));
        amountOut = IPortalV2(portal).emergencyUnlock(p.tokenIn, p.amountIn, p.from, p.emergencyTo);
    }

    function _mint(SynthParams memory p) internal returns (uint256 amountOut) {
        address synthesis = IAddressBook(addressBook).synthesis(uint64(block.chainid));
        amountOut = ISynthesisV2(synthesis).mint(p.tokenIn, p.amountIn, p.from, p.to, p.tokenInChainIdFrom);
    }

    function _emergencyMint(SynthParams memory p) internal returns (uint256 amountOut) {
        require(currentChainIdFrom == p.chainIdTo, "Router: wrong emergency init");
        address synthesis = IAddressBook(addressBook).synthesis(uint64(block.chainid));
        p.tokenIn = ISynthesisV2(synthesis).synthByOriginal(p.tokenInChainIdFrom, p.tokenIn);
        amountOut = ISynthesisV2(synthesis).emergencyMint(p.tokenIn, p.amountIn, p.from, p.emergencyTo);
    }

    function _wrap(WrapParams memory p) internal returns (uint256 amountOut) {
        require(msg.value >= p.amountIn, "Router: invalid amount");
        IWETH9(p.tokenIn).deposit{ value: p.amountIn }();
        SafeERC20.safeTransfer(IERC20(p.tokenIn), p.to, p.amountIn);
        amountOut = p.amountIn;
    }

    function _unwrap(WrapParams memory p) internal returns (uint256 amountOut) {
        if (p.from != address(this)) {
            SafeERC20.safeTransferFrom(IERC20(p.tokenIn), p.from, address(this), p.amountIn);
        }
        IWETH9(p.tokenIn).withdraw(p.amountIn);
        (bool sent, ) = p.to.call{ value: p.amountIn }("");
        require(sent, "Router: failed to send ETH");
        amountOut = p.amountIn;
    }

    function _proceedFees(uint256 executionPrice, address accountant) internal virtual override {
        require(msg.value >= executionPrice, "Router: invalid amount");
        (bool sent, ) = accountant.call{ value: executionPrice }("");
        require(sent, "Router: failed to send Ether");
        emit FeePaid(msg.sender, accountant, executionPrice);
    }

    /**
     * @dev Should check current params for mask and return correct values.
     *
     * @param currentAmountIn current op amountIn, can be UINT256_MAX;
     * @param currentFrom current op from, always must be equal address(0), except initial op;
     * @param currentEmergencyTo current op emergencyTo, must be msg.sender in initial op or addres(0) in all others;
     * @param prevMaskedParams prev params, which can be used to update current given params.
     */
    function _checkMaskedParams(
        uint256 currentAmountIn,
        address currentFrom,
        address currentEmergencyTo,
        MaskedParams memory prevMaskedParams
    ) internal view returns (uint256 amountIn, address from, address emergencyTo) {
        // amountIn check
        amountIn = currentAmountIn == type(uint256).max ? prevMaskedParams.amountOut : currentAmountIn;

        // from check
        if (currentFrom != address(0)) {
            require(currentFrom == msg.sender, "Router: wrong sender");
            from = currentFrom;
        } else {
            from = prevMaskedParams.to;
        }

        // emergencyTo check
        if (currentRequestId == 0 && currentEmergencyTo != address(0)) {
            // only in initial chain (currentRequestId always 0)
            require(currentEmergencyTo == msg.sender, "Router: wrong emergencyTo");
            emergencyTo = currentEmergencyTo;
        } else {
            // on next chain always using first one
            emergencyTo = prevMaskedParams.emergencyTo;
        }
    }

    function _checkTo(address to, address emergencyTo, uint64 chainId, bytes32 nextOp) internal view virtual returns (address correctTo) {
        require(to == address(0) || nextOp == bytes32(0), "Router: wrong to");
        if (nextOp == bytes32(0)) {
            correctTo = to;
            require(correctTo == emergencyTo, "Router: wrong receiver");
        } else if (nextOp == LOCK_MINT_CODE) {
            correctTo = IAddressBook(addressBook).portal(chainId);
        } else if (nextOp == BURN_UNLOCK_CODE || nextOp == BURN_MINT_CODE) {
            correctTo = IAddressBook(addressBook).synthesis(chainId);
        } else if (WRAP_CODE == nextOp || UNWRAP_CODE == nextOp) {
            correctTo = IAddressBook(addressBook).router(chainId);
        }
    }

}