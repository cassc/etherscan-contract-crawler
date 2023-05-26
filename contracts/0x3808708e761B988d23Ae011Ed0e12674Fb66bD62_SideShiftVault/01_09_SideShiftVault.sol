// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {SafeCastLib} from '@rari-capital/solmate/src/utils/SafeCastLib.sol';
import {SafeTransferLib} from '@rari-capital/solmate/src/utils/SafeTransferLib.sol';
import {FixedPointMathLib} from '@rari-capital/solmate/src/utils/FixedPointMathLib.sol';
import {ERC4626} from '@rari-capital/solmate/src/mixins/ERC4626.sol';
import {ERC20} from '@rari-capital/solmate/src/tokens/ERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract SideShiftVault is ERC4626, Ownable {
    using SafeCastLib for uint256;
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /// @notice the underlying token the vault accepts
    ERC20 public immutable UNDERLYING;

    /// @notice bool clarifying vault's have been initialized
    bool public contractInitialized;

    /// @notice Event emits when vault is initialized
    event ContractInitialization(address indexed user);

    /// @notice bool clarifying if shares have been minted for merkle claimees
    bool public merkleMinted;

    /// @notice The root hash of the Merkle tree - as it won't change made immutable
    bytes32 public immutable merkleRoot;

    /// @notice The number of shares in the vault not claimed from the merkle tree
    uint256 public merkleUnclaimed;

    /// @notice mapping for addresses in merkle that have claimed
    mapping(address => bool) public merkleClaimed;

    /// @notice Event emits when shares for address in merkle are minted
    event MerkleSharesMinted(address indexed user, uint256 shares);

    /// @notice Event emits when address in merkle claims shares
    event MerkleClaim(address indexed user, uint256 amount);

    /// Merkle root used as a param at deployment
    constructor(ERC20 _UNDERLYING, bytes32 _merkleRoot)
        ERC4626(
            _UNDERLYING,
            string(
                abi.encodePacked('SideShift ', _UNDERLYING.name(), ' Vault')
            ),
            string(abi.encodePacked('sv', _UNDERLYING.symbol()))
        )
    {
        UNDERLYING = _UNDERLYING;
        totalSupply = type(uint256).max;
        merkleRoot = _merkleRoot;
    }

    // ================ VAULT ACCOUNTING ==================== //
    /// @notice Calculates the current balance of the underlying token i.e. XAI
    /// @return The contract's balance of XAI
    function totalAssets() public view override returns (uint256) {
        return UNDERLYING.balanceOf(address(this));
    }

    /// @notice Calculates the max depositable amount of the underlying token
    /// @return The outstanding balance of XAI token not staked in the contract
    function maxDeposit(address _address)
        public
        view
        override
        returns (uint256)
    {
        return UNDERLYING.balanceOf(_address);
    }

    /// @notice Calculates the max mintable shares
    /// @return The amount of shares mintable for total supply of unstaked XAI
    function maxMint(address _address) public view override returns (uint256) {
        return previewDeposit(UNDERLYING.balanceOf(_address));
    }

    // ================== MERKLE TREE CLAIM ========================== //
    /// @notice Mints shares to contract that can be claimed by addresses in merkle
    function merkleMint(
        uint256 _shares,
        uint256 _amount,
        address _sender
    ) internal {
        require(_amount == _shares, 'INSUFFICIENT_AMOUNT');
        merkleMinted = true;
        merkleUnclaimed = _shares;
        _mint(address(this), _shares);
        emit MerkleSharesMinted(_sender, _shares);
    }

    /// @notice Claims eligible amount of shares for address in merkle
    function claimShares(
        address _sender,
        uint256 _amount,
        bytes32[] calldata merkleProof
    ) external {
        require(!merkleClaimed[_sender], 'ALREADY_CLAIMED');
        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(_sender, _amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            'INVALID_PROOF'
        );
        // Set address to claimed and deduct shares from merkle unclaimed total
        merkleClaimed[_sender] = true;
        merkleUnclaimed -= _amount;

        // Mint shares and burn contract shares --> Transfer uses callers as msg.sender
        // And TransferFrom would require allowance for every merkle address
        _burn(address(this), _amount);
        _mint(_sender, _amount);

        // Emit claim event
        emit MerkleClaim(_sender, _amount);
    }

    function checkMerkle(
        address _sender,
        uint256 _amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_sender, _amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            'INVALID_PROOF'
        );
        return true;
    }

    /// @notice Emergency function to transfer shares to owner if the merkle root missed an address
    /// Shares can then be transferred from the owner to the address missed from the merkle
    function emergencyMerkleTransfer(uint256 _amount) external onlyOwner {
        require(_amount <= merkleUnclaimed, 'CLAIM_TOO_HIGH');
        merkleUnclaimed -= _amount;
        _burn(address(this), _amount);
        _mint(msg.sender, _amount);
    }

    // ================= ADMIN FUNCTIONs =============== //
    /// @notice Initializes contract by setting totalSupply to 0 from type(uint256).max
    /// Added merkle + deposit to avoid front run risk on the deposit
    function vaultInitialize(uint256 _shares, uint256 _amount)
        external
        onlyOwner
    {
        require(!contractInitialized, 'ALREADY_INITIALIZED');

        // Setting supply to 0 to initialize contract from overflow state
        contractInitialized = true;
        totalSupply = 0;

        // Mint shares for all addresses in merkle tree and hold in contract
        merkleMint(_shares, _amount, msg.sender);
        require(
            UNDERLYING.transferFrom(msg.sender, address(this), _amount),
            'TRANSFER_FAIL'
        );
        emit ContractInitialization(msg.sender);
    }
}