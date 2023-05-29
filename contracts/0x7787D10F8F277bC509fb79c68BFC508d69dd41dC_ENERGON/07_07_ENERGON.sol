// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../common/Ownable.sol";

contract ENERGON is ERC20, ERC20Burnable, Ownable {
    uint8 _tokenDecimals;
    bool public enableClaim;
    address public allocator;
    bool public allocDisabled;
    mapping(address => mapping(uint8 => uint8)) public usedNonce;
    mapping(address => uint256) public minters;
    uint256 public numMinters;
    bool public recipientsBlocked;
    mapping(address => uint256) public recipientsAllowlist;

    event UpdatedAllocator(address addr);
    event AllocationDisabled();
    event Claimed(address indexed addr, uint256 amount, uint256 nonce);
    event AddedMinter(address indexed minter);
    event RemovedMinter(address indexed minter);
    event Minted(address indexed account, uint256 amount);
    event AddRecipient(address indexed addr);

    /// @dev Initialize contract
    /// @param _name The name of the token
    /// @param _symbol The token symbol
    /// @param _initialSupply The initial supply
    /// @param _decimals The token's decimals
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        uint8 _decimals
    ) ERC20(_name, _symbol) {
        _tokenDecimals = _decimals;
        _mint(msg.sender, _initialSupply);
        recipientsBlocked = true;
    }

    /// @dev Modifier to check if sender is a minter
    modifier isMinter() {
        require(minters[msg.sender] > 0, "ENERGON: NOT_MINTER");
        _;
    }

    /// @dev Modifier to check if an address can receiver tokens
    modifier canReceive(address addr) {
        require(!recipientsBlocked || recipientsAllowlist[addr] > 0, "ENERGON: NO_PERMIT");
        _;
    }

    function decimals() public view override returns (uint8) {
        return _tokenDecimals;
    }

    /// @notice Set allocator
    /// @param addr The address of the allocator
    function setAllocator(address addr) public onlyOwner {
        allocator = addr;
        emit UpdatedAllocator(addr);
    }

    /// @notice Disable allocation via signature.
    function disableAllocation() public onlyOwner {
        allocDisabled = true;
        emit AllocationDisabled();
    }

    /// @dev Add minters
    /// @param addrs The address of the minters
    function addMinters(address[] memory addrs) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            minters[addrs[i]] = 1;
            numMinters++;
            emit AddedMinter(addrs[i]);
        }
    }

    /// @dev Remove a minter
    /// @param addr The address of the minter
    function removeMinter(address addr) public onlyOwner {
        delete minters[addr];
        numMinters--;
        emit RemovedMinter(addr);
    }

    /// @dev Disable recipient blocking
    function disableRecipientBlock() public onlyOwner {
        recipientsBlocked = false;
    }

    /// @dev Add an address that can receive tokens
    /// @param addr The target address
    function addRecipient(address addr) public onlyOwner {
        recipientsAllowlist[addr] = 1;
        emit AddRecipient(addr);
    }

    /// @dev Mint amount for an address.
    /// @param to The account that will receive the minted tokens.
    /// @param amount The amount of tokens to be minted.
    function mint(address to, uint256 amount) public isMinter {
        _mint(to, amount);
        emit Minted(to, amount);
    }

    /// @notice Claim energon with a signature
    /// @param _amount The amount to claim
    /// @param _signature The claim signature created by the allocator
    /// @param _sigNonce The unique signature nonce
    function claim(
        uint256 _amount,
        bytes memory _signature,
        uint8 _sigNonce
    ) public {
        require(!allocDisabled, "ENERGON: DISABLED");
        require(usedNonce[msg.sender][_sigNonce] == 0, "ENERGON: SIG_NONCE_USED");
        require(verifySig(allocator, msg.sender, _amount, _sigNonce, _signature), "ENERGON: BAD_SIG");
        usedNonce[msg.sender][_sigNonce] = 1;
        _mint(msg.sender, _amount);
        emit Claimed(msg.sender, _amount, _sigNonce);
    }

    function transfer(address recipient, uint256 amount) public virtual override canReceive(recipient) returns (bool) {
        return ERC20.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override canReceive(recipient) returns (bool) {
        return ERC20.transferFrom(sender, recipient, amount);
    }

    /// @dev Construct mint message hash
    function getMessageHash(
        address addr,
        uint256 _amount,
        uint8 nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr, _amount, nonce));
    }

    /// @dev Construct a signed message hash
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    /// @dev Recover the signer
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /// @dev Verify mint signature
    function verifySig(
        address _signer,
        address _addr,
        uint256 _amount,
        uint8 _nonce,
        bytes memory signature
    ) internal pure returns (bool) {
        if (address(0) == _signer) return false;
        bytes32 messageHash = getMessageHash(_addr, _amount, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}