// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// implements the ERC1155 standard
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRedeemNFT.sol";

contract RedeemNFT is ERC1155, AccessControl, Ownable, IRedeemNFT {
    using ECDSA for bytes32;
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    mapping(address => mapping(uint256 => bool)) internal usedNonces;
    mapping(uint256 => bool) internal usedInternalIds;
    mapping(address => bool) internal claimedTokens;

    string public name;
    string public symbol;
    bool private claimActive = true;

    uint256 private immutable endTime;

    constructor(
        address initialSignerAddress,
        string memory _name,
        string memory _symbol,
        uint256 _endtime
    )
        ERC1155("https://api.monkeybet.co/monkeybet/pitboss/{id}")
        AccessControl()
    {
        name = _name;
        symbol = _symbol;
        endTime = _endtime;

        require(
            initialSignerAddress != address(0x0),
            "Initial signer required"
        );

        // Setting the role admin for all the roles (signer).
        _setRoleAdmin(SIGNER_ROLE, DEFAULT_ADMIN_ROLE);

        // Granting roles to accounts.
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SIGNER_ROLE, initialSignerAddress);
    }

    function claim(
        address sender,
        address signer,
        uint256 nonce,
        uint256 qty,
        uint256 internalId,
        bytes calldata signature
    ) external {
        require(block.timestamp <= endTime, "Claim are currently close");
        require(claimActive == true, "Claim are currently close");
        require(msg.sender == sender, "Sender does not match");
        require(!usedInternalIds[internalId], "Internal id already used");
        require(!claimedTokens[sender], "PitBoss Already Claimed");

        _requireValidNonceAndUpdate(signer, nonce);

        usedInternalIds[internalId] = true;

        address messageSigner = _getSigner(
            sender,
            signer,
            nonce,
            qty,
            internalId,
            signature
        );

        require(messageSigner == signer, "Signer does not match");

        _requireHasRole(SIGNER_ROLE, messageSigner);

        _mint(msg.sender, 0, qty, "");

        claimedTokens[sender] = true;

        emit TokensRedeemed(sender, signer, internalId, qty);
    }

    function toogleRedeem() public onlyOwner {
        claimActive = !claimActive;
    }

    function statusRedeem() public view returns (bool status) {
        return claimActive;
    }

    function isUsedNonce(address signer, uint256 nonce)
        external
        view
        returns (bool)
    {
        return usedNonces[signer][nonce];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** Internal Functions */

    /**
        @notice Gets the current chain id using the opcode 'chainid()'.
        @return the current chain id.
     */
    function _getChainId() internal view returns (uint256) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /** Internal Functions */

    function _requireValidNonceAndUpdate(address signer, uint256 nonce)
        internal
    {
        require(!usedNonces[signer][nonce], "Nonce already used");
        usedNonces[signer][nonce] = true;
    }

    function _requireHasRole(bytes32 role, address account) internal view {
        require(hasRole(role, account), "Account has not role");
    }

    function _getSigner(
        address sender,
        address signer,
        uint256 nonce,
        uint256 qty,
        uint256 internalId,
        bytes memory signature
    ) internal view returns (address) {
        bytes32 hash = _hashData(
            sender,
            signer,
            nonce,
            qty,
            internalId,
            _getChainId()
        );
        bytes32 messageHash = hash.toEthSignedMessageHash();
        return messageHash.recover(signature);
    }

    function _hashData(
        address sender,
        address signer,
        uint256 nonce,
        uint256 qty,
        uint256 internalId,
        uint256 chainId
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    sender,
                    signer,
                    nonce,
                    qty,
                    internalId,
                    chainId
                )
            );
    }
}