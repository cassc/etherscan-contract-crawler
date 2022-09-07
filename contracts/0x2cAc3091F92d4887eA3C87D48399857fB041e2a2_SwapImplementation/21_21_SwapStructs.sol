// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WormholeStructs {
    struct TransferWithPayload {
        // PayloadID uint8 = 3
        uint8 payloadID;
        // Amount being transferred (big-endian uint256)
        uint256 amount;
        // Address of the token. Left-zero-padded if shorter than 32 bytes
        bytes32 tokenAddress;
        // Chain ID of the token
        uint16 tokenChain;
        // Address of the recipient. Left-zero-padded if shorter than 32 bytes
        bytes32 to;
        // Chain ID of the recipient
        uint16 toChain;
        // Address of the message sender. Left-zero-padded if shorter than 32 bytes
        bytes32 fromAddress;
        // An arbitrary payload
        bytes payload;
    }
    struct Transfer {
        // PayloadID uint8 = 1
        uint8 payloadID;
        // Amount being transferred (big-endian uint256)
        uint256 amount;
        // Address of the token. Left-zero-padded if shorter than 32 bytes
        bytes32 tokenAddress;
        // Chain ID of the token
        uint16 tokenChain;
        // Address of the recipient. Left-zero-padded if shorter than 32 bytes
        bytes32 to;
        // Chain ID of the recipient
        uint16 toChain;
        // Amount of tokens (big-endian uint256) that the user is willing to pay as relayer fee. Must be <= Amount.
        uint256 fee;
    }

	struct Signature {
		bytes32 r;
		bytes32 s;
		uint8 v;
		uint8 guardianIndex;
	}

	struct VM {
		uint8 version;
		uint32 timestamp;
		uint32 nonce;
		uint16 emitterChainId;
		bytes32 emitterAddress;
		uint64 sequence;
		uint8 consistencyLevel;
		bytes payload;

		uint32 guardianSetIndex;
		Signature[] signatures;

		bytes32 hash;
	}
    struct AssetMeta {
        // PayloadID uint8 = 2
        uint8 payloadID;
        // Address of the token. Left-zero-padded if shorter than 32 bytes
        bytes32 tokenAddress;
        // Chain ID of the token
        uint16 tokenChain;
        // Number of decimals of the token (big-endian uint256)
        uint8 decimals;
        // Symbol of the token (UTF-8)
        bytes32 symbol;
        // Name of the token (UTF-8)
        bytes32 name;
    }
}

/**
 * @title IWormhole
 * @dev Wormhole functions to call them for decoding/encoding VAA
 */
abstract contract IWormhole {
function parseAndVerifyVM(bytes calldata encodedVM) public virtual view returns (WormholeStructs.VM memory vm, bool valid, string memory reason);
}
/**
 * @title ITokenBridgeWormhole
 * @dev Wormhole Token bridge functions to call them for swapping
 */
abstract contract ITokenBridgeWormhole {
    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress) public view virtual returns (address);
    function tokenImplementation() public view virtual returns (address);
    function chainId() public view virtual returns  (uint16);
    function wormhole() public view virtual returns  (address);
    function isTransferCompleted(bytes32 hash) public virtual view returns (bool);
    function completeTransfer(bytes memory encodedVm) public virtual;
    function parseTransfer(bytes memory encoded) public virtual pure returns (WormholeStructs.Transfer memory transfer);
    function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) public virtual payable returns (uint64 sequence) ;
    function transferTokensWithPayload(
        address token,
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient,
        uint32 nonce,
        bytes memory payload
    ) public virtual payable returns (uint64 sequence);
    function parseTransferWithPayload(bytes memory encoded) public virtual pure returns (WormholeStructs.TransferWithPayload memory transfer);
    function _parseTransferCommon(bytes memory encoded) public virtual pure returns (WormholeStructs.Transfer memory transfer);
}

// A partial WETH interfaec.
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

/**
 * @title AtlasDexSwap
 */
contract SwapStructs {

    struct _1inchSwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    struct _0xSwapDescription {
        address inputToken;
        address outputToken;
        uint256 inputTokenAmount;
    }

    struct LockedToken {
        address _wormholeBridgeToken;
        address _token;
        uint256 _amount;
        uint16 _recipientChain;
        bytes32 _recipient;
        uint32 _nonce;
        bytes _1inchData;
        bytes _0xData;
        bool _IsWrapped;
        bool _IsUnWrapped;
        uint256 _amountToUnwrap;
        bytes _payload;
    }

    struct CrossChainRelayerPayload {
        bytes32 receiver;
        bytes32 token;
        
        bytes32 _id;

        uint256 slippage;

        uint256 fee;
    }
} // end of class