// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import "../common/IFerrumDeployer.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../common/SafeAmount.sol";
import "../common/signature/PublicMultiSigCheckable.sol";

/**
@notice Basic implementation of IronSafe
  IronSafe is a multisig wallet with a veto functionality
 */
contract BasicIronSafe is PublicMultiSigCheckable {
	using SafeERC20 for IERC20;
	string constant public NAME = "FERRUM_BASIC_IRON_SAFE";
	string constant public VERSION = "000.001";
	address constant public DEFAULT_QUORUM_ID = address(1);

    bytes32 public deploySalt; // To control the deployed address
    mapping(address=>bool) public vetoRights;
    uint256 public vetoRightsLength;

	bool private _locked;
	modifier locked() {
		require(!_locked, "BIS: Locked");
		_locked = true;
		_;
		_locked = false;
	}

	constructor () EIP712(NAME, VERSION) {
		(uint256 minSignatures,
        address[] memory addresses,
        bytes32 _deploySalt) = abi.decode(IFerrumDeployer(msg.sender).initData(),
            (uint256, address[], bytes32));
        deploySalt = _deploySalt;
        _initialize(DEFAULT_QUORUM_ID, 1, uint16(minSignatures), 0, addresses);
	}

    /**
     @notice Override the initialize method to
     */
    function initialize(
        address /*quorumId*/,
        uint64 /*groupId*/,
        uint16 /*minSignatures*/,
        uint8 /*ownerGroupId*/,
        address[] calldata /*addresses*/
    ) public pure override {
        revert("BIS: not supported");
    }

	bytes32 constant private SET_VETO = keccak256(
		"SetVeto(address to,bytes32 salt,uint64 expiry)");
    /**
    @notice Sets the veto right
    @param to The to
    @param salt The salt
    @param multiSignature The multiSignature
     */
	function setVeto(address to, bytes32 salt, uint64 expiry, bytes memory multiSignature
    ) external expiryRange(expiry) {
        require(!vetoRights[to], "BIS: already has veto");
        require(quorumSubscriptions[to].id != address(0), "BIS: Not a quorum subscriber");
		bytes32 message = keccak256(
			abi.encode(SET_VETO, to, salt, expiry));
		verifyMsg(message, salt, multiSignature);
        vetoRights[to] = true;
        vetoRightsLength += 1;
	}

	bytes32 constant private UNSET_VETO = keccak256(
		"UnsetVeto(address to,bytes32 salt,uint64 expiry)");
    /**
    @notice Unset the veto right
    @param to Who to set the veto to
    @param salt The signature salt
    @param expiry The signature expiry
    @param multiSignature The multi signature
     */
	function unsetVeto(address to, bytes32 salt, uint64 expiry, bytes memory multiSignature
    ) external expiryRange(expiry) {
        require(vetoRights[to], "BSI: has no veto");
		bytes32 message = keccak256(
			abi.encode(UNSET_VETO, to, salt, expiry));
		verifyMsg(message, salt, multiSignature);
        _unsetVeto(to);
    }

	bytes32 constant private SEND_ETH_SIGNED_METHOD = keccak256(
		"SendEthSignedMethod(address to,uint256 amount,bytes32 salt,uint64 expiry)");
    /**
    @notice Sent ETH
    @param to The receiver
    @param amount The amount
    @param salt The signature salt
    @param multiSignature The multi signature
     */
	function sendEthSigned(address to, uint256 amount,
		bytes32 salt, uint64 expiry, bytes memory multiSignature)
	external expiryRange(expiry) locked {
		bytes32 message = keccak256(
			abi.encode(SEND_ETH_SIGNED_METHOD, to, amount, salt, expiry));
		verifyMsg(message, salt, multiSignature);
		SafeAmount.safeTransferETH(to, amount);
	}

	bytes32 constant private SEND_SIGNED_METHOD = keccak256(
		"SendSignedMethod(address to,address token,uint256 amount,bytes32 salt,uint64 expiry)");
	function sendSigned(address to, address token, uint256 amount,
		bytes32 salt, uint64 expiry, bytes memory multiSignature
    ) external expiryRange(expiry) {
		bytes32 message = keccak256(
			abi.encode(SEND_SIGNED_METHOD, to, token, amount, salt, expiry));
		verifyMsg(message, salt, multiSignature);
		IERC20(token).safeTransfer(to, amount);
	}

    /**
     @notice Removes an address from the quorum. Note the number of addresses 
      in the quorum cannot drop below minSignatures.
      For owned quorums, only owning quorum can execute this action. For non-owned
      only quorum itself.
      Also removes veto right if _address is a veto holder.
     @param _address The address to remove
     @param salt The signature salt
     @param expiry The expiry
     @param multiSignature The multisig encoded signature
     */
    function internalRemoveFromQuorum(
        address _address,
        bytes32 salt,
        uint64 expiry,
        bytes memory multiSignature
    ) internal virtual override {
        super.internalRemoveFromQuorum(_address, salt, expiry, multiSignature);
        if (vetoRights[_address]) {
            _unsetVeto(_address);
        }
    }

    /*
    @notice Unset the veto right
    @param to Who to set the veto to
    @param salt The signature salt
    @param expiry The signature expiry
    @param multiSignature The multi signature
     */
	function _unsetVeto(address to
    ) internal {
        vetoRightsLength -= 1;
        delete vetoRights[to];
    }


    function verifyMsg(bytes32 message, bytes32 salt, bytes memory multisig
    ) internal {
        require(!usedHashes[salt], "MSC: Message already used");
        bytes32 digest = _hashTypedDataV4(message);
        (bool result, address[] memory signers) = tryVerifyDigestWithAddress(
            digest,
            1,
            multisig);
        require(result, "BIS: invalid signature");
        usedHashes[salt] = true;
        // ensure there is at least one veto
        if (vetoRightsLength == 0) {
            return;
        }
        for (uint i=0; i<signers.length; i++) {
            if (vetoRights[signers[i]]) {
                return;
            }
        }
        require(vetoRightsLength == 0, "BIS: no veto signature");
    }

    /**
     @notice Override to use the veto signatures 
     @param message The message to verify
     @param salt The salt to be unique
     @param expectedGroupId The expected group ID
     @param multiSignature The signatures formatted as a multisig
     */
    function verifyUniqueSalt(
        bytes32 message,
        bytes32 salt,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) internal override {
        require(expectedGroupId == 0, "BIS: Unsupported group ID");
        verifyMsg(message, salt, multiSignature);
    }

    function verifyUniqueSaltWithQuorumId(
        bytes32 message,
        address expectedQuorumId,
        bytes32 salt,
        uint64 expectedGroupId,
        bytes memory multiSignature
    ) internal override {
        require(multiSignature.length != 0, "MSC: multiSignature required");
        bytes32 digest = _hashTypedDataV4(message);
        (bool result, address[] memory signers) = tryVerifyDigestWithAddress(digest, expectedGroupId, multiSignature);
        require(result, "MSC: Invalid signature");
        require(!usedHashes[salt], "MSC: Message already used");
        require(
            expectedQuorumId == address(0) ||
            quorumSubscriptions[signers[0]].id == expectedQuorumId, "MSC: wrong quorum");
        usedHashes[salt] = true;
        for (uint i=0; i<signers.length; i++) {
            if (vetoRights[signers[i]]) {
                return;
            }
        }
        require(vetoRightsLength == 0, "BIS: no veto signature");
    }
}