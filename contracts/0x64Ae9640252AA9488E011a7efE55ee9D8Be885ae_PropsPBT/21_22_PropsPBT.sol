// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./PBT/PBTSimple.sol";

error MintNotOpen();
error TotalSupplyReached();
error CannotUpdateDeadline();
error CannotMakeChanges();

contract PropsPBT is PBTSimple, Ownable, AccessControlEnumerable {
    bytes32 private constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
  
    uint256 public TOTAL_SUPPLY = 300;
    uint256 public supply;

    string private _baseTokenURI;

    mapping(uint256 => bool) public tokenIsLockedState;
    mapping(uint256 => address) public tokenDelegates;

    struct UnlockRequest {
        uint256 tokenId;
        address requester;
        uint256 firstRequestedOn;
    }

    mapping(uint256 => UnlockRequest) public tokenUnlockRequests;

    event MintedTokenWithChip(address indexed chipAddress, uint256 indexed tokenId, address indexed minter);

    constructor(string memory name_, string memory symbol_)
        PBTSimple(name_, symbol_)
    {
         _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function mint(
        bytes calldata signatureFromChip,
        uint256 blockNumberUsedInSig
    ) external {
        if (supply == TOTAL_SUPPLY) {
            revert TotalSupplyReached();
        }

         TokenData memory tokenData = _getTokenDataForChipSignature(signatureFromChip, blockNumberUsedInSig);
        
        _mintTokenWithChip(signatureFromChip, blockNumberUsedInSig);

        tokenDelegates[tokenData.tokenId] =_msgSender();
        tokenIsLockedState[tokenData.tokenId] = true;
        
        unchecked {
            ++supply;
        }

        emit MintedTokenWithChip(tokenData.chipAddress, tokenData.tokenId, _msgSender());
    }

     function updateTokenLockedState(
         bytes calldata signatureFromChip,
         uint256 blockNumberUsedInSig,
         bool isLocked
    ) external {
       uint256 tokenId = _getTokenDataForChipSignature(signatureFromChip, blockNumberUsedInSig).tokenId;
       require(tokenDelegates[tokenId] == _msgSender(), "Only authorized delegate can update token locked state");
       tokenIsLockedState[tokenId] = isLocked;
    }


    //@dev - these functions allow for someone with the chip in their possession for more than 24 hours to unlock the token for transfer

    function initiateTokenUnlock(
        bytes calldata signatureFromChip,
        uint256 blockNumberUsedInSig
    ) external {
        uint256 tokenId = _getTokenDataForChipSignature(signatureFromChip, blockNumberUsedInSig).tokenId;
        tokenUnlockRequests[tokenId] = UnlockRequest(tokenId, _msgSender(), block.timestamp);
    }

    function completeTokenUnlock(
        bytes calldata signatureFromChip,
        uint256 blockNumberUsedInSig
    ) external {
        uint256 currentTime = block.timestamp;
        uint256 tokenId = _getTokenDataForChipSignature(signatureFromChip, blockNumberUsedInSig).tokenId;
        UnlockRequest storage unlockRequest = tokenUnlockRequests[tokenId];
        require(unlockRequest.requester == _msgSender(), "Only initial requester can complete token unlock");

        //first request must have been between 48 and 24 hours ago
        require(unlockRequest.firstRequestedOn >= currentTime - 172800 && unlockRequest.firstRequestedOn <= currentTime - 86400, "No initial unlock request found for token in the required timeframe window");
        tokenIsLockedState[tokenId] = false;
    }

    function getTokenData(address chipAddress) external view returns (TokenData memory) {
        return _tokenDatas[chipAddress];
    }
    
    function getTokenDataFromScan( 
        bytes calldata signatureFromChip,
        uint256 blockNumberUsedInSig
    ) external view returns (TokenData memory) {
         TokenData memory tokenData = _getTokenDataForChipSignature(signatureFromChip, blockNumberUsedInSig);
        return tokenData;
    }

     function updateTotalSupply(
        uint256 newSupply
    ) external minRole(CONTRACT_ADMIN_ROLE) {
        TOTAL_SUPPLY = newSupply;
    }

    function seedChipToTokenMapping(
        address[] calldata chipAddresses,
        uint256[] calldata tokenIds,
        bool throwIfTokenAlreadyMinted
    ) external minRole(CONTRACT_ADMIN_ROLE) {
        _seedChipToTokenMapping(
            chipAddresses,
            tokenIds,
            throwIfTokenAlreadyMinted
        );
    }

    function updateChips(
        address[] calldata chipAddressesOld,
        address[] calldata chipAddressesNew
    ) external minRole(CONTRACT_ADMIN_ROLE) {
        _updateChips(chipAddressesOld, chipAddressesNew);
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external minRole(CONTRACT_ADMIN_ROLE) {
        _baseTokenURI = baseURI;
    }

    function transferTokenViaChip(
        bytes calldata signatureFromChip,
        uint256 blockNumberUsedInSig,
        bool useSafeTransferFrom
    ) external {
        uint256 tokenId = _getTokenDataForChipSignature(signatureFromChip, blockNumberUsedInSig).tokenId;
        require( !tokenIsLockedState[tokenId], "Token is locked. If you are the owner use updateTokenLockedState() to unlock. If you are not the owner use initiateTokenUnlock() to begin the unlock process.");
        _transferTokenWithChip(signatureFromChip, blockNumberUsedInSig, useSafeTransferFrom);
        tokenDelegates[tokenId] =_msgSender();
        tokenIsLockedState[tokenId] = true;
    }

    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) minRole(CONTRACT_ADMIN_ROLE) {
        if(!hasRole(role, account)){
            super._grantRole(role,account);
        }
    }

    /**
   * @dev Check if minimum role for function is required.
   */
    modifier minRole(bytes32 _role) {
        require(_hasMinRole(_role), "Not authorized");
        _;
    }

    function hasMinRole(bytes32 _role) public view virtual returns (bool){
        return _hasMinRole(_role);
    }

    function _hasMinRole(bytes32 _role) internal view returns (bool) {
        // @dev does account have role?
        if(hasRole(_role, _msgSender())) return true;
        // @dev are we checking against default admin?
        if(_role == DEFAULT_ADMIN_ROLE) return false;
        // @dev walk up tree to check if user has role admin role
        return _hasMinRole(getRoleAdmin(_role));
    }

     /**
   * @dev see {IERC165-supportsInterface}
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(PBTSimple, AccessControlEnumerable) returns (bool) {
      return super.supportsInterface(interfaceId);
  }

}