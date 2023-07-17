// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./common/BaseGovernanceWithUserUpgradable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "./interfaces/ILock.sol";
import "./interfaces/ISplitManager.sol";

/// @title Deals with user funds and assets only
/// @author swapr
/// @notice Only deals with ILock ERC721 proxy, ETH,BNB,MATIC or ERC20 funds
/// @dev Can only be interacted from an identified Swapr contract
contract SwaprWallet is BaseGovernanceWithUserUpgradable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    uint internal constant _EXP = 1e18;

    bytes32 public constant SWAPRGL_ROLE = keccak256("SWAPRGL_ROLE");

    mapping(address => mapping(uint => bytes)) private _lockedNFTs; // for sig based nft deposits

    mapping(address => mapping(address => uint)) private _ercBank; //erc deposits

    mapping(address => uint) private _nativeBank; //native deposits

    event Splitted(uint256[] newIDs);

    /// @notice only allows calls from Swapr on-chin or Swapr Signature based contracts
    modifier onlySwapr() {
        require(hasRole(SWAPRGL_ROLE, _msgSender()), "ERROR: ONLY_SWAPR_ROLE");
        _;
    }

    /// @notice initializes the contract
    /// @param data encoded address of SwaprGL contract
    function initialize(bytes calldata data) public initializer {
        address swaprGLAddress = abi.decode(data, (address));
        __BaseGovernanceWithUser_init(_msgSender());
        // //You can setup custom roles here in addition to the default gevernance roles
        require(swaprGLAddress != address(0), "ERROR: ZERO_ADDRESS");
        _setupRole(SWAPRGL_ROLE, swaprGLAddress);

        // //All variables must be initialized below this comment in sequence to prevent upgrade conflicts
    }

    /// @notice transfers the asset to self
    /// @dev requires NFT to be approved by depositor prior to call
    /// @param lock address of ERC721 proxy
    /// @param nftId tokenId
    /// @param owner owner of the asset
    function _transferToSelfNFT(address lock, uint nftId, address owner) internal {
        ILock lockContract = ILock(lock);
        require(_getNFTOwner(lock, nftId) == owner, "ERROR: NO_NFT_OWNERSHIP");
        //requires approval for transfer
        lockContract.safeTransferFrom(owner, address(this), nftId);
    }

    /// @notice locks the NFT within wallet bound by owner signature
    /// @dev sig can be used anywhere to refer to this nft along with the offchain data
    /// @param sig user's sign with purpose of deposit as message
    /// @param lock lock proxy address
    /// @param nftId tokenId within the lock
    /// @param owner address of the owner to verify the ownership
    function lockNFT(bytes calldata sig, address lock, uint nftId, address owner) external onlySwapr {
        require(getLockedPart(lock, nftId) < _EXP, "LOCKED_PART_IS_100");
        if (!_isNFT(lock, nftId)) {
            _transferToSelfNFT(lock, nftId, owner);
        }
        _lockedNFTs[lock][nftId] = sig;
    }

    /// @notice updates the NFT record within wallet bound by owner signature
    /// @dev sig can be used anywhere to refer to this nft along with the offchain data
    /// @param sig new user's sign with purpose of deposit as message
    /// @param lock lock proxy address
    /// @param nftId tokenId within the lock
    function updateLockedNFT(bytes calldata sig, address lock, uint nftId) external onlySwapr {
        require(_getNFTOwner(lock, nftId) == address(this), "WALLET_IS_NOT_OWNER");
        _lockedNFTs[lock][nftId] = sig;
    }

    /// @notice splits the NFT from lock if it has locked part
    /// @dev this function is _experimental and the dev may perform splitting directly through lock proxy
    /// @param lock lock proxy address
    /// @param nftId tokenId within the lock
    /// @param addresses array of addresses of new owners
    /// @return newIDs array of new tokenIds
    function splitLockedPart(
        address lock,
        uint nftId,
        address[] memory addresses
    ) external returns (uint256[] memory newIDs) {
        uint256 lockedPart = getLockedPart(lock, nftId);
        uint256 splitablePart = _EXP - lockedPart;

        uint256[] memory splitParts = new uint[](2);
        splitParts[0] = lockedPart;
        splitParts[1] = splitablePart;

        //requires approval
        newIDs = ILock(lock).split(nftId, splitParts, addresses);
        emit Splitted(newIDs);
    }

    /// @notice returns the locked part of the NFT
    /// @param lock lock proxy address
    /// @param nftId tokenId within the lock
    /// @return lockedPart locked part of the NFT
    function getLockedPart(address lock, uint nftId) public view returns (uint256 lockedPart) {
        ILock lockContract = ILock(lock);
        ISplitManager splitManager = ISplitManager(lockContract.splitManager());
        lockedPart = splitManager.getLockedPart(nftId);
    }

    /// @notice removes the NFT record from within SwaprWallet
    /// @dev only for SwaprGL sig based deposits
    /// @param lock lock proxy address
    /// @param nftId tokenId within the lock
    function disposeNFT(address lock, uint nftId) external onlySwapr {
        if (_isNFT(lock, nftId)) {
            delete _lockedNFTs[lock][nftId];
        }
    }

    /// @notice transfers the ownership from itself to some EOA
    /// @dev only for SwaprGL sig based deposits
    /// @param lock lock proxy address
    /// @param nftId tokenId within the lock
    /// @param receiver address of the new owner
    function releaseNFT(address lock, uint nftId, address receiver) external onlySwapr {
        //claim outside swapr wallet - withdraw
        ILock lockContract = ILock(lock);
        delete _lockedNFTs[lock][nftId];
        lockContract.safeTransferFrom(address(this), receiver, nftId);
    }

    /// @notice splits the NFT before release on buy now
    /// @dev only for splitable purchase
    /// @param lock lock proxy address
    /// @param nftId tokenId within the lock
    /// @param splitParts parts to be splitted in percentage
    /// @param addresses array of addresses of new owners sequentially as splitParts
    /// @return newIDs array of new tokenIds
    function splitReleaseNFT(
        address lock,
        uint nftId,
        uint[] calldata splitParts,
        address[] calldata addresses
    ) external returns (uint256[] memory newIDs) {
        newIDs = ILock(lock).split(nftId, splitParts, addresses);
    }

    /// @notice Public function for user to deposit funds as ETH, BNB or MATIC etc
    function depositNative() public payable {
        require(msg.value > 0, "ERROR: LOW_VALUE_OBSERVED");
        _nativeBank[_msgSender()] += msg.value;
    }

    /// @notice used when deposit occurs from swaprGL
    /// @dev only swaprGL can call this function
    /// @param depositor address of the depositor
    function depositNativeSwapr(address depositor) public payable onlySwapr {
        _nativeBank[depositor] += msg.value;
    }

    /// @notice swaps native ETH funds only within swapr wallet
    /// @dev only swaprGL can call this function
    /// @param from address of the sender
    /// @param to address of the receiver
    /// @param amount amount to be swapped
    function swapNative(address from, address to, uint amount) external onlySwapr {
        require(_nativeBank[from] >= amount, "ERROR: LOW_VALUE_RELEASE");
        _nativeBank[from] -= amount;
        _nativeBank[to] += amount;
    }

    /// @notice sends the held ETH funds from itself to some EOA
    /// @dev only for SwaprGL sig based deposits
    /// @param receiver address of the new owner
    /// @param owner address of the owner
    /// @param amount amount to be released
    function releaseNative(address receiver, address owner, uint amount) external onlySwapr {
        require(_nativeBank[owner] >= amount, "ERROR: LOW_VALUE_RELEASE");
        _nativeBank[owner] -= amount;
        payable(receiver).transfer(amount);
    }

    /// @notice deposits ERC20 funds first transfer to self and then within swapr wallet
    /// @dev approval for relevant token required for transfer to happen
    /// @param token address of the token
    function depositERC(address token) external {
        IERC20MetadataUpgradeable fundToken = IERC20MetadataUpgradeable(token);
        uint allowance = fundToken.allowance(_msgSender(), address(this));
        require(allowance > 0, "ERROR: ZERO_ALLOWANCE");
        fundToken.safeTransferFrom(_msgSender(), address(this), allowance);
        _ercBank[_msgSender()][token] += allowance;
    }

    /// @notice used when deposit occurs from swaprGL
    /// @dev only swaprGL can call this function
    /// @param token address of the token
    /// @param depositor address of the depositor
    /// @param amount amount to be deposited
    function depositERCSwapr(address token, address depositor, uint amount) external onlySwapr {
        _ercBank[depositor][token] += amount;
    }

    /// @notice swaps ERC20 funds only within swapr wallet
    /// @dev only swaprGL can call this function
    /// @param token address of the token
    /// @param from address of the sender
    /// @param to address of the receiver
    /// @param amount amount to be swapped
    function swapERC(address token, address from, address to, uint amount) external onlySwapr {
        //unlock should be performed before swaping
        require(_ercBank[from][token] >= amount, "ERROR: LOW_VALUE_RELEASE");
        _ercBank[from][token] -= amount;
        _ercBank[to][token] += amount;
    }

    /// @notice sends the held ERC20 funds from itself to some EOA
    /// @dev only for SwaprGL sig based deposits
    /// @param token address of the token
    /// @param receiver address of the new owner
    /// @param owner address of the owner
    /// @param amount amount to be released
    function releaseERC(address token, address receiver, address owner, uint amount) external onlySwapr {
        require(_ercBank[owner][token] >= amount, "ERROR: LOW_VALUE_RELEASE");
        IERC20MetadataUpgradeable paymentToken = IERC20MetadataUpgradeable(token);
        _ercBank[owner][token] -= amount;
        paymentToken.transfer(receiver, amount);
    }

    /// @notice get available balance ETH / ERC20
    /// @dev balance excludes the locked balance
    /// @param owner address of the holder
    /// @param token address(0) means ETH balance
    /// @return balance funds that can be used
    function getBalance(address owner, address token) external view returns (uint balance) {
        if (token == address(0)) {
            balance = _getNativeBalance(owner);
        } else {
            balance = _getErcBalance(owner, token);
        }
    }

    /// @notice internal function to get native balance of an address
    /// @param _owner address of the holder
    /// @return balance funds that can be used
    function _getNativeBalance(address _owner) internal view returns (uint) {
        return _nativeBank[_owner];
    }

    /// @notice internal function to get erc20 balance of an address
    /// @param _owner address of the holder
    /// @param _token address of the token
    /// @return balance funds that can be used
    function _getErcBalance(address _owner, address _token) internal view returns (uint) {
        return _ercBank[_owner][_token];
    }

    /// @notice check if nft is locked within swapr
    /// @param lock address of the lock proxy
    /// @param nftId id of the nft
    /// @return bool true if locked
    function isNFTLocked(address lock, uint nftId) external view returns (bool) {
        return _isNFT(lock, nftId);
    }

    /// @notice check if nft is locked within swapr
    /// @param _lock address of the lock proxy
    /// @param _nftId id of the nft
    /// @return bool true if locked
    function _isNFT(address _lock, uint _nftId) internal view returns (bool) {
        return abi.encodePacked(_lockedNFTs[_lock][_nftId]).length > 0;
    }

    /// @notice get locked nft signature
    /// @param lock address of the lock proxy
    /// @param nftId id of the nft
    /// @return sig signature of the nft
    function getNFT(address lock, uint nftId) external view returns (bytes memory sig) {
        sig = _lockedNFTs[lock][nftId];
    }

    /// @notice get owner of nft from lock proxy
    /// @param lock address of the lock proxy
    /// @param nftId id of the nft
    /// @return owner address of the owner
    function _getNFTOwner(address lock, uint nftId) internal view returns (address) {
        ILock lockContract = ILock(lock);
        return lockContract.ownerOf(nftId);
    }
}